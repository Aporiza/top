// Formal frontend comb boundary: PTAB_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/fifo/PTAB.cpp:212.
// Role: PTAB comb.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module PTAB_comb_top #(
    parameter integer W_PtabCombIn = 64,
    parameter integer W_PtabCombOut = 64
) (
    input wire [W_PtabCombIn-1:0] PTAB_comb_in,
    output wire [W_PtabCombOut-1:0] PTAB_comb_out
);

    wire [W_PtabCombIn-1:0] PTAB_comb_pi;
    wire [W_PtabCombOut-1:0] PTAB_comb_po;

    assign PTAB_comb_pi = PTAB_comb_in;
    assign PTAB_comb_out = PTAB_comb_po;

    PTAB_comb_bsd_top #(
        .W_PtabCombIn(W_PtabCombIn),
        .W_PtabCombOut(W_PtabCombOut)
    ) u_PTAB_comb_bsd_top (
        .pi(PTAB_comb_pi),
        .po(PTAB_comb_po)
    );

endmodule

module PTAB_comb_bsd_top #(
    parameter integer W_PtabCombIn = 64,
    parameter integer W_PtabCombOut = 64
) (
    input wire [W_PtabCombIn-1:0] pi,
    output wire [W_PtabCombOut-1:0] po
);
    assign po = {W_PtabCombOut{1'b0}};
endmodule
