// Formal frontend comb boundary: front_ptab_write_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/train_IO.h:352 and front_top.cpp:730,1574-1586.
// Role: PTAB write input assembly.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front_ptab_write_comb_top #(
    parameter integer W_FrontPtabWriteCombIn = 64,
    parameter integer W_FrontPtabWriteCombOut = 64
) (
    input wire [W_FrontPtabWriteCombIn-1:0] front_ptab_write_comb_in,
    output wire [W_FrontPtabWriteCombOut-1:0] front_ptab_write_comb_out
);

    wire [W_FrontPtabWriteCombIn-1:0] front_ptab_write_comb_pi;
    wire [W_FrontPtabWriteCombOut-1:0] front_ptab_write_comb_po;

    assign front_ptab_write_comb_pi = front_ptab_write_comb_in;
    assign front_ptab_write_comb_out = front_ptab_write_comb_po;

    front_ptab_write_comb_bsd_top #(
        .W_FrontPtabWriteCombIn(W_FrontPtabWriteCombIn),
        .W_FrontPtabWriteCombOut(W_FrontPtabWriteCombOut)
    ) u_front_ptab_write_comb_bsd_top (
        .pi(front_ptab_write_comb_pi),
        .po(front_ptab_write_comb_po)
    );

endmodule

module front_ptab_write_comb_bsd_top #(
    parameter integer W_FrontPtabWriteCombIn = 64,
    parameter integer W_FrontPtabWriteCombOut = 64
) (
    input wire [W_FrontPtabWriteCombIn-1:0] pi,
    output wire [W_FrontPtabWriteCombOut-1:0] po
);
    assign po = {W_FrontPtabWriteCombOut{1'b0}};
endmodule
