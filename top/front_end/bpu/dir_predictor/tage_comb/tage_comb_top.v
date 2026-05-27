// 前端正式 comb 边界： tage_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 TAGE 方向预测结果包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module tage_comb_top #(
    parameter W_TageCombIn  = 3312,  // 实际： TAGE_TOP::TageCombIn
    parameter W_TageCombOut = 1932   // 实际： TAGE_TOP::TageCombOut
) (
    input  wire [W_TageCombIn-1:0]  tage_input_bundle,
    output wire [W_TageCombOut-1:0] tage_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_TageCombIn-1:0]  pi;
    wire [W_TageCombOut-1:0] po;
    assign pi = {
        tage_input_bundle
    };

    assign {
        tage_bundle
    } = po;

    tage_comb_bsd_top #(
        .W_TageCombIn(W_TageCombIn),
        .W_TageCombOut(W_TageCombOut)
    ) u_tage_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module tage_comb_bsd_top #(
    parameter W_TageCombIn  = 3312,  // 实际： TAGE_TOP::TageCombIn
    parameter W_TageCombOut = 1932   // 实际： TAGE_TOP::TageCombOut
) (
    input  wire [W_TageCombIn-1:0]  pi,
    output wire [W_TageCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_TageCombOut{1'b0}};

endmodule
