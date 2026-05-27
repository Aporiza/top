// 前端正式 comb 边界： btb_pre_read_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BTB 预读请求包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

module btb_pre_read_comb_top #(
    parameter W_BtbPreReadCombIn  = 105,  // 实际： BTB_TOP::BtbPreReadCombIn
    parameter W_BtbPreReadCombOut = 228   // 实际： BTB_TOP::BtbPreReadCombOut
) (
    input  wire [W_BtbPreReadCombIn-1:0]  bpu_pre_read_req_bundle,
    output wire [W_BtbPreReadCombOut-1:0] btb_pre_read_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BtbPreReadCombIn-1:0]  pi;
    wire [W_BtbPreReadCombOut-1:0] po;
    assign pi = {
        bpu_pre_read_req_bundle
    };

    assign {
        btb_pre_read_bundle
    } = po;

    btb_pre_read_comb_bsd_top #(
        .W_BtbPreReadCombIn(W_BtbPreReadCombIn),
        .W_BtbPreReadCombOut(W_BtbPreReadCombOut)
    ) u_btb_pre_read_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module btb_pre_read_comb_bsd_top #(
    parameter W_BtbPreReadCombIn  = 105,  // 实际： BTB_TOP::BtbPreReadCombIn
    parameter W_BtbPreReadCombOut = 228   // 实际： BTB_TOP::BtbPreReadCombOut
) (
    input  wire [W_BtbPreReadCombIn-1:0]  pi,
    output wire [W_BtbPreReadCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BtbPreReadCombOut{1'b0}};

endmodule
