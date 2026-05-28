// 前端正式 comb 边界： front_front2back_write_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_front2back_write_comb.
// 作用：生成 front2back FIFO 写入和旁路数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_front2back_write_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontFront2backWriteCombIn(6536 bit) -> FrontFront2backWriteCombOut(10791 bit)
//
// 输入 FrontFront2backWriteCombIn = 6536 bit
//   = fifo_out                     1635 bit
//   + ptab_out                     4851 bit
//   + checker_out                    49 bit
//   + use_front2back_output_bypass    1 bit
//   = 合计                           6536 bit
//
// 输出 FrontFront2backWriteCombOut = 10791 bit
//   = front2back_fifo_in          5396 bit
//   + bypass_front2back_fifo_out  5395 bit
//   = 合计                         10791 bit
//
// 关键结构展开：
//   fifo_out                   : instruction_FIFO_out  1635 bit
//   ptab_out                   : PTAB_out              4851 bit
//   checker_out                : predecode_checker_out   49 bit
//   front2back_fifo_in         : front2back_FIFO_in    5396 bit
//   bypass_front2back_fifo_out : front2back_FIFO_out   5395 bit
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
// 自查确认：front_front2back_write_comb Input Bits = 6536, Output Bits = 10791。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module front_front2back_write_comb_top #(
    parameter W_InstructionFifoOut          = 1635,  // 实际：1635，front_top W_InstructionFifoOut
    parameter W_PtabOut                     = 4851,  // 实际：4851，front_top W_PtabOut
    parameter W_PredecodeCheckerOut         = 49,    // 实际：49，front_top W_PredecodeCheckerOut
    parameter W_Front2BackFifoIn            = 5396,  // 实际：5396，front_top W_Front2BackFifoIn
    parameter W_Front2BackFifoOut           = 5395,  // 实际：5395，front_top W_Front2BackFifoOut
    parameter W_FrontFront2backWriteCombIn  =
        W_InstructionFifoOut + W_PtabOut + W_PredecodeCheckerOut + 1,  // 实际：6536
    parameter W_FrontFront2backWriteCombOut =
        W_Front2BackFifoIn + W_Front2BackFifoOut                       // 实际：10791
) (
    input  wire [W_FrontFront2backWriteCombIn-1:0]  front_front2back_write_input_bundle,
    output wire [W_FrontFront2backWriteCombOut-1:0] front_front2back_write_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontFront2backWriteCombIn-1:0]  pi;
    wire [W_FrontFront2backWriteCombOut-1:0] po;
    assign pi = front_front2back_write_input_bundle;
    assign front_front2back_write_output_bundle = po;

    front_front2back_write_comb_bsd_top #(
        .W_FrontFront2backWriteCombIn(W_FrontFront2backWriteCombIn),
        .W_FrontFront2backWriteCombOut(W_FrontFront2backWriteCombOut)
    ) u_front_front2back_write_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_front2back_write_comb_bsd_top #(
    parameter W_FrontFront2backWriteCombIn  = 6536,   // 实际：6536
    parameter W_FrontFront2backWriteCombOut = 10791   // 实际：10791
) (
    input  wire [W_FrontFront2backWriteCombIn-1:0]  pi,
    output wire [W_FrontFront2backWriteCombOut-1:0] po
);

    localparam [W_FrontFront2backWriteCombOut-1:0] FRONT_FRONT2BACK_WRITE_ZERO = 0;

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = FRONT_FRONT2BACK_WRITE_ZERO;

endmodule
