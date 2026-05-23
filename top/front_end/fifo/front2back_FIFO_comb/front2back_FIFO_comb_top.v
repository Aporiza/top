// Formal frontend comb boundary: front2back_FIFO_comb.
// Source: simulator-front/front-end front2back FIFO comb calculation.
// Role: front2back FIFO combinational update.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module front2back_FIFO_comb_top #(
    parameter integer W_Front2BackFifoIn      = 5396,  // actual: 5396, from front_top W_Front2BackFifoIn
    parameter integer W_Front2BackFifoOut     = 5395,  // actual: 5395, from front_top W_Front2BackFifoOut
    parameter integer W_Front2BackCombOut     = 10794,  // actual: 10794, from front_top W_Front2BackCombOut
    parameter integer FRONT2BACK_FIFO_SIZE    = 64,  // actual: 64, from simulator-front frontend_feature_config.h
    parameter integer W_Front2backFifoCombIn  = W_Front2BackFifoIn + W_Front2BackFifoOut,  // actual: 10791, W_Front2BackFifoIn + W_Front2BackFifoOut
    parameter integer W_Front2backFifoCombOut = W_Front2BackCombOut    // actual: 10794, W_Front2BackCombOut
) (
    input  wire                           aclk,
    input  wire                           aresetn,
    input  wire [W_Front2BackFifoIn-1:0]  front2back_fifo_in,
    input  wire [W_Front2BackFifoOut-1:0] front2back_fifo_rd,
    output wire [W_Front2BackCombOut-1:0] front2back_fifo_req
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_Front2backFifoCombIn-1:0]  pi;
    wire [W_Front2backFifoCombOut-1:0] po;
    assign pi = {
        front2back_fifo_in,
        front2back_fifo_rd
    };

    assign {
        front2back_fifo_req
    } = po;

    front2back_FIFO_comb_bsd_top #(
        .W_Front2BackFifoIn(W_Front2BackFifoIn),
        .W_Front2BackFifoOut(W_Front2BackFifoOut),
        .FRONT2BACK_FIFO_SIZE(FRONT2BACK_FIFO_SIZE),
        .W_Front2backFifoCombIn(W_Front2backFifoCombIn),
        .W_Front2backFifoCombOut(W_Front2backFifoCombOut)
    ) u_front2back_FIFO_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

module front2back_FIFO_comb_bsd_top #(
    parameter integer W_Front2BackFifoIn      = 5396,  // actual: 5396, from front_top W_Front2BackFifoIn
    parameter integer W_Front2BackFifoOut     = 5395,  // actual: 5395, from front_top W_Front2BackFifoOut
    parameter integer FRONT2BACK_FIFO_SIZE    = 64,  // actual: 64, from simulator-front frontend_feature_config.h
    parameter integer W_Front2backFifoCombIn  = 10791,  // actual: 10791, W_Front2BackFifoIn + W_Front2BackFifoOut
    parameter integer W_Front2backFifoCombOut = 10794    // actual: 10794, W_Front2BackCombOut
) (
    input  wire                                     aclk,
    input  wire                                     aresetn,
    input  wire [W_Front2backFifoCombIn-1:0]  pi,
    output wire [W_Front2backFifoCombOut-1:0] po
);

    localparam integer W_Front2BackPayload = W_Front2BackFifoOut - 3;
    localparam integer W_Front2BackCtrlOut =
        W_Front2backFifoCombOut - W_Front2BackFifoOut;
    localparam integer PTR_BITS = clog2(FRONT2BACK_FIFO_SIZE);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = (i == 0) ? 1 : i;
        end
    endfunction

    function [PTR_BITS-1:0] ptr_next;
        input [PTR_BITS-1:0] ptr;
        begin
            ptr_next = (ptr == FRONT2BACK_FIFO_SIZE - 1) ?
                {PTR_BITS{1'b0}} : ptr + 1'b1;
        end
    endfunction

    wire [W_Front2BackFifoIn-1:0]  fifo_in;
    wire [W_Front2BackFifoOut-1:0] unused_fifo_rd;

    assign {
        fifo_in,
        unused_fifo_rd
    } = pi;

    wire [W_Front2BackPayload-1:0] write_payload =
        fifo_in[W_Front2BackPayload-1:0];
    wire read_enable = fifo_in[W_Front2BackPayload];
    wire write_enable = fifo_in[W_Front2BackPayload + 1];
    wire refetch = fifo_in[W_Front2BackPayload + 2];
    wire reset = fifo_in[W_Front2BackPayload + 3];

    reg [W_Front2BackPayload-1:0] fifo_mem [0:FRONT2BACK_FIFO_SIZE-1];
    reg [PTR_BITS-1:0] fifo_head;
    reg [PTR_BITS-1:0] fifo_tail;
    reg [PTR_BITS:0]   fifo_count;

    wire rd_valid = (fifo_count != {(PTR_BITS+1){1'b0}});
    wire [W_Front2BackPayload-1:0] rd_payload = fifo_mem[fifo_head];

    wire do_clear = reset || refetch;
    wire do_write = write_enable && !do_clear;
    wire do_read  = read_enable && !do_clear && (rd_valid || do_write);
    wire pop_existing = do_read && rd_valid;
    wire store_write = do_write && ((fifo_count < FRONT2BACK_FIFO_SIZE) || pop_existing);
    wire [PTR_BITS:0] next_count =
        do_clear ? {(PTR_BITS+1){1'b0}} :
        fifo_count
      + {{PTR_BITS{1'b0}}, store_write}
      - {{PTR_BITS{1'b0}}, pop_existing};

    wire next_full = (next_count >= FRONT2BACK_FIFO_SIZE);
    wire next_empty = (next_count == {(PTR_BITS+1){1'b0}});
    wire [W_Front2BackPayload-1:0] read_payload =
        rd_valid ? rd_payload : write_payload;

    wire [W_Front2BackFifoOut-1:0] out_regs = {
        next_full,
        next_empty,
        do_read,
        do_read ? read_payload :
        (rd_valid ? rd_payload : {W_Front2BackPayload{1'b0}})
    };

    assign po = {
        {W_Front2BackCtrlOut{1'b0}},
        out_regs
    };

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn || reset || refetch) begin
            fifo_head <= {PTR_BITS{1'b0}};
            fifo_tail <= {PTR_BITS{1'b0}};
            fifo_count <= {(PTR_BITS+1){1'b0}};
        end else begin
            if (store_write) begin
                fifo_mem[fifo_tail] <= write_payload;
                fifo_tail <= ptr_next(fifo_tail);
            end
            if (pop_existing) begin
                fifo_head <= ptr_next(fifo_head);
            end
            fifo_count <= next_count;
        end
    end

endmodule
