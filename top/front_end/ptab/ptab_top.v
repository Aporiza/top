// Source struct:
//   PTAB_in  = {reset, refetch, write_enable, predict_dir,
//               predict_next_fetch_address, predict_base_pc, metadata,
//               read_enable, need_mini_flush}
//   PTAB_out = {dummy_entry, full, empty, predict_dir,
//               predict_next_fetch_address, predict_base_pc, metadata}
// PTAB queue storage and pointers stay internal.

module ptab_top #(
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
    parameter integer W_PtabIn =
        1 + 1 + 1 + FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) +
        W_FrontOutMeta + 1 + 1,
    parameter integer W_PtabOut =
        1 + 1 + 1 + FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) + W_FrontOutMeta
) (
    input wire [W_PtabIn-1:0] ptab_in,

    output wire [W_PtabOut-1:0] ptab_out,
    output wire dummy_entry,
    output wire full,
    output wire empty,
    output wire [FETCH_WIDTH-1:0] predict_dir,
    output wire [31:0] predict_next_fetch_address,
    output wire [(32 * FETCH_WIDTH)-1:0] predict_base_pc,
    output wire [W_FrontOutMeta-1:0] ptab_meta
);

    wire [W_PtabIn-1:0]  pi;
    wire [W_PtabOut-1:0] po;

    wire reset;
    wire refetch;
    wire write_enable;
    wire [FETCH_WIDTH-1:0] predict_dir_in;
    wire [31:0] predict_next_fetch_address_in;
    wire [(32 * FETCH_WIDTH)-1:0] predict_base_pc_in;
    wire [W_FrontOutMeta-1:0] ptab_meta_in;
    wire read_enable;
    wire need_mini_flush;

    assign {
        reset,
        refetch,
        write_enable,
        predict_dir_in,
        predict_next_fetch_address_in,
        predict_base_pc_in,
        ptab_meta_in,
        read_enable,
        need_mini_flush
    } = ptab_in;

    assign pi = {
        ptab_in
    };

    assign {
        dummy_entry,
        full,
        empty,
        predict_dir,
        predict_next_fetch_address,
        predict_base_pc,
        ptab_meta
    } = po;

    assign ptab_out = po;

    ptab_bsd_top #(
        .W_PtabIn(W_PtabIn),
        .W_PtabOut(W_PtabOut)
    ) u_ptab_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
