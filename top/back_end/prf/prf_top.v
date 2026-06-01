// ffc PRF 边界的 BSD 封装。
//
// 参考结构体：
//   PrfIn  = {iss2prf, exe2prf, dec_bcast, rob_bcast}
//   PrfOut = {prf2exe, prf_awake}
//
// BSD 接口：
//   u_prf_bsd_top(clk, rst_n, pi, po)
//   pi = {iss2prf, exe2prf, dec_bcast, rob_bcast}
//   po = {prf2exe, prf_awake}
//
// 端口命名统一按 back_end 包规范使用 clk/rst_n/pi/po。
// qm3dc 里部分历史网表使用 din/dout、pi_ext/po_ext 等名字，属于生成器输出名；
// 若复用那类网表，需要先套一层同名 *_bsd_top 薄适配，转换成本包规范后再接入。
//
// FTQ PC 查询不是 PRF 边界，ffc 中由 EXU 发起查询。
// 因此本封装不再给 PRF 暴露 ftq_*_pc_req/resp，避免 BSD 端口和模拟器不一致。


module prf_top #(
    parameter integer ISSUE_WIDTH       = 15,
    parameter integer TOTAL_FU_COUNT    = 19,
    parameter integer LSU_LOAD_WB_WIDTH = 3,
    parameter integer PRF_IDX_WIDTH     = 9,
    parameter integer ROB_IDX_WIDTH     = 9,
    parameter integer STQ_IDX_WIDTH     = 6,
    parameter integer LDQ_IDX_WIDTH     = 6,
    parameter integer BR_TAG_WIDTH      = 6,
    parameter integer BR_MASK_WIDTH     = 64,
    parameter integer CSR_IDX_WIDTH     = 12,
    parameter integer FTQ_IDX_WIDTH     = 7,
    parameter integer FTQ_OFFSET_WIDTH  = 4,
    parameter integer UOP_TYPE_WIDTH    = 5,
    parameter integer MAX_UOP_TYPE      = 18,
    parameter integer W_DebugMeta            = 32 + 32 + 8 + 1 + 64,
    parameter integer W_IssPrfUop       =
        (3 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        3 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH + BR_MASK_WIDTH +
        CSR_IDX_WIDTH + ROB_IDX_WIDTH + STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH +
        1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_IssPrfIO        = ISSUE_WIDTH * (1 + W_IssPrfUop),
    parameter integer W_ExePrfWbUop     =
        PRF_IDX_WIDTH + 32 + BR_MASK_WIDTH + 1 + UOP_TYPE_WIDTH,
    parameter integer W_ExePrfEntry     = 1 + W_ExePrfWbUop,
    parameter integer W_ExePrfIO        =
        (ISSUE_WIDTH + TOTAL_FU_COUNT) * W_ExePrfEntry,
    parameter integer W_DecBroadcastIO  =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_RobBroadcastIO  =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_WakeInfo        = 1 + PRF_IDX_WIDTH,
    parameter integer W_PrfAwakeIO      = LSU_LOAD_WB_WIDTH * W_WakeInfo,
    parameter integer W_PrfExeUop       =
        (3 * PRF_IDX_WIDTH) + 64 +
        FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 + 3 + 2 + 3 + 7 + 32 +
        BR_TAG_WIDTH + BR_MASK_WIDTH + CSR_IDX_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + UOP_TYPE_WIDTH + W_DebugMeta,
    parameter integer W_PrfExeIO        = ISSUE_WIDTH * (1 + W_PrfExeUop),
    parameter integer W_PrfIn           =
        W_IssPrfIO + W_ExePrfIO + W_DecBroadcastIO + W_RobBroadcastIO,
    parameter integer W_PrfOut          =
        W_PrfExeIO + W_PrfAwakeIO
) (
    input wire clk,
    input wire rst_n,

    input wire [W_IssPrfIO-1:0]       iss2prf,
    input wire [W_ExePrfIO-1:0]       exe2prf,
    input wire [W_DecBroadcastIO-1:0] dec_bcast,
    input wire [W_RobBroadcastIO-1:0] rob_bcast,

    output wire [W_PrfExeIO-1:0]      prf2exe,
    output wire [W_PrfAwakeIO-1:0]    prf_awake
);

    wire [W_PrfIn-1:0]  pi;
    wire [W_PrfOut-1:0] po;

    // iss2prf 的字段级视图，对齐 IssPrfIO 的字段顺序。
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
    wire [(W_DebugMeta * ISSUE_WIDTH)-1:0]     iss2prf_iss_entry_uop_dbg;

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
        iss2prf_iss_entry_uop_op,
        iss2prf_iss_entry_uop_dbg
    } = iss2prf;

    // exe2prf 的字段级视图，对齐 ExePrfIO 的字段顺序。
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

    // 共享广播输入的字段级视图，用于核对 dec_bcast/rob_bcast 位序。
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

    // prf2exe 的字段级视图，对齐 PrfExeIO 的字段顺序。
    wire [ISSUE_WIDTH-1:0]        prf2exe_iss_entry_valid;
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
    wire [(W_DebugMeta * ISSUE_WIDTH)-1:0]     prf2exe_iss_entry_uop_dbg;

    assign {
        prf2exe_iss_entry_valid,
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
        prf2exe_iss_entry_uop_op,
        prf2exe_iss_entry_uop_dbg
    } = prf2exe;

    wire [LSU_LOAD_WB_WIDTH-1:0]                   prf_awake_wake_valid;
    wire [(PRF_IDX_WIDTH * LSU_LOAD_WB_WIDTH)-1:0] prf_awake_wake_preg;
    assign {
        prf_awake_wake_valid,
        prf_awake_wake_preg
    } = prf_awake;

    assign pi = {
        iss2prf,
        exe2prf,
        dec_bcast,
        rob_bcast
    };
    assign {
        prf2exe,
        prf_awake
    } = po;

    prf_bsd_top #(
        .W_PrfIn(W_PrfIn),
        .W_PrfOut(W_PrfOut)
    ) u_prf_bsd_top (
        .clk(clk),
        .rst_n(rst_n),
        .pi(pi),
        .po(po)
    );

endmodule
