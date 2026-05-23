// Formal frontend comb boundary: front_bpu_control_comb.
// Source: simulator-front/front-end/front_top.cpp, front_bpu_control_comb.
// Role: BPU run/stall control and input bundle construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_bpu_control_comb_top #(
    parameter integer PC_BITS                  = 32,
    parameter integer W_BpuIn                  = 2739,  // actual: 2739, from front_top W_BpuIn
    parameter integer W_FrontBpuControlCombIn  = W_BpuIn + 2 + 1 + 1 + PC_BITS,  // actual: 2775, W_BpuIn + 2 + 1 + 1 + PC_BITS
    parameter integer W_FrontBpuControlCombOut = 3 + W_BpuIn + W_BpuIn    // actual: 5481, 3 + W_BpuIn + W_BpuIn
) (
    input  wire [W_BpuIn-1:0] bpu_in_seed,
    input  wire               fetch_addr_fifo_full_latch,
    input  wire               ptab_full_latch,
    input  wire               global_reset,
    input  wire               global_refetch,
    input  wire [PC_BITS-1:0] global_refetch_address,
    output wire               bpu_stall,
    output wire               bpu_can_run,
    output wire               bpu_icache_ready,
    output wire [W_BpuIn-1:0] bpu_in_after_control,
    output wire [W_BpuIn-1:0] bpu_input_payload
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontBpuControlCombIn-1:0]  pi;
    wire [W_FrontBpuControlCombOut-1:0] po;
    assign pi = {
        bpu_in_seed,
        fetch_addr_fifo_full_latch,
        ptab_full_latch,
        global_reset,
        global_refetch,
        global_refetch_address
    };

    assign {
        bpu_stall,
        bpu_can_run,
        bpu_icache_ready,
        bpu_in_after_control,
        bpu_input_payload
    } = po;

    front_bpu_control_comb_bsd_top #(
        .W_FrontBpuControlCombIn(W_FrontBpuControlCombIn),
        .W_FrontBpuControlCombOut(W_FrontBpuControlCombOut)
    ) u_front_bpu_control_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_bpu_control_comb_bsd_top #(
    parameter integer W_FrontBpuControlCombIn  = 2775,  // actual: 2775, W_BpuIn + 2 + 1 + 1 + PC_BITS
    parameter integer W_FrontBpuControlCombOut = 5481    // actual: 5481, 3 + W_BpuIn + W_BpuIn
) (
    input  wire [W_FrontBpuControlCombIn-1:0]  pi,
    output wire [W_FrontBpuControlCombOut-1:0] po
);

    assign po = {W_FrontBpuControlCombOut{1'b0}};

endmodule
