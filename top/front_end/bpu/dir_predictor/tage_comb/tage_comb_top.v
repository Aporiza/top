// Formal frontend comb boundary: tage_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/dir_predictor/TAGE_top.h:948,1497.
// Role: TAGE comb.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module tage_comb_top #(
    parameter integer W_TageCombIn = 64,
    parameter integer W_TageCombOut = 64
) (
    input wire [W_TageCombIn-1:0] tage_comb_in,
    output wire [W_TageCombOut-1:0] tage_comb_out
);

    wire [W_TageCombIn-1:0] tage_comb_pi;
    wire [W_TageCombOut-1:0] tage_comb_po;

    assign tage_comb_pi = tage_comb_in;
    assign tage_comb_out = tage_comb_po;

    tage_comb_bsd_top #(
        .W_TageCombIn(W_TageCombIn),
        .W_TageCombOut(W_TageCombOut)
    ) u_tage_comb_bsd_top (
        .pi(tage_comb_pi),
        .po(tage_comb_po)
    );

endmodule

module tage_comb_bsd_top #(
    parameter integer W_TageCombIn = 64,
    parameter integer W_TageCombOut = 64
) (
    input wire [W_TageCombIn-1:0] pi,
    output wire [W_TageCombOut-1:0] po
);
    assign po = {W_TageCombOut{1'b0}};
endmodule
