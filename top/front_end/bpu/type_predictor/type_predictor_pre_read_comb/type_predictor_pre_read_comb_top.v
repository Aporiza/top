// Formal frontend comb boundary: type_predictor_pre_read_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: type predictor pre-read bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module type_predictor_pre_read_comb_top #(
    parameter integer W_TypePredictorPreReadCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_TypePredictorPreReadCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_TypePredictorPreReadCombIn-1:0]  bpu_pre_read_req_bundle,
    output wire [W_TypePredictorPreReadCombOut-1:0] type_predictor_pre_read_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_TypePredictorPreReadCombIn-1:0]  pi;
    wire [W_TypePredictorPreReadCombOut-1:0] po;
    assign pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        type_predictor_pre_read_bundle
    } = po;

    type_predictor_pre_read_comb_bsd_top #(
        .W_TypePredictorPreReadCombIn(W_TypePredictorPreReadCombIn),
        .W_TypePredictorPreReadCombOut(W_TypePredictorPreReadCombOut)
    ) u_type_predictor_pre_read_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module type_predictor_pre_read_comb_bsd_top #(
    parameter integer W_TypePredictorPreReadCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_TypePredictorPreReadCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_TypePredictorPreReadCombIn-1:0]  pi,
    output wire [W_TypePredictorPreReadCombOut-1:0] po
);

    assign po = {W_TypePredictorPreReadCombOut{1'b0}};

endmodule
