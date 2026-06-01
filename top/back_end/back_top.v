// ffc 模拟器后端的顶层连接封装。
//
// 参考来源：
//   simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/back-end/include/BackTop.h
//   simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/back-end/BackTop.cpp
//
// 命名约定：
//   - 模块之间的总线尽量保留 BackTop.h 里的成员名，方便和模拟器逐项核对。
//   - 单生产者到单消费者的方向性总线使用 producer2consumer 形式，例如 dec2ren。
//   - 广播或共享边带沿用模拟器结构体名，例如 rob_bcast、dec_bcast。
//   - 顶层内存/MMIO 端口使用 *_io 后缀，和 BackTop.h 中暴露给外部内存系统的名字一致。
//   - 每个子模块 *_top 只把业务信号打包进 pi/po；clk 和 rst_n 单独连接，
//     不计入 pi/po 位宽，便于组员直接按 BSD 端口接入。
//
// FTQ PC 查询路径按 ffc BackTop.cpp 的一级连接边界组织：
//   PreIduQueue <-> EXU: ftq_exu_pc_req/ftq_exu_pc_resp
//   PreIduQueue <-> ROB: ftq_rob_pc_req/ftq_rob_pc_resp


module back_top #(
    // ---------------------------------------------------------------------
    // 后端基础结构参数。
    // 从 config.h.large 派生的宽度保留模拟器常量名，避免 BSD 对接时重新翻译。
    // ---------------------------------------------------------------------
    parameter integer FETCH_WIDTH              = 16,
    parameter integer DECODE_WIDTH             = 8,
    parameter integer COMMIT_WIDTH             = DECODE_WIDTH,

    parameter integer AREG_IDX_WIDTH           = 6,
    parameter integer PRF_IDX_WIDTH            = 9,
    parameter integer ROB_IDX_WIDTH            = 9,
    parameter integer STQ_IDX_WIDTH            = 6,
    parameter integer LDQ_IDX_WIDTH            = 6,

    parameter integer BR_TAG_WIDTH             = 6,
    parameter integer BR_MASK_WIDTH            = 64,
    parameter integer CSR_IDX_WIDTH            = 12,
    parameter integer FTQ_IDX_WIDTH            = 7,
    parameter integer FTQ_OFFSET_WIDTH         = 4,
    parameter integer INST_TYPE_WIDTH          = 5,
    parameter integer UOP_TYPE_WIDTH           = 5,
    parameter integer ROB_CPLT_MASK_WIDTH      = 3,
    parameter integer W_TmaMeta              = 4,
    parameter integer W_DebugMeta            = 32 + 32 + 8 + 1 + 64,
    parameter integer W_RobDisTmaMeta        = 3,

    // ---------------------------------------------------------------------
    // 前端和 BPU 元数据参数。
    // 这些字段来自 FrontPreIO，会穿过 PreIduQueue 并参与后端回训相关路径。
    // ---------------------------------------------------------------------
    parameter integer IQ_NUM                   = 5,
    parameter integer MAX_UOP_TYPE             = 18,
    parameter integer BPU_SCL_META_NTABLE      = 8,
    parameter integer BPU_SCL_META_IDX_BITS    = 16,
    parameter integer tage_scl_meta_sum_t_BITS = 16,
    parameter integer BPU_LOOP_META_IDX_BITS   = 16,
    parameter integer BPU_LOOP_META_TAG_BITS   = 16,
    parameter integer TN_MAX                   = 4,
    parameter integer TAGE_IDX_WIDTH           = 12,
    parameter integer TAGE_TAG_WIDTH           = 8,
    parameter integer pcpn_t_BITS              = 3,

    // ---------------------------------------------------------------------
    // 发射、执行和 LSU 结构参数。
    // 这里描述后端主要阵列宽度和端口数量，供后续 packed bus 位宽公式复用。
    // ---------------------------------------------------------------------
    parameter integer IQ_READY_NUM_WIDTH       = 8,
    parameter integer MAX_IQ_DISPATCH_WIDTH    = DECODE_WIDTH,
    parameter integer MAX_STQ_DISPATCH_WIDTH   = DECODE_WIDTH,
    parameter integer MAX_LDQ_DISPATCH_WIDTH   = DECODE_WIDTH,
    parameter integer MAX_WAKEUP_PORTS         = 11,
    parameter integer ISSUE_WIDTH              = 15,
    parameter integer TOTAL_FU_COUNT           = 19,
    parameter integer FTQ_EXU_PC_PORT_NUM      = 8,
    parameter integer FTQ_ROB_PC_PORT_NUM      = 1,
    parameter integer ROB_NUM                  = 512,
    parameter integer LSU_LDU_COUNT            = 3,
    parameter integer LSU_STA_COUNT            = 2,
    parameter integer LSU_AGU_COUNT            = 5,
    parameter integer LSU_SDU_COUNT            = 2,
    parameter integer LSU_LOAD_WB_WIDTH        = LSU_LDU_COUNT,
    parameter integer LSU_LDU_WIDTH            = 2,
    parameter integer W_STQ_COUNT              = 7,
    parameter integer W_LDQ_COUNT              = 7,

    // ---------------------------------------------------------------------
    // 基础边带和指令项位宽。
    // 下面的宽度按 C++ IO/types 结构体字段顺序展开，包含 TmaMeta/DebugMeta。
    // ---------------------------------------------------------------------
    parameter integer W_InstructionBufferEntry =
        1 + 32 + 32 + 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1,
    parameter integer W_InstInfo               =
        32 + (3 * AREG_IDX_WIDTH) + (4 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + 3 + 2 + 2 +
        3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH +
        ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 1 + 6 + INST_TYPE_WIDTH + W_TmaMeta + W_DebugMeta,
    parameter integer W_InstEntry              = 1 + W_InstInfo,
    // Back_out.commit_entry 保留 ffc 使用的 InstEntry 边带字段，不能再裁掉 dbg/tma。
    parameter integer W_BackCommitInfo         = W_InstInfo,
    parameter integer W_BackCommitEntry        = 1 + W_BackCommitInfo,

    // ---------------------------------------------------------------------
    // IDU、重命名、派遣和 ROB 相关包格式位宽。
    // 这些包跨越多个 BSD 边界，字段顺序必须和 ffc IO.h 中结构体声明一致。
    // ---------------------------------------------------------------------
    parameter integer W_DecRenInst             =
        32 + (3 * AREG_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + INST_TYPE_WIDTH +
        3 + 1 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) + 2 + W_TmaMeta + W_DebugMeta,
    parameter integer W_DecRenIO               = DECODE_WIDTH * (W_DecRenInst + 1),
    parameter integer W_RenDecIO               = 1,
    parameter integer W_IduConsumeIO           = DECODE_WIDTH,
    parameter integer W_PreFrontIO             = FETCH_WIDTH + 1,
    parameter integer W_DecBroadcastIO         =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_FtqPcReadReq           = 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH,
    parameter integer W_FtqPcReadResp          = 1 + 1 + 32 + 1 + 32,
    parameter integer W_FtqExuPcReqIO          = FTQ_EXU_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqExuPcRespIO         = FTQ_EXU_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_FtqRobPcReqIO          = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqRobPcRespIO         = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_PreIssueIO             = W_InstructionBufferEntry * DECODE_WIDTH,
    parameter integer W_RobCommitInst          =
        32 + AREG_IDX_WIDTH + (2 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + 1 + 7 +
        ROB_IDX_WIDTH + 1 + STQ_IDX_WIDTH + 1 + 4 +
        INST_TYPE_WIDTH + W_TmaMeta + W_DebugMeta + 1,
    parameter integer W_RobCommitIO            = COMMIT_WIDTH * (1 + W_RobCommitInst),
    parameter integer W_RobBroadcastIO         =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_RobDisIO               = W_RobDisTmaMeta + 3 + ROB_IDX_WIDTH + 1,
    parameter integer W_DisRobInst             =
        32 + (2 * AREG_IDX_WIDTH) + (2 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + INST_TYPE_WIDTH +
        1 + 1 + 3 + 7 + 32 + BR_MASK_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) +
        1 + 3 + W_TmaMeta + W_DebugMeta,
    parameter integer W_DisRobIO               = DECODE_WIDTH * (W_DisRobInst + 1 + 1),
    parameter integer W_RenDisInst             =
        32 + (3 * AREG_IDX_WIDTH) + (4 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + INST_TYPE_WIDTH +
        3 + 1 + 2 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) + 2 + W_TmaMeta + W_DebugMeta,
    parameter integer W_RenDisIO               = DECODE_WIDTH * (W_RenDisInst + 1),
    parameter integer W_DisRenIO               = 1,
    parameter integer W_WakeInfo               = 1 + PRF_IDX_WIDTH,
    parameter integer W_PrfAwakeIO             = LSU_LOAD_WB_WIDTH * W_WakeInfo,
    parameter integer W_IssAwakeIO             = MAX_WAKEUP_PORTS * W_WakeInfo,

    // ---------------------------------------------------------------------
    // 发射、物理寄存器堆和执行单元相关包格式位宽。
    // ExeIssIO 同时包含 ready 和 fu_ready_mask，和模拟器发射检查逻辑一致。
    // ---------------------------------------------------------------------
    parameter integer W_DisIssUop              =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_DisIssIO               =
        IQ_NUM * MAX_IQ_DISPATCH_WIDTH * (1 + W_DisIssUop),
    parameter integer W_IssDisIO               = IQ_NUM * IQ_READY_NUM_WIDTH,
    parameter integer W_IssPrfUop              =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_IssPrfIO               = ISSUE_WIDTH * (1 + W_IssPrfUop),
    parameter integer W_PrfExeUop              =
        (3 * PRF_IDX_WIDTH) + 64 +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 3 + 2 + 3 + 7 + 32 +
        BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_PrfExeIO               = ISSUE_WIDTH * (1 + W_PrfExeUop),
    parameter integer W_ExePrfWbUop            =
        PRF_IDX_WIDTH + 32 + BR_MASK_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExePrfEntry            = 1 + W_ExePrfWbUop,
    parameter integer W_ExePrfIO               =
        (ISSUE_WIDTH + TOTAL_FU_COUNT) * W_ExePrfEntry,
    parameter integer W_ExeIssIO               = ISSUE_WIDTH + (ISSUE_WIDTH * MAX_UOP_TYPE),
    parameter integer W_ExuIdIO                =
        1 + 32 + ROB_IDX_WIDTH + BR_TAG_WIDTH + FTQ_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_ExuRobUop              =
        32 + 32 + ROB_IDX_WIDTH + 2 + 3 + UOP_TYPE_WIDTH + 1 + W_DebugMeta,
    parameter integer W_ExuRobIO               = ISSUE_WIDTH * (1 + W_ExuRobUop),
    parameter integer W_ExeCsrIO               = 1 + 1 + 12 + 32 + 32,
    parameter integer W_CsrExeIO               = 32,
    parameter integer W_CsrRobIO               = 1,
    parameter integer W_RobCsrIO               = 2,
    parameter integer W_CsrFrontIO             = 32 + 32,
    parameter integer W_CsrStatusIO            = 32 + 32 + 32 + 2,

    // ---------------------------------------------------------------------
    // LSU、DCache 和外设接口包格式位宽。
    // peripheral/DCache 端口保留 MicroOp、StqEntry、req_id、replay 等上下文，
    // 使 LSU BSD 能按 ffc RealLsu 的后端行为建模。
    // ---------------------------------------------------------------------
    parameter integer W_DisLsuIO               =
        MAX_STQ_DISPATCH_WIDTH *
            (1 + BR_MASK_WIDTH + 3 + ROB_IDX_WIDTH + 1 + 1) +
        MAX_LDQ_DISPATCH_WIDTH *
            (1 + LDQ_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1),
    parameter integer W_LsuDisIO               =
        STQ_IDX_WIDTH + 1 + W_STQ_COUNT + W_LDQ_COUNT +
        (LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH) + MAX_LDQ_DISPATCH_WIDTH,
    parameter integer W_ExeLsuReqUop           =
        32 + PRF_IDX_WIDTH + 3 + 7 + 1 + BR_MASK_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + 1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_ExeLsuIO               =
        (LSU_AGU_COUNT + LSU_SDU_COUNT) * (1 + W_ExeLsuReqUop),
    parameter integer W_LsuExeRespUop          =
        32 + 32 + PRF_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1 +
        2 + UOP_TYPE_WIDTH + 1 + W_DebugMeta,
    parameter integer W_LsuExeIO               =
        (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT) * (1 + W_LsuExeRespUop),
    parameter integer W_LsuRobIO               = ROB_NUM + 2,
    parameter integer W_SizeT                  = 64,
    parameter integer W_MicroOp                =
        32 + (2 * AREG_IDX_WIDTH) + (3 * PRF_IDX_WIDTH) + 96 +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + 1 + 3 + 2 + 2 +
        3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH +
        ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 1 + 4 + UOP_TYPE_WIDTH +
        W_TmaMeta + W_DebugMeta + 1,
    parameter integer W_StqEntry               =
        7 + 8 + 32 + 32 + 32 + 32 + 32 + BR_MASK_WIDTH + 32 + 32,
    parameter integer W_PeripheralReqIO        = 1 + 1 + 32 + 32 + W_MicroOp,
    parameter integer W_PeripheralRespIO       = 1 + 1 + 32 + W_MicroOp,
    parameter integer W_LoadReq                = 1 + 32 + W_MicroOp + W_SizeT,
    parameter integer W_StoreReq               = 1 + 32 + 32 + 8 + W_StqEntry + W_SizeT,
    parameter integer W_LoadResp               = 1 + 32 + W_MicroOp + W_SizeT + 2,
    parameter integer W_StoreResp              = 1 + 2 + W_SizeT + 1,
    parameter integer W_ReplayResp             = 2 + W_SizeT + 8,
    parameter integer W_DCacheReqPorts         =
        (LSU_LDU_COUNT * W_LoadReq) + (LSU_STA_COUNT * W_StoreReq),
    parameter integer W_DCacheRespPorts        =
        (LSU_LDU_COUNT * W_LoadResp) + (LSU_STA_COUNT * W_StoreResp) +
        W_ReplayResp,
    parameter integer W_LsuDcacheIO            = W_DCacheReqPorts,
    parameter integer W_DcacheLsuIO            = W_DCacheRespPorts,

    // ---------------------------------------------------------------------
    // 子模块聚合接口位宽。
    // 每个 W_*In/W_*Out 都对应一个 *_bsd_top 的 pi/po 宽度。
    // ---------------------------------------------------------------------
    parameter integer W_FrontPreIO             =
        (32 * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) +
        FETCH_WIDTH +
        FETCH_WIDTH +
        FETCH_WIDTH +
        (pcpn_t_BITS * FETCH_WIDTH) +
        (pcpn_t_BITS * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) +
        (TAGE_IDX_WIDTH * FETCH_WIDTH * TN_MAX) +
        (TAGE_TAG_WIDTH * FETCH_WIDTH * TN_MAX) +
        FETCH_WIDTH +
        FETCH_WIDTH +
        (tage_scl_meta_sum_t_BITS * FETCH_WIDTH) +
        (BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS * FETCH_WIDTH) +
        FETCH_WIDTH +
        FETCH_WIDTH +
        FETCH_WIDTH +
        (BPU_LOOP_META_IDX_BITS * FETCH_WIDTH) +
        (BPU_LOOP_META_TAG_BITS * FETCH_WIDTH) +
        FETCH_WIDTH,
    parameter integer W_PreIduQueueIn          =
        W_FrontPreIO
        + W_IduConsumeIO
        + W_RobBroadcastIO
        + W_RobCommitIO
        + W_ExuIdIO
        + W_FtqExuPcReqIO
        + W_FtqRobPcReqIO,
    parameter integer W_PreIduQueueOut         =
        W_PreFrontIO
        + W_PreIssueIO
        + W_FtqExuPcRespIO
        + W_FtqRobPcRespIO,
    parameter integer W_IduIn                  =
        W_PreIssueIO
        + W_RenDecIO
        + W_RobBroadcastIO
        + W_ExuIdIO,
    // BackTop.cpp 会读取 idu->br_latch 并送回 PreIduQueue。
    // 这里把该状态打包在 IduOut 内部传递，而不是额外增加顶层端口。
    parameter integer W_IduOut                 =
        W_DecRenIO
        + W_DecBroadcastIO
        + W_IduConsumeIO
        + W_ExuIdIO,
    parameter integer W_RenIn                  =
        W_DecRenIO
        + W_DecBroadcastIO
        + W_DisRenIO
        + W_RobBroadcastIO
        + W_RobCommitIO,
    parameter integer W_RenOut                 =
        W_RenDecIO
        + W_RenDisIO,
    parameter integer W_DisIn                  =
        W_RenDisIO
        + W_RobDisIO
        + W_IssDisIO
        + W_LsuDisIO
        + W_PrfAwakeIO
        + W_IssAwakeIO
        + W_RobBroadcastIO
        + W_DecBroadcastIO,
    parameter integer W_DisOut                 =
        W_DisRenIO
        + W_DisRobIO
        + W_DisIssIO
        + W_DisLsuIO,
    parameter integer W_IsuIn                  =
        W_DisIssIO
        + W_PrfAwakeIO
        + W_ExeIssIO
        + W_RobBroadcastIO
        + W_DecBroadcastIO,
    parameter integer W_IsuOut                 =
        W_IssPrfIO
        + W_IssDisIO
        + W_IssAwakeIO,
    parameter integer W_PrfIn                  =
        W_IssPrfIO
        + W_ExePrfIO
        + W_DecBroadcastIO
        + W_RobBroadcastIO,
    parameter integer W_PrfOut                 =
        W_PrfExeIO
        + W_PrfAwakeIO,
    parameter integer W_ExuIn                  =
        W_PrfExeIO
        + W_DecBroadcastIO
        + W_RobBroadcastIO
        + W_CsrExeIO
        + W_LsuExeIO
        + W_FtqExuPcRespIO,
    parameter integer W_ExuOut                 =
        W_ExePrfIO
        + W_ExeIssIO
        + W_ExeCsrIO
        + W_ExeLsuIO
        + W_ExuIdIO
        + W_ExuRobIO
        + W_FtqExuPcReqIO,
    parameter integer W_RobIn                  =
        W_DisRobIO
        + W_CsrRobIO
        + W_LsuRobIO
        + W_DecBroadcastIO
        + W_ExuRobIO
        + W_FtqRobPcRespIO,
    parameter integer W_RobOut                 =
        W_RobDisIO
        + W_RobCsrIO
        + W_RobCommitIO
        + W_RobBroadcastIO
        + W_FtqRobPcReqIO,
    parameter integer W_CsrIn                  =
        W_ExeCsrIO
        + W_RobCsrIO
        + W_RobBroadcastIO,
    parameter integer W_CsrOut                 =
        W_CsrExeIO
        + W_CsrRobIO
        + W_CsrFrontIO
        + W_CsrStatusIO,
    parameter integer W_LsuIn                  =
        W_RobCommitIO
        + W_RobBroadcastIO
        + W_DecBroadcastIO
        + W_CsrStatusIO
        + W_DisLsuIO
        + W_ExeLsuIO
        + W_PeripheralRespIO
        + W_DcacheLsuIO,
    parameter integer W_LsuOut                 =
        W_LsuDisIO
        + W_LsuRobIO
        + W_LsuExeIO
        + W_PeripheralReqIO
        + W_LsuDcacheIO
) (
    input wire clk,
    input wire rst_n,

    // 来自前端、DCache 和外设侧的顶层输入。
    // MMU 不作为顶层外露端口，相关行为由 LSU BSD 内部实现。
    input  wire [(32 * FETCH_WIDTH)-1:0]                         front2pre_inst,
    input  wire [(32 * FETCH_WIDTH)-1:0]                         front2pre_pc,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_valid,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_predict_dir,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_alt_pred,
    input  wire [(pcpn_t_BITS * FETCH_WIDTH)-1:0]                front2pre_altpcpn,
    input  wire [(pcpn_t_BITS * FETCH_WIDTH)-1:0]                front2pre_pcpn,
    input  wire [(32 * FETCH_WIDTH)-1:0]                         front2pre_predict_next_fetch_address,
    input  wire [(TAGE_IDX_WIDTH * FETCH_WIDTH * TN_MAX)-1:0]    front2pre_tage_idx,
    input  wire [(TAGE_TAG_WIDTH * FETCH_WIDTH * TN_MAX)-1:0]    front2pre_tage_tag,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_sc_used,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_sc_pred,
    input  wire [(tage_scl_meta_sum_t_BITS * FETCH_WIDTH)-1:0]   front2pre_sc_sum,
    input  wire [(BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS *
        FETCH_WIDTH)-1:0]                                       front2pre_sc_idx,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_loop_used,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_loop_hit,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_loop_pred,
    input  wire [(BPU_LOOP_META_IDX_BITS * FETCH_WIDTH)-1:0]     front2pre_loop_idx,
    input  wire [(BPU_LOOP_META_TAG_BITS * FETCH_WIDTH)-1:0]     front2pre_loop_tag,
    input  wire [FETCH_WIDTH-1:0]                                front2pre_page_fault_inst,
    input  wire [W_PeripheralRespIO-1:0] peripheral_resp_io,
    input  wire [W_DcacheLsuIO-1:0]      dcache2lsu_io,

    // 输出给前端、CSR 观察端口、DCache 和外设侧的顶层信号。
    output wire                                          mispred,
    output wire                                          stall,
    output wire                                          flush,
    output wire                                          fence_i,
    output wire                                          itlb_flush,
    output wire [FETCH_WIDTH-1:0]                        fire,
    output wire [31:0]                                   redirect_pc,
    output wire [(W_BackCommitEntry * COMMIT_WIDTH)-1:0] commit_entry,
    output wire [31:0]                                   sstatus,
    output wire [31:0]                                   mstatus,
    output wire [31:0]                                   satp,
    output wire [1:0]                                    privilege,
    output wire [W_PeripheralReqIO-1:0]                  peripheral_req_io,
    output wire [W_LsuDcacheIO-1:0]                      lsu2dcache_io
);

    // ---------------------------------------------------------------------
    // 1. 模块间互连总线。
    // ---------------------------------------------------------------------

    // PreIduQueue、前端反馈和 IDU 取指消费路径。
    wire [W_PreFrontIO-1:0]   pre2front;
    wire [W_PreIssueIO-1:0]   pre_issue;
    wire [W_IduConsumeIO-1:0] idu_consume;
    wire [W_ExuIdIO-1:0]      idu_br_latch;

    // 译码、重命名、派遣、发射和物理寄存器堆路径。
    wire [W_DecRenIO-1:0]       dec2ren;
    wire [W_DecBroadcastIO-1:0] dec_bcast;
    wire [W_RenDecIO-1:0]       ren2dec;
    wire [W_RenDisIO-1:0]       ren2dis;
    wire [W_DisRenIO-1:0]       dis2ren;
    wire [W_DisIssIO-1:0]       dis2iss;
    wire [W_DisRobIO-1:0]       dis2rob;
    wire [W_DisLsuIO-1:0]       dis2lsu;
    wire [W_IssDisIO-1:0]       iss2dis;
    wire [W_IssPrfIO-1:0]       iss2prf;
    wire [W_IssAwakeIO-1:0]     iss_awake;
    wire [W_PrfAwakeIO-1:0]     prf_awake;

    // 执行单元和 LSU 数据路径。
    wire [W_PrfExeIO-1:0] prf2exe;
    wire [W_ExePrfIO-1:0] exe2prf;
    wire [W_ExeIssIO-1:0] exe2iss;
    wire [W_ExeLsuIO-1:0] exe2lsu;
    wire [W_ExeCsrIO-1:0] exe2csr;
    wire [W_ExuIdIO-1:0]  exu2id;
    wire [W_ExuRobIO-1:0] exu2rob;

    wire [W_LsuExeIO-1:0] lsu2exe;
    wire [W_LsuDisIO-1:0] lsu2dis;
    wire [W_LsuRobIO-1:0] lsu2rob;

    // ROB、CSR 以及提交/异常广播路径。
    wire [W_RobDisIO-1:0]       rob2dis;
    wire [W_RobCsrIO-1:0]       rob2csr;
    wire [W_RobBroadcastIO-1:0] rob_bcast;
    wire [W_RobCommitIO-1:0]    rob_commit;

    wire [W_CsrExeIO-1:0]    csr2exe;
    wire [W_CsrRobIO-1:0]    csr2rob;
    wire [W_CsrFrontIO-1:0]  csr2front;
    wire [W_CsrStatusIO-1:0] csr_status;

    // FTQ PC 读端口路径，按 ffc 分成 EXU 查询和 ROB 查询两组。
    wire [W_FtqExuPcReqIO-1:0]  ftq_exu_pc_req;
    wire [W_FtqExuPcRespIO-1:0] ftq_exu_pc_resp;
    wire [W_FtqRobPcReqIO-1:0]  ftq_rob_pc_req;
    wire [W_FtqRobPcRespIO-1:0] ftq_rob_pc_resp;

    // ---------------------------------------------------------------------
    // 2. 子模块额外展开给 back_top 使用的字段。
    // 这些字段仍然来自各模块 po，总线本身没有新增业务端口。
    // ---------------------------------------------------------------------

    // 来源模块：preiduqueue_top，用于生成前端 fire/stall 相关输出。
    wire [FETCH_WIDTH-1:0] preiduqueue_out_pre2front_fire;
    wire                   preiduqueue_out_pre2front_ready;

    // 来源模块：idu_top，用于普通分支重定向路径。
    wire        idu_out_dec_bcast_mispred;
    wire [BR_MASK_WIDTH-1:0] idu_out_dec_bcast_br_mask_unused;
    wire [BR_TAG_WIDTH-1:0]  idu_out_dec_bcast_br_id_unused;
    wire [ROB_IDX_WIDTH-1:0] idu_out_dec_bcast_redirect_rob_idx_unused;
    wire [BR_MASK_WIDTH-1:0] idu_out_dec_bcast_clear_mask_unused;
    wire        idu_out_idu_br_latch_mispred_unused;
    wire [31:0] idu_out_idu_br_latch_redirect_pc;
    wire [ROB_IDX_WIDTH-1:0] idu_out_idu_br_latch_redirect_rob_idx_unused;
    wire [BR_TAG_WIDTH-1:0]  idu_out_idu_br_latch_br_id_unused;
    wire [FTQ_IDX_WIDTH-1:0] idu_out_idu_br_latch_ftq_idx_unused;
    wire [BR_MASK_WIDTH-1:0] idu_out_idu_br_latch_clear_mask_unused;

    // 来源模块：rob_top，用于 flush、fence、异常和提交相关输出。
    wire        rob_out_rob_bcast_flush;
    wire        rob_out_rob_bcast_mret;
    wire        rob_out_rob_bcast_sret;
    wire        rob_out_rob_bcast_exception;
    wire        rob_out_rob_bcast_fence;
    wire        rob_out_rob_bcast_fence_i;
    wire        rob_out_rob_bcast_ecall_unused;
    wire        rob_out_rob_bcast_page_fault_inst_unused;
    wire        rob_out_rob_bcast_page_fault_load_unused;
    wire        rob_out_rob_bcast_page_fault_store_unused;
    wire        rob_out_rob_bcast_illegal_inst_unused;
    wire        rob_out_rob_bcast_interrupt_unused;
    wire [31:0] rob_out_rob_bcast_trap_val_unused;
    wire [31:0] rob_out_rob_bcast_pc;
    wire [ROB_IDX_WIDTH-1:0] rob_out_rob_bcast_head_rob_idx_unused;
    wire                     rob_out_rob_bcast_head_valid_unused;
    wire [ROB_IDX_WIDTH-1:0] rob_out_rob_bcast_head_incomplete_rob_idx_unused;
    wire                     rob_out_rob_bcast_head_incomplete_valid_unused;

    // 来源模块：csr_top，用于异常返回地址和 CSR 状态观察输出。
    wire [31:0] csr_out_csr2front_epc;
    wire [31:0] csr_out_csr2front_trap_pc;
    wire [31:0] csr_out_csr_status_sstatus;
    wire [31:0] csr_out_csr_status_mstatus;
    wire [31:0] csr_out_csr_status_satp;
    wire [1:0]  csr_out_csr_status_privilege;

    // 顶层本地胶水信号，只在 back_top 内部组合使用。
    wire [W_FrontPreIO-1:0] front2pre;
    wire [31:0] redirect_pc_from_flush;

    // ---------------------------------------------------------------------
    // 3. Back_out.commit_entry 拼接逻辑。
    //
    // rob_top 输出保持 RobCommitIO 原始布局；back_top 在这里把它转换成
    // Back_out.commit_entry 所需的 InstEntry 布局，并保留 tma/dbg 边带。
    // ---------------------------------------------------------------------

    wire [COMMIT_WIDTH-1:0]                     backout_rob_commit_entry_valid;
    wire [(W_RobCommitInst * COMMIT_WIDTH)-1:0] backout_rob_commit_entry_uop;

    wire [(32 * COMMIT_WIDTH)-1:0]               backout_rob_commit_entry_uop_diag_val;
    wire [(AREG_IDX_WIDTH * COMMIT_WIDTH)-1:0]   backout_rob_commit_entry_uop_dest_areg;
    wire [(PRF_IDX_WIDTH * COMMIT_WIDTH)-1:0]    backout_rob_commit_entry_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * COMMIT_WIDTH)-1:0]    backout_rob_commit_entry_uop_old_dest_preg;
    wire [(FTQ_IDX_WIDTH * COMMIT_WIDTH)-1:0]    backout_rob_commit_entry_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * COMMIT_WIDTH)-1:0] backout_rob_commit_entry_uop_ftq_offset;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_ftq_is_last;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_mispred;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_br_taken;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_dest_en;
    wire [(7 * COMMIT_WIDTH)-1:0]                backout_rob_commit_entry_uop_func7;
    wire [(ROB_IDX_WIDTH * COMMIT_WIDTH)-1:0]    backout_rob_commit_entry_uop_rob_idx;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_rob_flag;
    wire [(STQ_IDX_WIDTH * COMMIT_WIDTH)-1:0]    backout_rob_commit_entry_uop_stq_idx;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_stq_flag;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_page_fault_inst;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_page_fault_load;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_page_fault_store;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_illegal_inst;
    wire [(INST_TYPE_WIDTH * COMMIT_WIDTH)-1:0]  backout_rob_commit_entry_uop_type;
    wire [(W_TmaMeta * COMMIT_WIDTH)-1:0]         backout_rob_commit_entry_uop_tma;
    wire [(W_DebugMeta * COMMIT_WIDTH)-1:0]       backout_rob_commit_entry_uop_dbg;
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_flush_pipe;
    wire [(32 * COMMIT_WIDTH)-1:0]               backout_commit_entry_uop_diag_val;

    // RobCommitInst 本身不提供的 InstInfo 字段保持为零，
    // 与 C++ to_inst_entry() 中默认构造后未赋值字段的行为一致。
    wire [(2 * AREG_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        commit_entry_zero_src_areg;
    wire [(2 * PRF_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        commit_entry_zero_src_preg;
    wire [COMMIT_WIDTH-1:0] commit_entry_zero_src1_en;
    wire [COMMIT_WIDTH-1:0] commit_entry_zero_src2_en;
    wire [COMMIT_WIDTH-1:0] commit_entry_zero_src1_busy;
    wire [COMMIT_WIDTH-1:0] commit_entry_zero_src2_busy;
    wire [COMMIT_WIDTH-1:0] commit_entry_zero_src1_is_pc;
    wire [COMMIT_WIDTH-1:0] commit_entry_zero_src2_is_imm;
    wire [(3 * COMMIT_WIDTH)-1:0] commit_entry_zero_func3;
    wire [(32 * COMMIT_WIDTH)-1:0] commit_entry_zero_imm;
    wire [(BR_TAG_WIDTH * COMMIT_WIDTH)-1:0] commit_entry_zero_br_id;
    wire [(BR_MASK_WIDTH * COMMIT_WIDTH)-1:0] commit_entry_zero_br_mask;
    wire [(CSR_IDX_WIDTH * COMMIT_WIDTH)-1:0] commit_entry_zero_csr_idx;
    wire [(LDQ_IDX_WIDTH * COMMIT_WIDTH)-1:0] commit_entry_zero_ldq_idx;
    wire [(ROB_CPLT_MASK_WIDTH * COMMIT_WIDTH)-1:0]
        commit_entry_zero_expect_mask;
    wire [(ROB_CPLT_MASK_WIDTH * COMMIT_WIDTH)-1:0]
        commit_entry_zero_cplt_mask;
    wire [COMMIT_WIDTH-1:0] commit_entry_zero_is_atomic;

    genvar commit_idx;

    // ---------------------------------------------------------------------
    // 4. 对齐 BackTop.cpp 的顶层组合胶水。
    // ---------------------------------------------------------------------

    assign front2pre = {
        front2pre_inst,
        front2pre_pc,
        front2pre_valid,
        front2pre_predict_dir,
        front2pre_alt_pred,
        front2pre_altpcpn,
        front2pre_pcpn,
        front2pre_predict_next_fetch_address,
        front2pre_tage_idx,
        front2pre_tage_tag,
        front2pre_sc_used,
        front2pre_sc_pred,
        front2pre_sc_sum,
        front2pre_sc_idx,
        front2pre_loop_used,
        front2pre_loop_hit,
        front2pre_loop_pred,
        front2pre_loop_idx,
        front2pre_loop_tag,
        front2pre_page_fault_inst
    };

    assign {
        backout_rob_commit_entry_valid,
        backout_rob_commit_entry_uop
    } = rob_commit;

    assign {
        backout_rob_commit_entry_uop_diag_val,
        backout_rob_commit_entry_uop_dest_areg,
        backout_rob_commit_entry_uop_dest_preg,
        backout_rob_commit_entry_uop_old_dest_preg,
        backout_rob_commit_entry_uop_ftq_idx,
        backout_rob_commit_entry_uop_ftq_offset,
        backout_rob_commit_entry_uop_ftq_is_last,
        backout_rob_commit_entry_uop_mispred,
        backout_rob_commit_entry_uop_br_taken,
        backout_rob_commit_entry_uop_dest_en,
        backout_rob_commit_entry_uop_func7,
        backout_rob_commit_entry_uop_rob_idx,
        backout_rob_commit_entry_uop_rob_flag,
        backout_rob_commit_entry_uop_stq_idx,
        backout_rob_commit_entry_uop_stq_flag,
        backout_rob_commit_entry_uop_page_fault_inst,
        backout_rob_commit_entry_uop_page_fault_load,
        backout_rob_commit_entry_uop_page_fault_store,
        backout_rob_commit_entry_uop_illegal_inst,
        backout_rob_commit_entry_uop_type,
        backout_rob_commit_entry_uop_tma,
        backout_rob_commit_entry_uop_dbg,
        backout_rob_commit_entry_uop_flush_pipe
    } = backout_rob_commit_entry_uop;

    generate
        for (commit_idx = 0; commit_idx < COMMIT_WIDTH;
             commit_idx = commit_idx + 1) begin : gen_commit_entry_diag_val
            assign backout_commit_entry_uop_diag_val
                [(32 * (commit_idx + 1))-1:(32 * commit_idx)] =
                    (flush && backout_rob_commit_entry_valid[commit_idx]) ?
                    redirect_pc :
                    backout_rob_commit_entry_uop_diag_val
                        [(32 * (commit_idx + 1))-1:(32 * commit_idx)];
        end
    endgenerate

    assign commit_entry_zero_src_areg    =
        {(2 * AREG_IDX_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_src_preg    =
        {(2 * PRF_IDX_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_src1_en     = {COMMIT_WIDTH{1'b0}};
    assign commit_entry_zero_src2_en     = {COMMIT_WIDTH{1'b0}};
    assign commit_entry_zero_src1_busy   = {COMMIT_WIDTH{1'b0}};
    assign commit_entry_zero_src2_busy   = {COMMIT_WIDTH{1'b0}};
    assign commit_entry_zero_src1_is_pc  = {COMMIT_WIDTH{1'b0}};
    assign commit_entry_zero_src2_is_imm = {COMMIT_WIDTH{1'b0}};
    assign commit_entry_zero_func3       = {(3 * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_imm         = {(32 * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_br_id       =
        {(BR_TAG_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_br_mask     =
        {(BR_MASK_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_csr_idx     =
        {(CSR_IDX_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_ldq_idx     =
        {(LDQ_IDX_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_expect_mask =
        {(ROB_CPLT_MASK_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_cplt_mask   =
        {(ROB_CPLT_MASK_WIDTH * COMMIT_WIDTH){1'b0}};
    assign commit_entry_zero_is_atomic   = {COMMIT_WIDTH{1'b0}};

    // ---------------------------------------------------------------------
    // 5. 按后端数据流顺序例化各模块。
    // ---------------------------------------------------------------------

    // 前端输入队列和 FTQ PC 查询服务。
    preiduqueue_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .W_PreIduQueueIn(W_PreIduQueueIn),
        .W_PreIduQueueOut(W_PreIduQueueOut)
    ) pre (
        .clk(clk),
        .rst_n(rst_n),
        .front2pre(front2pre),
        .idu_consume(idu_consume),
        .rob_bcast(rob_bcast),
        .rob_commit(rob_commit),
        .idu_br_latch(idu_br_latch),
        .ftq_exu_pc_req(ftq_exu_pc_req),
        .ftq_rob_pc_req(ftq_rob_pc_req),
        .pre2front(pre2front),
        .pre_issue(pre_issue),
        .ftq_exu_pc_resp(ftq_exu_pc_resp),
        .ftq_rob_pc_resp(ftq_rob_pc_resp),
        .pre2front_fire(preiduqueue_out_pre2front_fire),
        .pre2front_ready(preiduqueue_out_pre2front_ready)
    );

    // 译码模块。
    idu_top #(
        .W_IduIn(W_IduIn),
        .W_IduOut(W_IduOut)
    ) idu (
        .clk(clk),
        .rst_n(rst_n),
        .pre_issue(pre_issue),
        .ren2dec(ren2dec),
        .rob_bcast(rob_bcast),
        .exu2id(exu2id),
        .dec2ren(dec2ren),
        .dec_bcast(dec_bcast),
        .idu_consume(idu_consume),
        .idu_br_latch(idu_br_latch),
        .dec_bcast_mispred(idu_out_dec_bcast_mispred),
        .dec_bcast_br_mask(idu_out_dec_bcast_br_mask_unused),
        .dec_bcast_br_id(idu_out_dec_bcast_br_id_unused),
        .dec_bcast_redirect_rob_idx(
            idu_out_dec_bcast_redirect_rob_idx_unused),
        .dec_bcast_clear_mask(idu_out_dec_bcast_clear_mask_unused),
        .idu_br_latch_mispred(idu_out_idu_br_latch_mispred_unused),
        .idu_br_latch_redirect_pc(idu_out_idu_br_latch_redirect_pc),
        .idu_br_latch_redirect_rob_idx(
            idu_out_idu_br_latch_redirect_rob_idx_unused),
        .idu_br_latch_br_id(idu_out_idu_br_latch_br_id_unused),
        .idu_br_latch_ftq_idx(idu_out_idu_br_latch_ftq_idx_unused),
        .idu_br_latch_clear_mask(idu_out_idu_br_latch_clear_mask_unused)
    );

    // 重命名模块。
    ren_top #(
        .W_RenIn(W_RenIn),
        .W_RenOut(W_RenOut)
    ) rename (
        .clk(clk),
        .rst_n(rst_n),
        .dec2ren(dec2ren),
        .dec_bcast(dec_bcast),
        .dis2ren(dis2ren),
        .rob_bcast(rob_bcast),
        .rob_commit(rob_commit),
        .ren2dec(ren2dec),
        .ren2dis(ren2dis)
    );

    // 派遣模块。
    dispatch_top #(
        .W_DisIn(W_DisIn),
        .W_DisOut(W_DisOut)
    ) dispatch (
        .clk(clk),
        .rst_n(rst_n),
        .ren2dis(ren2dis),
        .rob2dis(rob2dis),
        .iss2dis(iss2dis),
        .lsu2dis(lsu2dis),
        .prf_awake(prf_awake),
        .iss_awake(iss_awake),
        .rob_bcast(rob_bcast),
        .dec_bcast(dec_bcast),
        .dis2ren(dis2ren),
        .dis2rob(dis2rob),
        .dis2iss(dis2iss),
        .dis2lsu(dis2lsu)
    );

    // 发射模块。
    isu_top #(
        .W_IsuIn(W_IsuIn),
        .W_IsuOut(W_IsuOut)
    ) isu (
        .clk(clk),
        .rst_n(rst_n),
        .dis2iss(dis2iss),
        .prf_awake(prf_awake),
        .exe2iss(exe2iss),
        .rob_bcast(rob_bcast),
        .dec_bcast(dec_bcast),
        .iss2prf(iss2prf),
        .iss2dis(iss2dis),
        .iss_awake(iss_awake)
    );

    // 物理寄存器堆模块。
    prf_top #(
        .W_PrfIn(W_PrfIn),
        .W_PrfOut(W_PrfOut)
    ) prf (
        .clk(clk),
        .rst_n(rst_n),
        .iss2prf(iss2prf),
        .exe2prf(exe2prf),
        .dec_bcast(dec_bcast),
        .rob_bcast(rob_bcast),
        .prf2exe(prf2exe),
        .prf_awake(prf_awake)
    );

    // 执行模块。
    exu_top #(
        .W_ExuIn(W_ExuIn),
        .W_ExuOut(W_ExuOut)
    ) exu (
        .clk(clk),
        .rst_n(rst_n),
        .prf2exe(prf2exe),
        .dec_bcast(dec_bcast),
        .rob_bcast(rob_bcast),
        .csr2exe(csr2exe),
        .lsu2exe(lsu2exe),
        .ftq_exu_pc_resp(ftq_exu_pc_resp),
        .exe2prf(exe2prf),
        .exe2iss(exe2iss),
        .exe2csr(exe2csr),
        .exe2lsu(exe2lsu),
        .exu2id(exu2id),
        .exu2rob(exu2rob),
        .ftq_exu_pc_req(ftq_exu_pc_req)
    );

    // 重排序缓冲模块。
    rob_top #(
        .COMMIT_WIDTH(COMMIT_WIDTH),
        .W_InstEntry(W_InstEntry),
        .W_RobIn(W_RobIn),
        .W_RobOut(W_RobOut)
    ) rob (
        .clk(clk),
        .rst_n(rst_n),
        .dis2rob(dis2rob),
        .csr2rob(csr2rob),
        .lsu2rob(lsu2rob),
        .dec_bcast(dec_bcast),
        .exu2rob(exu2rob),
        .ftq_rob_pc_resp(ftq_rob_pc_resp),
        .rob2dis(rob2dis),
        .rob2csr(rob2csr),
        .rob_commit(rob_commit),
        .rob_bcast(rob_bcast),
        .ftq_rob_pc_req(ftq_rob_pc_req),
        .rob_bcast_flush(rob_out_rob_bcast_flush),
        .rob_bcast_mret(rob_out_rob_bcast_mret),
        .rob_bcast_sret(rob_out_rob_bcast_sret),
        .rob_bcast_ecall(rob_out_rob_bcast_ecall_unused),
        .rob_bcast_exception(rob_out_rob_bcast_exception),
        .rob_bcast_fence(rob_out_rob_bcast_fence),
        .rob_bcast_fence_i(rob_out_rob_bcast_fence_i),
        .rob_bcast_page_fault_inst(rob_out_rob_bcast_page_fault_inst_unused),
        .rob_bcast_page_fault_load(rob_out_rob_bcast_page_fault_load_unused),
        .rob_bcast_page_fault_store(rob_out_rob_bcast_page_fault_store_unused),
        .rob_bcast_illegal_inst(rob_out_rob_bcast_illegal_inst_unused),
        .rob_bcast_interrupt(rob_out_rob_bcast_interrupt_unused),
        .rob_bcast_trap_val(rob_out_rob_bcast_trap_val_unused),
        .rob_bcast_pc(rob_out_rob_bcast_pc),
        .rob_bcast_head_rob_idx(rob_out_rob_bcast_head_rob_idx_unused),
        .rob_bcast_head_valid(rob_out_rob_bcast_head_valid_unused),
        .rob_bcast_head_incomplete_rob_idx(
            rob_out_rob_bcast_head_incomplete_rob_idx_unused),
        .rob_bcast_head_incomplete_valid(
            rob_out_rob_bcast_head_incomplete_valid_unused)
    );

    // CSR 模块。
    csr_top #(
        .W_CsrIn(W_CsrIn),
        .W_CsrOut(W_CsrOut)
    ) csr (
        .clk(clk),
        .rst_n(rst_n),
        .exe2csr(exe2csr),
        .rob2csr(rob2csr),
        .rob_bcast(rob_bcast),
        .csr2exe(csr2exe),
        .csr2rob(csr2rob),
        .csr2front(csr2front),
        .csr_status(csr_status),
        .csr2front_epc(csr_out_csr2front_epc),
        .csr2front_trap_pc(csr_out_csr2front_trap_pc),
        .csr_status_sstatus(csr_out_csr_status_sstatus),
        .csr_status_mstatus(csr_out_csr_status_mstatus),
        .csr_status_satp(csr_out_csr_status_satp),
        .csr_status_privilege(csr_out_csr_status_privilege)
    );

    // 访存模块，包含对外 DCache 和外设总线；MMU 行为在 LSU BSD 内部实现。
    lsu_top #(
        .W_LsuIn(W_LsuIn),
        .W_LsuOut(W_LsuOut)
    ) lsu (
        .clk(clk),
        .rst_n(rst_n),
        .rob_commit(rob_commit),
        .rob_bcast(rob_bcast),
        .dec_bcast(dec_bcast),
        .csr_status(csr_status),
        .dis2lsu(dis2lsu),
        .exe2lsu(exe2lsu),
        .peripheral_resp(peripheral_resp_io),
        .dcache2lsu(dcache2lsu_io),
        .lsu2dis(lsu2dis),
        .lsu2rob(lsu2rob),
        .lsu2exe(lsu2exe),
        .peripheral_req(peripheral_req_io),
        .lsu2dcache(lsu2dcache_io)
    );

    // ---------------------------------------------------------------------
    // 6. 顶层输出组装。
    // ---------------------------------------------------------------------

    // 前端可见的控制输出。
    assign fire       = preiduqueue_out_pre2front_fire;
    assign flush      = rob_out_rob_bcast_flush;
    assign fence_i    = rob_out_rob_bcast_fence_i;
    assign itlb_flush = rob_out_rob_bcast_fence;

    assign mispred = rob_out_rob_bcast_flush ? 1'b1 : idu_out_dec_bcast_mispred;
    assign stall   = ~preiduqueue_out_pre2front_ready;

    // 重定向 PC 选择规则对齐 BackTop.cpp：
    //   普通分支路径来自 IDU 的分支锁存信息；
    //   flush 路径来自 CSR epc/trap_pc 或 ROB 提供的 pc + 4。
    assign redirect_pc_from_flush =
        (rob_out_rob_bcast_mret || rob_out_rob_bcast_sret) ?
            csr_out_csr2front_epc :
        (rob_out_rob_bcast_exception ?
            csr_out_csr2front_trap_pc :
            (rob_out_rob_bcast_pc + 32'd4));

    assign redirect_pc =
        rob_out_rob_bcast_flush ?
            redirect_pc_from_flush :
            idu_out_idu_br_latch_redirect_pc;

    // CSR 状态观察输出。
    assign sstatus   = csr_out_csr_status_sstatus;
    assign mstatus   = csr_out_csr_status_mstatus;
    assign satp      = csr_out_csr_status_satp;
    assign privilege = csr_out_csr_status_privilege;

    // Back_out.commit_entry 按 InstEntry 字段顺序拼接。
    // 字段来源规则：
    //   1. RobCommitInst 已提供的字段使用 backout_rob_commit_entry_uop_*；
    //   2. RobCommitInst 未提供的字段使用 commit_entry_zero_* 补零。
    assign commit_entry = {
        // InstEntry.valid 字段。
        backout_rob_commit_entry_valid,

        // InstInfo 中的架构寄存器和物理寄存器字段。
        backout_commit_entry_uop_diag_val,
        backout_rob_commit_entry_uop_dest_areg,
        commit_entry_zero_src_areg,
        backout_rob_commit_entry_uop_dest_preg,
        commit_entry_zero_src_preg,
        backout_rob_commit_entry_uop_old_dest_preg,

        // FTQ 索引和分支预测相关字段。
        backout_rob_commit_entry_uop_ftq_idx,
        backout_rob_commit_entry_uop_ftq_offset,
        backout_rob_commit_entry_uop_ftq_is_last,
        backout_rob_commit_entry_uop_mispred,
        backout_rob_commit_entry_uop_br_taken,

        // 操作数控制、功能码和立即数字段。
        backout_rob_commit_entry_uop_dest_en,
        commit_entry_zero_src1_en,
        commit_entry_zero_src2_en,
        commit_entry_zero_src1_busy,
        commit_entry_zero_src2_busy,
        commit_entry_zero_src1_is_pc,
        commit_entry_zero_src2_is_imm,
        commit_entry_zero_func3,
        backout_rob_commit_entry_uop_func7,
        commit_entry_zero_imm,
        commit_entry_zero_br_id,
        commit_entry_zero_br_mask,
        commit_entry_zero_csr_idx,

        // ROB/LSU 记账字段。
        backout_rob_commit_entry_uop_rob_idx,
        backout_rob_commit_entry_uop_stq_idx,
        backout_rob_commit_entry_uop_stq_flag,
        commit_entry_zero_ldq_idx,
        commit_entry_zero_expect_mask,
        commit_entry_zero_cplt_mask,
        backout_rob_commit_entry_uop_rob_flag,

        // 异常、指令类型以及 tma/dbg 边带字段。
        backout_rob_commit_entry_uop_page_fault_inst,
        backout_rob_commit_entry_uop_page_fault_load,
        backout_rob_commit_entry_uop_page_fault_store,
        backout_rob_commit_entry_uop_illegal_inst,
        commit_entry_zero_is_atomic,
        backout_rob_commit_entry_uop_flush_pipe,
        backout_rob_commit_entry_uop_type,
        backout_rob_commit_entry_uop_tma,
        backout_rob_commit_entry_uop_dbg
    };

endmodule
