// Formal frontend comb boundary: front_checker_input_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_checker_input_comb.
// Role: checker input construction from instruction FIFO and PTAB output.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_checker_input_comb_top #(
    parameter integer W_InstructionFifoOut       = 64,
    parameter integer W_PtabOut                  = 64,
    parameter integer W_PredecodeCheckerIn       = 64,
    parameter integer W_FrontCheckerInputCombIn  = W_InstructionFifoOut + W_PtabOut,
    parameter integer W_FrontCheckerInputCombOut = W_PredecodeCheckerIn
) (
    input  wire [W_FrontCheckerInputCombIn-1:0]  bsd_pi,
    output wire [W_FrontCheckerInputCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_InstructionFifoOut-1:0]       instruction_fifo_out;
    wire [W_PtabOut-1:0]                  ptab_out;
    wire [W_PredecodeCheckerIn-1:0]       checker_in;
    wire [W_FrontCheckerInputCombIn-1:0]  front_checker_input_comb_bsd_pi;
    wire [W_FrontCheckerInputCombOut-1:0] front_checker_input_comb_bsd_po;

    assign {
        instruction_fifo_out,
        ptab_out
    } = bsd_pi;

    assign front_checker_input_comb_bsd_pi = {
        instruction_fifo_out,
        ptab_out
    };

    assign {
        checker_in
    } = front_checker_input_comb_bsd_po;

    assign bsd_po = {
        checker_in
    };

    front_checker_input_comb_bsd_top #(
        .W_FrontCheckerInputCombIn(W_FrontCheckerInputCombIn),
        .W_FrontCheckerInputCombOut(W_FrontCheckerInputCombOut)
    ) u_front_checker_input_comb_bsd_top (
        .bsd_pi(front_checker_input_comb_bsd_pi),
        .bsd_po(front_checker_input_comb_bsd_po)
    );

endmodule

module front_checker_input_comb_bsd_top #(
    parameter integer W_FrontCheckerInputCombIn  = 64,
    parameter integer W_FrontCheckerInputCombOut = 64
) (
    input  wire [W_FrontCheckerInputCombIn-1:0]  bsd_pi,
    output wire [W_FrontCheckerInputCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontCheckerInputCombOut{1'b0}};

endmodule
