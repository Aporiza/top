// Source struct:
//   fetch_address_FIFO_in  = {reset, refetch, read_enable, write_enable,
//                             fetch_address}
//   fetch_address_FIFO_out = {full, empty, read_valid, fetch_address}
// FIFO storage and pointers stay internal.

module fetch_address_fifo_top #(
    parameter integer W_FetchAddressFifoIn = 1 + 1 + 1 + 1 + 32,
    parameter integer W_FetchAddressFifoOut = 1 + 1 + 1 + 32
) (
    input wire [W_FetchAddressFifoIn-1:0] fetch_address_fifo_in,

    output wire [W_FetchAddressFifoOut-1:0] fetch_address_fifo_out,
    output wire full,
    output wire empty,
    output wire read_valid,
    output wire [31:0] fetch_address
);

    wire [W_FetchAddressFifoIn-1:0]  pi;
    wire [W_FetchAddressFifoOut-1:0] po;

    wire reset;
    wire refetch;
    wire read_enable;
    wire write_enable;
    wire [31:0] fetch_address_in;
    assign {
        reset,
        refetch,
        read_enable,
        write_enable,
        fetch_address_in
    } = fetch_address_fifo_in;

    assign pi = {
        fetch_address_fifo_in
    };

    assign {
        full,
        empty,
        read_valid,
        fetch_address
    } = po;

    assign fetch_address_fifo_out = po;

    fetch_address_fifo_bsd_top #(
        .W_FetchAddressFifoIn(W_FetchAddressFifoIn),
        .W_FetchAddressFifoOut(W_FetchAddressFifoOut)
    ) u_fetch_address_fifo_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
