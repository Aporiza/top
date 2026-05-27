// 前端正式 comb 边界： front_bpu_control_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_bpu_control_comb.
// 作用：生成 BPU 运行/阻塞控制和输入数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_bpu_control_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontBpuControlCombIn(2775 bit) -> FrontBpuControlCombOut(5480 bit)
//
// 输入 FrontBpuControlCombIn = 2775 bit
//   = bpu_in_seed                         2739 bit
//   + fetch_addr_fifo_full_latch_snapshot    1 bit
//   + ptab_full_latch_snapshot               1 bit
//   + global_reset                           1 bit
//   + global_refetch                         1 bit
//   + refetch_address                       32 bit
//   = 合计                                  2775 bit
//
// 输出 FrontBpuControlCombOut = 5480 bit
//   = bpu_stall           1 bit
//   + bpu_can_run         1 bit
//   + bpu_icache_ready    1 bit
//   + bpu_in           2739 bit
//   + bpu_input        2738 bit
//   = 合计               5480 bit
//
// 关键结构展开：
//   bpu_in_seed : BPU_in                2739 bit
//   bpu_in      : BPU_in                2739 bit
//   bpu_input   : BPU_TOP::InputPayload 2738 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_bpu_control_comb Input Bits = 2775, Output Bits = 5480。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module front_bpu_control_comb_top #(
    parameter PC_BITS                  = 32,
    parameter W_BpuIn                  = 2739,  // 实际：2739, 来自 front_top W_BpuIn
    parameter W_BpuInputPayload        = 2738,  // 实际：2738, BPU_TOP::InputPayload，比 BPU_in 少 reset 位
    parameter W_FrontBpuControlCombIn  = W_BpuIn + 2 + 1 + 1 + PC_BITS,  // 实际：2775, W_BpuIn + 2 + 1 + 1 + PC_BITS
    parameter W_FrontBpuControlCombOut = 3 + W_BpuIn + W_BpuInputPayload    // 实际：5480, 3 + W_BpuIn + W_BpuInputPayload
) (
    input  wire [W_FrontBpuControlCombIn-1:0]  front_bpu_control_input_bundle,
    output wire [W_FrontBpuControlCombOut-1:0] front_bpu_control_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontBpuControlCombIn-1:0]  pi;
    wire [W_FrontBpuControlCombOut-1:0] po;
    assign pi = front_bpu_control_input_bundle;
    assign front_bpu_control_output_bundle = po;

    front_bpu_control_comb_bsd_top #(
        .W_FrontBpuControlCombIn(W_FrontBpuControlCombIn),
        .W_FrontBpuControlCombOut(W_FrontBpuControlCombOut)
    ) u_front_bpu_control_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_bpu_control_comb_bsd_top #(
    parameter W_FrontBpuControlCombIn  = 2775,  // 实际：2775, W_BpuIn + 2 + 1 + 1 + PC_BITS
    parameter W_FrontBpuControlCombOut = 5480    // 实际：5480, 3 + BPU_in(2739) + BPU_TOP::InputPayload(2738)
) (
    input  wire [W_FrontBpuControlCombIn-1:0]  pi,
    output wire [W_FrontBpuControlCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontBpuControlCombOut{1'b0}};

endmodule
