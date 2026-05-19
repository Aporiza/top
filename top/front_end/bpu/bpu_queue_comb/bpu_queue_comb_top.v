// Formal frontend comb boundary: bpu_queue_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BPU queue update bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module bpu_queue_comb_top #(
    parameter integer W_BpuQueueCombIn  = 64,
    parameter integer W_BpuQueueCombOut = 64
) (
    input  wire [W_BpuQueueCombIn-1:0]  bsd_pi,
    output wire [W_BpuQueueCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuQueueCombIn-1:0]  bpu_predict_main_bundle;
    wire [W_BpuQueueCombOut-1:0] bpu_queue_bundle;
    wire [W_BpuQueueCombIn-1:0]  bpu_queue_comb_bsd_pi;
    wire [W_BpuQueueCombOut-1:0] bpu_queue_comb_bsd_po;

    assign {
        bpu_predict_main_bundle
    } = bsd_pi;

    assign bpu_queue_comb_bsd_pi = {
        bpu_predict_main_bundle
    };

    assign {
        bpu_queue_bundle
    } = bpu_queue_comb_bsd_po;

    assign bsd_po = {
        bpu_queue_bundle
    };

    bpu_queue_comb_bsd_top #(
        .W_BpuQueueCombIn(W_BpuQueueCombIn),
        .W_BpuQueueCombOut(W_BpuQueueCombOut)
    ) u_bpu_queue_comb_bsd_top (
        .bsd_pi(bpu_queue_comb_bsd_pi),
        .bsd_po(bpu_queue_comb_bsd_po)
    );

endmodule

module bpu_queue_comb_bsd_top #(
    parameter integer W_BpuQueueCombIn  = 64,
    parameter integer W_BpuQueueCombOut = 64
) (
    input  wire [W_BpuQueueCombIn-1:0]  bsd_pi,
    output wire [W_BpuQueueCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BpuQueueCombOut{1'b0}};

endmodule
