// Formal frontend comb boundary: type_pred_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: type prediction result bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module type_pred_comb_top #(
    parameter integer W_TypePredCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_TypePredCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_TypePredCombIn-1:0]  type_pred_input_bundle,
    output wire [W_TypePredCombOut-1:0] type_pred_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_TypePredCombIn-1:0]  pi;
    wire [W_TypePredCombOut-1:0] po;
    assign pi = {
        type_pred_input_bundle
    };

    assign {
        type_pred_bundle
    } = po;

    type_pred_comb_bsd_top #(
        .W_TypePredCombIn(W_TypePredCombIn),
        .W_TypePredCombOut(W_TypePredCombOut)
    ) u_type_pred_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module type_pred_comb_bsd_top #(
    parameter integer W_TypePredCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_TypePredCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_TypePredCombIn-1:0]  pi,
    output wire [W_TypePredCombOut-1:0] po
);

    assign po = {W_TypePredCombOut{1'b0}};

endmodule
