// Formal frontend comb boundary: bpu_predict_main_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: main BPU prediction output construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module bpu_predict_main_comb_top #(
    parameter integer W_BpuPredictMainCombIn  = 64,
    parameter integer W_BpuPredictMainCombOut = 64
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  bsd_pi,
    output wire [W_BpuPredictMainCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuPredictMainCombIn-1:0]  bpu_submodule_bind_bundle;
    wire [W_BpuPredictMainCombOut-1:0] bpu_predict_main_bundle;
    wire [W_BpuPredictMainCombIn-1:0]  bpu_predict_main_comb_bsd_pi;
    wire [W_BpuPredictMainCombOut-1:0] bpu_predict_main_comb_bsd_po;

    assign {
        bpu_submodule_bind_bundle
    } = bsd_pi;

    assign bpu_predict_main_comb_bsd_pi = {
        bpu_submodule_bind_bundle
    };

    assign {
        bpu_predict_main_bundle
    } = bpu_predict_main_comb_bsd_po;

    assign bsd_po = {
        bpu_predict_main_bundle
    };

    bpu_predict_main_comb_bsd_top #(
        .W_BpuPredictMainCombIn(W_BpuPredictMainCombIn),
        .W_BpuPredictMainCombOut(W_BpuPredictMainCombOut)
    ) u_bpu_predict_main_comb_bsd_top (
        .bsd_pi(bpu_predict_main_comb_bsd_pi),
        .bsd_po(bpu_predict_main_comb_bsd_po)
    );

endmodule

module bpu_predict_main_comb_bsd_top #(
    parameter integer W_BpuPredictMainCombIn  = 64,
    parameter integer W_BpuPredictMainCombOut = 64
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  bsd_pi,
    output wire [W_BpuPredictMainCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BpuPredictMainCombOut{1'b0}};

endmodule
