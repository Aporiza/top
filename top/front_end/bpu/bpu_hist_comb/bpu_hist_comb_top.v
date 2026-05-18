// Formal frontend comb boundary: bpu_hist_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/BPU.h:1222,1641.
// Role: history/RAS update boundary.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module bpu_hist_comb_top #(
    parameter integer W_BpuHistCombIn = 64,
    parameter integer W_BpuHistCombOut = 64
) (
    input wire [W_BpuHistCombIn-1:0] bpu_hist_comb_in,
    output wire [W_BpuHistCombOut-1:0] bpu_hist_comb_out
);

    wire [W_BpuHistCombIn-1:0] bpu_hist_comb_pi;
    wire [W_BpuHistCombOut-1:0] bpu_hist_comb_po;

    assign bpu_hist_comb_pi = bpu_hist_comb_in;
    assign bpu_hist_comb_out = bpu_hist_comb_po;

    bpu_hist_comb_bsd_top #(
        .W_BpuHistCombIn(W_BpuHistCombIn),
        .W_BpuHistCombOut(W_BpuHistCombOut)
    ) u_bpu_hist_comb_bsd_top (
        .pi(bpu_hist_comb_pi),
        .po(bpu_hist_comb_po)
    );

endmodule

module bpu_hist_comb_bsd_top #(
    parameter integer W_BpuHistCombIn = 64,
    parameter integer W_BpuHistCombOut = 64
) (
    input wire [W_BpuHistCombIn-1:0] pi,
    output wire [W_BpuHistCombOut-1:0] po
);
    assign po = {W_BpuHistCombOut{1'b0}};
endmodule
