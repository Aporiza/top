// Formal frontend comb boundary: front_read_enable_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_read_enable_comb.
// Role: read-enable generation for frontend queues.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_read_enable_comb_top #(
    parameter integer W_FrontReadEnableCombIn  = 9,
    parameter integer W_FrontReadEnableCombOut = 6
) (
    input  wire [W_FrontReadEnableCombIn-1:0]  bsd_pi,
    output wire [W_FrontReadEnableCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire                                FIFO_read_enable;
    wire                                fetch_addr_fifo_empty_latch_snapshot;
    wire                                fifo_empty_latch_snapshot;
    wire                                ptab_empty_latch_snapshot;
    wire                                front2back_fifo_full_latch_snapshot;
    wire                                global_reset;
    wire                                global_refetch;
    wire                                icache_read_ready;
    wire                                icache_read_ready_2;
    wire                                fetch_addr_fifo_read_enable_slot0;
    wire                                fetch_addr_fifo_read_enable_slot1_candidate;
    wire                                predecode_can_run_old;
    wire                                inst_fifo_read_enable;
    wire                                ptab_read_enable;
    wire                                front2back_read_enable;
    wire [W_FrontReadEnableCombIn-1:0]  front_read_enable_comb_bsd_pi;
    wire [W_FrontReadEnableCombOut-1:0] front_read_enable_comb_bsd_po;

    assign {
        FIFO_read_enable,
        fetch_addr_fifo_empty_latch_snapshot,
        fifo_empty_latch_snapshot,
        ptab_empty_latch_snapshot,
        front2back_fifo_full_latch_snapshot,
        global_reset,
        global_refetch,
        icache_read_ready,
        icache_read_ready_2
    } = bsd_pi;

    assign front_read_enable_comb_bsd_pi = {
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
    } = front_read_enable_comb_bsd_po;

    assign bsd_po = {
        fetch_addr_fifo_read_enable_slot0,
        fetch_addr_fifo_read_enable_slot1_candidate,
        predecode_can_run_old,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    };

    front_read_enable_comb_bsd_top #(
        .W_FrontReadEnableCombIn(W_FrontReadEnableCombIn),
        .W_FrontReadEnableCombOut(W_FrontReadEnableCombOut)
    ) u_front_read_enable_comb_bsd_top (
        .bsd_pi(front_read_enable_comb_bsd_pi),
        .bsd_po(front_read_enable_comb_bsd_po)
    );

endmodule

module front_read_enable_comb_bsd_top #(
    parameter integer W_FrontReadEnableCombIn  = 64,
    parameter integer W_FrontReadEnableCombOut = 64
) (
    input  wire [W_FrontReadEnableCombIn-1:0]  bsd_pi,
    output wire [W_FrontReadEnableCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontReadEnableCombOut{1'b0}};

endmodule
