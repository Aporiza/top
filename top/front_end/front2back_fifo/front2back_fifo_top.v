// Source struct:
//   front2back_FIFO_in  = {reset, refetch, write_enable, read_enable,
//                          fetch_group, page_fault_inst, inst_valid,
//                          predict_dir_corrected,
//                          predict_next_fetch_address_corrected,
//                          predict_base_pc, metadata}
//   front2back_FIFO_out = {full, empty, front2back_FIFO_valid, fetch_group,
//                          page_fault_inst, inst_valid, predict_dir_corrected,
//                          predict_next_fetch_address_corrected,
//                          predict_base_pc, metadata}
// FIFO storage and pointers stay internal.

module front2back_fifo_top #(
    parameter integer FETCH_WIDTH = 16,
    parameter integer TN_MAX = 4,
    parameter integer TAGE_IDX_WIDTH = 12,
    parameter integer TAGE_TAG_WIDTH = 8,
    parameter integer BPU_SCL_META_NTABLE = 8,
    parameter integer BPU_SCL_META_IDX_BITS = 16,
    parameter integer BPU_LOOP_META_IDX_BITS = 16,
    parameter integer BPU_LOOP_META_TAG_BITS = 16,
    parameter integer tage_scl_meta_sum_t_BITS = 16,
    parameter integer pcpn_t_BITS = 3,
    parameter integer W_FrontOutMeta =
        FETCH_WIDTH +
        (pcpn_t_BITS * FETCH_WIDTH) +
        (pcpn_t_BITS * FETCH_WIDTH) +
        (TAGE_IDX_WIDTH * FETCH_WIDTH * TN_MAX) +
        (TAGE_TAG_WIDTH * FETCH_WIDTH * TN_MAX) +
        FETCH_WIDTH +
        FETCH_WIDTH +
        (tage_scl_meta_sum_t_BITS * FETCH_WIDTH) +
        (BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS * FETCH_WIDTH) +
        FETCH_WIDTH +
        FETCH_WIDTH +
        FETCH_WIDTH +
        (BPU_LOOP_META_IDX_BITS * FETCH_WIDTH) +
        (BPU_LOOP_META_TAG_BITS * FETCH_WIDTH),
    parameter integer W_Front2BackFifoIn =
        1 + 1 + 1 + 1 + (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH +
        FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) + W_FrontOutMeta,
    parameter integer W_Front2BackFifoOut =
        1 + 1 + 1 + (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH +
        FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) + W_FrontOutMeta
) (
    input wire [W_Front2BackFifoIn-1:0] front2back_fifo_in,

    output wire [W_Front2BackFifoOut-1:0] front2back_fifo_out,
    output wire full,
    output wire empty,
    output wire front2back_FIFO_valid,
    output wire [(32 * FETCH_WIDTH)-1:0] fetch_group,
    output wire [FETCH_WIDTH-1:0] page_fault_inst,
    output wire [FETCH_WIDTH-1:0] inst_valid,
    output wire [FETCH_WIDTH-1:0] predict_dir_corrected,
    output wire [31:0] predict_next_fetch_address_corrected,
    output wire [(32 * FETCH_WIDTH)-1:0] predict_base_pc,
    output wire [W_FrontOutMeta-1:0] front2back_meta
);

    wire [W_Front2BackFifoIn-1:0]  pi;
    wire [W_Front2BackFifoOut-1:0] po;

    wire reset;
    wire refetch;
    wire write_enable;
    wire read_enable;
    wire [(32 * FETCH_WIDTH)-1:0] fetch_group_in;
    wire [FETCH_WIDTH-1:0] page_fault_inst_in;
    wire [FETCH_WIDTH-1:0] inst_valid_in;
    wire [FETCH_WIDTH-1:0] predict_dir_corrected_in;
    wire [31:0] predict_next_fetch_address_corrected_in;
    wire [(32 * FETCH_WIDTH)-1:0] predict_base_pc_in;
    wire [W_FrontOutMeta-1:0] front2back_meta_in;

    assign {
        reset,
        refetch,
        write_enable,
        read_enable,
        fetch_group_in,
        page_fault_inst_in,
        inst_valid_in,
        predict_dir_corrected_in,
        predict_next_fetch_address_corrected_in,
        predict_base_pc_in,
        front2back_meta_in
    } = front2back_fifo_in;

    assign pi = {
        front2back_fifo_in
    };

    assign {
        full,
        empty,
        front2back_FIFO_valid,
        fetch_group,
        page_fault_inst,
        inst_valid,
        predict_dir_corrected,
        predict_next_fetch_address_corrected,
        predict_base_pc,
        front2back_meta
    } = po;

    assign front2back_fifo_out = po;

    front2back_fifo_bsd_top #(
        .W_Front2BackFifoIn(W_Front2BackFifoIn),
        .W_Front2BackFifoOut(W_Front2BackFifoOut)
    ) u_front2back_fifo_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
