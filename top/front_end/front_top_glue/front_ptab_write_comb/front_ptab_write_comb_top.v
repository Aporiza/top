// 前端正式 comb 边界： front_ptab_write_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_ptab_write_comb.
// 作用：根据 BPU 输出生成 PTAB 写入数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module front_ptab_write_comb_top #(
    parameter W_BpuOut                = 4949,  // 实际： 4949, 来自 front_top W_BpuOut
    parameter W_PtabIn                = 4853,  // 实际： 4853, 来自 front_top W_PtabIn
    parameter W_FrontPtabWriteCombIn  = W_BpuOut + 3,  // 实际： 4952, W_BpuOut + 3
    parameter W_FrontPtabWriteCombOut = W_PtabIn    // 实际： 4853, W_PtabIn
) (
    input  wire [W_BpuOut-1:0] bpu_output_payload,
    input  wire                global_reset,
    input  wire                global_refetch,
    input  wire                ptab_can_write,
    output wire [W_PtabIn-1:0] ptab_in
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontPtabWriteCombIn-1:0]  pi;
    wire [W_FrontPtabWriteCombOut-1:0] po;
    assign pi = {
        bpu_output_payload,
        global_reset,
        global_refetch,
        ptab_can_write
    };

    assign {
        ptab_in
    } = po;

    front_ptab_write_comb_bsd_top #(
        .W_FrontPtabWriteCombIn(W_FrontPtabWriteCombIn),
        .W_FrontPtabWriteCombOut(W_FrontPtabWriteCombOut)
    ) u_front_ptab_write_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_ptab_write_comb_bsd_top #(
    parameter W_FrontPtabWriteCombIn  = 4952,  // 实际： 4952, W_BpuOut + 3
    parameter W_FrontPtabWriteCombOut = 4853    // 实际： 4853, W_PtabIn
) (
    input  wire [W_FrontPtabWriteCombIn-1:0]  pi,
    output wire [W_FrontPtabWriteCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontPtabWriteCombOut{1'b0}};

endmodule
