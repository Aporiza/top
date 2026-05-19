// Formal frontend comb boundary: predecode_checker_comb.
// Source: simulator-ff/front-end predecode checker comb calculation.
// Role: predecode checker correction generation.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module predecode_checker_comb_top #(
    parameter integer W_PredecodeCheckerIn      = 64,
    parameter integer W_PredecodeCheckerOut     = 64,
    parameter integer W_PredecodeCheckerCombIn  = W_PredecodeCheckerIn,
    parameter integer W_PredecodeCheckerCombOut = W_PredecodeCheckerOut
) (
    input  wire [W_PredecodeCheckerCombIn-1:0]  bsd_pi,
    output wire [W_PredecodeCheckerCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_PredecodeCheckerIn-1:0]      checker_in;
    wire [W_PredecodeCheckerOut-1:0]     checker_out;
    wire [W_PredecodeCheckerCombIn-1:0]  predecode_checker_comb_bsd_pi;
    wire [W_PredecodeCheckerCombOut-1:0] predecode_checker_comb_bsd_po;

    assign {
        checker_in
    } = bsd_pi;

    assign predecode_checker_comb_bsd_pi = {
        checker_in
    };

    assign {
        checker_out
    } = predecode_checker_comb_bsd_po;

    assign bsd_po = {
        checker_out
    };

    predecode_checker_comb_bsd_top #(
        .W_PredecodeCheckerCombIn(W_PredecodeCheckerCombIn),
        .W_PredecodeCheckerCombOut(W_PredecodeCheckerCombOut)
    ) u_predecode_checker_comb_bsd_top (
        .bsd_pi(predecode_checker_comb_bsd_pi),
        .bsd_po(predecode_checker_comb_bsd_po)
    );

endmodule

module predecode_checker_comb_bsd_top #(
    parameter integer W_PredecodeCheckerCombIn  = 64,
    parameter integer W_PredecodeCheckerCombOut = 64
) (
    input  wire [W_PredecodeCheckerCombIn-1:0]  bsd_pi,
    output wire [W_PredecodeCheckerCombOut-1:0] bsd_po
);

    assign bsd_po = {W_PredecodeCheckerCombOut{1'b0}};

endmodule
