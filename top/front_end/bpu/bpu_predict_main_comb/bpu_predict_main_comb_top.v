// 前端正式 comb 边界： bpu_predict_main_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BPU 主预测输出包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module bpu_predict_main_comb_top #(
    parameter W_BpuPredictMainCombIn  = 5798,  // 实际： BPU_TOP::BpuPredictMainCombIn
    parameter W_BpuPredictMainCombOut = 6502   // 实际： BPU_TOP::BpuPredictMainCombOut
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  bpu_submodule_bind_bundle,
    output wire [W_BpuPredictMainCombOut-1:0] bpu_predict_main_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BpuPredictMainCombIn-1:0]  pi;
    wire [W_BpuPredictMainCombOut-1:0] po;
    assign pi = {
        bpu_submodule_bind_bundle
    };

    assign {
        bpu_predict_main_bundle
    } = po;

    bpu_predict_main_comb_bsd_top #(
        .W_BpuPredictMainCombIn(W_BpuPredictMainCombIn),
        .W_BpuPredictMainCombOut(W_BpuPredictMainCombOut)
    ) u_bpu_predict_main_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_predict_main_comb_bsd_top #(
    parameter W_BpuPredictMainCombIn  = 5798,  // 实际： BPU_TOP::BpuPredictMainCombIn
    parameter W_BpuPredictMainCombOut = 6502   // 实际： BPU_TOP::BpuPredictMainCombOut
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  pi,
    output wire [W_BpuPredictMainCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BpuPredictMainCombOut{1'b0}};

endmodule
