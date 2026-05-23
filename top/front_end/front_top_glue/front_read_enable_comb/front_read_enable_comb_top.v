// Formal frontend comb boundary: front_read_enable_comb.
// Source: simulator-front/front-end/front_top.cpp, front_read_enable_comb.
// Role: read-enable generation for frontend queues.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_read_enable_comb_top #(
    parameter integer W_FrontReadEnableCombIn  = 9,  // actual: 9, from front_top
    parameter integer W_FrontReadEnableCombOut = 6    // actual: 6, from front_top
) (
    input  wire  FIFO_read_enable,
    input  wire  fetch_addr_fifo_empty_latch_snapshot,
    input  wire  fifo_empty_latch_snapshot,
    input  wire  ptab_empty_latch_snapshot,
    input  wire  front2back_fifo_full_latch_snapshot,
    input  wire  global_reset,
    input  wire  global_refetch,
    input  wire  icache_read_ready,
    input  wire  icache_read_ready_2,
    output wire  fetch_addr_fifo_read_enable_slot0,
    output wire  fetch_addr_fifo_read_enable_slot1_candidate,
    output wire  predecode_can_run_old,
    output wire  inst_fifo_read_enable,
    output wire  ptab_read_enable,
    output wire  front2back_read_enable
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontReadEnableCombIn-1:0]  pi;
    wire [W_FrontReadEnableCombOut-1:0] po;
    assign pi = {
        FIFO_read_enable,
        fetch_addr_fifo_empty_latch_snapshot,
        fifo_empty_latch_snapshot,
        ptab_empty_latch_snapshot,
        front2back_fifo_full_latch_snapshot,
        global_reset,
        global_refetch,
        icache_read_ready,
        icache_read_ready_2
    };

    assign {
        fetch_addr_fifo_read_enable_slot0,
        fetch_addr_fifo_read_enable_slot1_candidate,
        predecode_can_run_old,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    } = po;

    front_read_enable_comb_bsd_top #(
        .W_FrontReadEnableCombIn(W_FrontReadEnableCombIn),
        .W_FrontReadEnableCombOut(W_FrontReadEnableCombOut)
    ) u_front_read_enable_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_read_enable_comb_bsd_top #(
    parameter integer W_FrontReadEnableCombIn  = 9,  // actual: 9, from front_top
    parameter integer W_FrontReadEnableCombOut = 6    // actual: 6, from front_top
) (
    input  wire [W_FrontReadEnableCombIn-1:0]  pi,
    output wire [W_FrontReadEnableCombOut-1:0] po
);

    assign po = {W_FrontReadEnableCombOut{1'b0}};

endmodule
