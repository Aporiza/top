// Formal frontend comb boundary: front_output_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/train_IO.h:384 and front_top.cpp:863,1707.
// Role: front_top output assembly.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front_output_comb_top #(
    parameter integer W_FrontOutputCombIn = 64,
    parameter integer W_FrontOutputCombOut = 64
) (
    input wire [W_FrontOutputCombIn-1:0] front_output_comb_in,
    output wire [W_FrontOutputCombOut-1:0] front_output_comb_out
);

    wire [W_FrontOutputCombIn-1:0] front_output_comb_pi;
    wire [W_FrontOutputCombOut-1:0] front_output_comb_po;

    assign front_output_comb_pi = front_output_comb_in;
    assign front_output_comb_out = front_output_comb_po;

    front_output_comb_bsd_top #(
        .W_FrontOutputCombIn(W_FrontOutputCombIn),
        .W_FrontOutputCombOut(W_FrontOutputCombOut)
    ) u_front_output_comb_bsd_top (
        .pi(front_output_comb_pi),
        .po(front_output_comb_po)
    );

endmodule

module front_output_comb_bsd_top #(
    parameter integer W_FrontOutputCombIn = 64,
    parameter integer W_FrontOutputCombOut = 64
) (
    input wire [W_FrontOutputCombIn-1:0] pi,
    output wire [W_FrontOutputCombOut-1:0] po
);
    assign po = {W_FrontOutputCombOut{1'b0}};
endmodule
