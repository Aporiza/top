// Formal frontend comb boundary: bpu_hist_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: BPU history update bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module bpu_hist_comb_top #(
    parameter integer W_BpuHistCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuHistCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuHistCombIn-1:0]  bpu_predict_main_bundle,
    output wire [W_BpuHistCombOut-1:0] bpu_hist_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BpuHistCombIn-1:0]  pi;
    wire [W_BpuHistCombOut-1:0] po;
    assign pi = {
        bpu_predict_main_bundle
    };

    assign {
        bpu_hist_bundle
    } = po;

    bpu_hist_comb_bsd_top #(
        .W_BpuHistCombIn(W_BpuHistCombIn),
        .W_BpuHistCombOut(W_BpuHistCombOut)
    ) u_bpu_hist_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_hist_comb_bsd_top #(
    parameter integer W_BpuHistCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuHistCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuHistCombIn-1:0]  pi,
    output wire [W_BpuHistCombOut-1:0] po
);

    assign po = {W_BpuHistCombOut{1'b0}};

endmodule
