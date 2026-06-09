// 前端正式 comb 边界： front_global_control_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_global_control_comb.
// 作用：选择全局 reset/refetch 控制。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_global_control_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontGlobalControlCombIn(67 bit) -> FrontGlobalControlCombOut(34 bit)
//
// 输入 FrontGlobalControlCombIn = 67 bit
//   = reset                               1 bit
//   + backend_refetch                     1 bit
//   + backend_refetch_address            32 bit
//   + predecode_refetch_snapshot          1 bit
//   + predecode_refetch_address_snapshot 32 bit
//   = 合计                                 67 bit
//
// 输出 FrontGlobalControlCombOut = 34 bit
//   = global_reset     1 bit
//   + global_refetch   1 bit
//   + refetch_address 32 bit
//   = 合计              34 bit
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
// 自查确认：front_global_control_comb Input Bits = 67, Output Bits = 34。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module front_global_control_comb_top #(
    parameter PC_BITS                     = 32,
    parameter W_FrontGlobalControlCombIn  = 1 + 1 + PC_BITS + 1 + PC_BITS,  // 实际：67, 1 + 1 + PC_BITS + 1 + PC_BITS
    parameter W_FrontGlobalControlCombOut = 1 + 1 + PC_BITS    // 实际：34, 1 + 1 + PC_BITS
) (
    input  wire [W_FrontGlobalControlCombIn-1:0]  front_global_control_input_bundle,
    output wire [W_FrontGlobalControlCombOut-1:0] front_global_control_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontGlobalControlCombIn-1:0]  pi;
    wire [W_FrontGlobalControlCombOut-1:0] po;
    assign pi = front_global_control_input_bundle;
    assign front_global_control_output_bundle = po;

    front_global_control_comb_bsd_top #(
        .W_FrontGlobalControlCombIn(W_FrontGlobalControlCombIn),
        .W_FrontGlobalControlCombOut(W_FrontGlobalControlCombOut)
    ) u_front_global_control_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_global_control_comb_bsd_top #(
    parameter W_FrontGlobalControlCombIn  = 67,  // 实际：67, 1 + 1 + PC_BITS + 1 + PC_BITS
    parameter W_FrontGlobalControlCombOut = 34    // 实际：34, 1 + 1 + PC_BITS
) (
    input  wire [W_FrontGlobalControlCombIn-1:0]  pi,
    output wire [W_FrontGlobalControlCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontGlobalControlCombOut{1'b0}};

endmodule
