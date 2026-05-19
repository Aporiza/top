// Formal frontend comb boundary: bpu_pre_read_req_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BPU pre-read request bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module bpu_pre_read_req_comb_top #(
    parameter integer W_BpuPreReadReqCombIn  = 64,
    parameter integer W_BpuPreReadReqCombOut = 64
) (
    input  wire [W_BpuPreReadReqCombIn-1:0]  bsd_pi,
    output wire [W_BpuPreReadReqCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuPreReadReqCombIn-1:0]  bpu_input_bundle;
    wire [W_BpuPreReadReqCombOut-1:0] bpu_pre_read_req_bundle;
    wire [W_BpuPreReadReqCombIn-1:0]  bpu_pre_read_req_comb_bsd_pi;
    wire [W_BpuPreReadReqCombOut-1:0] bpu_pre_read_req_comb_bsd_po;

    assign {
        bpu_input_bundle
    } = bsd_pi;

    assign bpu_pre_read_req_comb_bsd_pi = {
        bpu_input_bundle
    };

    assign {
        bpu_pre_read_req_bundle
    } = bpu_pre_read_req_comb_bsd_po;

    assign bsd_po = {
        bpu_pre_read_req_bundle
    };

    bpu_pre_read_req_comb_bsd_top #(
        .W_BpuPreReadReqCombIn(W_BpuPreReadReqCombIn),
        .W_BpuPreReadReqCombOut(W_BpuPreReadReqCombOut)
    ) u_bpu_pre_read_req_comb_bsd_top (
        .bsd_pi(bpu_pre_read_req_comb_bsd_pi),
        .bsd_po(bpu_pre_read_req_comb_bsd_po)
    );

endmodule

module bpu_pre_read_req_comb_bsd_top #(
    parameter integer W_BpuPreReadReqCombIn  = 64,
    parameter integer W_BpuPreReadReqCombOut = 64
) (
    input  wire [W_BpuPreReadReqCombIn-1:0]  bsd_pi,
    output wire [W_BpuPreReadReqCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BpuPreReadReqCombOut{1'b0}};

endmodule
