// 前端正式 comb 边界： front_checker_input_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_checker_input_comb.
// 作用：根据 instruction FIFO 和 PTAB 输出生成 checker 输入包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_checker_input_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontCheckerInputCombIn(6486 bit) -> FrontCheckerInputCombOut(624 bit)
//
// 输入 FrontCheckerInputCombIn = 6486 bit
//   = fifo_out 1635 bit
//   + ptab_out 4851 bit
//   = 合计       6486 bit
//
// 输出 FrontCheckerInputCombOut = 624 bit
//   = checker_in 624 bit
//   = 合计         624 bit
//
// 关键结构展开：
//   fifo_out   : instruction_FIFO_out 1635 bit
//   ptab_out   : PTAB_out             4851 bit
//   checker_in : predecode_checker_in  624 bit
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
// 自查确认：front_checker_input_comb Input Bits = 6486, Output Bits = 624。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module front_checker_input_comb_top #(
    parameter W_InstructionFifoOut       = 1635,  // 实际：1635，front_top W_InstructionFifoOut
    parameter W_PtabOut                  = 4851,  // 实际：4851，front_top W_PtabOut
    parameter W_PredecodeCheckerIn       = 624,   // 实际：624，front_top W_PredecodeCheckerIn
    parameter W_FrontCheckerInputCombIn  =
        W_InstructionFifoOut + W_PtabOut,          // 实际：6486
    parameter W_FrontCheckerInputCombOut =
        W_PredecodeCheckerIn                       // 实际：624
) (
    input  wire [W_FrontCheckerInputCombIn-1:0]  front_checker_input_bundle,
    output wire [W_FrontCheckerInputCombOut-1:0] front_checker_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontCheckerInputCombIn-1:0]  pi;
    wire [W_FrontCheckerInputCombOut-1:0] po;
    assign pi = front_checker_input_bundle;
    assign front_checker_output_bundle = po;

    front_checker_input_comb_bsd_top #(
        .W_FrontCheckerInputCombIn(W_FrontCheckerInputCombIn),
        .W_FrontCheckerInputCombOut(W_FrontCheckerInputCombOut)
    ) u_front_checker_input_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_checker_input_comb_bsd_top #(
    parameter W_FrontCheckerInputCombIn  = 6486,  // 实际：6486
    parameter W_FrontCheckerInputCombOut = 624    // 实际：624
) (
    input  wire [W_FrontCheckerInputCombIn-1:0]  pi,
    output wire [W_FrontCheckerInputCombOut-1:0] po
);


`ifdef USE_CPP_GOLDEN_BSD
    `include "slices/cpp_golden/cpp_golden_bsd_macros.vh"
    `CPP_GOLDEN_BSD(front_checker_input_comb, W_FrontCheckerInputCombIn, W_FrontCheckerInputCombOut)
`else
// 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontCheckerInputCombOut{1'b0}};
`endif


endmodule
