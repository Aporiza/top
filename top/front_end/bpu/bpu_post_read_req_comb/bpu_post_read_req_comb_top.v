// Formal frontend comb boundary: bpu_post_read_req_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BPU post-read request bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module bpu_post_read_req_comb_top #(
    parameter integer W_BpuPostReadReqCombIn  = 64,
    parameter integer W_BpuPostReadReqCombOut = 64
) (
    input  wire [W_BpuPostReadReqCombIn-1:0]  bsd_pi,
    output wire [W_BpuPostReadReqCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuPostReadReqCombIn-1:0]  bpu_pre_read_req_bundle;
    wire [W_BpuPostReadReqCombOut-1:0] bpu_post_read_req_bundle;
    wire [W_BpuPostReadReqCombIn-1:0]  bpu_post_read_req_comb_bsd_pi;
    wire [W_BpuPostReadReqCombOut-1:0] bpu_post_read_req_comb_bsd_po;

    assign {
        bpu_pre_read_req_bundle
    } = bsd_pi;

    assign bpu_post_read_req_comb_bsd_pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        bpu_post_read_req_bundle
    } = bpu_post_read_req_comb_bsd_po;

    assign bsd_po = {
        bpu_post_read_req_bundle
    };

    bpu_post_read_req_comb_bsd_top #(
        .W_BpuPostReadReqCombIn(W_BpuPostReadReqCombIn),
        .W_BpuPostReadReqCombOut(W_BpuPostReadReqCombOut)
    ) u_bpu_post_read_req_comb_bsd_top (
        .bsd_pi(bpu_post_read_req_comb_bsd_pi),
        .bsd_po(bpu_post_read_req_comb_bsd_po)
    );

endmodule

module bpu_post_read_req_comb_bsd_top #(
    parameter integer W_BpuPostReadReqCombIn  = 64,
    parameter integer W_BpuPostReadReqCombOut = 64
) (
    input  wire [W_BpuPostReadReqCombIn-1:0]  bsd_pi,
    output wire [W_BpuPostReadReqCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BpuPostReadReqCombOut{1'b0}};

endmodule
