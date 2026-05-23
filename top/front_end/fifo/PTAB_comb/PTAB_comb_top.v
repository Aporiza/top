// Formal frontend comb boundary: PTAB_comb.
// Source: simulator-front/front-end PTAB comb calculation.
// Role: PTAB combinational update.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module PTAB_comb_top #(
    parameter integer W_PtabIn      = 4853,  // actual: 4853, from front_top W_PtabIn
    parameter integer W_PtabOut     = 4851,  // actual: 4851, from front_top W_PtabOut
    parameter integer PTAB_SIZE     = 32,  // actual: 32, from simulator-front frontend_feature_config.h
    parameter integer W_PtabCombIn  = W_PtabIn + W_PtabOut,  // actual: 9704, W_PtabIn + W_PtabOut
    parameter integer W_PtabCombOut = 14561    // actual: 14561, from front_top W_PtabCombOut
) (
    input  wire                     aclk,
    input  wire                     aresetn,
    input  wire [W_PtabIn-1:0]      ptab_in,
    input  wire [W_PtabOut-1:0]     ptab_rd,
    output wire [W_PtabCombOut-1:0] ptab_req
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_PtabCombIn-1:0]  pi;
    wire [W_PtabCombOut-1:0] po;
    assign pi = {
        ptab_in,
        ptab_rd
    };

    assign {
        ptab_req
    } = po;

    PTAB_comb_bsd_top #(
        .W_PtabIn(W_PtabIn),
        .W_PtabOut(W_PtabOut),
        .PTAB_SIZE(PTAB_SIZE),
        .W_PtabCombIn(W_PtabCombIn),
        .W_PtabCombOut(W_PtabCombOut)
    ) u_PTAB_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

module PTAB_comb_bsd_top #(
    parameter integer W_PtabIn      = 4853,  // actual: 4853, from front_top W_PtabIn
    parameter integer W_PtabOut     = 4851,  // actual: 4851, from front_top W_PtabOut
    parameter integer PTAB_SIZE     = 32,  // actual: 32, from simulator-front frontend_feature_config.h
    parameter integer W_PtabCombIn  = 9704,  // actual: 9704, W_PtabIn + W_PtabOut
    parameter integer W_PtabCombOut = 14561    // actual: 14561, from front_top W_PtabCombOut
) (
    input  wire                         aclk,
    input  wire                         aresetn,
    input  wire [W_PtabCombIn-1:0]  pi,
    output wire [W_PtabCombOut-1:0] po
);

    localparam integer W_PtabPayload = W_PtabOut - 3;
    localparam integer W_PtabCtrlOut = W_PtabCombOut - W_PtabOut;
    localparam integer PTR_BITS = clog2(PTAB_SIZE);

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
            ptr_next = (ptr == PTAB_SIZE - 1) ?
                {PTR_BITS{1'b0}} : ptr + 1'b1;
        end
    endfunction

    wire [W_PtabIn-1:0]  ptab_in;
    wire [W_PtabOut-1:0] unused_ptab_rd;

    assign {
        ptab_in,
        unused_ptab_rd
    } = pi;

    wire need_mini_flush = ptab_in[0];
    wire read_enable = ptab_in[1];
    wire [W_PtabPayload-1:0] write_payload =
        ptab_in[W_PtabPayload + 1:2];
    wire write_enable = ptab_in[W_PtabPayload + 2];
    wire refetch = ptab_in[W_PtabPayload + 3];
    wire reset = ptab_in[W_PtabPayload + 4];

    reg [W_PtabPayload-1:0] ptab_mem [0:PTAB_SIZE-1];
    reg                     ptab_dummy_mem [0:PTAB_SIZE-1];
    reg [PTR_BITS-1:0]      ptab_head;
    reg [PTR_BITS-1:0]      ptab_tail;
    reg [PTR_BITS:0]        ptab_count;

    wire rd_valid = (ptab_count != {(PTR_BITS+1){1'b0}});
    wire rd_dummy = ptab_dummy_mem[ptab_head];
    wire [W_PtabPayload-1:0] rd_payload = ptab_mem[ptab_head];

    wire do_clear = reset || refetch;
    wire do_write = write_enable && !do_clear;
    wire push_dummy = do_write && need_mini_flush;
    wire do_read = read_enable && !do_clear && (rd_valid || do_write || push_dummy);
    wire pop_existing = do_read && rd_valid;
    wire bypass_write = do_read && !rd_valid && do_write;
    wire store_write = do_write && !bypass_write && ((ptab_count < PTAB_SIZE) || pop_existing);
    wire store_dummy =
        push_dummy &&
        (((ptab_count + {{PTR_BITS{1'b0}}, store_write}) < PTAB_SIZE) ||
         pop_existing);
    wire [PTR_BITS:0] push_count =
        {{PTR_BITS{1'b0}}, store_write} + {{PTR_BITS{1'b0}}, store_dummy};
    wire [PTR_BITS:0] next_count =
        do_clear ? {(PTR_BITS+1){1'b0}} :
        ptab_count + push_count - {{PTR_BITS{1'b0}}, pop_existing};

    wire read_dummy = rd_valid ? rd_dummy : 1'b0;
    wire [W_PtabPayload-1:0] read_payload =
        rd_valid ? rd_payload : write_payload;

    wire next_full = (next_count >= (PTAB_SIZE - 1));
    wire next_empty = (next_count == {(PTR_BITS+1){1'b0}});

    wire [W_PtabOut-1:0] out_regs = {
        do_read ? read_dummy : (rd_valid ? rd_dummy : 1'b0),
        next_full,
        next_empty,
        do_read ? read_payload :
        (rd_valid ? rd_payload : {W_PtabPayload{1'b0}})
    };

    assign po = {
        {W_PtabCtrlOut{1'b0}},
        out_regs
    };

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn || reset || refetch) begin
            ptab_head <= {PTR_BITS{1'b0}};
            ptab_tail <= {PTR_BITS{1'b0}};
            ptab_count <= {(PTR_BITS+1){1'b0}};
        end else begin
            if (store_write) begin
                ptab_mem[ptab_tail] <= write_payload;
                ptab_dummy_mem[ptab_tail] <= 1'b0;
                ptab_tail <= ptr_next(ptab_tail);
            end
            if (store_dummy) begin
                ptab_mem[store_write ? ptr_next(ptab_tail) : ptab_tail] <= {W_PtabPayload{1'b0}};
                ptab_dummy_mem[store_write ? ptr_next(ptab_tail) : ptab_tail] <= 1'b1;
                ptab_tail <= store_write ? ptr_next(ptr_next(ptab_tail)) : ptr_next(ptab_tail);
            end
            if (pop_existing) begin
                ptab_head <= ptr_next(ptab_head);
            end
            ptab_count <= next_count;
        end
    end

endmodule
