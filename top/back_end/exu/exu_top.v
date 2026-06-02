// simulator-main 默认配置 EXU 边界的 BSD 封装。
//
// Exu.h 结构体边界：
//   ExuIn  = {prf2exe, dec_bcast, rob_bcast, csr2exe, lsu2exe,
//             csr_status, fu2exu}
//   ExuOut = {exe2prf, exe2iss, exe2csr, exe2lsu, exu2id, exu2rob,
//             exu2fu}
//
// BSD 接口规范：
//   u_exu_bsd_top(clk, rst_n, pi, po)
//   pi = {prf2exe, dec_bcast, rob_bcast, csr2exe, lsu2exe, csr_status,
//         fu2exu}
//   po = {exe2prf, exe2iss, exe2csr, exe2lsu, exu2id, exu2rob, exu2fu}
//
// fu2exu/exu2fu 是 Exu.h 里显式写进 ExuIn/ExuOut 的 FU 边界。
// BackTop.cpp 没有把它们暴露成后端顶层端口，但 EXU BSD 的 pi/po 必须按
// Exu.h 保留这两个字段，避免组员按源码生成的接口和 wrapper 位宽不一致。
// main 版 EXU 重新接入 csr_status，CSR 读写和异常相关逻辑都在 EXU 内部使用。


