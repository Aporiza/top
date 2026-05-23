// Formal frontend comb boundary: front_read_stage_input_comb.
// Source: simulator-front/front-end/front_top.cpp, front_read_stage_input_comb.
// Role: queue read/reset/refetch control construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front_read_stage_input_comb_top #(
    parameter integer W_FrontReadStageInputCombIn  = 7,  // actual: 7, from front_top
    parameter integer W_FrontReadStageInputCombOut = 12    // actual: 12, from front_top
) (
    input  wire  refetch,
    input  wire  global_reset,
    input  wire  global_refetch,
    input  wire  fetch_addr_fifo_read_enable_slot0,
    input  wire  inst_fifo_read_enable,
    input  wire  ptab_read_enable,
    input  wire  front2back_read_enable,
    output wire  fetch_addr_fifo_reset,
    output wire  fetch_addr_fifo_refetch,
    output wire  fetch_addr_fifo_read_enable,
    output wire  fifo_reset,
    output wire  fifo_refetch,
    output wire  fifo_read_enable,
    output wire  ptab_reset,
    output wire  ptab_refetch,
    output wire  ptab_out_read_enable,
    output wire  front2back_fifo_reset,
    output wire  front2back_fifo_refetch,
    output wire  front2back_fifo_read_enable
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FrontReadStageInputCombIn-1:0]  pi;
    wire [W_FrontReadStageInputCombOut-1:0] po;
    assign pi = {
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
    } = po;

    front_read_stage_input_comb_bsd_top #(
        .W_FrontReadStageInputCombIn(W_FrontReadStageInputCombIn),
        .W_FrontReadStageInputCombOut(W_FrontReadStageInputCombOut)
    ) u_front_read_stage_input_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_read_stage_input_comb_bsd_top #(
    parameter integer W_FrontReadStageInputCombIn  = 7,  // actual: 7, from front_top
    parameter integer W_FrontReadStageInputCombOut = 12    // actual: 12, from front_top
) (
    input  wire [W_FrontReadStageInputCombIn-1:0]  pi,
    output wire [W_FrontReadStageInputCombOut-1:0] po
);

    assign po = {W_FrontReadStageInputCombOut{1'b0}};

endmodule
