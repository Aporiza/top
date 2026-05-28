// Source struct:
//   CsrIn  = {exe2csr, rob2csr, rob_bcast}
//   CsrOut = {csr2exe, csr2rob, csr2front, csr_status}
// CSR_RegFile, privilege register and CSR write-back staging are internal.

// -----------------------------------------------------------------------------
// 后端端口自查
// 模块：csr_top
// 文件：csr/csr_top.v:50
// 来源：当前 back_end RTL module 声明
// BSD 层：csr_bsd_top，实例名 u_csr_bsd_top，当前仓库未提供定义
//
// 输入端口：3 个，合计 180 bit
// 输出端口：10 个，合计 357 bit
//
// 参数：
//   ROB_IDX_WIDTH    = 11  // 11
//   BR_MASK_WIDTH    = 64  // 64
//   W_ExeCsrIO       = 1 + 1 + 12 + 32 + 32  // 78
//   W_RobCsrIO       = 2  // 2
//   W_RobBroadcastIO = 7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1  // 100
//   W_CsrExeIO       = 32  // 32
//   W_CsrRobIO       = 1  // 1
//   W_CsrFrontIO     = 32 + 32  // 64
//   W_CsrStatusIO    = 32 + 32 + 32 + 2  // 98
//   W_CsrIn          = W_ExeCsrIO + W_RobCsrIO + W_RobBroadcastIO  // 180
//   W_CsrOut         = W_CsrExeIO + W_CsrRobIO + W_CsrFrontIO + W_CsrStatusIO  // 195
//
// 输入端口：
//   exe2csr    [W_ExeCsrIO-1:0]        78 bit
//   rob2csr    [W_RobCsrIO-1:0]        2 bit
//   rob_bcast  [W_RobBroadcastIO-1:0]  100 bit
//
// 输出端口：
//   csr2exe               [W_CsrExeIO-1:0]     32 bit
//   csr2rob               [W_CsrRobIO-1:0]     1 bit
//   csr2front             [W_CsrFrontIO-1:0]   64 bit
//   csr_status            [W_CsrStatusIO-1:0]  98 bit
//   csr2front_epc         [31:0]               32 bit
//   csr2front_trap_pc     [31:0]               32 bit
//   csr_status_sstatus    [31:0]               32 bit
//   csr_status_mstatus    [31:0]               32 bit
//   csr_status_satp       [31:0]               32 bit
//   csr_status_privilege  [1:0]                2 bit
//
// BSD 层端口：当前仓库只实例化该 bsd_top，未提供 module 定义。
// 后续补 bsd_top 时，需要保持实例名和 pi/po 连接一致。
// -----------------------------------------------------------------------------

module csr_top #(
    parameter integer ROB_IDX_WIDTH       = 11,
    parameter integer BR_MASK_WIDTH    = 64,
    parameter integer W_ExeCsrIO       = 1 + 1 + 12 + 32 + 32,
    parameter integer W_RobCsrIO       = 2,
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_CsrExeIO    = 32,
    parameter integer W_CsrRobIO    = 1,
    parameter integer W_CsrFrontIO  = 32 + 32,
    parameter integer W_CsrStatusIO = 32 + 32 + 32 + 2,
    parameter integer W_CsrIn       = W_ExeCsrIO + W_RobCsrIO + W_RobBroadcastIO,
    parameter integer W_CsrOut      =
        W_CsrExeIO + W_CsrRobIO + W_CsrFrontIO + W_CsrStatusIO
) (
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
        .pi(pi),
        .po(po)
    );

endmodule
