// 前端正式 comb 边界： front_read_stage_input_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_read_stage_input_comb.
// 作用：生成队列读使能、reset 和 refetch 控制包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module front_read_stage_input_comb_top #(
    parameter W_FrontReadStageInputCombIn  = 7,  // 实际： 7, 来自 front_top
    parameter W_FrontReadStageInputCombOut = 12    // 实际： 12, 来自 front_top
) (
    input  wire  refetch,
    input  wire  global_reset,
    input  wire  global_refetch,
    input  wire  fetch_addr_fifo_read_enable_slot0,
    input  wire  inst_fifo_read_enable,
    input  wire  ptab_read_enable,
    input  wire  front2back_read_enable,
    output wire  fetch_addr_fifo_reset,
    output wire  fetch_addr_fifo_refetch,
    output wire  fetch_addr_fifo_read_enable,
    output wire  fifo_reset,
    output wire  fifo_refetch,
    output wire  fifo_read_enable,
    output wire  ptab_reset,
    output wire  ptab_refetch,
    output wire  ptab_out_read_enable,
    output wire  front2back_fifo_reset,
    output wire  front2back_fifo_refetch,
    output wire  front2back_fifo_read_enable
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontReadStageInputCombIn-1:0]  pi;
    wire [W_FrontReadStageInputCombOut-1:0] po;
    assign pi = {
        refetch,
        global_reset,
        global_refetch,
        fetch_addr_fifo_read_enable_slot0,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    };

    assign {
        fetch_addr_fifo_reset,
        fetch_addr_fifo_refetch,
        fetch_addr_fifo_read_enable,
        fifo_reset,
        fifo_refetch,
        fifo_read_enable,
        ptab_reset,
        ptab_refetch,
        ptab_out_read_enable,
        front2back_fifo_reset,
        front2back_fifo_refetch,
        front2back_fifo_read_enable
    } = po;

    front_read_stage_input_comb_bsd_top #(
        .W_FrontReadStageInputCombIn(W_FrontReadStageInputCombIn),
        .W_FrontReadStageInputCombOut(W_FrontReadStageInputCombOut)
    ) u_front_read_stage_input_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_read_stage_input_comb_bsd_top #(
    parameter W_FrontReadStageInputCombIn  = 7,  // 实际： 7, 来自 front_top
    parameter W_FrontReadStageInputCombOut = 12    // 实际： 12, 来自 front_top
) (
    input  wire [W_FrontReadStageInputCombIn-1:0]  pi,
    output wire [W_FrontReadStageInputCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontReadStageInputCombOut{1'b0}};

endmodule
