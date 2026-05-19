// Formal frontend comb boundary: btb_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BTB target result bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module btb_comb_top #(
    parameter integer W_BtbCombIn  = 64,
    parameter integer W_BtbCombOut = 64
) (
    input  wire [W_BtbCombIn-1:0]  bsd_pi,
    output wire [W_BtbCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BtbCombIn-1:0]  btb_post_read_req_bundle;
    wire [W_BtbCombOut-1:0] btb_bundle;
    wire [W_BtbCombIn-1:0]  btb_comb_bsd_pi;
    wire [W_BtbCombOut-1:0] btb_comb_bsd_po;

    assign {
        btb_post_read_req_bundle
    } = bsd_pi;

    assign btb_comb_bsd_pi = {
        btb_post_read_req_bundle
    };

    assign {
        btb_bundle
    } = btb_comb_bsd_po;

    assign bsd_po = {
        btb_bundle
    };

    btb_comb_bsd_top #(
        .W_BtbCombIn(W_BtbCombIn),
        .W_BtbCombOut(W_BtbCombOut)
    ) u_btb_comb_bsd_top (
        .bsd_pi(btb_comb_bsd_pi),
        .bsd_po(btb_comb_bsd_po)
    );

endmodule

module btb_comb_bsd_top #(
    parameter integer W_BtbCombIn  = 64,
    parameter integer W_BtbCombOut = 64
) (
    input  wire [W_BtbCombIn-1:0]  bsd_pi,
    output wire [W_BtbCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BtbCombOut{1'b0}};

endmodule
