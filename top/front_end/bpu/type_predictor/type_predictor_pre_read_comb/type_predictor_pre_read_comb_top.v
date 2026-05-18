// Formal frontend comb boundary: type_predictor_pre_read_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/type_predictor/TypePredictor.h:320,411.
// Role: type predictor pre-read.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module type_predictor_pre_read_comb_top #(
    parameter integer W_TypePredictorPreReadCombIn = 64,
    parameter integer W_TypePredictorPreReadCombOut = 64
) (
    input wire [W_TypePredictorPreReadCombIn-1:0] type_predictor_pre_read_comb_in,
    output wire [W_TypePredictorPreReadCombOut-1:0] type_predictor_pre_read_comb_out
);

    wire [W_TypePredictorPreReadCombIn-1:0] type_predictor_pre_read_comb_pi;
    wire [W_TypePredictorPreReadCombOut-1:0] type_predictor_pre_read_comb_po;

    assign type_predictor_pre_read_comb_pi = type_predictor_pre_read_comb_in;
    assign type_predictor_pre_read_comb_out = type_predictor_pre_read_comb_po;

    type_predictor_pre_read_comb_bsd_top #(
        .W_TypePredictorPreReadCombIn(W_TypePredictorPreReadCombIn),
        .W_TypePredictorPreReadCombOut(W_TypePredictorPreReadCombOut)
    ) u_type_predictor_pre_read_comb_bsd_top (
        .pi(type_predictor_pre_read_comb_pi),
        .po(type_predictor_pre_read_comb_po)
    );

endmodule

module type_predictor_pre_read_comb_bsd_top #(
    parameter integer W_TypePredictorPreReadCombIn = 64,
    parameter integer W_TypePredictorPreReadCombOut = 64
) (
    input wire [W_TypePredictorPreReadCombIn-1:0] pi,
    output wire [W_TypePredictorPreReadCombOut-1:0] po
);
    assign po = {W_TypePredictorPreReadCombOut{1'b0}};
endmodule
