// Formal frontend comb boundary: tage_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: TAGE direction result bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module tage_comb_top #(
    parameter integer W_TageCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_TageCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_TageCombIn-1:0]  tage_input_bundle,
    output wire [W_TageCombOut-1:0] tage_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_TageCombIn-1:0]  pi;
    wire [W_TageCombOut-1:0] po;
    assign pi = {
        tage_input_bundle
    };

    assign {
        tage_bundle
    } = po;

    tage_comb_bsd_top #(
        .W_TageCombIn(W_TageCombIn),
        .W_TageCombOut(W_TageCombOut)
    ) u_tage_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module tage_comb_bsd_top #(
    parameter integer W_TageCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_TageCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_TageCombIn-1:0]  pi,
    output wire [W_TageCombOut-1:0] po
);

    assign po = {W_TageCombOut{1'b0}};

endmodule
