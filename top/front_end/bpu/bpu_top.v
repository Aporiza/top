// BPU 分组顶层，用于前端 comb 训练边界连接。
// 源码依据：simulator-front/front-end/BPU/BPU.h。
// comb 实例使用语义变量端口；每个 wrapper 内部再拼接 pi/po。
//
// 阅读顺序：
// 1. 先看参数和 localparam，确认 simulator-front 默认配置下的位宽。
// 2. 再看 BPU_TOP 级别寄存器壳，确认哪些状态需要周期末写回。
// 3. 然后看 13 个 BPU comb wrapper 的调用链。
// 4. 最后看 always 块，理解 aresetn/reset 和普通运行时的状态更新关系。
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
    parameter W_BpuIn                 = 2739,  // 实际：2739, 来自 front_top W_BpuIn
    parameter W_BpuOut                = 4949    // 实际：4949, 来自 front_top W_BpuOut
) (
    input  wire                aclk,
    input  wire                aresetn,
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
    localparam NLP_TAG_BITS     = PC_BITS;
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

    // 这些 next-state 线对应 BPU_TOP::UpdateRequest 字段；在真实 BPU comb BSD
    // 逻辑接入前先保持当前状态。
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

    // 组合链路输入拼接。
    // 这里仍是变量级 bundle，不直接暴露 pi/po；pi/po 只在各 comb wrapper 的 BSD 层出现。
    assign bpu_pre_read_req_input_bundle = bpu_in[W_BpuPreReadReqCombIn-1:0];
    assign type_predictor_pre_read_input_bundle =
        bpu_pre_read_req_payload[W_TypePredictorPreReadCombIn-1:0];
    assign tage_pre_read_input_bundle = {
        {(W_TagePreReadCombIn-W_BpuPreReadReqCombOut){1'b0}},
        bpu_pre_read_req_payload
    };
    assign btb_pre_read_input_bundle = bpu_pre_read_req_payload[W_BtbPreReadCombIn-1:0];
    assign bpu_post_read_req_input_bundle = {
        {(W_BpuPostReadReqCombIn-W_BpuPreReadReqCombOut){1'b0}},
        bpu_pre_read_req_payload
    };
    assign type_pred_input_bundle = {
        type_predictor_pre_read_payload,
        bpu_post_read_req_payload
    };
    assign tage_input_bundle = {
        tage_pre_read_payload,
        bpu_post_read_req_payload
    };
    assign btb_post_read_req_input_bundle = {
        btb_pre_read_payload,
        bpu_post_read_req_payload
    };
    assign btb_input_bundle = {
        btb_post_read_req_payload,
        bpu_post_read_req_payload
    };
    assign bpu_submodule_bind_input_bundle = {
        type_pred_payload,
        tage_payload,
        btb_payload
    };
    assign bpu_predict_main_input_bundle = {
        bpu_submodule_bind_payload,
        type_pred_payload,
        tage_payload,
        btb_payload,
        bpu_post_read_req_payload
    };
    assign bpu_hist_input_bundle = {
        bpu_predict_main_payload,
        type_pred_payload,
        bpu_post_read_req_payload,
        bpu_in
    };
    assign bpu_queue_input_bundle = {
        bpu_predict_main_payload,
        bpu_in
    };

    // 第 1 组：预读请求阶段。
    // BPU 先生成统一预读请求，再分别送 TypePredictor/TAGE/BTB。
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
    // aresetn 是异步硬复位；reset 是模拟器传入的同步清空信号。
    // 当前真实 next-state 尚未接入，所以普通运行分支暂时保持寄存器自循环。
    reg [31:0] bpu_state_i;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
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
        end else if (reset) begin
            // reset 是来自模拟器前端的同步控制信号，不和 aresetn 放在同一级。
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

    wire [W_BpuOut-1:0] bpu_predict_main_front_view =
        bpu_predict_main_payload[W_BpuOut-1:0];
    wire [W_BpuOut-1:0] bpu_hist_front_view =
        bpu_hist_payload[W_BpuOut-1:0];
    wire [W_BpuOut-1:0] bpu_queue_front_view = {
        {(W_BpuOut-W_BpuQueueCombOut){1'b0}},
        bpu_queue_payload
    };

    assign bpu_out =
        bpu_predict_main_front_view |
        bpu_hist_front_view |
        bpu_queue_front_view;

endmodule
