// 前端正式 comb 边界： front_ptab_write_comb.
// 源码依据： simulator-front/front-end/front_top.cpp, front_ptab_write_comb.
// 作用：根据 BPU 输出生成 PTAB 写入数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_ptab_write_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontPtabWriteCombIn(4473 bit) -> FrontPtabWriteCombOut(4853 bit)
//
// 输入 FrontPtabWriteCombIn = 4473 bit
//   = bpu_output     4470 bit
//   + global_reset      1 bit
//   + global_refetch    1 bit
//   + ptab_can_write    1 bit
//   = 合计             4473 bit
//
// 输出 FrontPtabWriteCombOut = 4853 bit
//   = ptab_in 4853 bit
//   = 合计      4853 bit
//
// 关键结构展开：
//   bpu_output : BPU_TOP::OutputPayload 4470 bit
//   ptab_in    : PTAB_in                4853 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_ptab_write_comb Input Bits = 4473, Output Bits = 4853。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module front_ptab_write_comb_top #(
    parameter W_BpuOutputPayload      = 4470,  // 实际：4470, BPU_TOP::OutputPayload
    parameter W_PtabIn                = 4853,  // 实际：4853, PTAB_in
    parameter W_FrontPtabWriteCombIn  = W_BpuOutputPayload + 3,  // 实际：4473, OutputPayload + reset/refetch/can_write
    parameter W_FrontPtabWriteCombOut = W_PtabIn                 // 实际：4853, PTAB_in
) (
    input  wire [W_FrontPtabWriteCombIn-1:0]  front_ptab_write_input_bundle,
    output wire [W_FrontPtabWriteCombOut-1:0] front_ptab_write_output_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_FrontPtabWriteCombIn-1:0]  pi;
    wire [W_FrontPtabWriteCombOut-1:0] po;
    assign pi = front_ptab_write_input_bundle;
    assign front_ptab_write_output_bundle = po;

    front_ptab_write_comb_bsd_top #(
        .W_FrontPtabWriteCombIn(W_FrontPtabWriteCombIn),
        .W_FrontPtabWriteCombOut(W_FrontPtabWriteCombOut)
    ) u_front_ptab_write_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front_ptab_write_comb_bsd_top #(
    parameter W_FrontPtabWriteCombIn  = 4473,  // 实际：4473, BPU_TOP::OutputPayload(4470) + 3
    parameter W_FrontPtabWriteCombOut = 4853   // 实际：4853, PTAB_in
) (
    input  wire [W_FrontPtabWriteCombIn-1:0]  pi,
    output wire [W_FrontPtabWriteCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_FrontPtabWriteCombOut{1'b0}};

endmodule
