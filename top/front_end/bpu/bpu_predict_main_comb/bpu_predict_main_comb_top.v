// Formal frontend comb boundary: bpu_predict_main_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: main BPU prediction output construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module bpu_predict_main_comb_top #(
    parameter integer W_BpuPredictMainCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuPredictMainCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  bpu_submodule_bind_bundle,
    output wire [W_BpuPredictMainCombOut-1:0] bpu_predict_main_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BpuPredictMainCombIn-1:0]  pi;
    wire [W_BpuPredictMainCombOut-1:0] po;
    assign pi = {
        bpu_submodule_bind_bundle
    };

    assign {
        bpu_predict_main_bundle
    } = po;

    bpu_predict_main_comb_bsd_top #(
        .W_BpuPredictMainCombIn(W_BpuPredictMainCombIn),
        .W_BpuPredictMainCombOut(W_BpuPredictMainCombOut)
    ) u_bpu_predict_main_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_predict_main_comb_bsd_top #(
    parameter integer W_BpuPredictMainCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuPredictMainCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  pi,
    output wire [W_BpuPredictMainCombOut-1:0] po
);

    assign po = {W_BpuPredictMainCombOut{1'b0}};

endmodule
