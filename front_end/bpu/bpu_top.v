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
    localparam W_TypePredReadData      = W_TypePredCombIn - W_TypeInputPayload - W_TypePredictorPreReadCombOut;
    localparam W_TypePredCombResult    = W_TypePredCombOut - W_TypeOutputPayload;
    localparam W_TageStateInput        = W_TagePreReadCombIn - W_TageInputPayload;
    localparam W_TageReadData          = W_TageCombIn - W_TageInputPayload;
    localparam W_BtbReadData           = W_BtbCombIn - W_BtbInputPayload;
    localparam W_TageCombResult        = W_TageCombOut - W_TageOutputPayload;
    localparam W_BtbCombResult         = W_BtbCombOut - W_BtbOutputPayload;

    // TypePredictor 表项和读写请求位宽，来自 TypePredictor.h。
    localparam TYPE_PRED_SET_NUM       = 2048;
    localparam TYPE_PRED_WAY_NUM       = 2;
    localparam TYPE_PRED_SET_IDX_BITS  = 11;
    localparam TYPE_PRED_TAG_BITS      = 12;
    localparam TYPE_PRED_CONF_BITS     = 2;
    localparam TYPE_PRED_AGE_BITS      = 2;
    localparam TYPE_PRED_WAY_BITS      = 1;
    localparam W_TypePredEntry         =
        1 + TYPE_PRED_TAG_BITS + BR_TYPE_BITS + TYPE_PRED_CONF_BITS + TYPE_PRED_AGE_BITS;
    localparam W_TypePredPredReq       = FETCH_WIDTH * (1 + BPU_BANK_SEL_BITS + TYPE_PRED_SET_IDX_BITS + TYPE_PRED_TAG_BITS);
    localparam W_TypePredUpdReq        = COMMIT_WIDTH * (1 + BPU_BANK_SEL_BITS + TYPE_PRED_SET_IDX_BITS + TYPE_PRED_TAG_BITS);
    localparam TYPE_PRED_TABLE_DEPTH   = BPU_BANK_NUM * TYPE_PRED_SET_NUM * TYPE_PRED_WAY_NUM;
    localparam TYPE_PRED_REQ_TAG_LSB   = 0;
    localparam TYPE_PRED_REQ_SET_LSB   = FETCH_WIDTH * TYPE_PRED_TAG_BITS;
    localparam TYPE_PRED_REQ_BANK_LSB  = TYPE_PRED_REQ_SET_LSB + (FETCH_WIDTH * TYPE_PRED_SET_IDX_BITS);
    localparam TYPE_PRED_REQ_VALID_LSB = TYPE_PRED_REQ_BANK_LSB + (FETCH_WIDTH * BPU_BANK_SEL_BITS);
    localparam TYPE_UPD_REQ_TAG_LSB    = 0;
    localparam TYPE_UPD_REQ_SET_LSB    = COMMIT_WIDTH * TYPE_PRED_TAG_BITS;
    localparam TYPE_UPD_REQ_BANK_LSB   = TYPE_UPD_REQ_SET_LSB + (COMMIT_WIDTH * TYPE_PRED_SET_IDX_BITS);
    localparam TYPE_UPD_REQ_VALID_LSB  = TYPE_UPD_REQ_BANK_LSB + (COMMIT_WIDTH * BPU_BANK_SEL_BITS);
    localparam TYPE_REQ_WRITE_ENTRY_LSB = 0;
    localparam TYPE_REQ_WRITE_WAY_LSB   = COMMIT_WIDTH * W_TypePredEntry;
    localparam TYPE_REQ_WRITE_SET_LSB   = TYPE_REQ_WRITE_WAY_LSB + (COMMIT_WIDTH * TYPE_PRED_WAY_BITS);
    localparam TYPE_REQ_WRITE_BANK_LSB  = TYPE_REQ_WRITE_SET_LSB + (COMMIT_WIDTH * TYPE_PRED_SET_IDX_BITS);
    localparam TYPE_REQ_WRITE_EN_LSB    = TYPE_REQ_WRITE_BANK_LSB + (COMMIT_WIDTH * BPU_BANK_SEL_BITS);

    // TAGE 表项和状态位宽，来自 TAGE_top.h。tage_reset_ctr_t 和 tage_path_hist_t 按源码特殊位宽计算。
    localparam BASE_ENTRY_NUM          = 2048;
    localparam TN_ENTRY_NUM            = 4096;
    localparam TAGE_SC_ENTRY_NUM       = 1024;
    localparam TAGE_SC_L_ENTRY_NUM     = 1024;
    localparam TAGE_LOOP_ENTRY_NUM     = 1024;
    localparam TAGE_BASE_IDX_BITS      = 11;
    localparam TAGE_RESET_CTR_BITS     = TAGE_IDX_BITS + 11;
    localparam TAGE_USE_ALT_CTR_BITS   = 4;
    localparam TAGE_USE_ALT_CTR_INIT   = 7;
    localparam TAGE_SC_IDX_BITS        = 10;
    localparam TAGE_SC_CTR_BITS        = 2;
    localparam TAGE_SC_L_IDX_BITS      = 10;
    localparam TAGE_SC_L_CTR_BITS      = 6;
    localparam TAGE_SC_L_THETA_BITS    = 16;
    localparam TAGE_SC_L_THETA_INIT    = 18;
    localparam TAGE_LOOP_TABLE_IDX_BITS = 10;
    localparam TAGE_LOOP_TAG_BITS      = 16;
    localparam TAGE_LOOP_ITER_BITS     = 12;
    localparam TAGE_LOOP_CONF_BITS     = 3;
    localparam TAGE_LOOP_AGE_BITS      = 3;
    localparam W_TageTableReadData     =
        (TN_MAX * TAGE_TAG_BITS)
      + (TN_MAX * 3)
      + (TN_MAX * 2)
      + 2;
    localparam W_TageIndexTag          = (TN_MAX * TAGE_IDX_BITS) + (TN_MAX * TAGE_TAG_BITS) + TAGE_BASE_IDX_BITS;
    localparam W_TageUpdateRequest     = 89;
    localparam W_TageLoopEntry         =
        1 + TAGE_LOOP_TAG_BITS + TAGE_LOOP_ITER_BITS + TAGE_LOOP_ITER_BITS
      + TAGE_LOOP_CONF_BITS + TAGE_LOOP_AGE_BITS + 1;
    localparam TAGE_BASE_TABLE_DEPTH   = BPU_BANK_NUM * BASE_ENTRY_NUM;
    localparam TAGE_TN_TABLE_DEPTH     = BPU_BANK_NUM * TN_MAX * TN_ENTRY_NUM;
    localparam TAGE_SC_TABLE_DEPTH     = BPU_BANK_NUM * TAGE_SC_ENTRY_NUM;
    localparam TAGE_SCL_TABLE_DEPTH    = BPU_BANK_NUM * BPU_SCL_META_NTABLE * TAGE_SC_L_ENTRY_NUM;
    localparam TAGE_LOOP_TABLE_DEPTH   = BPU_BANK_NUM * TAGE_LOOP_ENTRY_NUM;
    localparam TAGE_IN_LOOP_TAG_LSB    = 0;
    localparam TAGE_IN_LOOP_IDX_LSB    = TAGE_IN_LOOP_TAG_LSB + BPU_LOOP_META_TAG_BITS;
    localparam TAGE_IN_LOOP_PRED_LSB   = TAGE_IN_LOOP_IDX_LSB + BPU_LOOP_META_IDX_BITS;
    localparam TAGE_IN_LOOP_HIT_LSB    = TAGE_IN_LOOP_PRED_LSB + 1;
    localparam TAGE_IN_LOOP_USED_LSB   = TAGE_IN_LOOP_HIT_LSB + 1;
    localparam TAGE_IN_SC_IDX_LSB      = TAGE_IN_LOOP_USED_LSB + 1;
    localparam TAGE_IN_SC_SUM_LSB      = TAGE_IN_SC_IDX_LSB + (BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS);
    localparam TAGE_IN_SC_PRED_LSB     = TAGE_IN_SC_SUM_LSB + BPU_SCL_META_SUM_BITS;
    localparam TAGE_IN_SC_USED_LSB     = TAGE_IN_SC_PRED_LSB + 1;
    localparam TAGE_IN_IDX_FLAT_LSB    = TAGE_IN_SC_USED_LSB + 1;
    localparam TAGE_IN_TAG_FLAT_LSB    = TAGE_IN_IDX_FLAT_LSB + (TN_MAX * TAGE_IDX_BITS);
    localparam TAGE_IN_ALTPCPN_LSB     = TAGE_IN_TAG_FLAT_LSB + (TN_MAX * TAGE_TAG_BITS);
    localparam TAGE_IN_PCPN_LSB        = TAGE_IN_ALTPCPN_LSB + PCPN_BITS;
    localparam TAGE_IN_ALT_PRED_LSB    = TAGE_IN_PCPN_LSB + PCPN_BITS;
    localparam TAGE_IN_PRED_LSB        = TAGE_IN_ALT_PRED_LSB + 1;
    localparam TAGE_IN_REAL_DIR_LSB    = TAGE_IN_PRED_LSB + 1;
    localparam TAGE_IN_PC_UPDATE_LSB   = TAGE_IN_REAL_DIR_LSB + 1;
    localparam TAGE_IN_UPDATE_EN_LSB   = TAGE_IN_PC_UPDATE_LSB + PC_BITS;
    localparam TAGE_IN_PATH_LSB        = TAGE_IN_UPDATE_EN_LSB + 1;
    localparam TAGE_IN_FH_LSB          = TAGE_IN_PATH_LSB + TAGE_SC_PATH_BITS;
    localparam TAGE_IN_GHR_LSB         = TAGE_IN_FH_LSB + (FH_N_MAX * TN_MAX * 32);
    localparam TAGE_PRE_IDX_LSB        = 0;
    localparam TAGE_PRE_USEFUL_LSB     = 60;
    localparam TAGE_PRE_UPD_LSB        = TAGE_PRE_USEFUL_LSB + 13;
    localparam TAGE_PRE_PRED_LSB       = TAGE_PRE_UPD_LSB + 244;
    localparam TAGE_PRE_PRED_LOOP_TAG_LSB  = 0;
    localparam TAGE_PRE_PRED_LOOP_IDX_LSB  = 16;
    localparam TAGE_PRE_PRED_SCL_IDX_LSB   = 32;
    localparam TAGE_PRE_PRED_SC_IDX_LSB    = 160;
    localparam TAGE_PRE_PRED_IDX_TAG_LSB   = 170;
    localparam TAGE_PRE_PRED_VALID_LSB     = 261;
    localparam TAGE_PRE_UPD_RESET_IDX_LSB  = 0;
    localparam TAGE_PRE_UPD_RESET_VALID_LSB = 12;
    localparam TAGE_PRE_UPD_LOOP_VALID_LSB = 13;
    localparam TAGE_PRE_UPD_LOOP_TAG_LSB   = 14;
    localparam TAGE_PRE_UPD_LOOP_IDX_LSB   = 30;
    localparam TAGE_PRE_UPD_SCL_IDX_LSB    = 46;
    localparam TAGE_PRE_UPD_TAGE_IDX_LSB   = 174;
    localparam TAGE_PRE_UPD_SC_IDX_LSB     = 222;
    localparam TAGE_PRE_UPD_BASE_IDX_LSB   = 232;
    localparam TAGE_PRE_UPD_VALID_LSB      = 243;
    localparam TAGE_PRE_IDX_VALID_LSB      = 0;
    localparam TAGE_PRE_IDX_TAGE_IDX_LSB   = 1;
    localparam TAGE_PRE_IDX_BASE_IDX_LSB   = 49;
    localparam TAGE_RD_UPD_RESET_DATA_LSB  = 0;
    localparam TAGE_RD_UPD_RESET_IDX_LSB   = 8;
    localparam TAGE_RD_UPD_RESET_VALID_LSB = 20;
    localparam TAGE_RD_UPD_LOOP_TAG_LSB    = 21;
    localparam TAGE_RD_UPD_LOOP_IDX_LSB    = 37;
    localparam TAGE_RD_UPD_LOOP_DIR_LSB    = 53;
    localparam TAGE_RD_UPD_LOOP_AGE_LSB    = 54;
    localparam TAGE_RD_UPD_LOOP_CONF_LSB   = 57;
    localparam TAGE_RD_UPD_LOOP_LIMIT_LSB  = 60;
    localparam TAGE_RD_UPD_LOOP_COUNT_LSB  = 72;
    localparam TAGE_RD_UPD_LOOP_ENTRY_TAG_LSB = 84;
    localparam TAGE_RD_UPD_LOOP_VALID_LSB  = 100;
    localparam TAGE_RD_UPD_SCL_CTR_LSB     = 101;
    localparam TAGE_RD_UPD_TABLE_DATA_LSB  = 149;
    localparam TAGE_RD_UPD_SC_CTR_LSB      = 203;
    localparam TAGE_RD_UPD_SC_IDX_LSB      = 205;
    localparam TAGE_RD_UPD_BASE_IDX_LSB    = 215;
    localparam TAGE_RD_UPD_VALID_LSB       = 226;
    localparam TAGE_RD_PRED_LOOP_TAG_LSB   = 227;
    localparam TAGE_RD_PRED_LOOP_IDX_LSB   = 243;
    localparam TAGE_RD_PRED_LOOP_DIR_LSB   = 259;
    localparam TAGE_RD_PRED_LOOP_AGE_LSB   = 260;
    localparam TAGE_RD_PRED_LOOP_CONF_LSB  = 263;
    localparam TAGE_RD_PRED_LOOP_LIMIT_LSB = 266;
    localparam TAGE_RD_PRED_LOOP_COUNT_LSB = 278;
    localparam TAGE_RD_PRED_LOOP_ENTRY_TAG_LSB = 290;
    localparam TAGE_RD_PRED_LOOP_VALID_LSB = 306;
    localparam TAGE_RD_PRED_SCL_CTR_LSB    = 307;
    localparam TAGE_RD_PRED_SC_CTR_LSB     = 355;
    localparam TAGE_RD_PRED_TABLE_DATA_LSB = 357;
    localparam TAGE_RD_PRED_IDX_TAG_LSB    = 411;
    localparam TAGE_RD_PRED_VALID_LSB      = 502;
    localparam TAGE_RD_SRAM_PRNG_LSB       = 503;
    localparam TAGE_RD_NEW_DATA_LSB        = 535;
    localparam TAGE_RD_NEW_VALID_LSB       = 589;
    localparam TAGE_RD_SRAM_DELAY_DATA_LSB = 590;
    localparam TAGE_RD_SRAM_DELAY_COUNT_LSB = 644;
    localparam TAGE_RD_SRAM_DELAY_ACTIVE_LSB = 676;
    localparam TAGE_RD_USEFUL_RESET_DATA_LSB = 677;
    localparam TAGE_RD_USEFUL_RESET_VALID_LSB = 685;
    localparam TAGE_RD_MEM_LSB             = 686;
    localparam TAGE_RD_IDX_LSB             = 741;
    localparam TAGE_RD_STATE_LSB           = 801;
    localparam TAGE_REQ_LOOP_DIR_LSB       = 0;
    localparam TAGE_REQ_LOOP_AGE_LSB       = 1;
    localparam TAGE_REQ_LOOP_CONF_LSB      = 4;
    localparam TAGE_REQ_LOOP_LIMIT_LSB     = 7;
    localparam TAGE_REQ_LOOP_COUNT_LSB     = 19;
    localparam TAGE_REQ_LOOP_TAG_LSB       = 31;
    localparam TAGE_REQ_LOOP_VALID_LSB     = 47;
    localparam TAGE_REQ_LOOP_WR_IDX_LSB    = 48;
    localparam TAGE_REQ_LOOP_WE_LSB        = 64;
    localparam TAGE_REQ_SCL_THETA_DATA_LSB = 65;
    localparam TAGE_REQ_SCL_THETA_WE_LSB   = 81;
    localparam TAGE_REQ_SCL_DATA_LSB       = 82;
    localparam TAGE_REQ_SCL_IDX_LSB        = 130;
    localparam TAGE_REQ_SCL_WE_LSB         = 258;
    localparam TAGE_REQ_SC_DATA_LSB        = 266;
    localparam TAGE_REQ_SC_IDX_LSB         = 268;
    localparam TAGE_REQ_SC_WE_LSB          = 278;
    localparam TAGE_REQ_USEFUL_RESET_DATA_LSB = 279;
    localparam TAGE_REQ_USEFUL_RESET_ROW_LSB = 291;
    localparam TAGE_REQ_USEFUL_RESET_WE_LSB = 339;
    localparam TAGE_REQ_TAG_DATA_LSB       = 343;
    localparam TAGE_REQ_TAG_IDX_LSB        = 375;
    localparam TAGE_REQ_TAG_WE_LSB         = 423;
    localparam TAGE_REQ_USEFUL_DATA_LSB    = 427;
    localparam TAGE_REQ_USEFUL_IDX_LSB     = 435;
    localparam TAGE_REQ_USEFUL_WE_LSB      = 483;
    localparam TAGE_REQ_CNT_DATA_LSB       = 487;
    localparam TAGE_REQ_CNT_IDX_LSB        = 499;
    localparam TAGE_REQ_CNT_WE_LSB         = 547;
    localparam TAGE_REQ_BASE_DATA_LSB      = 551;
    localparam TAGE_REQ_BASE_IDX_LSB       = 553;
    localparam TAGE_REQ_BASE_WE_LSB        = 564;
    localparam TAGE_REQ_LSFR_NEXT_LSB      = 565;
    localparam TAGE_REQ_LSFR_WE_LSB        = 569;
    localparam TAGE_REQ_USE_ALT_NEXT_LSB   = 570;
    localparam TAGE_REQ_USE_ALT_WE_LSB     = 574;
    localparam TAGE_REQ_RESET_CNT_NEXT_LSB = 575;
    localparam TAGE_REQ_RESET_CNT_WE_LSB   = 598;
    localparam TAGE_REQ_UPD_WINFO_NEXT_LSB = 599;
    localparam TAGE_REQ_PRED_PC_NEXT_LSB   = 688;
    localparam TAGE_REQ_PRED_TAG_NEXT_LSB  = 720;
    localparam TAGE_REQ_PRED_IDX_NEXT_LSB  = 752;
    localparam TAGE_REQ_PRED_BASE_NEXT_LSB = 800;
    localparam TAGE_REQ_UPD_IDX_NEXT_LSB   = 811;
    localparam TAGE_REQ_UPD_TAG_NEXT_LSB   = 859;
    localparam TAGE_REQ_UPD_ALTPCPN_NEXT_LSB = 891;
    localparam TAGE_REQ_UPD_PCPN_NEXT_LSB  = 894;
    localparam TAGE_REQ_UPD_ALT_NEXT_LSB   = 897;
    localparam TAGE_REQ_UPD_PRED_NEXT_LSB  = 898;
    localparam TAGE_REQ_UPD_PC_NEXT_LSB    = 899;
    localparam TAGE_REQ_UPD_REAL_NEXT_LSB  = 931;
    localparam TAGE_REQ_DO_UPD_NEXT_LSB    = 932;
    localparam TAGE_REQ_DO_PRED_NEXT_LSB   = 933;
    localparam TAGE_REQ_SRAM_PRNG_NEXT_LSB = 934;
    localparam TAGE_REQ_SRAM_DELAY_DATA_NEXT_LSB = 966;
    localparam TAGE_REQ_SRAM_DELAY_COUNT_NEXT_LSB = 1020;
    localparam TAGE_REQ_SRAM_DELAY_ACTIVE_NEXT_LSB = 1052;
    localparam TAGE_REQ_NEXT_STATE_LSB     = 1658;

    // BTB/BHT/TC 表项和状态位宽，来自 BTB_top.h。
    localparam BTB_ENTRY_NUM           = 1024;
    localparam BTB_TYPE_ENTRY_NUM      = 4096;
    localparam BHT_ENTRY_NUM           = 2048;
    localparam TC_ENTRY_NUM            = 2048;
    localparam BTB_WAY_NUM             = 4;
    localparam TC_WAY_NUM              = 2;
    localparam BTB_IDX_BITS            = 10;
    localparam BTB_TYPE_IDX_BITS       = 12;
    localparam BHT_IDX_BITS            = 11;
    localparam TC_IDX_BITS             = 11;
    localparam BTB_TAG_BITS            = 8;
    localparam TC_TAG_BITS             = 10;
    localparam BTB_WAY_BITS            = 2;
    localparam TC_WAY_BITS             = 1;
    localparam BHT_HIST_BITS           = 11;
    localparam W_BtbSetData            = (BTB_WAY_NUM * BTB_TAG_BITS) + (BTB_WAY_NUM * PC_BITS) + BTB_WAY_NUM + (BTB_WAY_NUM * 3);
    localparam W_TcSetData             = (TC_WAY_NUM * PC_BITS) + (TC_WAY_NUM * TC_TAG_BITS) + TC_WAY_NUM + (TC_WAY_NUM * 3);
    localparam W_BtbMemReadResult      = W_BtbSetData + W_TcSetData + BR_TYPE_BITS + BHT_HIST_BITS + 1;
    localparam W_BtbStateInput         = 166;
    localparam BTB_TABLE_DEPTH         = BPU_BANK_NUM * BTB_WAY_NUM * BTB_ENTRY_NUM;
    localparam BHT_TABLE_DEPTH         = BPU_BANK_NUM * BHT_ENTRY_NUM;
    localparam TC_TABLE_DEPTH          = BPU_BANK_NUM * TC_WAY_NUM * TC_ENTRY_NUM;
    localparam BTB_PRE_UPD_REQ_LSB     = 0;
    localparam BTB_PRE_PRED_REQ_LSB    = 143;
    localparam BTB_POST_UPD_TC_TAG_LSB = 0;
    localparam BTB_POST_UPD_TC_IDX_LSB = BTB_POST_UPD_TC_TAG_LSB + TC_TAG_BITS;
    localparam BTB_POST_UPD_TC_RE_LSB  = BTB_POST_UPD_TC_IDX_LSB + TC_IDX_BITS;
    localparam BTB_POST_NEXT_BHT_LSB   = BTB_POST_UPD_TC_RE_LSB + 1;
    localparam BTB_POST_PRED_TC_IDX_LSB = BTB_POST_NEXT_BHT_LSB + BHT_HIST_BITS;
    localparam BTB_POST_PRED_TC_RE_LSB = BTB_POST_PRED_TC_IDX_LSB + TC_IDX_BITS;
    localparam BTB_RD_UPD_TC_SET_LSB        = 0;
    localparam BTB_RD_UPD_TC_WRITE_TAG_LSB  = 92;
    localparam BTB_RD_UPD_TC_WRITE_IDX_LSB  = 102;
    localparam BTB_RD_UPD_TC_READ_VALID_LSB = 113;
    localparam BTB_RD_UPD_BTB_SET_LSB       = 114;
    localparam BTB_RD_UPD_NEXT_BHT_LSB      = 290;
    localparam BTB_RD_UPD_BHT_DATA_LSB      = 301;
    localparam BTB_RD_UPD_TAG_LSB           = 312;
    localparam BTB_RD_UPD_BHT_IDX_LSB       = 320;
    localparam BTB_RD_UPD_TYPE_IDX_LSB      = 331;
    localparam BTB_RD_UPD_BTB_IDX_LSB       = 343;
    localparam BTB_RD_UPD_READ_VALID_LSB    = 353;
    localparam BTB_RD_PRED_TC_SET_LSB       = 354;
    localparam BTB_RD_PRED_BTB_SET_LSB      = 446;
    localparam BTB_RD_PRED_BHT_DATA_LSB     = 622;
    localparam BTB_RD_PRED_TYPE_DATA_LSB    = 633;
    localparam BTB_RD_PRED_TAG_LSB          = 636;
    localparam BTB_RD_PRED_TC_IDX_LSB       = 644;
    localparam BTB_RD_PRED_BHT_IDX_LSB      = 655;
    localparam BTB_RD_PRED_TYPE_IDX_LSB     = 666;
    localparam BTB_RD_PRED_BTB_IDX_LSB      = 678;
    localparam BTB_RD_PRED_READ_VALID_LSB   = 688;
    localparam BTB_RD_SRAM_PRNG_LSB         = 689;
    localparam BTB_RD_NEW_READ_DATA_LSB     = 721;
    localparam BTB_RD_NEW_READ_VALID_LSB    = 1004;
    localparam BTB_RD_SRAM_DELAY_DATA_LSB   = 1005;
    localparam BTB_RD_SRAM_DELAY_COUNT_LSB  = 1288;
    localparam BTB_RD_SRAM_DELAY_ACTIVE_LSB = 1320;
    localparam BTB_RD_MEM2_LSB              = 1321;
    localparam BTB_RD_IDX2_LSB              = 1604;
    localparam BTB_RD_MEM1_LSB              = 1657;
    localparam BTB_RD_IDX1_LSB              = 1940;
    localparam BTB_RD_STATE_LSB             = 1993;
    localparam BTB_REQ_BTB_USEFUL_LSB       = 0;
    localparam BTB_REQ_BTB_VALID_LSB        = 3;
    localparam BTB_REQ_BTB_BTA_LSB          = 4;
    localparam BTB_REQ_BTB_TAG_LSB          = 36;
    localparam BTB_REQ_BTB_IDX_LSB          = 44;
    localparam BTB_REQ_BTB_WAY_LSB          = 54;
    localparam BTB_REQ_BTB_WE_LSB           = 56;
    localparam BTB_REQ_TC_USEFUL_LSB        = 57;
    localparam BTB_REQ_TC_VALID_LSB         = 60;
    localparam BTB_REQ_TC_TAG_LSB           = 61;
    localparam BTB_REQ_TC_TARGET_LSB        = 71;
    localparam BTB_REQ_TC_IDX_LSB           = 103;
    localparam BTB_REQ_TC_WAY_LSB           = 114;
    localparam BTB_REQ_TC_WE_LSB            = 115;
    localparam BTB_REQ_BHT_DATA_LSB         = 116;
    localparam BTB_REQ_BHT_IDX_LSB          = 127;
    localparam BTB_REQ_BHT_WE_LSB           = 138;
    localparam BTB_REQ_UPD_WRITES_BTB_NEXT_LSB = 155;
    localparam BTB_REQ_UPD_NEXT_USEFUL_NEXT_LSB = 156;
    localparam BTB_REQ_UPD_W_TARGET_NEXT_LSB = 159;
    localparam BTB_REQ_UPD_VICTIM_NEXT_LSB  = 160;
    localparam BTB_REQ_UPD_HIT_INFO_NEXT_LSB = 162;
    localparam BTB_REQ_UPD_NEXT_BHT_NEXT_LSB = 165;
    localparam BTB_REQ_PRED_BHT_NEXT_LSB    = 176;
    localparam BTB_REQ_PRED_TYPE_NEXT_LSB   = 187;
    localparam BTB_REQ_PRED_IDX_NEXT_LSB    = 199;
    localparam BTB_REQ_PRED_TAG_NEXT_LSB    = 209;
    localparam BTB_REQ_PRED_PC_NEXT_LSB     = 217;
    localparam BTB_REQ_UPD_DIR_NEXT_LSB     = 249;
    localparam BTB_REQ_UPD_TYPE_NEXT_LSB    = 250;
    localparam BTB_REQ_UPD_ADDR_NEXT_LSB    = 253;
    localparam BTB_REQ_UPD_PC_NEXT_LSB      = 285;
    localparam BTB_REQ_DO_UPD_NEXT_LSB      = 317;
    localparam BTB_REQ_DO_PRED_NEXT_LSB     = 318;
    localparam BTB_REQ_SRAM_PRNG_NEXT_LSB   = 319;
    localparam BTB_REQ_SRAM_DELAY_DATA_NEXT_LSB = 351;
    localparam BTB_REQ_SRAM_DELAY_COUNT_NEXT_LSB = 634;
    localparam BTB_REQ_SRAM_DELAY_ACTIVE_NEXT_LSB = 666;
    localparam BTB_REQ_NEXT_STATE_LSB       = 1052;

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

    // TypePredictor 自有表项。BSD comb 只计算读写请求，真实表状态在这里保存。
    reg [W_TypePredEntry-1:0]                    type_pred_table [0:TYPE_PRED_TABLE_DEPTH-1];

    // TAGE 每个 bank 各自有一份表和流水状态，对应 C++ 中 BPU_TOP::tage[BPU_BANK_NUM]。
    reg [1:0]                                    tage_state_reg [0:BPU_BANK_NUM-1];
    reg [3:0]                                    tage_lsfr_reg [0:BPU_BANK_NUM-1];
    reg [TAGE_RESET_CTR_BITS-1:0]                tage_reset_cnt_reg [0:BPU_BANK_NUM-1];
    reg [TAGE_USE_ALT_CTR_BITS-1:0]              tage_use_alt_ctr_reg [0:BPU_BANK_NUM-1];
    reg [TAGE_SC_L_THETA_BITS-1:0]               tage_scl_theta_reg [0:BPU_BANK_NUM-1];
    reg                                          tage_do_pred_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          tage_do_upd_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          tage_upd_real_dir_latch_reg [0:BPU_BANK_NUM-1];
    reg [PC_BITS-1:0]                            tage_upd_pc_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          tage_upd_pred_in_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          tage_upd_alt_pred_in_latch_reg [0:BPU_BANK_NUM-1];
    reg [PCPN_BITS-1:0]                          tage_upd_pcpn_in_latch_reg [0:BPU_BANK_NUM-1];
    reg [PCPN_BITS-1:0]                          tage_upd_altpcpn_in_latch_reg [0:BPU_BANK_NUM-1];
    reg [TN_MAX*TAGE_TAG_BITS-1:0]               tage_upd_tag_flat_latch_reg [0:BPU_BANK_NUM-1];
    reg [TN_MAX*TAGE_IDX_BITS-1:0]               tage_upd_idx_flat_latch_reg [0:BPU_BANK_NUM-1];
    reg [TAGE_BASE_IDX_BITS-1:0]                 tage_pred_calc_base_idx_latch_reg [0:BPU_BANK_NUM-1];
    reg [TN_MAX*TAGE_IDX_BITS-1:0]               tage_pred_calc_idx_latch_reg [0:BPU_BANK_NUM-1];
    reg [TN_MAX*TAGE_TAG_BITS-1:0]               tage_pred_calc_tag_latch_reg [0:BPU_BANK_NUM-1];
    reg [PC_BITS-1:0]                            tage_pred_pc_latch_reg [0:BPU_BANK_NUM-1];
    reg [W_TageUpdateRequest-1:0]                tage_upd_calc_winfo_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          tage_sram_delay_active_reg [0:BPU_BANK_NUM-1];
    reg [31:0]                                   tage_sram_delay_counter_reg [0:BPU_BANK_NUM-1];
    reg [W_TageTableReadData-1:0]                tage_sram_delayed_data_reg [0:BPU_BANK_NUM-1];
    reg [31:0]                                   tage_sram_prng_state_reg [0:BPU_BANK_NUM-1];
    reg [1:0]                                    tage_base_counter_table [0:TAGE_BASE_TABLE_DEPTH-1];
    reg [TAGE_TAG_BITS-1:0]                      tage_tag_table [0:TAGE_TN_TABLE_DEPTH-1];
    reg [2:0]                                    tage_cnt_table [0:TAGE_TN_TABLE_DEPTH-1];
    reg [1:0]                                    tage_useful_table [0:TAGE_TN_TABLE_DEPTH-1];
    reg [TAGE_SC_CTR_BITS-1:0]                   tage_sc_ctr_table [0:TAGE_SC_TABLE_DEPTH-1];
    reg [TAGE_SC_L_CTR_BITS-1:0]                 tage_scl_table [0:TAGE_SCL_TABLE_DEPTH-1];
    reg [W_TageLoopEntry-1:0]                    tage_loop_table [0:TAGE_LOOP_TABLE_DEPTH-1];

    // BTB 每个 bank 各自保存 BTB/BHT/TC 表和流水状态，对应 C++ 中 BPU_TOP::btb[BPU_BANK_NUM]。
    reg [1:0]                                    btb_state_reg [0:BPU_BANK_NUM-1];
    reg                                          btb_do_pred_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          btb_do_upd_latch_reg [0:BPU_BANK_NUM-1];
    reg [PC_BITS-1:0]                            btb_upd_pc_latch_reg [0:BPU_BANK_NUM-1];
    reg [PC_BITS-1:0]                            btb_upd_actual_addr_latch_reg [0:BPU_BANK_NUM-1];
    reg [BR_TYPE_BITS-1:0]                       btb_upd_br_type_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          btb_upd_actual_dir_latch_reg [0:BPU_BANK_NUM-1];
    reg [PC_BITS-1:0]                            btb_pred_calc_pc_latch_reg [0:BPU_BANK_NUM-1];
    reg [BTB_TAG_BITS-1:0]                       btb_pred_calc_btb_tag_latch_reg [0:BPU_BANK_NUM-1];
    reg [BTB_IDX_BITS-1:0]                       btb_pred_calc_btb_idx_latch_reg [0:BPU_BANK_NUM-1];
    reg [BTB_TYPE_IDX_BITS-1:0]                  btb_pred_calc_type_idx_latch_reg [0:BPU_BANK_NUM-1];
    reg [BHT_IDX_BITS-1:0]                       btb_pred_calc_bht_idx_latch_reg [0:BPU_BANK_NUM-1];
    reg [BHT_HIST_BITS-1:0]                      btb_upd_calc_next_bht_val_latch_reg [0:BPU_BANK_NUM-1];
    reg [2:0]                                    btb_upd_calc_hit_info_latch_reg [0:BPU_BANK_NUM-1];
    reg [BTB_WAY_BITS-1:0]                       btb_upd_calc_victim_way_latch_reg [0:BPU_BANK_NUM-1];
    reg [TC_WAY_BITS-1:0]                        btb_upd_calc_w_target_way_latch_reg [0:BPU_BANK_NUM-1];
    reg [2:0]                                    btb_upd_calc_next_useful_val_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          btb_upd_calc_writes_btb_latch_reg [0:BPU_BANK_NUM-1];
    reg                                          btb_sram_delay_active_reg [0:BPU_BANK_NUM-1];
    reg [31:0]                                   btb_sram_delay_counter_reg [0:BPU_BANK_NUM-1];
    reg [W_BtbMemReadResult-1:0]                 btb_sram_delayed_data_reg [0:BPU_BANK_NUM-1];
    reg [31:0]                                   btb_sram_prng_state_reg [0:BPU_BANK_NUM-1];
    reg [BTB_TAG_BITS-1:0]                       btb_tag_table [0:BTB_TABLE_DEPTH-1];
    reg [PC_BITS-1:0]                            btb_bta_table [0:BTB_TABLE_DEPTH-1];
    reg                                          btb_valid_table [0:BTB_TABLE_DEPTH-1];
    reg [2:0]                                    btb_useful_table [0:BTB_TABLE_DEPTH-1];
    reg [BHT_HIST_BITS-1:0]                      btb_bht_table [0:BHT_TABLE_DEPTH-1];
    reg [PC_BITS-1:0]                            btb_tc_target_table [0:TC_TABLE_DEPTH-1];
    reg [TC_TAG_BITS-1:0]                        btb_tc_tag_table [0:TC_TABLE_DEPTH-1];
    reg                                          btb_tc_valid_table [0:TC_TABLE_DEPTH-1];
    reg [2:0]                                    btb_tc_useful_table [0:TC_TABLE_DEPTH-1];

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
    wire [W_TypePredPredReq-1:0]             type_pred_pred_req_bundle;
    wire [W_TypePredUpdReq-1:0]              type_pred_upd_req_bundle;
    wire [W_TypePredReadData-1:0]            type_pred_read_data_bundle;
    wire [FETCH_WIDTH*TYPE_PRED_WAY_NUM*W_TypePredEntry-1:0] type_pred_read_pred_entries;
    wire [COMMIT_WIDTH*TYPE_PRED_WAY_NUM*W_TypePredEntry-1:0] type_pred_read_upd_entries;
    wire [W_TypePredCombResult-1:0]          type_pred_comb_result;

    wire [BPU_BANK_NUM*W_TagePreReadCombIn-1:0]        tage_pre_read_input_bundle_all;
    wire [BPU_BANK_NUM*W_TagePreReadCombOut-1:0]       tage_pre_read_payload_all;
    wire [BPU_BANK_NUM*W_TageCombIn-1:0]               tage_input_bundle_all;
    wire [BPU_BANK_NUM*W_TageCombOut-1:0]              tage_payload_all;
    wire [BPU_BANK_NUM*W_TageStateInput-1:0]            tage_state_input_bundle_all;
    wire [BPU_BANK_NUM*W_TageReadData-1:0]              tage_read_data_bundle_all;
    wire [BPU_BANK_NUM*W_TageCombResult-1:0]            tage_comb_result_all;

    wire [BPU_BANK_NUM*W_BtbPreReadCombIn-1:0]         btb_pre_read_input_bundle_all;
    wire [BPU_BANK_NUM*W_BtbPreReadCombOut-1:0]        btb_pre_read_payload_all;
    wire [BPU_BANK_NUM*W_BtbPostReadReqCombIn-1:0]     btb_post_read_req_input_bundle_all;
    wire [BPU_BANK_NUM*W_BtbPostReadReqCombOut-1:0]    btb_post_read_req_payload_all;
    wire [BPU_BANK_NUM*W_BtbCombIn-1:0]                btb_input_bundle_all;
    wire [BPU_BANK_NUM*W_BtbCombOut-1:0]               btb_payload_all;
    wire [BPU_BANK_NUM*W_BtbReadData-1:0]               btb_read_data_pre_bundle_all;
    wire [BPU_BANK_NUM*W_BtbReadData-1:0]               btb_read_data_bundle_all;
    wire [BPU_BANK_NUM*W_BtbCombResult-1:0]             btb_comb_result_all;

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
    wire [BPU_BANK_NUM*W_TageOutputPayload-1:0] tage_output_payload_all;
    wire [BPU_BANK_NUM*W_BtbOutputPayload-1:0]  btb_output_payload_all;

    genvar bpu_output_bank_g;
    generate
        for (bpu_output_bank_g = 0; bpu_output_bank_g < BPU_BANK_NUM;
             bpu_output_bank_g = bpu_output_bank_g + 1) begin : gen_bpu_output_bank
            assign tage_output_payload_all[
                bpu_output_bank_g*W_TageOutputPayload +: W_TageOutputPayload
            ] = tage_payload_all[
                bpu_output_bank_g*W_TageCombOut + W_TageCombOut - 1 -: W_TageOutputPayload
            ];

            assign btb_output_payload_all[
                bpu_output_bank_g*W_BtbOutputPayload +: W_BtbOutputPayload
            ] = btb_payload_all[
                bpu_output_bank_g*W_BtbCombOut + W_BtbCombOut - 1 -: W_BtbOutputPayload
            ];

            assign tage_comb_result_all[
                bpu_output_bank_g*W_TageCombResult +: W_TageCombResult
            ] = tage_payload_all[
                bpu_output_bank_g*W_TageCombOut +: W_TageCombResult
            ];

            assign btb_comb_result_all[
                bpu_output_bank_g*W_BtbCombResult +: W_BtbCombResult
            ] = btb_payload_all[
                bpu_output_bank_g*W_BtbCombOut +: W_BtbCombResult
            ];
        end
    endgenerate

    // 组合链路输入拼接。
    // predict_main 输出拆分。
    // 子预测器表读数据。
    // 这部分对应 C++ 里的 type_pred/tage/btb *_seq_read 和 *_data_seq_read。
    // 组员补 BSD 时只替换组合计算，表项、延迟寄存器和周期末写回仍由这里统一保存。
    assign type_pred_pred_req_bundle =
        type_predictor_pre_read_payload[W_TypePredictorPreReadCombOut-1 -: W_TypePredPredReq];
    assign type_pred_upd_req_bundle =
        type_predictor_pre_read_payload[W_TypePredUpdReq-1:0];
    assign type_pred_read_data_bundle = {
        type_pred_read_pred_entries,
        type_pred_read_upd_entries
    };
    assign type_pred_comb_result = type_pred_payload[W_TypePredCombResult-1:0];

    genvar type_pred_lane_g;
    genvar type_pred_way_g;
    generate
        for (type_pred_lane_g = 0; type_pred_lane_g < FETCH_WIDTH;
             type_pred_lane_g = type_pred_lane_g + 1) begin : gen_type_pred_read_pred_lane
            for (type_pred_way_g = 0; type_pred_way_g < TYPE_PRED_WAY_NUM;
                 type_pred_way_g = type_pred_way_g + 1) begin : gen_type_pred_read_pred_way
                wire type_pred_re =
                    type_pred_pred_req_bundle[TYPE_PRED_REQ_VALID_LSB + type_pred_lane_g];
                wire [BPU_BANK_SEL_BITS-1:0] type_pred_bank =
                    type_pred_pred_req_bundle[
                        TYPE_PRED_REQ_BANK_LSB + type_pred_lane_g*BPU_BANK_SEL_BITS +: BPU_BANK_SEL_BITS
                    ];
                wire [TYPE_PRED_SET_IDX_BITS-1:0] type_pred_set =
                    type_pred_pred_req_bundle[
                        TYPE_PRED_REQ_SET_LSB + type_pred_lane_g*TYPE_PRED_SET_IDX_BITS +: TYPE_PRED_SET_IDX_BITS
                    ];
                wire [31:0] type_pred_table_index =
                    ((({{(32-BPU_BANK_SEL_BITS){1'b0}}, type_pred_bank} * TYPE_PRED_SET_NUM)
                    + {{(32-TYPE_PRED_SET_IDX_BITS){1'b0}}, type_pred_set}) * TYPE_PRED_WAY_NUM)
                    + type_pred_way_g;
                assign type_pred_read_pred_entries[
                    (type_pred_lane_g*TYPE_PRED_WAY_NUM + type_pred_way_g)*W_TypePredEntry +: W_TypePredEntry
                ] = type_pred_re ? type_pred_table[type_pred_table_index] : {W_TypePredEntry{1'b0}};
            end
        end

        for (type_pred_lane_g = 0; type_pred_lane_g < COMMIT_WIDTH;
             type_pred_lane_g = type_pred_lane_g + 1) begin : gen_type_pred_read_upd_lane
            for (type_pred_way_g = 0; type_pred_way_g < TYPE_PRED_WAY_NUM;
                 type_pred_way_g = type_pred_way_g + 1) begin : gen_type_pred_read_upd_way
                wire type_upd_re =
                    type_pred_upd_req_bundle[TYPE_UPD_REQ_VALID_LSB + type_pred_lane_g];
                wire [BPU_BANK_SEL_BITS-1:0] type_upd_bank =
                    type_pred_upd_req_bundle[
                        TYPE_UPD_REQ_BANK_LSB + type_pred_lane_g*BPU_BANK_SEL_BITS +: BPU_BANK_SEL_BITS
                    ];
                wire [TYPE_PRED_SET_IDX_BITS-1:0] type_upd_set =
                    type_pred_upd_req_bundle[
                        TYPE_UPD_REQ_SET_LSB + type_pred_lane_g*TYPE_PRED_SET_IDX_BITS +: TYPE_PRED_SET_IDX_BITS
                    ];
                wire [31:0] type_upd_table_index =
                    ((({{(32-BPU_BANK_SEL_BITS){1'b0}}, type_upd_bank} * TYPE_PRED_SET_NUM)
                    + {{(32-TYPE_PRED_SET_IDX_BITS){1'b0}}, type_upd_set}) * TYPE_PRED_WAY_NUM)
                    + type_pred_way_g;
                assign type_pred_read_upd_entries[
                    (type_pred_lane_g*TYPE_PRED_WAY_NUM + type_pred_way_g)*W_TypePredEntry +: W_TypePredEntry
                ] = type_upd_re ? type_pred_table[type_upd_table_index] : {W_TypePredEntry{1'b0}};
            end
        end
    endgenerate

    genvar bpu_state_read_bank_g;
    genvar bpu_tage_way_g;
    genvar bpu_tage_scl_g;
    generate
        for (bpu_state_read_bank_g = 0; bpu_state_read_bank_g < BPU_BANK_NUM;
             bpu_state_read_bank_g = bpu_state_read_bank_g + 1) begin : gen_tage_state_read_bank
            wire [W_TageInputPayload-1:0] tage_input_this =
                post_tage_in[bpu_state_read_bank_g*W_TageInputPayload +: W_TageInputPayload];
            wire [W_TagePreReadCombOut-1:0] tage_pre_read_this =
                tage_pre_read_payload_all[bpu_state_read_bank_g*W_TagePreReadCombOut +: W_TagePreReadCombOut];
            wire [261:0] tage_pred_req_this = tage_pre_read_this[TAGE_PRE_PRED_LSB +: 262];
            wire [243:0] tage_upd_req_this = tage_pre_read_this[TAGE_PRE_UPD_LSB +: 244];
            wire [59:0] tage_idx_this = tage_pre_read_this[TAGE_PRE_IDX_LSB +: 60];
            wire [12:0] tage_useful_req_this = tage_pre_read_this[TAGE_PRE_USEFUL_LSB +: 13];
            wire tage_pred_read_valid = tage_pred_req_this[TAGE_PRE_PRED_VALID_LSB];
            wire [W_TageIndexTag-1:0] tage_pred_idx_tag =
                tage_pred_req_this[TAGE_PRE_PRED_IDX_TAG_LSB +: W_TageIndexTag];
            wire [TN_MAX*TAGE_IDX_BITS-1:0] tage_pred_idx_flat =
                tage_pred_idx_tag[TAGE_BASE_IDX_BITS + (TN_MAX*TAGE_TAG_BITS) +: (TN_MAX*TAGE_IDX_BITS)];
            wire [TAGE_BASE_IDX_BITS-1:0] tage_pred_base_idx =
                tage_pred_idx_tag[0 +: TAGE_BASE_IDX_BITS];
            wire [TAGE_SC_IDX_BITS-1:0] tage_pred_sc_idx =
                tage_pred_req_this[TAGE_PRE_PRED_SC_IDX_LSB +: TAGE_SC_IDX_BITS];
            wire [BPU_SCL_META_NTABLE*TAGE_SC_L_IDX_BITS-1:0] tage_pred_scl_idx_flat =
                tage_pred_req_this[TAGE_PRE_PRED_SCL_IDX_LSB +: (BPU_SCL_META_NTABLE*TAGE_SC_L_IDX_BITS)];
            wire [TAGE_LOOP_TABLE_IDX_BITS-1:0] tage_pred_loop_idx =
                tage_pred_req_this[TAGE_PRE_PRED_LOOP_IDX_LSB +: TAGE_LOOP_TABLE_IDX_BITS];
            wire [TAGE_LOOP_TAG_BITS-1:0] tage_pred_loop_tag =
                tage_pred_req_this[TAGE_PRE_PRED_LOOP_TAG_LSB +: TAGE_LOOP_TAG_BITS];
            wire tage_upd_read_valid = tage_upd_req_this[TAGE_PRE_UPD_VALID_LSB];
            wire [TAGE_BASE_IDX_BITS-1:0] tage_upd_base_idx =
                tage_upd_req_this[TAGE_PRE_UPD_BASE_IDX_LSB +: TAGE_BASE_IDX_BITS];
            wire [TAGE_SC_IDX_BITS-1:0] tage_upd_sc_idx =
                tage_upd_req_this[TAGE_PRE_UPD_SC_IDX_LSB +: TAGE_SC_IDX_BITS];
            wire [TN_MAX*TAGE_IDX_BITS-1:0] tage_upd_idx_flat =
                tage_upd_req_this[TAGE_PRE_UPD_TAGE_IDX_LSB +: (TN_MAX*TAGE_IDX_BITS)];
            wire [BPU_SCL_META_NTABLE*TAGE_SC_L_IDX_BITS-1:0] tage_upd_scl_idx_flat =
                tage_upd_req_this[TAGE_PRE_UPD_SCL_IDX_LSB +: (BPU_SCL_META_NTABLE*TAGE_SC_L_IDX_BITS)];
            wire tage_upd_loop_valid = tage_upd_req_this[TAGE_PRE_UPD_LOOP_VALID_LSB];
            wire [TAGE_LOOP_TABLE_IDX_BITS-1:0] tage_upd_loop_idx =
                tage_upd_req_this[TAGE_PRE_UPD_LOOP_IDX_LSB +: TAGE_LOOP_TABLE_IDX_BITS];
            wire [TAGE_LOOP_TAG_BITS-1:0] tage_upd_loop_tag =
                tage_upd_req_this[TAGE_PRE_UPD_LOOP_TAG_LSB +: TAGE_LOOP_TAG_BITS];
            wire tage_upd_reset_row_valid = tage_upd_req_this[TAGE_PRE_UPD_RESET_VALID_LSB];
            wire [TAGE_IDX_BITS-1:0] tage_upd_reset_row_idx =
                tage_upd_req_this[TAGE_PRE_UPD_RESET_IDX_LSB +: TAGE_IDX_BITS];
            wire tage_useful_reset_row_valid = tage_useful_req_this[TAGE_IDX_BITS];
            wire [TAGE_IDX_BITS-1:0] tage_useful_reset_row_idx =
                tage_useful_req_this[0 +: TAGE_IDX_BITS];
            wire tage_idx_valid = tage_idx_this[TAGE_PRE_IDX_VALID_LSB];
            wire [TN_MAX*TAGE_IDX_BITS-1:0] tage_idx_flat =
                tage_idx_this[TAGE_PRE_IDX_TAGE_IDX_LSB +: (TN_MAX*TAGE_IDX_BITS)];
            wire [TAGE_BASE_IDX_BITS-1:0] tage_idx_base =
                tage_idx_this[TAGE_PRE_IDX_BASE_IDX_LSB +: TAGE_BASE_IDX_BITS];

            wire [TN_MAX*TAGE_TAG_BITS-1:0] tage_mem_tag_bundle;
            wire [TN_MAX*3-1:0]             tage_mem_cnt_bundle;
            wire [TN_MAX*2-1:0]             tage_mem_useful_bundle;
            wire [TN_MAX*TAGE_TAG_BITS-1:0] tage_pred_tag_bundle;
            wire [TN_MAX*3-1:0]             tage_pred_cnt_bundle;
            wire [TN_MAX*2-1:0]             tage_pred_useful_bundle;
            wire [TN_MAX*TAGE_TAG_BITS-1:0] tage_upd_tag_bundle;
            wire [TN_MAX*3-1:0]             tage_upd_cnt_bundle;
            wire [TN_MAX*2-1:0]             tage_upd_useful_bundle;
            wire [TN_MAX*2-1:0]             tage_upd_reset_data_bundle;
            wire [TN_MAX*2-1:0]             tage_useful_reset_data_bundle;

            for (bpu_tage_way_g = 0; bpu_tage_way_g < TN_MAX;
                 bpu_tage_way_g = bpu_tage_way_g + 1) begin : gen_tage_table_read_way
                wire [TAGE_IDX_BITS-1:0] mem_idx =
                    tage_idx_flat[bpu_tage_way_g*TAGE_IDX_BITS +: TAGE_IDX_BITS];
                wire [TAGE_IDX_BITS-1:0] pred_idx =
                    tage_pred_idx_flat[bpu_tage_way_g*TAGE_IDX_BITS +: TAGE_IDX_BITS];
                wire [TAGE_IDX_BITS-1:0] upd_idx =
                    tage_upd_idx_flat[bpu_tage_way_g*TAGE_IDX_BITS +: TAGE_IDX_BITS];
                wire [31:0] mem_table_index =
                    ((bpu_state_read_bank_g * TN_MAX + bpu_tage_way_g) * TN_ENTRY_NUM)
                    + {{(32-TAGE_IDX_BITS){1'b0}}, mem_idx};
                wire [31:0] pred_table_index =
                    ((bpu_state_read_bank_g * TN_MAX + bpu_tage_way_g) * TN_ENTRY_NUM)
                    + {{(32-TAGE_IDX_BITS){1'b0}}, pred_idx};
                wire [31:0] upd_table_index =
                    ((bpu_state_read_bank_g * TN_MAX + bpu_tage_way_g) * TN_ENTRY_NUM)
                    + {{(32-TAGE_IDX_BITS){1'b0}}, upd_idx};
                wire [31:0] upd_reset_table_index =
                    ((bpu_state_read_bank_g * TN_MAX + bpu_tage_way_g) * TN_ENTRY_NUM)
                    + {{(32-TAGE_IDX_BITS){1'b0}}, tage_upd_reset_row_idx};
                wire [31:0] useful_reset_table_index =
                    ((bpu_state_read_bank_g * TN_MAX + bpu_tage_way_g) * TN_ENTRY_NUM)
                    + {{(32-TAGE_IDX_BITS){1'b0}}, tage_useful_reset_row_idx};
                assign tage_mem_tag_bundle[bpu_tage_way_g*TAGE_TAG_BITS +: TAGE_TAG_BITS] =
                    tage_idx_valid ? tage_tag_table[mem_table_index] : {TAGE_TAG_BITS{1'b0}};
                assign tage_mem_cnt_bundle[bpu_tage_way_g*3 +: 3] =
                    tage_idx_valid ? tage_cnt_table[mem_table_index] : 3'b000;
                assign tage_mem_useful_bundle[bpu_tage_way_g*2 +: 2] =
                    tage_idx_valid ? tage_useful_table[mem_table_index] : 2'b00;
                assign tage_pred_tag_bundle[bpu_tage_way_g*TAGE_TAG_BITS +: TAGE_TAG_BITS] =
                    tage_pred_read_valid ? tage_tag_table[pred_table_index] : {TAGE_TAG_BITS{1'b0}};
                assign tage_pred_cnt_bundle[bpu_tage_way_g*3 +: 3] =
                    tage_pred_read_valid ? tage_cnt_table[pred_table_index] : 3'b000;
                assign tage_pred_useful_bundle[bpu_tage_way_g*2 +: 2] =
                    tage_pred_read_valid ? tage_useful_table[pred_table_index] : 2'b00;
                assign tage_upd_tag_bundle[bpu_tage_way_g*TAGE_TAG_BITS +: TAGE_TAG_BITS] =
                    tage_upd_read_valid ? tage_tag_table[upd_table_index] : {TAGE_TAG_BITS{1'b0}};
                assign tage_upd_cnt_bundle[bpu_tage_way_g*3 +: 3] =
                    tage_upd_read_valid ? tage_cnt_table[upd_table_index] : 3'b000;
                assign tage_upd_useful_bundle[bpu_tage_way_g*2 +: 2] =
                    tage_upd_read_valid ? tage_useful_table[upd_table_index] : 2'b00;
                assign tage_upd_reset_data_bundle[bpu_tage_way_g*2 +: 2] =
                    tage_upd_reset_row_valid ? tage_useful_table[upd_reset_table_index] : 2'b00;
                assign tage_useful_reset_data_bundle[bpu_tage_way_g*2 +: 2] =
                    tage_useful_reset_row_valid ? tage_useful_table[useful_reset_table_index] : 2'b00;
            end

            wire [W_TageTableReadData-1:0] tage_mem_table_data = {
                tage_mem_tag_bundle,
                tage_mem_cnt_bundle,
                tage_mem_useful_bundle,
                tage_idx_valid ? tage_base_counter_table[(bpu_state_read_bank_g * BASE_ENTRY_NUM) + tage_idx_base] : 2'b00
            };
            wire [W_TageTableReadData-1:0] tage_pred_table_data = {
                tage_pred_tag_bundle,
                tage_pred_cnt_bundle,
                tage_pred_useful_bundle,
                tage_pred_read_valid ? tage_base_counter_table[(bpu_state_read_bank_g * BASE_ENTRY_NUM) + tage_pred_base_idx] : 2'b00
            };
            wire [W_TageTableReadData-1:0] tage_upd_table_data = {
                tage_upd_tag_bundle,
                tage_upd_cnt_bundle,
                tage_upd_useful_bundle,
                tage_upd_read_valid ? tage_base_counter_table[(bpu_state_read_bank_g * BASE_ENTRY_NUM) + tage_upd_base_idx] : 2'b00
            };
            wire [W_TageLoopEntry-1:0] tage_pred_loop_entry =
                tage_pred_read_valid
                    ? tage_loop_table[(bpu_state_read_bank_g * TAGE_LOOP_ENTRY_NUM) + tage_pred_loop_idx]
                    : {W_TageLoopEntry{1'b0}};
            wire [W_TageLoopEntry-1:0] tage_upd_loop_entry =
                (tage_upd_read_valid && tage_upd_loop_valid)
                    ? tage_loop_table[(bpu_state_read_bank_g * TAGE_LOOP_ENTRY_NUM) + tage_upd_loop_idx]
                    : {W_TageLoopEntry{1'b0}};
            wire [BPU_SCL_META_NTABLE*TAGE_SC_L_CTR_BITS-1:0] tage_pred_scl_ctr_bundle;
            wire [BPU_SCL_META_NTABLE*TAGE_SC_L_CTR_BITS-1:0] tage_upd_scl_ctr_bundle;

            for (bpu_tage_scl_g = 0; bpu_tage_scl_g < BPU_SCL_META_NTABLE;
                 bpu_tage_scl_g = bpu_tage_scl_g + 1) begin : gen_tage_scl_read
                wire [TAGE_SC_L_IDX_BITS-1:0] pred_scl_idx =
                    tage_pred_scl_idx_flat[bpu_tage_scl_g*TAGE_SC_L_IDX_BITS +: TAGE_SC_L_IDX_BITS];
                wire [TAGE_SC_L_IDX_BITS-1:0] upd_scl_idx =
                    tage_upd_scl_idx_flat[bpu_tage_scl_g*TAGE_SC_L_IDX_BITS +: TAGE_SC_L_IDX_BITS];
                assign tage_pred_scl_ctr_bundle[bpu_tage_scl_g*TAGE_SC_L_CTR_BITS +: TAGE_SC_L_CTR_BITS] =
                    tage_pred_read_valid
                        ? tage_scl_table[((bpu_state_read_bank_g * BPU_SCL_META_NTABLE + bpu_tage_scl_g) * TAGE_SC_L_ENTRY_NUM) + pred_scl_idx]
                        : {TAGE_SC_L_CTR_BITS{1'b0}};
                assign tage_upd_scl_ctr_bundle[bpu_tage_scl_g*TAGE_SC_L_CTR_BITS +: TAGE_SC_L_CTR_BITS] =
                    tage_upd_read_valid
                        ? tage_scl_table[((bpu_state_read_bank_g * BPU_SCL_META_NTABLE + bpu_tage_scl_g) * TAGE_SC_L_ENTRY_NUM) + upd_scl_idx]
                        : {TAGE_SC_L_CTR_BITS{1'b0}};
            end

            assign tage_state_input_bundle_all[bpu_state_read_bank_g*W_TageStateInput +: W_TageStateInput] = {
                tage_state_reg[bpu_state_read_bank_g],
                tage_input_this[TAGE_IN_FH_LSB +: (FH_N_MAX*TN_MAX*32)],
                tage_input_this[TAGE_IN_GHR_LSB +: GHR_LENGTH],
                tage_lsfr_reg[bpu_state_read_bank_g],
                tage_reset_cnt_reg[bpu_state_read_bank_g],
                tage_use_alt_ctr_reg[bpu_state_read_bank_g],
                tage_scl_theta_reg[bpu_state_read_bank_g],
                tage_do_pred_latch_reg[bpu_state_read_bank_g],
                tage_do_upd_latch_reg[bpu_state_read_bank_g],
                tage_upd_real_dir_latch_reg[bpu_state_read_bank_g],
                tage_upd_pc_latch_reg[bpu_state_read_bank_g],
                tage_upd_pred_in_latch_reg[bpu_state_read_bank_g],
                tage_upd_alt_pred_in_latch_reg[bpu_state_read_bank_g],
                tage_upd_pcpn_in_latch_reg[bpu_state_read_bank_g],
                tage_upd_altpcpn_in_latch_reg[bpu_state_read_bank_g],
                tage_upd_tag_flat_latch_reg[bpu_state_read_bank_g],
                tage_upd_idx_flat_latch_reg[bpu_state_read_bank_g],
                tage_pred_calc_base_idx_latch_reg[bpu_state_read_bank_g],
                tage_pred_calc_idx_latch_reg[bpu_state_read_bank_g],
                tage_pred_calc_tag_latch_reg[bpu_state_read_bank_g],
                tage_pred_pc_latch_reg[bpu_state_read_bank_g],
                tage_upd_calc_winfo_latch_reg[bpu_state_read_bank_g]
            };

            assign tage_read_data_bundle_all[bpu_state_read_bank_g*W_TageReadData +: W_TageReadData] = {
                tage_state_input_bundle_all[bpu_state_read_bank_g*W_TageStateInput +: W_TageStateInput],
                tage_idx_this,
                tage_mem_table_data,
                tage_idx_valid,
                tage_useful_reset_row_valid,
                tage_useful_reset_data_bundle,
                tage_sram_delay_active_reg[bpu_state_read_bank_g],
                tage_sram_delay_counter_reg[bpu_state_read_bank_g],
                tage_sram_delayed_data_reg[bpu_state_read_bank_g],
                tage_idx_valid,
                tage_mem_table_data,
                tage_sram_prng_state_reg[bpu_state_read_bank_g],
                tage_pred_read_valid,
                tage_pred_idx_tag,
                tage_pred_table_data,
                tage_pred_read_valid ? tage_sc_ctr_table[(bpu_state_read_bank_g * TAGE_SC_ENTRY_NUM) + tage_pred_sc_idx] : {TAGE_SC_CTR_BITS{1'b0}},
                tage_pred_scl_ctr_bundle,
                tage_pred_loop_entry[W_TageLoopEntry-1],
                tage_pred_loop_entry[W_TageLoopEntry-2 -: TAGE_LOOP_TAG_BITS],
                tage_pred_loop_entry[TAGE_LOOP_ITER_BITS+TAGE_LOOP_CONF_BITS+TAGE_LOOP_AGE_BITS+1 +: TAGE_LOOP_ITER_BITS],
                tage_pred_loop_entry[TAGE_LOOP_CONF_BITS+TAGE_LOOP_AGE_BITS+1 +: TAGE_LOOP_ITER_BITS],
                tage_pred_loop_entry[TAGE_LOOP_AGE_BITS+1 +: TAGE_LOOP_CONF_BITS],
                tage_pred_loop_entry[1 +: TAGE_LOOP_AGE_BITS],
                tage_pred_loop_entry[0],
                {{(TAGE_LOOP_TAG_BITS-TAGE_LOOP_TABLE_IDX_BITS){1'b0}}, tage_pred_loop_idx},
                tage_pred_loop_tag,
                tage_upd_read_valid,
                tage_upd_base_idx,
                tage_upd_sc_idx,
                tage_upd_read_valid ? tage_sc_ctr_table[(bpu_state_read_bank_g * TAGE_SC_ENTRY_NUM) + tage_upd_sc_idx] : {TAGE_SC_CTR_BITS{1'b0}},
                tage_upd_table_data,
                tage_upd_scl_ctr_bundle,
                tage_upd_loop_entry[W_TageLoopEntry-1],
                tage_upd_loop_entry[W_TageLoopEntry-2 -: TAGE_LOOP_TAG_BITS],
                tage_upd_loop_entry[TAGE_LOOP_ITER_BITS+TAGE_LOOP_CONF_BITS+TAGE_LOOP_AGE_BITS+1 +: TAGE_LOOP_ITER_BITS],
                tage_upd_loop_entry[TAGE_LOOP_CONF_BITS+TAGE_LOOP_AGE_BITS+1 +: TAGE_LOOP_ITER_BITS],
                tage_upd_loop_entry[TAGE_LOOP_AGE_BITS+1 +: TAGE_LOOP_CONF_BITS],
                tage_upd_loop_entry[1 +: TAGE_LOOP_AGE_BITS],
                tage_upd_loop_entry[0],
                {{(TAGE_LOOP_TAG_BITS-TAGE_LOOP_TABLE_IDX_BITS){1'b0}}, tage_upd_loop_idx},
                tage_upd_loop_tag,
                tage_upd_reset_row_valid,
                tage_upd_reset_row_idx,
                tage_upd_reset_data_bundle
            };
        end
    endgenerate

    genvar bpu_btb_way_g;
    genvar bpu_btb_tc_way_g;
    generate
        for (bpu_state_read_bank_g = 0; bpu_state_read_bank_g < BPU_BANK_NUM;
             bpu_state_read_bank_g = bpu_state_read_bank_g + 1) begin : gen_btb_state_read_bank
            wire [W_BtbPreReadCombOut-1:0] btb_pre_read_this =
                btb_pre_read_payload_all[bpu_state_read_bank_g*W_BtbPreReadCombOut +: W_BtbPreReadCombOut];
            wire [W_BtbPostReadReqCombOut-1:0] btb_post_read_this =
                btb_post_read_req_payload_all[bpu_state_read_bank_g*W_BtbPostReadReqCombOut +: W_BtbPostReadReqCombOut];
            wire [84:0] btb_pred_req_this =
                btb_pre_read_this[BTB_PRE_PRED_REQ_LSB +: 85];
            wire [142:0] btb_upd_req_this =
                btb_pre_read_this[BTB_PRE_UPD_REQ_LSB +: 143];
            wire btb_pred_read_valid = btb_pred_req_this[84];
            wire [BTB_IDX_BITS-1:0] btb_pred_btb_idx =
                btb_pred_req_this[42 +: BTB_IDX_BITS];
            wire [BHT_IDX_BITS-1:0] btb_pred_bht_idx =
                btb_pred_req_this[19 +: BHT_IDX_BITS];
            wire [BTB_TYPE_IDX_BITS-1:0] btb_pred_type_idx =
                btb_pred_req_this[30 +: BTB_TYPE_IDX_BITS];
            wire [BTB_TAG_BITS-1:0] btb_pred_tag =
                btb_pred_req_this[11 +: BTB_TAG_BITS];
            wire btb_upd_read_valid = btb_upd_req_this[142];
            wire [BTB_IDX_BITS-1:0] btb_upd_btb_idx =
                btb_upd_req_this[64 +: BTB_IDX_BITS];
            wire [BHT_IDX_BITS-1:0] btb_upd_bht_idx =
                btb_upd_req_this[41 +: BHT_IDX_BITS];
            wire [BTB_TYPE_IDX_BITS-1:0] btb_upd_type_idx =
                btb_upd_req_this[52 +: BTB_TYPE_IDX_BITS];
            wire [BTB_TAG_BITS-1:0] btb_upd_tag =
                btb_upd_req_this[33 +: BTB_TAG_BITS];
            wire btb_pred_tc_re =
                btb_post_read_this[BTB_POST_PRED_TC_RE_LSB];
            wire [TC_IDX_BITS-1:0] btb_pred_tc_idx =
                btb_post_read_this[BTB_POST_PRED_TC_IDX_LSB +: TC_IDX_BITS];
            wire btb_upd_tc_re =
                btb_post_read_this[BTB_POST_UPD_TC_RE_LSB];
            wire [TC_IDX_BITS-1:0] btb_upd_tc_idx =
                btb_post_read_this[BTB_POST_UPD_TC_IDX_LSB +: TC_IDX_BITS];
            wire [TC_TAG_BITS-1:0] btb_upd_tc_tag =
                btb_post_read_this[BTB_POST_UPD_TC_TAG_LSB +: TC_TAG_BITS];
            wire [BHT_HIST_BITS-1:0] btb_upd_next_bht =
                btb_post_read_this[BTB_POST_NEXT_BHT_LSB +: BHT_HIST_BITS];
            wire [W_BtbSetData-1:0] btb_pred_set_data;
            wire [W_BtbSetData-1:0] btb_upd_set_data;
            wire [W_TcSetData-1:0] btb_pred_tc_set_data;
            wire [W_TcSetData-1:0] btb_upd_tc_set_data;

            for (bpu_btb_way_g = 0; bpu_btb_way_g < BTB_WAY_NUM;
                 bpu_btb_way_g = bpu_btb_way_g + 1) begin : gen_btb_way_read
                wire [31:0] pred_btb_table_index =
                    ((bpu_state_read_bank_g * BTB_WAY_NUM + bpu_btb_way_g) * BTB_ENTRY_NUM)
                    + {{(32-BTB_IDX_BITS){1'b0}}, btb_pred_btb_idx};
                wire [31:0] upd_btb_table_index =
                    ((bpu_state_read_bank_g * BTB_WAY_NUM + bpu_btb_way_g) * BTB_ENTRY_NUM)
                    + {{(32-BTB_IDX_BITS){1'b0}}, btb_upd_btb_idx};
                assign btb_pred_set_data[(BTB_WAY_NUM*BTB_TAG_BITS) - 1 - bpu_btb_way_g*BTB_TAG_BITS -: BTB_TAG_BITS] =
                    btb_pred_read_valid ? btb_tag_table[pred_btb_table_index] : {BTB_TAG_BITS{1'b0}};
                assign btb_pred_set_data[(BTB_WAY_NUM*BTB_TAG_BITS + BTB_WAY_NUM*PC_BITS) - 1 - bpu_btb_way_g*PC_BITS -: PC_BITS] =
                    btb_pred_read_valid ? btb_bta_table[pred_btb_table_index] : {PC_BITS{1'b0}};
                assign btb_pred_set_data[(BTB_WAY_NUM*BTB_TAG_BITS + BTB_WAY_NUM*PC_BITS + BTB_WAY_NUM) - 1 - bpu_btb_way_g] =
                    btb_pred_read_valid ? btb_valid_table[pred_btb_table_index] : 1'b0;
                assign btb_pred_set_data[(BTB_WAY_NUM*BTB_TAG_BITS + BTB_WAY_NUM*PC_BITS + BTB_WAY_NUM + BTB_WAY_NUM*3) - 1 - bpu_btb_way_g*3 -: 3] =
                    btb_pred_read_valid ? btb_useful_table[pred_btb_table_index] : 3'b000;
                assign btb_upd_set_data[(BTB_WAY_NUM*BTB_TAG_BITS) - 1 - bpu_btb_way_g*BTB_TAG_BITS -: BTB_TAG_BITS] =
                    btb_upd_read_valid ? btb_tag_table[upd_btb_table_index] : {BTB_TAG_BITS{1'b0}};
                assign btb_upd_set_data[(BTB_WAY_NUM*BTB_TAG_BITS + BTB_WAY_NUM*PC_BITS) - 1 - bpu_btb_way_g*PC_BITS -: PC_BITS] =
                    btb_upd_read_valid ? btb_bta_table[upd_btb_table_index] : {PC_BITS{1'b0}};
                assign btb_upd_set_data[(BTB_WAY_NUM*BTB_TAG_BITS + BTB_WAY_NUM*PC_BITS + BTB_WAY_NUM) - 1 - bpu_btb_way_g] =
                    btb_upd_read_valid ? btb_valid_table[upd_btb_table_index] : 1'b0;
                assign btb_upd_set_data[(BTB_WAY_NUM*BTB_TAG_BITS + BTB_WAY_NUM*PC_BITS + BTB_WAY_NUM + BTB_WAY_NUM*3) - 1 - bpu_btb_way_g*3 -: 3] =
                    btb_upd_read_valid ? btb_useful_table[upd_btb_table_index] : 3'b000;
            end

            for (bpu_btb_tc_way_g = 0; bpu_btb_tc_way_g < TC_WAY_NUM;
                 bpu_btb_tc_way_g = bpu_btb_tc_way_g + 1) begin : gen_btb_tc_way_read
                wire [31:0] pred_tc_table_index =
                    ((bpu_state_read_bank_g * TC_WAY_NUM + bpu_btb_tc_way_g) * TC_ENTRY_NUM)
                    + {{(32-TC_IDX_BITS){1'b0}}, btb_pred_tc_idx};
                wire [31:0] upd_tc_table_index =
                    ((bpu_state_read_bank_g * TC_WAY_NUM + bpu_btb_tc_way_g) * TC_ENTRY_NUM)
                    + {{(32-TC_IDX_BITS){1'b0}}, btb_upd_tc_idx};
                assign btb_pred_tc_set_data[(TC_WAY_NUM*PC_BITS) - 1 - bpu_btb_tc_way_g*PC_BITS -: PC_BITS] =
                    btb_pred_tc_re ? btb_tc_target_table[pred_tc_table_index] : {PC_BITS{1'b0}};
                assign btb_pred_tc_set_data[(TC_WAY_NUM*PC_BITS + TC_WAY_NUM*TC_TAG_BITS) - 1 - bpu_btb_tc_way_g*TC_TAG_BITS -: TC_TAG_BITS] =
                    btb_pred_tc_re ? btb_tc_tag_table[pred_tc_table_index] : {TC_TAG_BITS{1'b0}};
                assign btb_pred_tc_set_data[(TC_WAY_NUM*PC_BITS + TC_WAY_NUM*TC_TAG_BITS + TC_WAY_NUM) - 1 - bpu_btb_tc_way_g] =
                    btb_pred_tc_re ? btb_tc_valid_table[pred_tc_table_index] : 1'b0;
                assign btb_pred_tc_set_data[(TC_WAY_NUM*PC_BITS + TC_WAY_NUM*TC_TAG_BITS + TC_WAY_NUM + TC_WAY_NUM*3) - 1 - bpu_btb_tc_way_g*3 -: 3] =
                    btb_pred_tc_re ? btb_tc_useful_table[pred_tc_table_index] : 3'b000;
                assign btb_upd_tc_set_data[(TC_WAY_NUM*PC_BITS) - 1 - bpu_btb_tc_way_g*PC_BITS -: PC_BITS] =
                    btb_upd_tc_re ? btb_tc_target_table[upd_tc_table_index] : {PC_BITS{1'b0}};
                assign btb_upd_tc_set_data[(TC_WAY_NUM*PC_BITS + TC_WAY_NUM*TC_TAG_BITS) - 1 - bpu_btb_tc_way_g*TC_TAG_BITS -: TC_TAG_BITS] =
                    btb_upd_tc_re ? btb_tc_tag_table[upd_tc_table_index] : {TC_TAG_BITS{1'b0}};
                assign btb_upd_tc_set_data[(TC_WAY_NUM*PC_BITS + TC_WAY_NUM*TC_TAG_BITS + TC_WAY_NUM) - 1 - bpu_btb_tc_way_g] =
                    btb_upd_tc_re ? btb_tc_valid_table[upd_tc_table_index] : 1'b0;
                assign btb_upd_tc_set_data[(TC_WAY_NUM*PC_BITS + TC_WAY_NUM*TC_TAG_BITS + TC_WAY_NUM + TC_WAY_NUM*3) - 1 - bpu_btb_tc_way_g*3 -: 3] =
                    btb_upd_tc_re ? btb_tc_useful_table[upd_tc_table_index] : 3'b000;
            end

            wire [W_BtbStateInput-1:0] btb_state_input_this = {
                btb_state_reg[bpu_state_read_bank_g],
                btb_do_pred_latch_reg[bpu_state_read_bank_g],
                btb_do_upd_latch_reg[bpu_state_read_bank_g],
                btb_upd_pc_latch_reg[bpu_state_read_bank_g],
                btb_upd_actual_addr_latch_reg[bpu_state_read_bank_g],
                btb_upd_br_type_latch_reg[bpu_state_read_bank_g],
                btb_upd_actual_dir_latch_reg[bpu_state_read_bank_g],
                btb_pred_calc_pc_latch_reg[bpu_state_read_bank_g],
                btb_pred_calc_btb_tag_latch_reg[bpu_state_read_bank_g],
                btb_pred_calc_btb_idx_latch_reg[bpu_state_read_bank_g],
                btb_pred_calc_type_idx_latch_reg[bpu_state_read_bank_g],
                btb_pred_calc_bht_idx_latch_reg[bpu_state_read_bank_g],
                btb_upd_calc_next_bht_val_latch_reg[bpu_state_read_bank_g],
                btb_upd_calc_hit_info_latch_reg[bpu_state_read_bank_g],
                btb_upd_calc_victim_way_latch_reg[bpu_state_read_bank_g],
                btb_upd_calc_w_target_way_latch_reg[bpu_state_read_bank_g],
                btb_upd_calc_next_useful_val_latch_reg[bpu_state_read_bank_g],
                btb_upd_calc_writes_btb_latch_reg[bpu_state_read_bank_g]
            };
            wire [W_BtbMemReadResult-1:0] btb_mem_zero = {W_BtbMemReadResult{1'b0}};
            wire [52:0] btb_idx_zero = 53'b0;

            assign btb_read_data_pre_bundle_all[bpu_state_read_bank_g*W_BtbReadData +: W_BtbReadData] = {
                btb_state_input_this,
                btb_idx_zero,
                btb_mem_zero,
                btb_idx_zero,
                btb_mem_zero,
                btb_sram_delay_active_reg[bpu_state_read_bank_g],
                btb_sram_delay_counter_reg[bpu_state_read_bank_g],
                btb_sram_delayed_data_reg[bpu_state_read_bank_g],
                1'b0,
                {W_BtbMemReadResult{1'b0}},
                btb_sram_prng_state_reg[bpu_state_read_bank_g],
                btb_pred_read_valid,
                btb_pred_btb_idx,
                btb_pred_type_idx,
                btb_pred_bht_idx,
                {TC_IDX_BITS{1'b0}},
                btb_pred_tag,
                3'b000,
                btb_pred_read_valid ? btb_bht_table[(bpu_state_read_bank_g * BHT_ENTRY_NUM) + btb_pred_bht_idx] : {BHT_HIST_BITS{1'b0}},
                btb_pred_set_data,
                {W_TcSetData{1'b0}},
                btb_upd_read_valid,
                btb_upd_btb_idx,
                btb_upd_type_idx,
                btb_upd_bht_idx,
                btb_upd_tag,
                btb_upd_read_valid ? btb_bht_table[(bpu_state_read_bank_g * BHT_ENTRY_NUM) + btb_upd_bht_idx] : {BHT_HIST_BITS{1'b0}},
                {BHT_HIST_BITS{1'b0}},
                btb_upd_set_data,
                1'b0,
                {TC_IDX_BITS{1'b0}},
                {TC_TAG_BITS{1'b0}},
                {W_TcSetData{1'b0}}
            };
            assign btb_read_data_bundle_all[bpu_state_read_bank_g*W_BtbReadData +: W_BtbReadData] = {
                btb_state_input_this,
                btb_idx_zero,
                btb_mem_zero,
                btb_idx_zero,
                btb_mem_zero,
                btb_sram_delay_active_reg[bpu_state_read_bank_g],
                btb_sram_delay_counter_reg[bpu_state_read_bank_g],
                btb_sram_delayed_data_reg[bpu_state_read_bank_g],
                1'b0,
                {W_BtbMemReadResult{1'b0}},
                btb_sram_prng_state_reg[bpu_state_read_bank_g],
                btb_pred_read_valid,
                btb_pred_btb_idx,
                btb_pred_type_idx,
                btb_pred_bht_idx,
                btb_pred_tc_idx,
                btb_pred_tag,
                3'b000,
                btb_pred_read_valid ? btb_bht_table[(bpu_state_read_bank_g * BHT_ENTRY_NUM) + btb_pred_bht_idx] : {BHT_HIST_BITS{1'b0}},
                btb_pred_set_data,
                btb_pred_tc_set_data,
                btb_upd_read_valid,
                btb_upd_btb_idx,
                btb_upd_type_idx,
                btb_upd_bht_idx,
                btb_upd_tag,
                btb_upd_read_valid ? btb_bht_table[(bpu_state_read_bank_g * BHT_ENTRY_NUM) + btb_upd_bht_idx] : {BHT_HIST_BITS{1'b0}},
                btb_upd_next_bht,
                btb_upd_set_data,
                btb_upd_tc_re,
                btb_upd_tc_idx,
                btb_upd_tc_tag,
                btb_upd_tc_set_data
            };
        end
    endgenerate

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
        type_pred_read_data_bundle
    };
    // 子预测器结果汇总，再送入 predict_main。
    assign bpu_submodule_bind_input_bundle = {
        pre_do_pred_on_this_pc,
        pre_this_pc_bank_sel,
        post_btb_in,
        type_output_payload
    };

    // C++ 里 TAGE/BTB 都按 BPU_BANK_NUM 独立调用。
    // 这里每个 bank 单独拼接输入，避免只取低位 bank 后复制给所有 bank。
    // bpu_submodule_bind 会把 TypePredictor 结果合并进 BTB 输入，
    // 所以后续 BTB post_read/comb 使用 btb_in_with_type_all。
    wire [BPU_BANK_NUM*W_BtbInputPayload-1:0] btb_in_with_type_all =
        bpu_submodule_bind_payload;

    genvar bpu_input_bank_g;
    generate
        for (bpu_input_bank_g = 0; bpu_input_bank_g < BPU_BANK_NUM;
             bpu_input_bank_g = bpu_input_bank_g + 1) begin : gen_bpu_input_bank
            assign tage_pre_read_input_bundle_all[
                bpu_input_bank_g*W_TagePreReadCombIn +: W_TagePreReadCombIn
            ] = {
                post_tage_in[bpu_input_bank_g*W_TageInputPayload +: W_TageInputPayload],
                tage_state_input_bundle_all[bpu_input_bank_g*W_TageStateInput +: W_TageStateInput]
            };

            assign tage_input_bundle_all[
                bpu_input_bank_g*W_TageCombIn +: W_TageCombIn
            ] = {
                post_tage_in[bpu_input_bank_g*W_TageInputPayload +: W_TageInputPayload],
                tage_read_data_bundle_all[bpu_input_bank_g*W_TageReadData +: W_TageReadData]
            };

            assign btb_pre_read_input_bundle_all[
                bpu_input_bank_g*W_BtbPreReadCombIn +: W_BtbPreReadCombIn
            ] = btb_in_with_type_all[
                bpu_input_bank_g*W_BtbInputPayload +: W_BtbInputPayload
            ];

            assign btb_post_read_req_input_bundle_all[
                bpu_input_bank_g*W_BtbPostReadReqCombIn +: W_BtbPostReadReqCombIn
            ] = {
                btb_in_with_type_all[bpu_input_bank_g*W_BtbInputPayload +: W_BtbInputPayload],
                btb_read_data_pre_bundle_all[bpu_input_bank_g*W_BtbReadData +: W_BtbReadData]
            };

            assign btb_input_bundle_all[
                bpu_input_bank_g*W_BtbCombIn +: W_BtbCombIn
            ] = {
                btb_in_with_type_all[bpu_input_bank_g*W_BtbInputPayload +: W_BtbInputPayload],
                btb_read_data_bundle_all[bpu_input_bank_g*W_BtbReadData +: W_BtbReadData]
            };
        end
    endgenerate

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

    // 第 4 组：预测器结果汇总与主预测输出。
    // submodule_bind 先把 TypePredictor 的类型结果并入 BTB 输入。
    bpu_submodule_bind_comb_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuSubmoduleBindCombIn),
        .W_BpuSubmoduleBindCombOut(W_BpuSubmoduleBindCombOut)
    ) u_bpu_submodule_bind_comb_top (
        .bpu_submodule_bind_input_bundle(bpu_submodule_bind_input_bundle),
        .bpu_submodule_bind_bundle(bpu_submodule_bind_payload)
    );

    // TAGE/BTB 与 C++ 一样按 bank 独立展开。
    // 每个 bank 都有自己的 pre_read/post_read/comb 边界，后续 BSD 也按同一位序补逻辑。
    genvar bpu_comb_bank_g;
    generate
        for (bpu_comb_bank_g = 0; bpu_comb_bank_g < BPU_BANK_NUM;
             bpu_comb_bank_g = bpu_comb_bank_g + 1) begin : gen_bpu_comb_bank
            tage_pre_read_comb_top #(
                .W_TagePreReadCombIn(W_TagePreReadCombIn),
                .W_TagePreReadCombOut(W_TagePreReadCombOut)
            ) u_tage_pre_read_comb_top (
                .bpu_pre_read_req_bundle(
                    tage_pre_read_input_bundle_all[
                        bpu_comb_bank_g*W_TagePreReadCombIn +: W_TagePreReadCombIn
                    ]
                ),
                .tage_pre_read_bundle(
                    tage_pre_read_payload_all[
                        bpu_comb_bank_g*W_TagePreReadCombOut +: W_TagePreReadCombOut
                    ]
                )
            );

            tage_comb_top #(
                .W_TageCombIn(W_TageCombIn),
                .W_TageCombOut(W_TageCombOut)
            ) u_tage_comb_top (
                .tage_input_bundle(
                    tage_input_bundle_all[
                        bpu_comb_bank_g*W_TageCombIn +: W_TageCombIn
                    ]
                ),
                .tage_bundle(
                    tage_payload_all[
                        bpu_comb_bank_g*W_TageCombOut +: W_TageCombOut
                    ]
                )
            );

            btb_pre_read_comb_top #(
                .W_BtbPreReadCombIn(W_BtbPreReadCombIn),
                .W_BtbPreReadCombOut(W_BtbPreReadCombOut)
            ) u_btb_pre_read_comb_top (
                .bpu_pre_read_req_bundle(
                    btb_pre_read_input_bundle_all[
                        bpu_comb_bank_g*W_BtbPreReadCombIn +: W_BtbPreReadCombIn
                    ]
                ),
                .btb_pre_read_bundle(
                    btb_pre_read_payload_all[
                        bpu_comb_bank_g*W_BtbPreReadCombOut +: W_BtbPreReadCombOut
                    ]
                )
            );

            btb_post_read_req_comb_top #(
                .W_BtbPostReadReqCombIn(W_BtbPostReadReqCombIn),
                .W_BtbPostReadReqCombOut(W_BtbPostReadReqCombOut)
            ) u_btb_post_read_req_comb_top (
                .btb_post_read_req_input_bundle(
                    btb_post_read_req_input_bundle_all[
                        bpu_comb_bank_g*W_BtbPostReadReqCombIn +: W_BtbPostReadReqCombIn
                    ]
                ),
                .btb_post_read_req_bundle(
                    btb_post_read_req_payload_all[
                        bpu_comb_bank_g*W_BtbPostReadReqCombOut +: W_BtbPostReadReqCombOut
                    ]
                )
            );

            btb_comb_top #(
                .W_BtbCombIn(W_BtbCombIn),
                .W_BtbCombOut(W_BtbCombOut)
            ) u_btb_comb_top (
                .btb_post_read_req_bundle(
                    btb_input_bundle_all[
                        bpu_comb_bank_g*W_BtbCombIn +: W_BtbCombIn
                    ]
                ),
                .btb_bundle(
                    btb_payload_all[
                        bpu_comb_bank_g*W_BtbCombOut +: W_BtbCombOut
                    ]
                )
            );
        end
    endgenerate

    // predict_main 汇总 Type/TAGE/BTB 的输出，生成 BPU 对 front_top 的输出候选。
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
    reg [31:0] bpu_state_bank_i;
    reg [31:0] bpu_state_way_i;
    reg [31:0] bpu_state_scl_i;
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
            // TypePredictor/TAGE/BTB 的表状态不属于 27 个 BSD comb，本层需要真实保存。
            for (bpu_state_i = 0; bpu_state_i < TYPE_PRED_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                type_pred_table[bpu_state_i] <= {W_TypePredEntry{1'b0}};
            end
            for (bpu_state_bank_i = 0; bpu_state_bank_i < BPU_BANK_NUM; bpu_state_bank_i = bpu_state_bank_i + 1) begin
                tage_state_reg[bpu_state_bank_i] <= 2'b00;
                tage_lsfr_reg[bpu_state_bank_i] <= 4'b0001;
                tage_reset_cnt_reg[bpu_state_bank_i] <= {TAGE_RESET_CTR_BITS{1'b0}};
                tage_use_alt_ctr_reg[bpu_state_bank_i] <= 4'd7;
                tage_scl_theta_reg[bpu_state_bank_i] <= 16'd18;
                tage_do_pred_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_do_upd_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_real_dir_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                tage_upd_pred_in_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_alt_pred_in_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_pcpn_in_latch_reg[bpu_state_bank_i] <= {PCPN_BITS{1'b0}};
                tage_upd_altpcpn_in_latch_reg[bpu_state_bank_i] <= {PCPN_BITS{1'b0}};
                tage_upd_tag_flat_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_TAG_BITS){1'b0}};
                tage_upd_idx_flat_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_IDX_BITS){1'b0}};
                tage_pred_calc_base_idx_latch_reg[bpu_state_bank_i] <= {TAGE_BASE_IDX_BITS{1'b0}};
                tage_pred_calc_idx_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_IDX_BITS){1'b0}};
                tage_pred_calc_tag_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_TAG_BITS){1'b0}};
                tage_pred_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                tage_upd_calc_winfo_latch_reg[bpu_state_bank_i] <= {W_TageUpdateRequest{1'b0}};
                tage_sram_delay_active_reg[bpu_state_bank_i] <= 1'b0;
                tage_sram_delay_counter_reg[bpu_state_bank_i] <= 32'b0;
                tage_sram_delayed_data_reg[bpu_state_bank_i] <= {W_TageTableReadData{1'b0}};
                tage_sram_prng_state_reg[bpu_state_bank_i] <= 32'h1357_9bdf;
                btb_state_reg[bpu_state_bank_i] <= 2'b00;
                btb_do_pred_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_do_upd_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_upd_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                btb_upd_actual_addr_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                btb_upd_br_type_latch_reg[bpu_state_bank_i] <= {BR_TYPE_BITS{1'b0}};
                btb_upd_actual_dir_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_pred_calc_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                btb_pred_calc_btb_tag_latch_reg[bpu_state_bank_i] <= {BTB_TAG_BITS{1'b0}};
                btb_pred_calc_btb_idx_latch_reg[bpu_state_bank_i] <= {BTB_IDX_BITS{1'b0}};
                btb_pred_calc_type_idx_latch_reg[bpu_state_bank_i] <= {BTB_TYPE_IDX_BITS{1'b0}};
                btb_pred_calc_bht_idx_latch_reg[bpu_state_bank_i] <= {BHT_IDX_BITS{1'b0}};
                btb_upd_calc_next_bht_val_latch_reg[bpu_state_bank_i] <= {BHT_HIST_BITS{1'b0}};
                btb_upd_calc_hit_info_latch_reg[bpu_state_bank_i] <= 3'b000;
                btb_upd_calc_victim_way_latch_reg[bpu_state_bank_i] <= {BTB_WAY_BITS{1'b0}};
                btb_upd_calc_w_target_way_latch_reg[bpu_state_bank_i] <= {TC_WAY_BITS{1'b0}};
                btb_upd_calc_next_useful_val_latch_reg[bpu_state_bank_i] <= 3'b000;
                btb_upd_calc_writes_btb_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_sram_delay_active_reg[bpu_state_bank_i] <= 1'b0;
                btb_sram_delay_counter_reg[bpu_state_bank_i] <= 32'b0;
                btb_sram_delayed_data_reg[bpu_state_bank_i] <= {W_BtbMemReadResult{1'b0}};
                btb_sram_prng_state_reg[bpu_state_bank_i] <= 32'h2468_ace1;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_BASE_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_base_counter_table[bpu_state_i] <= 2'b00;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_TN_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_tag_table[bpu_state_i] <= {TAGE_TAG_BITS{1'b0}};
                tage_cnt_table[bpu_state_i] <= 3'b000;
                tage_useful_table[bpu_state_i] <= 2'b00;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_SC_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_sc_ctr_table[bpu_state_i] <= 2'd1;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_SCL_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_scl_table[bpu_state_i] <= 6'd32;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_LOOP_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_loop_table[bpu_state_i] <= {W_TageLoopEntry{1'b0}};
            end
            for (bpu_state_i = 0; bpu_state_i < BTB_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                btb_tag_table[bpu_state_i] <= {BTB_TAG_BITS{1'b0}};
                btb_bta_table[bpu_state_i] <= {PC_BITS{1'b0}};
                btb_valid_table[bpu_state_i] <= 1'b0;
                btb_useful_table[bpu_state_i] <= 3'b000;
            end
            for (bpu_state_i = 0; bpu_state_i < BHT_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                btb_bht_table[bpu_state_i] <= {BHT_HIST_BITS{1'b0}};
            end
            for (bpu_state_i = 0; bpu_state_i < TC_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                btb_tc_target_table[bpu_state_i] <= {PC_BITS{1'b0}};
                btb_tc_tag_table[bpu_state_i] <= {TC_TAG_BITS{1'b0}};
                btb_tc_valid_table[bpu_state_i] <= 1'b0;
                btb_tc_useful_table[bpu_state_i] <= 3'b000;
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
            // 同步 reset 也按 C++ 初始化路径清空内部表状态。
            for (bpu_state_i = 0; bpu_state_i < TYPE_PRED_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                type_pred_table[bpu_state_i] <= {W_TypePredEntry{1'b0}};
            end
            for (bpu_state_bank_i = 0; bpu_state_bank_i < BPU_BANK_NUM; bpu_state_bank_i = bpu_state_bank_i + 1) begin
                tage_state_reg[bpu_state_bank_i] <= 2'b00;
                tage_lsfr_reg[bpu_state_bank_i] <= 4'b0001;
                tage_reset_cnt_reg[bpu_state_bank_i] <= {TAGE_RESET_CTR_BITS{1'b0}};
                tage_use_alt_ctr_reg[bpu_state_bank_i] <= 4'd7;
                tage_scl_theta_reg[bpu_state_bank_i] <= 16'd18;
                tage_do_pred_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_do_upd_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_real_dir_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                tage_upd_pred_in_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_alt_pred_in_latch_reg[bpu_state_bank_i] <= 1'b0;
                tage_upd_pcpn_in_latch_reg[bpu_state_bank_i] <= {PCPN_BITS{1'b0}};
                tage_upd_altpcpn_in_latch_reg[bpu_state_bank_i] <= {PCPN_BITS{1'b0}};
                tage_upd_tag_flat_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_TAG_BITS){1'b0}};
                tage_upd_idx_flat_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_IDX_BITS){1'b0}};
                tage_pred_calc_base_idx_latch_reg[bpu_state_bank_i] <= {TAGE_BASE_IDX_BITS{1'b0}};
                tage_pred_calc_idx_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_IDX_BITS){1'b0}};
                tage_pred_calc_tag_latch_reg[bpu_state_bank_i] <= {(TN_MAX*TAGE_TAG_BITS){1'b0}};
                tage_pred_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                tage_upd_calc_winfo_latch_reg[bpu_state_bank_i] <= {W_TageUpdateRequest{1'b0}};
                tage_sram_delay_active_reg[bpu_state_bank_i] <= 1'b0;
                tage_sram_delay_counter_reg[bpu_state_bank_i] <= 32'b0;
                tage_sram_delayed_data_reg[bpu_state_bank_i] <= {W_TageTableReadData{1'b0}};
                tage_sram_prng_state_reg[bpu_state_bank_i] <= 32'h1357_9bdf;
                btb_state_reg[bpu_state_bank_i] <= 2'b00;
                btb_do_pred_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_do_upd_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_upd_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                btb_upd_actual_addr_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                btb_upd_br_type_latch_reg[bpu_state_bank_i] <= {BR_TYPE_BITS{1'b0}};
                btb_upd_actual_dir_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_pred_calc_pc_latch_reg[bpu_state_bank_i] <= {PC_BITS{1'b0}};
                btb_pred_calc_btb_tag_latch_reg[bpu_state_bank_i] <= {BTB_TAG_BITS{1'b0}};
                btb_pred_calc_btb_idx_latch_reg[bpu_state_bank_i] <= {BTB_IDX_BITS{1'b0}};
                btb_pred_calc_type_idx_latch_reg[bpu_state_bank_i] <= {BTB_TYPE_IDX_BITS{1'b0}};
                btb_pred_calc_bht_idx_latch_reg[bpu_state_bank_i] <= {BHT_IDX_BITS{1'b0}};
                btb_upd_calc_next_bht_val_latch_reg[bpu_state_bank_i] <= {BHT_HIST_BITS{1'b0}};
                btb_upd_calc_hit_info_latch_reg[bpu_state_bank_i] <= 3'b000;
                btb_upd_calc_victim_way_latch_reg[bpu_state_bank_i] <= {BTB_WAY_BITS{1'b0}};
                btb_upd_calc_w_target_way_latch_reg[bpu_state_bank_i] <= {TC_WAY_BITS{1'b0}};
                btb_upd_calc_next_useful_val_latch_reg[bpu_state_bank_i] <= 3'b000;
                btb_upd_calc_writes_btb_latch_reg[bpu_state_bank_i] <= 1'b0;
                btb_sram_delay_active_reg[bpu_state_bank_i] <= 1'b0;
                btb_sram_delay_counter_reg[bpu_state_bank_i] <= 32'b0;
                btb_sram_delayed_data_reg[bpu_state_bank_i] <= {W_BtbMemReadResult{1'b0}};
                btb_sram_prng_state_reg[bpu_state_bank_i] <= 32'h2468_ace1;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_BASE_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_base_counter_table[bpu_state_i] <= 2'b00;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_TN_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_tag_table[bpu_state_i] <= {TAGE_TAG_BITS{1'b0}};
                tage_cnt_table[bpu_state_i] <= 3'b000;
                tage_useful_table[bpu_state_i] <= 2'b00;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_SC_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_sc_ctr_table[bpu_state_i] <= 2'd1;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_SCL_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_scl_table[bpu_state_i] <= 6'd32;
            end
            for (bpu_state_i = 0; bpu_state_i < TAGE_LOOP_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                tage_loop_table[bpu_state_i] <= {W_TageLoopEntry{1'b0}};
            end
            for (bpu_state_i = 0; bpu_state_i < BTB_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                btb_tag_table[bpu_state_i] <= {BTB_TAG_BITS{1'b0}};
                btb_bta_table[bpu_state_i] <= {PC_BITS{1'b0}};
                btb_valid_table[bpu_state_i] <= 1'b0;
                btb_useful_table[bpu_state_i] <= 3'b000;
            end
            for (bpu_state_i = 0; bpu_state_i < BHT_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                btb_bht_table[bpu_state_i] <= {BHT_HIST_BITS{1'b0}};
            end
            for (bpu_state_i = 0; bpu_state_i < TC_TABLE_DEPTH; bpu_state_i = bpu_state_i + 1) begin
                btb_tc_target_table[bpu_state_i] <= {PC_BITS{1'b0}};
                btb_tc_tag_table[bpu_state_i] <= {TC_TAG_BITS{1'b0}};
                btb_tc_valid_table[bpu_state_i] <= 1'b0;
                btb_tc_useful_table[bpu_state_i] <= 3'b000;
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
            // TypePredictor 表写回。comb 只给出写请求，本层按 bank/set/way 写真实表项。
            for (bpu_state_i = 0; bpu_state_i < COMMIT_WIDTH; bpu_state_i = bpu_state_i + 1) begin
                if (type_pred_comb_result[TYPE_REQ_WRITE_EN_LSB + bpu_state_i]) begin
                    type_pred_table[
                        ((({{(32-BPU_BANK_SEL_BITS){1'b0}},
                            type_pred_comb_result[
                                TYPE_REQ_WRITE_BANK_LSB + bpu_state_i*BPU_BANK_SEL_BITS +: BPU_BANK_SEL_BITS
                            ]} * TYPE_PRED_SET_NUM)
                        + {{(32-TYPE_PRED_SET_IDX_BITS){1'b0}},
                            type_pred_comb_result[
                                TYPE_REQ_WRITE_SET_LSB + bpu_state_i*TYPE_PRED_SET_IDX_BITS +: TYPE_PRED_SET_IDX_BITS
                            ]}) * TYPE_PRED_WAY_NUM)
                        + {{(32-TYPE_PRED_WAY_BITS){1'b0}},
                            type_pred_comb_result[
                                TYPE_REQ_WRITE_WAY_LSB + bpu_state_i*TYPE_PRED_WAY_BITS +: TYPE_PRED_WAY_BITS
                            ]}
                    ] <= type_pred_comb_result[
                        TYPE_REQ_WRITE_ENTRY_LSB + bpu_state_i*W_TypePredEntry +: W_TypePredEntry
                    ];
                end
            end

            // TAGE 每个 bank 独立写回，覆盖表项、延迟读状态和下一拍锁存值。
            for (bpu_state_bank_i = 0; bpu_state_bank_i < BPU_BANK_NUM; bpu_state_bank_i = bpu_state_bank_i + 1) begin
                tage_state_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_NEXT_STATE_LSB +: 2
                ];
                if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_BASE_WE_LSB]) begin
                    tage_base_counter_table[
                        (bpu_state_bank_i * BASE_ENTRY_NUM)
                        + {{(32-TAGE_BASE_IDX_BITS){1'b0}},
                            tage_comb_result_all[
                                bpu_state_bank_i*W_TageCombResult + TAGE_REQ_BASE_IDX_LSB +: TAGE_BASE_IDX_BITS
                            ]}
                    ] <= tage_comb_result_all[
                        bpu_state_bank_i*W_TageCombResult + TAGE_REQ_BASE_DATA_LSB +: 2
                    ];
                end
                if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SC_WE_LSB]) begin
                    tage_sc_ctr_table[
                        (bpu_state_bank_i * TAGE_SC_ENTRY_NUM)
                        + {{(32-TAGE_SC_IDX_BITS){1'b0}},
                            tage_comb_result_all[
                                bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SC_IDX_LSB +: TAGE_SC_IDX_BITS
                            ]}
                    ] <= tage_comb_result_all[
                        bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SC_DATA_LSB +: TAGE_SC_CTR_BITS
                    ];
                end
                if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SCL_THETA_WE_LSB]) begin
                    tage_scl_theta_reg[bpu_state_bank_i] <= tage_comb_result_all[
                        bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SCL_THETA_DATA_LSB +: TAGE_SC_L_THETA_BITS
                    ];
                end
                if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LSFR_WE_LSB]) begin
                    tage_lsfr_reg[bpu_state_bank_i] <= tage_comb_result_all[
                        bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LSFR_NEXT_LSB +: 4
                    ];
                end
                if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_USE_ALT_WE_LSB]) begin
                    tage_use_alt_ctr_reg[bpu_state_bank_i] <= tage_comb_result_all[
                        bpu_state_bank_i*W_TageCombResult + TAGE_REQ_USE_ALT_NEXT_LSB +: TAGE_USE_ALT_CTR_BITS
                    ];
                end
                if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_RESET_CNT_WE_LSB]) begin
                    tage_reset_cnt_reg[bpu_state_bank_i] <= tage_comb_result_all[
                        bpu_state_bank_i*W_TageCombResult + TAGE_REQ_RESET_CNT_NEXT_LSB +: TAGE_RESET_CTR_BITS
                    ];
                end
                if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_WE_LSB]) begin
                    tage_loop_table[
                        (bpu_state_bank_i * TAGE_LOOP_ENTRY_NUM)
                        + {{(32-TAGE_LOOP_TABLE_IDX_BITS){1'b0}},
                            tage_comb_result_all[
                                bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_WR_IDX_LSB +: TAGE_LOOP_TABLE_IDX_BITS
                            ]}
                    ] <= {
                        tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_VALID_LSB],
                        tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_TAG_LSB +: TAGE_LOOP_TAG_BITS],
                        tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_LIMIT_LSB +: TAGE_LOOP_ITER_BITS],
                        tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_COUNT_LSB +: TAGE_LOOP_ITER_BITS],
                        tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_CONF_LSB +: TAGE_LOOP_CONF_BITS],
                        tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_AGE_LSB +: TAGE_LOOP_AGE_BITS],
                        tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_LOOP_DIR_LSB]
                    };
                end
                for (bpu_state_scl_i = 0; bpu_state_scl_i < BPU_SCL_META_NTABLE; bpu_state_scl_i = bpu_state_scl_i + 1) begin
                    if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SCL_WE_LSB]) begin
                        tage_scl_table[
                            ((bpu_state_bank_i * BPU_SCL_META_NTABLE + bpu_state_scl_i) * TAGE_SC_L_ENTRY_NUM)
                            + {{(32-TAGE_SC_L_IDX_BITS){1'b0}},
                                tage_comb_result_all[
                                    bpu_state_bank_i*W_TageCombResult
                                    + TAGE_REQ_SCL_IDX_LSB
                                    + bpu_state_scl_i*BPU_SCL_META_IDX_BITS +: TAGE_SC_L_IDX_BITS
                                ]}
                        ] <= tage_comb_result_all[
                            bpu_state_bank_i*W_TageCombResult
                            + TAGE_REQ_SCL_DATA_LSB
                            + bpu_state_scl_i*TAGE_SC_L_CTR_BITS +: TAGE_SC_L_CTR_BITS
                        ];
                    end
                end
                for (bpu_state_way_i = 0; bpu_state_way_i < TN_MAX; bpu_state_way_i = bpu_state_way_i + 1) begin
                    if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_TAG_WE_LSB]) begin
                        tage_tag_table[
                            ((bpu_state_bank_i * TN_MAX + bpu_state_way_i) * TN_ENTRY_NUM)
                            + {{(32-TAGE_IDX_BITS){1'b0}},
                                tage_comb_result_all[
                                    bpu_state_bank_i*W_TageCombResult
                                    + TAGE_REQ_TAG_IDX_LSB
                                    + bpu_state_way_i*TAGE_IDX_BITS +: TAGE_IDX_BITS
                                ]}
                        ] <= tage_comb_result_all[
                            bpu_state_bank_i*W_TageCombResult
                            + TAGE_REQ_TAG_DATA_LSB
                            + bpu_state_way_i*TAGE_TAG_BITS +: TAGE_TAG_BITS
                        ];
                    end
                    if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_CNT_WE_LSB]) begin
                        tage_cnt_table[
                            ((bpu_state_bank_i * TN_MAX + bpu_state_way_i) * TN_ENTRY_NUM)
                            + {{(32-TAGE_IDX_BITS){1'b0}},
                                tage_comb_result_all[
                                    bpu_state_bank_i*W_TageCombResult
                                    + TAGE_REQ_CNT_IDX_LSB
                                    + bpu_state_way_i*TAGE_IDX_BITS +: TAGE_IDX_BITS
                                ]}
                        ] <= tage_comb_result_all[
                            bpu_state_bank_i*W_TageCombResult
                            + TAGE_REQ_CNT_DATA_LSB
                            + bpu_state_way_i*3 +: 3
                        ];
                    end
                    if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_USEFUL_WE_LSB]) begin
                        tage_useful_table[
                            ((bpu_state_bank_i * TN_MAX + bpu_state_way_i) * TN_ENTRY_NUM)
                            + {{(32-TAGE_IDX_BITS){1'b0}},
                                tage_comb_result_all[
                                    bpu_state_bank_i*W_TageCombResult
                                    + TAGE_REQ_USEFUL_IDX_LSB
                                    + bpu_state_way_i*TAGE_IDX_BITS +: TAGE_IDX_BITS
                                ]}
                        ] <= tage_comb_result_all[
                            bpu_state_bank_i*W_TageCombResult
                            + TAGE_REQ_USEFUL_DATA_LSB
                            + bpu_state_way_i*2 +: 2
                        ];
                    end
                    if (tage_comb_result_all[bpu_state_bank_i*W_TageCombResult + TAGE_REQ_USEFUL_RESET_WE_LSB]) begin
                        tage_useful_table[
                            ((bpu_state_bank_i * TN_MAX + bpu_state_way_i) * TN_ENTRY_NUM)
                            + {{(32-TAGE_IDX_BITS){1'b0}},
                                tage_comb_result_all[
                                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_USEFUL_RESET_ROW_LSB +: TAGE_IDX_BITS
                                ]}
                        ] <= tage_comb_result_all[
                            bpu_state_bank_i*W_TageCombResult
                            + TAGE_REQ_USEFUL_RESET_DATA_LSB
                            + bpu_state_way_i*2 +: 2
                        ];
                    end
                end
                tage_upd_calc_winfo_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_WINFO_NEXT_LSB +: W_TageUpdateRequest
                ];
                tage_pred_pc_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_PRED_PC_NEXT_LSB +: PC_BITS
                ];
                tage_pred_calc_tag_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_PRED_TAG_NEXT_LSB +: (TN_MAX*TAGE_TAG_BITS)
                ];
                tage_pred_calc_idx_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_PRED_IDX_NEXT_LSB +: (TN_MAX*TAGE_IDX_BITS)
                ];
                tage_pred_calc_base_idx_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_PRED_BASE_NEXT_LSB +: TAGE_BASE_IDX_BITS
                ];
                tage_upd_idx_flat_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_IDX_NEXT_LSB +: (TN_MAX*TAGE_IDX_BITS)
                ];
                tage_upd_tag_flat_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_TAG_NEXT_LSB +: (TN_MAX*TAGE_TAG_BITS)
                ];
                tage_upd_altpcpn_in_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_ALTPCPN_NEXT_LSB +: PCPN_BITS
                ];
                tage_upd_pcpn_in_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_PCPN_NEXT_LSB +: PCPN_BITS
                ];
                tage_upd_alt_pred_in_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_ALT_NEXT_LSB
                ];
                tage_upd_pred_in_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_PRED_NEXT_LSB
                ];
                tage_upd_pc_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_PC_NEXT_LSB +: PC_BITS
                ];
                tage_upd_real_dir_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_UPD_REAL_NEXT_LSB
                ];
                tage_do_upd_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_DO_UPD_NEXT_LSB
                ];
                tage_do_pred_latch_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_DO_PRED_NEXT_LSB
                ];
                tage_sram_prng_state_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SRAM_PRNG_NEXT_LSB +: 32
                ];
                tage_sram_delayed_data_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SRAM_DELAY_DATA_NEXT_LSB +: W_TageTableReadData
                ];
                tage_sram_delay_counter_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SRAM_DELAY_COUNT_NEXT_LSB +: 32
                ];
                tage_sram_delay_active_reg[bpu_state_bank_i] <= tage_comb_result_all[
                    bpu_state_bank_i*W_TageCombResult + TAGE_REQ_SRAM_DELAY_ACTIVE_NEXT_LSB
                ];

                // BTB/BHT/TC 表写回和下一拍锁存值。
                btb_state_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_NEXT_STATE_LSB +: 2
                ];
                if (btb_comb_result_all[bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_WE_LSB]) begin
                    btb_tag_table[
                        ((bpu_state_bank_i * BTB_WAY_NUM
                        + {{(32-BTB_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_WAY_LSB +: BTB_WAY_BITS
                            ]}) * BTB_ENTRY_NUM)
                        + {{(32-BTB_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_IDX_LSB +: BTB_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[
                        bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_TAG_LSB +: BTB_TAG_BITS
                    ];
                    btb_bta_table[
                        ((bpu_state_bank_i * BTB_WAY_NUM
                        + {{(32-BTB_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_WAY_LSB +: BTB_WAY_BITS
                            ]}) * BTB_ENTRY_NUM)
                        + {{(32-BTB_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_IDX_LSB +: BTB_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[
                        bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_BTA_LSB +: PC_BITS
                    ];
                    btb_valid_table[
                        ((bpu_state_bank_i * BTB_WAY_NUM
                        + {{(32-BTB_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_WAY_LSB +: BTB_WAY_BITS
                            ]}) * BTB_ENTRY_NUM)
                        + {{(32-BTB_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_IDX_LSB +: BTB_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_VALID_LSB];
                    btb_useful_table[
                        ((bpu_state_bank_i * BTB_WAY_NUM
                        + {{(32-BTB_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_WAY_LSB +: BTB_WAY_BITS
                            ]}) * BTB_ENTRY_NUM)
                        + {{(32-BTB_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_IDX_LSB +: BTB_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[
                        bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BTB_USEFUL_LSB +: 3
                    ];
                end
                if (btb_comb_result_all[bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_WE_LSB]) begin
                    btb_tc_target_table[
                        ((bpu_state_bank_i * TC_WAY_NUM
                        + {{(32-TC_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_WAY_LSB +: TC_WAY_BITS
                            ]}) * TC_ENTRY_NUM)
                        + {{(32-TC_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_IDX_LSB +: TC_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[
                        bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_TARGET_LSB +: PC_BITS
                    ];
                    btb_tc_tag_table[
                        ((bpu_state_bank_i * TC_WAY_NUM
                        + {{(32-TC_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_WAY_LSB +: TC_WAY_BITS
                            ]}) * TC_ENTRY_NUM)
                        + {{(32-TC_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_IDX_LSB +: TC_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[
                        bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_TAG_LSB +: TC_TAG_BITS
                    ];
                    btb_tc_valid_table[
                        ((bpu_state_bank_i * TC_WAY_NUM
                        + {{(32-TC_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_WAY_LSB +: TC_WAY_BITS
                            ]}) * TC_ENTRY_NUM)
                        + {{(32-TC_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_IDX_LSB +: TC_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_VALID_LSB];
                    btb_tc_useful_table[
                        ((bpu_state_bank_i * TC_WAY_NUM
                        + {{(32-TC_WAY_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_WAY_LSB +: TC_WAY_BITS
                            ]}) * TC_ENTRY_NUM)
                        + {{(32-TC_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_IDX_LSB +: TC_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[
                        bpu_state_bank_i*W_BtbCombResult + BTB_REQ_TC_USEFUL_LSB +: 3
                    ];
                end
                if (btb_comb_result_all[bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BHT_WE_LSB]) begin
                    btb_bht_table[
                        (bpu_state_bank_i * BHT_ENTRY_NUM)
                        + {{(32-BHT_IDX_BITS){1'b0}},
                            btb_comb_result_all[
                                bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BHT_IDX_LSB +: BHT_IDX_BITS
                            ]}
                    ] <= btb_comb_result_all[
                        bpu_state_bank_i*W_BtbCombResult + BTB_REQ_BHT_DATA_LSB +: BHT_HIST_BITS
                    ];
                end
                btb_upd_calc_writes_btb_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_WRITES_BTB_NEXT_LSB
                ];
                btb_upd_calc_next_useful_val_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_NEXT_USEFUL_NEXT_LSB +: 3
                ];
                btb_upd_calc_w_target_way_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_W_TARGET_NEXT_LSB +: TC_WAY_BITS
                ];
                btb_upd_calc_victim_way_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_VICTIM_NEXT_LSB +: BTB_WAY_BITS
                ];
                btb_upd_calc_hit_info_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_HIT_INFO_NEXT_LSB +: 3
                ];
                btb_upd_calc_next_bht_val_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_NEXT_BHT_NEXT_LSB +: BHT_HIST_BITS
                ];
                btb_pred_calc_bht_idx_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_PRED_BHT_NEXT_LSB +: BHT_IDX_BITS
                ];
                btb_pred_calc_type_idx_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_PRED_TYPE_NEXT_LSB +: BTB_TYPE_IDX_BITS
                ];
                btb_pred_calc_btb_idx_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_PRED_IDX_NEXT_LSB +: BTB_IDX_BITS
                ];
                btb_pred_calc_btb_tag_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_PRED_TAG_NEXT_LSB +: BTB_TAG_BITS
                ];
                btb_pred_calc_pc_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_PRED_PC_NEXT_LSB +: PC_BITS
                ];
                btb_upd_actual_dir_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_DIR_NEXT_LSB
                ];
                btb_upd_br_type_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_TYPE_NEXT_LSB +: BR_TYPE_BITS
                ];
                btb_upd_actual_addr_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_ADDR_NEXT_LSB +: PC_BITS
                ];
                btb_upd_pc_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_UPD_PC_NEXT_LSB +: PC_BITS
                ];
                btb_do_upd_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_DO_UPD_NEXT_LSB
                ];
                btb_do_pred_latch_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_DO_PRED_NEXT_LSB
                ];
                btb_sram_prng_state_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_SRAM_PRNG_NEXT_LSB +: 32
                ];
                btb_sram_delayed_data_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_SRAM_DELAY_DATA_NEXT_LSB +: W_BtbMemReadResult
                ];
                btb_sram_delay_counter_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_SRAM_DELAY_COUNT_NEXT_LSB +: 32
                ];
                btb_sram_delay_active_reg[bpu_state_bank_i] <= btb_comb_result_all[
                    bpu_state_bank_i*W_BtbCombResult + BTB_REQ_SRAM_DELAY_ACTIVE_NEXT_LSB
                ];
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
