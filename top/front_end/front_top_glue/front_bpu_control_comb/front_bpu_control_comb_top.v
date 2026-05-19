// Formal frontend comb boundary: front_bpu_control_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_bpu_control_comb.
// Role: BPU run/stall control and input bundle construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_bpu_control_comb_top #(
    parameter integer PC_BITS                  = 32,
    parameter integer W_BpuIn                  = 64,
    parameter integer W_FrontBpuControlCombIn  = W_BpuIn + 2 + 1 + 1 + PC_BITS,
    parameter integer W_FrontBpuControlCombOut = 3 + W_BpuIn + W_BpuIn
) (
    input  wire [W_FrontBpuControlCombIn-1:0]  bsd_pi,
    output wire [W_FrontBpuControlCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuIn-1:0]                  bpu_in_seed;
    wire                                fetch_addr_fifo_full_latch;
    wire                                ptab_full_latch;
    wire                                global_reset;
    wire                                global_refetch;
    wire [PC_BITS-1:0]                  global_refetch_address;
    wire                                bpu_stall;
    wire                                bpu_can_run;
    wire                                bpu_icache_ready;
    wire [W_BpuIn-1:0]                  bpu_in_after_control;
    wire [W_BpuIn-1:0]                  bpu_input_payload;
    wire [W_FrontBpuControlCombIn-1:0]  front_bpu_control_comb_bsd_pi;
    wire [W_FrontBpuControlCombOut-1:0] front_bpu_control_comb_bsd_po;

    assign {
        bpu_in_seed,
        fetch_addr_fifo_full_latch,
        ptab_full_latch,
        global_reset,
        global_refetch,
        global_refetch_address
    } = bsd_pi;

    assign front_bpu_control_comb_bsd_pi = {
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
    } = front_bpu_control_comb_bsd_po;

    assign bsd_po = {
        bpu_stall,
        bpu_can_run,
        bpu_icache_ready,
        bpu_in_after_control,
        bpu_input_payload
    };

    front_bpu_control_comb_bsd_top #(
        .W_FrontBpuControlCombIn(W_FrontBpuControlCombIn),
        .W_FrontBpuControlCombOut(W_FrontBpuControlCombOut)
    ) u_front_bpu_control_comb_bsd_top (
        .bsd_pi(front_bpu_control_comb_bsd_pi),
        .bsd_po(front_bpu_control_comb_bsd_po)
    );

endmodule

module front_bpu_control_comb_bsd_top #(
    parameter integer W_FrontBpuControlCombIn  = 64,
    parameter integer W_FrontBpuControlCombOut = 64
) (
    input  wire [W_FrontBpuControlCombIn-1:0]  bsd_pi,
    output wire [W_FrontBpuControlCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontBpuControlCombOut{1'b0}};

endmodule
