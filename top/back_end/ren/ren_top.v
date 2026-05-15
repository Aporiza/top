// Source struct:
//   RenIn  = {dec2ren, dec_bcast, dis2ren, rob_bcast, rob_commit}
//   RenOut = {ren2dec, ren2dis}
// RAT, free-list and checkpoint registers remain internal to rename.

module ren_top #(
    parameter integer DECODE_WIDTH        = 8,
    parameter integer AREG_IDX_WIDTH      = 6,
    parameter integer PRF_IDX_WIDTH       = 9,
    parameter integer ROB_IDX_WIDTH       = 9,
    parameter integer STQ_IDX_WIDTH       = 6,
    parameter integer LDQ_IDX_WIDTH       = 6,
    parameter integer BR_TAG_WIDTH        = 6,
    parameter integer BR_MASK_WIDTH       = 64,
    parameter integer CSR_IDX_WIDTH       = 12,
    parameter integer FTQ_IDX_WIDTH       = 7,
    parameter integer FTQ_OFFSET_WIDTH    = 4,
    parameter integer INST_TYPE_WIDTH     = 5,
    parameter integer ROB_CPLT_MASK_WIDTH = 3,
    parameter integer COMMIT_WIDTH        = DECODE_WIDTH,
    parameter integer W_DecRenInst        =
        32 + (3 * AREG_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        INST_TYPE_WIDTH + 3 + 1 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH +
        BR_MASK_WIDTH + CSR_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) + 2,
    parameter integer W_DecRenIO       = DECODE_WIDTH * (W_DecRenInst + 1),
    parameter integer W_DecBroadcastIO =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_DisRenIO       = 1,
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_RobCommitInst =
        32 + AREG_IDX_WIDTH + (2 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + 2 + 1 + 7 + ROB_IDX_WIDTH + 1 +
        STQ_IDX_WIDTH + 1 + 4 + INST_TYPE_WIDTH + 1,
    parameter integer W_RobCommitIO = COMMIT_WIDTH * (1 + W_RobCommitInst),
    parameter integer W_RenDecIO    = 1,
    parameter integer W_RenDisInst  =
        32 + (3 * AREG_IDX_WIDTH) + (4 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + INST_TYPE_WIDTH + 3 + 1 + 2 + 2 + 3 + 7 +
        32 + BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH +
        (2 * ROB_CPLT_MASK_WIDTH) + 2,
    parameter integer W_RenDisIO = DECODE_WIDTH * (W_RenDisInst + 1),
    parameter integer W_RenIn    =
        W_DecRenIO + W_DecBroadcastIO + W_DisRenIO + W_RobBroadcastIO +
        W_RobCommitIO,
    parameter integer W_RenOut = W_RenDecIO + W_RenDisIO
) (
    input wire [W_DecRenIO-1:0]       dec2ren,
    input wire [W_DecBroadcastIO-1:0] dec_bcast,
    input wire [W_DisRenIO-1:0]       dis2ren,
    input wire [W_RobBroadcastIO-1:0] rob_bcast,
    input wire [W_RobCommitIO-1:0]    rob_commit,

    output wire [W_RenDecIO-1:0] ren2dec,
    output wire [W_RenDisIO-1:0] ren2dis
);

    wire [W_RenIn-1:0]  pi;
    wire [W_RenOut-1:0] po;

    // Field-level view of dec2ren, matching DecRenIO.
    wire [(W_DecRenInst * DECODE_WIDTH)-1:0] dec2ren_uop;
    wire [DECODE_WIDTH-1:0]                  dec2ren_valid;
    assign {
        dec2ren_uop,
        dec2ren_valid
    } = dec2ren;
    wire [(32 * DECODE_WIDTH)-1:0]               dec2ren_uop_diag_val;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   dec2ren_uop_dest_areg;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   dec2ren_uop_src1_areg;
    wire [(AREG_IDX_WIDTH * DECODE_WIDTH)-1:0]   dec2ren_uop_src2_areg;
    wire [(FTQ_IDX_WIDTH * DECODE_WIDTH)-1:0]    dec2ren_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * DECODE_WIDTH)-1:0] dec2ren_uop_ftq_offset;
    wire [DECODE_WIDTH-1:0]                      dec2ren_uop_ftq_is_last;
    wire [(INST_TYPE_WIDTH * DECODE_WIDTH)-1:0]  dec2ren_uop_type;
    wire [DECODE_WIDTH-1:0]                      dec2ren_uop_dest_en;
    wire [DECODE_WIDTH-1:0]                      dec2ren_uop_src1_en;
    wire [DECODE_WIDTH-1:0]                      dec2ren_uop_src2_en;
    wire [DECODE_WIDTH-1:0]                      dec2ren_uop_is_atomic;
    wire [DECODE_WIDTH-1:0]                      dec2ren_uop_src1_is_pc;
    wire [DECODE_WIDTH-1:0]                      dec2ren_uop_src2_is_imm;
    wire [(3 * DECODE_WIDTH)-1:0]                dec2ren_uop_func3;
    wire [(7 * DECODE_WIDTH)-1:0]                dec2ren_uop_func7;
    wire [(32 * DECODE_WIDTH)-1:0]               dec2ren_uop_imm;
    wire [(BR_TAG_WIDTH * DECODE_WIDTH)-1:0]     dec2ren_uop_br_id;
    wire [(BR_MASK_WIDTH * DECODE_WIDTH)-1:0]    dec2ren_uop_br_mask;
    wire [(CSR_IDX_WIDTH * DECODE_WIDTH)-1:0]    dec2ren_uop_csr_idx;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        dec2ren_uop_expect_mask;
    wire [(ROB_CPLT_MASK_WIDTH * DECODE_WIDTH)-1:0]
        dec2ren_uop_cplt_mask;
    wire [DECODE_WIDTH-1:0]                 dec2ren_uop_page_fault_inst;
    wire [DECODE_WIDTH-1:0]                 dec2ren_uop_illegal_inst;
    assign {
        dec2ren_uop_diag_val,
        dec2ren_uop_dest_areg,
        dec2ren_uop_src1_areg,
        dec2ren_uop_src2_areg,
        dec2ren_uop_ftq_idx,
        dec2ren_uop_ftq_offset,
        dec2ren_uop_ftq_is_last,
        dec2ren_uop_type,
        dec2ren_uop_dest_en,
        dec2ren_uop_src1_en,
        dec2ren_uop_src2_en,
        dec2ren_uop_is_atomic,
        dec2ren_uop_src1_is_pc,
        dec2ren_uop_src2_is_imm,
        dec2ren_uop_func3,
        dec2ren_uop_func7,
        dec2ren_uop_imm,
        dec2ren_uop_br_id,
        dec2ren_uop_br_mask,
        dec2ren_uop_csr_idx,
        dec2ren_uop_expect_mask,
        dec2ren_uop_cplt_mask,
        dec2ren_uop_page_fault_inst,
        dec2ren_uop_illegal_inst
    } = dec2ren_uop;

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

    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_valid;
    wire [(W_RobCommitInst * COMMIT_WIDTH)-1:0] rob_commit_entry_uop;
    assign {
        rob_commit_entry_valid,
        rob_commit_entry_uop
    } = rob_commit;
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
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_ftq_is_last;
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_mispred;
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_br_taken;
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_dest_en;
    wire [(7 * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_func7;
    wire [(ROB_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_rob_idx;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_rob_flag;
    wire [(STQ_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_stq_idx;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_stq_flag;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_page_fault_inst;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_page_fault_load;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_page_fault_store;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_illegal_inst;
    wire [(INST_TYPE_WIDTH * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_type;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_flush_pipe;
    assign {
        rob_commit_entry_uop_diag_val,
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
        rob_commit_entry_uop_flush_pipe
    } = rob_commit_entry_uop;

    wire ren2dec_ready;
    assign ren2dec_ready = ren2dec;

    wire [(W_RenDisInst * DECODE_WIDTH)-1:0] ren2dis_uop;
    wire [DECODE_WIDTH-1:0]                  ren2dis_valid;
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

    assign pi = {
        dec2ren,
        dec_bcast,
        dis2ren,
        rob_bcast,
        rob_commit
    };
    assign {
        ren2dec,
        ren2dis
    } = po;

    ren_bsd_top #(
        .W_RenIn(W_RenIn),
        .W_RenOut(W_RenOut)
    ) u_ren_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
