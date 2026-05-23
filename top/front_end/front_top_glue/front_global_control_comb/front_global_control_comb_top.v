// Formal frontend comb boundary: front_global_control_comb.
// Source: simulator-front/front-end/front_top.cpp, front_global_control_comb.
// Role: global reset/refetch selection.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_global_control_comb_top #(
    parameter integer PC_BITS                     = 32,
    parameter integer W_FrontGlobalControlCombIn  = 1 + 1 + PC_BITS + 1 + PC_BITS,  // actual: 67, 1 + 1 + PC_BITS + 1 + PC_BITS
    parameter integer W_FrontGlobalControlCombOut = 1 + 1 + PC_BITS    // actual: 34, 1 + 1 + PC_BITS
) (
    input  wire               reset,
    input  wire               refetch,
    input  wire [PC_BITS-1:0] refetch_address,
    input  wire               predecode_refetch_snapshot,
    input  wire [PC_BITS-1:0] predecode_refetch_address_snapshot,
    output wire               global_reset,
    output wire               global_refetch,
    output wire [PC_BITS-1:0] global_refetch_address
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontGlobalControlCombIn-1:0]  pi;
    wire [W_FrontGlobalControlCombOut-1:0] po;
    assign pi = {
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
    } = po;

    front_global_control_comb_bsd_top #(
        .W_FrontGlobalControlCombIn(W_FrontGlobalControlCombIn),
        .W_FrontGlobalControlCombOut(W_FrontGlobalControlCombOut)
    ) u_front_global_control_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_global_control_comb_bsd_top #(
    parameter integer W_FrontGlobalControlCombIn  = 67,  // actual: 67, 1 + 1 + PC_BITS + 1 + PC_BITS
    parameter integer W_FrontGlobalControlCombOut = 34    // actual: 34, 1 + 1 + PC_BITS
) (
    input  wire [W_FrontGlobalControlCombIn-1:0]  pi,
    output wire [W_FrontGlobalControlCombOut-1:0] po
);

    assign po = {W_FrontGlobalControlCombOut{1'b0}};

endmodule
