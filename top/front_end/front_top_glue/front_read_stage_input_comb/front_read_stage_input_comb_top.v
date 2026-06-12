// 前端正式 comb 边界： front_read_stage_input_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_read_stage_input_comb.
// 作用：生成队列读使能、reset 和 refetch 控制包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_read_stage_input_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontReadStageInputCombIn(7 bit) -> FrontReadStageInputCombOut(12 bit)
//
// 输入 FrontReadStageInputCombIn = 7 bit
//   = backend_refetch                   1 bit
//   + global_reset                      1 bit
//   + global_refetch                    1 bit
//   + fetch_addr_fifo_read_enable_slot0 1 bit
//   + inst_fifo_read_enable             1 bit
//   + ptab_read_enable                  1 bit
//   + front2back_read_enable            1 bit
//   = 合计                                7 bit
//
// 输出 FrontReadStageInputCombOut = 12 bit
//   = fetch_addr_fifo_reset        1 bit
//   + fetch_addr_fifo_refetch      1 bit
//   + fetch_addr_fifo_read_enable  1 bit
//   + fifo_reset                   1 bit
//   + fifo_refetch                 1 bit
//   + fifo_read_enable             1 bit
//   + ptab_reset                   1 bit
//   + ptab_refetch                 1 bit
//   + ptab_read_enable             1 bit
//   + front2back_fifo_reset        1 bit
//   + front2back_fifo_refetch      1 bit
//   + front2back_fifo_read_enable  1 bit
//   = 合计                          12 bit
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
// 自查确认：front_read_stage_input_comb Input Bits = 7, Output Bits = 12。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module front_read_stage_input_comb_top #(
    parameter W_FrontReadStageInputCombIn  = 7,  // 实际：7, 来自 front_top
    parameter W_FrontReadStageInputCombOut = 12    // 实际：12, 来自 front_top
) (
    input  wire [W_FrontReadStageInputCombIn-1:0]  front_read_stage_input_bundle,
    output wire [W_FrontReadStageInputCombOut-1:0] front_read_stage_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontReadStageInputCombIn-1:0]  pi;
    wire [W_FrontReadStageInputCombOut-1:0] po;
    assign pi = front_read_stage_input_bundle;
    assign front_read_stage_output_bundle = po;

    front_read_stage_input_comb_bsd_top #(
        .W_FrontReadStageInputCombIn(W_FrontReadStageInputCombIn),
        .W_FrontReadStageInputCombOut(W_FrontReadStageInputCombOut)
    ) u_front_read_stage_input_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_read_stage_input_comb_bsd_top #(
    parameter W_FrontReadStageInputCombIn  = 7,  // 实际：7, 来自 front_top
    parameter W_FrontReadStageInputCombOut = 12    // 实际：12, 来自 front_top
) (
    input  wire [W_FrontReadStageInputCombIn-1:0]  pi,
    output wire [W_FrontReadStageInputCombOut-1:0] po
);


`ifdef USE_CPP_GOLDEN_BSD
    `include "slices/cpp_golden/cpp_golden_bsd_macros.vh"
    `CPP_GOLDEN_BSD(front_read_stage_input_comb, W_FrontReadStageInputCombIn, W_FrontReadStageInputCombOut)
`else
// 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontReadStageInputCombOut{1'b0}};
`endif


endmodule
