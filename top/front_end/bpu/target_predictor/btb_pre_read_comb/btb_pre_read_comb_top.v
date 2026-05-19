// Formal frontend comb boundary: btb_pre_read_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BTB pre-read bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module btb_pre_read_comb_top #(
    parameter integer W_BtbPreReadCombIn  = 64,
    parameter integer W_BtbPreReadCombOut = 64
) (
    input  wire [W_BtbPreReadCombIn-1:0]  bsd_pi,
    output wire [W_BtbPreReadCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BtbPreReadCombIn-1:0]  bpu_pre_read_req_bundle;
    wire [W_BtbPreReadCombOut-1:0] btb_pre_read_bundle;
    wire [W_BtbPreReadCombIn-1:0]  btb_pre_read_comb_bsd_pi;
    wire [W_BtbPreReadCombOut-1:0] btb_pre_read_comb_bsd_po;

    assign {
        bpu_pre_read_req_bundle
    } = bsd_pi;

    assign btb_pre_read_comb_bsd_pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        btb_pre_read_bundle
    } = btb_pre_read_comb_bsd_po;

    assign bsd_po = {
        btb_pre_read_bundle
    };

    btb_pre_read_comb_bsd_top #(
        .W_BtbPreReadCombIn(W_BtbPreReadCombIn),
        .W_BtbPreReadCombOut(W_BtbPreReadCombOut)
    ) u_btb_pre_read_comb_bsd_top (
        .bsd_pi(btb_pre_read_comb_bsd_pi),
        .bsd_po(btb_pre_read_comb_bsd_po)
    );

endmodule

module btb_pre_read_comb_bsd_top #(
    parameter integer W_BtbPreReadCombIn  = 64,
    parameter integer W_BtbPreReadCombOut = 64
) (
    input  wire [W_BtbPreReadCombIn-1:0]  bsd_pi,
    output wire [W_BtbPreReadCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BtbPreReadCombOut{1'b0}};

endmodule
