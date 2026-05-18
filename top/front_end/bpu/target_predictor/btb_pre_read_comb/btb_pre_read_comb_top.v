// Formal frontend comb boundary: btb_pre_read_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/target_predictor/BTB_top.h:675,925.
// Role: BTB pre-read.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module btb_pre_read_comb_top #(
    parameter integer W_BtbPreReadCombIn = 64,
    parameter integer W_BtbPreReadCombOut = 64
) (
    input wire [W_BtbPreReadCombIn-1:0] btb_pre_read_comb_in,
    output wire [W_BtbPreReadCombOut-1:0] btb_pre_read_comb_out
);

    wire [W_BtbPreReadCombIn-1:0] btb_pre_read_comb_pi;
    wire [W_BtbPreReadCombOut-1:0] btb_pre_read_comb_po;

    assign btb_pre_read_comb_pi = btb_pre_read_comb_in;
    assign btb_pre_read_comb_out = btb_pre_read_comb_po;

    btb_pre_read_comb_bsd_top #(
        .W_BtbPreReadCombIn(W_BtbPreReadCombIn),
        .W_BtbPreReadCombOut(W_BtbPreReadCombOut)
    ) u_btb_pre_read_comb_bsd_top (
        .pi(btb_pre_read_comb_pi),
        .po(btb_pre_read_comb_po)
    );

endmodule

module btb_pre_read_comb_bsd_top #(
    parameter integer W_BtbPreReadCombIn = 64,
    parameter integer W_BtbPreReadCombOut = 64
) (
    input wire [W_BtbPreReadCombIn-1:0] pi,
    output wire [W_BtbPreReadCombOut-1:0] po
);
    assign po = {W_BtbPreReadCombOut{1'b0}};
endmodule
