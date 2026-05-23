// Formal frontend comb boundary: front_front2back_write_comb.
// Source: simulator-front/front-end/front_top.cpp, front_front2back_write_comb.
// Role: front2back FIFO write and bypass bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_front2back_write_comb_top #(
    parameter integer W_InstructionFifoOut          = 1635,  // actual: 1635, from front_top W_InstructionFifoOut
    parameter integer W_PtabOut                     = 4851,  // actual: 4851, from front_top W_PtabOut
    parameter integer W_PredecodeCheckerOut         = 49,  // actual: 49, from front_top W_PredecodeCheckerOut
    parameter integer W_Front2BackFifoIn            = 5396,  // actual: 5396, from front_top W_Front2BackFifoIn
    parameter integer W_Front2BackFifoOut           = 5395,  // actual: 5395, from front_top W_Front2BackFifoOut
    parameter integer W_FrontFront2backWriteCombIn  = W_InstructionFifoOut + W_PtabOut + W_PredecodeCheckerOut + 1,  // actual: 6536, W_InstructionFifoOut + W_PtabOut + W_PredecodeCheckerOut + 1
    parameter integer W_FrontFront2backWriteCombOut = W_Front2BackFifoIn + W_Front2BackFifoOut    // actual: 10791, W_Front2BackFifoIn + W_Front2BackFifoOut
) (
    input  wire [W_InstructionFifoOut-1:0]  instruction_fifo_out,
    input  wire [W_PtabOut-1:0]             ptab_out,
    input  wire [W_PredecodeCheckerOut-1:0] checker_out,
    input  wire                             use_front2back_output_bypass,
    output wire [W_Front2BackFifoIn-1:0]    front2back_fifo_in,
    output wire [W_Front2BackFifoOut-1:0]   bypass_front2back_fifo_out
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontFront2backWriteCombIn-1:0]  pi;
    wire [W_FrontFront2backWriteCombOut-1:0] po;
    assign pi = {
        instruction_fifo_out,
        ptab_out,
        checker_out,
        use_front2back_output_bypass
    };

    assign {
        front2back_fifo_in,
        bypass_front2back_fifo_out
    } = po;

    front_front2back_write_comb_bsd_top #(
        .W_FrontFront2backWriteCombIn(W_FrontFront2backWriteCombIn),
        .W_FrontFront2backWriteCombOut(W_FrontFront2backWriteCombOut)
    ) u_front_front2back_write_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_front2back_write_comb_bsd_top #(
    parameter integer W_FrontFront2backWriteCombIn  = 6536,  // actual: 6536, W_InstructionFifoOut + W_PtabOut + W_PredecodeCheckerOut + 1
    parameter integer W_FrontFront2backWriteCombOut = 10791    // actual: 10791, W_Front2BackFifoIn + W_Front2BackFifoOut
) (
    input  wire [W_FrontFront2backWriteCombIn-1:0]  pi,
    output wire [W_FrontFront2backWriteCombOut-1:0] po
);

    assign po = {W_FrontFront2backWriteCombOut{1'b0}};

endmodule
