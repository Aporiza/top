// 前端正式 comb 边界： bpu_hist_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BPU 历史更新数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module bpu_hist_comb_top #(
    parameter W_BpuHistCombIn  = 6944,  // 实际： BPU_TOP::BpuHistCombIn
    parameter W_BpuHistCombOut = 5935   // 实际： BPU_TOP::BpuHistCombOut
) (
    input  wire [W_BpuHistCombIn-1:0]  bpu_predict_main_bundle,
    output wire [W_BpuHistCombOut-1:0] bpu_hist_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BpuHistCombIn-1:0]  pi;
    wire [W_BpuHistCombOut-1:0] po;
    assign pi = {
        bpu_predict_main_bundle
    };

    assign {
        bpu_hist_bundle
    } = po;

    bpu_hist_comb_bsd_top #(
        .W_BpuHistCombIn(W_BpuHistCombIn),
        .W_BpuHistCombOut(W_BpuHistCombOut)
    ) u_bpu_hist_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_hist_comb_bsd_top #(
    parameter W_BpuHistCombIn  = 6944,  // 实际： BPU_TOP::BpuHistCombIn
    parameter W_BpuHistCombOut = 5935   // 实际： BPU_TOP::BpuHistCombOut
) (
    input  wire [W_BpuHistCombIn-1:0]  pi,
    output wire [W_BpuHistCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BpuHistCombOut{1'b0}};

endmodule
