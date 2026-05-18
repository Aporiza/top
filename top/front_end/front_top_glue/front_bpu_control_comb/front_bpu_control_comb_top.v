// Formal frontend comb boundary: front_bpu_control_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/train_IO.h:327 and front_top.cpp:679,1210-1256.
// Role: BPU input and stall control.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module front_bpu_control_comb_top #(
    parameter integer W_FrontBpuControlCombIn = 64,
    parameter integer W_FrontBpuControlCombOut = 64
) (
    input wire [W_FrontBpuControlCombIn-1:0] front_bpu_control_comb_in,
    output wire [W_FrontBpuControlCombOut-1:0] front_bpu_control_comb_out
);

    wire [W_FrontBpuControlCombIn-1:0] front_bpu_control_comb_pi;
    wire [W_FrontBpuControlCombOut-1:0] front_bpu_control_comb_po;

    assign front_bpu_control_comb_pi = front_bpu_control_comb_in;
    assign front_bpu_control_comb_out = front_bpu_control_comb_po;

    front_bpu_control_comb_bsd_top #(
        .W_FrontBpuControlCombIn(W_FrontBpuControlCombIn),
        .W_FrontBpuControlCombOut(W_FrontBpuControlCombOut)
    ) u_front_bpu_control_comb_bsd_top (
        .pi(front_bpu_control_comb_pi),
        .po(front_bpu_control_comb_po)
    );

endmodule

module front_bpu_control_comb_bsd_top #(
    parameter integer W_FrontBpuControlCombIn = 64,
    parameter integer W_FrontBpuControlCombOut = 64
) (
    input wire [W_FrontBpuControlCombIn-1:0] pi,
    output wire [W_FrontBpuControlCombOut-1:0] po
);
    assign po = {W_FrontBpuControlCombOut{1'b0}};
endmodule
