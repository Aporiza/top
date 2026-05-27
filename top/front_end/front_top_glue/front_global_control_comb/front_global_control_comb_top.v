// 前端正式 comb 边界： front_global_control_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_global_control_comb.
// 作用：选择全局 reset/refetch 控制。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module front_global_control_comb_top #(
    parameter PC_BITS                     = 32,
    parameter W_FrontGlobalControlCombIn  = 1 + 1 + PC_BITS + 1 + PC_BITS,  // 实际： 67, 1 + 1 + PC_BITS + 1 + PC_BITS
    parameter W_FrontGlobalControlCombOut = 1 + 1 + PC_BITS    // 实际： 34, 1 + 1 + PC_BITS
) (
    input  wire               reset,
    input  wire               refetch,
    input  wire [PC_BITS-1:0] refetch_address,
    input  wire               predecode_refetch_snapshot,
    input  wire [PC_BITS-1:0] predecode_refetch_address_snapshot,
    output wire               global_reset,
    output wire               global_refetch,
    output wire [PC_BITS-1:0] global_refetch_address
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontGlobalControlCombIn-1:0]  pi;
    wire [W_FrontGlobalControlCombOut-1:0] po;
    assign pi = {
        reset,
        refetch,
        refetch_address,
        predecode_refetch_snapshot,
        predecode_refetch_address_snapshot
    };

    assign {
        global_reset,
        global_refetch,
        global_refetch_address
    } = po;

    front_global_control_comb_bsd_top #(
        .W_FrontGlobalControlCombIn(W_FrontGlobalControlCombIn),
        .W_FrontGlobalControlCombOut(W_FrontGlobalControlCombOut)
    ) u_front_global_control_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_global_control_comb_bsd_top #(
    parameter W_FrontGlobalControlCombIn  = 67,  // 实际： 67, 1 + 1 + PC_BITS + 1 + PC_BITS
    parameter W_FrontGlobalControlCombOut = 34    // 实际： 34, 1 + 1 + PC_BITS
) (
    input  wire [W_FrontGlobalControlCombIn-1:0]  pi,
    output wire [W_FrontGlobalControlCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontGlobalControlCombOut{1'b0}};

endmodule
