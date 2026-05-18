// Formal frontend comb boundary: front_read_enable_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/train_IO.h:281 and front_top.cpp:624,1072.
// Role: read-enable generation.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front_read_enable_comb_top #(
    parameter integer W_FrontReadEnableCombIn = 64,
    parameter integer W_FrontReadEnableCombOut = 64
) (
    input wire [W_FrontReadEnableCombIn-1:0] front_read_enable_comb_in,
    output wire [W_FrontReadEnableCombOut-1:0] front_read_enable_comb_out
);

    wire [W_FrontReadEnableCombIn-1:0] front_read_enable_comb_pi;
    wire [W_FrontReadEnableCombOut-1:0] front_read_enable_comb_po;

    assign front_read_enable_comb_pi = front_read_enable_comb_in;
    assign front_read_enable_comb_out = front_read_enable_comb_po;

    front_read_enable_comb_bsd_top #(
        .W_FrontReadEnableCombIn(W_FrontReadEnableCombIn),
        .W_FrontReadEnableCombOut(W_FrontReadEnableCombOut)
    ) u_front_read_enable_comb_bsd_top (
        .pi(front_read_enable_comb_pi),
        .po(front_read_enable_comb_po)
    );

endmodule

module front_read_enable_comb_bsd_top #(
    parameter integer W_FrontReadEnableCombIn = 64,
    parameter integer W_FrontReadEnableCombOut = 64
) (
    input wire [W_FrontReadEnableCombIn-1:0] pi,
    output wire [W_FrontReadEnableCombOut-1:0] po
);
    assign po = {W_FrontReadEnableCombOut{1'b0}};
endmodule
