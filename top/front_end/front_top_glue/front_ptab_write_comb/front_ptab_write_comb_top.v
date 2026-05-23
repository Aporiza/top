// Formal frontend comb boundary: front_ptab_write_comb.
// Source: simulator-front/front-end/front_top.cpp, front_ptab_write_comb.
// Role: PTAB write bundle construction from BPU output.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_ptab_write_comb_top #(
    parameter integer W_BpuOut                = 4949,  // actual: 4949, from front_top W_BpuOut
    parameter integer W_PtabIn                = 4853,  // actual: 4853, from front_top W_PtabIn
    parameter integer W_FrontPtabWriteCombIn  = W_BpuOut + 3,  // actual: 4952, W_BpuOut + 3
    parameter integer W_FrontPtabWriteCombOut = W_PtabIn    // actual: 4853, W_PtabIn
) (
    input  wire [W_BpuOut-1:0] bpu_output_payload,
    input  wire                global_reset,
    input  wire                global_refetch,
    input  wire                ptab_can_write,
    output wire [W_PtabIn-1:0] ptab_in
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontPtabWriteCombIn-1:0]  pi;
    wire [W_FrontPtabWriteCombOut-1:0] po;
    assign pi = {
        bpu_output_payload,
        global_reset,
        global_refetch,
        ptab_can_write
    };

    assign {
        ptab_in
    } = po;

    front_ptab_write_comb_bsd_top #(
        .W_FrontPtabWriteCombIn(W_FrontPtabWriteCombIn),
        .W_FrontPtabWriteCombOut(W_FrontPtabWriteCombOut)
    ) u_front_ptab_write_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_ptab_write_comb_bsd_top #(
    parameter integer W_FrontPtabWriteCombIn  = 4952,  // actual: 4952, W_BpuOut + 3
    parameter integer W_FrontPtabWriteCombOut = 4853    // actual: 4853, W_PtabIn
) (
    input  wire [W_FrontPtabWriteCombIn-1:0]  pi,
    output wire [W_FrontPtabWriteCombOut-1:0] po
);

    assign po = {W_FrontPtabWriteCombOut{1'b0}};

endmodule
