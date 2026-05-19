// Formal frontend comb boundary: front_read_stage_input_comb.
// Source: simulator-ff/front-end/front_top.cpp, front_read_stage_input_comb.
// Role: queue read/reset/refetch control construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module front_read_stage_input_comb_top #(
    parameter integer W_FrontReadStageInputCombIn  = 7,
    parameter integer W_FrontReadStageInputCombOut = 12
) (
    input  wire [W_FrontReadStageInputCombIn-1:0]  bsd_pi,
    output wire [W_FrontReadStageInputCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire                                    refetch;
    wire                                    global_reset;
    wire                                    global_refetch;
    wire                                    fetch_addr_fifo_read_enable_slot0;
    wire                                    inst_fifo_read_enable;
    wire                                    ptab_read_enable;
    wire                                    front2back_read_enable;
    wire                                    fetch_addr_fifo_reset;
    wire                                    fetch_addr_fifo_refetch;
    wire                                    fetch_addr_fifo_read_enable;
    wire                                    fifo_reset;
    wire                                    fifo_refetch;
    wire                                    fifo_read_enable;
    wire                                    ptab_reset;
    wire                                    ptab_refetch;
    wire                                    ptab_out_read_enable;
    wire                                    front2back_fifo_reset;
    wire                                    front2back_fifo_refetch;
    wire                                    front2back_fifo_read_enable;
    wire [W_FrontReadStageInputCombIn-1:0]  front_read_stage_input_comb_bsd_pi;
    wire [W_FrontReadStageInputCombOut-1:0] front_read_stage_input_comb_bsd_po;

    assign {
        refetch,
        global_reset,
        global_refetch,
        fetch_addr_fifo_read_enable_slot0,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    } = bsd_pi;

    assign front_read_stage_input_comb_bsd_pi = {
        refetch,
        global_reset,
        global_refetch,
        fetch_addr_fifo_read_enable_slot0,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    };

    assign {
        fetch_addr_fifo_reset,
        fetch_addr_fifo_refetch,
        fetch_addr_fifo_read_enable,
        fifo_reset,
        fifo_refetch,
        fifo_read_enable,
        ptab_reset,
        ptab_refetch,
        ptab_out_read_enable,
        front2back_fifo_reset,
        front2back_fifo_refetch,
        front2back_fifo_read_enable
    } = front_read_stage_input_comb_bsd_po;

    assign bsd_po = {
        fetch_addr_fifo_reset,
        fetch_addr_fifo_refetch,
        fetch_addr_fifo_read_enable,
        fifo_reset,
        fifo_refetch,
        fifo_read_enable,
        ptab_reset,
        ptab_refetch,
        ptab_out_read_enable,
        front2back_fifo_reset,
        front2back_fifo_refetch,
        front2back_fifo_read_enable
    };

    front_read_stage_input_comb_bsd_top #(
        .W_FrontReadStageInputCombIn(W_FrontReadStageInputCombIn),
        .W_FrontReadStageInputCombOut(W_FrontReadStageInputCombOut)
    ) u_front_read_stage_input_comb_bsd_top (
        .bsd_pi(front_read_stage_input_comb_bsd_pi),
        .bsd_po(front_read_stage_input_comb_bsd_po)
    );

endmodule

module front_read_stage_input_comb_bsd_top #(
    parameter integer W_FrontReadStageInputCombIn  = 64,
    parameter integer W_FrontReadStageInputCombOut = 64
) (
    input  wire [W_FrontReadStageInputCombIn-1:0]  bsd_pi,
    output wire [W_FrontReadStageInputCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FrontReadStageInputCombOut{1'b0}};

endmodule
