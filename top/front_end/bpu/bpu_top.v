// BPU 分组顶层，用于前端 comb 训练边界连接。
// 源码依据：simulator-front/front-end/BPU/BPU.h。
// comb 实例使用语义变量端口；每个 wrapper 内部再拼接 pi/po。
//
// 阅读顺序：
// 1. 先看参数和 localparam，确认 simulator-front 默认配置下的位宽。
// 2. 再看 BPU_TOP 级别寄存器壳，确认哪些状态需要周期末写回。
// 3. 然后看 13 个 BPU comb wrapper 的调用链。
// 4. 最后看 always 块，理解 rst_n/reset 和普通运行时的状态更新关系。
//
// 当前状态：
// - bpu_top 已经保留 BPU_TOP 级别状态寄存器和复位初值。
// - 13 个 BPU comb 的真实预测/更新逻辑仍在各自 *_bsd_top 内占位。
// - 因此本文件当前主要用于端口、位宽和调用顺序交付，不代表 BPU 功能已经完整。

module bpu_top #(
    parameter FETCH_WIDTH             = 16,
    parameter COMMIT_WIDTH            = 8,
    parameter TN_MAX                  = 4,
    parameter PC_BITS                 = 32,
    parameter PCPN_BITS               = 3,
    parameter BR_TYPE_BITS            = 3,
    parameter TAGE_IDX_BITS           = 12,
    parameter TAGE_TAG_BITS           = 8,
    parameter BPU_SCL_META_NTABLE     = 8,
    parameter BPU_SCL_META_IDX_BITS   = 16,
    parameter BPU_SCL_META_SUM_BITS   = 16,
    parameter BPU_LOOP_META_IDX_BITS  = 16,
    parameter BPU_LOOP_META_TAG_BITS  = 16,
    parameter BPU_BANK_NUM            = FETCH_WIDTH,
    parameter Q_DEPTH                 = 500,
    parameter GHR_LENGTH              = 512,
    parameter FH_N_MAX                = 3,
    parameter RAS_DEPTH               = 64,
    parameter TAGE_SC_PATH_BITS       = 16,
    parameter NLP_TABLE_SIZE          = 4096,
    parameter NLP_CONF_BITS           = 2,
    parameter RESET_PC                = 32'h0000_0000,
    parameter W_BpuIn                 = 2738,  // 实际：2738, BPU_TOP::InputPayload
    parameter W_BpuOut                = 4470    // 实际：4470, BPU_TOP::OutputPayload
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                reset,
    input  wire [W_BpuIn-1:0]  bpu_in,
    output wire [W_BpuOut-1:0] bpu_out
);

    localparam S_IDLE    = 2'd0;
    localparam S_WORKING = 2'd1;
    localparam S_REFETCH = 2'd2;

    // 当前 default 配置下的手工展开位宽。
    // Q_DEPTH=500，需要 9 位索引和计数；RAS_DEPTH=64，计数需要 7 位。
    // 这里不用自定义函数，避免在交付 RTL 里引入额外语法。
    localparam QUEUE_PTR_BITS   = 9;
    localparam QUEUE_COUNT_BITS = 9;
    localparam RAS_COUNT_BITS   = 7;
    localparam BPU_BANK_SEL_BITS = 4;
    localparam BPU_BANK_SEL_EXT_BITS = 5;
    localparam RAS_INDEX_BITS   = 6;
    localparam NLP_INDEX_BITS   = 12;
    localparam NLP_TAG_BITS     = 30;
    localparam W_NlpEntry       = 1 + NLP_TAG_BITS + PC_BITS + NLP_CONF_BITS;
    localparam W_BpuQueueEntry  =
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

    // simulator-front 默认配置下的正式 comb 输入/输出位宽。
    // 这些是 BSD pi/po 的打包位宽，不是临时路由总线宽度。
    localparam W_BpuPreReadReqCombIn          = 369;    // BPU_TOP::BpuPreReadReqCombIn
    localparam W_BpuPreReadReqCombOut         = 875;    // BPU_TOP::BpuPreReadReqCombOut
    localparam W_TypePredictorPreReadCombIn   = 816;    // TypePredictor::InputPayload
    localparam W_TypePredictorPreReadCombOut  = 672;    // TypePredictor::PreReadCombOut
    // tage_reset_ctr_t 按 TAGE_IDX_WIDTH + 11 计算，不按 wire32_t 计算。
    localparam W_TagePreReadCombIn            = 2528;   // TAGE_TOP::TagePreReadCombIn
    localparam W_TagePreReadCombOut           = 579;    // TAGE_TOP::TagePreReadCombOut
    localparam W_BtbPreReadCombIn             = 105;    // BTB_TOP::BtbPreReadCombIn
    localparam W_BtbPreReadCombOut            = 228;    // BTB_TOP::BtbPreReadCombOut
    localparam W_BpuPostReadReqCombIn         = 7332;   // BPU_TOP::BpuPostReadReqCombIn
    localparam W_BpuPostReadReqCombOut        = 22509;  // BPU_TOP::BpuPostReadReqCombOut
    localparam W_TypePredCombIn               = 2448;   // TypePredictor::TypePredCombIn
    localparam W_TypePredCombOut              = 376;    // TypePredictor::TypePredCombOut
    localparam W_TageCombIn                   = 3329;   // TAGE_TOP::TageCombIn，tage_path_hist_t 按 TAGE_SC_PATH_BITS 计算
    localparam W_TageCombOut                  = 1932;   // TAGE_TOP::TageCombOut
    localparam W_BtbPostReadReqCombIn         = 2264;   // BTB_TOP::BtbPostReadReqCombIn
    localparam W_BtbPostReadReqCombOut        = 45;     // BTB_TOP::BtbPostReadReqCombOut
    localparam W_BtbCombIn                    = 2264;   // BTB_TOP::BtbCombIn
    localparam W_BtbCombOut                   = 1089;   // BTB_TOP::BtbCombOut
    localparam W_BpuSubmoduleBindCombIn       = 1856;   // BPU_TOP::BpuSubmoduleBindCombIn
    localparam W_BpuSubmoduleBindCombOut      = 1680;   // BPU_TOP::BpuSubmoduleBindCombOut
    localparam W_BpuPredictMainCombIn         = 5798;   // BPU_TOP::BpuPredictMainCombIn
    localparam W_BpuPredictMainCombOut        = 6502;   // BPU_TOP::BpuPredictMainCombOut
    localparam W_BpuHistCombIn                = 6944;   // BPU_TOP::BpuHistCombIn
    localparam W_BpuHistCombOut               = 5935;   // BPU_TOP::BpuHistCombOut
    localparam W_BpuQueueCombIn               = 3152;   // BPU_TOP::BpuQueueCombIn
    localparam W_BpuQueueCombOut              = 3281;   // BPU_TOP::BpuQueueCombOut

    // BPU_TOP::InputPayload / OutputPayload 中几个关键子结构的位宽。
    // 这些不是新的接口，只是为了让下面的拼接按 C++ 字段名展开，避免继续低位硬截。
    localparam W_BpuInputUpdateBasePc  = COMMIT_WIDTH * PC_BITS;
    localparam W_BpuInputUpdValid      = COMMIT_WIDTH;
    localparam W_BpuInputActualDir     = COMMIT_WIDTH;
    localparam W_BpuInputActualType    = COMMIT_WIDTH * BR_TYPE_BITS;
    localparam W_BpuInputActualTarget  = COMMIT_WIDTH * PC_BITS;
    localparam W_BpuInputPredDir       = COMMIT_WIDTH;
    localparam W_BpuInputAltPred       = COMMIT_WIDTH;
    localparam W_BpuInputPcpn          = COMMIT_WIDTH * PCPN_BITS;
    localparam W_BpuInputAltPcpn       = COMMIT_WIDTH * PCPN_BITS;
    localparam W_BpuInputTageTags      = COMMIT_WIDTH * TN_MAX * TAGE_TAG_BITS;
    localparam W_BpuInputTageIdxs      = COMMIT_WIDTH * TN_MAX * TAGE_IDX_BITS;
    localparam W_BpuInputScUsed        = COMMIT_WIDTH;
    localparam W_BpuInputScPred        = COMMIT_WIDTH;
    localparam W_BpuInputScSum         = COMMIT_WIDTH * BPU_SCL_META_SUM_BITS;
    localparam W_BpuInputScIdx         = COMMIT_WIDTH * BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS;
    localparam W_BpuInputLoopUsed      = COMMIT_WIDTH;
    localparam W_BpuInputLoopHit       = COMMIT_WIDTH;
    localparam W_BpuInputLoopPred      = COMMIT_WIDTH;
    localparam W_BpuInputLoopIdx       = COMMIT_WIDTH * BPU_LOOP_META_IDX_BITS;
    localparam W_BpuInputLoopTag       = COMMIT_WIDTH * BPU_LOOP_META_TAG_BITS;
    localparam W_TypeInputPayload      = W_TypePredictorPreReadCombIn;
    localparam W_TageInputPayload      = 1248;
    localparam W_BtbInputPayload       = W_BtbPreReadCombIn;
    localparam W_TypeOutputPayload     = 80;
    localparam W_TageOutputPayload     = 272;
    localparam W_BtbOutputPayload      = 35;
    localparam W_TageCombResult        = W_TageCombOut - W_TageOutputPayload;
    localparam W_BtbCombResult         = W_BtbCombOut - W_BtbOutputPayload;

    // BPU_TOP 中的寄存器和存储结构，依据 simulator-front/front-end/BPU/BPU.h。
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

    // BPU_TOP::InputPayload 按 BPU.h 字段顺序拆开。
    // front_bpu_control_comb 已经把外部 BPU_in 转成 InputPayload，这里不再把 reset 拼进 BPU 输入。
    wire                                        bpu_in_refetch;
    wire [PC_BITS-1:0]                         bpu_in_refetch_address;
    wire                                        bpu_in_icache_read_ready;
    wire [W_BpuInputUpdateBasePc-1:0]           bpu_in_update_base_pc;
    wire [W_BpuInputUpdValid-1:0]               bpu_in_upd_valid;
    wire [W_BpuInputActualDir-1:0]              bpu_in_actual_dir;
    wire [W_BpuInputActualType-1:0]             bpu_in_actual_br_type;
    wire [W_BpuInputActualTarget-1:0]           bpu_in_actual_targets;
    wire [W_BpuInputPredDir-1:0]                bpu_in_pred_dir;
    wire [W_BpuInputAltPred-1:0]                bpu_in_alt_pred;
    wire [W_BpuInputPcpn-1:0]                   bpu_in_pcpn;
    wire [W_BpuInputAltPcpn-1:0]                bpu_in_altpcpn;
    wire [W_BpuInputTageTags-1:0]               bpu_in_tage_tags;
    wire [W_BpuInputTageIdxs-1:0]               bpu_in_tage_idxs;
    wire [W_BpuInputScUsed-1:0]                 bpu_in_sc_used;
    wire [W_BpuInputScPred-1:0]                 bpu_in_sc_pred;
    wire [W_BpuInputScSum-1:0]                  bpu_in_sc_sum;
    wire [W_BpuInputScIdx-1:0]                  bpu_in_sc_idx;
    wire [W_BpuInputLoopUsed-1:0]               bpu_in_loop_used;
    wire [W_BpuInputLoopHit-1:0]                bpu_in_loop_hit;
    wire [W_BpuInputLoopPred-1:0]               bpu_in_loop_pred;
    wire [W_BpuInputLoopIdx-1:0]                bpu_in_loop_idx;
    wire [W_BpuInputLoopTag-1:0]                bpu_in_loop_tag;
    assign {
        bpu_in_refetch,
        bpu_in_refetch_address,
        bpu_in_icache_read_ready,
        bpu_in_update_base_pc,
        bpu_in_upd_valid,
        bpu_in_actual_dir,
        bpu_in_actual_br_type,
        bpu_in_actual_targets,
        bpu_in_pred_dir,
        bpu_in_alt_pred,
        bpu_in_pcpn,
        bpu_in_altpcpn,
        bpu_in_tage_tags,
        bpu_in_tage_idxs,
        bpu_in_sc_used,
        bpu_in_sc_pred,
        bpu_in_sc_sum,
        bpu_in_sc_idx,
        bpu_in_loop_used,
        bpu_in_loop_hit,
        bpu_in_loop_pred,
        bpu_in_loop_idx,
        bpu_in_loop_tag
    } = bpu_in;

    // BPU_TOP::UpdateRequest 对应的周期末写回值。
    // 这里把 27 个 comb 产生的请求收束到真正的 BPU 顶层寄存器。
    wire [GHR_LENGTH-1:0]                       arch_ghr_next                    = hist_arch_ghr_next;
    wire [GHR_LENGTH-1:0]                       spec_ghr_next                    = bpu_in_refetch ? hist_arch_ghr_next : hist_spec_ghr_next;
    wire [FH_N_MAX*TN_MAX*32-1:0]               arch_fh_next                     = hist_arch_fh_next;
    wire [FH_N_MAX*TN_MAX*32-1:0]               spec_fh_next                     = bpu_in_refetch ? hist_arch_fh_next : hist_spec_fh_next;
    wire [TAGE_SC_PATH_BITS-1:0]                arch_path_next                   = hist_arch_path_next;
    wire [TAGE_SC_PATH_BITS-1:0]                spec_path_next                   = bpu_in_refetch ? hist_arch_path_next : hist_spec_path_next;
    wire [RAS_COUNT_BITS-1:0]                   arch_ras_count_next              = hist_arch_ras_count_next;
    wire [RAS_COUNT_BITS-1:0]                   spec_ras_count_next              = bpu_in_refetch ? hist_arch_ras_count_next : hist_spec_ras_count_next;
    wire [PC_BITS-1:0]                          pc_reg_next                      = bpu_in_refetch ? bpu_in_refetch_address : (pre_going_to_do_pred ? predict_next_fetch_addr_calc : pc_reg);
    wire [1:0]                                  state_next                       = S_IDLE;
    wire                                        do_pred_latch_next               = 1'b0;
    wire [BPU_BANK_NUM-1:0]                     do_upd_latch_next                = {BPU_BANK_NUM{1'b0}};
    wire                                        pc_can_send_to_icache_next       = (bpu_in_refetch || pre_going_to_do_pred) ? 1'b1 : pc_can_send_to_icache_reg;
    wire [PC_BITS-1:0]                          pred_base_pc_fired_next          = pre_pred_base_pc;
    wire [FETCH_WIDTH-1:0]                      tage_calc_pred_dir_latch_next    = predict_tage_calc_pred_dir_latch_next;
    wire [FETCH_WIDTH-1:0]                      tage_calc_altpred_latch_next     = predict_tage_calc_altpred_latch_next;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]            tage_calc_pcpn_latch_next        = predict_tage_calc_pcpn_latch_next;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]            tage_calc_altpcpn_latch_next     = predict_tage_calc_altpcpn_latch_next;
    wire [FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0] tage_pred_calc_tags_latch_next   = predict_tage_pred_calc_tags_latch_next;
    wire [FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0] tage_pred_calc_idxs_latch_next   = predict_tage_pred_calc_idxs_latch_next;
    wire [FETCH_WIDTH-1:0]                      tage_result_valid_latch_next     = predict_tage_result_valid_latch_next;
    wire [FETCH_WIDTH*PC_BITS-1:0]              btb_pred_target_latch_next       = predict_btb_pred_target_latch_next;
    wire [FETCH_WIDTH-1:0]                      btb_result_valid_latch_next      = predict_btb_result_valid_latch_next;
    wire [BPU_BANK_NUM-1:0]                     tage_done_next                   = {BPU_BANK_NUM{1'b0}};
    wire [BPU_BANK_NUM-1:0]                     btb_done_next                    = {BPU_BANK_NUM{1'b0}};
    wire [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]      q_wr_ptr_next                    = queue_q_wr_ptr_next;
    wire [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]      q_rd_ptr_next                    = queue_q_rd_ptr_next;
    wire [BPU_BANK_NUM*QUEUE_COUNT_BITS-1:0]    q_count_next                     = queue_q_count_next;
    wire [PC_BITS-1:0]                          saved_2ahead_prediction_next     = bpu_in_refetch ? (bpu_in_refetch_address + (FETCH_WIDTH * 4)) : saved_2ahead_prediction_reg;
    wire                                        saved_2ahead_pred_valid_next     = bpu_in_refetch ? 1'b0 : saved_2ahead_pred_valid_reg;
    wire                                        saved_mini_flush_req_next        = bpu_in_refetch ? 1'b0 : saved_mini_flush_req_reg;
    wire                                        saved_mini_flush_correct_next    = bpu_in_refetch ? 1'b0 : saved_mini_flush_correct_reg;
    wire [PC_BITS-1:0]                          saved_mini_flush_target_next     = bpu_in_refetch ? {PC_BITS{1'b0}} : saved_mini_flush_target_reg;
    wire                                        nlp_s1_valid_next                = 1'b0;
    wire [PC_BITS-1:0]                          nlp_s1_req_pc_next               = {PC_BITS{1'b0}};
    wire [PC_BITS-1:0]                          nlp_s1_pred_next_pc_next         = {PC_BITS{1'b0}};
    wire                                        nlp_s1_hit_next                  = 1'b0;
    wire [NLP_CONF_BITS-1:0]                    nlp_s1_conf_next                 = {NLP_CONF_BITS{1'b0}};
    wire                                        nlp_s2_valid_next                = 1'b0;
    wire [PC_BITS-1:0]                          nlp_s2_req_pc_next               = {PC_BITS{1'b0}};
    wire [PC_BITS-1:0]                          nlp_s2_pred_2ahead_pc_next       = {PC_BITS{1'b0}};
    wire                                        nlp_s2_hit_next                  = 1'b0;
    wire [NLP_CONF_BITS-1:0]                    nlp_s2_conf_next                 = {NLP_CONF_BITS{1'b0}};

    // BPU 组合链路的中间 bundle。
    // 命名按源码里的 comb 阶段保留，方便从 BPU.h 对照：
    // pre_read_req -> 各预测器 pre_read -> post_read_req -> 各预测器 comb
    // -> submodule_bind -> predict_main -> hist/queue。
    wire [W_BpuPreReadReqCombIn-1:0]        bpu_pre_read_req_input_bundle;
    wire [W_BpuPreReadReqCombOut-1:0]       bpu_pre_read_req_payload;
    wire [W_BpuPostReadReqCombIn-1:0]       bpu_post_read_req_input_bundle;
    wire [W_BpuPostReadReqCombOut-1:0]      bpu_post_read_req_payload;

    wire [W_TypePredictorPreReadCombIn-1:0]  type_predictor_pre_read_input_bundle;
    wire [W_TypePredictorPreReadCombOut-1:0] type_predictor_pre_read_payload;
    wire [W_TypePredCombIn-1:0]              type_pred_input_bundle;
    wire [W_TypePredCombOut-1:0]             type_pred_payload;

    wire [W_TagePreReadCombIn-1:0]         tage_pre_read_input_bundle;
    wire [W_TagePreReadCombOut-1:0]        tage_pre_read_payload;
    wire [W_TageCombIn-1:0]                tage_input_bundle;
    wire [W_TageCombOut-1:0]               tage_payload;

    wire [W_BtbPreReadCombIn-1:0]          btb_pre_read_input_bundle;
    wire [W_BtbPreReadCombOut-1:0]         btb_pre_read_payload;
    wire [W_BtbPostReadReqCombIn-1:0]      btb_post_read_req_input_bundle;
    wire [W_BtbPostReadReqCombOut-1:0]     btb_post_read_req_payload;
    wire [W_BtbCombIn-1:0]                 btb_input_bundle;
    wire [W_BtbCombOut-1:0]                btb_payload;

    wire [W_BpuSubmoduleBindCombIn-1:0]    bpu_submodule_bind_input_bundle;
    wire [W_BpuSubmoduleBindCombOut-1:0]   bpu_submodule_bind_payload;
    wire [W_BpuPredictMainCombIn-1:0]      bpu_predict_main_input_bundle;
    wire [W_BpuPredictMainCombOut-1:0]     bpu_predict_main_payload;
    wire [W_BpuHistCombIn-1:0]             bpu_hist_input_bundle;
    wire [W_BpuHistCombOut-1:0]            bpu_hist_payload;
    wire [W_BpuQueueCombIn-1:0]            bpu_queue_input_bundle;
    wire [W_BpuQueueCombOut-1:0]           bpu_queue_payload;

    // BPU 内部路由临时总线。
    // 当前各 BSD 逻辑仍是占位实现，部分下游 comb 只需要上游大 bundle 的局部字段。
    // 这里先显式拼成 route bundle，再按目标输入宽度取低位，避免 Verilog 隐式截断。
    // 后续真实 BSD 字段拆分完成后，应把这些 route bundle 替换成按源码字段名拼接的输入。
    wire pre_use_arch_ras_snapshot;
    wire [RAS_COUNT_BITS-1:0] pre_ras_count_snapshot;
    wire pre_ras_has_entry_snapshot;
    wire [RAS_INDEX_BITS-1:0] pre_ras_top_index;
    wire [PC_BITS-1:0] pre_pred_base_pc;
    wire [PC_BITS-1:0] pre_boundary_addr;
    wire [FETCH_WIDTH-1:0] pre_do_pred_on_this_pc;
    wire [FETCH_WIDTH*BPU_BANK_SEL_EXT_BITS-1:0] pre_this_pc_bank_sel;
    wire [FETCH_WIDTH*PC_BITS-1:0] pre_do_pred_for_this_pc;
    wire [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0] pre_q_read_slot;
    wire pre_going_to_do_pred;
    wire [BPU_BANK_NUM-1:0] pre_going_to_do_upd;
    wire pre_set_submodule_input;
    wire pre_nlp_pred_base_re;
    wire [NLP_INDEX_BITS-1:0] pre_nlp_pred_base_idx;
    wire pre_nlp_train_re;
    wire [NLP_INDEX_BITS-1:0] pre_nlp_train_idx;
    assign {
        pre_use_arch_ras_snapshot,
        pre_ras_count_snapshot,
        pre_ras_has_entry_snapshot,
        pre_ras_top_index,
        pre_pred_base_pc,
        pre_boundary_addr,
        pre_do_pred_on_this_pc,
        pre_this_pc_bank_sel,
        pre_do_pred_for_this_pc,
        pre_q_read_slot,
        pre_going_to_do_pred,
        pre_going_to_do_upd,
        pre_set_submodule_input,
        pre_nlp_pred_base_re,
        pre_nlp_pred_base_idx,
        pre_nlp_train_re,
        pre_nlp_train_idx
    } = bpu_pre_read_req_payload;

    wire [PC_BITS-1:0] ras_top_snapshot =
        pre_ras_has_entry_snapshot
            ? (pre_use_arch_ras_snapshot ? arch_ras_stack[pre_ras_top_index] : spec_ras_stack[pre_ras_top_index])
            : {PC_BITS{1'b0}};
    wire [W_NlpEntry-1:0] nlp_pred_base_entry_snapshot =
        pre_nlp_pred_base_re ? nlp_table[pre_nlp_pred_base_idx] : {W_NlpEntry{1'b0}};
    wire [BPU_BANK_NUM*W_BpuQueueEntry-1:0] queue_read_data_snapshot;
    wire [RAS_DEPTH*PC_BITS-1:0] arch_ras_stack_flat_snapshot;
    wire [RAS_DEPTH*PC_BITS-1:0] spec_ras_stack_flat_snapshot;

    genvar bpu_queue_read_g;
    generate
        for (bpu_queue_read_g = 0; bpu_queue_read_g < BPU_BANK_NUM; bpu_queue_read_g = bpu_queue_read_g + 1) begin : gen_bpu_queue_read
            wire [QUEUE_PTR_BITS-1:0] q_read_slot_this =
                pre_q_read_slot[bpu_queue_read_g*QUEUE_PTR_BITS +: QUEUE_PTR_BITS];
            assign queue_read_data_snapshot[bpu_queue_read_g*W_BpuQueueEntry +: W_BpuQueueEntry] =
                pre_going_to_do_upd[bpu_queue_read_g]
                    ? update_queue[(q_read_slot_this * BPU_BANK_NUM) + bpu_queue_read_g]
                    : {W_BpuQueueEntry{1'b0}};
        end
    endgenerate

    genvar bpu_ras_flat_g;
    generate
        for (bpu_ras_flat_g = 0; bpu_ras_flat_g < RAS_DEPTH; bpu_ras_flat_g = bpu_ras_flat_g + 1) begin : gen_bpu_ras_flat
            assign arch_ras_stack_flat_snapshot[bpu_ras_flat_g*PC_BITS +: PC_BITS] = arch_ras_stack[bpu_ras_flat_g];
            assign spec_ras_stack_flat_snapshot[bpu_ras_flat_g*PC_BITS +: PC_BITS] = spec_ras_stack[bpu_ras_flat_g];
        end
    endgenerate

    wire post_nlp_s1_re;
    wire [NLP_INDEX_BITS-1:0] post_nlp_s1_idx;
    wire [PC_BITS-1:0] post_nlp_s1_req_pc;
    wire [W_TypeInputPayload-1:0] post_type_in;
    wire [BPU_BANK_NUM*W_TageInputPayload-1:0] post_tage_in;
    wire [BPU_BANK_NUM*W_BtbInputPayload-1:0] post_btb_in;
    assign {
        post_nlp_s1_re,
        post_nlp_s1_idx,
        post_nlp_s1_req_pc,
        post_type_in,
        post_tage_in,
        post_btb_in
    } = bpu_post_read_req_payload;

    wire [W_TypeOutputPayload-1:0] type_output_payload =
        type_pred_payload[W_TypePredCombOut-1 -: W_TypeOutputPayload];
    wire [W_TageOutputPayload-1:0] tage_output_payload =
        tage_payload[W_TageCombOut-1 -: W_TageOutputPayload];
    wire [W_BtbOutputPayload-1:0] btb_output_payload =
        btb_payload[W_BtbCombOut-1 -: W_BtbOutputPayload];
    wire [BPU_BANK_NUM*W_TageOutputPayload-1:0] tage_output_payload_all =
        {BPU_BANK_NUM{tage_output_payload}};
    wire [BPU_BANK_NUM*W_BtbOutputPayload-1:0] btb_output_payload_all =
        {BPU_BANK_NUM{btb_output_payload}};

    // 组合链路输入拼接。
    // predict_main 输出拆分。
    // BpuPredictMainCombOut = out + final_pred_dir + next_fetch_addr_calc + ...
    wire [W_BpuOut-1:0]                         predict_output_payload;
    wire [FETCH_WIDTH-1:0]                      predict_final_pred_dir;
    wire [PC_BITS-1:0]                          predict_next_fetch_addr_calc;
    wire [PC_BITS-1:0]                          predict_final_2_ahead_address;
    wire [FETCH_WIDTH-1:0]                      predict_tage_calc_pred_dir_latch_next;
    wire [FETCH_WIDTH-1:0]                      predict_tage_calc_altpred_latch_next;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]            predict_tage_calc_pcpn_latch_next;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]            predict_tage_calc_altpcpn_latch_next;
    wire [FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0] predict_tage_pred_calc_tags_latch_next;
    wire [FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0] predict_tage_pred_calc_idxs_latch_next;
    wire [FETCH_WIDTH-1:0]                      predict_tage_result_valid_latch_next;
    wire [FETCH_WIDTH*PC_BITS-1:0]              predict_btb_pred_target_latch_next;
    wire [FETCH_WIDTH-1:0]                      predict_btb_result_valid_latch_next;
    assign {
        predict_output_payload,
        predict_final_pred_dir,
        predict_next_fetch_addr_calc,
        predict_final_2_ahead_address,
        predict_tage_calc_pred_dir_latch_next,
        predict_tage_calc_altpred_latch_next,
        predict_tage_calc_pcpn_latch_next,
        predict_tage_calc_altpcpn_latch_next,
        predict_tage_pred_calc_tags_latch_next,
        predict_tage_pred_calc_idxs_latch_next,
        predict_tage_result_valid_latch_next,
        predict_btb_pred_target_latch_next,
        predict_btb_result_valid_latch_next
    } = bpu_predict_main_payload;

    // hist 输出拆分。
    // 这些字段对应 BPU.h 里的 BpuHistCombOut，用来在周期末写回 BPU 历史状态。
    wire                                        hist_should_update_spec_hist;
    wire [GHR_LENGTH-1:0]                       hist_spec_ghr_next;
    wire [FH_N_MAX*TN_MAX*32-1:0]               hist_spec_fh_next;
    wire [GHR_LENGTH-1:0]                       hist_arch_ghr_next;
    wire [FH_N_MAX*TN_MAX*32-1:0]               hist_arch_fh_next;
    wire [TAGE_SC_PATH_BITS-1:0]                hist_spec_path_next;
    wire [TAGE_SC_PATH_BITS-1:0]                hist_arch_path_next;
    wire [RAS_DEPTH*PC_BITS-1:0]                hist_arch_ras_stack_next;
    wire [RAS_COUNT_BITS-1:0]                   hist_arch_ras_count_next;
    wire [RAS_DEPTH*PC_BITS-1:0]                hist_spec_ras_stack_next;
    wire [RAS_COUNT_BITS-1:0]                   hist_spec_ras_count_next;
    assign {
        hist_should_update_spec_hist,
        hist_spec_ghr_next,
        hist_spec_fh_next,
        hist_arch_ghr_next,
        hist_arch_fh_next,
        hist_spec_path_next,
        hist_arch_path_next,
        hist_arch_ras_stack_next,
        hist_arch_ras_count_next,
        hist_spec_ras_stack_next,
        hist_spec_ras_count_next
    } = bpu_hist_payload;

    // queue 输出拆分。
    // 这些字段对应 BPU.h 里的 BpuQueueCombOut，用来写回 update_queue 和读写指针。
    wire [BPU_BANK_NUM-1:0]                     queue_q_push_en;
    wire [BPU_BANK_NUM-1:0]                     queue_q_pop_en;
    wire [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]      queue_q_wr_ptr_next;
    wire [BPU_BANK_NUM*QUEUE_PTR_BITS-1:0]      queue_q_rd_ptr_next;
    wire [BPU_BANK_NUM*QUEUE_COUNT_BITS-1:0]    queue_q_count_next;
    wire [COMMIT_WIDTH-1:0]                     queue_q_entry_we;
    wire [COMMIT_WIDTH*BPU_BANK_SEL_BITS-1:0]   queue_q_entry_bank;
    wire [COMMIT_WIDTH*QUEUE_PTR_BITS-1:0]      queue_q_entry_slot;
    wire [COMMIT_WIDTH*W_BpuQueueEntry-1:0]     queue_q_entry_data;
    wire                                        queue_update_queue_full;
    assign {
        queue_q_push_en,
        queue_q_pop_en,
        queue_q_wr_ptr_next,
        queue_q_rd_ptr_next,
        queue_q_count_next,
        queue_q_entry_we,
        queue_q_entry_bank,
        queue_q_entry_slot,
        queue_q_entry_data,
        queue_update_queue_full
    } = bpu_queue_payload;

    // 按 C++ bpu_seq_read -> pre_read_req_comb 的字段顺序拼接输入。
    assign bpu_pre_read_req_input_bundle = {
        bpu_in_refetch,
        bpu_in_refetch_address,
        bpu_in_icache_read_ready,
        pc_reg,
        pc_can_send_to_icache_reg,
        q_count_reg,
        q_rd_ptr_reg,
        arch_ras_count_reg,
        spec_ras_count_reg
    };

    // 按 C++ bpu_data_seq_read -> post_read_req_comb 的字段顺序拼接输入。
    assign bpu_post_read_req_input_bundle = {
        bpu_in_refetch,
        bpu_in_update_base_pc,
        bpu_in_upd_valid,
        bpu_in_actual_br_type,
        spec_ghr_reg,
        spec_fh_reg,
        spec_path_reg,
        pre_pred_base_pc,
        pre_going_to_do_pred,
        pre_set_submodule_input,
        pre_do_pred_on_this_pc,
        pre_this_pc_bank_sel,
        pre_do_pred_for_this_pc,
        pre_going_to_do_upd,
        queue_read_data_snapshot,
        nlp_pred_base_entry_snapshot
    };

    // 子预测器 pre-read / comb 输入。
    // BPU_TOP 只负责外层状态和请求传递；Type/TAGE/BTB 自身表项读数据属于各子预测器模块边界。
    assign type_predictor_pre_read_input_bundle = post_type_in;
    assign type_pred_input_bundle = {
        post_type_in,
        type_predictor_pre_read_payload,
        {(W_TypePredCombIn-W_TypeInputPayload-W_TypePredictorPreReadCombOut){1'b0}}
    };
    assign tage_pre_read_input_bundle = {
        post_tage_in[W_TageInputPayload-1:0],
        {(W_TagePreReadCombIn-W_TageInputPayload){1'b0}}
    };
    assign tage_input_bundle = {
        post_tage_in[W_TageInputPayload-1:0],
        tage_pre_read_payload,
        {(W_TageCombIn-W_TageInputPayload-W_TagePreReadCombOut){1'b0}}
    };
    assign btb_pre_read_input_bundle = post_btb_in[W_BtbInputPayload-1:0];
    assign btb_post_read_req_input_bundle = {
        post_btb_in[W_BtbInputPayload-1:0],
        btb_pre_read_payload,
        {(W_BtbPostReadReqCombIn-W_BtbInputPayload-W_BtbPreReadCombOut){1'b0}}
    };
    assign btb_input_bundle = {
        post_btb_in[W_BtbInputPayload-1:0],
        btb_post_read_req_payload,
        {(W_BtbCombIn-W_BtbInputPayload-W_BtbPostReadReqCombOut){1'b0}}
    };

    // 子预测器结果汇总，再送入 predict_main。
    assign bpu_submodule_bind_input_bundle = {
        pre_do_pred_on_this_pc,
        pre_this_pc_bank_sel,
        post_btb_in,
        type_output_payload
    };
    assign bpu_predict_main_input_bundle = {
        bpu_in_refetch,
        bpu_in_refetch_address,
        pre_pred_base_pc,
        pre_boundary_addr,
        pc_can_send_to_icache_reg,
        pre_going_to_do_pred,
        pre_do_pred_on_this_pc,
        pre_this_pc_bank_sel,
        pre_do_pred_for_this_pc,
        pre_ras_has_entry_snapshot,
        ras_top_snapshot,
        saved_2ahead_prediction_reg,
        saved_2ahead_pred_valid_reg,
        saved_mini_flush_correct_reg,
        saved_mini_flush_target_reg,
        type_output_payload,
        tage_output_payload_all,
        btb_output_payload_all
    };

    // hist/queue 用 predict_main 输出和 BPU 输入共同生成周期末写回请求。
    assign bpu_hist_input_bundle = {
        bpu_in_refetch,
        bpu_in_update_base_pc,
        bpu_in_upd_valid,
        bpu_in_actual_dir,
        bpu_in_actual_br_type,
        bpu_in_pred_dir,
        pre_going_to_do_pred,
        pre_do_pred_on_this_pc,
        pre_this_pc_bank_sel,
        pre_do_pred_for_this_pc,
        spec_ghr_reg,
        spec_fh_reg,
        arch_ghr_reg,
        arch_fh_reg,
        spec_path_reg,
        arch_path_reg,
        arch_ras_stack_flat_snapshot,
        arch_ras_count_reg,
        spec_ras_stack_flat_snapshot,
        spec_ras_count_reg,
        type_output_payload,
        predict_final_pred_dir
    };
    assign bpu_queue_input_bundle = {
        bpu_in_update_base_pc,
        bpu_in_upd_valid,
        bpu_in_actual_dir,
        bpu_in_actual_br_type,
        bpu_in_actual_targets,
        bpu_in_pred_dir,
        bpu_in_alt_pred,
        bpu_in_pcpn,
        bpu_in_altpcpn,
        bpu_in_tage_tags,
        bpu_in_tage_idxs,
        bpu_in_sc_used,
        bpu_in_sc_pred,
        bpu_in_sc_sum,
        bpu_in_sc_idx,
        bpu_in_loop_used,
        bpu_in_loop_hit,
        bpu_in_loop_pred,
        bpu_in_loop_idx,
        bpu_in_loop_tag,
        q_wr_ptr_reg,
        q_rd_ptr_reg,
        q_count_reg,
        pre_going_to_do_upd
    };

    bpu_pre_read_req_comb_top #(
        .W_BpuPreReadReqCombIn(W_BpuPreReadReqCombIn),
        .W_BpuPreReadReqCombOut(W_BpuPreReadReqCombOut)
    ) u_bpu_pre_read_req_comb_top (
        .bpu_input_bundle(bpu_pre_read_req_input_bundle),
        .bpu_pre_read_req_bundle(bpu_pre_read_req_payload)
    );

    type_predictor_pre_read_comb_top #(
        .W_TypePredictorPreReadCombIn(W_TypePredictorPreReadCombIn),
        .W_TypePredictorPreReadCombOut(W_TypePredictorPreReadCombOut)
    ) u_type_predictor_pre_read_comb_top (
        .bpu_pre_read_req_bundle(type_predictor_pre_read_input_bundle),
        .type_predictor_pre_read_bundle(type_predictor_pre_read_payload)
    );

    tage_pre_read_comb_top #(
        .W_TagePreReadCombIn(W_TagePreReadCombIn),
        .W_TagePreReadCombOut(W_TagePreReadCombOut)
    ) u_tage_pre_read_comb_top (
        .bpu_pre_read_req_bundle(tage_pre_read_input_bundle),
        .tage_pre_read_bundle(tage_pre_read_payload)
    );

    btb_pre_read_comb_top #(
        .W_BtbPreReadCombIn(W_BtbPreReadCombIn),
        .W_BtbPreReadCombOut(W_BtbPreReadCombOut)
    ) u_btb_pre_read_comb_top (
        .bpu_pre_read_req_bundle(btb_pre_read_input_bundle),
        .btb_pre_read_bundle(btb_pre_read_payload)
    );

    // 第 2 组：读后请求阶段。
    // 预读结果返回后，BPU 再生成各预测器后续组合计算需要的输入。
    bpu_post_read_req_comb_top #(
        .W_BpuPostReadReqCombIn(W_BpuPostReadReqCombIn),
        .W_BpuPostReadReqCombOut(W_BpuPostReadReqCombOut)
    ) u_bpu_post_read_req_comb_top (
        .bpu_pre_read_req_bundle(bpu_post_read_req_input_bundle),
        .bpu_post_read_req_bundle(bpu_post_read_req_payload)
    );

    // 第 3 组：三个预测器并行计算。
    // TypePredictor 负责分支类型，TAGE 负责方向，BTB 负责目标地址。
    type_pred_comb_top #(
        .W_TypePredCombIn(W_TypePredCombIn),
        .W_TypePredCombOut(W_TypePredCombOut)
    ) u_type_pred_comb_top (
        .type_pred_input_bundle(type_pred_input_bundle),
        .type_pred_bundle(type_pred_payload)
    );

    tage_comb_top #(
        .W_TageCombIn(W_TageCombIn),
        .W_TageCombOut(W_TageCombOut)
    ) u_tage_comb_top (
        .tage_input_bundle(tage_input_bundle),
        .tage_bundle(tage_payload)
    );

    btb_post_read_req_comb_top #(
        .W_BtbPostReadReqCombIn(W_BtbPostReadReqCombIn),
        .W_BtbPostReadReqCombOut(W_BtbPostReadReqCombOut)
    ) u_btb_post_read_req_comb_top (
        .btb_post_read_req_input_bundle(btb_post_read_req_input_bundle),
        .btb_post_read_req_bundle(btb_post_read_req_payload)
    );

    btb_comb_top #(
        .W_BtbCombIn(W_BtbCombIn),
        .W_BtbCombOut(W_BtbCombOut)
    ) u_btb_comb_top (
        .btb_post_read_req_bundle(btb_input_bundle),
        .btb_bundle(btb_payload)
    );

    // 第 4 组：预测器结果汇总与主预测输出。
    // submodule_bind 把三个预测器结果整理成主预测所需格式，predict_main 生成 BPU 对 front_top 的输出候选。
    bpu_submodule_bind_comb_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuSubmoduleBindCombIn),
        .W_BpuSubmoduleBindCombOut(W_BpuSubmoduleBindCombOut)
    ) u_bpu_submodule_bind_comb_top (
        .bpu_submodule_bind_input_bundle(bpu_submodule_bind_input_bundle),
        .bpu_submodule_bind_bundle(bpu_submodule_bind_payload)
    );

    bpu_predict_main_comb_top #(
        .W_BpuPredictMainCombIn(W_BpuPredictMainCombIn),
        .W_BpuPredictMainCombOut(W_BpuPredictMainCombOut)
    ) u_bpu_predict_main_comb_top (
        .bpu_submodule_bind_bundle(bpu_predict_main_input_bundle),
        .bpu_predict_main_bundle(bpu_predict_main_payload)
    );

    // 第 5 组：历史和队列更新请求。
    // hist 对应 GHR/FH/path/RAS 等历史状态更新，queue 对应 BPU update queue。
    bpu_hist_comb_top #(
        .W_BpuHistCombIn(W_BpuHistCombIn),
        .W_BpuHistCombOut(W_BpuHistCombOut)
    ) u_bpu_hist_comb_top (
        .bpu_predict_main_bundle(bpu_hist_input_bundle),
        .bpu_hist_bundle(bpu_hist_payload)
    );

    bpu_queue_comb_top #(
        .W_BpuQueueCombIn(W_BpuQueueCombIn),
        .W_BpuQueueCombOut(W_BpuQueueCombOut)
    ) u_bpu_queue_comb_top (
        .bpu_predict_main_bundle(bpu_queue_input_bundle),
        .bpu_queue_bundle(bpu_queue_payload)
    );

    // 周期末状态写回。
    // rst_n 是异步硬复位；reset 是模拟器传入的同步清空信号。
    // BPU_TOP::UpdateRequest 对应的周期末写回值。
    // 这里把 27 个 comb 产生的请求收束到真正的 BPU 顶层寄存器。
    reg [31:0] bpu_state_i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
            for (bpu_state_i = 0; bpu_state_i < (Q_DEPTH * BPU_BANK_NUM); bpu_state_i = bpu_state_i + 1) begin
                update_queue[bpu_state_i] <= {W_BpuQueueEntry{1'b0}};
            end
        end else if (reset) begin
            // reset 是来自模拟器前端的同步控制信号，不和 rst_n 放在同一级。
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
            for (bpu_state_i = 0; bpu_state_i < (Q_DEPTH * BPU_BANK_NUM); bpu_state_i = bpu_state_i + 1) begin
                update_queue[bpu_state_i] <= {W_BpuQueueEntry{1'b0}};
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
            for (bpu_state_i = 0; bpu_state_i < RAS_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                arch_ras_stack[bpu_state_i] <= hist_arch_ras_stack_next[bpu_state_i*PC_BITS +: PC_BITS];
                if (bpu_in_refetch) begin
                    spec_ras_stack[bpu_state_i] <= hist_arch_ras_stack_next[bpu_state_i*PC_BITS +: PC_BITS];
                end else begin
                    spec_ras_stack[bpu_state_i] <= hist_spec_ras_stack_next[bpu_state_i*PC_BITS +: PC_BITS];
                end
            end
            for (bpu_state_i = 0; bpu_state_i < COMMIT_WIDTH; bpu_state_i = bpu_state_i + 1) begin
                if (queue_q_entry_we[bpu_state_i]) begin
                    update_queue[
                        (queue_q_entry_slot[bpu_state_i*QUEUE_PTR_BITS +: QUEUE_PTR_BITS] * BPU_BANK_NUM)
                        + {{(32-BPU_BANK_SEL_BITS){1'b0}}, queue_q_entry_bank[bpu_state_i*BPU_BANK_SEL_BITS +: BPU_BANK_SEL_BITS]}
                    ] <= queue_q_entry_data[bpu_state_i*W_BpuQueueEntry +: W_BpuQueueEntry];
                end
            end
        end
    end

    // BPU 对 front_top 的输出来自 predict_main；update_queue_full 由 queue comb 覆盖。
    // 2-Ahead 默认关闭时，相关输出保持无效，和 simulator-front 默认配置一致。
    assign bpu_out = {
        predict_output_payload[W_BpuOut-1:68],
        queue_update_queue_full,
        1'b0,
        predict_output_payload[65:34],
        1'b0,
        1'b0,
        predict_output_payload[31:0]
    };

endmodule
