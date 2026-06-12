// 前端正式 comb 边界： predecode_comb.
// 源码依据： simulator-front/front-end predecode comb calculation.
// 作用：生成 predecode 结果包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：predecode_comb
// 来源：train_IO.h / predecode.cpp
// 配置：simulator-front 默认 large 配置
// 接口：PredecodeCombIn(64 bit) -> PredecodeCombOut(34 bit)
//
// 输入 PredecodeCombIn = 64 bit
//   = inst 32 bit
//   + pc   32 bit
//   = 合计   64 bit
//
// 输出 PredecodeCombOut = 34 bit
//   = type            2 bit
//   + target_address 32 bit
//   = 合计             34 bit
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
// 自查确认：predecode_comb Input Bits = 64, Output Bits = 34。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module predecode_comb_top #(
    parameter INST_BITS           = 32,
    parameter PC_BITS             = 32,
    parameter PREDECODE_TYPE_BITS = 2,
    parameter W_PredecodeCombIn   = INST_BITS + PC_BITS,          // 实际：64, predecode_read_data
    parameter W_PredecodeCombOut  = PREDECODE_TYPE_BITS + PC_BITS // 实际：34, PredecodeResult
) (
    input  wire [W_PredecodeCombIn-1:0]  predecode_input_bundle,
    output wire [W_PredecodeCombOut-1:0] predecode_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_PredecodeCombIn-1:0]     pi;
    wire [W_PredecodeCombOut-1:0]    po;
    assign pi = predecode_input_bundle;
    assign predecode_output_bundle = po;

    predecode_comb_bsd_top #(
        .W_PredecodeCombIn(W_PredecodeCombIn),
        .W_PredecodeCombOut(W_PredecodeCombOut)
    ) u_predecode_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module predecode_comb_bsd_top #(
    parameter W_PredecodeCombIn  = 64,  // 实际：64, predecode_read_data = inst_word_t(32) + pc_t(32)
    parameter W_PredecodeCombOut = 34   // 实际：34, PredecodeResult = predecode_type_t(2) + target_addr_t(32)
) (
    input  wire [W_PredecodeCombIn-1:0]  pi,
    output wire [W_PredecodeCombOut-1:0] po
);


`ifdef USE_CPP_GOLDEN_BSD
    `include "slices/cpp_golden/cpp_golden_bsd_macros.vh"
    `CPP_GOLDEN_BSD(predecode_comb, W_PredecodeCombIn, W_PredecodeCombOut)
`else
// 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_PredecodeCombOut{1'b0}};
`endif


endmodule
