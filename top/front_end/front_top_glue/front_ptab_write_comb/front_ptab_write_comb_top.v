// Formal frontend comb boundary: front_ptab_write_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_ptab_write_comb.
// Role: PTAB write bundle construction from BPU output.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_ptab_write_comb_top #(
    parameter integer W_BpuOut                = 64,
    parameter integer W_PtabIn                = 64,
    parameter integer W_FrontPtabWriteCombIn  = W_BpuOut + 3,
    parameter integer W_FrontPtabWriteCombOut = W_PtabIn
) (
    input  wire [W_FrontPtabWriteCombIn-1:0]  bsd_pi,
    output wire [W_FrontPtabWriteCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuOut-1:0]                bpu_output_payload;
    wire                               global_reset;
    wire                               global_refetch;
    wire                               ptab_can_write;
    wire [W_PtabIn-1:0]                ptab_in;
    wire [W_FrontPtabWriteCombIn-1:0]  front_ptab_write_comb_bsd_pi;
    wire [W_FrontPtabWriteCombOut-1:0] front_ptab_write_comb_bsd_po;

    assign {
        bpu_output_payload,
        global_reset,
        global_refetch,
        ptab_can_write
    } = bsd_pi;

    assign front_ptab_write_comb_bsd_pi = {
        bpu_output_payload,
        global_reset,
        global_refetch,
        ptab_can_write
    };

    assign {
        ptab_in
    } = front_ptab_write_comb_bsd_po;

    assign bsd_po = {
        ptab_in
    };

    front_ptab_write_comb_bsd_top #(
        .W_FrontPtabWriteCombIn(W_FrontPtabWriteCombIn),
        .W_FrontPtabWriteCombOut(W_FrontPtabWriteCombOut)
    ) u_front_ptab_write_comb_bsd_top (
        .bsd_pi(front_ptab_write_comb_bsd_pi),
        .bsd_po(front_ptab_write_comb_bsd_po)
    );

endmodule

module front_ptab_write_comb_bsd_top #(
    parameter integer W_FrontPtabWriteCombIn  = 64,
    parameter integer W_FrontPtabWriteCombOut = 64
) (
    input  wire [W_FrontPtabWriteCombIn-1:0]  bsd_pi,
    output wire [W_FrontPtabWriteCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontPtabWriteCombOut{1'b0}};

endmodule
