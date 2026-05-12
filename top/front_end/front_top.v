// Frontend top connectivity view.
// Canonical source:
//   simulator-new-lsu-tmp/front-end/front_IO.h
//   simulator-new-lsu-tmp/front-end/front_top.cpp
//
// This file is a top-down connection skeleton. It shows top-level ports,
// module-to-module wiring and selected glue logic. Module internals such as
// predictor tables, FIFO storage, ICache RAMs and sequential state stay inside
// each module wrapper or its future slices.

module front_top #(
    // ---------------------------------------------------------------------
    // Core/frontend shape constants. Keep simulator names where possible.
    // ---------------------------------------------------------------------
    parameter integer FETCH_WIDTH  = 16,
    parameter integer DECODE_WIDTH = 8,
    parameter integer COMMIT_WIDTH = DECODE_WIDTH,

    parameter integer TN_MAX                   = 4,
    parameter integer TAGE_IDX_WIDTH           = 12,
    parameter integer TAGE_TAG_WIDTH           = 8,
    parameter integer BPU_SCL_META_NTABLE      = 8,
    parameter integer BPU_SCL_META_IDX_BITS    = 16,
    parameter integer BPU_LOOP_META_IDX_BITS   = 16,
    parameter integer BPU_LOOP_META_TAG_BITS   = 16,
    parameter integer tage_scl_meta_sum_t_BITS = 16,
    parameter integer pcpn_t_BITS              = 3,
    parameter integer br_type_t_BITS           = 3,
    parameter integer predecode_type_t_BITS    = 2,

    // ---------------------------------------------------------------------
    // Basic packet widths from front_IO.h.
    // ---------------------------------------------------------------------
    parameter integer W_CsrStatusIO = 32 + 32 + 32 + 2,
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
    parameter integer W_BpuIn =
        1 + COMMIT_WIDTH + 1 + 32 + (32 * COMMIT_WIDTH) +
        COMMIT_WIDTH + COMMIT_WIDTH + (br_type_t_BITS * COMMIT_WIDTH) +
        (32 * COMMIT_WIDTH) + W_BackUpdateMeta + 1,
    parameter integer W_BpuOut =
        32 + 1 + 32 + 1 + W_FrontOutMeta + 32 + 1 + 1 + 32 + 1 + 1 + 32,
    parameter integer W_FetchAddressFifoIn = 1 + 1 + 1 + 1 + 32,
    parameter integer W_FetchAddressFifoOut = 1 + 1 + 1 + 32,
    parameter integer W_IcacheIn = 1 + 1 + 1 + 1 + 1 + 1 + 32 + 1 + 32 +
        W_CsrStatusIO + 1,
    parameter integer W_IcacheOut =
        4 + 14 + (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH +
        (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH + 32 + 32,
    parameter integer W_PredecodeIn = (32 * FETCH_WIDTH) + (32 * FETCH_WIDTH),
    parameter integer W_PredecodeOut =
        (predecode_type_t_BITS * FETCH_WIDTH) + (32 * FETCH_WIDTH),
    parameter integer W_InstructionFifoIn =
        1 + 1 + 1 + (32 * FETCH_WIDTH) + (32 * FETCH_WIDTH) +
        FETCH_WIDTH + FETCH_WIDTH + 1 + (predecode_type_t_BITS * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) + 32,
    parameter integer W_InstructionFifoOut =
        1 + 1 + 1 + (32 * FETCH_WIDTH) + (32 * FETCH_WIDTH) +
        FETCH_WIDTH + FETCH_WIDTH + (predecode_type_t_BITS * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) + 32,
    parameter integer W_PtabIn =
        1 + 1 + 1 + FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) +
        W_FrontOutMeta + 1 + 1,
    parameter integer W_PtabOut =
        1 + 1 + 1 + FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) + W_FrontOutMeta,
    parameter integer W_PredecodeCheckerIn =
        FETCH_WIDTH + 32 + (predecode_type_t_BITS * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) + 32,
    parameter integer W_PredecodeCheckerOut = FETCH_WIDTH + 32 + 1,
    parameter integer W_Front2BackFifoIn =
        1 + 1 + 1 + 1 + (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH +
        FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) + W_FrontOutMeta,
    parameter integer W_Front2BackFifoOut =
        1 + 1 + 1 + (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH +
        FETCH_WIDTH + 32 + (32 * FETCH_WIDTH) + W_FrontOutMeta
) (
    // front_top_in fields.
    input wire reset,
    input wire [COMMIT_WIDTH-1:0] back2front_valid,
    input wire refetch,
    input wire itlb_flush,
    input wire fence_i,
    input wire [31:0] refetch_address,
    input wire [(32 * COMMIT_WIDTH)-1:0] predict_base_pc,
    input wire [COMMIT_WIDTH-1:0] predict_dir_in,
    input wire [COMMIT_WIDTH-1:0] actual_dir,
    input wire [(br_type_t_BITS * COMMIT_WIDTH)-1:0] actual_br_type,
    input wire [(32 * COMMIT_WIDTH)-1:0] actual_target,
    input wire [COMMIT_WIDTH-1:0] alt_pred_in,
    input wire [(pcpn_t_BITS * COMMIT_WIDTH)-1:0] altpcpn_in,
    input wire [(pcpn_t_BITS * COMMIT_WIDTH)-1:0] pcpn_in,
    input wire [(TAGE_IDX_WIDTH * COMMIT_WIDTH * TN_MAX)-1:0] tage_idx_in,
    input wire [(TAGE_TAG_WIDTH * COMMIT_WIDTH * TN_MAX)-1:0] tage_tag_in,
    input wire [COMMIT_WIDTH-1:0] sc_used_in,
    input wire [COMMIT_WIDTH-1:0] sc_pred_in,
    input wire [(tage_scl_meta_sum_t_BITS * COMMIT_WIDTH)-1:0] sc_sum_in,
    input wire [(BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS *
        COMMIT_WIDTH)-1:0] sc_idx_in,
    input wire [COMMIT_WIDTH-1:0] loop_used_in,
    input wire [COMMIT_WIDTH-1:0] loop_hit_in,
    input wire [COMMIT_WIDTH-1:0] loop_pred_in,
    input wire [(BPU_LOOP_META_IDX_BITS * COMMIT_WIDTH)-1:0] loop_idx_in,
    input wire [(BPU_LOOP_META_TAG_BITS * COMMIT_WIDTH)-1:0] loop_tag_in,
    input wire FIFO_read_enable,
    input wire [W_CsrStatusIO-1:0] csr_status,

    // front_top_out fields.
    output wire FIFO_valid,
    output wire commit_stall,
    output wire [(32 * FETCH_WIDTH)-1:0] pc,
    output wire [(32 * FETCH_WIDTH)-1:0] instructions,
    output wire [FETCH_WIDTH-1:0] predict_dir_out,
    output wire [31:0] predict_next_fetch_address,
    output wire [FETCH_WIDTH-1:0] alt_pred_out,
    output wire [(pcpn_t_BITS * FETCH_WIDTH)-1:0] altpcpn_out,
    output wire [(pcpn_t_BITS * FETCH_WIDTH)-1:0] pcpn_out,
    output wire [FETCH_WIDTH-1:0] page_fault_inst,
    output wire [FETCH_WIDTH-1:0] inst_valid,
    output wire [(TAGE_IDX_WIDTH * FETCH_WIDTH * TN_MAX)-1:0] tage_idx_out,
    output wire [(TAGE_TAG_WIDTH * FETCH_WIDTH * TN_MAX)-1:0] tage_tag_out,
    output wire [FETCH_WIDTH-1:0] sc_used_out,
    output wire [FETCH_WIDTH-1:0] sc_pred_out,
    output wire [(tage_scl_meta_sum_t_BITS * FETCH_WIDTH)-1:0] sc_sum_out,
    output wire [(BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS *
        FETCH_WIDTH)-1:0] sc_idx_out,
    output wire [FETCH_WIDTH-1:0] loop_used_out,
    output wire [FETCH_WIDTH-1:0] loop_hit_out,
    output wire [FETCH_WIDTH-1:0] loop_pred_out,
    output wire [(BPU_LOOP_META_IDX_BITS * FETCH_WIDTH)-1:0] loop_idx_out,
    output wire [(BPU_LOOP_META_TAG_BITS * FETCH_WIDTH)-1:0] loop_tag_out
);

    // ---------------------------------------------------------------------
    // 1. Module-to-module buses.
    // ---------------------------------------------------------------------

    wire [W_BpuIn-1:0] bpu_in_bus;
    wire [W_BpuOut-1:0] bpu_out_bus;

    wire [W_FetchAddressFifoIn-1:0] fetch_address_fifo_in_bus;
    wire [W_FetchAddressFifoOut-1:0] fetch_address_fifo_out_bus;

    wire [W_IcacheIn-1:0] icache_in_bus;
    wire [W_IcacheOut-1:0] icache_out_bus;

    wire [W_InstructionFifoIn-1:0] instruction_fifo_in_bus;
    wire [W_InstructionFifoOut-1:0] instruction_fifo_out_bus;

    wire [W_PtabIn-1:0] ptab_in_bus;
    wire [W_PtabOut-1:0] ptab_out_bus;

    wire [W_PredecodeIn-1:0] predecode_in_bus;
    wire [W_PredecodeOut-1:0] predecode_out_bus;

    wire [W_PredecodeCheckerIn-1:0] predecode_checker_in_bus;
    wire [W_PredecodeCheckerOut-1:0] predecode_checker_out_bus;

    wire [W_Front2BackFifoIn-1:0] front2back_fifo_in_bus;
    wire [W_Front2BackFifoOut-1:0] front2back_fifo_out_bus;

    // ---------------------------------------------------------------------
    // 2. Selected fields exposed by wrappers for readable top-level wiring.
    // ---------------------------------------------------------------------

    wire bpu_out_icache_read_valid;
    wire [31:0] bpu_out_fetch_address;
    wire bpu_out_ptab_write_enable;
    wire [31:0] bpu_out_predict_next_fetch_address;
    wire [FETCH_WIDTH-1:0] bpu_out_predict_dir;
    wire [31:0] bpu_out_predict_base_pc;
    wire bpu_out_update_queue_full;
    wire bpu_out_mini_flush_req;
    wire bpu_out_mini_flush_correct;
    wire [31:0] bpu_out_two_ahead_target;
    wire [31:0] bpu_out_mini_flush_target;
    wire [W_FrontOutMeta-1:0] bpu_out_meta;

    wire fetch_address_fifo_out_full;
    wire fetch_address_fifo_out_empty;
    wire fetch_address_fifo_out_read_valid;
    wire [31:0] fetch_address_fifo_out_fetch_address;

    wire icache_out_read_ready;
    wire icache_out_read_complete;
    wire [(32 * FETCH_WIDTH)-1:0] icache_out_fetch_group;
    wire [(32 * FETCH_WIDTH)-1:0] icache_out_pc;
    wire [FETCH_WIDTH-1:0] icache_out_page_fault_inst;
    wire [FETCH_WIDTH-1:0] icache_out_inst_valid;

    wire instruction_fifo_out_full;
    wire instruction_fifo_out_empty;
    wire instruction_fifo_out_FIFO_valid;
    wire [(32 * FETCH_WIDTH)-1:0] instruction_fifo_out_instructions;
    wire [(32 * FETCH_WIDTH)-1:0] instruction_fifo_out_pc;
    wire [FETCH_WIDTH-1:0] instruction_fifo_out_page_fault_inst;
    wire [FETCH_WIDTH-1:0] instruction_fifo_out_inst_valid;
    wire [(predecode_type_t_BITS * FETCH_WIDTH)-1:0]
        instruction_fifo_out_predecode_type;
    wire [(32 * FETCH_WIDTH)-1:0]
        instruction_fifo_out_predecode_target_address;
    wire [31:0] instruction_fifo_out_seq_next_pc;

    wire ptab_out_dummy_entry;
    wire ptab_out_full;
    wire ptab_out_empty;
    wire [FETCH_WIDTH-1:0] ptab_out_predict_dir;
    wire [31:0] ptab_out_predict_next_fetch_address;
    wire [(32 * FETCH_WIDTH)-1:0] ptab_out_predict_base_pc;
    wire [W_FrontOutMeta-1:0] ptab_out_meta;

    wire [(predecode_type_t_BITS * FETCH_WIDTH)-1:0] predecode_out_type;
    wire [(32 * FETCH_WIDTH)-1:0] predecode_out_target_address;

    wire [FETCH_WIDTH-1:0] checker_out_predict_dir_corrected;
    wire [31:0] checker_out_predict_next_fetch_address_corrected;
    wire checker_out_predecode_flush_enable;

    wire front2back_fifo_out_full;
    wire front2back_fifo_out_empty;
    wire front2back_fifo_out_valid;
    wire [(32 * FETCH_WIDTH)-1:0] front2back_fifo_out_fetch_group;
    wire [FETCH_WIDTH-1:0] front2back_fifo_out_page_fault_inst;
    wire [FETCH_WIDTH-1:0] front2back_fifo_out_inst_valid;
    wire [FETCH_WIDTH-1:0] front2back_fifo_out_predict_dir_corrected;
    wire [31:0] front2back_fifo_out_predict_next_fetch_address_corrected;
    wire [(32 * FETCH_WIDTH)-1:0] front2back_fifo_out_predict_base_pc;
    wire [W_FrontOutMeta-1:0] front2back_fifo_out_meta;

    // ---------------------------------------------------------------------
    // 3. Top-level glue that mirrors front_top.cpp mainline.
    // ---------------------------------------------------------------------

    wire global_reset;
    wire global_refetch;
    wire [31:0] global_refetch_address;

    wire bpu_stall;
    wire bpu_can_run;
    wire bpu_icache_ready;
    wire fetch_address_fifo_read_enable;
    wire instruction_fifo_read_enable;
    wire ptab_read_enable;
    wire front2back_fifo_read_enable;
    wire predecode_can_run;
    wire ptab_can_write;
    wire front2back_can_write;

    wire fetch_address_fifo_write_enable;
    wire [31:0] fetch_address_fifo_write_address;
    wire icache_read_valid;
    wire [31:0] icache_fetch_address;
    wire instruction_fifo_write_enable;
    wire [(32 * FETCH_WIDTH)-1:0] ptab_in_predict_base_pc_group;
    wire [31:0] instruction_fifo_seq_next_pc;

    genvar fetch_lane;

    assign global_reset = reset;
    assign global_refetch = refetch || checker_out_predecode_flush_enable;
    assign global_refetch_address =
        refetch ? refetch_address :
        checker_out_predict_next_fetch_address_corrected;

    assign bpu_stall =
        fetch_address_fifo_out_full || ptab_out_full;
    assign bpu_can_run =
        ~bpu_stall || global_reset || global_refetch;
    assign bpu_icache_ready =
        ~fetch_address_fifo_out_full;

    assign fetch_address_fifo_read_enable =
        icache_out_read_ready &&
        ~fetch_address_fifo_out_empty &&
        ~global_reset &&
        ~global_refetch;
    assign predecode_can_run =
        ~instruction_fifo_out_empty &&
        ~ptab_out_empty &&
        ~front2back_fifo_out_full &&
        ~global_reset &&
        ~global_refetch &&
        ~ptab_out_dummy_entry;
    assign instruction_fifo_read_enable = predecode_can_run;
    assign ptab_read_enable = predecode_can_run;
    assign front2back_fifo_read_enable = FIFO_read_enable;

    assign ptab_can_write =
        bpu_out_ptab_write_enable &&
        ~ptab_out_full &&
        ~global_reset &&
        ~global_refetch;
    assign front2back_can_write =
        predecode_can_run &&
        ~front2back_fifo_out_full &&
        ~global_reset;

    assign fetch_address_fifo_write_enable =
        bpu_out_icache_read_valid &&
        bpu_can_run &&
        ~global_reset &&
        ~bpu_out_mini_flush_correct;
    assign fetch_address_fifo_write_address =
        fetch_address_fifo_write_enable ? bpu_out_fetch_address : 32'b0;

    assign icache_read_valid =
        fetch_address_fifo_out_read_valid;
    assign icache_fetch_address =
        fetch_address_fifo_out_fetch_address;
    assign instruction_fifo_write_enable =
        icache_out_read_complete && icache_read_valid;
    assign instruction_fifo_seq_next_pc =
        icache_fetch_address + (FETCH_WIDTH * 32'd4);

    generate
        for (fetch_lane = 0; fetch_lane < FETCH_WIDTH;
             fetch_lane = fetch_lane + 1) begin : gen_ptab_predict_base_pc
            assign ptab_in_predict_base_pc_group
                [(32 * (fetch_lane + 1))-1:(32 * fetch_lane)] =
                    bpu_out_predict_base_pc + (fetch_lane * 32'd4);
        end
    endgenerate

    // ---------------------------------------------------------------------
    // 4. Bus assembly in module data-flow order.
    // ---------------------------------------------------------------------

    assign bpu_in_bus = {
        reset,
        back2front_valid,
        global_refetch,
        global_refetch_address,
        predict_base_pc,
        predict_dir_in,
        actual_dir,
        actual_br_type,
        actual_target,
        alt_pred_in,
        altpcpn_in,
        pcpn_in,
        tage_idx_in,
        tage_tag_in,
        sc_used_in,
        sc_pred_in,
        sc_sum_in,
        sc_idx_in,
        loop_used_in,
        loop_hit_in,
        loop_pred_in,
        loop_idx_in,
        loop_tag_in,
        bpu_icache_ready
    };

    assign fetch_address_fifo_in_bus = {
        global_reset,
        global_refetch,
        fetch_address_fifo_read_enable,
        fetch_address_fifo_write_enable,
        fetch_address_fifo_write_address
    };

    assign icache_in_bus = {
        global_reset,
        global_refetch,
        itlb_flush,
        fence_i,
        1'b0,
        icache_read_valid,
        icache_fetch_address,
        1'b0,
        32'b0,
        csr_status,
        1'b0
    };

    assign predecode_in_bus = {
        icache_out_fetch_group,
        icache_out_pc
    };

    assign instruction_fifo_in_bus = {
        global_reset,
        global_refetch,
        instruction_fifo_write_enable,
        icache_out_fetch_group,
        icache_out_pc,
        icache_out_page_fault_inst,
        icache_out_inst_valid,
        instruction_fifo_read_enable,
        predecode_out_type,
        predecode_out_target_address,
        instruction_fifo_seq_next_pc
    };

    assign ptab_in_bus = {
        global_reset,
        global_refetch,
        ptab_can_write,
        bpu_out_predict_dir,
        bpu_out_predict_next_fetch_address,
        ptab_in_predict_base_pc_group,
        bpu_out_meta,
        ptab_read_enable,
        bpu_out_mini_flush_req
    };

    assign predecode_checker_in_bus = {
        ptab_out_predict_dir,
        ptab_out_predict_next_fetch_address,
        instruction_fifo_out_predecode_type,
        instruction_fifo_out_predecode_target_address,
        instruction_fifo_out_seq_next_pc
    };

    assign front2back_fifo_in_bus = {
        global_reset,
        refetch,
        front2back_can_write,
        front2back_fifo_read_enable,
        instruction_fifo_out_instructions,
        instruction_fifo_out_page_fault_inst,
        instruction_fifo_out_inst_valid,
        checker_out_predict_dir_corrected,
        checker_out_predict_next_fetch_address_corrected,
        ptab_out_predict_base_pc,
        ptab_out_meta
    };

    // ---------------------------------------------------------------------
    // 5. Module instances.
    // ---------------------------------------------------------------------

    bpu_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .COMMIT_WIDTH(COMMIT_WIDTH),
        .TN_MAX(TN_MAX),
        .TAGE_IDX_WIDTH(TAGE_IDX_WIDTH),
        .TAGE_TAG_WIDTH(TAGE_TAG_WIDTH),
        .BPU_SCL_META_NTABLE(BPU_SCL_META_NTABLE),
        .BPU_SCL_META_IDX_BITS(BPU_SCL_META_IDX_BITS),
        .BPU_LOOP_META_IDX_BITS(BPU_LOOP_META_IDX_BITS),
        .BPU_LOOP_META_TAG_BITS(BPU_LOOP_META_TAG_BITS),
        .W_BpuIn(W_BpuIn),
        .W_BpuOut(W_BpuOut),
        .W_FrontOutMeta(W_FrontOutMeta)
    ) bpu (
        .bpu_in(bpu_in_bus),
        .bpu_out(bpu_out_bus),
        .icache_read_valid(bpu_out_icache_read_valid),
        .fetch_address(bpu_out_fetch_address),
        .PTAB_write_enable(bpu_out_ptab_write_enable),
        .predict_next_fetch_address(bpu_out_predict_next_fetch_address),
        .predict_dir(bpu_out_predict_dir),
        .predict_base_pc(bpu_out_predict_base_pc),
        .update_queue_full(bpu_out_update_queue_full),
        .mini_flush_req(bpu_out_mini_flush_req),
        .mini_flush_correct(bpu_out_mini_flush_correct),
        .two_ahead_target(bpu_out_two_ahead_target),
        .mini_flush_target(bpu_out_mini_flush_target),
        .bpu_meta(bpu_out_meta)
    );

    fetch_address_fifo_top #(
        .W_FetchAddressFifoIn(W_FetchAddressFifoIn),
        .W_FetchAddressFifoOut(W_FetchAddressFifoOut)
    ) fetch_address_fifo (
        .fetch_address_fifo_in(fetch_address_fifo_in_bus),
        .fetch_address_fifo_out(fetch_address_fifo_out_bus),
        .full(fetch_address_fifo_out_full),
        .empty(fetch_address_fifo_out_empty),
        .read_valid(fetch_address_fifo_out_read_valid),
        .fetch_address(fetch_address_fifo_out_fetch_address)
    );

    icache_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .W_CsrStatusIO(W_CsrStatusIO),
        .W_IcacheIn(W_IcacheIn),
        .W_IcacheOut(W_IcacheOut)
    ) icache (
        .icache_in(icache_in_bus),
        .icache_out(icache_out_bus),
        .icache_read_ready(icache_out_read_ready),
        .icache_read_complete(icache_out_read_complete),
        .fetch_group(icache_out_fetch_group),
        .fetch_pc_group(icache_out_pc),
        .page_fault_inst(icache_out_page_fault_inst),
        .inst_valid(icache_out_inst_valid)
    );

    predecode_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .W_PredecodeIn(W_PredecodeIn),
        .W_PredecodeOut(W_PredecodeOut)
    ) predecode (
        .predecode_in(predecode_in_bus),
        .predecode_out(predecode_out_bus),
        .predecode_type(predecode_out_type),
        .predecode_target_address(predecode_out_target_address)
    );

    instruction_fifo_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .W_InstructionFifoIn(W_InstructionFifoIn),
        .W_InstructionFifoOut(W_InstructionFifoOut)
    ) instruction_fifo (
        .instruction_fifo_in(instruction_fifo_in_bus),
        .instruction_fifo_out(instruction_fifo_out_bus),
        .full(instruction_fifo_out_full),
        .empty(instruction_fifo_out_empty),
        .FIFO_valid(instruction_fifo_out_FIFO_valid),
        .instructions(instruction_fifo_out_instructions),
        .pc(instruction_fifo_out_pc),
        .page_fault_inst(instruction_fifo_out_page_fault_inst),
        .inst_valid(instruction_fifo_out_inst_valid),
        .predecode_type(instruction_fifo_out_predecode_type),
        .predecode_target_address(
            instruction_fifo_out_predecode_target_address
        ),
        .seq_next_pc(instruction_fifo_out_seq_next_pc)
    );

    ptab_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .TN_MAX(TN_MAX),
        .TAGE_IDX_WIDTH(TAGE_IDX_WIDTH),
        .TAGE_TAG_WIDTH(TAGE_TAG_WIDTH),
        .BPU_SCL_META_NTABLE(BPU_SCL_META_NTABLE),
        .BPU_SCL_META_IDX_BITS(BPU_SCL_META_IDX_BITS),
        .BPU_LOOP_META_IDX_BITS(BPU_LOOP_META_IDX_BITS),
        .BPU_LOOP_META_TAG_BITS(BPU_LOOP_META_TAG_BITS),
        .W_PtabIn(W_PtabIn),
        .W_PtabOut(W_PtabOut),
        .W_FrontOutMeta(W_FrontOutMeta)
    ) ptab (
        .ptab_in(ptab_in_bus),
        .ptab_out(ptab_out_bus),
        .dummy_entry(ptab_out_dummy_entry),
        .full(ptab_out_full),
        .empty(ptab_out_empty),
        .predict_dir(ptab_out_predict_dir),
        .predict_next_fetch_address(ptab_out_predict_next_fetch_address),
        .predict_base_pc(ptab_out_predict_base_pc),
        .ptab_meta(ptab_out_meta)
    );

    predecode_checker_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .W_PredecodeCheckerIn(W_PredecodeCheckerIn),
        .W_PredecodeCheckerOut(W_PredecodeCheckerOut)
    ) predecode_checker (
        .predecode_checker_in(predecode_checker_in_bus),
        .predecode_checker_out(predecode_checker_out_bus),
        .predict_dir_corrected(checker_out_predict_dir_corrected),
        .predict_next_fetch_address_corrected(
            checker_out_predict_next_fetch_address_corrected
        ),
        .predecode_flush_enable(checker_out_predecode_flush_enable)
    );

    front2back_fifo_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .TN_MAX(TN_MAX),
        .TAGE_IDX_WIDTH(TAGE_IDX_WIDTH),
        .TAGE_TAG_WIDTH(TAGE_TAG_WIDTH),
        .BPU_SCL_META_NTABLE(BPU_SCL_META_NTABLE),
        .BPU_SCL_META_IDX_BITS(BPU_SCL_META_IDX_BITS),
        .BPU_LOOP_META_IDX_BITS(BPU_LOOP_META_IDX_BITS),
        .BPU_LOOP_META_TAG_BITS(BPU_LOOP_META_TAG_BITS),
        .W_Front2BackFifoIn(W_Front2BackFifoIn),
        .W_Front2BackFifoOut(W_Front2BackFifoOut),
        .W_FrontOutMeta(W_FrontOutMeta)
    ) front2back_fifo (
        .front2back_fifo_in(front2back_fifo_in_bus),
        .front2back_fifo_out(front2back_fifo_out_bus),
        .full(front2back_fifo_out_full),
        .empty(front2back_fifo_out_empty),
        .front2back_FIFO_valid(front2back_fifo_out_valid),
        .fetch_group(front2back_fifo_out_fetch_group),
        .page_fault_inst(front2back_fifo_out_page_fault_inst),
        .inst_valid(front2back_fifo_out_inst_valid),
        .predict_dir_corrected(front2back_fifo_out_predict_dir_corrected),
        .predict_next_fetch_address_corrected(
            front2back_fifo_out_predict_next_fetch_address_corrected
        ),
        .predict_base_pc(front2back_fifo_out_predict_base_pc),
        .front2back_meta(front2back_fifo_out_meta)
    );

    // ---------------------------------------------------------------------
    // 6. External output assembly.
    // ---------------------------------------------------------------------

    assign FIFO_valid = front2back_fifo_out_valid;
    assign commit_stall = bpu_out_update_queue_full;
    assign pc = front2back_fifo_out_predict_base_pc;
    assign instructions = front2back_fifo_out_fetch_group;
    assign predict_dir_out = front2back_fifo_out_predict_dir_corrected;
    assign predict_next_fetch_address =
        front2back_fifo_out_predict_next_fetch_address_corrected;
    assign page_fault_inst = front2back_fifo_out_page_fault_inst;
    assign inst_valid = front2back_fifo_out_inst_valid;

    assign {
        alt_pred_out,
        altpcpn_out,
        pcpn_out,
        tage_idx_out,
        tage_tag_out,
        sc_used_out,
        sc_pred_out,
        sc_sum_out,
        sc_idx_out,
        loop_used_out,
        loop_hit_out,
        loop_pred_out,
        loop_idx_out,
        loop_tag_out
    } = front2back_fifo_out_meta;

endmodule
