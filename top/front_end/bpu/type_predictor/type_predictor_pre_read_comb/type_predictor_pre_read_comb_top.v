// Formal frontend comb boundary: type_predictor_pre_read_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: type predictor pre-read bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module type_predictor_pre_read_comb_top #(
    parameter integer W_TypePredictorPreReadCombIn  = 64,
    parameter integer W_TypePredictorPreReadCombOut = 64
) (
    input  wire [W_TypePredictorPreReadCombIn-1:0]  bsd_pi,
    output wire [W_TypePredictorPreReadCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_TypePredictorPreReadCombIn-1:0]  bpu_pre_read_req_bundle;
    wire [W_TypePredictorPreReadCombOut-1:0] type_predictor_pre_read_bundle;
    wire [W_TypePredictorPreReadCombIn-1:0]  type_predictor_pre_read_comb_bsd_pi;
    wire [W_TypePredictorPreReadCombOut-1:0] type_predictor_pre_read_comb_bsd_po;

    assign {
        bpu_pre_read_req_bundle
    } = bsd_pi;

    assign type_predictor_pre_read_comb_bsd_pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        type_predictor_pre_read_bundle
    } = type_predictor_pre_read_comb_bsd_po;

    assign bsd_po = {
        type_predictor_pre_read_bundle
    };

    type_predictor_pre_read_comb_bsd_top #(
        .W_TypePredictorPreReadCombIn(W_TypePredictorPreReadCombIn),
        .W_TypePredictorPreReadCombOut(W_TypePredictorPreReadCombOut)
    ) u_type_predictor_pre_read_comb_bsd_top (
        .bsd_pi(type_predictor_pre_read_comb_bsd_pi),
        .bsd_po(type_predictor_pre_read_comb_bsd_po)
    );

endmodule

module type_predictor_pre_read_comb_bsd_top #(
    parameter integer W_TypePredictorPreReadCombIn  = 64,
    parameter integer W_TypePredictorPreReadCombOut = 64
) (
    input  wire [W_TypePredictorPreReadCombIn-1:0]  bsd_pi,
    output wire [W_TypePredictorPreReadCombOut-1:0] bsd_po
);

    assign bsd_po = {W_TypePredictorPreReadCombOut{1'b0}};

endmodule
