// Formal frontend comb boundary: fetch_address_FIFO_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/fifo/fetch_address_FIFO.cpp:123.
// Role: fetch address FIFO comb.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module fetch_address_FIFO_comb_top #(
    parameter integer W_FetchAddressFifoCombIn = 64,
    parameter integer W_FetchAddressFifoCombOut = 64
) (
    input wire [W_FetchAddressFifoCombIn-1:0] fetch_address_FIFO_comb_in,
    output wire [W_FetchAddressFifoCombOut-1:0] fetch_address_FIFO_comb_out
);

    wire [W_FetchAddressFifoCombIn-1:0] fetch_address_FIFO_comb_pi;
    wire [W_FetchAddressFifoCombOut-1:0] fetch_address_FIFO_comb_po;

    assign fetch_address_FIFO_comb_pi = fetch_address_FIFO_comb_in;
    assign fetch_address_FIFO_comb_out = fetch_address_FIFO_comb_po;

    fetch_address_FIFO_comb_bsd_top #(
        .W_FetchAddressFifoCombIn(W_FetchAddressFifoCombIn),
        .W_FetchAddressFifoCombOut(W_FetchAddressFifoCombOut)
    ) u_fetch_address_FIFO_comb_bsd_top (
        .pi(fetch_address_FIFO_comb_pi),
        .po(fetch_address_FIFO_comb_po)
    );

endmodule

module fetch_address_FIFO_comb_bsd_top #(
    parameter integer W_FetchAddressFifoCombIn = 64,
    parameter integer W_FetchAddressFifoCombOut = 64
) (
    input wire [W_FetchAddressFifoCombIn-1:0] pi,
    output wire [W_FetchAddressFifoCombOut-1:0] po
);
    assign po = {W_FetchAddressFifoCombOut{1'b0}};
endmodule
