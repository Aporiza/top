// Formal frontend comb boundary: predecode_checker_comb.
// Source: simulator-front/front-end predecode checker comb calculation.
// Role: predecode checker correction generation.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module predecode_checker_comb_top #(
    parameter integer W_PredecodeCheckerIn      = 624,  // actual: 624, from front_top W_PredecodeCheckerIn
    parameter integer W_PredecodeCheckerOut     = 49,  // actual: 49, from front_top W_PredecodeCheckerOut
    parameter integer W_PredecodeCheckerCombIn  = W_PredecodeCheckerIn,  // actual: 624, W_PredecodeCheckerIn
    parameter integer W_PredecodeCheckerCombOut = W_PredecodeCheckerOut    // actual: 49, W_PredecodeCheckerOut
) (
    input  wire [W_PredecodeCheckerIn-1:0]  checker_in,
    output wire [W_PredecodeCheckerOut-1:0] checker_out
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_PredecodeCheckerCombIn-1:0]  pi;
    wire [W_PredecodeCheckerCombOut-1:0] po;
    assign pi = {
        checker_in
    };

    assign {
        checker_out
    } = po;

    predecode_checker_comb_bsd_top #(
        .W_PredecodeCheckerCombIn(W_PredecodeCheckerCombIn),
        .W_PredecodeCheckerCombOut(W_PredecodeCheckerCombOut)
    ) u_predecode_checker_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module predecode_checker_comb_bsd_top #(
    parameter integer W_PredecodeCheckerCombIn  = 624,  // actual: 624, W_PredecodeCheckerIn
    parameter integer W_PredecodeCheckerCombOut = 49    // actual: 49, W_PredecodeCheckerOut
) (
    input  wire [W_PredecodeCheckerCombIn-1:0]  pi,
    output wire [W_PredecodeCheckerCombOut-1:0] po
);

    assign po = {W_PredecodeCheckerCombOut{1'b0}};

endmodule
