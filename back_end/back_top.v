// Backend top connectivity view.
// Canonical source: maintain this file under back_end/.
//
// Source reference:
//   simulator-new-lsu-tmp/back-end/include/BackTop.h
//   simulator-new-lsu-tmp/back-end/BackTop.cpp
//
// This file is a top-down connection skeleton, not the final RTL
// implementation.  The top level shows module-to-module wiring; each module
// top further splits its local input/output buses before calling bsd_top.

module back_top #(
    // ---------------------------------------------------------------------
    // Core/backend shape constants.
    // Keep simulator constant names when a width is derived from config.h.
    // ---------------------------------------------------------------------
    parameter integer FETCH_WIDTH  = 16,
    parameter integer DECODE_WIDTH = 8,
    parameter integer COMMIT_WIDTH = DECODE_WIDTH,

    parameter integer AREG_IDX_WIDTH = 6,
    parameter integer PRF_IDX_WIDTH  = 11,
    parameter integer ROB_IDX_WIDTH  = 11,
    parameter integer STQ_IDX_WIDTH  = 9,
    parameter integer LDQ_IDX_WIDTH  = 9,

    parameter integer BR_TAG_WIDTH        = 6,
    parameter integer BR_MASK_WIDTH       = 64,
    parameter integer CSR_IDX_WIDTH       = 12,
    parameter integer FTQ_IDX_WIDTH       = 8,
    parameter integer FTQ_OFFSET_WIDTH    = 4,
    parameter integer INST_TYPE_WIDTH     = 5,
    parameter integer UOP_TYPE_WIDTH      = 5,
    parameter integer ROB_CPLT_MASK_WIDTH = 3,

    // ---------------------------------------------------------------------
    // Frontend/BPU metadata constants carried through backend packets.
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
    // Issue, execution and LSU structure constants.
    // ---------------------------------------------------------------------
    parameter integer IQ_READY_NUM_WIDTH     = 11,
    parameter integer MAX_IQ_DISPATCH_WIDTH  = DECODE_WIDTH,
    parameter integer MAX_STQ_DISPATCH_WIDTH = DECODE_WIDTH,
    parameter integer MAX_LDQ_DISPATCH_WIDTH = DECODE_WIDTH,
    parameter integer MAX_WAKEUP_PORTS       = 16,
    parameter integer ISSUE_WIDTH            = 24,
    parameter integer TOTAL_FU_COUNT         = 30,
    parameter integer FTQ_PRF_PC_PORT_NUM    = 12,
    parameter integer FTQ_ROB_PC_PORT_NUM    = 1,
    parameter integer ROB_NUM                = 2048,
    parameter integer LSU_LDU_COUNT          = 4,
    parameter integer LSU_STA_COUNT          = 4,
    parameter integer LSU_AGU_COUNT          = 8,
    parameter integer LSU_SDU_COUNT          = 4,
    parameter integer LSU_LOAD_WB_WIDTH      = LSU_LDU_COUNT,
    parameter integer LSU_LDU_WIDTH          = 2,
    parameter integer W_STQ_COUNT            = 10,
    parameter integer W_LDQ_COUNT            = 10,

    // ---------------------------------------------------------------------
    // Basic sideband and instruction-entry widths.
    // Widths below are derived from the C++ IO structs.
    // ---------------------------------------------------------------------
    parameter integer W_InstructionBufferEntry =
        1 + 32 + 32 + 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1,
    parameter integer W_InstInfo =
        32 + (3 * AREG_IDX_WIDTH) + (4 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + 3 + 2 + 2 +
        3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH +
        ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 1 + 6 + INST_TYPE_WIDTH,
    parameter integer W_InstEntry = 1 + W_InstInfo,
    // Back_out.commit_entry intentionally drops extra sideband fields.
    parameter integer W_BackCommitInfo  = W_InstInfo,
    parameter integer W_BackCommitEntry = 1 + W_BackCommitInfo,

    // ---------------------------------------------------------------------
    // IDU, rename, dispatch and ROB packet widths.
    // ---------------------------------------------------------------------
    parameter integer W_DecRenInst =
        32 + (3 * AREG_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + INST_TYPE_WIDTH +
        3 + 1 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) + 2,
    parameter integer W_DecRenIO       = DECODE_WIDTH * (W_DecRenInst + 1),
    parameter integer W_RenDecIO       = 1,
    parameter integer W_IduConsumeIO   = DECODE_WIDTH,
    parameter integer W_PreFrontIO     = FETCH_WIDTH + 1,
    parameter integer W_DecBroadcastIO =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_FtqPcReadReq   = 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH,
    parameter integer W_FtqPcReadResp  = 1 + 1 + 32 + 1 + 32,
    parameter integer W_FtqPrfPcReqIO  = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqPrfPcRespIO = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_FtqRobPcReqIO  = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqRobPcRespIO = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_PreIssueIO     = W_InstructionBufferEntry * DECODE_WIDTH,
    parameter integer W_RobCommitInst  =
        32 + AREG_IDX_WIDTH + (2 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + 1 + 7 +
        ROB_IDX_WIDTH + 1 + STQ_IDX_WIDTH + 1 + 4 + INST_TYPE_WIDTH + 1,
    parameter integer W_RobCommitIO    = COMMIT_WIDTH * (1 + W_RobCommitInst),
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_RobDisIO   = 3 + ROB_IDX_WIDTH + 1,
    parameter integer W_DisRobInst =
        32 + (2 * AREG_IDX_WIDTH) + (2 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + INST_TYPE_WIDTH +
        1 + 1 + 3 + 7 + 32 + BR_MASK_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) +
        1 + 3,
    parameter integer W_DisRobIO   = DECODE_WIDTH * (W_DisRobInst + 1 + 1),
    parameter integer W_RenDisInst =
        32 + (3 * AREG_IDX_WIDTH) + (4 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + INST_TYPE_WIDTH +
        3 + 1 + 2 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) + 2,
    parameter integer W_RenDisIO   = DECODE_WIDTH * (W_RenDisInst + 1),
    parameter integer W_DisRenIO   = 1,
    parameter integer W_WakeInfo   = 1 + PRF_IDX_WIDTH,
    parameter integer W_PrfAwakeIO = LSU_LOAD_WB_WIDTH * W_WakeInfo,
    parameter integer W_IssAwakeIO = MAX_WAKEUP_PORTS * W_WakeInfo,

    // ---------------------------------------------------------------------
    // Issue, PRF and EXU packet widths.
    // ---------------------------------------------------------------------
    parameter integer W_DisIssUop =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH,
    parameter integer W_DisIssIO =
        IQ_NUM * MAX_IQ_DISPATCH_WIDTH * (1 + W_DisIssUop),
    parameter integer W_IssDisIO  = IQ_NUM * IQ_READY_NUM_WIDTH,
    parameter integer W_IssPrfUop =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH,
    parameter integer W_IssPrfIO  = ISSUE_WIDTH * (1 + W_IssPrfUop),
    parameter integer W_PrfExeUop =
        32 + 1 + 1 + 32 + (3 * PRF_IDX_WIDTH) + 64 +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 3 + 2 + 3 + 7 + 32 +
        BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_PrfExeIO    = ISSUE_WIDTH * (1 + W_PrfExeUop),
    parameter integer W_ExePrfWbUop =
        PRF_IDX_WIDTH + 32 + BR_MASK_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExePrfEntry = 1 + W_ExePrfWbUop,
    parameter integer W_ExePrfIO    =
        (ISSUE_WIDTH + TOTAL_FU_COUNT) * W_ExePrfEntry,
    parameter integer W_ExeIssIO = ISSUE_WIDTH * MAX_UOP_TYPE,
    parameter integer W_ExuIdIO  =
        1 + 32 + ROB_IDX_WIDTH + BR_TAG_WIDTH + FTQ_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_ExuRobUop =
        32 + 32 + ROB_IDX_WIDTH + 2 + 3 + UOP_TYPE_WIDTH + 1,
    parameter integer W_ExuRobIO    = ISSUE_WIDTH * (1 + W_ExuRobUop),
    parameter integer W_ExeCsrIO    = 1 + 1 + 12 + 32 + 32,
    parameter integer W_CsrExeIO    = 32,
    parameter integer W_CsrRobIO    = 1,
    parameter integer W_RobCsrIO    = 2,
    parameter integer W_CsrFrontIO  = 32 + 32,
    parameter integer W_CsrStatusIO = 32 + 32 + 32 + 2,

    // ---------------------------------------------------------------------
    // LSU, DCache, peripheral and MMU packet widths.
    // ---------------------------------------------------------------------
    parameter integer W_DisLsuIO =
        MAX_STQ_DISPATCH_WIDTH *
            (1 + BR_MASK_WIDTH + 3 + ROB_IDX_WIDTH + 1 + 1) +
        MAX_LDQ_DISPATCH_WIDTH *
            (1 + LDQ_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1),
    parameter integer W_LsuDisIO =
        STQ_IDX_WIDTH + 1 + W_STQ_COUNT + W_LDQ_COUNT +
        (LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH) + MAX_LDQ_DISPATCH_WIDTH,
    parameter integer W_ExeLsuReqUop =
        32 + PRF_IDX_WIDTH + 3 + 7 + 1 + BR_MASK_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExeLsuIO =
        (LSU_AGU_COUNT + LSU_SDU_COUNT) * (1 + W_ExeLsuReqUop),
    parameter integer W_LsuExeRespUop =
        32 + 32 + PRF_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1 +
        2 + UOP_TYPE_WIDTH + 1,
    parameter integer W_LsuExeIO =
        (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT) * (1 + W_LsuExeRespUop),
    parameter integer W_LsuRobIO         = 1,
    parameter integer W_PeripheralReqIO  = 1 + 1 + 32 + 32 + 3,
    parameter integer W_PeripheralRespIO = 1 + 1 + 32,
    parameter integer W_LoadReq          = 1 + 32 + 32 + 1,
    parameter integer W_StoreReq         = 1 + 32 + 32 + 8 + 32 + 1,
    parameter integer W_LoadResp         = 1 + 32 + 32 + 2,
    parameter integer W_StoreResp        = 1 + 2 + 32,
    parameter integer W_DCacheReqPorts   =
        (LSU_LDU_COUNT * W_LoadReq) + (LSU_STA_COUNT * W_StoreReq),
    parameter integer W_DCacheRespPorts =
        (LSU_LDU_COUNT * W_LoadResp) + (LSU_STA_COUNT * W_StoreResp),
    parameter integer W_LsuDcacheIO = W_DCacheReqPorts + LSU_LDU_WIDTH + 1,
    parameter integer W_DcacheLsuIO = W_DCacheRespPorts + 1,
    parameter integer W_MMUReq      = 1 + 32,
    parameter integer W_MMUResp     = 1 + 32 + 2,
    parameter integer W_LsuMMUIO    =
        (W_MMUReq * LSU_LDU_COUNT) + (W_MMUReq * LSU_STA_COUNT) + W_CsrStatusIO,
    parameter integer W_MMULsuIO =
        (W_MMUResp * LSU_LDU_COUNT) + (W_MMUResp * LSU_STA_COUNT),

    // ---------------------------------------------------------------------
    // Aggregate module interface widths.
    // ---------------------------------------------------------------------
    parameter integer W_FrontPreIO =
        (32 * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) +
        FETCH_WIDTH +
        1 +
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
    parameter integer W_FrontPreIO_AFTER_FRONT_STALL =
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
    parameter integer W_PreIduQueueIn =
        W_FrontPreIO
        + W_IduConsumeIO
        + W_RobBroadcastIO
        + W_RobCommitIO
        + W_ExuIdIO
        + W_FtqPrfPcReqIO
        + W_FtqRobPcReqIO,
    parameter integer W_PreIduQueueOut =
        W_PreFrontIO
        + W_PreIssueIO
        + W_FtqPrfPcRespIO
        + W_FtqRobPcRespIO,
    parameter integer W_IduIn =
        W_PreIssueIO
        + W_RenDecIO
        + W_RobBroadcastIO
        + W_ExuIdIO,
    // BackTop.cpp also reads idu->br_latch and feeds it to PreIduQueue.
    // Keep that boundary inside the aggregate IduOut bus instead of adding a
    // separate top-level port.
    parameter integer W_IduOut =
        W_DecRenIO
        + W_DecBroadcastIO
        + W_IduConsumeIO
        + W_ExuIdIO,
    parameter integer W_RenIn =
        W_DecRenIO
        + W_DecBroadcastIO
        + W_DisRenIO
        + W_RobBroadcastIO
        + W_RobCommitIO,
    parameter integer W_RenOut =
        W_RenDecIO
        + W_RenDisIO,
    parameter integer W_DisIn  =
        W_RenDisIO
        + W_RobDisIO
        + W_IssDisIO
        + W_LsuDisIO
        + W_PrfAwakeIO
        + W_IssAwakeIO
        + W_RobBroadcastIO
        + W_DecBroadcastIO,
    parameter integer W_DisOut =
        W_DisRenIO
        + W_DisRobIO
        + W_DisIssIO
        + W_DisLsuIO,
    parameter integer W_IsuIn =
        W_DisIssIO
        + W_PrfAwakeIO
        + W_ExeIssIO
        + W_RobBroadcastIO
        + W_DecBroadcastIO,
    parameter integer W_IsuOut =
        W_IssPrfIO
        + W_IssDisIO
        + W_IssAwakeIO,
    parameter integer W_PrfIn  =
        W_IssPrfIO
        + W_ExePrfIO
        + W_DecBroadcastIO
        + W_RobBroadcastIO
        + W_FtqPrfPcRespIO,
    parameter integer W_PrfOut =
        W_PrfExeIO
        + W_PrfAwakeIO
        + W_FtqPrfPcReqIO,
    parameter integer W_ExuIn =
        W_PrfExeIO
        + W_DecBroadcastIO
        + W_RobBroadcastIO
        + W_CsrExeIO
        + W_LsuExeIO
        + W_CsrStatusIO,
    parameter integer W_ExuOut =
        W_ExePrfIO
        + W_ExeIssIO
        + W_ExeCsrIO
        + W_ExeLsuIO
        + W_ExuIdIO
        + W_ExuRobIO,
    parameter integer W_RobIn =
        W_DisRobIO
        + W_CsrRobIO
        + W_LsuRobIO
        + W_DecBroadcastIO
        + W_ExuRobIO
        + W_FtqRobPcRespIO
        + 1,
    parameter integer W_RobOut =
        W_RobDisIO
        + W_RobCsrIO
        + W_RobCommitIO
        + W_RobBroadcastIO
        + W_FtqRobPcReqIO,
    parameter integer W_CsrIn  =
        W_ExeCsrIO
        + W_RobCsrIO
        + W_RobBroadcastIO,
    parameter integer W_CsrOut =
        W_CsrExeIO
        + W_CsrRobIO
        + W_CsrFrontIO
        + W_CsrStatusIO,
    parameter integer W_LsuIn =
        W_RobCommitIO
        + W_RobBroadcastIO
        + W_DecBroadcastIO
        + W_CsrStatusIO
        + W_DisLsuIO
        + W_ExeLsuIO
        + W_PeripheralRespIO
        + W_DcacheLsuIO
        + W_MMULsuIO,
    parameter integer W_LsuOut =
        W_LsuDisIO
        + W_LsuRobIO
        + W_LsuExeIO
        + W_PeripheralReqIO
        + W_LsuDcacheIO
        + W_LsuMMUIO
) (
    // External inputs from frontend, DCache, peripheral and MMU/DTLB side.
    input  wire [W_FrontPreIO-1:0]       front2pre,
    input  wire [W_PeripheralRespIO-1:0] peripheral_resp,
    input  wire [W_DcacheLsuIO-1:0]      dcache2lsu,
    input  wire [W_MMULsuIO-1:0]         mmu2lsu_io,

    // External outputs back to frontend, CSR observer, DCache, peripheral
    // and MMU/DTLB side.
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
    output wire [W_PeripheralReqIO-1:0]                  peripheral_req,
    output wire [W_LsuDcacheIO-1:0]                      lsu2dcache,
    output wire [W_LsuMMUIO-1:0]                         lsu2mmu_io
);

    // ---------------------------------------------------------------------
    // 1. Module-to-module buses.
    // ---------------------------------------------------------------------

    // PreIduQueue / frontend / IDU path.
    wire [W_PreFrontIO-1:0]   pre2front;
    wire [W_PreIssueIO-1:0]   pre_issue;
    wire [W_IduConsumeIO-1:0] idu_consume;
    wire [W_ExuIdIO-1:0]      idu_br_latch;

    // Decode, rename, dispatch, issue and PRF path.
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

    // Execute and LSU path.
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

    // ROB and CSR path.
    wire [W_RobDisIO-1:0]       rob2dis;
    wire [W_RobCsrIO-1:0]       rob2csr;
    wire [W_RobBroadcastIO-1:0] rob_bcast;
    wire [W_RobCommitIO-1:0]    rob_commit;

    wire [W_CsrExeIO-1:0]    csr2exe;
    wire [W_CsrRobIO-1:0]    csr2rob;
    wire [W_CsrFrontIO-1:0]  csr2front;
    wire [W_CsrStatusIO-1:0] csr_status;

    // FTQ PC read path.
    wire [W_FtqPrfPcReqIO-1:0]  ftq_prf_pc_req;
    wire [W_FtqPrfPcRespIO-1:0] ftq_prf_pc_resp;
    wire [W_FtqRobPcReqIO-1:0]  ftq_rob_pc_req;
    wire [W_FtqRobPcRespIO-1:0] ftq_rob_pc_resp;

    // ---------------------------------------------------------------------
    // 2. Selected fields that are exposed by module wrappers for top outputs.
    // ---------------------------------------------------------------------

    // Source module: preiduqueue_top.
    wire [FETCH_WIDTH-1:0] preiduqueue_out_pre2front_fire;
    wire                   preiduqueue_out_pre2front_ready;

    // Source module: idu_top.
    wire        idu_out_dec_bcast_mispred;
    wire [31:0] idu_out_idu_br_latch_redirect_pc;

    // Source module: rob_top.
    wire        rob_out_rob_bcast_flush;
    wire        rob_out_rob_bcast_mret;
    wire        rob_out_rob_bcast_sret;
    wire        rob_out_rob_bcast_exception;
    wire        rob_out_rob_bcast_fence;
    wire        rob_out_rob_bcast_fence_i;
    wire [31:0] rob_out_rob_bcast_pc;

    // Source module: csr_top.
    wire [31:0] csr_out_csr2front_epc;
    wire [31:0] csr_out_csr2front_trap_pc;
    wire [31:0] csr_out_csr_status_sstatus;
    wire [31:0] csr_out_csr_status_mstatus;
    wire [31:0] csr_out_csr_status_satp;
    wire [1:0]  csr_out_csr_status_privilege;

    // Local top-level glue wires.
    wire [31:0] redirect_pc_from_flush;
    wire        front_stall_from_front2pre;

    // ---------------------------------------------------------------------
    // 3. Back_out.commit_entry glue.
    //
    // rob_top keeps the original RobCommitIO layout.  back_top converts that
    // layout to the submitted commit_entry format and intentionally drops
    // extra sideband fields from the external output.
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
    wire [COMMIT_WIDTH-1:0]                      backout_rob_commit_entry_uop_flush_pipe;
    wire [(32 * COMMIT_WIDTH)-1:0]               backout_commit_entry_uop_diag_val;

    // Fields that RobCommitInst does not provide are kept at the same
    // default value as C++ to_inst_entry(): zero after default init.
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
    // 4. Small top-level glue that mirrors BackTop.cpp.
    // ---------------------------------------------------------------------

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

    // Keep this exact C++ relation:
    //   rob->in.front_stall = &in.front_stall
    assign front_stall_from_front2pre =
        front2pre[W_FrontPreIO_AFTER_FRONT_STALL];

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
    // 5. Module instances in backend data-flow order.
    // ---------------------------------------------------------------------

    // Frontend input queue and FTQ PC service.
    preiduqueue_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .W_PreIduQueueIn(W_PreIduQueueIn),
        .W_PreIduQueueOut(W_PreIduQueueOut)
    ) pre (
        .front2pre(front2pre),
        .idu_consume(idu_consume),
        .rob_bcast(rob_bcast),
        .rob_commit(rob_commit),
        .idu_br_latch(idu_br_latch),
        .ftq_prf_pc_req(ftq_prf_pc_req),
        .ftq_rob_pc_req(ftq_rob_pc_req),
        .pre2front(pre2front),
        .pre_issue(pre_issue),
        .ftq_prf_pc_resp(ftq_prf_pc_resp),
        .ftq_rob_pc_resp(ftq_rob_pc_resp),
        .pre2front_fire(preiduqueue_out_pre2front_fire),
        .pre2front_ready(preiduqueue_out_pre2front_ready)
    );

    // Decode.
    idu_top #(
        .W_IduIn(W_IduIn),
        .W_IduOut(W_IduOut)
    ) idu (
        .pre_issue(pre_issue),
        .ren2dec(ren2dec),
        .rob_bcast(rob_bcast),
        .exu2id(exu2id),
        .dec2ren(dec2ren),
        .dec_bcast(dec_bcast),
        .idu_consume(idu_consume),
        .idu_br_latch(idu_br_latch),
        .dec_bcast_mispred(idu_out_dec_bcast_mispred),
        .idu_br_latch_redirect_pc(idu_out_idu_br_latch_redirect_pc)
    );

    // Rename.
    ren_top #(
        .W_RenIn(W_RenIn),
        .W_RenOut(W_RenOut)
    ) rename (
        .dec2ren(dec2ren),
        .dec_bcast(dec_bcast),
        .dis2ren(dis2ren),
        .rob_bcast(rob_bcast),
        .rob_commit(rob_commit),
        .ren2dec(ren2dec),
        .ren2dis(ren2dis)
    );

    // Dispatch.
    dispatch_top #(
        .W_DisIn(W_DisIn),
        .W_DisOut(W_DisOut)
    ) dispatch (
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

    // Issue.
    isu_top #(
        .W_IsuIn(W_IsuIn),
        .W_IsuOut(W_IsuOut)
    ) isu (
        .dis2iss(dis2iss),
        .prf_awake(prf_awake),
        .exe2iss(exe2iss),
        .rob_bcast(rob_bcast),
        .dec_bcast(dec_bcast),
        .iss2prf(iss2prf),
        .iss2dis(iss2dis),
        .iss_awake(iss_awake)
    );

    // Physical register file.
    prf_top #(
        .W_PrfIn(W_PrfIn),
        .W_PrfOut(W_PrfOut)
    ) prf (
        .iss2prf(iss2prf),
        .exe2prf(exe2prf),
        .dec_bcast(dec_bcast),
        .rob_bcast(rob_bcast),
        .ftq_prf_pc_resp(ftq_prf_pc_resp),
        .prf2exe(prf2exe),
        .prf_awake(prf_awake),
        .ftq_prf_pc_req(ftq_prf_pc_req)
    );

    // Execute.
    exu_top #(
        .W_ExuIn(W_ExuIn),
        .W_ExuOut(W_ExuOut)
    ) exu (
        .prf2exe(prf2exe),
        .dec_bcast(dec_bcast),
        .rob_bcast(rob_bcast),
        .csr2exe(csr2exe),
        .lsu2exe(lsu2exe),
        .csr_status(csr_status),
        .exe2prf(exe2prf),
        .exe2iss(exe2iss),
        .exe2csr(exe2csr),
        .exe2lsu(exe2lsu),
        .exu2id(exu2id),
        .exu2rob(exu2rob)
    );

    // Reorder buffer.
    rob_top #(
        .COMMIT_WIDTH(COMMIT_WIDTH),
        .W_InstEntry(W_InstEntry),
        .W_RobIn(W_RobIn),
        .W_RobOut(W_RobOut)
    ) rob (
        .dis2rob(dis2rob),
        .csr2rob(csr2rob),
        .lsu2rob(lsu2rob),
        .dec_bcast(dec_bcast),
        .exu2rob(exu2rob),
        .ftq_rob_pc_resp(ftq_rob_pc_resp),
        .front_stall(front_stall_from_front2pre),
        .rob2dis(rob2dis),
        .rob2csr(rob2csr),
        .rob_commit(rob_commit),
        .rob_bcast(rob_bcast),
        .ftq_rob_pc_req(ftq_rob_pc_req),
        .rob_bcast_flush(rob_out_rob_bcast_flush),
        .rob_bcast_mret(rob_out_rob_bcast_mret),
        .rob_bcast_sret(rob_out_rob_bcast_sret),
        .rob_bcast_exception(rob_out_rob_bcast_exception),
        .rob_bcast_fence(rob_out_rob_bcast_fence),
        .rob_bcast_fence_i(rob_out_rob_bcast_fence_i),
        .rob_bcast_pc(rob_out_rob_bcast_pc)
    );

    // CSR.
    csr_top #(
        .W_CsrIn(W_CsrIn),
        .W_CsrOut(W_CsrOut)
    ) csr (
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

    // Load/store unit, including external DCache/peripheral/MMU buses.
    lsu_top #(
        .W_LsuIn(W_LsuIn),
        .W_LsuOut(W_LsuOut)
    ) lsu (
        .rob_commit(rob_commit),
        .rob_bcast(rob_bcast),
        .dec_bcast(dec_bcast),
        .csr_status(csr_status),
        .dis2lsu(dis2lsu),
        .exe2lsu(exe2lsu),
        .peripheral_resp(peripheral_resp),
        .dcache2lsu(dcache2lsu),
        .mmu2lsu_io(mmu2lsu_io),
        .lsu2dis(lsu2dis),
        .lsu2rob(lsu2rob),
        .lsu2exe(lsu2exe),
        .peripheral_req(peripheral_req),
        .lsu2dcache(lsu2dcache),
        .lsu2mmu_io(lsu2mmu_io)
    );

    // ---------------------------------------------------------------------
    // 6. External output assembly.
    // ---------------------------------------------------------------------

    // Frontend-visible control outputs.
    assign fire       = preiduqueue_out_pre2front_fire;
    assign flush      = rob_out_rob_bcast_flush;
    assign fence_i    = rob_out_rob_bcast_fence_i;
    assign itlb_flush = rob_out_rob_bcast_fence;

    assign mispred = rob_out_rob_bcast_flush ? 1'b1 : idu_out_dec_bcast_mispred;
    assign stall   = ~preiduqueue_out_pre2front_ready;

    // Redirect PC follows BackTop.cpp:
    //   normal path -> IDU branch latch
    //   flush path  -> CSR epc/trap_pc or ROB pc + 4
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

    // CSR state outputs.
    assign sstatus   = csr_out_csr_status_sstatus;
    assign mstatus   = csr_out_csr_status_mstatus;
    assign satp      = csr_out_csr_status_satp;
    assign privilege = csr_out_csr_status_privilege;

    // Back_out.commit_entry follows InstEntry field order.
    // Field source rule:
    //   1. fields provided by RobCommitInst use backout_rob_commit_entry_uop_*;
    //   2. fields not provided by RobCommitInst use commit_entry_zero_*.
    assign commit_entry = {
        // InstEntry.valid.
        backout_rob_commit_entry_valid,

        // InstInfo architectural and physical register fields.
        backout_commit_entry_uop_diag_val,
        backout_rob_commit_entry_uop_dest_areg,
        commit_entry_zero_src_areg,
        backout_rob_commit_entry_uop_dest_preg,
        commit_entry_zero_src_preg,
        backout_rob_commit_entry_uop_old_dest_preg,

        // FTQ and branch prediction fields.
        backout_rob_commit_entry_uop_ftq_idx,
        backout_rob_commit_entry_uop_ftq_offset,
        backout_rob_commit_entry_uop_ftq_is_last,
        backout_rob_commit_entry_uop_mispred,
        backout_rob_commit_entry_uop_br_taken,

        // Operand and immediate fields.
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

        // ROB/LSU bookkeeping fields.
        backout_rob_commit_entry_uop_rob_idx,
        backout_rob_commit_entry_uop_stq_idx,
        backout_rob_commit_entry_uop_stq_flag,
        commit_entry_zero_ldq_idx,
        commit_entry_zero_expect_mask,
        commit_entry_zero_cplt_mask,
        backout_rob_commit_entry_uop_rob_flag,

        // Exception and type fields.
        backout_rob_commit_entry_uop_page_fault_inst,
        backout_rob_commit_entry_uop_page_fault_load,
        backout_rob_commit_entry_uop_page_fault_store,
        backout_rob_commit_entry_uop_illegal_inst,
        commit_entry_zero_is_atomic,
        backout_rob_commit_entry_uop_flush_pipe,
        backout_rob_commit_entry_uop_type
    };

endmodule
