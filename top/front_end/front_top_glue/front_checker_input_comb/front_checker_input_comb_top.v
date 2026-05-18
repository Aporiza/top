// Formal frontend comb boundary: front_checker_input_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/train_IO.h:363 and front_top.cpp:770,1602-1628.
// Role: checker input assembly.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front_checker_input_comb_top #(
    parameter integer W_FrontCheckerInputCombIn = 64,
    parameter integer W_FrontCheckerInputCombOut = 64
) (
    input wire [W_FrontCheckerInputCombIn-1:0] front_checker_input_comb_in,
    output wire [W_FrontCheckerInputCombOut-1:0] front_checker_input_comb_out
);

    wire [W_FrontCheckerInputCombIn-1:0] front_checker_input_comb_pi;
    wire [W_FrontCheckerInputCombOut-1:0] front_checker_input_comb_po;

    assign front_checker_input_comb_pi = front_checker_input_comb_in;
    assign front_checker_input_comb_out = front_checker_input_comb_po;

    front_checker_input_comb_bsd_top #(
        .W_FrontCheckerInputCombIn(W_FrontCheckerInputCombIn),
        .W_FrontCheckerInputCombOut(W_FrontCheckerInputCombOut)
    ) u_front_checker_input_comb_bsd_top (
        .pi(front_checker_input_comb_pi),
        .po(front_checker_input_comb_po)
    );

endmodule

module front_checker_input_comb_bsd_top #(
    parameter integer W_FrontCheckerInputCombIn = 64,
    parameter integer W_FrontCheckerInputCombOut = 64
) (
    input wire [W_FrontCheckerInputCombIn-1:0] pi,
    output wire [W_FrontCheckerInputCombOut-1:0] po
);
    assign po = {W_FrontCheckerInputCombOut{1'b0}};
endmodule
