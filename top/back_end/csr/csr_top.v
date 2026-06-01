// ffc CSR 边界的 BSD 封装。
//
// 参考结构体：
//   CsrIn  = {exe2csr, rob2csr, rob_bcast}
//   CsrOut = {csr2exe, csr2rob, csr2front, csr_status}
//
// BSD 接口：
//   u_csr_bsd_top(clk, rst_n, pi, po)
//   pi = {exe2csr, rob2csr, rob_bcast}
//   po = {csr2exe, csr2rob, csr2front, csr_status}
//
// 端口命名统一按 back_end 包规范使用 clk/rst_n/pi/po。
// qm3dc 里部分历史网表使用 din/dout、pi_ext/po_ext 等名字，属于生成器输出名；
// 若复用那类网表，需要先套一层同名 *_bsd_top 薄适配，转换成本包规范后再接入。
//
// 展开的 CSR/status 输出只供 back_top 连接前端和观察端口使用。
// BSD 仍然只需要实现 pi/po 两条业务总线以及 clk/rst_n 控制端口。


module csr_top #(
    parameter integer ROB_IDX_WIDTH    = 9,
    parameter integer BR_MASK_WIDTH    = 64,
    parameter integer W_ExeCsrIO       = 1 + 1 + 12 + 32 + 32,
    parameter integer W_RobCsrIO       = 2,
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_CsrExeIO       = 32,
    parameter integer W_CsrRobIO       = 1,
    parameter integer W_CsrFrontIO     = 32 + 32,
    parameter integer W_CsrStatusIO    = 32 + 32 + 32 + 2,
    parameter integer W_CsrIn          = W_ExeCsrIO + W_RobCsrIO + W_RobBroadcastIO,
    parameter integer W_CsrOut         =
        W_CsrExeIO + W_CsrRobIO + W_CsrFrontIO + W_CsrStatusIO
) (
    input wire clk,
    input wire rst_n,

    input wire [W_ExeCsrIO-1:0]       exe2csr,
    input wire [W_RobCsrIO-1:0]       rob2csr,
    input wire [W_RobBroadcastIO-1:0] rob_bcast,

    output wire [W_CsrExeIO-1:0]    csr2exe,
    output wire [W_CsrRobIO-1:0]    csr2rob,
    output wire [W_CsrFrontIO-1:0]  csr2front,
    output wire [W_CsrStatusIO-1:0] csr_status,

    output wire [31:0] csr2front_epc,
    output wire [31:0] csr2front_trap_pc,
    output wire [31:0] csr_status_sstatus,
    output wire [31:0] csr_status_mstatus,
    output wire [31:0] csr_status_satp,
    output wire [1:0]  csr_status_privilege
);

    wire [W_CsrIn-1:0]  pi;
    wire [W_CsrOut-1:0] po;

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

    wire rob2csr_interrupt_resp;
    wire rob2csr_commit;
    assign {
        rob2csr_interrupt_resp,
        rob2csr_commit
    } = rob2csr;

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

    assign pi = {
        exe2csr,
        rob2csr,
        rob_bcast
    };
    assign {
        csr2exe,
        csr2rob,
        csr2front,
        csr_status
    } = po;

    wire [31:0] csr2exe_rdata;
    assign csr2exe_rdata = csr2exe;

    wire csr2rob_interrupt_req;
    assign csr2rob_interrupt_req = csr2rob;

    assign {
        csr2front_epc,
        csr2front_trap_pc
    } = csr2front;
    assign {
        csr_status_sstatus,
        csr_status_mstatus,
        csr_status_satp,
        csr_status_privilege
    } = csr_status;

    csr_bsd_top #(
        .W_CsrIn(W_CsrIn),
        .W_CsrOut(W_CsrOut)
    ) u_csr_bsd_top (
        .clk(clk),
        .rst_n(rst_n),
        .pi(pi),
        .po(po)
    );

endmodule
