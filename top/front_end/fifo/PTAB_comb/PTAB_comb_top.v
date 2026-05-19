// Formal frontend comb boundary: PTAB_comb.
// Source: simulator-ff/front-end PTAB comb calculation.
// Role: PTAB combinational update.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module PTAB_comb_top #(
    parameter integer W_PtabIn      = 64,
    parameter integer W_PtabOut     = 64,
    parameter integer W_PtabCombIn  = W_PtabIn + W_PtabOut,
    parameter integer W_PtabCombOut = 64
) (
    input  wire [W_PtabCombIn-1:0]  bsd_pi,
    output wire [W_PtabCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_PtabIn-1:0]      ptab_in;
    wire [W_PtabOut-1:0]     ptab_rd;
    wire [W_PtabCombOut-1:0] ptab_req;
    wire [W_PtabCombIn-1:0]  PTAB_comb_bsd_pi;
    wire [W_PtabCombOut-1:0] PTAB_comb_bsd_po;

    assign {
        ptab_in,
        ptab_rd
    } = bsd_pi;

    assign PTAB_comb_bsd_pi = {
        ptab_in,
        ptab_rd
    };

    assign {
        ptab_req
    } = PTAB_comb_bsd_po;

    assign bsd_po = {
        ptab_req
    };

    PTAB_comb_bsd_top #(
        .W_PtabCombIn(W_PtabCombIn),
        .W_PtabCombOut(W_PtabCombOut)
    ) u_PTAB_comb_bsd_top (
        .bsd_pi(PTAB_comb_bsd_pi),
        .bsd_po(PTAB_comb_bsd_po)
    );

endmodule

module PTAB_comb_bsd_top #(
    parameter integer W_PtabCombIn  = 64,
    parameter integer W_PtabCombOut = 64
) (
    input  wire [W_PtabCombIn-1:0]  bsd_pi,
    output wire [W_PtabCombOut-1:0] bsd_po
);

    assign bsd_po = {W_PtabCombOut{1'b0}};

endmodule