module exu_top #(
    parameter integer ISSUE_WIDTH         = 22,
    parameter integer TOTAL_FU_COUNT      = 28,
    parameter integer PRF_IDX_WIDTH       = 7,
    parameter integer ROB_IDX_WIDTH       = 7,
    parameter integer STQ_IDX_WIDTH       = 6,
    parameter integer LDQ_IDX_WIDTH       = 6,
    parameter integer BR_TAG_WIDTH        = 6,
    parameter integer BR_MASK_WIDTH       = 64,
    parameter integer CSR_IDX_WIDTH       = 12,
    parameter integer FTQ_IDX_WIDTH       = 6,
    parameter integer FTQ_OFFSET_WIDTH    = 4,
    parameter integer UOP_TYPE_WIDTH      = 5,
    parameter integer MAX_UOP_TYPE        = 18,
    parameter integer LSU_LOAD_WB_WIDTH   = 4,
    parameter integer LSU_STA_COUNT       = 4,
    parameter integer LSU_AGU_COUNT       = 8,
    parameter integer LSU_SDU_COUNT       = 4,
    parameter integer W_PrfExeUop         =
        32 + 1 + 1 + 32 + (3 * PRF_IDX_WIDTH) + 64 +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 3 + 2 + 3 + 7 + 32 +
        BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExuInst           =
        W_PrfExeUop + 32 + 32 + 1 + 1 + 1 + 1 + 1,
    parameter integer W_FuInput            =
        1 + 1 + 1 + BR_MASK_WIDTH + BR_MASK_WIDTH + W_ExuInst,
    parameter integer W_FuOutput           = 1 + 1 + W_ExuInst,
    parameter integer W_Exu2FuIO           = TOTAL_FU_COUNT * W_FuInput,
    parameter integer W_Fu2ExuIO           = TOTAL_FU_COUNT * W_FuOutput,
    parameter integer W_PrfExeIO          = ISSUE_WIDTH * (1 + W_PrfExeUop),
    parameter integer W_DecBroadcastIO    =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_RobBroadcastIO    =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_CsrExeIO          = 32,
    parameter integer W_LsuExeRespUop     =
        32 + 32 + PRF_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1 +
        2 + UOP_TYPE_WIDTH + 1,
    parameter integer W_LsuExeIO          =
        (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT) * (1 + W_LsuExeRespUop),
    parameter integer W_ExePrfWbUop       =
        PRF_IDX_WIDTH + 32 + BR_MASK_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExePrfEntry       = 1 + W_ExePrfWbUop,
    parameter integer W_ExePrfIO          =
        (ISSUE_WIDTH + TOTAL_FU_COUNT) * W_ExePrfEntry,
    parameter integer W_ExeIssIO          = ISSUE_WIDTH * MAX_UOP_TYPE,
    parameter integer W_ExeCsrIO          = 1 + 1 + 12 + 32 + 32,
    parameter integer W_ExeLsuReqUop      =
        32 + PRF_IDX_WIDTH + 3 + 7 + 1 + BR_MASK_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExeLsuIO          =
        (LSU_AGU_COUNT + LSU_SDU_COUNT) * (1 + W_ExeLsuReqUop),
    parameter integer W_ExuIdIO           =
        1 + 32 + ROB_IDX_WIDTH + BR_TAG_WIDTH + FTQ_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_ExuRobUop         =
        32 + 32 + ROB_IDX_WIDTH + 2 + 3 + UOP_TYPE_WIDTH + 1,
    parameter integer W_ExuRobIO          = ISSUE_WIDTH * (1 + W_ExuRobUop),
    parameter integer W_CsrStatusIO       = 32 + 32 + 32 + 2,
    parameter integer W_ExuIn             =
        W_PrfExeIO + W_DecBroadcastIO + W_RobBroadcastIO + W_CsrExeIO +
        W_LsuExeIO + W_CsrStatusIO + W_Fu2ExuIO,
    parameter integer W_ExuOut            =
        W_ExePrfIO + W_ExeIssIO + W_ExeCsrIO + W_ExeLsuIO + W_ExuIdIO +
        W_ExuRobIO + W_Exu2FuIO
) (
    input wire clk,
    input wire rst_n,

    input wire [W_PrfExeIO-1:0]       prf2exe,
    input wire [W_DecBroadcastIO-1:0] dec_bcast,
    input wire [W_RobBroadcastIO-1:0] rob_bcast,
    input wire [W_CsrExeIO-1:0]       csr2exe,
    input wire [W_LsuExeIO-1:0]       lsu2exe,
    input wire [W_CsrStatusIO-1:0]    csr_status,
    input wire [W_Fu2ExuIO-1:0]       fu2exu,

    output wire [W_ExePrfIO-1:0] exe2prf,
    output wire [W_ExeIssIO-1:0] exe2iss,
    output wire [W_ExeCsrIO-1:0] exe2csr,
    output wire [W_ExeLsuIO-1:0] exe2lsu,
    output wire [W_ExuIdIO-1:0]  exu2id,
    output wire [W_ExuRobIO-1:0] exu2rob,
    output wire [W_Exu2FuIO-1:0] exu2fu
);

    wire [W_ExuIn-1:0]  pi;
    wire [W_ExuOut-1:0] po;

    // prf2exe 的字段级视图，对齐 PrfExeIO 的字段顺序。
    wire [ISSUE_WIDTH-1:0]                 prf2exe_iss_entry_valid;
    wire [(W_PrfExeUop * ISSUE_WIDTH)-1:0] prf2exe_iss_entry_uop;
    assign {
        prf2exe_iss_entry_valid,
        prf2exe_iss_entry_uop
    } = prf2exe;
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
    } = prf2exe_iss_entry_uop;

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

    wire [31:0] csr2exe_rdata;
    assign csr2exe_rdata = csr2exe;

    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0] lsu2exe_wb_req_valid;
    wire [(W_LsuExeRespUop * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop;
    assign {
        lsu2exe_wb_req_valid,
        lsu2exe_wb_req_uop
    } = lsu2exe;
    wire [(32 * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_diag_val;
    wire [(32 * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_result;
    wire [(PRF_IDX_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_dest_preg;
    wire [(BR_MASK_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_br_mask;
    wire [(ROB_IDX_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_rob_idx;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_dest_en;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_page_fault_load;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_page_fault_store;
    wire [(UOP_TYPE_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_op;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_flush_pipe;
    assign {
        lsu2exe_wb_req_uop_diag_val,
        lsu2exe_wb_req_uop_result,
        lsu2exe_wb_req_uop_dest_preg,
        lsu2exe_wb_req_uop_br_mask,
        lsu2exe_wb_req_uop_rob_idx,
        lsu2exe_wb_req_uop_dest_en,
        lsu2exe_wb_req_uop_page_fault_load,
        lsu2exe_wb_req_uop_page_fault_store,
        lsu2exe_wb_req_uop_op,
        lsu2exe_wb_req_uop_flush_pipe
    } = lsu2exe_wb_req_uop;

    wire [(ISSUE_WIDTH + TOTAL_FU_COUNT)-1:0] exe2prf_entry_valid;
    wire [(W_ExePrfWbUop * (ISSUE_WIDTH + TOTAL_FU_COUNT))-1:0]
        exe2prf_entry_uop;
    assign {
        exe2prf_entry_valid,
        exe2prf_entry_uop
    } = exe2prf;
    wire [(PRF_IDX_WIDTH * (ISSUE_WIDTH + TOTAL_FU_COUNT))-1:0]
        exe2prf_entry_uop_dest_preg;
    wire [(32 * (ISSUE_WIDTH + TOTAL_FU_COUNT))-1:0]
        exe2prf_entry_uop_result;
    wire [(BR_MASK_WIDTH * (ISSUE_WIDTH + TOTAL_FU_COUNT))-1:0]
        exe2prf_entry_uop_br_mask;
    wire [(ISSUE_WIDTH + TOTAL_FU_COUNT)-1:0] exe2prf_entry_uop_dest_en;
    wire [(UOP_TYPE_WIDTH * (ISSUE_WIDTH + TOTAL_FU_COUNT))-1:0]
        exe2prf_entry_uop_op;
    assign {
        exe2prf_entry_uop_dest_preg,
        exe2prf_entry_uop_result,
        exe2prf_entry_uop_br_mask,
        exe2prf_entry_uop_dest_en,
        exe2prf_entry_uop_op
    } = exe2prf_entry_uop;

    wire [(MAX_UOP_TYPE * ISSUE_WIDTH)-1:0] exe2iss_fu_ready_mask;
    assign exe2iss_fu_ready_mask = exe2iss;

    wire        exe2csr_we;
    wire        exe2csr_re;
    wire [11:0] exe2csr_idx;
    wire [31:0] exe2csr_wdata;
    wire [31:0] exe2csr_wcmd;
    assign {
        exe2csr_we,
        exe2csr_re,
        exe2csr_idx,
        exe2csr_wdata,
        exe2csr_wcmd
    } = exe2csr;

    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0] exe2lsu_req_valid;
    wire [(W_ExeLsuReqUop * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop;
    assign {
        exe2lsu_req_valid,
        exe2lsu_req_uop
    } = exe2lsu;
    wire [(32 * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_result;
    wire [(PRF_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_dest_preg;
    wire [(3 * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_func3;
    wire [(7 * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_func7;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_is_atomic;
    wire [(BR_MASK_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_br_mask;
    wire [(ROB_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_stq_idx;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_ldq_idx;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_rob_flag;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_dest_en;
    wire [(UOP_TYPE_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_op;
    assign {
        exe2lsu_req_uop_result,
        exe2lsu_req_uop_dest_preg,
        exe2lsu_req_uop_func3,
        exe2lsu_req_uop_func7,
        exe2lsu_req_uop_is_atomic,
        exe2lsu_req_uop_br_mask,
        exe2lsu_req_uop_rob_idx,
        exe2lsu_req_uop_stq_idx,
        exe2lsu_req_uop_stq_flag,
        exe2lsu_req_uop_ldq_idx,
        exe2lsu_req_uop_rob_flag,
        exe2lsu_req_uop_dest_en,
        exe2lsu_req_uop_op
    } = exe2lsu_req_uop;

    wire                     exu2id_mispred;
    wire [31:0]              exu2id_redirect_pc;
    wire [ROB_IDX_WIDTH-1:0] exu2id_redirect_rob_idx;
    wire [BR_TAG_WIDTH-1:0]  exu2id_br_id;
    wire [FTQ_IDX_WIDTH-1:0] exu2id_ftq_idx;
    wire [BR_MASK_WIDTH-1:0] exu2id_clear_mask;
    assign {
        exu2id_mispred,
        exu2id_redirect_pc,
        exu2id_redirect_rob_idx,
        exu2id_br_id,
        exu2id_ftq_idx,
        exu2id_clear_mask
    } = exu2id;

    wire [ISSUE_WIDTH-1:0]                 exu2rob_entry_valid;
    wire [(W_ExuRobUop * ISSUE_WIDTH)-1:0] exu2rob_entry_uop;
    assign {
        exu2rob_entry_valid,
        exu2rob_entry_uop
    } = exu2rob;
    wire [(32 * ISSUE_WIDTH)-1:0]             exu2rob_entry_uop_diag_val;
    wire [(32 * ISSUE_WIDTH)-1:0]             exu2rob_entry_uop_result;
    wire [(ROB_IDX_WIDTH * ISSUE_WIDTH)-1:0]  exu2rob_entry_uop_rob_idx;
    wire [ISSUE_WIDTH-1:0]                    exu2rob_entry_uop_mispred;
    wire [ISSUE_WIDTH-1:0]                    exu2rob_entry_uop_br_taken;
    wire [ISSUE_WIDTH-1:0]                    exu2rob_entry_uop_page_fault_inst;
    wire [ISSUE_WIDTH-1:0]                    exu2rob_entry_uop_page_fault_load;
    wire [ISSUE_WIDTH-1:0]                    exu2rob_entry_uop_page_fault_store;
    wire [(UOP_TYPE_WIDTH * ISSUE_WIDTH)-1:0] exu2rob_entry_uop_op;
    wire [ISSUE_WIDTH-1:0]                    exu2rob_entry_uop_flush_pipe;
    assign {
        exu2rob_entry_uop_diag_val,
        exu2rob_entry_uop_result,
        exu2rob_entry_uop_rob_idx,
        exu2rob_entry_uop_mispred,
        exu2rob_entry_uop_br_taken,
        exu2rob_entry_uop_page_fault_inst,
        exu2rob_entry_uop_page_fault_load,
        exu2rob_entry_uop_page_fault_store,
        exu2rob_entry_uop_op,
        exu2rob_entry_uop_flush_pipe
    } = exu2rob_entry_uop;

    assign pi = {
        prf2exe,
        dec_bcast,
        rob_bcast,
        csr2exe,
        lsu2exe,
        csr_status,
        fu2exu
    };
    assign {
        exe2prf,
        exe2iss,
        exe2csr,
        exe2lsu,
        exu2id,
        exu2rob,
        exu2fu
    } = po;

    exu_bsd_top #(
        .W_ExuIn(W_ExuIn),
        .W_ExuOut(W_ExuOut)
    ) u_exu_bsd_top (
        .clk(clk),
        .rst_n(rst_n),
        .pi(pi),
        .po(po)
    );

endmodule
