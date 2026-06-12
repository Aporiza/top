// 前端正式 comb 边界： predecode_checker_comb.
// 源码依据： simulator-front/front-end predecode checker 相关 comb 计算。
// 作用：生成 predecode checker 修正结果。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：predecode_checker_comb
// 来源：train_IO.h / predecode_checker.cpp
// 配置：simulator-front 默认 large 配置
// 接口：PredecodeCheckerCombIn(624 bit) -> PredecodeCheckerCombOut(49 bit)
//
// 输入 PredecodeCheckerCombIn = 624 bit
//   = inp_regs 624 bit
//   = 合计       624 bit
//
// 输出 PredecodeCheckerCombOut = 49 bit
//   = predict_dir_corrected[FETCH_WIDTH]   16 bit
//   + predict_next_fetch_address_corrected 32 bit
//   + predecode_flush_enable                1 bit
//   = 合计                                   49 bit
//
// 关键结构展开：
//   inp_regs : predecode_checker_in 624 bit
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
// 自查确认：predecode_checker_comb Input Bits = 624, Output Bits = 49。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module predecode_checker_comb_top #(
    parameter W_PredecodeCheckerIn      = 624,  // 实际：624, 来自 front_top W_PredecodeCheckerIn
    parameter W_PredecodeCheckerOut     = 49,  // 实际：49, 来自 front_top W_PredecodeCheckerOut
    parameter W_PredecodeCheckerCombIn  = W_PredecodeCheckerIn,  // 实际：624, W_PredecodeCheckerIn
    parameter W_PredecodeCheckerCombOut = W_PredecodeCheckerOut    // 实际：49, W_PredecodeCheckerOut
) (
    input  wire [W_PredecodeCheckerCombIn-1:0]  predecode_checker_input_bundle,
    output wire [W_PredecodeCheckerCombOut-1:0] predecode_checker_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_PredecodeCheckerCombIn-1:0]  pi;
    wire [W_PredecodeCheckerCombOut-1:0] po;
    assign pi = predecode_checker_input_bundle;
    assign predecode_checker_output_bundle = po;

    predecode_checker_comb_bsd_top #(
        .W_PredecodeCheckerCombIn(W_PredecodeCheckerCombIn),
        .W_PredecodeCheckerCombOut(W_PredecodeCheckerCombOut)
    ) u_predecode_checker_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module predecode_checker_comb_bsd_top #(
    parameter W_PredecodeCheckerCombIn  = 624,  // 实际：624, W_PredecodeCheckerIn
    parameter W_PredecodeCheckerCombOut = 49    // 实际：49, W_PredecodeCheckerOut
) (
    input  wire [W_PredecodeCheckerCombIn-1:0]  pi,
    output wire [W_PredecodeCheckerCombOut-1:0] po
);


`ifdef USE_CPP_GOLDEN_BSD
    `include "slices/cpp_golden/cpp_golden_bsd_macros.vh"
    `CPP_GOLDEN_BSD(predecode_checker_comb, W_PredecodeCheckerCombIn, W_PredecodeCheckerCombOut)
`else
// 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_PredecodeCheckerCombOut{1'b0}};
`endif


endmodule
