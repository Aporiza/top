// Source struct:
//   BPU_in  = front_IO.h::BPU_in
//   BPU_out = BPU_TOP::OutputPayload used by front_top.cpp
// Predictor tables, update queues, history registers and subpredictor state
// stay internal.

module bpu_top #(
    parameter integer FETCH_WIDTH  = 16,
    parameter integer COMMIT_WIDTH = 8,
    parameter integer TN_MAX = 4,
    parameter integer TAGE_IDX_WIDTH = 12,
    parameter integer TAGE_TAG_WIDTH = 8,
    parameter integer BPU_SCL_META_NTABLE = 8,
    parameter integer BPU_SCL_META_IDX_BITS = 16,
    parameter integer BPU_LOOP_META_IDX_BITS = 16,
    parameter integer BPU_LOOP_META_TAG_BITS = 16,
    parameter integer tage_scl_meta_sum_t_BITS = 16,
    parameter integer pcpn_t_BITS = 3,
    parameter integer br_type_t_BITS = 3,
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
    parameter integer W_BackUpdateMeta =
        COMMIT_WIDTH +
        (pcpn_t_BITS * COMMIT_WIDTH) +
        (pcpn_t_BITS * COMMIT_WIDTH) +
        (TAGE_IDX_WIDTH * COMMIT_WIDTH * TN_MAX) +
        (TAGE_TAG_WIDTH * COMMIT_WIDTH * TN_MAX) +
        COMMIT_WIDTH +
        COMMIT_WIDTH +
        (tage_scl_meta_sum_t_BITS * COMMIT_WIDTH) +
        (BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS * COMMIT_WIDTH) +
        COMMIT_WIDTH +
        COMMIT_WIDTH +
        COMMIT_WIDTH +
        (BPU_LOOP_META_IDX_BITS * COMMIT_WIDTH) +
        (BPU_LOOP_META_TAG_BITS * COMMIT_WIDTH),
    parameter integer W_BpuIn =
        1 + COMMIT_WIDTH + 1 + 32 + (32 * COMMIT_WIDTH) +
        COMMIT_WIDTH + COMMIT_WIDTH + (br_type_t_BITS * COMMIT_WIDTH) +
        (32 * COMMIT_WIDTH) + W_BackUpdateMeta + 1,
    parameter integer W_BpuOut =
        32 + 1 + 32 + 1 + W_FrontOutMeta + 32 + 1 + 1 + 32 + 1 + 1 + 32
) (
    input wire [W_BpuIn-1:0] bpu_in,

    output wire [W_BpuOut-1:0] bpu_out,
    output wire icache_read_valid,
    output wire [31:0] fetch_address,
    output wire PTAB_write_enable,
    output wire [31:0] predict_next_fetch_address,
    output wire [FETCH_WIDTH-1:0] predict_dir,
    output wire [31:0] predict_base_pc,
    output wire update_queue_full,
    output wire two_ahead_valid,
    output wire mini_flush_req,
    output wire mini_flush_correct,
    output wire [31:0] two_ahead_target,
    output wire [31:0] mini_flush_target,
    output wire [W_FrontOutMeta-1:0] bpu_meta
);

    wire [W_BpuIn-1:0]  pi;
    wire [W_BpuOut-1:0] po;

    wire reset;
    wire [COMMIT_WIDTH-1:0] back2front_valid;
    wire refetch;
    wire [31:0] refetch_address;
    wire [(32 * COMMIT_WIDTH)-1:0] predict_base_pc_in;
    wire [COMMIT_WIDTH-1:0] predict_dir_in;
    wire [COMMIT_WIDTH-1:0] actual_dir;
    wire [(br_type_t_BITS * COMMIT_WIDTH)-1:0] actual_br_type;
    wire [(32 * COMMIT_WIDTH)-1:0] actual_target;
    wire [W_BackUpdateMeta-1:0] back_update_meta;
    wire icache_read_ready;

    assign {
        reset,
        back2front_valid,
        refetch,
        refetch_address,
        predict_base_pc_in,
        predict_dir_in,
        actual_dir,
        actual_br_type,
        actual_target,
        back_update_meta,
        icache_read_ready
    } = bpu_in;

    assign pi = {
        bpu_in
    };

    assign {
        fetch_address,
        icache_read_valid,
        predict_next_fetch_address,
        PTAB_write_enable,
        predict_dir,
        bpu_meta,
        predict_base_pc,
        update_queue_full,
        two_ahead_valid,
        two_ahead_target,
        mini_flush_req,
        mini_flush_correct,
        mini_flush_target
    } = po;

    assign bpu_out = po;

    bpu_bsd_top #(
        .W_BpuIn(W_BpuIn),
        .W_BpuOut(W_BpuOut)
    ) u_bpu_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
