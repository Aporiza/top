// 前端正式 comb 边界： bpu_hist_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BPU 历史更新数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_hist_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuHistCombIn(6944 bit) -> BpuHistCombOut(5935 bit)
//
// 输入 BpuHistCombIn = 6944 bit
//   = refetch                               1 bit
//   + in_update_base_pc[COMMIT_WIDTH]     256 bit
//   + in_upd_valid[COMMIT_WIDTH]            8 bit
//   + in_actual_dir[COMMIT_WIDTH]           8 bit
//   + in_actual_br_type[COMMIT_WIDTH]      24 bit
//   + in_pred_dir[COMMIT_WIDTH]             8 bit
//   + going_to_do_pred                      1 bit
//   + do_pred_on_this_pc[FETCH_WIDTH]      16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]        80 bit
//   + do_pred_for_this_pc[FETCH_WIDTH]    512 bit
//   + Spec_GHR_snapshot[GHR_LENGTH]       512 bit
//   + Spec_FH_snapshot[FH_N_MAX][TN_MAX]  384 bit
//   + Arch_GHR_snapshot[GHR_LENGTH]       512 bit
//   + Arch_FH_snapshot[FH_N_MAX][TN_MAX]  384 bit
//   + Spec_PATH_snapshot                   16 bit
//   + Arch_PATH_snapshot                   16 bit
//   + Arch_ras_stack_snapshot[RAS_DEPTH] 2048 bit
//   + Arch_ras_count_snapshot               7 bit
//   + Spec_ras_stack_snapshot[RAS_DEPTH] 2048 bit
//   + Spec_ras_count_snapshot               7 bit
//   + type_out                             80 bit
//   + final_pred_dir[FETCH_WIDTH]          16 bit
//   = 合计                                 6944 bit
//
// 输出 BpuHistCombOut = 5935 bit
//   = should_update_spec_hist           1 bit
//   + Spec_GHR_next[GHR_LENGTH]       512 bit
//   + Spec_FH_next[FH_N_MAX][TN_MAX]  384 bit
//   + Arch_GHR_next[GHR_LENGTH]       512 bit
//   + Arch_FH_next[FH_N_MAX][TN_MAX]  384 bit
//   + Spec_PATH_next                   16 bit
//   + Arch_PATH_next                   16 bit
//   + Arch_ras_stack_next[RAS_DEPTH] 2048 bit
//   + Arch_ras_count_next               7 bit
//   + Spec_ras_stack_next[RAS_DEPTH] 2048 bit
//   + Spec_ras_count_next               7 bit
//   = 合计                             5935 bit
//
// 关键结构展开：
//   type_out : TypePredictor::OutputPayload 80 bit
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
// 自查确认：bpu_hist_comb Input Bits = 6944, Output Bits = 5935。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module bpu_hist_comb_top #(
    parameter W_BpuHistCombIn  = 6944,  // 实际：BPU_TOP::BpuHistCombIn
    parameter W_BpuHistCombOut = 5935   // 实际：BPU_TOP::BpuHistCombOut
) (
    input  wire [W_BpuHistCombIn-1:0]  bpu_predict_main_bundle,
    output wire [W_BpuHistCombOut-1:0] bpu_hist_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BpuHistCombIn-1:0]  pi;
    wire [W_BpuHistCombOut-1:0] po;
    assign pi = bpu_predict_main_bundle;

    assign bpu_hist_bundle = po;

    bpu_hist_comb_bsd_top #(
        .W_BpuHistCombIn(W_BpuHistCombIn),
        .W_BpuHistCombOut(W_BpuHistCombOut)
    ) u_bpu_hist_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_hist_comb_bsd_top #(
    parameter W_BpuHistCombIn  = 6944,  // 实际：BPU_TOP::BpuHistCombIn
    parameter W_BpuHistCombOut = 5935   // 实际：BPU_TOP::BpuHistCombOut
) (
    input  wire [W_BpuHistCombIn-1:0]  pi,
    output wire [W_BpuHistCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BpuHistCombOut{1'b0}};

endmodule
