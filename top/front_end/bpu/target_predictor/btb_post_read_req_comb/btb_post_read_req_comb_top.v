// Formal frontend comb boundary: btb_post_read_req_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BTB post-read request bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module btb_post_read_req_comb_top #(
    parameter integer W_BtbPostReadReqCombIn  = 64,
    parameter integer W_BtbPostReadReqCombOut = 64
) (
    input  wire [W_BtbPostReadReqCombIn-1:0]  bsd_pi,
    output wire [W_BtbPostReadReqCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BtbPostReadReqCombIn-1:0]  btb_post_read_req_input_bundle;
    wire [W_BtbPostReadReqCombOut-1:0] btb_post_read_req_bundle;
    wire [W_BtbPostReadReqCombIn-1:0]  btb_post_read_req_comb_bsd_pi;
    wire [W_BtbPostReadReqCombOut-1:0] btb_post_read_req_comb_bsd_po;

    assign {
        btb_post_read_req_input_bundle
    } = bsd_pi;

    assign btb_post_read_req_comb_bsd_pi = {
        btb_post_read_req_input_bundle
    };

    assign {
        btb_post_read_req_bundle
    } = btb_post_read_req_comb_bsd_po;

    assign bsd_po = {
        btb_post_read_req_bundle
    };

    btb_post_read_req_comb_bsd_top #(
        .W_BtbPostReadReqCombIn(W_BtbPostReadReqCombIn),
        .W_BtbPostReadReqCombOut(W_BtbPostReadReqCombOut)
    ) u_btb_post_read_req_comb_bsd_top (
        .bsd_pi(btb_post_read_req_comb_bsd_pi),
        .bsd_po(btb_post_read_req_comb_bsd_po)
    );

endmodule

module btb_post_read_req_comb_bsd_top #(
    parameter integer W_BtbPostReadReqCombIn  = 64,
    parameter integer W_BtbPostReadReqCombOut = 64
) (
    input  wire [W_BtbPostReadReqCombIn-1:0]  bsd_pi,
    output wire [W_BtbPostReadReqCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BtbPostReadReqCombOut{1'b0}};

endmodule
