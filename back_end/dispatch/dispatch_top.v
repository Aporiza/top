// Source struct:
//   DisIn  = {ren2dis, rob2dis, iss2dis, lsu2dis, prf_awake, iss_awake,
//             rob_bcast, dec_bcast}
//   DisOut = {dis2ren, dis2rob, dis2iss, dis2lsu}
// Busy-table, dispatch cache and allocation bookkeeping remain internal.

module dispatch_top #(
    parameter integer DECODE_WIDTH           = 8,
    parameter integer AREG_IDX_WIDTH         = 6,
    parameter integer PRF_IDX_WIDTH          = 11,
    parameter integer ROB_IDX_WIDTH          = 11,
    parameter integer STQ_IDX_WIDTH          = 9,
    parameter integer LDQ_IDX_WIDTH          = 9,
    parameter integer BR_TAG_WIDTH           = 6,
    parameter integer BR_MASK_WIDTH          = 64,
    parameter integer CSR_IDX_WIDTH          = 12,
    parameter integer FTQ_IDX_WIDTH          = 8,
    parameter integer FTQ_OFFSET_WIDTH       = 4,
    parameter integer INST_TYPE_WIDTH        = 5,
    parameter integer UOP_TYPE_WIDTH         = 5,
    parameter integer ROB_CPLT_MASK_WIDTH    = 3,
    parameter integer IQ_NUM                 = 5,
    parameter integer IQ_READY_NUM_WIDTH     = 11,
    parameter integer MAX_IQ_DISPATCH_WIDTH  = DECODE_WIDTH,
    parameter integer MAX_STQ_DISPATCH_WIDTH = DECODE_WIDTH,
    parameter integer MAX_LDQ_DISPATCH_WIDTH = DECODE_WIDTH,
    parameter integer LSU_LOAD_WB_WIDTH      = 4,
    parameter integer MAX_WAKEUP_PORTS       = 16,
    parameter integer W_STQ_COUNT            = 10,
    parameter integer W_LDQ_COUNT            = 10,
    parameter integer W_RenDisInst           =
        32 + (3 * AREG_IDX_WIDTH) + (4 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + INST_TYPE_WIDTH + 3 + 1 + 2 + 2 + 3 + 7 +
        32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 2,
    parameter integer W_RenDisIO = DECODE_WIDTH * (W_RenDisInst + 1),
    parameter integer W_RobDisIO = 3 + ROB_IDX_WIDTH + 1,
    parameter integer W_IssDisIO = IQ_NUM * IQ_READY_NUM_WIDTH,
    parameter integer W_LsuDisIO =
        STQ_IDX_WIDTH + 1 + W_STQ_COUNT + W_LDQ_COUNT +
        (LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH) + MAX_LDQ_DISPATCH_WIDTH,
    parameter integer W_WakeInfo       = 1 + PRF_IDX_WIDTH,
    parameter integer W_PrfAwakeIO     = LSU_LOAD_WB_WIDTH * W_WakeInfo,
    parameter integer W_IssAwakeIO     = MAX_WAKEUP_PORTS * W_WakeInfo,
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_DecBroadcastIO =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_DisRenIO   = 1,
    parameter integer W_DisRobInst =
        32 + (2 * AREG_IDX_WIDTH) + (2 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + 2 + INST_TYPE_WIDTH + 1 + 1 + 3 + 7 + 32 +
        BR_MASK_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 1 + 3,
    parameter integer W_DisRobIO  = DECODE_WIDTH * (W_DisRobInst + 1 + 1),
    parameter integer W_DisIssUop =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH,
    parameter integer W_DisIssIO =
        IQ_NUM * MAX_IQ_DISPATCH_WIDTH * (1 + W_DisIssUop),
    parameter integer W_DisLsuIO =
        MAX_STQ_DISPATCH_WIDTH *
            (1 + BR_MASK_WIDTH + 3 + ROB_IDX_WIDTH + 1 + 1) +
        MAX_LDQ_DISPATCH_WIDTH *
            (1 + LDQ_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1),
    parameter integer W_DisIn =
        W_RenDisIO + W_RobDisIO + W_IssDisIO + W_LsuDisIO + W_PrfAwakeIO +
        W_IssAwakeIO + W_RobBroadcastIO + W_DecBroadcastIO,
    parameter integer W_DisOut =
        W_DisRenIO + W_DisRobIO + W_DisIssIO + W_DisLsuIO
) (
    input wire [W_RenDisIO-1:0]       ren2dis,
    input wire [W_RobDisIO-1:0]       rob2dis,
    input wire [W_IssDisIO-1:0]       iss2dis,
    input wire [W_LsuDisIO-1:0]       lsu2dis,
    input wire [W_PrfAwakeIO-1:0]     prf_awake,
    input wire [W_IssAwakeIO-1:0]     iss_awake,
    input wire [W_RobBroadcastIO-1:0] rob_bcast,
    input wire [W_DecBroadcastIO-1:0] dec_bcast,

    output wire [W_DisRenIO-1:0] dis2ren,
    output wire [W_DisRobIO-1:0] dis2rob,
    output wire [W_DisIssIO-1:0] dis2iss,
    output wire [W_DisLsuIO-1:0] dis2lsu
);

    wire [W_DisIn-1:0]  pi;
    wire [W_DisOut-1:0] po;

    localparam integer N_DisIssReq = IQ_NUM * MAX_IQ_DISPATCH_WIDTH;

    // Field-level view of ren2dis, matching RenDisIO.
    wire [DECODE_WIDTH-1:0]                  ren2dis_valid;
    wire [(W_RenDisInst * DECODE_WIDTH)-1:0] ren2dis_uop;
    assign {
        ren2dis_uop,
        ren2dis_valid
    } = ren2dis;
    wire [(32 * DECODE_WIDTH)-1:0]               ren2dis_uop_diag_val;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   ren2dis_uop_dest_areg;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   ren2dis_uop_src1_areg;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   ren2dis_uop_src2_areg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0]    ren2dis_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0]    ren2dis_uop_src1_preg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0]    ren2dis_uop_src2_preg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0]    ren2dis_uop_old_dest_preg;
    wire [(FTQ_IDX_WIDTH * DECODE_WIDTH)-1:0]    ren2dis_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * DECODE_WIDTH)-1:0] ren2dis_uop_ftq_offset;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_ftq_is_last;
    wire [(INST_TYPE_WIDTH * DECODE_WIDTH)-1:0]  ren2dis_uop_type;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_dest_en;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_src1_en;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_src2_en;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_is_atomic;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_src1_busy;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_src2_busy;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_src1_is_pc;
    wire [DECODE_WIDTH-1:0]                      ren2dis_uop_src2_is_imm;
    wire [(3 * DECODE_WIDTH)-1:0]                ren2dis_uop_func3;
    wire [(7 * DECODE_WIDTH)-1:0]                ren2dis_uop_func7;
    wire [(32 * DECODE_WIDTH)-1:0]               ren2dis_uop_imm;
    wire [(BR_TAG_WIDTH * DECODE_WIDTH)-1:0]     ren2dis_uop_br_id;
    wire [(BR_MASK_WIDTH * DECODE_WIDTH)-1:0]    ren2dis_uop_br_mask;
    wire [(CSR_IDX_WIDTH * DECODE_WIDTH)-1:0]    ren2dis_uop_csr_idx;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        ren2dis_uop_expect_mask;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        ren2dis_uop_cplt_mask;
    wire [DECODE_WIDTH-1:0]                 ren2dis_uop_page_fault_inst;
    wire [DECODE_WIDTH-1:0]                 ren2dis_uop_illegal_inst;
    assign {
        ren2dis_uop_diag_val,
        ren2dis_uop_dest_areg,
        ren2dis_uop_src1_areg,
        ren2dis_uop_src2_areg,
        ren2dis_uop_dest_preg,
        ren2dis_uop_src1_preg,
        ren2dis_uop_src2_preg,
        ren2dis_uop_old_dest_preg,
        ren2dis_uop_ftq_idx,
        ren2dis_uop_ftq_offset,
        ren2dis_uop_ftq_is_last,
        ren2dis_uop_type,
        ren2dis_uop_dest_en,
        ren2dis_uop_src1_en,
        ren2dis_uop_src2_en,
        ren2dis_uop_is_atomic,
        ren2dis_uop_src1_busy,
        ren2dis_uop_src2_busy,
        ren2dis_uop_src1_is_pc,
        ren2dis_uop_src2_is_imm,
        ren2dis_uop_func3,
        ren2dis_uop_func7,
        ren2dis_uop_imm,
        ren2dis_uop_br_id,
        ren2dis_uop_br_mask,
        ren2dis_uop_csr_idx,
        ren2dis_uop_expect_mask,
        ren2dis_uop_cplt_mask,
        ren2dis_uop_page_fault_inst,
        ren2dis_uop_illegal_inst
    } = ren2dis_uop;

    wire                     rob2dis_ready;
    wire                     rob2dis_empty;
    wire                     rob2dis_stall;
    wire [ROB_IDX_WIDTH-1:0] rob2dis_enq_idx;
    wire                     rob2dis_rob_flag;
    assign {
        rob2dis_ready,
        rob2dis_empty,
        rob2dis_stall,
        rob2dis_enq_idx,
        rob2dis_rob_flag
    } = rob2dis;

    wire [(IQ_READY_NUM_WIDTH * IQ_NUM)-1:0] iss2dis_ready_num;
    assign iss2dis_ready_num = iss2dis;

    wire [STQ_IDX_WIDTH-1:0] lsu2dis_stq_tail;
    wire                     lsu2dis_stq_tail_flag;
    wire [W_STQ_COUNT-1:0]   lsu2dis_stq_free;
    wire [W_LDQ_COUNT-1:0]   lsu2dis_ldq_free;
    wire [(LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0]
        lsu2dis_ldq_alloc_idx;
    wire [MAX_LDQ_DISPATCH_WIDTH-1:0] lsu2dis_ldq_alloc_valid;
    assign {
        lsu2dis_stq_tail,
        lsu2dis_stq_tail_flag,
        lsu2dis_stq_free,
        lsu2dis_ldq_free,
        lsu2dis_ldq_alloc_idx,
        lsu2dis_ldq_alloc_valid
    } = lsu2dis;

    wire [LSU_LOAD_WB_WIDTH-1:0]                   prf_awake_wake_valid;
    wire [(PRF_IDX_WIDTH * LSU_LOAD_WB_WIDTH)-1:0] prf_awake_wake_preg;
    assign {
        prf_awake_wake_valid,
        prf_awake_wake_preg
    } = prf_awake;

    wire [MAX_WAKEUP_PORTS-1:0]                   iss_awake_wake_valid;
    wire [(PRF_IDX_WIDTH * MAX_WAKEUP_PORTS)-1:0] iss_awake_wake_preg;
    assign {
        iss_awake_wake_valid,
        iss_awake_wake_preg
    } = iss_awake;

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

    wire dis2ren_ready;
    assign dis2ren_ready = dis2ren;

    wire [(W_DisRobInst * DECODE_WIDTH)-1:0] dis2rob_uop;
    wire [DECODE_WIDTH-1:0]                  dis2rob_valid;
    wire [DECODE_WIDTH-1:0]                  dis2rob_dis_fire;
    assign {
        dis2rob_uop,
        dis2rob_valid,
        dis2rob_dis_fire
    } = dis2rob;
    wire [(32 * DECODE_WIDTH)-1:0]               dis2rob_uop_diag_val;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   dis2rob_uop_dest_areg;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   dis2rob_uop_src1_areg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0]    dis2rob_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0]    dis2rob_uop_old_dest_preg;
    wire [(FTQ_IDX_WIDTH * DECODE_WIDTH)-1:0]    dis2rob_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_ftq_offset;
    wire [DECODE_WIDTH-1:0]                      dis2rob_uop_ftq_is_last;
    wire [DECODE_WIDTH-1:0]                      dis2rob_uop_mispred;
    wire [DECODE_WIDTH-1:0]                      dis2rob_uop_br_taken;
    wire [(INST_TYPE_WIDTH * DECODE_WIDTH)-1:0]  dis2rob_uop_type;
    wire [DECODE_WIDTH-1:0]                      dis2rob_uop_dest_en;
    wire [DECODE_WIDTH-1:0]                      dis2rob_uop_is_atomic;
    wire [(3 * DECODE_WIDTH)-1:0]                dis2rob_uop_func3;
    wire [(7 * DECODE_WIDTH)-1:0]                dis2rob_uop_func7;
    wire [(32 * DECODE_WIDTH)-1:0]               dis2rob_uop_imm;
    wire [(BR_MASK_WIDTH * DECODE_WIDTH)-1:0]    dis2rob_uop_br_mask;
    wire [(ROB_IDX_WIDTH * DECODE_WIDTH)-1:0]    dis2rob_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * DECODE_WIDTH)-1:0]    dis2rob_uop_stq_idx;
    wire [DECODE_WIDTH-1:0]                      dis2rob_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * DECODE_WIDTH)-1:0]    dis2rob_uop_ldq_idx;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        dis2rob_uop_expect_mask;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        dis2rob_uop_cplt_mask;
    wire [DECODE_WIDTH-1:0]                 dis2rob_uop_rob_flag;
    wire [DECODE_WIDTH-1:0]                 dis2rob_uop_page_fault_inst;
    wire [DECODE_WIDTH-1:0]                 dis2rob_uop_illegal_inst;
    wire [DECODE_WIDTH-1:0]                 dis2rob_uop_flush_pipe;
    assign {
        dis2rob_uop_diag_val,
        dis2rob_uop_dest_areg,
        dis2rob_uop_src1_areg,
        dis2rob_uop_dest_preg,
        dis2rob_uop_old_dest_preg,
        dis2rob_uop_ftq_idx,
        dis2rob_uop_ftq_offset,
        dis2rob_uop_ftq_is_last,
        dis2rob_uop_mispred,
        dis2rob_uop_br_taken,
        dis2rob_uop_type,
        dis2rob_uop_dest_en,
        dis2rob_uop_is_atomic,
        dis2rob_uop_func3,
        dis2rob_uop_func7,
        dis2rob_uop_imm,
        dis2rob_uop_br_mask,
        dis2rob_uop_rob_idx,
        dis2rob_uop_stq_idx,
        dis2rob_uop_stq_flag,
        dis2rob_uop_ldq_idx,
        dis2rob_uop_expect_mask,
        dis2rob_uop_cplt_mask,
        dis2rob_uop_rob_flag,
        dis2rob_uop_page_fault_inst,
        dis2rob_uop_illegal_inst,
        dis2rob_uop_flush_pipe
    } = dis2rob_uop;

    wire [N_DisIssReq-1:0]                 dis2iss_req_valid;
    wire [(W_DisIssUop * N_DisIssReq)-1:0] dis2iss_req_uop;
    assign {
        dis2iss_req_valid,
        dis2iss_req_uop
    } = dis2iss;
    wire [(PRF_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_src1_preg;
    wire [(PRF_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_src2_preg;
    wire [(FTQ_IDX_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * N_DisIssReq)-1:0]
        dis2iss_req_uop_ftq_offset;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_is_atomic;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_dest_en;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_src1_en;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_src2_en;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_src1_busy;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_src2_busy;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_src1_is_pc;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_src2_is_imm;
    wire [(3 * N_DisIssReq)-1:0]              dis2iss_req_uop_func3;
    wire [(7 * N_DisIssReq)-1:0]              dis2iss_req_uop_func7;
    wire [(32 * N_DisIssReq)-1:0]             dis2iss_req_uop_imm;
    wire [(BR_TAG_WIDTH * N_DisIssReq)-1:0]   dis2iss_req_uop_br_id;
    wire [(BR_MASK_WIDTH * N_DisIssReq)-1:0]  dis2iss_req_uop_br_mask;
    wire [(CSR_IDX_WIDTH * N_DisIssReq)-1:0]  dis2iss_req_uop_csr_idx;
    wire [(ROB_IDX_WIDTH * N_DisIssReq)-1:0]  dis2iss_req_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * N_DisIssReq)-1:0]  dis2iss_req_uop_stq_idx;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * N_DisIssReq)-1:0]  dis2iss_req_uop_ldq_idx;
    wire [N_DisIssReq-1:0]                    dis2iss_req_uop_rob_flag;
    wire [(UOP_TYPE_WIDTH * N_DisIssReq)-1:0] dis2iss_req_uop_op;
    assign {
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
        dis2iss_req_uop_op
    } = dis2iss_req_uop;

    wire [MAX_STQ_DISPATCH_WIDTH-1:0]                   dis2lsu_alloc_req;
    wire [(BR_MASK_WIDTH * MAX_STQ_DISPATCH_WIDTH)-1:0] dis2lsu_br_mask;
    wire [(3 * MAX_STQ_DISPATCH_WIDTH)-1:0]             dis2lsu_func3;
    wire [(ROB_IDX_WIDTH * MAX_STQ_DISPATCH_WIDTH)-1:0] dis2lsu_rob_idx;
    wire [MAX_STQ_DISPATCH_WIDTH-1:0]                   dis2lsu_rob_flag;
    wire [MAX_STQ_DISPATCH_WIDTH-1:0]                   dis2lsu_stq_flag;
    wire [MAX_LDQ_DISPATCH_WIDTH-1:0]                   dis2lsu_ldq_alloc_req;
    wire [(LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0] dis2lsu_ldq_idx;
    wire [(BR_MASK_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0] dis2lsu_ldq_br_mask;
    wire [(ROB_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0] dis2lsu_ldq_rob_idx;
    wire [MAX_LDQ_DISPATCH_WIDTH-1:0]                   dis2lsu_ldq_rob_flag;
    assign {
        dis2lsu_alloc_req,
        dis2lsu_br_mask,
        dis2lsu_func3,
        dis2lsu_rob_idx,
        dis2lsu_rob_flag,
        dis2lsu_stq_flag,
        dis2lsu_ldq_alloc_req,
        dis2lsu_ldq_idx,
        dis2lsu_ldq_br_mask,
        dis2lsu_ldq_rob_idx,
        dis2lsu_ldq_rob_flag
    } = dis2lsu;

    assign pi = {
        ren2dis,
        rob2dis,
        iss2dis,
        lsu2dis,
        prf_awake,
        iss_awake,
        rob_bcast,
        dec_bcast
    };
    assign {
        dis2ren,
        dis2rob,
        dis2iss,
        dis2lsu
    } = po;

    dispatch_bsd_top #(
        .W_DisIn(W_DisIn),
        .W_DisOut(W_DisOut)
    ) u_dispatch_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
