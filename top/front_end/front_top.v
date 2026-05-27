// 前端顶层连接与训练边界包。
// 源码依据：simulator-front/front-end/front_IO.h,
//           simulator-front/front-end/train_IO.h,
//           simulator-front/front-end/front_top.cpp。
// comb 实例使用语义变量端口；每个 wrapper 内部再拼接 pi/po。

module front_top #(
    parameter FETCH_WIDTH            = 16,
    parameter COMMIT_WIDTH           = 8,
    parameter TN_MAX                 = 4,
    parameter PC_BITS                = 32,
    parameter INST_BITS              = 32,
    parameter PRIVILEGE_BITS         = 2,
    parameter PCPN_BITS              = 3,
    parameter BR_TYPE_BITS           = 3,
    parameter TAGE_IDX_BITS          = 12,
    parameter TAGE_TAG_BITS          = 8,
    parameter PREDECODE_TYPE_BITS    = 2,
    parameter BPU_SCL_META_NTABLE    = 8,
    parameter BPU_SCL_META_IDX_BITS  = 16,
    parameter BPU_SCL_META_SUM_BITS  = 16,
    parameter BPU_LOOP_META_IDX_BITS = 16,
    parameter BPU_LOOP_META_TAG_BITS = 16,
    parameter FETCH_ADDR_FIFO_SIZE   = 32,
    parameter INSTRUCTION_FIFO_SIZE  = 32,
    parameter PTAB_SIZE              = 32,
    parameter FRONT2BACK_FIFO_SIZE   = 64,
    parameter FETCH_ADDR_FIFO_SIZE_BITS =
        6,  // 实际：6, clog2(FETCH_ADDR_FIFO_SIZE + 1), FETCH_ADDR_FIFO_SIZE=32
    parameter INSTRUCTION_FIFO_SIZE_BITS =
        6,  // 实际：6, clog2(INSTRUCTION_FIFO_SIZE + 1), INSTRUCTION_FIFO_SIZE=32
    parameter PTAB_SIZE_BITS =
        6,  // 实际：6, clog2(PTAB_SIZE + 1), PTAB_SIZE=32
    parameter FRONT2BACK_FIFO_SIZE_BITS =
        7,  // 实际：7, clog2(FRONT2BACK_FIFO_SIZE + 1), FRONT2BACK_FIFO_SIZE=64
    parameter W_BackUpdateMeta       =
        COMMIT_WIDTH
      + (2 * PCPN_BITS * COMMIT_WIDTH)
      + (TAGE_IDX_BITS * COMMIT_WIDTH * TN_MAX)
      + (TAGE_TAG_BITS * COMMIT_WIDTH * TN_MAX)
      + COMMIT_WIDTH
      + COMMIT_WIDTH
      + (BPU_SCL_META_SUM_BITS * COMMIT_WIDTH)
      + (BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS * COMMIT_WIDTH)
      + COMMIT_WIDTH
      + COMMIT_WIDTH
      + COMMIT_WIDTH
      + (BPU_LOOP_META_IDX_BITS * COMMIT_WIDTH)
      + (BPU_LOOP_META_TAG_BITS * COMMIT_WIDTH),
    parameter W_FrontOutMeta         =
        FETCH_WIDTH
      + (2 * PCPN_BITS * FETCH_WIDTH)
      + (TAGE_IDX_BITS * FETCH_WIDTH * TN_MAX)
      + (TAGE_TAG_BITS * FETCH_WIDTH * TN_MAX)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (BPU_SCL_META_SUM_BITS * FETCH_WIDTH)
      + (BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS * FETCH_WIDTH)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (BPU_LOOP_META_IDX_BITS * FETCH_WIDTH)
      + (BPU_LOOP_META_TAG_BITS * FETCH_WIDTH),
    parameter W_BpuIn                =
        1
      + COMMIT_WIDTH
      + 1
      + PC_BITS
      + (COMMIT_WIDTH * PC_BITS)
      + COMMIT_WIDTH
      + COMMIT_WIDTH
      + (COMMIT_WIDTH * BR_TYPE_BITS)
      + (COMMIT_WIDTH * PC_BITS)
      + W_BackUpdateMeta
      + 1,
    parameter W_BpuInputPayload      =
        W_BpuIn - 1,  // 实际：2738，BPU_TOP::InputPayload 比 BPU_in 少 reset 位
    parameter W_BpuOut               =
        1
      + PC_BITS
      + 1
      + FETCH_WIDTH
      + PC_BITS
      + (FETCH_WIDTH * PC_BITS)
      + W_FrontOutMeta
      + 1
      + PC_BITS
      + 1
      + 1
      + PC_BITS,
    parameter W_FetchAddressFifoIn   = 1 + 1 + 1 + 1 + PC_BITS,
    parameter W_FetchAddressFifoOut  = 1 + 1 + 1 + PC_BITS,
    parameter W_FetchAddrCombOut     = 2 * W_FetchAddressFifoOut,
    parameter W_PredecodeIn          = INST_BITS + PC_BITS,
    parameter W_PredecodeOut         = PREDECODE_TYPE_BITS + PC_BITS,
    parameter W_PredecodeGroupIn     = FETCH_WIDTH * W_PredecodeIn,
    parameter W_PredecodeGroupOut    = FETCH_WIDTH * W_PredecodeOut,
    parameter W_InstructionFifoIn    =
        1
      + 1
      + 1
      + (FETCH_WIDTH * INST_BITS)
      + (FETCH_WIDTH * PC_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + 1
      + (FETCH_WIDTH * PREDECODE_TYPE_BITS)
      + (FETCH_WIDTH * PC_BITS)
      + PC_BITS,
    parameter W_InstructionFifoOut   =
        1
      + 1
      + 1
      + (FETCH_WIDTH * INST_BITS)
      + (FETCH_WIDTH * PC_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (FETCH_WIDTH * PREDECODE_TYPE_BITS)
      + (FETCH_WIDTH * PC_BITS)
      + PC_BITS,
    parameter W_InstructionCombOut   = 2 * W_InstructionFifoOut,
    parameter W_PtabIn               =
        1
      + 1
      + 1
      + FETCH_WIDTH
      + PC_BITS
      + (FETCH_WIDTH * PC_BITS)
      + W_FrontOutMeta
      + 1
      + 1,
    parameter W_PtabOut              =
        1
      + 1
      + 1
      + FETCH_WIDTH
      + PC_BITS
      + (FETCH_WIDTH * PC_BITS)
      + W_FrontOutMeta,
    parameter W_PtabCombOut          =
        W_PtabOut + 1 + 1 + (W_PtabOut - 1) + 1 + (W_PtabOut - 1) + 1,
    parameter W_PredecodeCheckerIn   =
        FETCH_WIDTH
      + PC_BITS
      + (FETCH_WIDTH * PREDECODE_TYPE_BITS)
      + (FETCH_WIDTH * PC_BITS)
      + PC_BITS,
    parameter W_PredecodeCheckerOut  = FETCH_WIDTH + PC_BITS + 1,
    parameter W_Front2BackFifoIn     =
        1
      + 1
      + 1
      + 1
      + (FETCH_WIDTH * INST_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + FETCH_WIDTH
      + PC_BITS
      + (FETCH_WIDTH * PC_BITS)
      + W_FrontOutMeta,
    parameter W_Front2BackFifoOut    =
        1
      + 1
      + 1
      + (FETCH_WIDTH * INST_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + FETCH_WIDTH
      + PC_BITS
      + (FETCH_WIDTH * PC_BITS)
      + W_FrontOutMeta,
    parameter W_Front2BackCombOut    = 2 * W_Front2BackFifoOut,
    parameter W_BpuOutputPayload     =
        PC_BITS
      + 1
      + PC_BITS
      + 1
      + FETCH_WIDTH
      + W_FrontOutMeta
      + PC_BITS
      + 1
      + 1
      + PC_BITS
      + 1
      + 1
      + PC_BITS,
    parameter W_FrontTopOut          =
        1
      + (FETCH_WIDTH * PC_BITS)
      + (FETCH_WIDTH * INST_BITS)
      + FETCH_WIDTH
      + PC_BITS
      + FETCH_WIDTH
      + (2 * FETCH_WIDTH * PCPN_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (FETCH_WIDTH * TN_MAX * TAGE_IDX_BITS)
      + (FETCH_WIDTH * TN_MAX * TAGE_TAG_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (FETCH_WIDTH * BPU_SCL_META_SUM_BITS)
      + (FETCH_WIDTH * BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (FETCH_WIDTH * BPU_LOOP_META_IDX_BITS)
      + (FETCH_WIDTH * BPU_LOOP_META_TAG_BITS)
) (
    // 时钟与全局控制信号。
    input  wire               aclk,
    input  wire               aresetn,
    input  wire               reset,
    input  wire               refetch,
    input  wire               itlb_flush,
    input  wire               fence_i,
    input  wire [PC_BITS-1:0] refetch_address,
    input  wire               FIFO_read_enable,

    // 后端返回前端的 BPU 训练反馈。
    input  wire [COMMIT_WIDTH-1:0]                                           back2front_valid,
    input  wire [COMMIT_WIDTH*PC_BITS-1:0]                                   predict_base_pc,
    input  wire [COMMIT_WIDTH-1:0]                                           predict_dir,
    input  wire [COMMIT_WIDTH-1:0]                                           actual_dir,
    input  wire [COMMIT_WIDTH*BR_TYPE_BITS-1:0]                              actual_br_type,
    input  wire [COMMIT_WIDTH*PC_BITS-1:0]                                   actual_target,
    input  wire [COMMIT_WIDTH-1:0]                                           alt_pred,
    input  wire [COMMIT_WIDTH*PCPN_BITS-1:0]                                 altpcpn,
    input  wire [COMMIT_WIDTH*PCPN_BITS-1:0]                                 pcpn,
    input  wire [COMMIT_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0]                      tage_idx,
    input  wire [COMMIT_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0]                      tage_tag,
    input  wire [COMMIT_WIDTH-1:0]                                           sc_used,
    input  wire [COMMIT_WIDTH-1:0]                                           sc_pred,
    input  wire [COMMIT_WIDTH*BPU_SCL_META_SUM_BITS-1:0]                     sc_sum,
    input  wire [COMMIT_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS-1:0] sc_idx,
    input  wire [COMMIT_WIDTH-1:0]                                           loop_used,
    input  wire [COMMIT_WIDTH-1:0]                                           loop_hit,
    input  wire [COMMIT_WIDTH-1:0]                                           loop_pred,
    input  wire [COMMIT_WIDTH*BPU_LOOP_META_IDX_BITS-1:0]                    loop_idx,
    input  wire [COMMIT_WIDTH*BPU_LOOP_META_TAG_BITS-1:0]                    loop_tag,

    // CSR 状态与前端 ICache 边界。
    input  wire [31:0]                      csr_status_sstatus,
    input  wire [31:0]                      csr_status_mstatus,
    input  wire [31:0]                      csr_status_satp,
    input  wire [PRIVILEGE_BITS-1:0]        csr_status_privilege,
    input  wire                             icache_read_ready,
    input  wire                             icache_read_complete,
    input  wire                             icache_read_ready_2,
    input  wire                             icache_read_complete_2,
    input  wire [FETCH_WIDTH*INST_BITS-1:0] icache_fetch_group,
    input  wire [FETCH_WIDTH-1:0]           icache_page_fault_inst,
    input  wire [FETCH_WIDTH-1:0]           icache_inst_valid,
    input  wire [PC_BITS-1:0]               icache_fetch_pc,
    input  wire [FETCH_WIDTH*INST_BITS-1:0] icache_fetch_group_2,
    input  wire [FETCH_WIDTH-1:0]           icache_page_fault_inst_2,
    input  wire [FETCH_WIDTH-1:0]           icache_inst_valid_2,
    input  wire [PC_BITS-1:0]               icache_fetch_pc_2,
    output wire                             icache_read_valid,
    output wire [PC_BITS-1:0]               fetch_address,
    output wire                             icache_read_valid_2,
    output wire [PC_BITS-1:0]               fetch_address_2,
    output wire                             icache_invalidate_req,
    output wire                             icache_run_comb_only,

    // 前端输出到后端的接口。
    output wire                                                             FIFO_valid,
    output wire [FETCH_WIDTH*PC_BITS-1:0]                                   pc,
    output wire [FETCH_WIDTH*INST_BITS-1:0]                                 instructions,
    output wire [FETCH_WIDTH-1:0]                                           out_predict_dir,
    output wire [PC_BITS-1:0]                                               predict_next_fetch_address,
    output wire [FETCH_WIDTH-1:0]                                           out_alt_pred,
    output wire [FETCH_WIDTH*PCPN_BITS-1:0]                                 out_altpcpn,
    output wire [FETCH_WIDTH*PCPN_BITS-1:0]                                 out_pcpn,
    output wire [FETCH_WIDTH-1:0]                                           page_fault_inst,
    output wire [FETCH_WIDTH-1:0]                                           inst_valid,
    output wire [FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0]                      out_tage_idx,
    output wire [FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0]                      out_tage_tag,
    output wire [FETCH_WIDTH-1:0]                                           out_sc_used,
    output wire [FETCH_WIDTH-1:0]                                           out_sc_pred,
    output wire [FETCH_WIDTH*BPU_SCL_META_SUM_BITS-1:0]                     out_sc_sum,
    output wire [FETCH_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS-1:0] out_sc_idx,
    output wire [FETCH_WIDTH-1:0]                                           out_loop_used,
    output wire [FETCH_WIDTH-1:0]                                           out_loop_hit,
    output wire [FETCH_WIDTH-1:0]                                           out_loop_pred,
    output wire [FETCH_WIDTH*BPU_LOOP_META_IDX_BITS-1:0]                    out_loop_idx,
    output wire [FETCH_WIDTH*BPU_LOOP_META_TAG_BITS-1:0]                    out_loop_tag
);

    // 本组寄存器对应 front_seq_read/front_seq_write 的前端状态快照。
    // 组合阶段只读取这些旧值；周期末再统一写回新值。
    reg                              predecode_refetch;
    reg  [PC_BITS-1:0]               predecode_refetch_address;
    reg  [31:0]                      front_sim_time;
    reg  [63:0]                      front_stats_cycles;
    reg                              fetch_addr_fifo_full_latch;
    reg                              fetch_addr_fifo_empty_latch;
    reg                              fifo_full_latch;
    reg                              fifo_empty_latch;
    reg                              ptab_full_latch;
    reg                              ptab_empty_latch;
    reg                              front2back_fifo_full_latch;
    reg                              front2back_fifo_empty_latch;
    reg  [W_FetchAddressFifoOut-1:0] fetch_addr_fifo_rd_snapshot_reg;
    reg  [W_InstructionFifoOut-1:0]  fifo_rd_snapshot_reg;
    reg  [W_PtabOut-1:0]             ptab_rd_snapshot_reg;
    reg  [W_Front2BackFifoOut-1:0]   front2back_fifo_rd_snapshot_reg;

    wire               predecode_refetch_snapshot           = predecode_refetch;
    wire [PC_BITS-1:0] predecode_refetch_address_snapshot   = predecode_refetch_address;
    wire [31:0]        front_sim_time_snapshot              = front_sim_time;
    wire [63:0]        front_stats_cycles_snapshot          = front_stats_cycles;
    wire               fetch_addr_fifo_empty_latch_snapshot = fetch_addr_fifo_empty_latch;
    wire               fifo_empty_latch_snapshot            = fifo_empty_latch;
    wire               ptab_empty_latch_snapshot            = ptab_empty_latch;
    wire               front2back_fifo_full_latch_snapshot  = front2back_fifo_full_latch;

    // 第 0 阶段：front_seq_read 的状态快照。
    // 源码对应 front_top.cpp 中进入 front_comb_calc 前读取的寄存器/FIFO/PTAB 旧状态。
    // 这些 wire 不更新状态，只把上一拍保存的值展开给后续组合逻辑使用。
    wire [W_FrontTopOut-1:0]         front_top_out_default                            = {W_FrontTopOut{1'b0}};
    wire [31:0]                      front_sim_time_init                              = front_sim_time_snapshot + 32'd1;
    wire [63:0]                      front_stats_cycles_init                          =
        front_stats_cycles_snapshot + 64'd1;
    wire                             front_state_req_valid_init                       = 1'b0;
    wire [W_BpuIn-1:0]               bpu_in_init                                      = {W_BpuIn{1'b0}};
    wire [W_FetchAddressFifoOut-1:0] fetch_addr_fifo_rd                               = fetch_addr_fifo_rd_snapshot_reg;
    wire [W_InstructionFifoOut-1:0]  fifo_rd                                          = fifo_rd_snapshot_reg;
    wire [W_PtabOut-1:0]             ptab_rd                                          = ptab_rd_snapshot_reg;
    wire [W_Front2BackFifoOut-1:0]   front2back_fifo_rd                               = front2back_fifo_rd_snapshot_reg;
    wire [W_FetchAddressFifoOut-1:0] fetch_addr_fifo_next_rd_init                     = fetch_addr_fifo_rd;
    wire [W_InstructionFifoOut-1:0]  fifo_next_rd_init                                = fifo_rd;
    wire [W_PtabOut-1:0]             ptab_next_rd_init                                = ptab_rd;
    wire [W_Front2BackFifoOut-1:0]   front2back_fifo_next_rd_init                     = front2back_fifo_rd;
    wire                             global_reset_init                                = 1'b0;
    wire                             global_refetch_init                              = 1'b0;
    wire                             icache_ready_init                                = 1'b0;
    wire                             icache_ready_2_init                              = 1'b0;
    wire                             fetch_addr_fifo_read_enable_slot0_init           = 1'b0;
    wire                             fetch_addr_fifo_read_enable_slot1_candidate_init = 1'b0;
    wire                             inst_fifo_read_enable_init                       = 1'b0;
    wire                             ptab_read_enable_init                            = 1'b0;
    wire                             front2back_read_enable_init                      = 1'b0;

    // 下面的各组 *_input_bundle / *_output_bundle 对应 C++ comb 函数的 input/output 结构体。
    // front_top 先用可读变量拼包，再从输出包拆回变量；comb_top 内部只桥接到 BSD 层 pi/po。
    wire               global_reset;
    wire               global_refetch;
    wire [PC_BITS-1:0] global_refetch_address;
    wire [1 + 1 + PC_BITS + 1 + PC_BITS - 1:0] front_global_control_input_bundle = {
        reset,
        refetch,
        refetch_address,
        predecode_refetch_snapshot,
        predecode_refetch_address_snapshot
    };
    wire [1 + 1 + PC_BITS - 1:0] front_global_control_output_bundle;
    assign {
        global_reset,
        global_refetch,
        global_refetch_address
    } = front_global_control_output_bundle;

    // 第 1 阶段：全局控制合成。
    // 源码对应 front_global_control_comb：合并外部 reset/refetch 与 predecode 发现的 refetch。
    // 输出 global_reset/global_refetch/global_refetch_address，后续所有 FIFO/PTAB/BPU 控制都使用这组全局控制。
    front_global_control_comb_top #(
        .PC_BITS(PC_BITS),
        .W_FrontGlobalControlCombIn(1 + 1 + PC_BITS + 1 + PC_BITS),
        .W_FrontGlobalControlCombOut(1 + 1 + PC_BITS)
    ) u_front_global_control_comb_top (
        .front_global_control_input_bundle(front_global_control_input_bundle),
        .front_global_control_output_bundle(front_global_control_output_bundle)
    );

    wire fetch_addr_fifo_read_enable_slot0;
    wire fetch_addr_fifo_read_enable_slot1_candidate;
    wire predecode_can_run_old;
    wire inst_fifo_read_enable;
    wire ptab_read_enable;
    wire front2back_read_enable;
    wire [9 - 1:0] front_read_enable_input_bundle = {
        FIFO_read_enable,
        fetch_addr_fifo_empty_latch_snapshot,
        fifo_empty_latch_snapshot,
        ptab_empty_latch_snapshot,
        front2back_fifo_full_latch_snapshot,
        global_reset,
        global_refetch,
        icache_read_ready,
        icache_read_ready_2
    };
    wire [6 - 1:0] front_read_enable_output_bundle;
    assign {
        fetch_addr_fifo_read_enable_slot0,
        fetch_addr_fifo_read_enable_slot1_candidate,
        predecode_can_run_old,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    } = front_read_enable_output_bundle;
    // 第 2 阶段：读使能生成。
    // 源码对应 front_read_enable_comb：根据后端是否取数、队列空满、ICache ready 和全局清空状态，
    // 决定本拍 fetch address FIFO、instruction FIFO、PTAB 和 front2back FIFO 是否允许读。
    front_read_enable_comb_top #(
        .W_FrontReadEnableCombIn(9),
        .W_FrontReadEnableCombOut(6)
    ) u_front_read_enable_comb_top (
        .front_read_enable_input_bundle(front_read_enable_input_bundle),
        .front_read_enable_output_bundle(front_read_enable_output_bundle)
    );

    wire fetch_addr_fifo_reset;
    wire fetch_addr_fifo_refetch;
    wire fetch_addr_fifo_read_enable;
    wire fifo_reset;
    wire fifo_refetch;
    wire fifo_read_enable;
    wire ptab_reset;
    wire ptab_refetch;
    wire ptab_out_read_enable;
    wire front2back_fifo_reset;
    wire front2back_fifo_refetch;
    wire front2back_fifo_read_enable;
    wire [7 - 1:0] front_read_stage_input_bundle = {
        refetch,
        global_reset,
        global_refetch,
        fetch_addr_fifo_read_enable_slot0,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    };
    wire [12 - 1:0] front_read_stage_output_bundle;
    assign {
        fetch_addr_fifo_reset,
        fetch_addr_fifo_refetch,
        fetch_addr_fifo_read_enable,
        fifo_reset,
        fifo_refetch,
        fifo_read_enable,
        ptab_reset,
        ptab_refetch,
        ptab_out_read_enable,
        front2back_fifo_reset,
        front2back_fifo_refetch,
        front2back_fifo_read_enable
    } = front_read_stage_output_bundle;
    // 第 3 阶段：把读使能转换为四个队列的控制输入。
    // 源码对应 front_read_stage_input_comb：把 global_reset/global_refetch/read_enable
    // 拆成各 FIFO/PTAB 自己的 reset、refetch、read_enable 信号。
    front_read_stage_input_comb_top #(
        .W_FrontReadStageInputCombIn(7),
        .W_FrontReadStageInputCombOut(12)
    ) u_front_read_stage_input_comb_top (
        .front_read_stage_input_bundle(front_read_stage_input_bundle),
        .front_read_stage_output_bundle(front_read_stage_output_bundle)
    );

    // 第 4 阶段：构造 BPU 原始输入。
    // 源码对应 front_top.cpp 中给 BPU_TOP 的 InputPayload 赋值：
    // 后端提交反馈、redirect 信息、预测元数据和 ICache ready 都先汇总到 bpu_in_seed。
    wire [W_BpuIn-1:0] bpu_in_seed = {
        reset,
        back2front_valid,
        refetch,
        refetch_address,
        predict_base_pc,
        predict_dir,
        actual_dir,
        actual_br_type,
        actual_target,
        alt_pred,
        altpcpn,
        pcpn,
        tage_idx,
        tage_tag,
        sc_used,
        sc_pred,
        sc_sum,
        sc_idx,
        loop_used,
        loop_hit,
        loop_pred,
        loop_idx,
        loop_tag,
        icache_read_ready
    };
    wire               bpu_stall;
    wire               bpu_can_run;
    wire               bpu_icache_ready;
    wire [W_BpuIn-1:0]           bpu_in_after_control;
    wire [W_BpuInputPayload-1:0] bpu_input_payload;
    wire [W_BpuIn + 2 + 1 + 1 + PC_BITS - 1:0] front_bpu_control_input_bundle = {
        bpu_in_seed,
        fetch_addr_fifo_full_latch,
        ptab_full_latch,
        global_reset,
        global_refetch,
        global_refetch_address
    };
    wire [3 + W_BpuIn + W_BpuInputPayload - 1:0] front_bpu_control_output_bundle;
    assign {
        bpu_stall,
        bpu_can_run,
        bpu_icache_ready,
        bpu_in_after_control,
        bpu_input_payload
    } = front_bpu_control_output_bundle;
    // 第 5 阶段：BPU 运行控制。
    // 源码对应 front_bpu_control_comb：根据 fetch address FIFO/PTAB 是否满和全局 refetch，
    // 判断 BPU 本拍是否可运行，并生成真正送入 bpu_top 的输入包。
    front_bpu_control_comb_top #(
        .PC_BITS(PC_BITS),
        .W_BpuIn(W_BpuIn),
        .W_BpuInputPayload(W_BpuInputPayload),
        .W_FrontBpuControlCombIn(W_BpuIn + 2 + 1 + 1 + PC_BITS),
        .W_FrontBpuControlCombOut(3 + W_BpuIn + W_BpuInputPayload)
    ) u_front_bpu_control_comb_top (
        .front_bpu_control_input_bundle(front_bpu_control_input_bundle),
        .front_bpu_control_output_bundle(front_bpu_control_output_bundle)
    );

    wire [W_BpuOut-1:0] bpu_output_payload;
    // 第 6 阶段：BPU 子系统。
    // bpu_top 内部继续展开 13 个 BPU 相关 comb wrapper，并保存 BPU_TOP 级别状态寄存器。
    // 当前真实预测逻辑仍需在各 BPU *_bsd_top 内补齐。
    bpu_top #(
        .FETCH_WIDTH(FETCH_WIDTH),
        .COMMIT_WIDTH(COMMIT_WIDTH),
        .TN_MAX(TN_MAX),
        .PC_BITS(PC_BITS),
        .PCPN_BITS(PCPN_BITS),
        .BR_TYPE_BITS(BR_TYPE_BITS),
        .TAGE_IDX_BITS(TAGE_IDX_BITS),
        .TAGE_TAG_BITS(TAGE_TAG_BITS),
        .BPU_SCL_META_NTABLE(BPU_SCL_META_NTABLE),
        .BPU_SCL_META_IDX_BITS(BPU_SCL_META_IDX_BITS),
        .BPU_SCL_META_SUM_BITS(BPU_SCL_META_SUM_BITS),
        .BPU_LOOP_META_IDX_BITS(BPU_LOOP_META_IDX_BITS),
        .BPU_LOOP_META_TAG_BITS(BPU_LOOP_META_TAG_BITS),
        .W_BpuIn(W_BpuIn),
        .W_BpuOut(W_BpuOut)
    ) u_bpu_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .reset(reset),
        .bpu_in(bpu_in_after_control),
        .bpu_out(bpu_output_payload)
    );

    wire                           bpu_output_icache_read_valid;
    wire [PC_BITS-1:0]             bpu_output_fetch_address;
    wire                           bpu_output_ptab_write_enable;
    wire [FETCH_WIDTH-1:0]         bpu_output_predict_dir;
    wire [PC_BITS-1:0]             bpu_output_predict_next_fetch_address;
    wire [FETCH_WIDTH*PC_BITS-1:0] bpu_output_predict_base_pc;
    wire [W_FrontOutMeta-1:0]      bpu_output_meta;
    wire                           bpu_output_two_ahead_valid;
    wire [PC_BITS-1:0]             bpu_output_two_ahead_target;
    wire                           bpu_output_mini_flush_req;
    wire                           bpu_output_mini_flush_correct;
    wire [PC_BITS-1:0]             bpu_output_mini_flush_target;
    assign {
        bpu_output_icache_read_valid,
        bpu_output_fetch_address,
        bpu_output_ptab_write_enable,
        bpu_output_predict_dir,
        bpu_output_predict_next_fetch_address,
        bpu_output_predict_base_pc,
        bpu_output_meta,
        bpu_output_two_ahead_valid,
        bpu_output_two_ahead_target,
        bpu_output_mini_flush_req,
        bpu_output_mini_flush_correct,
        bpu_output_mini_flush_target
    } = bpu_output_payload;

    assign icache_read_valid = bpu_output_icache_read_valid;
    assign fetch_address = bpu_output_fetch_address;
    assign icache_read_valid_2 = 1'b0;
    assign fetch_address_2 = {PC_BITS{1'b0}};
    assign icache_invalidate_req = 1'b0;
    assign icache_run_comb_only = 1'b0;

    // 第 7 阶段：fetch address FIFO。
    // 该 FIFO 保存 BPU 发出的取指地址；输入来自 BPU 输出和第三阶段的 reset/refetch/read 控制。
    // fetch_addr_fifo_req 低位是本拍队首快照，高位是 FIFO 内部写回请求。
    wire [W_FetchAddressFifoIn-1:0] fetch_addr_fifo_in = {
        fetch_addr_fifo_reset,
        fetch_addr_fifo_refetch,
        fetch_addr_fifo_read_enable,
        bpu_output_icache_read_valid,
        bpu_output_fetch_address
    };
    wire [W_FetchAddrCombOut-1:0] fetch_addr_fifo_req;
    wire [W_FetchAddressFifoOut-1:0] fetch_addr_fifo_out =
        fetch_addr_fifo_req[W_FetchAddressFifoOut-1:0];
    fetch_address_FIFO_comb_top #(
        .W_FetchAddressFifoIn(W_FetchAddressFifoIn),
        .W_FetchAddressFifoOut(W_FetchAddressFifoOut),
        .W_FetchAddrCombOut(W_FetchAddrCombOut),
        .FETCH_ADDR_FIFO_SIZE(FETCH_ADDR_FIFO_SIZE),
        .FETCH_ADDR_FIFO_SIZE_BITS(FETCH_ADDR_FIFO_SIZE_BITS)
    ) u_fetch_address_FIFO_comb_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .fetch_addr_fifo_in(fetch_addr_fifo_in),
        .fetch_addr_fifo_rd(fetch_addr_fifo_rd),
        .fetch_addr_fifo_req(fetch_addr_fifo_req)
    );

    // 第 8 阶段：predecode。
    // simulator-front 中 predecode_comb 的正式端口是单条指令粒度：
    // predecode_read_data = inst_word_t(32) + pc_t(32) = 64。
    // front_top 会对 FETCH_WIDTH 路指令逐条调用 predecode_comb，
    // 这里用 generate 展开 16 路，保持每个 predecode_comb_top 的端口仍是 64/34。
    wire [FETCH_WIDTH*PC_BITS-1:0] predecode_fetch_pc_group =
        {FETCH_WIDTH{icache_fetch_pc}};
    wire [W_PredecodeGroupIn-1:0] predecode_input_bundle = {
        icache_fetch_group,
        predecode_fetch_pc_group
    };
    wire [W_PredecodeGroupOut-1:0] predecode_output_bundle;
    wire [W_PredecodeGroupOut-1:0] predecode_result = predecode_output_bundle;

    genvar predecode_lane;
    generate
        for (
            predecode_lane = 0;
            predecode_lane < FETCH_WIDTH;
            predecode_lane = predecode_lane + 1
        ) begin : g_predecode_lane
            wire [W_PredecodeIn-1:0] predecode_lane_input;
            wire [W_PredecodeOut-1:0] predecode_lane_output;

            assign predecode_lane_input = {
                icache_fetch_group[(predecode_lane + 1) * INST_BITS - 1:predecode_lane * INST_BITS],
                predecode_fetch_pc_group[(predecode_lane + 1) * PC_BITS - 1:predecode_lane * PC_BITS]
            };

            assign predecode_output_bundle[(predecode_lane + 1) * W_PredecodeOut - 1:predecode_lane * W_PredecodeOut] =
                predecode_lane_output;

            predecode_comb_top #(
                .INST_BITS(INST_BITS),
                .PC_BITS(PC_BITS),
                .PREDECODE_TYPE_BITS(PREDECODE_TYPE_BITS),
                .W_PredecodeCombIn(W_PredecodeIn),
                .W_PredecodeCombOut(W_PredecodeOut)
            ) u_predecode_comb_top (
                .predecode_input_bundle(predecode_lane_input),
                .predecode_output_bundle(predecode_lane_output)
            );
        end
    endgenerate

    // 第 9 阶段：instruction FIFO。
    // 该 FIFO 保存 ICache 返回的指令、有效位、异常位、预译码结果和下一顺序 PC。
    // 写入条件来自 icache_read_complete，读出条件来自第三阶段的 fifo_read_enable。
    wire [W_InstructionFifoIn-1:0] instruction_fifo_in = {
        fifo_reset,
        fifo_refetch,
        icache_read_complete,
        icache_fetch_group,
        {FETCH_WIDTH{icache_fetch_pc}},
        icache_page_fault_inst,
        icache_inst_valid,
        fifo_read_enable,
        predecode_result,
        (icache_fetch_pc + (FETCH_WIDTH * 4))
    };
    wire [W_InstructionCombOut-1:0] instruction_fifo_req;
    wire [W_InstructionFifoOut-1:0] instruction_fifo_out =
        instruction_fifo_req[W_InstructionFifoOut-1:0];
    instruction_FIFO_comb_top #(
        .W_InstructionFifoIn(W_InstructionFifoIn),
        .W_InstructionFifoOut(W_InstructionFifoOut),
        .W_InstructionCombOut(W_InstructionCombOut),
        .W_InstructionFifoLowData(W_PredecodeGroupOut + PC_BITS),
        .INSTRUCTION_FIFO_SIZE(INSTRUCTION_FIFO_SIZE),
        .INSTRUCTION_FIFO_SIZE_BITS(INSTRUCTION_FIFO_SIZE_BITS)
    ) u_instruction_FIFO_comb_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .instruction_fifo_in(instruction_fifo_in),
        .fifo_rd(fifo_rd),
        .instruction_fifo_req(instruction_fifo_req)
    );

    wire [W_PtabIn-1:0]      ptab_in;
    wire [W_PtabCombOut-1:0] ptab_req;
    wire [W_PtabOut-1:0]     ptab_out = ptab_req[W_PtabOut-1:0];
    // front_ptab_write_comb 的源码输入是 BPU_TOP::OutputPayload，
    // 不是 front_IO.h 里的 BPU_out。BPU_out 展开了每条指令的 base PC，
    // OutputPayload 只保留一个 out_pred_base_pc，并额外带 update_queue_full。
    wire [W_BpuOutputPayload-1:0] bpu_output_payload_for_ptab = {
        bpu_output_fetch_address,
        bpu_output_icache_read_valid,
        bpu_output_predict_next_fetch_address,
        bpu_output_ptab_write_enable,
        bpu_output_predict_dir,
        bpu_output_meta,
        bpu_output_predict_base_pc[PC_BITS-1:0],
        1'b0,
        bpu_output_two_ahead_valid,
        bpu_output_two_ahead_target,
        bpu_output_mini_flush_req,
        bpu_output_mini_flush_correct,
        bpu_output_mini_flush_target
    };
    wire [W_BpuOutputPayload + 3 - 1:0] front_ptab_write_input_bundle = {
        bpu_output_payload_for_ptab,
        global_reset,
        global_refetch,
        ~ptab_full_latch
    };
    wire [W_PtabIn-1:0] front_ptab_write_output_bundle;
    assign ptab_in = front_ptab_write_output_bundle;

    // 第 10 阶段：PTAB 写入口构造。
    // 源码对应 front_ptab_write_comb：把 BPU 预测方向、next PC、base PC 和元数据整理成 PTAB 写入包。
    front_ptab_write_comb_top #(
        .W_BpuOutputPayload(W_BpuOutputPayload),
        .W_PtabIn(W_PtabIn),
        .W_FrontPtabWriteCombIn(W_BpuOutputPayload + 3),
        .W_FrontPtabWriteCombOut(W_PtabIn)
    ) u_front_ptab_write_comb_top (
        .front_ptab_write_input_bundle(front_ptab_write_input_bundle),
        .front_ptab_write_output_bundle(front_ptab_write_output_bundle)
    );

    // 第 11 阶段：PTAB。
    // PTAB 保存预测信息，后续 checker 会把 PTAB 队首预测和 instruction FIFO 队首指令对齐检查。
    PTAB_comb_top #(
        .W_PtabIn(W_PtabIn),
        .W_PtabOut(W_PtabOut),
        .W_PtabCombOut(W_PtabCombOut),
        .PTAB_SIZE(PTAB_SIZE),
        .PTAB_SIZE_BITS(PTAB_SIZE_BITS)
    ) u_PTAB_comb_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .ptab_in(ptab_in),
        .ptab_rd(ptab_rd),
        .ptab_req(ptab_req)
    );

    wire [W_PredecodeCheckerIn-1:0]  checker_in;
    wire [W_PredecodeCheckerOut-1:0] checker_out;
    wire [W_InstructionFifoOut + W_PtabOut - 1:0] front_checker_input_bundle = {
        instruction_fifo_out,
        ptab_out
    };
    wire [W_PredecodeCheckerIn-1:0] front_checker_output_bundle;
    assign checker_in = front_checker_output_bundle;

    // 第 12 阶段：checker 输入构造。
    // 源码对应 front_checker_input_comb：把 instruction FIFO 队首和 PTAB 队首拼成 predecode checker 输入。
    front_checker_input_comb_top #(
        .W_InstructionFifoOut(W_InstructionFifoOut),
        .W_PtabOut(W_PtabOut),
        .W_PredecodeCheckerIn(W_PredecodeCheckerIn),
        .W_FrontCheckerInputCombIn(W_InstructionFifoOut + W_PtabOut),
        .W_FrontCheckerInputCombOut(W_PredecodeCheckerIn)
    ) u_front_checker_input_comb_top (
        .front_checker_input_bundle(front_checker_input_bundle),
        .front_checker_output_bundle(front_checker_output_bundle)
    );

    // 第 13 阶段：predecode checker。
    // checker 判断预译码结果和预测路径是否需要触发 refetch，并输出下一拍保存的 refetch 状态。
    predecode_checker_comb_top #(
        .W_PredecodeCheckerIn(W_PredecodeCheckerIn),
        .W_PredecodeCheckerOut(W_PredecodeCheckerOut),
        .W_PredecodeCheckerCombIn(W_PredecodeCheckerIn),
        .W_PredecodeCheckerCombOut(W_PredecodeCheckerOut)
    ) u_predecode_checker_comb_top (
        .predecode_checker_input_bundle(checker_in),
        .predecode_checker_output_bundle(checker_out)
    );

    wire                           use_front2back_output_bypass = 1'b0;
    wire [W_Front2BackFifoIn-1:0]  front2back_fifo_in;
    wire [W_Front2BackFifoOut-1:0] bypass_front2back_fifo_out;
    wire [W_InstructionFifoOut + W_PtabOut + W_PredecodeCheckerOut + 1 - 1:0]
        front_front2back_write_input_bundle = {
            instruction_fifo_out,
            ptab_out,
            checker_out,
            use_front2back_output_bypass
        };
    wire [W_Front2BackFifoIn + W_Front2BackFifoOut - 1:0]
        front_front2back_write_output_bundle;
    assign {
        front2back_fifo_in,
        bypass_front2back_fifo_out
    } = front_front2back_write_output_bundle;

    // 第 14 阶段：front2back FIFO 写入口构造。
    // 源码对应 front_front2back_write_comb：把指令、预测信息和 checker 结果整理成送后端的队列输入。
    front_front2back_write_comb_top #(
        .W_InstructionFifoOut(W_InstructionFifoOut),
        .W_PtabOut(W_PtabOut),
        .W_PredecodeCheckerOut(W_PredecodeCheckerOut),
        .W_Front2BackFifoIn(W_Front2BackFifoIn),
        .W_Front2BackFifoOut(W_Front2BackFifoOut),
        .W_FrontFront2backWriteCombIn(W_InstructionFifoOut + W_PtabOut + W_PredecodeCheckerOut + 1),
        .W_FrontFront2backWriteCombOut(W_Front2BackFifoIn + W_Front2BackFifoOut)
    ) u_front_front2back_write_comb_top (
        .front_front2back_write_input_bundle(front_front2back_write_input_bundle),
        .front_front2back_write_output_bundle(front_front2back_write_output_bundle)
    );

    wire [W_Front2BackCombOut-1:0] front2back_fifo_req;
    wire [W_Front2BackFifoOut-1:0] front2back_fifo_out =
        front2back_fifo_req[W_Front2BackFifoOut-1:0];
    // 第 15 阶段：front2back FIFO。
    // 该 FIFO 是前端到后端的输出队列；后端通过 FIFO_read_enable 消费队首。
    front2back_FIFO_comb_top #(
        .W_Front2BackFifoIn(W_Front2BackFifoIn),
        .W_Front2BackFifoOut(W_Front2BackFifoOut),
        .W_Front2BackCombOut(W_Front2BackCombOut),
        .FRONT2BACK_FIFO_SIZE(FRONT2BACK_FIFO_SIZE),
        .FRONT2BACK_FIFO_SIZE_BITS(FRONT2BACK_FIFO_SIZE_BITS)
    ) u_front2back_FIFO_comb_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .front2back_fifo_in(front2back_fifo_in),
        .front2back_fifo_rd(front2back_fifo_rd),
        .front2back_fifo_req(front2back_fifo_req)
    );

    wire [W_FrontTopOut-1:0] front_top_out_bus;
    wire [W_Front2BackFifoOut + W_Front2BackFifoOut + 1 - 1:0] front_output_input_bundle = {
        front2back_fifo_out,
        bypass_front2back_fifo_out,
        use_front2back_output_bypass
    };
    wire [W_FrontTopOut-1:0] front_output_output_bundle;
    assign front_top_out_bus = front_output_output_bundle;
    // 第 16 阶段：前端对外输出整理。
    // 源码对应 front_output_comb：选择 front2back FIFO 队首或旁路结果，拆成后端可见的 front.out 字段。
    front_output_comb_top #(
        .W_Front2BackFifoOut(W_Front2BackFifoOut),
        .W_FrontTopOut(W_FrontTopOut),
        .W_FrontOutputCombIn(W_Front2BackFifoOut + W_Front2BackFifoOut + 1),
        .W_FrontOutputCombOut(W_FrontTopOut)
    ) u_front_output_comb_top (
        .front_output_input_bundle(front_output_input_bundle),
        .front_output_output_bundle(front_output_output_bundle)
    );
    assign {
        FIFO_valid,
        pc,
        instructions,
        out_predict_dir,
        predict_next_fetch_address,
        out_alt_pred,
        out_altpcpn,
        out_pcpn,
        page_fault_inst,
        inst_valid,
        out_tage_idx,
        out_tage_tag,
        out_sc_used,
        out_sc_pred,
        out_sc_sum,
        out_sc_idx,
        out_loop_used,
        out_loop_hit,
        out_loop_pred,
        out_loop_idx,
        out_loop_tag
    } = front_top_out_bus;

    // 第 17 阶段：周期末状态写回。
    // 源码对应 front_seq_write：本拍所有组合逻辑已经完成，这里统一更新前端寄存器快照。
    // aresetn 是异步硬复位；reset 是模拟器前端同步清空信号；普通运行时只写回组合阶段产生的新状态。
    wire front_state_req_valid = 1'b1; // front_top.cpp:1802 打开最终状态刷新请求。
    wire               next_predecode_refetch         = checker_out[0];
    wire [PC_BITS-1:0] next_predecode_refetch_address = checker_out[PC_BITS:1];
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            predecode_refetch <= 1'b0;
            predecode_refetch_address <= {PC_BITS{1'b0}};
            front_sim_time <= 32'd0;
            front_stats_cycles <= 64'd0;
            fetch_addr_fifo_full_latch <= 1'b0;
            fetch_addr_fifo_empty_latch <= 1'b1;
            fifo_full_latch <= 1'b0;
            fifo_empty_latch <= 1'b1;
            ptab_full_latch <= 1'b0;
            ptab_empty_latch <= 1'b1;
            front2back_fifo_full_latch <= 1'b0;
            front2back_fifo_empty_latch <= 1'b1;
            fetch_addr_fifo_rd_snapshot_reg <= {W_FetchAddressFifoOut{1'b0}};
            fifo_rd_snapshot_reg <= {W_InstructionFifoOut{1'b0}};
            ptab_rd_snapshot_reg <= {W_PtabOut{1'b0}};
            front2back_fifo_rd_snapshot_reg <= {W_Front2BackFifoOut{1'b0}};
        end else if (reset) begin
            // reset 是前端同步控制信号，用于清空前端状态；aresetn 才是硬复位。
            predecode_refetch <= 1'b0;
            predecode_refetch_address <= {PC_BITS{1'b0}};
            front_sim_time <= 32'd0;
            front_stats_cycles <= 64'd0;
            fetch_addr_fifo_full_latch <= 1'b0;
            fetch_addr_fifo_empty_latch <= 1'b1;
            fifo_full_latch <= 1'b0;
            fifo_empty_latch <= 1'b1;
            ptab_full_latch <= 1'b0;
            ptab_empty_latch <= 1'b1;
            front2back_fifo_full_latch <= 1'b0;
            front2back_fifo_empty_latch <= 1'b1;
            fetch_addr_fifo_rd_snapshot_reg <= {W_FetchAddressFifoOut{1'b0}};
            fifo_rd_snapshot_reg <= {W_InstructionFifoOut{1'b0}};
            ptab_rd_snapshot_reg <= {W_PtabOut{1'b0}};
            front2back_fifo_rd_snapshot_reg <= {W_Front2BackFifoOut{1'b0}};
        end else begin
            front_sim_time <= front_sim_time_init;
            front_stats_cycles <= front_stats_cycles_init;
            if (front_state_req_valid) begin
                predecode_refetch <= next_predecode_refetch;
                predecode_refetch_address <= next_predecode_refetch_address;
                fetch_addr_fifo_full_latch <= fetch_addr_fifo_out[W_FetchAddressFifoOut-1];
                fetch_addr_fifo_empty_latch <= fetch_addr_fifo_out[W_FetchAddressFifoOut-2];
                fifo_full_latch <= instruction_fifo_out[W_InstructionFifoOut-1];
                fifo_empty_latch <= instruction_fifo_out[W_InstructionFifoOut-2];
                ptab_full_latch <= ptab_out[W_PtabOut-2];
                ptab_empty_latch <= ptab_out[W_PtabOut-3];
                front2back_fifo_full_latch <= front2back_fifo_out[W_Front2BackFifoOut-1];
                front2back_fifo_empty_latch <= front2back_fifo_out[W_Front2BackFifoOut-2];
                fetch_addr_fifo_rd_snapshot_reg <= fetch_addr_fifo_out;
                fifo_rd_snapshot_reg <= instruction_fifo_out;
                ptab_rd_snapshot_reg <= ptab_out;
                front2back_fifo_rd_snapshot_reg <= front2back_fifo_out;
            end
        end
    end

endmodule
