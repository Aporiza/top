// Formal frontend comb boundary: bpu_queue_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/BPU.h:1370,1660.
// Role: BPU queue update boundary.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module bpu_queue_comb_top #(
    parameter integer W_BpuQueueCombIn = 64,
    parameter integer W_BpuQueueCombOut = 64
) (
    input wire [W_BpuQueueCombIn-1:0] bpu_queue_comb_in,
    output wire [W_BpuQueueCombOut-1:0] bpu_queue_comb_out
);

    wire [W_BpuQueueCombIn-1:0] bpu_queue_comb_pi;
    wire [W_BpuQueueCombOut-1:0] bpu_queue_comb_po;

    assign bpu_queue_comb_pi = bpu_queue_comb_in;
    assign bpu_queue_comb_out = bpu_queue_comb_po;

    bpu_queue_comb_bsd_top #(
        .W_BpuQueueCombIn(W_BpuQueueCombIn),
        .W_BpuQueueCombOut(W_BpuQueueCombOut)
    ) u_bpu_queue_comb_bsd_top (
        .pi(bpu_queue_comb_pi),
        .po(bpu_queue_comb_po)
    );

endmodule

module bpu_queue_comb_bsd_top #(
    parameter integer W_BpuQueueCombIn = 64,
    parameter integer W_BpuQueueCombOut = 64
) (
    input wire [W_BpuQueueCombIn-1:0] pi,
    output wire [W_BpuQueueCombOut-1:0] po
);
    assign po = {W_BpuQueueCombOut{1'b0}};
endmodule
