// Source struct:
//   PrfIn  = {iss2prf, exe2prf, dec_bcast, rob_bcast, ftq_prf_pc_resp}
//   PrfOut = {prf2exe, prf_awake, ftq_prf_pc_req}
// reg_file[PRF_NUM], bypass/equal logic and read/write slices are internal.

// -----------------------------------------------------------------------------
// 后端端口自查
// 模块：prf_top
// 文件：prf/prf_top.v:66
// 来源：当前 back_end RTL module 声明
// BSD 层：prf_bsd_top，实例名 u_prf_bsd_top，当前仓库未提供定义
//
// 输入端口：5 个，合计 12294 bit
// 输出端口：3 个，合计 8412 bit
//
// 参数：
//   ISSUE_WIDTH         = 24  // 24
//   TOTAL_FU_COUNT      = 30  // 30
//   LSU_LOAD_WB_WIDTH   = 4  // 4
//   PRF_IDX_WIDTH       = 11  // 11
//   ROB_IDX_WIDTH       = 11  // 11
//   STQ_IDX_WIDTH       = 9  // 9
//   LDQ_IDX_WIDTH       = 9  // 9
//   BR_TAG_WIDTH        = 6  // 6
//   BR_MASK_WIDTH       = 64  // 64
//   CSR_IDX_WIDTH       = 12  // 12
//   FTQ_IDX_WIDTH       = 8  // 8
//   FTQ_OFFSET_WIDTH    = 4  // 4
//   UOP_TYPE_WIDTH      = 5  // 5
//   MAX_UOP_TYPE        = 18  // 18
//   FTQ_PRF_PC_PORT_NUM = 12  // 12
//   W_IssPrfUop         = (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 3 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + UOP_TYPE_WIDTH  // 211
//   W_IssPrfIO          = ISSUE_WIDTH * (1 + W_IssPrfUop)  // 5088
//   W_ExePrfWbUop       = PRF_IDX_WIDTH + 32 + BR_MASK_WIDTH + 1 + UOP_TYPE_WIDTH  // 113
//   W_ExePrfEntry       = 1 + W_ExePrfWbUop  // 114
//   W_ExePrfIO          = (ISSUE_WIDTH + TOTAL_FU_COUNT) * W_ExePrfEntry  // 6156
//   W_DecBroadcastIO    = 1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH  // 146
//   W_RobBroadcastIO    = 7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1  // 100
//   W_FtqPcReadReq      = 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH  // 13
//   W_FtqPcReadResp     = 1 + 1 + 32 + 1 + 32  // 67
//   W_FtqPrfPcReqIO     = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadReq  // 156
//   W_FtqPrfPcRespIO    = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadResp  // 804
//   W_WakeInfo          = 1 + PRF_IDX_WIDTH  // 12
//   W_PrfAwakeIO        = LSU_LOAD_WB_WIDTH * W_WakeInfo  // 48
//   W_PrfExeUop         = 32 + 1 + 1 + 32 + (3 * PRF_IDX_WIDTH) + 64 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 3 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + UOP_TYPE_WIDTH  // 341
//   W_PrfExeIO          = ISSUE_WIDTH * (1 + W_PrfExeUop)  // 8208
//   W_PrfIn             = W_IssPrfIO + W_ExePrfIO + W_DecBroadcastIO + W_RobBroadcastIO + W_FtqPrfPcRespIO  // 12294
//   W_PrfOut            = W_PrfExeIO + W_PrfAwakeIO + W_FtqPrfPcReqIO  // 8412
//
// 输入端口：
//   iss2prf          [W_IssPrfIO-1:0]        5088 bit
//   exe2prf          [W_ExePrfIO-1:0]        6156 bit
//   dec_bcast        [W_DecBroadcastIO-1:0]  146 bit
//   rob_bcast        [W_RobBroadcastIO-1:0]  100 bit
//   ftq_prf_pc_resp  [W_FtqPrfPcRespIO-1:0]  804 bit
//
// 输出端口：
//   prf2exe         [W_PrfExeIO-1:0]       8208 bit
//   prf_awake       [W_PrfAwakeIO-1:0]     48 bit
//   ftq_prf_pc_req  [W_FtqPrfPcReqIO-1:0]  156 bit
//
// BSD 层端口：当前仓库只实例化该 bsd_top，未提供 module 定义。
// 后续补 bsd_top 时，需要保持实例名和 pi/po 连接一致。
// -----------------------------------------------------------------------------

