// Formal frontend comb boundary: btb_pre_read_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: BTB pre-read bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module btb_pre_read_comb_top #(
    parameter integer W_BtbPreReadCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BtbPreReadCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BtbPreReadCombIn-1:0]  bpu_pre_read_req_bundle,
    output wire [W_BtbPreReadCombOut-1:0] btb_pre_read_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BtbPreReadCombIn-1:0]  pi;
    wire [W_BtbPreReadCombOut-1:0] po;
    assign pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        btb_pre_read_bundle
    } = po;

    btb_pre_read_comb_bsd_top #(
        .W_BtbPreReadCombIn(W_BtbPreReadCombIn),
        .W_BtbPreReadCombOut(W_BtbPreReadCombOut)
    ) u_btb_pre_read_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module btb_pre_read_comb_bsd_top #(
    parameter integer W_BtbPreReadCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BtbPreReadCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BtbPreReadCombIn-1:0]  pi,
    output wire [W_BtbPreReadCombOut-1:0] po
);

    assign po = {W_BtbPreReadCombOut{1'b0}};

endmodule
