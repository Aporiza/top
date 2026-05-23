// Formal frontend comb boundary: front_output_comb.
// Source: simulator-front/front-end/front_top.cpp, front_output_comb.
// Role: final frontend output selection.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_output_comb_top #(
    parameter integer W_Front2BackFifoOut  = 5395,  // actual: 5395, from front_top W_Front2BackFifoOut
    parameter integer W_FrontTopOut        = 5393,  // actual: 5393, from front_top W_FrontTopOut
    parameter integer W_FrontOutputCombIn  = W_Front2BackFifoOut + W_Front2BackFifoOut + 1,  // actual: 10791, W_Front2BackFifoOut + W_Front2BackFifoOut + 1
    parameter integer W_FrontOutputCombOut = W_FrontTopOut    // actual: 5393, W_FrontTopOut
) (
    input  wire [W_Front2BackFifoOut-1:0] front2back_fifo_out,
    input  wire [W_Front2BackFifoOut-1:0] bypass_front2back_fifo_out,
    input  wire                           use_front2back_output_bypass,
    output wire [W_FrontTopOut-1:0]       front_top_out_bus
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontOutputCombIn-1:0]  pi;
    wire [W_FrontOutputCombOut-1:0] po;
    assign pi = {
        front2back_fifo_out,
        bypass_front2back_fifo_out,
        use_front2back_output_bypass
    };

    assign {
        front_top_out_bus
    } = po;

    front_output_comb_bsd_top #(
        .W_FrontOutputCombIn(W_FrontOutputCombIn),
        .W_FrontOutputCombOut(W_FrontOutputCombOut)
    ) u_front_output_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_output_comb_bsd_top #(
    parameter integer W_FrontOutputCombIn  = 10791,  // actual: 10791, W_Front2BackFifoOut + W_Front2BackFifoOut + 1
    parameter integer W_FrontOutputCombOut = 5393    // actual: 5393, W_FrontTopOut
) (
    input  wire [W_FrontOutputCombIn-1:0]  pi,
    output wire [W_FrontOutputCombOut-1:0] po
);

    assign po = {W_FrontOutputCombOut{1'b0}};

endmodule
