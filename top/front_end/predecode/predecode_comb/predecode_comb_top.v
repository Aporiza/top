// 前端正式 comb 边界： predecode_comb.
// 源码依据： simulator-front/front-end predecode comb calculation.
// 作用：生成 predecode 结果包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module predecode_comb_top #(
    parameter FETCH_WIDTH        = 16,
    parameter INST_BITS          = 32,
    parameter PC_BITS            = 32,
    parameter W_PredecodeOut     = 544,  // 实际： 544, 来自 front_top W_PredecodeOut
    parameter W_PredecodeCombIn  = (FETCH_WIDTH * INST_BITS) + (FETCH_WIDTH * PC_BITS),  // 实际： 1024, 来自 front_top W_PredecodeIn
    parameter W_PredecodeCombOut = W_PredecodeOut    // 实际： 544, 来自 front_top W_PredecodeOut
) (
    input  wire [FETCH_WIDTH*INST_BITS-1:0] icache_fetch_group,
    input  wire [FETCH_WIDTH*PC_BITS-1:0]   predecode_fetch_pc_group,
    output wire [W_PredecodeOut-1:0]        predecode_result
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_PredecodeCombIn-1:0]     pi;
    wire [W_PredecodeCombOut-1:0]    po;
    assign pi = {
        icache_fetch_group,
        predecode_fetch_pc_group
    };

    assign {
        predecode_result
    } = po;

    predecode_comb_bsd_top #(
        .W_PredecodeCombIn(W_PredecodeCombIn),
        .W_PredecodeCombOut(W_PredecodeCombOut)
    ) u_predecode_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module predecode_comb_bsd_top #(
    parameter W_PredecodeCombIn  = 1024,  // 实际： 1024, 来自 front_top W_PredecodeIn
    parameter W_PredecodeCombOut = 544    // 实际： 544, 来自 front_top W_PredecodeOut
) (
    input  wire [W_PredecodeCombIn-1:0]  pi,
    output wire [W_PredecodeCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_PredecodeCombOut{1'b0}};

endmodule
