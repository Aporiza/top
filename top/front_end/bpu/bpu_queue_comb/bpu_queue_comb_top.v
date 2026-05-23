// Formal frontend comb boundary: bpu_queue_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: BPU queue update bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module bpu_queue_comb_top #(
    parameter integer W_BpuQueueCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuQueueCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuQueueCombIn-1:0]  bpu_predict_main_bundle,
    output wire [W_BpuQueueCombOut-1:0] bpu_queue_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BpuQueueCombIn-1:0]  pi;
    wire [W_BpuQueueCombOut-1:0] po;
    assign pi = {
        bpu_predict_main_bundle
    };

    assign {
        bpu_queue_bundle
    } = po;

    bpu_queue_comb_bsd_top #(
        .W_BpuQueueCombIn(W_BpuQueueCombIn),
        .W_BpuQueueCombOut(W_BpuQueueCombOut)
    ) u_bpu_queue_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_queue_comb_bsd_top #(
    parameter integer W_BpuQueueCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuQueueCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuQueueCombIn-1:0]  pi,
    output wire [W_BpuQueueCombOut-1:0] po
);

    assign po = {W_BpuQueueCombOut{1'b0}};

endmodule
