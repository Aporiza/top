// Formal frontend comb boundary: instruction_FIFO_comb.
// Source: simulator-front/front-end instruction FIFO comb calculation.
// Role: instruction FIFO combinational update.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module instruction_FIFO_comb_top #(
    parameter integer W_InstructionFifoIn      = 1636,  // actual: 1636, from front_top W_InstructionFifoIn
    parameter integer W_InstructionFifoOut     = 1635,  // actual: 1635, from front_top W_InstructionFifoOut
    parameter integer W_InstructionCombOut     = 3274,  // actual: 3274, from front_top W_InstructionCombOut
    parameter integer W_InstructionFifoLowData = 576,  // actual: 576, W_PredecodeOut + PC_BITS
    parameter integer INSTRUCTION_FIFO_SIZE    = 32,  // actual: 32, from simulator-front frontend_feature_config.h
    parameter integer W_InstructionFifoCombIn  = W_InstructionFifoIn + W_InstructionFifoOut,  // actual: 3271, W_InstructionFifoIn + W_InstructionFifoOut
    parameter integer W_InstructionFifoCombOut = W_InstructionCombOut    // actual: 3274, W_InstructionCombOut
) (
    input  wire                            aclk,
    input  wire                            aresetn,
    input  wire [W_InstructionFifoIn-1:0]  instruction_fifo_in,
    input  wire [W_InstructionFifoOut-1:0] fifo_rd,
    output wire [W_InstructionCombOut-1:0] instruction_fifo_req
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_InstructionFifoCombIn-1:0]  pi;
    wire [W_InstructionFifoCombOut-1:0] po;
    assign pi = {
        instruction_fifo_in,
        fifo_rd
    };

    assign {
        instruction_fifo_req
    } = po;

    instruction_FIFO_comb_bsd_top #(
        .W_InstructionFifoIn(W_InstructionFifoIn),
        .W_InstructionFifoOut(W_InstructionFifoOut),
        .W_InstructionFifoLowData(W_InstructionFifoLowData),
        .INSTRUCTION_FIFO_SIZE(INSTRUCTION_FIFO_SIZE),
        .W_InstructionFifoCombIn(W_InstructionFifoCombIn),
        .W_InstructionFifoCombOut(W_InstructionFifoCombOut)
    ) u_instruction_FIFO_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

module instruction_FIFO_comb_bsd_top #(
    parameter integer W_InstructionFifoIn      = 1636,  // actual: 1636, from front_top W_InstructionFifoIn
    parameter integer W_InstructionFifoOut     = 1635,  // actual: 1635, from front_top W_InstructionFifoOut
    parameter integer W_InstructionFifoLowData = 576,  // actual: 576, W_PredecodeOut + PC_BITS
    parameter integer INSTRUCTION_FIFO_SIZE    = 32,  // actual: 32, from simulator-front frontend_feature_config.h
    parameter integer W_InstructionFifoCombIn  = 3271,  // actual: 3271, W_InstructionFifoIn + W_InstructionFifoOut
    parameter integer W_InstructionFifoCombOut = 3274    // actual: 3274, W_InstructionCombOut
) (
    input  wire                                    aclk,
    input  wire                                    aresetn,
    input  wire [W_InstructionFifoCombIn-1:0]  pi,
    output wire [W_InstructionFifoCombOut-1:0] po
);

    localparam integer W_InstructionPayload = W_InstructionFifoOut - 3;
    localparam integer W_InstructionHighData =
        W_InstructionPayload - W_InstructionFifoLowData;
    localparam integer W_InstructionCtrlOut =
        W_InstructionFifoCombOut - W_InstructionFifoOut;
    localparam integer PTR_BITS = clog2(INSTRUCTION_FIFO_SIZE);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = (i == 0) ? 1 : i;
        end
    endfunction

    function [PTR_BITS-1:0] ptr_next;
        input [PTR_BITS-1:0] ptr;
        begin
            ptr_next = (ptr == INSTRUCTION_FIFO_SIZE - 1) ?
                {PTR_BITS{1'b0}} : ptr + 1'b1;
        end
    endfunction

    wire [W_InstructionFifoIn-1:0]  fifo_in;
    wire [W_InstructionFifoOut-1:0] unused_fifo_rd;

    assign {
        fifo_in,
        unused_fifo_rd
    } = pi;

    wire [W_InstructionFifoLowData-1:0] write_payload_low =
        fifo_in[W_InstructionFifoLowData-1:0];
    wire read_enable = fifo_in[W_InstructionFifoLowData];
    wire [W_InstructionHighData-1:0] write_payload_high =
        fifo_in[W_InstructionFifoLowData + 1 +: W_InstructionHighData];
    wire write_enable =
        fifo_in[W_InstructionFifoLowData + 1 + W_InstructionHighData];
    wire refetch =
        fifo_in[W_InstructionFifoLowData + 2 + W_InstructionHighData];
    wire reset =
        fifo_in[W_InstructionFifoLowData + 3 + W_InstructionHighData];

    wire [W_InstructionPayload-1:0] write_payload = {
        write_payload_high,
        write_payload_low
    };

    reg [W_InstructionPayload-1:0] fifo_mem [0:INSTRUCTION_FIFO_SIZE-1];
    reg [PTR_BITS-1:0] fifo_head;
    reg [PTR_BITS-1:0] fifo_tail;
    reg [PTR_BITS:0]   fifo_count;

    wire rd_valid = (fifo_count != {(PTR_BITS+1){1'b0}});
    wire [W_InstructionPayload-1:0] rd_payload = fifo_mem[fifo_head];

    wire do_clear = reset || refetch;
    wire do_write = write_enable && !do_clear;
    wire do_read  = read_enable && !do_clear && (rd_valid || do_write);
    wire pop_existing = do_read && rd_valid;
    wire store_write = do_write && ((fifo_count < INSTRUCTION_FIFO_SIZE) || pop_existing);
    wire [PTR_BITS:0] next_count =
        do_clear ? {(PTR_BITS+1){1'b0}} :
        fifo_count
      + {{PTR_BITS{1'b0}}, store_write}
      - {{PTR_BITS{1'b0}}, pop_existing};

    wire next_full = (next_count >= INSTRUCTION_FIFO_SIZE);
    wire next_empty = (next_count == {(PTR_BITS+1){1'b0}});
    wire [W_InstructionPayload-1:0] read_payload =
        rd_valid ? rd_payload : write_payload;

    wire [W_InstructionFifoOut-1:0] out_regs = {
        next_full,
        next_empty,
        do_read,
        do_read ? read_payload :
        (rd_valid ? rd_payload : {W_InstructionPayload{1'b0}})
    };

    assign po = {
        {W_InstructionCtrlOut{1'b0}},
        out_regs
    };

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn || reset || refetch) begin
            fifo_head <= {PTR_BITS{1'b0}};
            fifo_tail <= {PTR_BITS{1'b0}};
            fifo_count <= {(PTR_BITS+1){1'b0}};
        end else begin
            if (store_write) begin
                fifo_mem[fifo_tail] <= write_payload;
                fifo_tail <= ptr_next(fifo_tail);
            end
            if (pop_existing) begin
                fifo_head <= ptr_next(fifo_head);
            end
            fifo_count <= next_count;
        end
    end

endmodule
