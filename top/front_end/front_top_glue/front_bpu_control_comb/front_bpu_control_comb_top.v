// 前端正式 comb 边界： front_bpu_control_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_bpu_control_comb.
// 作用：生成 BPU 运行/阻塞控制和输入数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module front_bpu_control_comb_top #(
    parameter PC_BITS                  = 32,
    parameter W_BpuIn                  = 2739,  // 实际： 2739, 来自 front_top W_BpuIn
    parameter W_FrontBpuControlCombIn  = W_BpuIn + 2 + 1 + 1 + PC_BITS,  // 实际： 2775, W_BpuIn + 2 + 1 + 1 + PC_BITS
    parameter W_FrontBpuControlCombOut = 3 + W_BpuIn + W_BpuIn    // 实际： 5481, 3 + W_BpuIn + W_BpuIn
) (
    input  wire [W_BpuIn-1:0] bpu_in_seed,
    input  wire               fetch_addr_fifo_full_latch,
    input  wire               ptab_full_latch,
    input  wire               global_reset,
    input  wire               global_refetch,
    input  wire [PC_BITS-1:0] global_refetch_address,
    output wire               bpu_stall,
    output wire               bpu_can_run,
    output wire               bpu_icache_ready,
    output wire [W_BpuIn-1:0] bpu_in_after_control,
    output wire [W_BpuIn-1:0] bpu_input_payload
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontBpuControlCombIn-1:0]  pi;
    wire [W_FrontBpuControlCombOut-1:0] po;
    assign pi = {
        bpu_in_seed,
        fetch_addr_fifo_full_latch,
        ptab_full_latch,
        global_reset,
        global_refetch,
        global_refetch_address
    };

    assign {
        bpu_stall,
        bpu_can_run,
        bpu_icache_ready,
        bpu_in_after_control,
        bpu_input_payload
    } = po;

    front_bpu_control_comb_bsd_top #(
        .W_FrontBpuControlCombIn(W_FrontBpuControlCombIn),
        .W_FrontBpuControlCombOut(W_FrontBpuControlCombOut)
    ) u_front_bpu_control_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_bpu_control_comb_bsd_top #(
    parameter W_FrontBpuControlCombIn  = 2775,  // 实际： 2775, W_BpuIn + 2 + 1 + 1 + PC_BITS
    parameter W_FrontBpuControlCombOut = 5481    // 实际： 5481, 3 + W_BpuIn + W_BpuIn
) (
    input  wire [W_FrontBpuControlCombIn-1:0]  pi,
    output wire [W_FrontBpuControlCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontBpuControlCombOut{1'b0}};

endmodule
