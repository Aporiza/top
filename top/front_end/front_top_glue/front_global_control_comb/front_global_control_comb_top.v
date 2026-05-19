// Formal frontend comb boundary: front_global_control_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_global_control_comb.
// Role: global reset/refetch selection.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_global_control_comb_top #(
    parameter integer PC_BITS                     = 32,
    parameter integer W_FrontGlobalControlCombIn  = 1 + 1 + PC_BITS + 1 + PC_BITS,
    parameter integer W_FrontGlobalControlCombOut = 1 + 1 + PC_BITS
) (
    input  wire [W_FrontGlobalControlCombIn-1:0]  bsd_pi,
    output wire [W_FrontGlobalControlCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire                                   reset;
    wire                                   refetch;
    wire [PC_BITS-1:0]                     refetch_address;
    wire                                   predecode_refetch_snapshot;
    wire [PC_BITS-1:0]                     predecode_refetch_address_snapshot;
    wire                                   global_reset;
    wire                                   global_refetch;
    wire [PC_BITS-1:0]                     global_refetch_address;
    wire [W_FrontGlobalControlCombIn-1:0]  front_global_control_comb_bsd_pi;
    wire [W_FrontGlobalControlCombOut-1:0] front_global_control_comb_bsd_po;

    assign {
        reset,
        refetch,
        refetch_address,
        predecode_refetch_snapshot,
        predecode_refetch_address_snapshot
    } = bsd_pi;

    assign front_global_control_comb_bsd_pi = {
        reset,
        refetch,
        refetch_address,
        predecode_refetch_snapshot,
        predecode_refetch_address_snapshot
    };

    assign {
        global_reset,
        global_refetch,
        global_refetch_address
    } = front_global_control_comb_bsd_po;

    assign bsd_po = {
        global_reset,
        global_refetch,
        global_refetch_address
    };

    front_global_control_comb_bsd_top #(
        .W_FrontGlobalControlCombIn(W_FrontGlobalControlCombIn),
        .W_FrontGlobalControlCombOut(W_FrontGlobalControlCombOut)
    ) u_front_global_control_comb_bsd_top (
        .bsd_pi(front_global_control_comb_bsd_pi),
        .bsd_po(front_global_control_comb_bsd_po)
    );

endmodule

module front_global_control_comb_bsd_top #(
    parameter integer W_FrontGlobalControlCombIn  = 64,
    parameter integer W_FrontGlobalControlCombOut = 64
) (
    input  wire [W_FrontGlobalControlCombIn-1:0]  bsd_pi,
    output wire [W_FrontGlobalControlCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontGlobalControlCombOut{1'b0}};

endmodule
