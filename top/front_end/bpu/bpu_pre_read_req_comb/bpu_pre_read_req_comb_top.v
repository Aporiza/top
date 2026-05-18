// Formal frontend comb boundary: bpu_pre_read_req_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/BPU.h:738,1908.
// Role: BPU predictor pre-read request.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module bpu_pre_read_req_comb_top #(
    parameter integer W_BpuPreReadReqCombIn = 64,
    parameter integer W_BpuPreReadReqCombOut = 64
) (
    input wire [W_BpuPreReadReqCombIn-1:0] bpu_pre_read_req_comb_in,
    output wire [W_BpuPreReadReqCombOut-1:0] bpu_pre_read_req_comb_out
);

    wire [W_BpuPreReadReqCombIn-1:0] bpu_pre_read_req_comb_pi;
    wire [W_BpuPreReadReqCombOut-1:0] bpu_pre_read_req_comb_po;

    assign bpu_pre_read_req_comb_pi = bpu_pre_read_req_comb_in;
    assign bpu_pre_read_req_comb_out = bpu_pre_read_req_comb_po;

    bpu_pre_read_req_comb_bsd_top #(
        .W_BpuPreReadReqCombIn(W_BpuPreReadReqCombIn),
        .W_BpuPreReadReqCombOut(W_BpuPreReadReqCombOut)
    ) u_bpu_pre_read_req_comb_bsd_top (
        .pi(bpu_pre_read_req_comb_pi),
        .po(bpu_pre_read_req_comb_po)
    );

endmodule

module bpu_pre_read_req_comb_bsd_top #(
    parameter integer W_BpuPreReadReqCombIn = 64,
    parameter integer W_BpuPreReadReqCombOut = 64
) (
    input wire [W_BpuPreReadReqCombIn-1:0] pi,
    output wire [W_BpuPreReadReqCombOut-1:0] po
);
    assign po = {W_BpuPreReadReqCombOut{1'b0}};
endmodule
