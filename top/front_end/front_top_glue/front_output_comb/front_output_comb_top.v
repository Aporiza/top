// 前端正式 comb 边界： front_output_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_output_comb.
// 作用：选择最终前端输出。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module front_output_comb_top #(
    parameter W_Front2BackFifoOut  = 5395,  // 实际： 5395, 来自 front_top W_Front2BackFifoOut
    parameter W_FrontTopOut        = 5393,  // 实际： 5393, 来自 front_top W_FrontTopOut
    parameter W_FrontOutputCombIn  = W_Front2BackFifoOut + W_Front2BackFifoOut + 1,  // 实际： 10791, W_Front2BackFifoOut + W_Front2BackFifoOut + 1
    parameter W_FrontOutputCombOut = W_FrontTopOut    // 实际： 5393, W_FrontTopOut
) (
    input  wire [W_Front2BackFifoOut-1:0] front2back_fifo_out,
    input  wire [W_Front2BackFifoOut-1:0] bypass_front2back_fifo_out,
    input  wire                           use_front2back_output_bypass,
    output wire [W_FrontTopOut-1:0]       front_top_out_bus
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontOutputCombIn-1:0]  pi;
    wire [W_FrontOutputCombOut-1:0] po;
    assign pi = {
        front2back_fifo_out,
        bypass_front2back_fifo_out,
        use_front2back_output_bypass
    };

    assign {
        front_top_out_bus
    } = po;

    front_output_comb_bsd_top #(
        .W_FrontOutputCombIn(W_FrontOutputCombIn),
        .W_FrontOutputCombOut(W_FrontOutputCombOut)
    ) u_front_output_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_output_comb_bsd_top #(
    parameter W_FrontOutputCombIn  = 10791,  // 实际： 10791, W_Front2BackFifoOut + W_Front2BackFifoOut + 1
    parameter W_FrontOutputCombOut = 5393    // 实际： 5393, W_FrontTopOut
) (
    input  wire [W_FrontOutputCombIn-1:0]  pi,
    output wire [W_FrontOutputCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontOutputCombOut{1'b0}};

endmodule
