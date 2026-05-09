// Source struct:
//   PreIduQueueIn  = {front2pre, idu_consume, rob_bcast, rob_commit,
//                     idu_br_latch, ftq_prf_pc_req, ftq_rob_pc_req}
//   PreIduQueueOut = {pre2front, issue, ftq_prf_pc_resp, ftq_rob_pc_resp}
// Internal FTQ, instruction buffers and slice logic are not top-level ports.

module preiduqueue_top #(
    parameter integer FETCH_WIDTH = 16,
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
    parameter integer ROB_CPLT_MASK_WIDTH = 3,
    parameter integer BPU_SCL_META_NTABLE = 8,
    parameter integer BPU_SCL_META_IDX_BITS = 16,
    parameter integer tage_scl_meta_sum_t_BITS = 16,
    parameter integer BPU_LOOP_META_IDX_BITS = 16,
    parameter integer BPU_LOOP_META_TAG_BITS = 16,
    parameter integer TN_MAX = 4,
    parameter integer TAGE_IDX_WIDTH = 12,
    parameter integer TAGE_TAG_WIDTH = 8,
    parameter integer pcpn_t_BITS = 3,
    parameter integer FTQ_PRF_PC_PORT_NUM = 12,
    parameter integer FTQ_ROB_PC_PORT_NUM = 1,
    parameter integer W_DebugMeta = 32 + 32 + 8 + 1 + 64,
    parameter integer W_TmaMeta = 4,
    parameter integer W_InstructionBufferEntry =
        1 + 32 + 32 + 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1,
    parameter integer W_FrontPreIO =
        (32 * FETCH_WIDTH) + (32 * FETCH_WIDTH) + FETCH_WIDTH + 1 +
        FETCH_WIDTH + FETCH_WIDTH + (pcpn_t_BITS * FETCH_WIDTH) +
        (pcpn_t_BITS * FETCH_WIDTH) + (32 * FETCH_WIDTH) +
        (TAGE_IDX_WIDTH * FETCH_WIDTH * TN_MAX) +
        (TAGE_TAG_WIDTH * FETCH_WIDTH * TN_MAX) + FETCH_WIDTH + FETCH_WIDTH +
        (tage_scl_meta_sum_t_BITS * FETCH_WIDTH) +
        (BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS * FETCH_WIDTH) +
        FETCH_WIDTH + FETCH_WIDTH + FETCH_WIDTH +
        (BPU_LOOP_META_IDX_BITS * FETCH_WIDTH) +
        (BPU_LOOP_META_TAG_BITS * FETCH_WIDTH) + FETCH_WIDTH,
    parameter integer W_IduConsumeIO = DECODE_WIDTH,
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_RobCommitInst =
        32 + AREG_IDX_WIDTH + (2 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + 2 + 1 + 7 + ROB_IDX_WIDTH + 1 +
        STQ_IDX_WIDTH + 1 + 4 + INST_TYPE_WIDTH + W_TmaMeta + W_DebugMeta + 1,
    parameter integer W_RobCommitIO = COMMIT_WIDTH * (1 + W_RobCommitInst),
    parameter integer W_ExuIdIO =
        1 + 32 + ROB_IDX_WIDTH + BR_TAG_WIDTH + FTQ_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_FtqPcReadReq = 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH,
    parameter integer W_FtqPcReadResp = 1 + 1 + 32 + 1 + 32,
    parameter integer W_FtqPrfPcReqIO = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqPrfPcRespIO = FTQ_PRF_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_FtqRobPcReqIO = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadReq,
    parameter integer W_FtqRobPcRespIO = FTQ_ROB_PC_PORT_NUM * W_FtqPcReadResp,
    parameter integer W_PreFrontIO = FETCH_WIDTH + 1,
    parameter integer W_PreIssueIO = W_InstructionBufferEntry * DECODE_WIDTH,
    parameter integer W_PreIduQueueIn =
        W_FrontPreIO + W_IduConsumeIO + W_RobBroadcastIO + W_RobCommitIO +
        W_ExuIdIO + W_FtqPrfPcReqIO + W_FtqRobPcReqIO,
    parameter integer W_PreIduQueueOut =
        W_PreFrontIO + W_PreIssueIO + W_FtqPrfPcRespIO + W_FtqRobPcRespIO
) (
    input  wire [W_FrontPreIO-1:0]      front2pre,
    input  wire [W_IduConsumeIO-1:0]    idu_consume,
    input  wire [W_RobBroadcastIO-1:0]  rob_bcast,
    input  wire [W_RobCommitIO-1:0]     rob_commit,
    input  wire [W_ExuIdIO-1:0]         idu_br_latch,
    input  wire [W_FtqPrfPcReqIO-1:0]   ftq_prf_pc_req,
    input  wire [W_FtqRobPcReqIO-1:0]   ftq_rob_pc_req,

    output wire [W_PreFrontIO-1:0]      pre2front,
    output wire [W_PreIssueIO-1:0]      pre_issue,
    output wire [W_FtqPrfPcRespIO-1:0]  ftq_prf_pc_resp,
    output wire [W_FtqRobPcRespIO-1:0]  ftq_rob_pc_resp,

    output wire [FETCH_WIDTH-1:0]       pre2front_fire,
    output wire                         pre2front_ready
);

    wire [W_PreIduQueueIn-1:0]  pi;
    wire [W_PreIduQueueOut-1:0] po;

    wire [(32 * FETCH_WIDTH)-1:0] front2pre_inst;
    wire [(32 * FETCH_WIDTH)-1:0] front2pre_pc;
    wire [FETCH_WIDTH-1:0] front2pre_valid;
    wire front2pre_front_stall;
    wire [FETCH_WIDTH-1:0] front2pre_predict_dir;
    wire [FETCH_WIDTH-1:0] front2pre_alt_pred;
    wire [(pcpn_t_BITS * FETCH_WIDTH)-1:0] front2pre_altpcpn;
    wire [(pcpn_t_BITS * FETCH_WIDTH)-1:0] front2pre_pcpn;
    wire [(32 * FETCH_WIDTH)-1:0] front2pre_predict_next_fetch_address;
    wire [(TAGE_IDX_WIDTH * FETCH_WIDTH * TN_MAX)-1:0] front2pre_tage_idx;
    wire [(TAGE_TAG_WIDTH * FETCH_WIDTH * TN_MAX)-1:0] front2pre_tage_tag;
    wire [FETCH_WIDTH-1:0] front2pre_sc_used;
    wire [FETCH_WIDTH-1:0] front2pre_sc_pred;
    wire [(tage_scl_meta_sum_t_BITS * FETCH_WIDTH)-1:0] front2pre_sc_sum;
    wire [(BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS * FETCH_WIDTH)-1:0]
        front2pre_sc_idx;
    wire [FETCH_WIDTH-1:0] front2pre_loop_used;
    wire [FETCH_WIDTH-1:0] front2pre_loop_hit;
    wire [FETCH_WIDTH-1:0] front2pre_loop_pred;
    wire [(BPU_LOOP_META_IDX_BITS * FETCH_WIDTH)-1:0] front2pre_loop_idx;
    wire [(BPU_LOOP_META_TAG_BITS * FETCH_WIDTH)-1:0] front2pre_loop_tag;
    wire [FETCH_WIDTH-1:0] front2pre_page_fault_inst;
    assign {front2pre_inst, front2pre_pc, front2pre_valid,
            front2pre_front_stall, front2pre_predict_dir,
            front2pre_alt_pred, front2pre_altpcpn, front2pre_pcpn,
            front2pre_predict_next_fetch_address, front2pre_tage_idx,
            front2pre_tage_tag, front2pre_sc_used, front2pre_sc_pred,
            front2pre_sc_sum, front2pre_sc_idx, front2pre_loop_used,
            front2pre_loop_hit, front2pre_loop_pred, front2pre_loop_idx,
            front2pre_loop_tag, front2pre_page_fault_inst} = front2pre;

    wire [DECODE_WIDTH-1:0] idu_consume_fire;
    assign idu_consume_fire = idu_consume;

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

    wire idu_br_latch_mispred;
    wire [31:0] idu_br_latch_redirect_pc;
    wire [ROB_IDX_WIDTH-1:0] idu_br_latch_redirect_rob_idx;
    wire [BR_TAG_WIDTH-1:0] idu_br_latch_br_id;
    wire [FTQ_IDX_WIDTH-1:0] idu_br_latch_ftq_idx;
    wire [BR_MASK_WIDTH-1:0] idu_br_latch_clear_mask;
    assign {idu_br_latch_mispred, idu_br_latch_redirect_pc,
            idu_br_latch_redirect_rob_idx, idu_br_latch_br_id,
            idu_br_latch_ftq_idx, idu_br_latch_clear_mask} = idu_br_latch;

    wire [FTQ_PRF_PC_PORT_NUM-1:0] ftq_prf_pc_req_valid;
    wire [(FTQ_IDX_WIDTH * FTQ_PRF_PC_PORT_NUM)-1:0]
        ftq_prf_pc_req_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * FTQ_PRF_PC_PORT_NUM)-1:0]
        ftq_prf_pc_req_ftq_offset;
    assign {ftq_prf_pc_req_valid, ftq_prf_pc_req_ftq_idx,
            ftq_prf_pc_req_ftq_offset} = ftq_prf_pc_req;

    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_req_valid;
    wire [(FTQ_IDX_WIDTH * FTQ_ROB_PC_PORT_NUM)-1:0]
        ftq_rob_pc_req_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * FTQ_ROB_PC_PORT_NUM)-1:0]
        ftq_rob_pc_req_ftq_offset;
    assign {ftq_rob_pc_req_valid, ftq_rob_pc_req_ftq_idx,
            ftq_rob_pc_req_ftq_offset} = ftq_rob_pc_req;

    assign pi =
        {front2pre, idu_consume, rob_bcast, rob_commit, idu_br_latch,
         ftq_prf_pc_req, ftq_rob_pc_req};
    assign {pre2front, pre_issue, ftq_prf_pc_resp, ftq_rob_pc_resp} = po;

    assign {pre2front_fire, pre2front_ready} = pre2front;

    wire [(W_InstructionBufferEntry * DECODE_WIDTH)-1:0] pre_issue_entries;
    assign pre_issue_entries = pre_issue;

    wire [FTQ_PRF_PC_PORT_NUM-1:0] ftq_prf_pc_resp_valid;
    wire [FTQ_PRF_PC_PORT_NUM-1:0] ftq_prf_pc_resp_entry_valid;
    wire [(32 * FTQ_PRF_PC_PORT_NUM)-1:0] ftq_prf_pc_resp_pc;
    wire [FTQ_PRF_PC_PORT_NUM-1:0] ftq_prf_pc_resp_pred_taken;
    wire [(32 * FTQ_PRF_PC_PORT_NUM)-1:0] ftq_prf_pc_resp_next_pc;
    assign {ftq_prf_pc_resp_valid, ftq_prf_pc_resp_entry_valid,
            ftq_prf_pc_resp_pc, ftq_prf_pc_resp_pred_taken,
            ftq_prf_pc_resp_next_pc} = ftq_prf_pc_resp;

    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_resp_valid;
    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_resp_entry_valid;
    wire [(32 * FTQ_ROB_PC_PORT_NUM)-1:0] ftq_rob_pc_resp_pc;
    wire [FTQ_ROB_PC_PORT_NUM-1:0] ftq_rob_pc_resp_pred_taken;
    wire [(32 * FTQ_ROB_PC_PORT_NUM)-1:0] ftq_rob_pc_resp_next_pc;
    assign {ftq_rob_pc_resp_valid, ftq_rob_pc_resp_entry_valid,
            ftq_rob_pc_resp_pc, ftq_rob_pc_resp_pred_taken,
            ftq_rob_pc_resp_next_pc} = ftq_rob_pc_resp;

    preiduqueue_bsd_top #(
        .W_PreIduQueueIn(W_PreIduQueueIn),
        .W_PreIduQueueOut(W_PreIduQueueOut)
    ) u_preiduqueue_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
