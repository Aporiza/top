// Frontend top connectivity view.
// Canonical source:
//   simulator-new/front-end/front_IO.h
//   simulator-new/front-end/front_top.cpp
//
// This file is a top-down connection skeleton for the training-expanded
// frontend view:
//   SimCpu::front_cycle() is the order reference.
//   FrontTop::step_bpu() / front_top() is the synthesizable hardware path.
//   FrontTop::step_oracle() is a simulator-only reference branch, kept as an
//   explicit boundary but not driven into hardware output muxes.
//
// Default-profile policy:
//   Keep every branch named for review, but default each visibility switch to
//   the current simulator-new frontend default. CONFIG_BPU and true ICache are
//   on. Oracle, 2-Ahead/NLP, ideal ICache slot1, fetch-to-ICache bypass and
//   ICache-to-predecode bypass are off unless the build enables them.
//
// It shows top-level ports, module-to-module wiring and selected glue logic.
// Module internals such as predictor tables, FIFO storage, ICache RAMs and
// sequential state stay inside each module wrapper or its future slices.

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
    parameter integer ICACHE_LINE_SIZE         = 64,

    // ---------------------------------------------------------------------
    // Branch visibility switches, aligned to simulator-new default config.
    // ---------------------------------------------------------------------
    parameter integer ENABLE_CONFIG_BPU_BRANCH = 1,
    parameter integer ENABLE_ORACLE_BRANCH = 0,
    parameter integer ENABLE_2AHEAD_BRANCH = 0,
    parameter integer ENABLE_ICACHE_SLOT1_BRANCH = 0,
    parameter integer ENABLE_FETCH_TO_ICACHE_BYPASS_BRANCH = 0,
    parameter integer ENABLE_ICACHE_TO_PREDECODE_BYPASS_BRANCH = 0,
    parameter integer ENABLE_FRONT2BACK_OUTPUT_BYPASS_BRANCH = 1,

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
    wire bpu_out_two_ahead_valid;
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
    wire icache_out_read_ready_2;
    wire icache_out_read_complete_2;
    wire [(32 * FETCH_WIDTH)-1:0] icache_out_fetch_group;
    wire [(32 * FETCH_WIDTH)-1:0] icache_out_pc;
    wire [FETCH_WIDTH-1:0] icache_out_page_fault_inst;
    wire [FETCH_WIDTH-1:0] icache_out_inst_valid;
    wire [(32 * FETCH_WIDTH)-1:0] icache_out_fetch_group_2;
    wire [(32 * FETCH_WIDTH)-1:0] icache_out_pc_2;
    wire [FETCH_WIDTH-1:0] icache_out_page_fault_inst_2;
    wire [FETCH_WIDTH-1:0] icache_out_inst_valid_2;

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
    wire predecode_refetch_snapshot;
    wire [31:0] predecode_refetch_address_snapshot;
    wire predecode_refetch_next;
    wire [31:0] predecode_refetch_address_next;

    wire bpu_stall;
    wire bpu_can_run;
    wire bpu_icache_ready;
    wire fetch_address_fifo_read_enable;
    wire instruction_fifo_read_enable;
    wire ptab_read_enable;
    wire front2back_fifo_read_enable;
    wire predecode_read_can_run;
    wire predecode_can_run;
    wire ptab_can_write;
    wire front2back_can_write;

    wire fetch_address_fifo_write_enable;
    wire normal_fetch_address_fifo_write_enable;
    wire can_bypass_fetch_to_icache;
    wire [31:0] fetch_address_fifo_write_address;
    wire icache_normal_invalidate_req;
    wire predecode_flush_icache_invalidate_req;
    wire [W_IcacheIn-1:0] icache_flush_invalidate_bus;
    wire icache_peek_read_ready;
    wire fetch_address_fifo_read_enable_slot1_candidate;
    wire fetch_address_fifo_read_enable_slot1;
    wire fetch_address_fifo_write_enable_primary;
    wire fetch_address_fifo_write_enable_2ahead;
    wire icache_read_valid;
    wire icache_read_valid_2;
    wire [31:0] icache_fetch_address;
    wire [31:0] icache_fetch_address_2;
    wire icache_slot0_data_valid;
    wire icache_slot1_data_valid;
    wire instruction_fifo_write_enable;
    wire instruction_fifo_write_enable_slot0;
    wire instruction_fifo_write_enable_slot1;
    wire [(32 * FETCH_WIDTH)-1:0] icache_selected_fetch_group;
    wire [(32 * FETCH_WIDTH)-1:0] icache_selected_pc_group;
    wire [FETCH_WIDTH-1:0] icache_selected_page_fault_inst;
    wire [FETCH_WIDTH-1:0] icache_selected_inst_valid;
    wire [(32 * FETCH_WIDTH)-1:0] checker_input_instructions;
    wire [FETCH_WIDTH-1:0] checker_input_page_fault_inst;
    wire [FETCH_WIDTH-1:0] checker_input_inst_valid;
    wire [(predecode_type_t_BITS * FETCH_WIDTH)-1:0] checker_input_type;
    wire [(32 * FETCH_WIDTH)-1:0] checker_input_target_address;
    wire [31:0] checker_input_seq_next_pc;
    wire [(32 * FETCH_WIDTH)-1:0] ptab_in_predict_base_pc_group;
    wire [31:0] instruction_fifo_fetch_pc;
    wire [31:0] instruction_fifo_seq_next_pc_raw;
    wire [31:0] instruction_fifo_seq_next_pc;
    wire [31:0] icache_line_mask;
    wire can_bypass_icache_to_predecode;
    wire use_icache_to_predecode_bypass;
    wire can_bypass_front2back_to_output;
    wire front2back_fifo_write_enable;
    wire oracle_branch_selected;

    wire front_output_valid;
    wire [(32 * FETCH_WIDTH)-1:0] front_output_fetch_group;
    wire [FETCH_WIDTH-1:0] front_output_page_fault_inst;
    wire [FETCH_WIDTH-1:0] front_output_inst_valid;
    wire [FETCH_WIDTH-1:0] front_output_predict_dir;
    wire [31:0] front_output_predict_next_fetch_address;
    wire [(32 * FETCH_WIDTH)-1:0] front_output_predict_base_pc;
    wire [W_FrontOutMeta-1:0] front_output_meta;

    wire cfg_bpu_branch;
    wire cfg_oracle_branch;
    wire cfg_2ahead_branch;
    wire cfg_icache_slot1_branch;
    wire cfg_fetch_to_icache_bypass_branch;
    wire cfg_icache_to_predecode_bypass_branch;
    wire cfg_front2back_output_bypass_branch;

    genvar fetch_lane;

    assign cfg_bpu_branch = (ENABLE_CONFIG_BPU_BRANCH != 0);
    assign cfg_oracle_branch = (ENABLE_ORACLE_BRANCH != 0);
    assign cfg_2ahead_branch = (ENABLE_2AHEAD_BRANCH != 0);
    assign cfg_icache_slot1_branch = (ENABLE_ICACHE_SLOT1_BRANCH != 0);
    assign cfg_fetch_to_icache_bypass_branch =
        (ENABLE_FETCH_TO_ICACHE_BYPASS_BRANCH != 0);
    assign cfg_icache_to_predecode_bypass_branch =
        (ENABLE_ICACHE_TO_PREDECODE_BYPASS_BRANCH != 0);
    assign cfg_front2back_output_bypass_branch =
        (ENABLE_FRONT2BACK_OUTPUT_BYPASS_BRANCH != 0);

    // Oracle lives outside front_top() in simulator-new. Keep the boundary
    // visible for training and HTML cross-reference, but do not synthesize
    // an oracle data source into this hardware wrapper.
    assign oracle_branch_selected = cfg_oracle_branch && ~cfg_bpu_branch;

    // front_seq_read() provides the previous cycle's checker-flush snapshot.
    // This skeleton keeps it visible as a named cycle boundary; in the C++
    // simulator it is written by front_seq_write() after checker execution.
    assign predecode_refetch_snapshot = predecode_refetch_next;
    assign predecode_refetch_address_snapshot =
        predecode_refetch_address_next;
    assign predecode_refetch_next = checker_out_predecode_flush_enable;
    assign predecode_refetch_address_next =
        checker_out_predict_next_fetch_address_corrected;

    assign global_reset = reset;
    assign global_refetch = refetch || predecode_refetch_snapshot;
    assign global_refetch_address =
        refetch ? refetch_address :
        predecode_refetch_address_snapshot;

    assign bpu_stall =
        fetch_address_fifo_out_full || ptab_out_full;
    assign bpu_can_run =
        ~bpu_stall || global_reset || global_refetch;
    assign bpu_icache_ready =
        ~fetch_address_fifo_out_full;

    // In USE_TRUE_ICACHE mode front_top.cpp calls icache_peek_ready() before
    // popping fetch_address_FIFO. The wrapper output is named separately here
    // to show that this ready belongs to the peek stage, not the later request.
    assign icache_peek_read_ready = icache_out_read_ready;
    assign fetch_address_fifo_read_enable =
        icache_peek_read_ready &&
        ~fetch_address_fifo_out_empty &&
        ~global_reset &&
        ~global_refetch;
    assign fetch_address_fifo_read_enable_slot1_candidate =
        cfg_icache_slot1_branch &&
        icache_out_read_ready_2 &&
        fetch_address_fifo_read_enable;
    assign fetch_address_fifo_read_enable_slot1 =
        fetch_address_fifo_read_enable_slot1_candidate &&
        ~fetch_address_fifo_out_empty;
    // front_read_enable_comb uses the old read-stage readiness check before
    // PTAB data is popped, so dummy_entry is filtered later in the F2B stage.
    assign predecode_read_can_run =
        ~instruction_fifo_out_empty &&
        ~ptab_out_empty &&
        ~front2back_fifo_out_full &&
        ~global_reset &&
        ~global_refetch;
    assign instruction_fifo_read_enable = predecode_read_can_run;
    assign ptab_read_enable = predecode_read_can_run;
    assign front2back_fifo_read_enable = FIFO_read_enable;

    assign predecode_can_run =
        (predecode_read_can_run && ~ptab_out_dummy_entry) ||
        use_icache_to_predecode_bypass;

    assign ptab_can_write =
        bpu_out_ptab_write_enable &&
        ~ptab_out_full &&
        ~global_reset &&
        ~global_refetch;
    assign front2back_can_write =
        predecode_can_run &&
        ~front2back_fifo_out_full &&
        ~global_reset;

    assign normal_fetch_address_fifo_write_enable =
        bpu_out_icache_read_valid &&
        bpu_can_run &&
        ~global_reset;

    assign can_bypass_fetch_to_icache =
        cfg_fetch_to_icache_bypass_branch &&
        ~fetch_address_fifo_out_read_valid &&
        normal_fetch_address_fifo_write_enable &&
        ~bpu_out_mini_flush_correct &&
        icache_peek_read_ready &&
        ~global_refetch;

    assign fetch_address_fifo_write_enable_primary =
        normal_fetch_address_fifo_write_enable &&
        ~bpu_out_mini_flush_correct &&
        ~can_bypass_fetch_to_icache;
    assign fetch_address_fifo_write_enable_2ahead =
        cfg_2ahead_branch &&
        bpu_out_two_ahead_valid &&
        normal_fetch_address_fifo_write_enable &&
        ~global_reset &&
        ~global_refetch;
    assign fetch_address_fifo_write_enable =
        fetch_address_fifo_write_enable_primary ||
        fetch_address_fifo_write_enable_2ahead;
    assign fetch_address_fifo_write_address =
        fetch_address_fifo_write_enable_primary ? bpu_out_fetch_address :
        fetch_address_fifo_write_enable_2ahead ? bpu_out_two_ahead_target :
        32'b0;

    assign icache_read_valid =
        fetch_address_fifo_out_read_valid ||
        can_bypass_fetch_to_icache;
    assign icache_fetch_address =
        fetch_address_fifo_out_read_valid ?
            fetch_address_fifo_out_fetch_address :
        can_bypass_fetch_to_icache ? bpu_out_fetch_address :
        32'b0;
    assign icache_read_valid_2 =
        cfg_icache_slot1_branch &&
        fetch_address_fifo_read_enable_slot1;
    assign icache_fetch_address_2 =
        icache_read_valid_2 ?
            (fetch_address_fifo_out_fetch_address + (FETCH_WIDTH * 32'd4)) :
            32'b0;

    // Normal ICache stage uses invalidate_req = false. A checker flush issues
    // a later invalidate-only ICache comb call in front_top.cpp after
    // predecode_checker_comb has produced the flush.
    assign icache_normal_invalidate_req = 1'b0;
    assign predecode_flush_icache_invalidate_req =
        checker_out_predecode_flush_enable;
    assign icache_flush_invalidate_bus = {
        1'b0,
        1'b0,
        1'b0,
        1'b0,
        predecode_flush_icache_invalidate_req,
        1'b0,
        32'b0,
        1'b0,
        32'b0,
        csr_status,
        1'b0
    };

    assign icache_slot0_data_valid =
        icache_out_read_complete &&
        icache_read_valid;
    assign icache_slot1_data_valid =
        cfg_icache_slot1_branch &&
        icache_out_read_complete_2 &&
        icache_read_valid_2;
    assign instruction_fifo_write_enable_slot0 =
        ~instruction_fifo_out_full &&
        icache_slot0_data_valid &&
        ~global_reset &&
        ~global_refetch;
    assign instruction_fifo_write_enable_slot1 =
        cfg_icache_slot1_branch &&
        ~instruction_fifo_out_full &&
        icache_slot1_data_valid &&
        ~global_reset &&
        ~global_refetch;
    assign instruction_fifo_write_enable =
        instruction_fifo_write_enable_slot0 ||
        instruction_fifo_write_enable_slot1;
    assign icache_selected_fetch_group =
        instruction_fifo_write_enable_slot0 ?
            icache_out_fetch_group : icache_out_fetch_group_2;
    assign icache_selected_pc_group =
        instruction_fifo_write_enable_slot0 ?
            icache_out_pc : icache_out_pc_2;
    assign icache_selected_page_fault_inst =
        instruction_fifo_write_enable_slot0 ?
            icache_out_page_fault_inst : icache_out_page_fault_inst_2;
    assign icache_selected_inst_valid =
        instruction_fifo_write_enable_slot0 ?
            icache_out_inst_valid : icache_out_inst_valid_2;
    assign instruction_fifo_fetch_pc = icache_selected_pc_group[31:0];
    assign instruction_fifo_seq_next_pc_raw =
        instruction_fifo_fetch_pc + (FETCH_WIDTH * 32'd4);
    assign icache_line_mask = ~(32'd0 + ICACHE_LINE_SIZE - 32'd1);
    assign instruction_fifo_seq_next_pc =
        ((instruction_fifo_seq_next_pc_raw & icache_line_mask) !=
         (instruction_fifo_fetch_pc & icache_line_mask)) ?
            (instruction_fifo_seq_next_pc_raw & icache_line_mask) :
            instruction_fifo_seq_next_pc_raw;

    assign can_bypass_icache_to_predecode =
        cfg_icache_to_predecode_bypass_branch &&
        instruction_fifo_out_empty &&
        ~ptab_out_empty &&
        ~front2back_fifo_out_full &&
        ~global_reset &&
        ~global_refetch &&
        icache_slot0_data_valid;
    assign use_icache_to_predecode_bypass =
        can_bypass_icache_to_predecode &&
        ~ptab_out_dummy_entry;

    assign checker_input_instructions =
        use_icache_to_predecode_bypass ?
            icache_selected_fetch_group : instruction_fifo_out_instructions;
    assign checker_input_page_fault_inst =
        use_icache_to_predecode_bypass ?
            icache_selected_page_fault_inst :
            instruction_fifo_out_page_fault_inst;
    assign checker_input_inst_valid =
        use_icache_to_predecode_bypass ?
            icache_selected_inst_valid : instruction_fifo_out_inst_valid;
    assign checker_input_type =
        use_icache_to_predecode_bypass ?
            predecode_out_type : instruction_fifo_out_predecode_type;
    assign checker_input_target_address =
        use_icache_to_predecode_bypass ?
            predecode_out_target_address :
            instruction_fifo_out_predecode_target_address;
    assign checker_input_seq_next_pc =
        use_icache_to_predecode_bypass ?
            instruction_fifo_seq_next_pc : instruction_fifo_out_seq_next_pc;

    assign can_bypass_front2back_to_output =
        cfg_front2back_output_bypass_branch &&
        front2back_fifo_read_enable &&
        front2back_fifo_out_empty &&
        ~front2back_fifo_out_valid &&
        front2back_can_write;
    assign front2back_fifo_write_enable =
        front2back_can_write && ~can_bypass_front2back_to_output;

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
        icache_normal_invalidate_req,
        icache_read_valid,
        icache_fetch_address,
        icache_read_valid_2,
        icache_fetch_address_2,
        csr_status,
        1'b0
    };

    assign predecode_in_bus = {
        icache_selected_fetch_group,
        icache_selected_pc_group
    };

    assign instruction_fifo_in_bus = {
        global_reset,
        global_refetch,
        instruction_fifo_write_enable,
        icache_selected_fetch_group,
        icache_selected_pc_group,
        icache_selected_page_fault_inst,
        icache_selected_inst_valid,
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
        checker_input_type,
        checker_input_target_address,
        checker_input_seq_next_pc
    };

    assign front2back_fifo_in_bus = {
        global_reset,
        refetch,
        front2back_fifo_write_enable,
        front2back_fifo_read_enable,
        checker_input_instructions,
        checker_input_page_fault_inst,
        checker_input_inst_valid,
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
        .two_ahead_valid(bpu_out_two_ahead_valid),
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
        .icache_read_ready_2(icache_out_read_ready_2),
        .icache_read_complete_2(icache_out_read_complete_2),
        .fetch_group(icache_out_fetch_group),
        .fetch_pc_group(icache_out_pc),
        .page_fault_inst(icache_out_page_fault_inst),
        .inst_valid(icache_out_inst_valid),
        .fetch_group_2(icache_out_fetch_group_2),
        .fetch_pc_group_2(icache_out_pc_2),
        .page_fault_inst_2(icache_out_page_fault_inst_2),
        .inst_valid_2(icache_out_inst_valid_2)
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

    assign front_output_valid =
        can_bypass_front2back_to_output ? 1'b1 : front2back_fifo_out_valid;
    assign front_output_fetch_group =
        can_bypass_front2back_to_output ?
            checker_input_instructions :
            front2back_fifo_out_fetch_group;
    assign front_output_page_fault_inst =
        can_bypass_front2back_to_output ?
            checker_input_page_fault_inst :
            front2back_fifo_out_page_fault_inst;
    assign front_output_inst_valid =
        can_bypass_front2back_to_output ?
            checker_input_inst_valid :
            front2back_fifo_out_inst_valid;
    assign front_output_predict_dir =
        can_bypass_front2back_to_output ?
            checker_out_predict_dir_corrected :
            front2back_fifo_out_predict_dir_corrected;
    assign front_output_predict_next_fetch_address =
        can_bypass_front2back_to_output ?
            checker_out_predict_next_fetch_address_corrected :
            front2back_fifo_out_predict_next_fetch_address_corrected;
    assign front_output_predict_base_pc =
        can_bypass_front2back_to_output ?
            ptab_out_predict_base_pc :
            front2back_fifo_out_predict_base_pc;
    assign front_output_meta =
        can_bypass_front2back_to_output ?
            ptab_out_meta :
            front2back_fifo_out_meta;

    assign FIFO_valid = front_output_valid;
    assign commit_stall = bpu_out_update_queue_full;
    assign pc = front_output_predict_base_pc;
    assign instructions = front_output_fetch_group;
    assign predict_dir_out = front_output_predict_dir;
    assign predict_next_fetch_address =
        front_output_predict_next_fetch_address;
    assign page_fault_inst = front_output_page_fault_inst;
    assign inst_valid = front_output_inst_valid;

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
    } = front_output_meta;

endmodule
