// 前端正式 comb 边界： bpu_queue_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BPU 队列更新数据包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_queue_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuQueueCombIn(3152 bit) -> BpuQueueCombOut(3281 bit)
//
// 输入 BpuQueueCombIn = 3152 bit
//   = in_update_base_pc[COMMIT_WIDTH]               256 bit
//   + in_upd_valid[COMMIT_WIDTH]                      8 bit
//   + in_actual_dir[COMMIT_WIDTH]                     8 bit
//   + in_actual_br_type[COMMIT_WIDTH]                24 bit
//   + in_actual_targets[COMMIT_WIDTH]               256 bit
//   + in_pred_dir[COMMIT_WIDTH]                       8 bit
//   + in_alt_pred[COMMIT_WIDTH]                       8 bit
//   + in_pcpn[COMMIT_WIDTH]                          24 bit
//   + in_altpcpn[COMMIT_WIDTH]                       24 bit
//   + in_tage_tags[COMMIT_WIDTH][TN_MAX]            256 bit
//   + in_tage_idxs[COMMIT_WIDTH][TN_MAX]            384 bit
//   + in_sc_used[COMMIT_WIDTH]                        8 bit
//   + in_sc_pred[COMMIT_WIDTH]                        8 bit
//   + in_sc_sum[COMMIT_WIDTH]                       128 bit
//   + in_sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE] 1024 bit
//   + in_loop_used[COMMIT_WIDTH]                      8 bit
//   + in_loop_hit[COMMIT_WIDTH]                       8 bit
//   + in_loop_pred[COMMIT_WIDTH]                      8 bit
//   + in_loop_idx[COMMIT_WIDTH]                     128 bit
//   + in_loop_tag[COMMIT_WIDTH]                     128 bit
//   + q_wr_ptr_snapshot[BPU_BANK_NUM]               144 bit
//   + q_rd_ptr_snapshot[BPU_BANK_NUM]               144 bit
//   + q_count_snapshot[BPU_BANK_NUM]                144 bit
//   + going_to_do_upd[BPU_BANK_NUM]                  16 bit
//   = 合计                                           3152 bit
//
// 输出 BpuQueueCombOut = 3281 bit
//   = q_push_en[BPU_BANK_NUM]       16 bit
//   + q_pop_en[BPU_BANK_NUM]        16 bit
//   + q_wr_ptr_next[BPU_BANK_NUM]  144 bit
//   + q_rd_ptr_next[BPU_BANK_NUM]  144 bit
//   + q_count_next[BPU_BANK_NUM]   144 bit
//   + q_entry_we[COMMIT_WIDTH]       8 bit
//   + q_entry_bank[COMMIT_WIDTH]    32 bit
//   + q_entry_slot[COMMIT_WIDTH]    72 bit
//   + q_entry_data[COMMIT_WIDTH]  2704 bit
//   + update_queue_full              1 bit
//   = 合计                          3281 bit
//
// 关键结构展开：
//   q_entry_data[COMMIT_WIDTH] : BPU_TOP::ReadData::QueueEntrySnapshot 2704 bit
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
// 自查确认：bpu_queue_comb Input Bits = 3152, Output Bits = 3281。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module bpu_queue_comb_top #(
    parameter W_BpuQueueCombIn  = 3152,  // 实际：BPU_TOP::BpuQueueCombIn
    parameter W_BpuQueueCombOut = 3281   // 实际：BPU_TOP::BpuQueueCombOut
) (
    input  wire [W_BpuQueueCombIn-1:0]  bpu_predict_main_bundle,
    output wire [W_BpuQueueCombOut-1:0] bpu_queue_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BpuQueueCombIn-1:0]  pi;
    wire [W_BpuQueueCombOut-1:0] po;
    assign pi = bpu_predict_main_bundle;

    assign bpu_queue_bundle = po;

    bpu_queue_comb_bsd_top #(
        .W_BpuQueueCombIn(W_BpuQueueCombIn),
        .W_BpuQueueCombOut(W_BpuQueueCombOut)
    ) u_bpu_queue_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_queue_comb_bsd_top #(
    parameter W_BpuQueueCombIn  = 3152,  // 实际：BPU_TOP::BpuQueueCombIn
    parameter W_BpuQueueCombOut = 3281   // 实际：BPU_TOP::BpuQueueCombOut
) (
    input  wire [W_BpuQueueCombIn-1:0]  pi,
    output wire [W_BpuQueueCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BpuQueueCombOut{1'b0}};

endmodule
