// Formal frontend comb boundary: btb_post_read_req_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/target_predictor/BTB_top.h:682,929.
// Role: BTB post-read request.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module btb_post_read_req_comb_top #(
    parameter integer W_BtbPostReadReqCombIn = 64,
    parameter integer W_BtbPostReadReqCombOut = 64
) (
    input wire [W_BtbPostReadReqCombIn-1:0] btb_post_read_req_comb_in,
    output wire [W_BtbPostReadReqCombOut-1:0] btb_post_read_req_comb_out
);

    wire [W_BtbPostReadReqCombIn-1:0] btb_post_read_req_comb_pi;
    wire [W_BtbPostReadReqCombOut-1:0] btb_post_read_req_comb_po;

    assign btb_post_read_req_comb_pi = btb_post_read_req_comb_in;
    assign btb_post_read_req_comb_out = btb_post_read_req_comb_po;

    btb_post_read_req_comb_bsd_top #(
        .W_BtbPostReadReqCombIn(W_BtbPostReadReqCombIn),
        .W_BtbPostReadReqCombOut(W_BtbPostReadReqCombOut)
    ) u_btb_post_read_req_comb_bsd_top (
        .pi(btb_post_read_req_comb_pi),
        .po(btb_post_read_req_comb_po)
    );

endmodule

module btb_post_read_req_comb_bsd_top #(
    parameter integer W_BtbPostReadReqCombIn = 64,
    parameter integer W_BtbPostReadReqCombOut = 64
) (
    input wire [W_BtbPostReadReqCombIn-1:0] pi,
    output wire [W_BtbPostReadReqCombOut-1:0] po
);
    assign po = {W_BtbPostReadReqCombOut{1'b0}};
endmodule
