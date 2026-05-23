// Formal frontend comb boundary: fetch_address_FIFO_comb.
// Source: simulator-front/front-end FIFO comb calculation.
// Role: fetch-address FIFO combinational update.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module fetch_address_FIFO_comb_top #(
    parameter integer W_FetchAddressFifoIn      = 36,  // actual: 36, from front_top W_FetchAddressFifoIn
    parameter integer W_FetchAddressFifoOut     = 35,  // actual: 35, from front_top W_FetchAddressFifoOut
    parameter integer W_FetchAddrCombOut        = 70,  // actual: 70, from front_top W_FetchAddrCombOut
    parameter integer FETCH_ADDR_FIFO_SIZE      = 32,  // actual: 32, from simulator-front frontend_feature_config.h
    parameter integer W_FetchAddressFifoCombIn  = W_FetchAddressFifoIn + W_FetchAddressFifoOut,  // actual: 71, W_FetchAddressFifoIn + W_FetchAddressFifoOut
    parameter integer W_FetchAddressFifoCombOut = W_FetchAddrCombOut    // actual: 70, W_FetchAddrCombOut
) (
    input  wire                             aclk,
    input  wire                             aresetn,
    input  wire [W_FetchAddressFifoIn-1:0]  fetch_addr_fifo_in,
    input  wire [W_FetchAddressFifoOut-1:0] fetch_addr_fifo_rd,
    output wire [W_FetchAddrCombOut-1:0]    fetch_addr_fifo_req
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_FetchAddressFifoCombIn-1:0]  pi;
    wire [W_FetchAddressFifoCombOut-1:0] po;
    assign pi = {
        fetch_addr_fifo_in,
        fetch_addr_fifo_rd
    };

    assign {
        fetch_addr_fifo_req
    } = po;

    fetch_address_FIFO_comb_bsd_top #(
        .W_FetchAddressFifoIn(W_FetchAddressFifoIn),
        .W_FetchAddressFifoOut(W_FetchAddressFifoOut),
        .FETCH_ADDR_FIFO_SIZE(FETCH_ADDR_FIFO_SIZE),
        .W_FetchAddressFifoCombIn(W_FetchAddressFifoCombIn),
        .W_FetchAddressFifoCombOut(W_FetchAddressFifoCombOut)
    ) u_fetch_address_FIFO_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

module fetch_address_FIFO_comb_bsd_top #(
    parameter integer W_FetchAddressFifoIn      = 36,  // actual: 36, from front_top W_FetchAddressFifoIn
    parameter integer W_FetchAddressFifoOut     = 35,  // actual: 35, from front_top W_FetchAddressFifoOut
    parameter integer FETCH_ADDR_FIFO_SIZE      = 32,  // actual: 32, from simulator-front frontend_feature_config.h
    parameter integer W_FetchAddressFifoCombIn  = 71,  // actual: 71, W_FetchAddressFifoIn + W_FetchAddressFifoOut
    parameter integer W_FetchAddressFifoCombOut = 70    // actual: 70, W_FetchAddrCombOut
) (
    input  wire                                     aclk,
    input  wire                                     aresetn,
    input  wire [W_FetchAddressFifoCombIn-1:0]  pi,
    output wire [W_FetchAddressFifoCombOut-1:0] po
);

    localparam integer W_FetchAddressPayload = W_FetchAddressFifoOut - 3;
    localparam integer W_FetchAddressCtrlOut =
        W_FetchAddressFifoCombOut - W_FetchAddressFifoOut;
    localparam integer PTR_BITS = clog2(FETCH_ADDR_FIFO_SIZE);

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
            ptr_next = (ptr == FETCH_ADDR_FIFO_SIZE - 1) ?
                {PTR_BITS{1'b0}} : ptr + 1'b1;
        end
    endfunction

    wire [W_FetchAddressFifoIn-1:0]  fifo_in;
    wire [W_FetchAddressFifoOut-1:0] unused_fifo_rd;

    assign {
        fifo_in,
        unused_fifo_rd
    } = pi;

    wire reset        = fifo_in[W_FetchAddressPayload + 3];
    wire refetch      = fifo_in[W_FetchAddressPayload + 2];
    wire read_enable  = fifo_in[W_FetchAddressPayload + 1];
    wire write_enable = fifo_in[W_FetchAddressPayload];
    wire [W_FetchAddressPayload-1:0] write_fetch_address =
        fifo_in[W_FetchAddressPayload-1:0];

    reg [W_FetchAddressPayload-1:0] fifo_mem [0:FETCH_ADDR_FIFO_SIZE-1];
    reg [PTR_BITS-1:0] fifo_head;
    reg [PTR_BITS-1:0] fifo_tail;
    reg [PTR_BITS:0]   fifo_count;

    wire rd_valid = (fifo_count != {(PTR_BITS+1){1'b0}});
    wire [W_FetchAddressPayload-1:0] rd_fetch_address = fifo_mem[fifo_head];

    wire do_clear = reset || refetch;
    wire do_write = write_enable && !do_clear;
    wire do_read  = read_enable && !do_clear && (rd_valid || do_write);
    wire pop_existing = do_read && rd_valid;
    wire store_write = do_write && ((fifo_count < FETCH_ADDR_FIFO_SIZE) || pop_existing);
    wire [PTR_BITS:0] next_count =
        do_clear ? {(PTR_BITS+1){1'b0}} :
        fifo_count
      + {{PTR_BITS{1'b0}}, store_write}
      - {{PTR_BITS{1'b0}}, pop_existing};

    wire next_full = (next_count >= (FETCH_ADDR_FIFO_SIZE - 1));
    wire next_empty = (next_count == {(PTR_BITS+1){1'b0}});
    wire [W_FetchAddressPayload-1:0] read_fetch_address =
        rd_valid ? rd_fetch_address : write_fetch_address;

    wire [W_FetchAddressFifoOut-1:0] out_regs = {
        next_full,
        next_empty,
        do_read,
        do_read ? read_fetch_address :
        (rd_valid ? rd_fetch_address : {W_FetchAddressPayload{1'b0}})
    };

    assign po = {
        {W_FetchAddressCtrlOut{1'b0}},
        out_regs
    };

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn || reset || refetch) begin
            fifo_head <= {PTR_BITS{1'b0}};
            fifo_tail <= {PTR_BITS{1'b0}};
            fifo_count <= {(PTR_BITS+1){1'b0}};
        end else begin
            if (store_write) begin
                fifo_mem[fifo_tail] <= write_fetch_address;
                fifo_tail <= ptr_next(fifo_tail);
            end
            if (pop_existing) begin
                fifo_head <= ptr_next(fifo_head);
            end
            fifo_count <= next_count;
        end
    end

endmodule
