// 前端正式 comb 边界： type_predictor_pre_read_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成类型预测器预读请求包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module type_predictor_pre_read_comb_top #(
    parameter W_TypePredictorPreReadCombIn  = 816,  // 实际： TypePredictor::InputPayload
    parameter W_TypePredictorPreReadCombOut = 672   // 实际： TypePredictor::PreReadCombOut
) (
    input  wire [W_TypePredictorPreReadCombIn-1:0]  bpu_pre_read_req_bundle,
    output wire [W_TypePredictorPreReadCombOut-1:0] type_predictor_pre_read_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_TypePredictorPreReadCombIn-1:0]  pi;
    wire [W_TypePredictorPreReadCombOut-1:0] po;
    assign pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        type_predictor_pre_read_bundle
    } = po;

    type_predictor_pre_read_comb_bsd_top #(
        .W_TypePredictorPreReadCombIn(W_TypePredictorPreReadCombIn),
        .W_TypePredictorPreReadCombOut(W_TypePredictorPreReadCombOut)
    ) u_type_predictor_pre_read_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module type_predictor_pre_read_comb_bsd_top #(
    parameter W_TypePredictorPreReadCombIn  = 816,  // 实际： TypePredictor::InputPayload
    parameter W_TypePredictorPreReadCombOut = 672   // 实际： TypePredictor::PreReadCombOut
) (
    input  wire [W_TypePredictorPreReadCombIn-1:0]  pi,
    output wire [W_TypePredictorPreReadCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_TypePredictorPreReadCombOut{1'b0}};

endmodule
