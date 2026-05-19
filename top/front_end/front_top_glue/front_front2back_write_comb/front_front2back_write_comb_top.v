// Formal frontend comb boundary: front_front2back_write_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_front2back_write_comb.
// Role: front2back FIFO write and bypass bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_front2back_write_comb_top #(
    parameter integer W_InstructionFifoOut          = 64,
    parameter integer W_PtabOut                     = 64,
    parameter integer W_PredecodeCheckerOut         = 64,
    parameter integer W_Front2BackFifoIn            = 64,
    parameter integer W_Front2BackFifoOut           = 64,
    parameter integer W_FrontFront2backWriteCombIn  = W_InstructionFifoOut + W_PtabOut + W_PredecodeCheckerOut + 1,
    parameter integer W_FrontFront2backWriteCombOut = W_Front2BackFifoIn + W_Front2BackFifoOut
) (
    input  wire [W_FrontFront2backWriteCombIn-1:0]  bsd_pi,
    output wire [W_FrontFront2backWriteCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_InstructionFifoOut-1:0]          instruction_fifo_out;
    wire [W_PtabOut-1:0]                     ptab_out;
    wire [W_PredecodeCheckerOut-1:0]         checker_out;
    wire                                     use_front2back_output_bypass;
    wire [W_Front2BackFifoIn-1:0]            front2back_fifo_in;
    wire [W_Front2BackFifoOut-1:0]           bypass_front2back_fifo_out;
    wire [W_FrontFront2backWriteCombIn-1:0]  front_front2back_write_comb_bsd_pi;
    wire [W_FrontFront2backWriteCombOut-1:0] front_front2back_write_comb_bsd_po;

    assign {
        instruction_fifo_out,
        ptab_out,
        checker_out,
        use_front2back_output_bypass
    } = bsd_pi;

    assign front_front2back_write_comb_bsd_pi = {
        instruction_fifo_out,
        ptab_out,
        checker_out,
        use_front2back_output_bypass
    };

    assign {
        front2back_fifo_in,
        bypass_front2back_fifo_out
    } = front_front2back_write_comb_bsd_po;

    assign bsd_po = {
        front2back_fifo_in,
        bypass_front2back_fifo_out
    };

    front_front2back_write_comb_bsd_top #(
        .W_FrontFront2backWriteCombIn(W_FrontFront2backWriteCombIn),
        .W_FrontFront2backWriteCombOut(W_FrontFront2backWriteCombOut)
    ) u_front_front2back_write_comb_bsd_top (
        .bsd_pi(front_front2back_write_comb_bsd_pi),
        .bsd_po(front_front2back_write_comb_bsd_po)
    );

endmodule

module front_front2back_write_comb_bsd_top #(
    parameter integer W_FrontFront2backWriteCombIn  = 64,
    parameter integer W_FrontFront2backWriteCombOut = 64
) (
    input  wire [W_FrontFront2backWriteCombIn-1:0]  bsd_pi,
    output wire [W_FrontFront2backWriteCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontFront2backWriteCombOut{1'b0}};

endmodule
