// 前端正式 comb 边界： front_checker_input_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_checker_input_comb.
// 作用：根据 instruction FIFO 和 PTAB 输出生成 checker 输入包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module front_checker_input_comb_top #(
    parameter W_InstructionFifoOut       = 1635,  // 实际： 1635, 来自 front_top W_InstructionFifoOut
    parameter W_PtabOut                  = 4851,  // 实际： 4851, 来自 front_top W_PtabOut
    parameter W_PredecodeCheckerIn       = 624,  // 实际： 624, 来自 front_top W_PredecodeCheckerIn
    parameter W_FrontCheckerInputCombIn  = W_InstructionFifoOut + W_PtabOut,  // 实际： 6486, W_InstructionFifoOut + W_PtabOut
    parameter W_FrontCheckerInputCombOut = W_PredecodeCheckerIn    // 实际： 624, W_PredecodeCheckerIn
) (
    input  wire [W_InstructionFifoOut-1:0] instruction_fifo_out,
    input  wire [W_PtabOut-1:0]            ptab_out,
    output wire [W_PredecodeCheckerIn-1:0] checker_in
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontCheckerInputCombIn-1:0]  pi;
    wire [W_FrontCheckerInputCombOut-1:0] po;
    assign pi = {
        instruction_fifo_out,
        ptab_out
    };

    assign {
        checker_in
    } = po;

    front_checker_input_comb_bsd_top #(
        .W_FrontCheckerInputCombIn(W_FrontCheckerInputCombIn),
        .W_FrontCheckerInputCombOut(W_FrontCheckerInputCombOut)
    ) u_front_checker_input_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_checker_input_comb_bsd_top #(
    parameter W_FrontCheckerInputCombIn  = 6486,  // 实际： 6486, W_InstructionFifoOut + W_PtabOut
    parameter W_FrontCheckerInputCombOut = 624    // 实际： 624, W_PredecodeCheckerIn
) (
    input  wire [W_FrontCheckerInputCombIn-1:0]  pi,
    output wire [W_FrontCheckerInputCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontCheckerInputCombOut{1'b0}};

endmodule
