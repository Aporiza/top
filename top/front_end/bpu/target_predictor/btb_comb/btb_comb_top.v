// 前端正式 comb 边界： btb_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BTB 目标地址结果包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module btb_comb_top #(
    parameter W_BtbCombIn  = 2264,  // 实际： BTB_TOP::BtbCombIn
    parameter W_BtbCombOut = 1089   // 实际： BTB_TOP::BtbCombOut
) (
    input  wire [W_BtbCombIn-1:0]  btb_post_read_req_bundle,
    output wire [W_BtbCombOut-1:0] btb_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BtbCombIn-1:0]  pi;
    wire [W_BtbCombOut-1:0] po;
    assign pi = {
        btb_post_read_req_bundle
    };

    assign {
        btb_bundle
    } = po;

    btb_comb_bsd_top #(
        .W_BtbCombIn(W_BtbCombIn),
        .W_BtbCombOut(W_BtbCombOut)
    ) u_btb_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module btb_comb_bsd_top #(
    parameter W_BtbCombIn  = 2264,  // 实际： BTB_TOP::BtbCombIn
    parameter W_BtbCombOut = 1089   // 实际： BTB_TOP::BtbCombOut
) (
    input  wire [W_BtbCombIn-1:0]  pi,
    output wire [W_BtbCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BtbCombOut{1'b0}};

endmodule
