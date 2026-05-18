// Formal frontend comb boundary: front_front2back_write_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/train_IO.h:371 and front_top.cpp:785,1652-1684.
// Role: front2back FIFO input assembly.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front_front2back_write_comb_top #(
    parameter integer W_FrontFront2backWriteCombIn = 64,
    parameter integer W_FrontFront2backWriteCombOut = 64
) (
    input wire [W_FrontFront2backWriteCombIn-1:0] front_front2back_write_comb_in,
    output wire [W_FrontFront2backWriteCombOut-1:0] front_front2back_write_comb_out
);

    wire [W_FrontFront2backWriteCombIn-1:0] front_front2back_write_comb_pi;
    wire [W_FrontFront2backWriteCombOut-1:0] front_front2back_write_comb_po;

    assign front_front2back_write_comb_pi = front_front2back_write_comb_in;
    assign front_front2back_write_comb_out = front_front2back_write_comb_po;

    front_front2back_write_comb_bsd_top #(
        .W_FrontFront2backWriteCombIn(W_FrontFront2backWriteCombIn),
        .W_FrontFront2backWriteCombOut(W_FrontFront2backWriteCombOut)
    ) u_front_front2back_write_comb_bsd_top (
        .pi(front_front2back_write_comb_pi),
        .po(front_front2back_write_comb_po)
    );

endmodule

module front_front2back_write_comb_bsd_top #(
    parameter integer W_FrontFront2backWriteCombIn = 64,
    parameter integer W_FrontFront2backWriteCombOut = 64
) (
    input wire [W_FrontFront2backWriteCombIn-1:0] pi,
    output wire [W_FrontFront2backWriteCombOut-1:0] po
);
    assign po = {W_FrontFront2backWriteCombOut{1'b0}};
endmodule
