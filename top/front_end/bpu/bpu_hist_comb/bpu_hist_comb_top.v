// Formal frontend comb boundary: bpu_hist_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BPU history update bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module bpu_hist_comb_top #(
    parameter integer W_BpuHistCombIn  = 64,
    parameter integer W_BpuHistCombOut = 64
) (
    input  wire [W_BpuHistCombIn-1:0]  bsd_pi,
    output wire [W_BpuHistCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuHistCombIn-1:0]  bpu_predict_main_bundle;
    wire [W_BpuHistCombOut-1:0] bpu_hist_bundle;
    wire [W_BpuHistCombIn-1:0]  bpu_hist_comb_bsd_pi;
    wire [W_BpuHistCombOut-1:0] bpu_hist_comb_bsd_po;

    assign {
        bpu_predict_main_bundle
    } = bsd_pi;

    assign bpu_hist_comb_bsd_pi = {
        bpu_predict_main_bundle
    };

    assign {
        bpu_hist_bundle
    } = bpu_hist_comb_bsd_po;

    assign bsd_po = {
        bpu_hist_bundle
    };

    bpu_hist_comb_bsd_top #(
        .W_BpuHistCombIn(W_BpuHistCombIn),
        .W_BpuHistCombOut(W_BpuHistCombOut)
    ) u_bpu_hist_comb_bsd_top (
        .bsd_pi(bpu_hist_comb_bsd_pi),
        .bsd_po(bpu_hist_comb_bsd_po)
    );

endmodule

module bpu_hist_comb_bsd_top #(
    parameter integer W_BpuHistCombIn  = 64,
    parameter integer W_BpuHistCombOut = 64
) (
    input  wire [W_BpuHistCombIn-1:0]  bsd_pi,
    output wire [W_BpuHistCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BpuHistCombOut{1'b0}};

endmodule
