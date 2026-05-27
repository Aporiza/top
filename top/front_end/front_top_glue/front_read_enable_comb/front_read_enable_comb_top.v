// 前端正式 comb 边界： front_read_enable_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_read_enable_comb.
// 作用：生成前端各队列读使能。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module front_read_enable_comb_top #(
    parameter W_FrontReadEnableCombIn  = 9,  // 实际： 9, 来自 front_top
    parameter W_FrontReadEnableCombOut = 6    // 实际： 6, 来自 front_top
) (
    input  wire  FIFO_read_enable,
    input  wire  fetch_addr_fifo_empty_latch_snapshot,
    input  wire  fifo_empty_latch_snapshot,
    input  wire  ptab_empty_latch_snapshot,
    input  wire  front2back_fifo_full_latch_snapshot,
    input  wire  global_reset,
    input  wire  global_refetch,
    input  wire  icache_read_ready,
    input  wire  icache_read_ready_2,
    output wire  fetch_addr_fifo_read_enable_slot0,
    output wire  fetch_addr_fifo_read_enable_slot1_candidate,
    output wire  predecode_can_run_old,
    output wire  inst_fifo_read_enable,
    output wire  ptab_read_enable,
    output wire  front2back_read_enable
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontReadEnableCombIn-1:0]  pi;
    wire [W_FrontReadEnableCombOut-1:0] po;
    assign pi = {
        FIFO_read_enable,
        fetch_addr_fifo_empty_latch_snapshot,
        fifo_empty_latch_snapshot,
        ptab_empty_latch_snapshot,
        front2back_fifo_full_latch_snapshot,
        global_reset,
        global_refetch,
        icache_read_ready,
        icache_read_ready_2
    };

    assign {
        fetch_addr_fifo_read_enable_slot0,
        fetch_addr_fifo_read_enable_slot1_candidate,
        predecode_can_run_old,
        inst_fifo_read_enable,
        ptab_read_enable,
        front2back_read_enable
    } = po;

    front_read_enable_comb_bsd_top #(
        .W_FrontReadEnableCombIn(W_FrontReadEnableCombIn),
        .W_FrontReadEnableCombOut(W_FrontReadEnableCombOut)
    ) u_front_read_enable_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_read_enable_comb_bsd_top #(
    parameter W_FrontReadEnableCombIn  = 9,  // 实际： 9, 来自 front_top
    parameter W_FrontReadEnableCombOut = 6    // 实际： 6, 来自 front_top
) (
    input  wire [W_FrontReadEnableCombIn-1:0]  pi,
    output wire [W_FrontReadEnableCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontReadEnableCombOut{1'b0}};

endmodule
