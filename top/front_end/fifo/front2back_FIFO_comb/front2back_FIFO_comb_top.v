// Formal frontend comb boundary: front2back_FIFO_comb.
// Source: simulator-ff/front-end front2back FIFO comb calculation.
// Role: front2back FIFO combinational update.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front2back_FIFO_comb_top #(
    parameter integer W_Front2BackFifoIn      = 64,
    parameter integer W_Front2BackFifoOut     = 64,
    parameter integer W_Front2BackCombOut     = 64,
    parameter integer W_Front2backFifoCombIn  = W_Front2BackFifoIn + W_Front2BackFifoOut,
    parameter integer W_Front2backFifoCombOut = W_Front2BackCombOut
) (
    input  wire [W_Front2backFifoCombIn-1:0]  bsd_pi,
    output wire [W_Front2backFifoCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_Front2BackFifoIn-1:0]      front2back_fifo_in;
    wire [W_Front2BackFifoOut-1:0]     front2back_fifo_rd;
    wire [W_Front2BackCombOut-1:0]     front2back_fifo_req;
    wire [W_Front2backFifoCombIn-1:0]  front2back_FIFO_comb_bsd_pi;
    wire [W_Front2backFifoCombOut-1:0] front2back_FIFO_comb_bsd_po;

    assign {
        front2back_fifo_in,
        front2back_fifo_rd
    } = bsd_pi;

    assign front2back_FIFO_comb_bsd_pi = {
        front2back_fifo_in,
        front2back_fifo_rd
    };

    assign {
        front2back_fifo_req
    } = front2back_FIFO_comb_bsd_po;

    assign bsd_po = {
        front2back_fifo_req
    };

    front2back_FIFO_comb_bsd_top #(
        .W_Front2backFifoCombIn(W_Front2backFifoCombIn),
        .W_Front2backFifoCombOut(W_Front2backFifoCombOut)
    ) u_front2back_FIFO_comb_bsd_top (
        .bsd_pi(front2back_FIFO_comb_bsd_pi),
        .bsd_po(front2back_FIFO_comb_bsd_po)
    );

endmodule

module front2back_FIFO_comb_bsd_top #(
    parameter integer W_Front2backFifoCombIn  = 64,
    parameter integer W_Front2backFifoCombOut = 64
) (
    input  wire [W_Front2backFifoCombIn-1:0]  bsd_pi,
    output wire [W_Front2backFifoCombOut-1:0] bsd_po
);

    assign bsd_po = {W_Front2backFifoCombOut{1'b0}};

endmodule
