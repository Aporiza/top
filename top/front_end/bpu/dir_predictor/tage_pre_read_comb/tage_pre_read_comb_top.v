// Formal frontend comb boundary: tage_pre_read_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: TAGE pre-read bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module tage_pre_read_comb_top #(
    parameter integer W_TagePreReadCombIn  = 64,
    parameter integer W_TagePreReadCombOut = 64
) (
    input  wire [W_TagePreReadCombIn-1:0]  bsd_pi,
    output wire [W_TagePreReadCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_TagePreReadCombIn-1:0]  bpu_pre_read_req_bundle;
    wire [W_TagePreReadCombOut-1:0] tage_pre_read_bundle;
    wire [W_TagePreReadCombIn-1:0]  tage_pre_read_comb_bsd_pi;
    wire [W_TagePreReadCombOut-1:0] tage_pre_read_comb_bsd_po;

    assign {
        bpu_pre_read_req_bundle
    } = bsd_pi;

    assign tage_pre_read_comb_bsd_pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        tage_pre_read_bundle
    } = tage_pre_read_comb_bsd_po;

    assign bsd_po = {
        tage_pre_read_bundle
    };

    tage_pre_read_comb_bsd_top #(
        .W_TagePreReadCombIn(W_TagePreReadCombIn),
        .W_TagePreReadCombOut(W_TagePreReadCombOut)
    ) u_tage_pre_read_comb_bsd_top (
        .bsd_pi(tage_pre_read_comb_bsd_pi),
        .bsd_po(tage_pre_read_comb_bsd_po)
    );

endmodule

module tage_pre_read_comb_bsd_top #(
    parameter integer W_TagePreReadCombIn  = 64,
    parameter integer W_TagePreReadCombOut = 64
) (
    input  wire [W_TagePreReadCombIn-1:0]  bsd_pi,
    output wire [W_TagePreReadCombOut-1:0] bsd_po
);

    assign bsd_po = {W_TagePreReadCombOut{1'b0}};

endmodule
