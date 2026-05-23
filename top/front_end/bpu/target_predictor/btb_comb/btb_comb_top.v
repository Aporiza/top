// Formal frontend comb boundary: btb_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: BTB target result bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module btb_comb_top #(
    parameter integer W_BtbCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BtbCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BtbCombIn-1:0]  btb_post_read_req_bundle,
    output wire [W_BtbCombOut-1:0] btb_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BtbCombIn-1:0]  pi;
    wire [W_BtbCombOut-1:0] po;
    assign pi = {
        btb_post_read_req_bundle
    };

    assign {
        btb_bundle
    } = po;

    btb_comb_bsd_top #(
        .W_BtbCombIn(W_BtbCombIn),
        .W_BtbCombOut(W_BtbCombOut)
    ) u_btb_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module btb_comb_bsd_top #(
    parameter integer W_BtbCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BtbCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BtbCombIn-1:0]  pi,
    output wire [W_BtbCombOut-1:0] po
);

    assign po = {W_BtbCombOut{1'b0}};

endmodule
