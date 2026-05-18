// Formal frontend comb boundary: btb_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/target_predictor/BTB_top.h:711,940.
// Role: BTB target prediction.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module btb_comb_top #(
    parameter integer W_BtbCombIn = 64,
    parameter integer W_BtbCombOut = 64
) (
    input wire [W_BtbCombIn-1:0] btb_comb_in,
    output wire [W_BtbCombOut-1:0] btb_comb_out
);

    wire [W_BtbCombIn-1:0] btb_comb_pi;
    wire [W_BtbCombOut-1:0] btb_comb_po;

    assign btb_comb_pi = btb_comb_in;
    assign btb_comb_out = btb_comb_po;

    btb_comb_bsd_top #(
        .W_BtbCombIn(W_BtbCombIn),
        .W_BtbCombOut(W_BtbCombOut)
    ) u_btb_comb_bsd_top (
        .pi(btb_comb_pi),
        .po(btb_comb_po)
    );

endmodule

module btb_comb_bsd_top #(
    parameter integer W_BtbCombIn = 64,
    parameter integer W_BtbCombOut = 64
) (
    input wire [W_BtbCombIn-1:0] pi,
    output wire [W_BtbCombOut-1:0] po
);
    assign po = {W_BtbCombOut{1'b0}};
endmodule