module prf_top #(
    parameter integer ISSUE_WIDTH            = 24,
    parameter integer TOTAL_FU_COUNT         = 30,
    parameter integer LSU_LOAD_WB_WIDTH      = 4,
    parameter integer PRF_IDX_WIDTH       = 11,
    parameter integer ROB_IDX_WIDTH       = 11,
    parameter integer STQ_IDX_WIDTH       = 9,
    parameter integer LDQ_IDX_WIDTH       = 9,
    parameter integer BR_TAG_WIDTH        = 6,
    parameter integer BR_MASK_WIDTH       = 64,
    parameter integer CSR_IDX_WIDTH       = 12,
    parameter integer FTQ_IDX_WIDTH       = 8,
    parameter integer FTQ_OFFSET_WIDTH    = 4,
    parameter integer UOP_TYPE_WIDTH      = 5,
    parameter integer MAX_UOP_TYPE        = 18,
    parameter integer FTQ_PRF_PC_PORT_NUM    = 12,
    parameter integer W_IssPrfUop         =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH,
    parameter integer W_IssPrfIO    = ISSUE_WIDTH * (1 + W_IssPrfUop),
    parameter integer W_ExePrfWbUop =
        PRF_IDX_WIDTH + 32 + BR_MASK_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExePrfEntry = 1 + W_ExePrfWbUop,
    parameter integer W_ExePrfIO    =
        (ISSUE_WIDTH + TOTAL_FU_COUNT) * W_ExePrfEntry,
    parameter integer W_DecBroadcastIO =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_FtqPcReadReq   = 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH,
    parameter integer W_FtqPcReadResp  = 1 + 1 + 32 + 1 + 32,
    parameter integer W_FtqPrfPcReqIO  = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqPrfPcRespIO = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_WakeInfo       = 1 + PRF_IDX_WIDTH,
    parameter integer W_PrfAwakeIO     = LSU_LOAD_WB_WIDTH * W_WakeInfo,
    parameter integer W_PrfExeUop      =
        32 + 1 + 1 + 32 + (3 * PRF_IDX_WIDTH) + 64 +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 3 + 2 + 3 + 7 + 32 +
        BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_PrfExeIO = ISSUE_WIDTH * (1 + W_PrfExeUop),
    parameter integer W_PrfIn    =
        W_IssPrfIO + W_ExePrfIO + W_DecBroadcastIO + W_RobBroadcastIO +
        W_FtqPrfPcRespIO,
    parameter integer W_PrfOut =
        W_PrfExeIO + W_PrfAwakeIO + W_FtqPrfPcReqIO
) (
    input wire [W_IssPrfIO-1:0]       iss2prf,
    input wire [W_ExePrfIO-1:0]       exe2prf,
    input wire [W_DecBroadcastIO-1:0] dec_bcast,
    input wire [W_RobBroadcastIO-1:0] rob_bcast,
    input wire [W_FtqPrfPcRespIO-1:0] ftq_prf_pc_resp,

    output wire [W_PrfExeIO-1:0]      prf2exe,
    output wire [W_PrfAwakeIO-1:0]    prf_awake,
    output wire [W_FtqPrfPcReqIO-1:0] ftq_prf_pc_req
);

    wire [W_PrfIn-1:0]  pi;
    wire [W_PrfOut-1:0] po;

    // Field-level view of iss2prf, matching IssPrfIO.
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_valid;
    wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_src1_preg;
    wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_src2_preg;
    wire [(FTQ_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_ftq_offset;
    wire [ISSUE_WIDTH-1:0]        iss2prf_iss_entry_uop_is_atomic;
    wire [ISSUE_WIDTH-1:0]        iss2prf_iss_entry_uop_dest_en;
    wire [ISSUE_WIDTH-1:0]        iss2prf_iss_entry_uop_src1_en;
    wire [ISSUE_WIDTH-1:0]        iss2prf_iss_entry_uop_src2_en;
    wire [ISSUE_WIDTH-1:0]        iss2prf_iss_entry_uop_src1_is_pc;
    wire [ISSUE_WIDTH-1:0]        iss2prf_iss_entry_uop_src2_is_imm;
    wire [(3 * ISSUE_WIDTH)-1:0]  iss2prf_iss_entry_uop_func3;
    wire [(7 * ISSUE_WIDTH)-1:0]  iss2prf_iss_entry_uop_func7;
    wire [(32 * ISSUE_WIDTH)-1:0] iss2prf_iss_entry_uop_imm;
    wire [(BR_TAG_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_br_id;
    wire [(BR_MASK_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_br_mask;
    wire [(CSR_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_csr_idx;
    wire [(ROB_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_stq_idx;
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        iss2prf_iss_entry_uop_ldq_idx;
    wire [ISSUE_WIDTH-1:0]                    iss2prf_iss_entry_uop_rob_flag;
    wire [(UOP_TYPE_WIDTH * ISSUE_WIDTH)-1:0] iss2prf_iss_entry_uop_op;

    assign {
        iss2prf_iss_entry_valid,
        iss2prf_iss_entry_uop_dest_preg,
        iss2prf_iss_entry_uop_src1_preg,
        iss2prf_iss_entry_uop_src2_preg,
        iss2prf_iss_entry_uop_ftq_idx,
        iss2prf_iss_entry_uop_ftq_offset,
        iss2prf_iss_entry_uop_is_atomic,
        iss2prf_iss_entry_uop_dest_en,
        iss2prf_iss_entry_uop_src1_en,
        iss2prf_iss_entry_uop_src2_en,
        iss2prf_iss_entry_uop_src1_is_pc,
        iss2prf_iss_entry_uop_src2_is_imm,
        iss2prf_iss_entry_uop_func3,
        iss2prf_iss_entry_uop_func7,
        iss2prf_iss_entry_uop_imm,
        iss2prf_iss_entry_uop_br_id,
        iss2prf_iss_entry_uop_br_mask,
        iss2prf_iss_entry_uop_csr_idx,
        iss2prf_iss_entry_uop_rob_idx,
        iss2prf_iss_entry_uop_stq_idx,
        iss2prf_iss_entry_uop_stq_flag,
        iss2prf_iss_entry_uop_ldq_idx,
        iss2prf_iss_entry_uop_rob_flag,
        iss2prf_iss_entry_uop_op
    } = iss2prf;

    // Field-level view of exe2prf, matching ExePrfIO.
    wire [ISSUE_WIDTH-1:0]                    exe2prf_entry_valid;
    wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]  exe2prf_entry_uop_dest_preg;
    wire [(32 * ISSUE_WIDTH)-1:0]             exe2prf_entry_uop_result;
    wire [(BR_MASK_WIDTH * ISSUE_WIDTH)-1:0]  exe2prf_entry_uop_br_mask;
    wire [ISSUE_WIDTH-1:0]                    exe2prf_entry_uop_dest_en;
    wire [(UOP_TYPE_WIDTH * ISSUE_WIDTH)-1:0] exe2prf_entry_uop_op;
    wire [TOTAL_FU_COUNT-1:0]                 exe2prf_bypass_valid;
    wire [(PRF_IDX_WIDTH * TOTAL_FU_COUNT)-1:0]
        exe2prf_bypass_uop_dest_preg;
    wire [(32 * TOTAL_FU_COUNT)-1:0] exe2prf_bypass_uop_result;
    wire [(BR_MASK_WIDTH * TOTAL_FU_COUNT)-1:0]
        exe2prf_bypass_uop_br_mask;
    wire [TOTAL_FU_COUNT-1:0]                    exe2prf_bypass_uop_dest_en;
    wire [(UOP_TYPE_WIDTH * TOTAL_FU_COUNT)-1:0] exe2prf_bypass_uop_op;

    assign {
        exe2prf_entry_valid,
        exe2prf_entry_uop_dest_preg,
        exe2prf_entry_uop_result,
        exe2prf_entry_uop_br_mask,
        exe2prf_entry_uop_dest_en,
        exe2prf_entry_uop_op,
        exe2prf_bypass_valid,
        exe2prf_bypass_uop_dest_preg,
        exe2prf_bypass_uop_result,
        exe2prf_bypass_uop_br_mask,
        exe2prf_bypass_uop_dest_en,
        exe2prf_bypass_uop_op
    } = exe2prf;

    // Field-level view of shared broadcast and FTQ response inputs.
    wire                     dec_bcast_mispred;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_br_mask;
    wire [BR_TAG_WIDTH-1:0]  dec_bcast_br_id;
    wire [ROB_IDX_WIDTH-1:0] dec_bcast_redirect_rob_idx;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_clear_mask;
    assign {
        dec_bcast_mispred,
        dec_bcast_br_mask,
        dec_bcast_br_id,
        dec_bcast_redirect_rob_idx,
        dec_bcast_clear_mask
    } = dec_bcast;

    wire                     rob_bcast_flush;
    wire                     rob_bcast_mret;
    wire                     rob_bcast_sret;
    wire                     rob_bcast_ecall;
    wire                     rob_bcast_exception;
    wire                     rob_bcast_fence;
    wire                     rob_bcast_fence_i;
    wire                     rob_bcast_page_fault_inst;
    wire                     rob_bcast_page_fault_load;
    wire                     rob_bcast_page_fault_store;
    wire                     rob_bcast_illegal_inst;
    wire                     rob_bcast_interrupt;
    wire [31:0]              rob_bcast_trap_val;
    wire [31:0]              rob_bcast_pc;
    wire [ROB_IDX_WIDTH-1:0] rob_bcast_head_rob_idx;
    wire                     rob_bcast_head_valid;
    wire [ROB_IDX_WIDTH-1:0] rob_bcast_head_incomplete_rob_idx;
    wire                     rob_bcast_head_incomplete_valid;
    assign {
        rob_bcast_flush,
        rob_bcast_mret,
        rob_bcast_sret,
        rob_bcast_ecall,
        rob_bcast_exception,
        rob_bcast_fence,
        rob_bcast_fence_i,
        rob_bcast_page_fault_inst,
        rob_bcast_page_fault_load,
        rob_bcast_page_fault_store,
        rob_bcast_illegal_inst,
        rob_bcast_interrupt,
        rob_bcast_trap_val,
        rob_bcast_pc,
        rob_bcast_head_rob_idx,
        rob_bcast_head_valid,
        rob_bcast_head_incomplete_rob_idx,
        rob_bcast_head_incomplete_valid
    } = rob_bcast;

    wire [FTQ_PRF_PC_PORT_NUM-1:0]        ftq_prf_pc_resp_valid;
    wire [FTQ_PRF_PC_PORT_NUM-1:0]        ftq_prf_pc_resp_entry_valid;
    wire [(32 * FTQ_PRF_PC_PORT_NUM)-1:0] ftq_prf_pc_resp_pc;
    wire [FTQ_PRF_PC_PORT_NUM-1:0]        ftq_prf_pc_resp_pred_taken;
    wire [(32 * FTQ_PRF_PC_PORT_NUM)-1:0] ftq_prf_pc_resp_next_pc;
    assign {
        ftq_prf_pc_resp_valid,
        ftq_prf_pc_resp_entry_valid,
        ftq_prf_pc_resp_pc,
        ftq_prf_pc_resp_pred_taken,
        ftq_prf_pc_resp_next_pc
    } = ftq_prf_pc_resp;

    // Field-level view of prf2exe, matching PrfExeIO.
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_valid;
    wire [(32 * ISSUE_WIDTH)-1:0] prf2exe_iss_entry_uop_pc;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_ftq_resp_valid;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_ftq_pred_taken;
    wire [(32 * ISSUE_WIDTH)-1:0] prf2exe_iss_entry_uop_ftq_next_pc;
    wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_src1_preg;
    wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_src2_preg;
    wire [(32 * ISSUE_WIDTH)-1:0] prf2exe_iss_entry_uop_src1_rdata;
    wire [(32 * ISSUE_WIDTH)-1:0] prf2exe_iss_entry_uop_src2_rdata;
    wire [(FTQ_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_ftq_offset;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_is_atomic;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_dest_en;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_src1_en;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_src2_en;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_src1_is_pc;
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_uop_src2_is_imm;
    wire [(3 * ISSUE_WIDTH)-1:0]  prf2exe_iss_entry_uop_func3;
    wire [(7 * ISSUE_WIDTH)-1:0]  prf2exe_iss_entry_uop_func7;
    wire [(32 * ISSUE_WIDTH)-1:0] prf2exe_iss_entry_uop_imm;
    wire [(BR_TAG_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_br_id;
    wire [(BR_MASK_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_br_mask;
    wire [(CSR_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_csr_idx;
    wire [(ROB_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_stq_idx;
    wire [ISSUE_WIDTH-1:0] prf2exe_iss_entry_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * ISSUE_WIDTH)-1:0]
        prf2exe_iss_entry_uop_ldq_idx;
    wire [ISSUE_WIDTH-1:0]                    prf2exe_iss_entry_uop_rob_flag;
    wire [(UOP_TYPE_WIDTH * ISSUE_WIDTH)-1:0] prf2exe_iss_entry_uop_op;

    assign {
        prf2exe_iss_entry_valid,
        prf2exe_iss_entry_uop_pc,
        prf2exe_iss_entry_uop_ftq_resp_valid,
        prf2exe_iss_entry_uop_ftq_pred_taken,
        prf2exe_iss_entry_uop_ftq_next_pc,
        prf2exe_iss_entry_uop_dest_preg,
        prf2exe_iss_entry_uop_src1_preg,
        prf2exe_iss_entry_uop_src2_preg,
        prf2exe_iss_entry_uop_src1_rdata,
        prf2exe_iss_entry_uop_src2_rdata,
        prf2exe_iss_entry_uop_ftq_idx,
        prf2exe_iss_entry_uop_ftq_offset,
        prf2exe_iss_entry_uop_is_atomic,
        prf2exe_iss_entry_uop_dest_en,
        prf2exe_iss_entry_uop_src1_en,
        prf2exe_iss_entry_uop_src2_en,
        prf2exe_iss_entry_uop_src1_is_pc,
        prf2exe_iss_entry_uop_src2_is_imm,
        prf2exe_iss_entry_uop_func3,
        prf2exe_iss_entry_uop_func7,
        prf2exe_iss_entry_uop_imm,
        prf2exe_iss_entry_uop_br_id,
        prf2exe_iss_entry_uop_br_mask,
        prf2exe_iss_entry_uop_csr_idx,
        prf2exe_iss_entry_uop_rob_idx,
        prf2exe_iss_entry_uop_stq_idx,
        prf2exe_iss_entry_uop_stq_flag,
        prf2exe_iss_entry_uop_ldq_idx,
        prf2exe_iss_entry_uop_rob_flag,
        prf2exe_iss_entry_uop_op
    } = prf2exe;

    wire [LSU_LOAD_WB_WIDTH-1:0]                   prf_awake_wake_valid;
    wire [(PRF_IDX_WIDTH * LSU_LOAD_WB_WIDTH)-1:0] prf_awake_wake_preg;
    assign {
        prf_awake_wake_valid,
        prf_awake_wake_preg
    } = prf_awake;

    wire [FTQ_PRF_PC_PORT_NUM-1:0] ftq_prf_pc_req_valid;
    wire [(FTQ_IDX_WIDTH * FTQ_PRF_PC_PORT_NUM)-1:0]
        ftq_prf_pc_req_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * FTQ_PRF_PC_PORT_NUM)-1:0]
        ftq_prf_pc_req_ftq_offset;
    assign {
        ftq_prf_pc_req_valid,
        ftq_prf_pc_req_ftq_idx,
        ftq_prf_pc_req_ftq_offset
    } = ftq_prf_pc_req;

    assign pi = {
        iss2prf,
        exe2prf,
        dec_bcast,
        rob_bcast,
        ftq_prf_pc_resp
    };
    assign {
        prf2exe,
        prf_awake,
        ftq_prf_pc_req
    } = po;

    prf_bsd_top #(
        .W_PrfIn(W_PrfIn),
        .W_PrfOut(W_PrfOut)
    ) u_prf_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
