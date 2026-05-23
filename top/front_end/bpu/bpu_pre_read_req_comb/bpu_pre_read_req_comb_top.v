// Formal frontend comb boundary: bpu_pre_read_req_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: BPU pre-read request bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module bpu_pre_read_req_comb_top #(
    parameter integer W_BpuPreReadReqCombIn  = 2739,  // actual: 2739, from bpu_top W_BpuIn
    parameter integer W_BpuPreReadReqCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuPreReadReqCombIn-1:0]  bpu_input_bundle,
    output wire [W_BpuPreReadReqCombOut-1:0] bpu_pre_read_req_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BpuPreReadReqCombIn-1:0]  pi;
    wire [W_BpuPreReadReqCombOut-1:0] po;
    assign pi = {
        bpu_input_bundle
    };

    assign {
        bpu_pre_read_req_bundle
    } = po;

    bpu_pre_read_req_comb_bsd_top #(
        .W_BpuPreReadReqCombIn(W_BpuPreReadReqCombIn),
        .W_BpuPreReadReqCombOut(W_BpuPreReadReqCombOut)
    ) u_bpu_pre_read_req_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_pre_read_req_comb_bsd_top #(
    parameter integer W_BpuPreReadReqCombIn  = 2739,  // actual: 2739, from bpu_top W_BpuIn
    parameter integer W_BpuPreReadReqCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuPreReadReqCombIn-1:0]  pi,
    output wire [W_BpuPreReadReqCombOut-1:0] po
);

    assign po = {W_BpuPreReadReqCombOut{1'b0}};

endmodule
