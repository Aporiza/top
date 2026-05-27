// 前端正式 comb 边界： bpu_predict_main_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BPU 主预测输出包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_predict_main_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuPredictMainCombIn(5798 bit) -> BpuPredictMainCombOut(6502 bit)
//
// 输入 BpuPredictMainCombIn = 5798 bit
//   = refetch                              1 bit
//   + refetch_address                     32 bit
//   + pred_base_pc                        32 bit
//   + boundary_addr                       32 bit
//   + pc_can_send_to_icache_snapshot       1 bit
//   + going_to_do_pred                     1 bit
//   + do_pred_on_this_pc[FETCH_WIDTH]     16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]       80 bit
//   + do_pred_for_this_pc[FETCH_WIDTH]   512 bit
//   + ras_has_entry_snapshot               1 bit
//   + ras_top_snapshot                    32 bit
//   + saved_2ahead_prediction_snapshot    32 bit
//   + saved_2ahead_pred_valid_snapshot     1 bit
//   + saved_mini_flush_correct_snapshot    1 bit
//   + saved_mini_flush_target_snapshot    32 bit
//   + type_out                            80 bit
//   + tage_out[BPU_BANK_NUM]            4352 bit
//   + btb_out[BPU_BANK_NUM]              560 bit
//   = 合计                                5798 bit
//
// 输出 BpuPredictMainCombOut = 6502 bit
//   = out                                                 4470 bit
//   + final_pred_dir[FETCH_WIDTH]                           16 bit
//   + next_fetch_addr_calc                                  32 bit
//   + final_2_ahead_address                                 32 bit
//   + tage_calc_pred_dir_latch_next[FETCH_WIDTH]            16 bit
//   + tage_calc_altpred_latch_next[FETCH_WIDTH]             16 bit
//   + tage_calc_pcpn_latch_next[FETCH_WIDTH]                48 bit
//   + tage_calc_altpcpn_latch_next[FETCH_WIDTH]             48 bit
//   + tage_pred_calc_tags_latch_next[FETCH_WIDTH][TN_MAX]  512 bit
//   + tage_pred_calc_idxs_latch_next[FETCH_WIDTH][TN_MAX]  768 bit
//   + tage_result_valid_latch_next[FETCH_WIDTH]             16 bit
//   + btb_pred_target_latch_next[FETCH_WIDTH]              512 bit
//   + btb_result_valid_latch_next[FETCH_WIDTH]              16 bit
//   = 合计                                                  6502 bit
//
// 关键结构展开：
//   type_out               : TypePredictor::OutputPayload   80 bit
//   tage_out[BPU_BANK_NUM] : TAGE_TOP::OutputPayload      4352 bit
//   btb_out[BPU_BANK_NUM]  : BTB_TOP::OutputPayload        560 bit
//   out                    : BPU_TOP::OutputPayload       4470 bit
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
// 自查确认：bpu_predict_main_comb Input Bits = 5798, Output Bits = 6502。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module bpu_predict_main_comb_top #(
    parameter W_BpuPredictMainCombIn  = 5798,  // 实际：BPU_TOP::BpuPredictMainCombIn
    parameter W_BpuPredictMainCombOut = 6502   // 实际：BPU_TOP::BpuPredictMainCombOut
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  bpu_submodule_bind_bundle,
    output wire [W_BpuPredictMainCombOut-1:0] bpu_predict_main_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BpuPredictMainCombIn-1:0]  pi;
    wire [W_BpuPredictMainCombOut-1:0] po;
    assign pi = bpu_submodule_bind_bundle;

    assign bpu_predict_main_bundle = po;

    bpu_predict_main_comb_bsd_top #(
        .W_BpuPredictMainCombIn(W_BpuPredictMainCombIn),
        .W_BpuPredictMainCombOut(W_BpuPredictMainCombOut)
    ) u_bpu_predict_main_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_predict_main_comb_bsd_top #(
    parameter W_BpuPredictMainCombIn  = 5798,  // 实际：BPU_TOP::BpuPredictMainCombIn
    parameter W_BpuPredictMainCombOut = 6502   // 实际：BPU_TOP::BpuPredictMainCombOut
) (
    input  wire [W_BpuPredictMainCombIn-1:0]  pi,
    output wire [W_BpuPredictMainCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BpuPredictMainCombOut{1'b0}};

endmodule
