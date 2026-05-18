// Formal frontend comb boundary: predecode_checker_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/predecode_checker.cpp:16.
// Role: checker comb.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module predecode_checker_comb_top #(
    parameter integer W_PredecodeCheckerCombIn = 64,
    parameter integer W_PredecodeCheckerCombOut = 64
) (
    input wire [W_PredecodeCheckerCombIn-1:0] predecode_checker_comb_in,
    output wire [W_PredecodeCheckerCombOut-1:0] predecode_checker_comb_out
);

    wire [W_PredecodeCheckerCombIn-1:0] predecode_checker_comb_pi;
    wire [W_PredecodeCheckerCombOut-1:0] predecode_checker_comb_po;

    assign predecode_checker_comb_pi = predecode_checker_comb_in;
    assign predecode_checker_comb_out = predecode_checker_comb_po;

    predecode_checker_comb_bsd_top #(
        .W_PredecodeCheckerCombIn(W_PredecodeCheckerCombIn),
        .W_PredecodeCheckerCombOut(W_PredecodeCheckerCombOut)
    ) u_predecode_checker_comb_bsd_top (
        .pi(predecode_checker_comb_pi),
        .po(predecode_checker_comb_po)
    );

endmodule

module predecode_checker_comb_bsd_top #(
    parameter integer W_PredecodeCheckerCombIn = 64,
    parameter integer W_PredecodeCheckerCombOut = 64
) (
    input wire [W_PredecodeCheckerCombIn-1:0] pi,
    output wire [W_PredecodeCheckerCombOut-1:0] po
);
    assign po = {W_PredecodeCheckerCombOut{1'b0}};
endmodule
