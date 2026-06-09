// simulator-main 默认配置 IDU 边界的 BSD 封装。
//
// 参考结构体：
//   IduIn  = {issue, ren2dec, rob_bcast, exu2id}
//   IduOut = {dec2ren, dec_bcast, idu_consume}
//
// BSD 接口规范：
//   u_idu_bsd_top(clk, rst_n, pi, po)
//   pi = {pre_issue, ren2dec, rob_bcast, exu2id}
//   po = {dec2ren, dec_bcast, idu_consume}
//
// 模拟器里 IDU 的 issue 输入在本封装中命名为 pre_issue，表示来自 PreIduQueue。
// idu_br_latch 是 class Idu 的公开成员状态，不属于 IduOut，因此不能进入 BSD po。
// 这里由 idu_top 包装层单独锁存它，供 BackTop.cpp 等价的重定向路径和 PreIduQueue 使用。


module idu_top #(
    parameter integer DECODE_WIDTH             = 8,
    parameter integer AREG_IDX_WIDTH           = 6,
    parameter integer PRF_IDX_WIDTH            = 7,
    parameter integer ROB_IDX_WIDTH            = 7,
    parameter integer STQ_IDX_WIDTH            = 6,
    parameter integer LDQ_IDX_WIDTH            = 6,
    parameter integer BR_TAG_WIDTH             = 6,
    parameter integer BR_MASK_WIDTH            = 64,
    parameter integer CSR_IDX_WIDTH            = 12,
    parameter integer FTQ_IDX_WIDTH            = 6,
    parameter integer FTQ_OFFSET_WIDTH         = 4,
    parameter integer INST_TYPE_WIDTH          = 5,
    parameter integer ROB_CPLT_MASK_WIDTH      = 3,
    parameter integer W_InstructionBufferEntry =
        1 + 32 + 32 + 1 + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1,
    parameter integer W_PreIssueIO             = W_InstructionBufferEntry * DECODE_WIDTH,
    parameter integer W_RenDecIO               = 1,
    parameter integer W_RobBroadcastIO         =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_ExuIdIO                =
        1 + 32 + ROB_IDX_WIDTH + BR_TAG_WIDTH + FTQ_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_DecRenInst             =
        32 + (3 * AREG_IDX_WIDTH) + FTQ_IDX_WIDTH + FTQ_OFFSET_WIDTH + 1 +
        INST_TYPE_WIDTH + 3 + 1 + 2 + 3 + 7 + 32 + BR_TAG_WIDTH +
        BR_MASK_WIDTH + CSR_IDX_WIDTH + (2 * ROB_CPLT_MASK_WIDTH) + 2,
    parameter integer W_DecRenIO               = DECODE_WIDTH * (W_DecRenInst + 1),
    parameter integer W_DecBroadcastIO         =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_IduConsumeIO           = DECODE_WIDTH,
    parameter integer W_IduIn                  =
        W_PreIssueIO + W_RenDecIO + W_RobBroadcastIO + W_ExuIdIO,
    parameter integer W_IduOut                 =
        W_DecRenIO + W_DecBroadcastIO + W_IduConsumeIO
) (
    input wire clk,
    input wire rst_n,

    input wire [W_PreIssueIO-1:0]     pre_issue,
    input wire [W_RenDecIO-1:0]       ren2dec,
    input wire [W_RobBroadcastIO-1:0] rob_bcast,
    input wire [W_ExuIdIO-1:0]        exu2id,

    output wire [W_DecRenIO-1:0]       dec2ren,
    output wire [W_DecBroadcastIO-1:0] dec_bcast,
    output wire [W_IduConsumeIO-1:0]   idu_consume,
    output wire [W_ExuIdIO-1:0]        idu_br_latch,

    output wire                     dec_bcast_mispred,
    output wire [BR_MASK_WIDTH-1:0] dec_bcast_br_mask,
    output wire [BR_TAG_WIDTH-1:0]  dec_bcast_br_id,
    output wire [ROB_IDX_WIDTH-1:0] dec_bcast_redirect_rob_idx,
    output wire [BR_MASK_WIDTH-1:0] dec_bcast_clear_mask,

    output wire                     idu_br_latch_mispred,
    output wire [31:0]              idu_br_latch_redirect_pc,
    output wire [ROB_IDX_WIDTH-1:0] idu_br_latch_redirect_rob_idx,
    output wire [BR_TAG_WIDTH-1:0]  idu_br_latch_br_id,
    output wire [FTQ_IDX_WIDTH-1:0] idu_br_latch_ftq_idx,
    output wire [BR_MASK_WIDTH-1:0] idu_br_latch_clear_mask
);

    wire [W_IduIn-1:0]     pi;
    wire [W_IduOut-1:0]    po;
    reg  [W_ExuIdIO-1:0]   idu_br_latch_q;

    wire [(W_InstructionBufferEntry * DECODE_WIDTH)-1:0] pre_issue_entries;
    assign pre_issue_entries = pre_issue;

    wire ren2dec_ready;
    assign ren2dec_ready = ren2dec;

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

    assign pi = {
        pre_issue,
        ren2dec,
        rob_bcast,
        exu2id
    };
    assign {
        dec2ren,
        dec_bcast,
        idu_consume
    } = po;

    // simulator-main 的 br_latch 是 IDU 类对象内部的顺序状态：
    //   - Idu::init() 把 br_latch 清零；
    //   - 非 flush 周期，Idu::seq() 后 br_latch 等于本拍 exu2id；
    //   - flush 周期，comb_fire() 先把 br_latch_1 清零，seq() 再写回 br_latch。
    // BSD po 必须只对应 IduOut，所以这里在包装层复刻这个状态，供 BackTop 和
    // PreIduQueue 读取；组员实现 idu_bsd_top 时不需要把该状态再塞进 po。
    assign idu_br_latch = idu_br_latch_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idu_br_latch_q <= {W_ExuIdIO{1'b0}};
        end else if (rob_bcast_flush) begin
            idu_br_latch_q <= {W_ExuIdIO{1'b0}};
        end else begin
            idu_br_latch_q <= exu2id;
        end
    end

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

    assign {
        dec_bcast_mispred,
        dec_bcast_br_mask,
        dec_bcast_br_id,
        dec_bcast_redirect_rob_idx,
        dec_bcast_clear_mask
    } = dec_bcast;

    wire [DECODE_WIDTH-1:0] idu_consume_fire;
    assign idu_consume_fire = idu_consume;

    assign {
        idu_br_latch_mispred,
        idu_br_latch_redirect_pc,
        idu_br_latch_redirect_rob_idx,
        idu_br_latch_br_id,
        idu_br_latch_ftq_idx,
        idu_br_latch_clear_mask
    } = idu_br_latch;

    idu_bsd_top #(
        .W_IduIn(W_IduIn),    // 实际值：825 bit，main/default 的 IduIn = {pre_issue, ren2dec, rob_bcast, exu2id}。
        .W_IduOut(W_IduOut)   // 实际值：1790 bit，main/default 的 IduOut = {dec2ren, dec_bcast, idu_consume}。
    ) u_idu_bsd_top (
        .clk(clk),
        .rst_n(rst_n),
        .pi(pi),
        .po(po)
    );

endmodule
