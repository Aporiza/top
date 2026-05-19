// Formal frontend comb boundary: instruction_FIFO_comb.
// Source: simulator-ff/front-end instruction FIFO comb calculation.
// Role: instruction FIFO combinational update.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module instruction_FIFO_comb_top #(
    parameter integer W_InstructionFifoIn      = 64,
    parameter integer W_InstructionFifoOut     = 64,
    parameter integer W_InstructionCombOut     = 64,
    parameter integer W_InstructionFifoCombIn  = W_InstructionFifoIn + W_InstructionFifoOut,
    parameter integer W_InstructionFifoCombOut = W_InstructionCombOut
) (
    input  wire [W_InstructionFifoCombIn-1:0]  bsd_pi,
    output wire [W_InstructionFifoCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_InstructionFifoIn-1:0]      instruction_fifo_in;
    wire [W_InstructionFifoOut-1:0]     fifo_rd;
    wire [W_InstructionCombOut-1:0]     instruction_fifo_req;
    wire [W_InstructionFifoCombIn-1:0]  instruction_FIFO_comb_bsd_pi;
    wire [W_InstructionFifoCombOut-1:0] instruction_FIFO_comb_bsd_po;

    assign {
        instruction_fifo_in,
        fifo_rd
    } = bsd_pi;

    assign instruction_FIFO_comb_bsd_pi = {
        instruction_fifo_in,
        fifo_rd
    };

    assign {
        instruction_fifo_req
    } = instruction_FIFO_comb_bsd_po;

    assign bsd_po = {
        instruction_fifo_req
    };

    instruction_FIFO_comb_bsd_top #(
        .W_InstructionFifoCombIn(W_InstructionFifoCombIn),
        .W_InstructionFifoCombOut(W_InstructionFifoCombOut)
    ) u_instruction_FIFO_comb_bsd_top (
        .bsd_pi(instruction_FIFO_comb_bsd_pi),
        .bsd_po(instruction_FIFO_comb_bsd_po)
    );

endmodule

module instruction_FIFO_comb_bsd_top #(
    parameter integer W_InstructionFifoCombIn  = 64,
    parameter integer W_InstructionFifoCombOut = 64
) (
    input  wire [W_InstructionFifoCombIn-1:0]  bsd_pi,
    output wire [W_InstructionFifoCombOut-1:0] bsd_po
);

    assign bsd_po = {W_InstructionFifoCombOut{1'b0}};

endmodule
