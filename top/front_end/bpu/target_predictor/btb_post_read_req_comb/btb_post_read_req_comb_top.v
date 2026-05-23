// Formal frontend comb boundary: btb_post_read_req_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: BTB post-read request bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module btb_post_read_req_comb_top #(
    parameter integer W_BtbPostReadReqCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BtbPostReadReqCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BtbPostReadReqCombIn-1:0]  btb_post_read_req_input_bundle,
    output wire [W_BtbPostReadReqCombOut-1:0] btb_post_read_req_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BtbPostReadReqCombIn-1:0]  pi;
    wire [W_BtbPostReadReqCombOut-1:0] po;
    assign pi = {
        btb_post_read_req_input_bundle
    };

    assign {
        btb_post_read_req_bundle
    } = po;

    btb_post_read_req_comb_bsd_top #(
        .W_BtbPostReadReqCombIn(W_BtbPostReadReqCombIn),
        .W_BtbPostReadReqCombOut(W_BtbPostReadReqCombOut)
    ) u_btb_post_read_req_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module btb_post_read_req_comb_bsd_top #(
    parameter integer W_BtbPostReadReqCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BtbPostReadReqCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BtbPostReadReqCombIn-1:0]  pi,
    output wire [W_BtbPostReadReqCombOut-1:0] po
);

    assign po = {W_BtbPostReadReqCombOut{1'b0}};

endmodule
