// Formal frontend comb boundary: type_pred_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: type prediction result bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module type_pred_comb_top #(
    parameter integer W_TypePredCombIn  = 64,
    parameter integer W_TypePredCombOut = 64
) (
    input  wire [W_TypePredCombIn-1:0]  bsd_pi,
    output wire [W_TypePredCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_TypePredCombIn-1:0]  type_pred_input_bundle;
    wire [W_TypePredCombOut-1:0] type_pred_bundle;
    wire [W_TypePredCombIn-1:0]  type_pred_comb_bsd_pi;
    wire [W_TypePredCombOut-1:0] type_pred_comb_bsd_po;

    assign {
        type_pred_input_bundle
    } = bsd_pi;

    assign type_pred_comb_bsd_pi = {
        type_pred_input_bundle
    };

    assign {
        type_pred_bundle
    } = type_pred_comb_bsd_po;

    assign bsd_po = {
        type_pred_bundle
    };

    type_pred_comb_bsd_top #(
        .W_TypePredCombIn(W_TypePredCombIn),
        .W_TypePredCombOut(W_TypePredCombOut)
    ) u_type_pred_comb_bsd_top (
        .bsd_pi(type_pred_comb_bsd_pi),
        .bsd_po(type_pred_comb_bsd_po)
    );

endmodule

module type_pred_comb_bsd_top #(
    parameter integer W_TypePredCombIn  = 64,
    parameter integer W_TypePredCombOut = 64
) (
    input  wire [W_TypePredCombIn-1:0]  bsd_pi,
    output wire [W_TypePredCombOut-1:0] bsd_po
);

    assign bsd_po = {W_TypePredCombOut{1'b0}};

endmodule
