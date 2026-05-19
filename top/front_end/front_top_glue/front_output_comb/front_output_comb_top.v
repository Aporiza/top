// Formal frontend comb boundary: front_output_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_output_comb.
// Role: final frontend output selection.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_output_comb_top #(
    parameter integer W_Front2BackFifoOut  = 64,
    parameter integer W_FrontTopOut        = 64,
    parameter integer W_FrontOutputCombIn  = W_Front2BackFifoOut + W_Front2BackFifoOut + 1,
    parameter integer W_FrontOutputCombOut = W_FrontTopOut
) (
    input  wire [W_FrontOutputCombIn-1:0]  bsd_pi,
    output wire [W_FrontOutputCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_Front2BackFifoOut-1:0]  front2back_fifo_out;
    wire [W_Front2BackFifoOut-1:0]  bypass_front2back_fifo_out;
    wire                            use_front2back_output_bypass;
    wire [W_FrontTopOut-1:0]        front_top_out_bus;
    wire [W_FrontOutputCombIn-1:0]  front_output_comb_bsd_pi;
    wire [W_FrontOutputCombOut-1:0] front_output_comb_bsd_po;

    assign {
        front2back_fifo_out,
        bypass_front2back_fifo_out,
        use_front2back_output_bypass
    } = bsd_pi;

    assign front_output_comb_bsd_pi = {
        front2back_fifo_out,
        bypass_front2back_fifo_out,
        use_front2back_output_bypass
    };

    assign {
        front_top_out_bus
    } = front_output_comb_bsd_po;

    assign bsd_po = {
        front_top_out_bus
    };

    front_output_comb_bsd_top #(
        .W_FrontOutputCombIn(W_FrontOutputCombIn),
        .W_FrontOutputCombOut(W_FrontOutputCombOut)
    ) u_front_output_comb_bsd_top (
        .bsd_pi(front_output_comb_bsd_pi),
        .bsd_po(front_output_comb_bsd_po)
    );

endmodule

module front_output_comb_bsd_top #(
    parameter integer W_FrontOutputCombIn  = 64,
    parameter integer W_FrontOutputCombOut = 64
) (
    input  wire [W_FrontOutputCombIn-1:0]  bsd_pi,
    output wire [W_FrontOutputCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontOutputCombOut{1'b0}};

endmodule
