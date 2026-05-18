// Formal frontend comb boundary: bpu_post_read_req_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/BPU.h:888,1910.
// Role: BPU post-read request/result assembly.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module bpu_post_read_req_comb_top #(
    parameter integer W_BpuPostReadReqCombIn = 64,
    parameter integer W_BpuPostReadReqCombOut = 64
) (
    input wire [W_BpuPostReadReqCombIn-1:0] bpu_post_read_req_comb_in,
    output wire [W_BpuPostReadReqCombOut-1:0] bpu_post_read_req_comb_out
);

    wire [W_BpuPostReadReqCombIn-1:0] bpu_post_read_req_comb_pi;
    wire [W_BpuPostReadReqCombOut-1:0] bpu_post_read_req_comb_po;

    assign bpu_post_read_req_comb_pi = bpu_post_read_req_comb_in;
    assign bpu_post_read_req_comb_out = bpu_post_read_req_comb_po;

    bpu_post_read_req_comb_bsd_top #(
        .W_BpuPostReadReqCombIn(W_BpuPostReadReqCombIn),
        .W_BpuPostReadReqCombOut(W_BpuPostReadReqCombOut)
    ) u_bpu_post_read_req_comb_bsd_top (
        .pi(bpu_post_read_req_comb_pi),
        .po(bpu_post_read_req_comb_po)
    );

endmodule

module bpu_post_read_req_comb_bsd_top #(
    parameter integer W_BpuPostReadReqCombIn = 64,
    parameter integer W_BpuPostReadReqCombOut = 64
) (
    input wire [W_BpuPostReadReqCombIn-1:0] pi,
    output wire [W_BpuPostReadReqCombOut-1:0] po
);
    assign po = {W_BpuPostReadReqCombOut{1'b0}};
endmodule
