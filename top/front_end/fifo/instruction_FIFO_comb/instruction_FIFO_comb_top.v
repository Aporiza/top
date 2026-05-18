// Formal frontend comb boundary: instruction_FIFO_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/fifo/instruction_FIFO.cpp:147.
// Role: instruction FIFO comb.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module instruction_FIFO_comb_top #(
    parameter integer W_InstructionFifoCombIn = 64,
    parameter integer W_InstructionFifoCombOut = 64
) (
    input wire [W_InstructionFifoCombIn-1:0] instruction_FIFO_comb_in,
    output wire [W_InstructionFifoCombOut-1:0] instruction_FIFO_comb_out
);

    wire [W_InstructionFifoCombIn-1:0] instruction_FIFO_comb_pi;
    wire [W_InstructionFifoCombOut-1:0] instruction_FIFO_comb_po;

    assign instruction_FIFO_comb_pi = instruction_FIFO_comb_in;
    assign instruction_FIFO_comb_out = instruction_FIFO_comb_po;

    instruction_FIFO_comb_bsd_top #(
        .W_InstructionFifoCombIn(W_InstructionFifoCombIn),
        .W_InstructionFifoCombOut(W_InstructionFifoCombOut)
    ) u_instruction_FIFO_comb_bsd_top (
        .pi(instruction_FIFO_comb_pi),
        .po(instruction_FIFO_comb_po)
    );

endmodule

module instruction_FIFO_comb_bsd_top #(
    parameter integer W_InstructionFifoCombIn = 64,
    parameter integer W_InstructionFifoCombOut = 64
) (
    input wire [W_InstructionFifoCombIn-1:0] pi,
    output wire [W_InstructionFifoCombOut-1:0] po
);
    assign po = {W_InstructionFifoCombOut{1'b0}};
endmodule
