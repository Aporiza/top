// Source struct:
//   IsuIn  = {dis2iss, prf_awake, exe2iss, rob_bcast, dec_bcast}
//   IsuOut = {iss2prf, iss2dis, iss_awake}
// Issue queues and wakeup slots are private implementation state.

module isu_top #(
    parameter integer DECODE_WIDTH = 8,
    parameter integer PRF_IDX_WIDTH = 11,
    parameter integer ROB_IDX_WIDTH = 11,
    parameter integer STQ_IDX_WIDTH = 9,
    parameter integer LDQ_IDX_WIDTH = 9,
    parameter integer BR_TAG_WIDTH = 6,
    parameter integer BR_MASK_WIDTH = 64,
    parameter integer CSR_IDX_WIDTH = 12,
    parameter integer FTQ_IDX_WIDTH = 8,
    parameter integer FTQ_OFFSET_WIDTH = 4,
    parameter integer UOP_TYPE_WIDTH = 5,
    parameter integer IQ_NUM = 5,
    parameter integer MAX_UOP_TYPE = 18,
    parameter integer IQ_READY_NUM_WIDTH = 11,
    parameter integer MAX_IQ_DISPATCH_WIDTH = DECODE_WIDTH,
    parameter integer LSU_LOAD_WB_WIDTH = 4,
    parameter integer MAX_WAKEUP_PORTS = 16,
    parameter integer ISSUE_WIDTH = 24,
    parameter integer W_DebugMeta = 32 + 32 + 8 + 1 + 64,
    parameter integer W_DisIssUop =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_DisIssIO =
        IQ_NUM * MAX_IQ_DISPATCH_WIDTH * (1 + W_DisIssUop),
    parameter integer W_WakeInfo = 1 + PRF_IDX_WIDTH,
    parameter integer W_PrfAwakeIO = LSU_LOAD_WB_WIDTH * W_WakeInfo,
    parameter integer W_ExeIssIO = ISSUE_WIDTH * MAX_UOP_TYPE,
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_DecBroadcastIO =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_IssPrfUop =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_IssPrfIO = ISSUE_WIDTH * (1 + W_IssPrfUop),
    parameter integer W_IssDisIO = IQ_NUM * IQ_READY_NUM_WIDTH,
    parameter integer W_IssAwakeIO = MAX_WAKEUP_PORTS * W_WakeInfo,
    parameter integer W_IsuIn =
        W_DisIssIO + W_PrfAwakeIO + W_ExeIssIO + W_RobBroadcastIO +
        W_DecBroadcastIO,
    parameter integer W_IsuOut = W_IssPrfIO + W_IssDisIO + W_IssAwakeIO
) (
    input  wire [W_DisIssIO-1:0]       dis2iss,
    input  wire [W_PrfAwakeIO-1:0]     prf_awake,
    input  wire [W_ExeIssIO-1:0]       exe2iss,
    input  wire [W_RobBroadcastIO-1:0] rob_bcast,
    input  wire [W_DecBroadcastIO-1:0] dec_bcast,

    output wire [W_IssPrfIO-1:0]       iss2prf,
    output wire [W_IssDisIO-1:0]       iss2dis,
    output wire [W_IssAwakeIO-1:0]     iss_awake
);

    wire [W_IsuIn-1:0]  pi;
    wire [W_IsuOut-1:0] po;

    localparam integer N_DisIssReq = IQ_NUM * MAX_IQ_DISPATCH_WIDTH;

    // Field-level view of dis2iss, matching DisIssIO.
    wire [N_DisIssReq-1:0] dis2iss_req_valid;
    wire [(PRF_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_src1_preg;
    wire [(PRF_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_src2_preg;
    wire [(FTQ_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * N_DisIssReq)-1:0]
        dis2iss_req_uop_ftq_offset;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_is_atomic;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_dest_en;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_src1_en;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_src2_en;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_src1_busy;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_src2_busy;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_src1_is_pc;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_src2_is_imm;
    wire [(3 * N_DisIssReq)-1:0] dis2iss_req_uop_func3;
    wire [(7 * N_DisIssReq)-1:0] dis2iss_req_uop_func7;
    wire [(32 * N_DisIssReq)-1:0] dis2iss_req_uop_imm;
    wire [(BR_TAG_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_br_id;
    wire [(BR_MASK_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_br_mask;
    wire [(CSR_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_csr_idx;
    wire [(ROB_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_stq_idx;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_ldq_idx;
    wire [N_DisIssReq-1:0] dis2iss_req_uop_rob_flag;
    wire [(UOP_TYPE_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_op;
    wire [(W_DebugMeta * N_DisIssReq)-1:0] dis2iss_req_uop_dbg;

    assign {dis2iss_req_valid,
            dis2iss_req_uop_dest_preg,
            dis2iss_req_uop_src1_preg,
            dis2iss_req_uop_src2_preg,
            dis2iss_req_uop_ftq_idx,
            dis2iss_req_uop_ftq_offset,
            dis2iss_req_uop_is_atomic,
            dis2iss_req_uop_dest_en,
            dis2iss_req_uop_src1_en,
            dis2iss_req_uop_src2_en,
            dis2iss_req_uop_src1_busy,
            dis2iss_req_uop_src2_busy,
            dis2iss_req_uop_src1_is_pc,
            dis2iss_req_uop_src2_is_imm,
            dis2iss_req_uop_func3,
            dis2iss_req_uop_func7,
            dis2iss_req_uop_imm,
            dis2iss_req_uop_br_id,
            dis2iss_req_uop_br_mask,
            dis2iss_req_uop_csr_idx,
            dis2iss_req_uop_rob_idx,
            dis2iss_req_uop_stq_idx,
            dis2iss_req_uop_stq_flag,
            dis2iss_req_uop_ldq_idx,
            dis2iss_req_uop_rob_flag,
            dis2iss_req_uop_op,
            dis2iss_req_uop_dbg} = dis2iss;

    wire [LSU_LOAD_WB_WIDTH-1:0] prf_awake_wake_valid;
    wire [(PRF_IDX_WIDTH * LSU_LOAD_WB_WIDTH)-1:0] prf_awake_wake_preg;
    assign {prf_awake_wake_valid, prf_awake_wake_preg} = prf_awake;

    wire [(MAX_UOP_TYPE * ISSUE_WIDTH)-1:0] exe2iss_fu_ready_mask;
    assign exe2iss_fu_ready_mask = exe2iss;

    wire rob_bcast_flush;
    wire rob_bcast_mret;
    wire rob_bcast_sret;
    wire rob_bcast_ecall;
    wire rob_bcast_exception;
    wire rob_bcast_fence;
    wire rob_bcast_fence_i;
    wire rob_bcast_page_fault_inst;
    wire rob_bcast_page_fault_load;
    wire rob_bcast_page_fault_store;
    wire rob_bcast_illegal_inst;
    wire rob_bcast_interrupt;
    wire [31:0] rob_bcast_trap_val;
    wire [31:0] rob_bcast_pc;
    wire [ROB_IDX_WIDTH-1:0] rob_bcast_head_rob_idx;
    wire rob_bcast_head_valid;
    wire [ROB_IDX_WIDTH-1:0] rob_bcast_head_incomplete_rob_idx;
    wire rob_bcast_head_incomplete_valid;
    assign {rob_bcast_flush, rob_bcast_mret, rob_bcast_sret,
            rob_bcast_ecall, rob_bcast_exception, rob_bcast_fence,
            rob_bcast_fence_i, rob_bcast_page_fault_inst,
            rob_bcast_page_fault_load, rob_bcast_page_fault_store,
            rob_bcast_illegal_inst, rob_bcast_interrupt,
            rob_bcast_trap_val, rob_bcast_pc, rob_bcast_head_rob_idx,
            rob_bcast_head_valid, rob_bcast_head_incomplete_rob_idx,
            rob_bcast_head_incomplete_valid} = rob_bcast;

    wire dec_bcast_mispred;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_br_mask;
    wire [BR_TAG_WIDTH-1:0] dec_bcast_br_id;
    wire [ROB_IDX_WIDTH-1:0] dec_bcast_redirect_rob_idx;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_clear_mask;
    assign {dec_bcast_mispred, dec_bcast_br_mask, dec_bcast_br_id,
            dec_bcast_redirect_rob_idx, dec_bcast_clear_mask} = dec_bcast;

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
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_is_atomic;
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_dest_en;
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_src1_en;
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_src2_en;
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_src1_is_pc;
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_src2_is_imm;
    wire [(3 * ISSUE_WIDTH)-1:0] iss2prf_iss_entry_uop_func3;
    wire [(7 * ISSUE_WIDTH)-1:0] iss2prf_iss_entry_uop_func7;
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
    wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_uop_rob_flag;
    wire [(UOP_TYPE_WIDTH * ISSUE_WIDTH)-1:0] iss2prf_iss_entry_uop_op;
    wire [(W_DebugMeta * ISSUE_WIDTH)-1:0] iss2prf_iss_entry_uop_dbg;

    assign {iss2prf_iss_entry_valid,
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
            iss2prf_iss_entry_uop_op,
            iss2prf_iss_entry_uop_dbg} = iss2prf;

    wire [(IQ_READY_NUM_WIDTH * IQ_NUM)-1:0] iss2dis_ready_num;
    assign iss2dis_ready_num = iss2dis;

    wire [MAX_WAKEUP_PORTS-1:0] iss_awake_wake_valid;
    wire [(PRF_IDX_WIDTH * MAX_WAKEUP_PORTS)-1:0] iss_awake_wake_preg;
    assign {iss_awake_wake_valid, iss_awake_wake_preg} = iss_awake;

    assign pi = {dis2iss, prf_awake, exe2iss, rob_bcast, dec_bcast};
    assign {iss2prf, iss2dis, iss_awake} = po;

    isu_bsd_top #(
        .W_IsuIn(W_IsuIn),
        .W_IsuOut(W_IsuOut)
    ) u_isu_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
