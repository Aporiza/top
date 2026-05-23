// Formal frontend comb boundary: front_checker_input_comb.
// Source: simulator-front/front-end/front_top.cpp, front_checker_input_comb.
// Role: checker input construction from instruction FIFO and PTAB output.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_checker_input_comb_top #(
    parameter integer W_InstructionFifoOut       = 1635,  // actual: 1635, from front_top W_InstructionFifoOut
    parameter integer W_PtabOut                  = 4851,  // actual: 4851, from front_top W_PtabOut
    parameter integer W_PredecodeCheckerIn       = 624,  // actual: 624, from front_top W_PredecodeCheckerIn
    parameter integer W_FrontCheckerInputCombIn  = W_InstructionFifoOut + W_PtabOut,  // actual: 6486, W_InstructionFifoOut + W_PtabOut
    parameter integer W_FrontCheckerInputCombOut = W_PredecodeCheckerIn    // actual: 624, W_PredecodeCheckerIn
) (
    input  wire [W_InstructionFifoOut-1:0] instruction_fifo_out,
    input  wire [W_PtabOut-1:0]            ptab_out,
    output wire [W_PredecodeCheckerIn-1:0] checker_in
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontCheckerInputCombIn-1:0]  pi;
    wire [W_FrontCheckerInputCombOut-1:0] po;
    assign pi = {
        instruction_fifo_out,
        ptab_out
    };

    assign {
        checker_in
    } = po;

    front_checker_input_comb_bsd_top #(
        .W_FrontCheckerInputCombIn(W_FrontCheckerInputCombIn),
        .W_FrontCheckerInputCombOut(W_FrontCheckerInputCombOut)
    ) u_front_checker_input_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_checker_input_comb_bsd_top #(
    parameter integer W_FrontCheckerInputCombIn  = 6486,  // actual: 6486, W_InstructionFifoOut + W_PtabOut
    parameter integer W_FrontCheckerInputCombOut = 624    // actual: 624, W_PredecodeCheckerIn
) (
    input  wire [W_FrontCheckerInputCombIn-1:0]  pi,
    output wire [W_FrontCheckerInputCombOut-1:0] po
);

    assign po = {W_FrontCheckerInputCombOut{1'b0}};

endmodule
