// Source struct:
//   instruction_FIFO_in  = {reset, refetch, write_enable, fetch_group, pc,
//                           page_fault_inst, inst_valid, read_enable,
//                           predecode_type, predecode_target_address,
//                           seq_next_pc}
//   instruction_FIFO_out = {full, empty, FIFO_valid, instructions, pc,
//                           page_fault_inst, inst_valid, predecode_type,
//                           predecode_target_address, seq_next_pc}
// FIFO storage and pointers stay internal.

module instruction_fifo_top #(
    parameter integer FETCH_WIDTH = 16,
    parameter integer predecode_type_t_BITS = 2,
    parameter integer W_InstructionFifoIn =
        1 + 1 + 1 + (32 * FETCH_WIDTH) + (32 * FETCH_WIDTH) +
        FETCH_WIDTH + FETCH_WIDTH + 1 + (predecode_type_t_BITS * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) + 32,
    parameter integer W_InstructionFifoOut =
        1 + 1 + 1 + (32 * FETCH_WIDTH) + (32 * FETCH_WIDTH) +
        FETCH_WIDTH + FETCH_WIDTH + (predecode_type_t_BITS * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) + 32
) (
    input wire [W_InstructionFifoIn-1:0] instruction_fifo_in,

    output wire [W_InstructionFifoOut-1:0] instruction_fifo_out,
    output wire full,
    output wire empty,
    output wire FIFO_valid,
    output wire [(32 * FETCH_WIDTH)-1:0] instructions,
    output wire [(32 * FETCH_WIDTH)-1:0] pc,
    output wire [FETCH_WIDTH-1:0] page_fault_inst,
    output wire [FETCH_WIDTH-1:0] inst_valid,
    output wire [(predecode_type_t_BITS * FETCH_WIDTH)-1:0] predecode_type,
    output wire [(32 * FETCH_WIDTH)-1:0] predecode_target_address,
    output wire [31:0] seq_next_pc
);

    wire [W_InstructionFifoIn-1:0]  pi;
    wire [W_InstructionFifoOut-1:0] po;

    wire reset;
    wire refetch;
    wire write_enable;
    wire [(32 * FETCH_WIDTH)-1:0] fetch_group_in;
    wire [(32 * FETCH_WIDTH)-1:0] pc_in;
    wire [FETCH_WIDTH-1:0] page_fault_inst_in;
    wire [FETCH_WIDTH-1:0] inst_valid_in;
    wire read_enable;
    wire [(predecode_type_t_BITS * FETCH_WIDTH)-1:0] predecode_type_in;
    wire [(32 * FETCH_WIDTH)-1:0] predecode_target_address_in;
    wire [31:0] seq_next_pc_in;

    assign {
        reset,
        refetch,
        write_enable,
        fetch_group_in,
        pc_in,
        page_fault_inst_in,
        inst_valid_in,
        read_enable,
        predecode_type_in,
        predecode_target_address_in,
        seq_next_pc_in
    } = instruction_fifo_in;

    assign pi = {
        instruction_fifo_in
    };

    assign {
        full,
        empty,
        FIFO_valid,
        instructions,
        pc,
        page_fault_inst,
        inst_valid,
        predecode_type,
        predecode_target_address,
        seq_next_pc
    } = po;

    assign instruction_fifo_out = po;

    instruction_fifo_bsd_top #(
        .W_InstructionFifoIn(W_InstructionFifoIn),
        .W_InstructionFifoOut(W_InstructionFifoOut)
    ) u_instruction_fifo_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
