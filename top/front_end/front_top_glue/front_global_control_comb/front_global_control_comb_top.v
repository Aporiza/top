// Formal frontend comb boundary: front_global_control_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/train_IO.h:267 and front_top.cpp:613,1009.
// Role: global reset/refetch selection.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front_global_control_comb_top #(
    parameter integer W_FrontGlobalControlCombIn = 64,
    parameter integer W_FrontGlobalControlCombOut = 64
) (
    input wire [W_FrontGlobalControlCombIn-1:0] front_global_control_comb_in,
    output wire [W_FrontGlobalControlCombOut-1:0] front_global_control_comb_out
);

    wire [W_FrontGlobalControlCombIn-1:0] front_global_control_comb_pi;
    wire [W_FrontGlobalControlCombOut-1:0] front_global_control_comb_po;

    assign front_global_control_comb_pi = front_global_control_comb_in;
    assign front_global_control_comb_out = front_global_control_comb_po;

    front_global_control_comb_bsd_top #(
        .W_FrontGlobalControlCombIn(W_FrontGlobalControlCombIn),
        .W_FrontGlobalControlCombOut(W_FrontGlobalControlCombOut)
    ) u_front_global_control_comb_bsd_top (
        .pi(front_global_control_comb_pi),
        .po(front_global_control_comb_po)
    );

endmodule

module front_global_control_comb_bsd_top #(
    parameter integer W_FrontGlobalControlCombIn = 64,
    parameter integer W_FrontGlobalControlCombOut = 64
) (
    input wire [W_FrontGlobalControlCombIn-1:0] pi,
    output wire [W_FrontGlobalControlCombOut-1:0] po
);
    assign po = {W_FrontGlobalControlCombOut{1'b0}};
endmodule
