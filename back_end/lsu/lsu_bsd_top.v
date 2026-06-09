`timescale 1ns / 1ps
`include "axi_llc_params.vh"
`include "qm3_cpu_params.vh"

// simulator-main 默认配置 LSU 边界的 BSD 封装。
//
// BSD 接口规范：
//   u_lsu_bsd_top(clk, rst_n, pi, po)
//
// pi/po 的低位 IO 部分和 LSU_Train.h 保持一致：
//   pi = {current LsuState, LsuIn IO}
//   po = {next    LsuState, LsuOut IO}
//
// 这里的外部 pi/po 只包含 IO 部分；本封装内部补上 LsuState 后再交给
// RealLsu_BSD。当前 RealLsu_BSD 仍是占位组合逻辑，next state = current
// state，LSU 输出 IO 暂时为 0。
module lsu_bsd_top #(
    parameter integer W_LsuIn          = 4927,
    parameter integer W_LsuOut         = 2504,
    parameter integer W_LsuState       = 32247
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [W_LsuIn-1:0]    pi,
    output wire [W_LsuOut-1:0]   po
);

    localparam integer LSU_PI_WIDTH = W_LsuIn + W_LsuState;
    localparam integer LSU_PO_WIDTH = W_LsuOut + W_LsuState;

    reg  [W_LsuState-1:0] lsu_state_q;
    wire [W_LsuState-1:0] lsu_state_d;

    wire [LSU_PI_WIDTH-1:0] real_lsu_pi;
    wire [LSU_PO_WIDTH-1:0] real_lsu_po;

    assign real_lsu_pi[0 +: W_LsuIn] = pi;
    assign real_lsu_pi[W_LsuIn +: W_LsuState] = lsu_state_q;

    assign po = real_lsu_po[0 +: W_LsuOut];
    assign lsu_state_d = real_lsu_po[W_LsuOut +: W_LsuState];

    RealLsu_BSD #(
        .LSU_IN_IO_WIDTH(W_LsuIn),
        .LSU_OUT_IO_WIDTH(W_LsuOut),
        .LSU_STATE_WIDTH(W_LsuState)
    ) u_reallsu_bsd (
        .pi(real_lsu_pi),
        .po(real_lsu_po)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lsu_state_q <= W_LsuState'(0);
        end else begin
            lsu_state_q <= lsu_state_d;
        end
    end

endmodule


// Combinational BSD block for RealLsu.
//
// Inputs and outputs are packed in the same order as LSU_Train.h pi/po.
// Full RealLsu behavior is intentionally left for later C++ translation.
module RealLsu_BSD #(
    parameter integer LSU_IN_IO_WIDTH  = 4927,
    parameter integer LSU_OUT_IO_WIDTH = 2504,
    parameter integer LSU_STATE_WIDTH  = 32247,
    parameter integer LSU_PI_WIDTH     = LSU_IN_IO_WIDTH + LSU_STATE_WIDTH,
    parameter integer LSU_PO_WIDTH     = LSU_OUT_IO_WIDTH + LSU_STATE_WIDTH
) (
    input  wire [LSU_PI_WIDTH-1:0]      pi,
    output wire [LSU_PO_WIDTH-1:0]      po
);

    assign po[0 +: LSU_OUT_IO_WIDTH] = {LSU_OUT_IO_WIDTH{1'b0}};
    assign po[LSU_OUT_IO_WIDTH +: LSU_STATE_WIDTH] =
        pi[LSU_IN_IO_WIDTH +: LSU_STATE_WIDTH];

endmodule
