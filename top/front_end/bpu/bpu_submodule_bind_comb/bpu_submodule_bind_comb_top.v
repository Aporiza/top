// 前端正式 comb 边界： bpu_submodule_bind_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：汇总 BPU 预测器子模块结果。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_submodule_bind_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuSubmoduleBindCombIn(1856 bit) -> BpuSubmoduleBindCombOut(1680 bit)
//
// 输入 BpuSubmoduleBindCombIn = 1856 bit
//   = do_pred_on_this_pc[FETCH_WIDTH]   16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]     80 bit
//   + btb_in[BPU_BANK_NUM]            1680 bit
//   + type_out                          80 bit
//   = 合计                              1856 bit
//
// 输出 BpuSubmoduleBindCombOut = 1680 bit
//   = btb_in_with_type[BPU_BANK_NUM] 1680 bit
//   = 合计                             1680 bit
//
// 关键结构展开：
//   btb_in[BPU_BANK_NUM]           : BTB_TOP::InputPayload        1680 bit
//   type_out                       : TypePredictor::OutputPayload   80 bit
//   btb_in_with_type[BPU_BANK_NUM] : BTB_TOP::InputPayload        1680 bit
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
// 自查确认：bpu_submodule_bind_comb Input Bits = 1856, Output Bits = 1680。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module bpu_submodule_bind_comb_top #(
    parameter W_BpuSubmoduleBindCombIn  = 1856,  // 实际：BPU_TOP::BpuSubmoduleBindCombIn
    parameter W_BpuSubmoduleBindCombOut = 1680   // 实际：BPU_TOP::BpuSubmoduleBindCombOut
) (
    input  wire [W_BpuSubmoduleBindCombIn-1:0]  bpu_submodule_bind_input_bundle,
    output wire [W_BpuSubmoduleBindCombOut-1:0] bpu_submodule_bind_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BpuSubmoduleBindCombIn-1:0]  pi;
    wire [W_BpuSubmoduleBindCombOut-1:0] po;
    assign pi = bpu_submodule_bind_input_bundle;

    assign bpu_submodule_bind_bundle = po;

    bpu_submodule_bind_comb_bsd_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuSubmoduleBindCombIn),
        .W_BpuSubmoduleBindCombOut(W_BpuSubmoduleBindCombOut)
    ) u_bpu_submodule_bind_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_submodule_bind_comb_bsd_top #(
    parameter W_BpuSubmoduleBindCombIn  = 1856,  // 实际：BPU_TOP::BpuSubmoduleBindCombIn
    parameter W_BpuSubmoduleBindCombOut = 1680   // 实际：BPU_TOP::BpuSubmoduleBindCombOut
) (
    input  wire [W_BpuSubmoduleBindCombIn-1:0]  pi,
    output wire [W_BpuSubmoduleBindCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BpuSubmoduleBindCombOut{1'b0}};

endmodule
