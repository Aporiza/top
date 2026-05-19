// Formal frontend comb boundary: fetch_address_FIFO_comb.
// Source: simulator-ff/front-end FIFO comb calculation.
// Role: fetch-address FIFO combinational update.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module fetch_address_FIFO_comb_top #(
    parameter integer W_FetchAddressFifoIn      = 64,
    parameter integer W_FetchAddressFifoOut     = 64,
    parameter integer W_FetchAddrCombOut        = 64,
    parameter integer W_FetchAddressFifoCombIn  = W_FetchAddressFifoIn + W_FetchAddressFifoOut,
    parameter integer W_FetchAddressFifoCombOut = W_FetchAddrCombOut
) (
    input  wire [W_FetchAddressFifoCombIn-1:0]  bsd_pi,
    output wire [W_FetchAddressFifoCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_FetchAddressFifoIn-1:0]      fetch_addr_fifo_in;
    wire [W_FetchAddressFifoOut-1:0]     fetch_addr_fifo_rd;
    wire [W_FetchAddrCombOut-1:0]        fetch_addr_fifo_req;
    wire [W_FetchAddressFifoCombIn-1:0]  fetch_address_FIFO_comb_bsd_pi;
    wire [W_FetchAddressFifoCombOut-1:0] fetch_address_FIFO_comb_bsd_po;

    assign {
        fetch_addr_fifo_in,
        fetch_addr_fifo_rd
    } = bsd_pi;

    assign fetch_address_FIFO_comb_bsd_pi = {
        fetch_addr_fifo_in,
        fetch_addr_fifo_rd
    };

    assign {
        fetch_addr_fifo_req
    } = fetch_address_FIFO_comb_bsd_po;

    assign bsd_po = {
        fetch_addr_fifo_req
    };

    fetch_address_FIFO_comb_bsd_top #(
        .W_FetchAddressFifoCombIn(W_FetchAddressFifoCombIn),
        .W_FetchAddressFifoCombOut(W_FetchAddressFifoCombOut)
    ) u_fetch_address_FIFO_comb_bsd_top (
        .bsd_pi(fetch_address_FIFO_comb_bsd_pi),
        .bsd_po(fetch_address_FIFO_comb_bsd_po)
    );

endmodule

module fetch_address_FIFO_comb_bsd_top #(
    parameter integer W_FetchAddressFifoCombIn  = 64,
    parameter integer W_FetchAddressFifoCombOut = 64
) (
    input  wire [W_FetchAddressFifoCombIn-1:0]  bsd_pi,
    output wire [W_FetchAddressFifoCombOut-1:0] bsd_po
);

    assign bsd_po = {W_FetchAddressFifoCombOut{1'b0}};

endmodule
