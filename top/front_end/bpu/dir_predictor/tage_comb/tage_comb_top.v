// Formal frontend comb boundary: tage_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: TAGE direction result bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module tage_comb_top #(
    parameter integer W_TageCombIn  = 64,
    parameter integer W_TageCombOut = 64
) (
    input  wire [W_TageCombIn-1:0]  bsd_pi,
    output wire [W_TageCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_TageCombIn-1:0]  tage_input_bundle;
    wire [W_TageCombOut-1:0] tage_bundle;
    wire [W_TageCombIn-1:0]  tage_comb_bsd_pi;
    wire [W_TageCombOut-1:0] tage_comb_bsd_po;

    assign {
        tage_input_bundle
    } = bsd_pi;

    assign tage_comb_bsd_pi = {
        tage_input_bundle
    };

    assign {
        tage_bundle
    } = tage_comb_bsd_po;

    assign bsd_po = {
        tage_bundle
    };

    tage_comb_bsd_top #(
        .W_TageCombIn(W_TageCombIn),
        .W_TageCombOut(W_TageCombOut)
    ) u_tage_comb_bsd_top (
        .bsd_pi(tage_comb_bsd_pi),
        .bsd_po(tage_comb_bsd_po)
    );

endmodule

module tage_comb_bsd_top #(
    parameter integer W_TageCombIn  = 64,
    parameter integer W_TageCombOut = 64
) (
    input  wire [W_TageCombIn-1:0]  bsd_pi,
    output wire [W_TageCombOut-1:0] bsd_po
);

    assign bsd_po = {W_TageCombOut{1'b0}};

endmodule
