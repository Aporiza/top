// Formal frontend comb boundary: tage_pre_read_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/dir_predictor/TAGE_top.h:933,1482.
// Role: TAGE pre-read.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module tage_pre_read_comb_top #(
    parameter integer W_TagePreReadCombIn = 64,
    parameter integer W_TagePreReadCombOut = 64
) (
    input wire [W_TagePreReadCombIn-1:0] tage_pre_read_comb_in,
    output wire [W_TagePreReadCombOut-1:0] tage_pre_read_comb_out
);

    wire [W_TagePreReadCombIn-1:0] tage_pre_read_comb_pi;
    wire [W_TagePreReadCombOut-1:0] tage_pre_read_comb_po;

    assign tage_pre_read_comb_pi = tage_pre_read_comb_in;
    assign tage_pre_read_comb_out = tage_pre_read_comb_po;

    tage_pre_read_comb_bsd_top #(
        .W_TagePreReadCombIn(W_TagePreReadCombIn),
        .W_TagePreReadCombOut(W_TagePreReadCombOut)
    ) u_tage_pre_read_comb_bsd_top (
        .pi(tage_pre_read_comb_pi),
        .po(tage_pre_read_comb_po)
    );

endmodule

module tage_pre_read_comb_bsd_top #(
    parameter integer W_TagePreReadCombIn = 64,
    parameter integer W_TagePreReadCombOut = 64
) (
    input wire [W_TagePreReadCombIn-1:0] pi,
    output wire [W_TagePreReadCombOut-1:0] po
);
    assign po = {W_TagePreReadCombOut{1'b0}};
endmodule
