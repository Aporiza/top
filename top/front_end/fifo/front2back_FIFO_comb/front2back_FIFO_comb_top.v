// Formal frontend comb boundary: front2back_FIFO_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/fifo/front2bank_FIFO.cpp:195.
// Role: front2back FIFO comb.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front2back_FIFO_comb_top #(
    parameter integer W_Front2backFifoCombIn = 64,
    parameter integer W_Front2backFifoCombOut = 64
) (
    input wire [W_Front2backFifoCombIn-1:0] front2back_FIFO_comb_in,
    output wire [W_Front2backFifoCombOut-1:0] front2back_FIFO_comb_out
);

    wire [W_Front2backFifoCombIn-1:0] front2back_FIFO_comb_pi;
    wire [W_Front2backFifoCombOut-1:0] front2back_FIFO_comb_po;

    assign front2back_FIFO_comb_pi = front2back_FIFO_comb_in;
    assign front2back_FIFO_comb_out = front2back_FIFO_comb_po;

    front2back_FIFO_comb_bsd_top #(
        .W_Front2backFifoCombIn(W_Front2backFifoCombIn),
        .W_Front2backFifoCombOut(W_Front2backFifoCombOut)
    ) u_front2back_FIFO_comb_bsd_top (
        .pi(front2back_FIFO_comb_pi),
        .po(front2back_FIFO_comb_po)
    );

endmodule

module front2back_FIFO_comb_bsd_top #(
    parameter integer W_Front2backFifoCombIn = 64,
    parameter integer W_Front2backFifoCombOut = 64
) (
    input wire [W_Front2backFifoCombIn-1:0] pi,
    output wire [W_Front2backFifoCombOut-1:0] po
);
    assign po = {W_Front2backFifoCombOut{1'b0}};
endmodule
