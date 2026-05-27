// 前端正式 comb 边界： type_pred_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成类型预测结果包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：type_pred_comb
// 来源：train_IO.h / BPU/type_predictor
// 配置：simulator-front 默认 large 配置
// 接口：TypePredCombIn(2448 bit) -> TypePredCombOut(376 bit)
//
// 输入 TypePredCombIn = 2448 bit
//   = inp       816 bit
//   + pre_read  672 bit
//   + rd        960 bit
//   = 合计       2448 bit
//
// 输出 TypePredCombOut = 376 bit
//   = out_regs  80 bit
//   + req      296 bit
//   = 合计       376 bit
//
// 关键结构展开：
//   inp      : TypePredictor::InputPayload   816 bit
//   pre_read : TypePredictor::PreReadCombOut 672 bit
//   rd       : TypePredictor::ReadData       960 bit
//   out_regs : TypePredictor::OutputPayload   80 bit
//   req      : TypePredictor::CombResult     296 bit
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
// 自查确认：type_pred_comb Input Bits = 2448, Output Bits = 376。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module type_pred_comb_top #(
    parameter W_TypePredCombIn  = 2448,  // 实际：TypePredictor::TypePredCombIn
    parameter W_TypePredCombOut = 376    // 实际：TypePredictor::TypePredCombOut
) (
    input  wire [W_TypePredCombIn-1:0]  type_pred_input_bundle,
    output wire [W_TypePredCombOut-1:0] type_pred_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_TypePredCombIn-1:0]  pi;
    wire [W_TypePredCombOut-1:0] po;
    assign pi = type_pred_input_bundle;

    assign type_pred_bundle = po;

    type_pred_comb_bsd_top #(
        .W_TypePredCombIn(W_TypePredCombIn),
        .W_TypePredCombOut(W_TypePredCombOut)
    ) u_type_pred_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module type_pred_comb_bsd_top #(
    parameter W_TypePredCombIn  = 2448,  // 实际：TypePredictor::TypePredCombIn
    parameter W_TypePredCombOut = 376    // 实际：TypePredictor::TypePredCombOut
) (
    input  wire [W_TypePredCombIn-1:0]  pi,
    output wire [W_TypePredCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_TypePredCombOut{1'b0}};

endmodule
