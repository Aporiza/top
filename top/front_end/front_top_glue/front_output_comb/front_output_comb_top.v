// 前端正式 comb 边界： front_output_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_output_comb.
// 作用：选择最终前端输出。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_output_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontOutputCombIn(10791 bit) -> FrontOutputCombOut(5393 bit)
//
// 输入 FrontOutputCombIn = 10791 bit
//   = saved_front2back_fifo_out     5395 bit
//   + bypass_front2back_fifo_out    5395 bit
//   + use_front2back_output_bypass     1 bit
//   = 合计                           10791 bit
//
// 输出 FrontOutputCombOut = 5393 bit
//   = out 5393 bit
//   = 合计  5393 bit
//
// 关键结构展开：
//   saved_front2back_fifo_out  : front2back_FIFO_out 5395 bit
//   bypass_front2back_fifo_out : front2back_FIFO_out 5395 bit
//   out                        : front_top_out       5393 bit
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
// 自查确认：front_output_comb Input Bits = 10791, Output Bits = 5393。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module front_output_comb_top #(
    parameter W_Front2BackFifoOut  = 5395,  // 实际：5395，front_top W_Front2BackFifoOut
    parameter W_FrontTopOut        = 5393,  // 实际：5393，front_top W_FrontTopOut
    parameter W_FrontOutputCombIn  =
        W_Front2BackFifoOut + W_Front2BackFifoOut + 1,  // 实际：10791
    parameter W_FrontOutputCombOut =
        W_FrontTopOut                                      // 实际：5393
) (
    input  wire [W_FrontOutputCombIn-1:0]  front_output_input_bundle,
    output wire [W_FrontOutputCombOut-1:0] front_output_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontOutputCombIn-1:0]  pi;
    wire [W_FrontOutputCombOut-1:0] po;
    assign pi = front_output_input_bundle;
    assign front_output_output_bundle = po;

    front_output_comb_bsd_top #(
        .W_FrontOutputCombIn(W_FrontOutputCombIn),
        .W_FrontOutputCombOut(W_FrontOutputCombOut)
    ) u_front_output_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_output_comb_bsd_top #(
    parameter W_FrontOutputCombIn  = 10791,  // 实际：10791
    parameter W_FrontOutputCombOut = 5393    // 实际：5393
) (
    input  wire [W_FrontOutputCombIn-1:0]  pi,
    output wire [W_FrontOutputCombOut-1:0] po
);


`ifdef USE_CPP_GOLDEN_BSD
    `include "slices/cpp_golden/cpp_golden_bsd_macros.vh"
    `CPP_GOLDEN_BSD(front_output_comb, W_FrontOutputCombIn, W_FrontOutputCombOut)
`else
// 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontOutputCombOut{1'b0}};
`endif


endmodule
