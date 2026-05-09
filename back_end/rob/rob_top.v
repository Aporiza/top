// Source struct:
//   RobIn  = {dis2rob, csr2rob, lsu2rob, dec_bcast, exu2rob, ftq_pc_resp,
//             front_stall}
//   RobOut = {rob2dis, rob2csr, rob_commit, rob_bcast, ftq_pc_req}
// ROB entries, head/tail pointers and commit row storage stay internal.

module rob_top #(
    parameter integer DECODE_WIDTH = 8,
    parameter integer COMMIT_WIDTH = DECODE_WIDTH,
    parameter integer AREG_IDX_WIDTH = 6,
    parameter integer PRF_IDX_WIDTH = 11,
    parameter integer ROB_IDX_WIDTH = 11,
    parameter integer STQ_IDX_WIDTH = 9,
    parameter integer LDQ_IDX_WIDTH = 9,
    parameter integer BR_TAG_WIDTH = 6,
    parameter integer BR_MASK_WIDTH = 64,
    parameter integer CSR_IDX_WIDTH = 12,
    parameter integer FTQ_IDX_WIDTH = 8,
    parameter integer FTQ_OFFSET_WIDTH = 4,
    parameter integer INST_TYPE_WIDTH = 5,
    parameter integer UOP_TYPE_WIDTH = 5,
    parameter integer ROB_CPLT_MASK_WIDTH = 3,
    parameter integer ISSUE_WIDTH = 24,
    parameter integer ROB_NUM = 2048,
    parameter integer FTQ_ROB_PC_PORT_NUM = 1,
    parameter integer W_DebugMeta = 32 + 32 + 8 + 1 + 64,
    parameter integer W_TmaMeta = 4,
    parameter integer W_InstInfo =
        32 + (3 * AREG_IDX_WIDTH) + (4 * PRF_IDX_WIDTH) +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 2 + 3 + 2 + 2 +
        3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH +
        ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 1 + 6 + INST_TYPE_WIDTH +
        W_TmaMeta + W_DebugMeta,
    parameter integer W_InstEntry = 1 + W_InstInfo,
    parameter integer W_DisRobInst =
        32 + (2 * AREG_IDX_WIDTH) + (2 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + 2 + INST_TYPE_WIDTH + 1 + 1 + 3 + 7 + 32 +
        BR_MASK_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 1 + 3 + W_TmaMeta + W_DebugMeta,
    parameter integer W_DisRobIO = DECODE_WIDTH * (W_DisRobInst + 1 + 1),
    parameter integer W_CsrRobIO = 1,
    parameter integer W_LsuRobIO = ROB_NUM + 1,
    parameter integer W_DecBroadcastIO =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_ExuRobUop =
        32 + 32 + ROB_IDX_WIDTH + 2 + 3 + UOP_TYPE_WIDTH + W_DebugMeta + 1,
    parameter integer W_ExuRobIO = ISSUE_WIDTH * (1 + W_ExuRobUop),
    parameter integer W_FtqPcReadReq = 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH,
    parameter integer W_FtqPcReadResp = 1 + 1 + 32 + 1 + 32,
    parameter integer W_FtqRobPcReqIO = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqRobPcRespIO = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_RobDisIO = 3 + 3 + ROB_IDX_WIDTH + 1,
    parameter integer W_RobCsrIO = 2,
    parameter integer W_RobCommitInst =
        32 + AREG_IDX_WIDTH + (2 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + 2 + 1 + 7 + ROB_IDX_WIDTH + 1 +
        STQ_IDX_WIDTH + 1 + 4 + INST_TYPE_WIDTH + W_TmaMeta + W_DebugMeta + 1,
    parameter integer W_RobCommitIO = COMMIT_WIDTH * (1 + W_RobCommitInst),
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_RobIn =
        W_DisRobIO + W_CsrRobIO + W_LsuRobIO + W_DecBroadcastIO + W_ExuRobIO +
        W_FtqRobPcRespIO + 1,
    parameter integer W_RobOut =
        W_RobDisIO + W_RobCsrIO + W_RobCommitIO + W_RobBroadcastIO +
        W_FtqRobPcReqIO
) (
    input  wire [W_DisRobIO-1:0]       dis2rob,
    input  wire [W_CsrRobIO-1:0]       csr2rob,
    input  wire [W_LsuRobIO-1:0]       lsu2rob,
    input  wire [W_DecBroadcastIO-1:0] dec_bcast,
    input  wire [W_ExuRobIO-1:0]       exu2rob,
    input  wire [W_FtqRobPcRespIO-1:0] ftq_rob_pc_resp,
    input  wire                        front_stall,

    output wire [W_RobDisIO-1:0]       rob2dis,
    output wire [W_RobCsrIO-1:0]       rob2csr,
    output wire [W_RobCommitIO-1:0]    rob_commit,
    output wire [W_RobBroadcastIO-1:0] rob_bcast,
    output wire [W_FtqRobPcReqIO-1:0]  ftq_rob_pc_req,

    output wire                        rob_bcast_flush,
    output wire                        rob_bcast_mret,
    output wire                        rob_bcast_sret,
    output wire                        rob_bcast_ecall,
    output wire                        rob_bcast_exception,
    output wire                        rob_bcast_fence,
    output wire                        rob_bcast_fence_i,
    output wire                        rob_bcast_page_fault_inst,
    output wire                        rob_bcast_page_fault_load,
    output wire                        rob_bcast_page_fault_store,
    output wire                        rob_bcast_illegal_inst,
    output wire                        rob_bcast_interrupt,
    output wire [31:0]                 rob_bcast_trap_val,
    output wire [31:0]                 rob_bcast_pc,
    output wire [ROB_IDX_WIDTH-1:0]    rob_bcast_head_rob_idx,
    output wire                        rob_bcast_head_valid,
    output wire [ROB_IDX_WIDTH-1:0]    rob_bcast_head_incomplete_rob_idx,
    output wire                        rob_bcast_head_incomplete_valid,

    output wire [(W_InstEntry * COMMIT_WIDTH)-1:0]
                                       rob_commit_entry_for_backout
);

    wire [W_RobIn-1:0]  pi;
    wire [W_RobOut-1:0] po;

    wire [(W_DisRobInst * DECODE_WIDTH)-1:0] dis2rob_uop;
    wire [DECODE_WIDTH-1:0] dis2rob_valid;
    wire [DECODE_WIDTH-1:0] dis2rob_dis_fire;
    assign {dis2rob_uop, dis2rob_valid, dis2rob_dis_fire} = dis2rob;
    wire [(32 * DECODE_WIDTH)-1:0] dis2rob_uop_diag_val;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_dest_areg;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_src1_areg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_old_dest_preg;
    wire [(FTQ_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_ftq_offset;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_ftq_is_last;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_mispred;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_br_taken;
    wire [(INST_TYPE_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_type;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_dest_en;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_is_atomic;
    wire [(3 * DECODE_WIDTH)-1:0] dis2rob_uop_func3;
    wire [(7 * DECODE_WIDTH)-1:0] dis2rob_uop_func7;
    wire [(32 * DECODE_WIDTH)-1:0] dis2rob_uop_imm;
    wire [(BR_MASK_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_br_mask;
    wire [(ROB_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_stq_idx;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * DECODE_WIDTH)-1:0] dis2rob_uop_ldq_idx;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        dis2rob_uop_expect_mask;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        dis2rob_uop_cplt_mask;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_rob_flag;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_page_fault_inst;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_illegal_inst;
    wire [DECODE_WIDTH-1:0] dis2rob_uop_flush_pipe;
    wire [(W_TmaMeta * DECODE_WIDTH)-1:0] dis2rob_uop_tma;
    wire [(W_DebugMeta * DECODE_WIDTH)-1:0] dis2rob_uop_dbg;
    assign {dis2rob_uop_diag_val, dis2rob_uop_dest_areg,
            dis2rob_uop_src1_areg, dis2rob_uop_dest_preg,
            dis2rob_uop_old_dest_preg, dis2rob_uop_ftq_idx,
            dis2rob_uop_ftq_offset, dis2rob_uop_ftq_is_last,
            dis2rob_uop_mispred, dis2rob_uop_br_taken,
            dis2rob_uop_type, dis2rob_uop_dest_en,
            dis2rob_uop_is_atomic, dis2rob_uop_func3,
            dis2rob_uop_func7, dis2rob_uop_imm, dis2rob_uop_br_mask,
            dis2rob_uop_rob_idx, dis2rob_uop_stq_idx,
            dis2rob_uop_stq_flag, dis2rob_uop_ldq_idx,
            dis2rob_uop_expect_mask, dis2rob_uop_cplt_mask,
            dis2rob_uop_rob_flag, dis2rob_uop_page_fault_inst,
            dis2rob_uop_illegal_inst, dis2rob_uop_flush_pipe,
            dis2rob_uop_tma, dis2rob_uop_dbg} = dis2rob_uop;

    wire csr2rob_interrupt_req;
    assign csr2rob_interrupt_req = csr2rob;

    wire [ROB_NUM-1:0] lsu2rob_tma_miss_mask;
    wire lsu2rob_committed_store_pending;
    assign {lsu2rob_tma_miss_mask,
            lsu2rob_committed_store_pending} = lsu2rob;

    wire dec_bcast_mispred;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_br_mask;
    wire [BR_TAG_WIDTH-1:0] dec_bcast_br_id;
    wire [ROB_IDX_WIDTH-1:0] dec_bcast_redirect_rob_idx;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_clear_mask;
    assign {dec_bcast_mispred, dec_bcast_br_mask, dec_bcast_br_id,
            dec_bcast_redirect_rob_idx, dec_bcast_clear_mask} = dec_bcast;

    wire [ISSUE_WIDTH-1:0] exu2rob_entry_valid;
    wire [(W_ExuRobUop * ISSUE_WIDTH)-1:0] exu2rob_entry_uop;
    assign {exu2rob_entry_valid, exu2rob_entry_uop} = exu2rob;
    wire [(32 * ISSUE_WIDTH)-1:0] exu2rob_entry_uop_diag_val;
    wire [(32 * ISSUE_WIDTH)-1:0] exu2rob_entry_uop_result;
    wire [(ROB_IDX_WIDTH * ISSUE_WIDTH)-1:0] exu2rob_entry_uop_rob_idx;
    wire [ISSUE_WIDTH-1:0] exu2rob_entry_uop_mispred;
    wire [ISSUE_WIDTH-1:0] exu2rob_entry_uop_br_taken;
    wire [ISSUE_WIDTH-1:0] exu2rob_entry_uop_page_fault_inst;
    wire [ISSUE_WIDTH-1:0] exu2rob_entry_uop_page_fault_load;
    wire [ISSUE_WIDTH-1:0] exu2rob_entry_uop_page_fault_store;
    wire [(UOP_TYPE_WIDTH * ISSUE_WIDTH)-1:0] exu2rob_entry_uop_op;
    wire [(W_DebugMeta * ISSUE_WIDTH)-1:0] exu2rob_entry_uop_dbg;
    wire [ISSUE_WIDTH-1:0] exu2rob_entry_uop_flush_pipe;
    assign {exu2rob_entry_uop_diag_val, exu2rob_entry_uop_result,
            exu2rob_entry_uop_rob_idx, exu2rob_entry_uop_mispred,
            exu2rob_entry_uop_br_taken,
            exu2rob_entry_uop_page_fault_inst,
            exu2rob_entry_uop_page_fault_load,
            exu2rob_entry_uop_page_fault_store, exu2rob_entry_uop_op,
            exu2rob_entry_uop_dbg,
            exu2rob_entry_uop_flush_pipe} = exu2rob_entry_uop;

    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_resp_valid;
    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_resp_entry_valid;
    wire [(32 * FTQ_ROB_PC_PORT_NUM)-1:0] ftq_rob_pc_resp_pc;
    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_resp_pred_taken;
    wire [(32 * FTQ_ROB_PC_PORT_NUM)-1:0] ftq_rob_pc_resp_next_pc;
    assign {ftq_rob_pc_resp_valid, ftq_rob_pc_resp_entry_valid,
            ftq_rob_pc_resp_pc, ftq_rob_pc_resp_pred_taken,
            ftq_rob_pc_resp_next_pc} = ftq_rob_pc_resp;

    assign pi =
        {dis2rob, csr2rob, lsu2rob, dec_bcast, exu2rob, ftq_rob_pc_resp,
         front_stall};
    assign {rob2dis, rob2csr, rob_commit, rob_bcast, ftq_rob_pc_req} = po;

    wire rob2dis_tma_head_is_memory;
    wire rob2dis_tma_head_is_miss;
    wire rob2dis_tma_head_not_ready;
    wire rob2dis_ready;
    wire rob2dis_empty;
    wire rob2dis_stall;
    wire [ROB_IDX_WIDTH-1:0] rob2dis_enq_idx;
    wire rob2dis_rob_flag;
    assign {rob2dis_tma_head_is_memory, rob2dis_tma_head_is_miss,
            rob2dis_tma_head_not_ready, rob2dis_ready, rob2dis_empty,
            rob2dis_stall, rob2dis_enq_idx, rob2dis_rob_flag} = rob2dis;

    wire rob2csr_interrupt_resp;
    wire rob2csr_commit;
    assign {rob2csr_interrupt_resp, rob2csr_commit} = rob2csr;

    wire [COMMIT_WIDTH-1:0] rob_commit_entry_valid;
    wire [(W_RobCommitInst * COMMIT_WIDTH)-1:0] rob_commit_entry_uop;
    assign {rob_commit_entry_valid, rob_commit_entry_uop} = rob_commit;
    wire [(32 * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_diag_val;
    wire [(AREG_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_dest_areg;
    wire [(PRF_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_old_dest_preg;
    wire [(FTQ_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_ftq_offset;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_ftq_is_last;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_mispred;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_br_taken;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_dest_en;
    wire [(7 * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_func7;
    wire [(ROB_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_rob_idx;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_rob_flag;
    wire [(STQ_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_stq_idx;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_stq_flag;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_page_fault_inst;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_page_fault_load;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_page_fault_store;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_illegal_inst;
    wire [(INST_TYPE_WIDTH * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_type;
    wire [(W_TmaMeta * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_tma;
    wire [(W_DebugMeta * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_dbg;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_flush_pipe;
    assign {rob_commit_entry_uop_diag_val,
            rob_commit_entry_uop_dest_areg,
            rob_commit_entry_uop_dest_preg,
            rob_commit_entry_uop_old_dest_preg,
            rob_commit_entry_uop_ftq_idx,
            rob_commit_entry_uop_ftq_offset,
            rob_commit_entry_uop_ftq_is_last,
            rob_commit_entry_uop_mispred,
            rob_commit_entry_uop_br_taken,
            rob_commit_entry_uop_dest_en,
            rob_commit_entry_uop_func7,
            rob_commit_entry_uop_rob_idx,
            rob_commit_entry_uop_rob_flag,
            rob_commit_entry_uop_stq_idx,
            rob_commit_entry_uop_stq_flag,
            rob_commit_entry_uop_page_fault_inst,
            rob_commit_entry_uop_page_fault_load,
            rob_commit_entry_uop_page_fault_store,
            rob_commit_entry_uop_illegal_inst,
            rob_commit_entry_uop_type,
            rob_commit_entry_uop_tma,
            rob_commit_entry_uop_dbg,
            rob_commit_entry_uop_flush_pipe} = rob_commit_entry_uop;

    assign {rob_bcast_flush, rob_bcast_mret, rob_bcast_sret,
            rob_bcast_ecall, rob_bcast_exception, rob_bcast_fence,
            rob_bcast_fence_i, rob_bcast_page_fault_inst,
            rob_bcast_page_fault_load, rob_bcast_page_fault_store,
            rob_bcast_illegal_inst, rob_bcast_interrupt,
            rob_bcast_trap_val, rob_bcast_pc, rob_bcast_head_rob_idx,
            rob_bcast_head_valid, rob_bcast_head_incomplete_rob_idx,
            rob_bcast_head_incomplete_valid} = rob_bcast;

    // The exact RobCommitInst::to_inst_entry(valid) conversion is filled by
    // the ROB slice.  These named outputs make the source explicit meanwhile.
    assign rob_commit_entry_for_backout =
        {(W_InstEntry * COMMIT_WIDTH){1'b0}};

    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_req_valid;
    wire [(FTQ_IDX_WIDTH * FTQ_ROB_PC_PORT_NUM)-1:0]
        ftq_rob_pc_req_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * FTQ_ROB_PC_PORT_NUM)-1:0]
        ftq_rob_pc_req_ftq_offset;
    assign {ftq_rob_pc_req_valid, ftq_rob_pc_req_ftq_idx,
            ftq_rob_pc_req_ftq_offset} = ftq_rob_pc_req;

    rob_bsd_top #(
        .W_RobIn(W_RobIn),
        .W_RobOut(W_RobOut)
    ) u_rob_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
