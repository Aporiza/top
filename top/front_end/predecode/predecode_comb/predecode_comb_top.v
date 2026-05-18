// Formal frontend comb boundary: predecode_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/predecode.cpp:16.
// Role: predecode comb.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module predecode_comb_top #(
    parameter integer W_PredecodeCombIn = 64,
    parameter integer W_PredecodeCombOut = 64
) (
    input wire [W_PredecodeCombIn-1:0] predecode_comb_in,
    output wire [W_PredecodeCombOut-1:0] predecode_comb_out
);

    wire [W_PredecodeCombIn-1:0] predecode_comb_pi;
    wire [W_PredecodeCombOut-1:0] predecode_comb_po;

    assign predecode_comb_pi = predecode_comb_in;
    assign predecode_comb_out = predecode_comb_po;

    predecode_comb_bsd_top #(
        .W_PredecodeCombIn(W_PredecodeCombIn),
        .W_PredecodeCombOut(W_PredecodeCombOut)
    ) u_predecode_comb_bsd_top (
        .pi(predecode_comb_pi),
        .po(predecode_comb_po)
    );

endmodule

module predecode_comb_bsd_top #(
    parameter integer W_PredecodeCombIn = 64,
    parameter integer W_PredecodeCombOut = 64
) (
    input wire [W_PredecodeCombIn-1:0] pi,
    output wire [W_PredecodeCombOut-1:0] po
);
    assign po = {W_PredecodeCombOut{1'b0}};
endmodule
