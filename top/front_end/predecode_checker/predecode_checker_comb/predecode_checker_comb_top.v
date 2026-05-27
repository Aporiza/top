// 前端正式 comb 边界： predecode_checker_comb.
// 源码依据： simulator-front/front-end predecode checker 相关 comb 计算。
// 作用：生成 predecode checker 修正结果。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module predecode_checker_comb_top #(
    parameter W_PredecodeCheckerIn      = 624,  // 实际： 624, 来自 front_top W_PredecodeCheckerIn
    parameter W_PredecodeCheckerOut     = 49,  // 实际： 49, 来自 front_top W_PredecodeCheckerOut
    parameter W_PredecodeCheckerCombIn  = W_PredecodeCheckerIn,  // 实际： 624, W_PredecodeCheckerIn
    parameter W_PredecodeCheckerCombOut = W_PredecodeCheckerOut    // 实际： 49, W_PredecodeCheckerOut
) (
    input  wire [W_PredecodeCheckerIn-1:0]  checker_in,
    output wire [W_PredecodeCheckerOut-1:0] checker_out
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_PredecodeCheckerCombIn-1:0]  pi;
    wire [W_PredecodeCheckerCombOut-1:0] po;
    assign pi = {
        checker_in
    };

    assign {
        checker_out
    } = po;

    predecode_checker_comb_bsd_top #(
        .W_PredecodeCheckerCombIn(W_PredecodeCheckerCombIn),
        .W_PredecodeCheckerCombOut(W_PredecodeCheckerCombOut)
    ) u_predecode_checker_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module predecode_checker_comb_bsd_top #(
    parameter W_PredecodeCheckerCombIn  = 624,  // 实际： 624, W_PredecodeCheckerIn
    parameter W_PredecodeCheckerCombOut = 49    // 实际： 49, W_PredecodeCheckerOut
) (
    input  wire [W_PredecodeCheckerCombIn-1:0]  pi,
    output wire [W_PredecodeCheckerCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_PredecodeCheckerCombOut{1'b0}};

endmodule
