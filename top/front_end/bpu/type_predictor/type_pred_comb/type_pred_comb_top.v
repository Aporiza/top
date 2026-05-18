// Formal frontend comb boundary: type_pred_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/type_predictor/TypePredictor.h:346,408-414.
// Role: type prediction.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module type_pred_comb_top #(
    parameter integer W_TypePredCombIn = 64,
    parameter integer W_TypePredCombOut = 64
) (
    input wire [W_TypePredCombIn-1:0] type_pred_comb_in,
    output wire [W_TypePredCombOut-1:0] type_pred_comb_out
);

    wire [W_TypePredCombIn-1:0] type_pred_comb_pi;
    wire [W_TypePredCombOut-1:0] type_pred_comb_po;

    assign type_pred_comb_pi = type_pred_comb_in;
    assign type_pred_comb_out = type_pred_comb_po;

    type_pred_comb_bsd_top #(
        .W_TypePredCombIn(W_TypePredCombIn),
        .W_TypePredCombOut(W_TypePredCombOut)
    ) u_type_pred_comb_bsd_top (
        .pi(type_pred_comb_pi),
        .po(type_pred_comb_po)
    );

endmodule

module type_pred_comb_bsd_top #(
    parameter integer W_TypePredCombIn = 64,
    parameter integer W_TypePredCombOut = 64
) (
    input wire [W_TypePredCombIn-1:0] pi,
    output wire [W_TypePredCombOut-1:0] po
);
    assign po = {W_TypePredCombOut{1'b0}};
endmodule
