// BPU grouped top for frontend comb training boundaries.
// Source: simulator-front/front-end/BPU/BPU.h.
// Comb instances use semantic variable ports; each wrapper builds pi/po internally.

module bpu_top #(
    parameter integer FETCH_WIDTH             = 16,
    parameter integer COMMIT_WIDTH            = 8,
    parameter integer TN_MAX                  = 4,
    parameter integer PC_BITS                 = 32,
    parameter integer PCPN_BITS               = 3,
    parameter integer BR_TYPE_BITS            = 3,
    parameter integer TAGE_IDX_BITS           = 12,
    parameter integer TAGE_TAG_BITS           = 8,
    parameter integer BPU_SCL_META_NTABLE     = 8,
    parameter integer BPU_SCL_META_IDX_BITS   = 16,
    parameter integer BPU_SCL_META_SUM_BITS   = 16,
    parameter integer BPU_LOOP_META_IDX_BITS  = 16,
    parameter integer BPU_LOOP_META_TAG_BITS  = 16,
    parameter integer BPU_BANK_NUM            = FETCH_WIDTH,
    parameter integer Q_DEPTH                 = 500,
    parameter integer GHR_LENGTH              = 512,
    parameter integer FH_N_MAX                = 3,
    parameter integer RAS_DEPTH               = 64,
    parameter integer TAGE_SC_PATH_BITS       = 16,
    parameter integer NLP_TABLE_SIZE          = 4096,
    parameter integer NLP_CONF_BITS           = 2,
    parameter integer RESET_PC                = 32'h0000_0000,
    parameter integer W_BpuIn                 = 2739,  // actual: 2739, from front_top W_BpuIn
    parameter integer W_BpuOut                = 4949    // actual: 4949, from front_top W_BpuOut
) (
    input  wire                aclk,
    input  wire                aresetn,
    input  wire                reset,
    input  wire [W_BpuIn-1:0]  bpu_in,
    output wire [W_BpuOut-1:0] bpu_out
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = (i == 0) ? 1 : i;
        end
    endfunction

    localparam integer S_IDLE    = 2'd0;
    localparam integer S_WORKING = 2'd1;
    localparam integer S_REFETCH = 2'd2;

    localparam integer QUEUE_PTR_BITS   = clog2(Q_DEPTH);
    localparam integer QUEUE_COUNT_BITS = clog2(Q_DEPTH + 1);
    localparam integer RAS_COUNT_BITS   = clog2(RAS_DEPTH + 1);
    localparam integer NLP_TAG_BITS     = PC_BITS;
    localparam integer W_NlpEntry       = 1 + NLP_TAG_BITS + PC_BITS + NLP_CONF_BITS;
    localparam integer W_BpuQueueEntry  =
        PC_BITS
      + 1
      + 1
      + BR_TYPE_BITS
      + PC_BITS
      + 1
      + 1
      + PCPN_BITS
      + PCPN_BITS
      + (TAGE_TAG_BITS * TN_MAX)
      + (TAGE_IDX_BITS * TN_MAX)
      + 1
      + 1
      + BPU_SCL_META_SUM_BITS
      + (BPU_SCL_META_IDX_BITS * BPU_SCL_META_NTABLE)
      + 1
      + 1
      + 1
      + BPU_LOOP_META_IDX_BITS
      + BPU_LOOP_META_TAG_BITS;

    // BPU_TOP::Registers & Memory from simulator-front/front-end/BPU/BPU.h.
    reg [GHR_LENGTH-1:0]                         arch_ghr_reg;
    reg [GHR_LENGTH-1:0]                         spec_ghr_reg;
    reg [FH_N_MAX*TN_MAX*32-1:0]                 arch_fh_reg;
    reg [FH_N_MAX*TN_MAX*32-1:0]                 spec_fh_reg;
    reg [TAGE_SC_PATH_BITS-1:0]                  arch_path_reg;
    reg [TAGE_SC_PATH_BITS-1:0]                  spec_path_reg;
    reg [PC_BITS-1:0]                            arch_ras_stack [0:RAS_DEPTH-1];
    reg [PC_BITS-1:0]                            spec_ras_stack [0:RAS_DEPTH-1];
    reg [RAS_COUNT_BITS-1:0]                     arch_ras_count_reg;
    reg [RAS_COUNT_BITS-1:0]                     spec_ras_count_reg;
    reg [PC_BITS-1:0]                            pc_reg;
    reg [1:0]                                    state_reg;
    reg                                          do_pred_latch_reg;
    reg [BPU_BANK_NUM-1:0]                       do_upd_latch_reg;
    reg                                          pc_can_send_to_icache_reg;
    reg [PC_BITS-1:0]                            pred_base_pc_fired_reg;
    reg [FETCH_WIDTH-1:0]                        tage_calc_pred_dir_latch_reg;
    reg [FETCH_WIDTH-1:0]                        tage_calc_altpred_latch_reg;
    reg [FETCH_WIDTH*PCPN_BITS-1:0]              tage_calc_pcpn_latch_reg;
    reg [FETCH_WIDTH*PCPN_BITS-1:0]              tage_calc_altpcpn_latch_reg;
    reg [FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0]   tage_pred_calc_tags_latch_reg;
    reg [FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0]   tage_pred_calc_idxs_latch_reg;
    reg [FETCH_WIDTH-1:0]                        tage_result_valid_latch_reg;
    reg [FETCH_WIDTH*PC_BITS-1:0]                btb_pred_target_latch_reg;
    reg [FETCH_WIDTH-1:0]                        btb_result_valid_latch_reg;
    reg [BPU_BANK_NUM-1:0]                       tage_done_reg;
    reg [BPU_BANK_NUM-1:0]                       btb_done_reg;
    reg [W_BpuQueueEntry-1:0]                    update_queue [0:(Q_DEPTH*BPU_BANK_NUM)-1];
    reg [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]        q_wr_ptr_reg;
    reg [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]        q_rd_ptr_reg;
    reg [BPU_BANK_NUM*QUEUE_COUNT_BITS-1:0]      q_count_reg;
    reg [W_NlpEntry-1:0]                         nlp_table [0:NLP_TABLE_SIZE-1];
    reg [PC_BITS-1:0]                            saved_2ahead_prediction_reg;
    reg                                          saved_2ahead_pred_valid_reg;
    reg                                          saved_mini_flush_req_reg;
    reg                                          saved_mini_flush_correct_reg;
    reg [PC_BITS-1:0]                            saved_mini_flush_target_reg;
    reg                                          nlp_s1_valid_reg;
    reg [PC_BITS-1:0]                            nlp_s1_req_pc_reg;
    reg [PC_BITS-1:0]                            nlp_s1_pred_next_pc_reg;
    reg                                          nlp_s1_hit_reg;
    reg [NLP_CONF_BITS-1:0]                      nlp_s1_conf_reg;
    reg                                          nlp_s2_valid_reg;
    reg [PC_BITS-1:0]                            nlp_s2_req_pc_reg;
    reg [PC_BITS-1:0]                            nlp_s2_pred_2ahead_pc_reg;
    reg                                          nlp_s2_hit_reg;
    reg [NLP_CONF_BITS-1:0]                      nlp_s2_conf_reg;

    // These next-state wires mirror BPU_TOP::UpdateRequest fields. They hold
    // state until the corresponding BPU comb BSD logic exposes real updates.
    wire [GHR_LENGTH-1:0]                       arch_ghr_next                    = arch_ghr_reg;
    wire [GHR_LENGTH-1:0]                       spec_ghr_next                    = spec_ghr_reg;
    wire [FH_N_MAX*TN_MAX*32-1:0]               arch_fh_next                     = arch_fh_reg;
    wire [FH_N_MAX*TN_MAX*32-1:0]               spec_fh_next                     = spec_fh_reg;
    wire [TAGE_SC_PATH_BITS-1:0]                arch_path_next                   = arch_path_reg;
    wire [TAGE_SC_PATH_BITS-1:0]                spec_path_next                   = spec_path_reg;
    wire [RAS_COUNT_BITS-1:0]                   arch_ras_count_next              = arch_ras_count_reg;
    wire [RAS_COUNT_BITS-1:0]                   spec_ras_count_next              = spec_ras_count_reg;
    wire [PC_BITS-1:0]                          pc_reg_next                      = pc_reg;
    wire [1:0]                                  state_next                       = state_reg;
    wire                                        do_pred_latch_next               = do_pred_latch_reg;
    wire [BPU_BANK_NUM-1:0]                     do_upd_latch_next                = do_upd_latch_reg;
    wire                                        pc_can_send_to_icache_next       = pc_can_send_to_icache_reg;
    wire [PC_BITS-1:0]                          pred_base_pc_fired_next          = pred_base_pc_fired_reg;
    wire [FETCH_WIDTH-1:0]                      tage_calc_pred_dir_latch_next    = tage_calc_pred_dir_latch_reg;
    wire [FETCH_WIDTH-1:0]                      tage_calc_altpred_latch_next     = tage_calc_altpred_latch_reg;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]            tage_calc_pcpn_latch_next        = tage_calc_pcpn_latch_reg;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]            tage_calc_altpcpn_latch_next     = tage_calc_altpcpn_latch_reg;
    wire [FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0] tage_pred_calc_tags_latch_next   = tage_pred_calc_tags_latch_reg;
    wire [FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0] tage_pred_calc_idxs_latch_next   = tage_pred_calc_idxs_latch_reg;
    wire [FETCH_WIDTH-1:0]                      tage_result_valid_latch_next     = tage_result_valid_latch_reg;
    wire [FETCH_WIDTH*PC_BITS-1:0]              btb_pred_target_latch_next       = btb_pred_target_latch_reg;
    wire [FETCH_WIDTH-1:0]                      btb_result_valid_latch_next      = btb_result_valid_latch_reg;
    wire [BPU_BANK_NUM-1:0]                     tage_done_next                   = tage_done_reg;
    wire [BPU_BANK_NUM-1:0]                     btb_done_next                    = btb_done_reg;
    wire [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]      q_wr_ptr_next                    = q_wr_ptr_reg;
    wire [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]      q_rd_ptr_next                    = q_rd_ptr_reg;
    wire [BPU_BANK_NUM*QUEUE_COUNT_BITS-1:0]    q_count_next                     = q_count_reg;
    wire [PC_BITS-1:0]                          saved_2ahead_prediction_next     = saved_2ahead_prediction_reg;
    wire                                        saved_2ahead_pred_valid_next     = saved_2ahead_pred_valid_reg;
    wire                                        saved_mini_flush_req_next        = saved_mini_flush_req_reg;
    wire                                        saved_mini_flush_correct_next    = saved_mini_flush_correct_reg;
    wire [PC_BITS-1:0]                          saved_mini_flush_target_next     = saved_mini_flush_target_reg;
    wire                                        nlp_s1_valid_next                = nlp_s1_valid_reg;
    wire [PC_BITS-1:0]                          nlp_s1_req_pc_next               = nlp_s1_req_pc_reg;
    wire [PC_BITS-1:0]                          nlp_s1_pred_next_pc_next         = nlp_s1_pred_next_pc_reg;
    wire                                        nlp_s1_hit_next                  = nlp_s1_hit_reg;
    wire [NLP_CONF_BITS-1:0]                    nlp_s1_conf_next                 = nlp_s1_conf_reg;
    wire                                        nlp_s2_valid_next                = nlp_s2_valid_reg;
    wire [PC_BITS-1:0]                          nlp_s2_req_pc_next               = nlp_s2_req_pc_reg;
    wire [PC_BITS-1:0]                          nlp_s2_pred_2ahead_pc_next       = nlp_s2_pred_2ahead_pc_reg;
    wire                                        nlp_s2_hit_next                  = nlp_s2_hit_reg;
    wire [NLP_CONF_BITS-1:0]                    nlp_s2_conf_next                 = nlp_s2_conf_reg;

    wire [W_BpuOut-1:0] bpu_pre_read_req_payload;
    wire [W_BpuOut-1:0] bpu_post_read_req_payload;

    wire [W_BpuOut-1:0] type_predictor_pre_read_payload;
    wire [W_BpuOut-1:0] type_pred_input_bundle;
    wire [W_BpuOut-1:0] type_pred_payload;

    wire [W_BpuOut-1:0] tage_pre_read_payload;
    wire [W_BpuOut-1:0] tage_input_bundle;
    wire [W_BpuOut-1:0] tage_payload;

    wire [W_BpuOut-1:0] btb_pre_read_payload;
    wire [W_BpuOut-1:0] btb_post_read_req_input_bundle;
    wire [W_BpuOut-1:0] btb_post_read_req_payload;
    wire [W_BpuOut-1:0] btb_payload;

    wire [W_BpuOut-1:0] bpu_submodule_bind_input_bundle;
    wire [W_BpuOut-1:0] bpu_submodule_bind_payload;
    wire [W_BpuOut-1:0] bpu_predict_main_payload;
    wire [W_BpuOut-1:0] bpu_hist_payload;
    wire [W_BpuOut-1:0] bpu_queue_payload;

    assign type_pred_input_bundle            = type_predictor_pre_read_payload | bpu_post_read_req_payload;
    assign tage_input_bundle                 = tage_pre_read_payload           | bpu_post_read_req_payload;
    assign btb_post_read_req_input_bundle    = btb_pre_read_payload            | bpu_post_read_req_payload;
    assign bpu_submodule_bind_input_bundle   = type_pred_payload               | tage_payload | btb_payload;

    bpu_pre_read_req_comb_top #(
        .W_BpuPreReadReqCombIn(W_BpuIn),
        .W_BpuPreReadReqCombOut(W_BpuOut)
    ) u_bpu_pre_read_req_comb_top (
        .bpu_input_bundle(bpu_in),
        .bpu_pre_read_req_bundle(bpu_pre_read_req_payload)
    );

    type_predictor_pre_read_comb_top #(
        .W_TypePredictorPreReadCombIn(W_BpuOut),
        .W_TypePredictorPreReadCombOut(W_BpuOut)
    ) u_type_predictor_pre_read_comb_top (
        .bpu_pre_read_req_bundle(bpu_pre_read_req_payload),
        .type_predictor_pre_read_bundle(type_predictor_pre_read_payload)
    );

    tage_pre_read_comb_top #(
        .W_TagePreReadCombIn(W_BpuOut),
        .W_TagePreReadCombOut(W_BpuOut)
    ) u_tage_pre_read_comb_top (
        .bpu_pre_read_req_bundle(bpu_pre_read_req_payload),
        .tage_pre_read_bundle(tage_pre_read_payload)
    );

    btb_pre_read_comb_top #(
        .W_BtbPreReadCombIn(W_BpuOut),
        .W_BtbPreReadCombOut(W_BpuOut)
    ) u_btb_pre_read_comb_top (
        .bpu_pre_read_req_bundle(bpu_pre_read_req_payload),
        .btb_pre_read_bundle(btb_pre_read_payload)
    );

    bpu_post_read_req_comb_top #(
        .W_BpuPostReadReqCombIn(W_BpuOut),
        .W_BpuPostReadReqCombOut(W_BpuOut)
    ) u_bpu_post_read_req_comb_top (
        .bpu_pre_read_req_bundle(bpu_pre_read_req_payload),
        .bpu_post_read_req_bundle(bpu_post_read_req_payload)
    );

    type_pred_comb_top #(
        .W_TypePredCombIn(W_BpuOut),
        .W_TypePredCombOut(W_BpuOut)
    ) u_type_pred_comb_top (
        .type_pred_input_bundle(type_pred_input_bundle),
        .type_pred_bundle(type_pred_payload)
    );

    tage_comb_top #(
        .W_TageCombIn(W_BpuOut),
        .W_TageCombOut(W_BpuOut)
    ) u_tage_comb_top (
        .tage_input_bundle(tage_input_bundle),
        .tage_bundle(tage_payload)
    );

    btb_post_read_req_comb_top #(
        .W_BtbPostReadReqCombIn(W_BpuOut),
        .W_BtbPostReadReqCombOut(W_BpuOut)
    ) u_btb_post_read_req_comb_top (
        .btb_post_read_req_input_bundle(btb_post_read_req_input_bundle),
        .btb_post_read_req_bundle(btb_post_read_req_payload)
    );

    btb_comb_top #(
        .W_BtbCombIn(W_BpuOut),
        .W_BtbCombOut(W_BpuOut)
    ) u_btb_comb_top (
        .btb_post_read_req_bundle(btb_post_read_req_payload),
        .btb_bundle(btb_payload)
    );

    bpu_submodule_bind_comb_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuOut),
        .W_BpuSubmoduleBindCombOut(W_BpuOut)
    ) u_bpu_submodule_bind_comb_top (
        .bpu_submodule_bind_input_bundle(bpu_submodule_bind_input_bundle),
        .bpu_submodule_bind_bundle(bpu_submodule_bind_payload)
    );

    bpu_predict_main_comb_top #(
        .W_BpuPredictMainCombIn(W_BpuOut),
        .W_BpuPredictMainCombOut(W_BpuOut)
    ) u_bpu_predict_main_comb_top (
        .bpu_submodule_bind_bundle(bpu_submodule_bind_payload),
        .bpu_predict_main_bundle(bpu_predict_main_payload)
    );

    bpu_hist_comb_top #(
        .W_BpuHistCombIn(W_BpuOut),
        .W_BpuHistCombOut(W_BpuOut)
    ) u_bpu_hist_comb_top (
        .bpu_predict_main_bundle(bpu_predict_main_payload),
        .bpu_hist_bundle(bpu_hist_payload)
    );

    bpu_queue_comb_top #(
        .W_BpuQueueCombIn(W_BpuOut),
        .W_BpuQueueCombOut(W_BpuOut)
    ) u_bpu_queue_comb_top (
        .bpu_predict_main_bundle(bpu_predict_main_payload),
        .bpu_queue_bundle(bpu_queue_payload)
    );

    integer bpu_state_i;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn || reset) begin
            arch_ghr_reg <= {GHR_LENGTH{1'b0}};
            spec_ghr_reg <= {GHR_LENGTH{1'b0}};
            arch_fh_reg <= {(FH_N_MAX*TN_MAX*32){1'b0}};
            spec_fh_reg <= {(FH_N_MAX*TN_MAX*32){1'b0}};
            arch_path_reg <= {TAGE_SC_PATH_BITS{1'b0}};
            spec_path_reg <= {TAGE_SC_PATH_BITS{1'b0}};
            arch_ras_count_reg <= {RAS_COUNT_BITS{1'b0}};
            spec_ras_count_reg <= {RAS_COUNT_BITS{1'b0}};
            pc_reg <= RESET_PC;
            state_reg <= S_IDLE;
            do_pred_latch_reg <= 1'b0;
            do_upd_latch_reg <= {BPU_BANK_NUM{1'b0}};
            pc_can_send_to_icache_reg <= 1'b1;
            pred_base_pc_fired_reg <= {PC_BITS{1'b0}};
            tage_calc_pred_dir_latch_reg <= {FETCH_WIDTH{1'b0}};
            tage_calc_altpred_latch_reg <= {FETCH_WIDTH{1'b0}};
            tage_calc_pcpn_latch_reg <= {(FETCH_WIDTH*PCPN_BITS){1'b0}};
            tage_calc_altpcpn_latch_reg <= {(FETCH_WIDTH*PCPN_BITS){1'b0}};
            tage_pred_calc_tags_latch_reg <= {(FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS){1'b0}};
            tage_pred_calc_idxs_latch_reg <= {(FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS){1'b0}};
            tage_result_valid_latch_reg <= {FETCH_WIDTH{1'b0}};
            btb_pred_target_latch_reg <= {(FETCH_WIDTH*PC_BITS){1'b0}};
            btb_result_valid_latch_reg <= {FETCH_WIDTH{1'b0}};
            tage_done_reg <= {BPU_BANK_NUM{1'b0}};
            btb_done_reg <= {BPU_BANK_NUM{1'b0}};
            q_wr_ptr_reg <= {(BPU_BANK_NUM*QUEUE_PTR_BITS){1'b0}};
            q_rd_ptr_reg <= {(BPU_BANK_NUM*QUEUE_PTR_BITS){1'b0}};
            q_count_reg <= {(BPU_BANK_NUM*QUEUE_COUNT_BITS){1'b0}};
            saved_2ahead_prediction_reg <= RESET_PC + (FETCH_WIDTH * 4);
            saved_2ahead_pred_valid_reg <= 1'b0;
            saved_mini_flush_req_reg <= 1'b0;
            saved_mini_flush_correct_reg <= 1'b0;
            saved_mini_flush_target_reg <= {PC_BITS{1'b0}};
            nlp_s1_valid_reg <= 1'b0;
            nlp_s1_req_pc_reg <= {PC_BITS{1'b0}};
            nlp_s1_pred_next_pc_reg <= {PC_BITS{1'b0}};
            nlp_s1_hit_reg <= 1'b0;
            nlp_s1_conf_reg <= {NLP_CONF_BITS{1'b0}};
            nlp_s2_valid_reg <= 1'b0;
            nlp_s2_req_pc_reg <= {PC_BITS{1'b0}};
            nlp_s2_pred_2ahead_pc_reg <= {PC_BITS{1'b0}};
            nlp_s2_hit_reg <= 1'b0;
            nlp_s2_conf_reg <= {NLP_CONF_BITS{1'b0}};
            for (bpu_state_i = 0; bpu_state_i < RAS_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                arch_ras_stack[bpu_state_i] <= {PC_BITS{1'b0}};
                spec_ras_stack[bpu_state_i] <= {PC_BITS{1'b0}};
            end
            for (bpu_state_i = 0; bpu_state_i < NLP_TABLE_SIZE; bpu_state_i = bpu_state_i + 1) begin
                nlp_table[bpu_state_i] <= {W_NlpEntry{1'b0}};
            end
        end else begin
            arch_ghr_reg <= arch_ghr_next;
            spec_ghr_reg <= spec_ghr_next;
            arch_fh_reg <= arch_fh_next;
            spec_fh_reg <= spec_fh_next;
            arch_path_reg <= arch_path_next;
            spec_path_reg <= spec_path_next;
            arch_ras_count_reg <= arch_ras_count_next;
            spec_ras_count_reg <= spec_ras_count_next;
            pc_reg <= pc_reg_next;
            state_reg <= state_next;
            do_pred_latch_reg <= do_pred_latch_next;
            do_upd_latch_reg <= do_upd_latch_next;
            pc_can_send_to_icache_reg <= pc_can_send_to_icache_next;
            pred_base_pc_fired_reg <= pred_base_pc_fired_next;
            tage_calc_pred_dir_latch_reg <= tage_calc_pred_dir_latch_next;
            tage_calc_altpred_latch_reg <= tage_calc_altpred_latch_next;
            tage_calc_pcpn_latch_reg <= tage_calc_pcpn_latch_next;
            tage_calc_altpcpn_latch_reg <= tage_calc_altpcpn_latch_next;
            tage_pred_calc_tags_latch_reg <= tage_pred_calc_tags_latch_next;
            tage_pred_calc_idxs_latch_reg <= tage_pred_calc_idxs_latch_next;
            tage_result_valid_latch_reg <= tage_result_valid_latch_next;
            btb_pred_target_latch_reg <= btb_pred_target_latch_next;
            btb_result_valid_latch_reg <= btb_result_valid_latch_next;
            tage_done_reg <= tage_done_next;
            btb_done_reg <= btb_done_next;
            q_wr_ptr_reg <= q_wr_ptr_next;
            q_rd_ptr_reg <= q_rd_ptr_next;
            q_count_reg <= q_count_next;
            saved_2ahead_prediction_reg <= saved_2ahead_prediction_next;
            saved_2ahead_pred_valid_reg <= saved_2ahead_pred_valid_next;
            saved_mini_flush_req_reg <= saved_mini_flush_req_next;
            saved_mini_flush_correct_reg <= saved_mini_flush_correct_next;
            saved_mini_flush_target_reg <= saved_mini_flush_target_next;
            nlp_s1_valid_reg <= nlp_s1_valid_next;
            nlp_s1_req_pc_reg <= nlp_s1_req_pc_next;
            nlp_s1_pred_next_pc_reg <= nlp_s1_pred_next_pc_next;
            nlp_s1_hit_reg <= nlp_s1_hit_next;
            nlp_s1_conf_reg <= nlp_s1_conf_next;
            nlp_s2_valid_reg <= nlp_s2_valid_next;
            nlp_s2_req_pc_reg <= nlp_s2_req_pc_next;
            nlp_s2_pred_2ahead_pc_reg <= nlp_s2_pred_2ahead_pc_next;
            nlp_s2_hit_reg <= nlp_s2_hit_next;
            nlp_s2_conf_reg <= nlp_s2_conf_next;
        end
    end

    assign bpu_out = bpu_predict_main_payload | bpu_hist_payload | bpu_queue_payload;

endmodule
