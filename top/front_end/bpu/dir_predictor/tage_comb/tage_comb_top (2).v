// 前端正式 comb 边界： tage_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 TAGE 方向预测结果包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：tage_comb
// 来源：train_IO.h / BPU/dir_predictor/TAGE_top.h
// 配置：simulator-front 默认 large 配置
// 接口：TageCombIn(3329 bit) -> TageCombOut(1932 bit)
//
// 输入 TageCombIn = 3329 bit
//   = inp 1248 bit
//   + rd  2081 bit
//   = 合计  3329 bit
//
// 输出 TageCombOut = 1932 bit
//   = out_regs  272 bit
//   + req      1660 bit
//   = 合计       1932 bit
//
// 关键结构展开：
//   inp      : TAGE_TOP::InputPayload  1248 bit
//   rd       : TAGE_TOP::ReadData      2081 bit
//   out_regs : TAGE_TOP::OutputPayload  272 bit
//   req      : TAGE_TOP::CombResult    1660 bit
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
// 自查确认：tage_comb Input Bits = 3329, Output Bits = 1932。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module tage_comb_top #(
    parameter W_TageCombIn  = 3329,  // 实际：3329, TAGE_TOP::TageCombIn
    parameter W_TageCombOut = 1932   // 实际：TAGE_TOP::TageCombOut
) (
    input  wire [W_TageCombIn-1:0]  tage_input_bundle,
    output wire [W_TageCombOut-1:0] tage_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_TageCombIn-1:0]  pi;
    wire [W_TageCombOut-1:0] po;
    assign pi = tage_input_bundle;

    assign tage_bundle = po;

    tage_comb_bsd_top #(
        .W_TageCombIn(W_TageCombIn),
        .W_TageCombOut(W_TageCombOut)
    ) u_tage_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module tage_comb_bsd_top #(
    parameter W_TageCombIn  = 3329,  // 实际：3329, TAGE_TOP::TageCombIn
    parameter W_TageCombOut = 1932   // 实际：TAGE_TOP::TageCombOut
) (
    input  wire [W_TageCombIn-1:0]  pi,
    output wire [W_TageCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_TageCombOut{1'b0}};

endmodule
