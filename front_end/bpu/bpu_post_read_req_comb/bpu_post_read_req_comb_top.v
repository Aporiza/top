// 前端正式 comb 边界： bpu_post_read_req_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BPU 读后请求包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_post_read_req_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuPostReadReqCombIn(7332 bit) -> BpuPostReadReqCombOut(22509 bit)
//
// 输入 BpuPostReadReqCombIn = 7332 bit
//   = refetch                             1 bit
//   + in_update_base_pc[COMMIT_WIDTH]   256 bit
//   + in_upd_valid[COMMIT_WIDTH]          8 bit
//   + in_actual_br_type[COMMIT_WIDTH]    24 bit
//   + ghr_snapshot[GHR_LENGTH]          512 bit
//   + fh_snapshot[FH_N_MAX][TN_MAX]     384 bit
//   + path_snapshot                      16 bit
//   + pred_base_pc                       32 bit
//   + going_to_do_pred                    1 bit
//   + set_submodule_input                 1 bit
//   + do_pred_on_this_pc[FETCH_WIDTH]    16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]      80 bit
//   + do_pred_for_this_pc[FETCH_WIDTH]  512 bit
//   + going_to_do_upd[BPU_BANK_NUM]      16 bit
//   + q_data[BPU_BANK_NUM]             5408 bit
//   + nlp_pred_base_entry_snapshot       65 bit
//   = 合计                               7332 bit
//
// 输出 BpuPostReadReqCombOut = 22509 bit
//   = nlp_s1_re                 1 bit
//   + nlp_s1_idx               12 bit
//   + nlp_s1_req_pc            32 bit
//   + type_in                 816 bit
//   + tage_in[BPU_BANK_NUM] 19968 bit
//   + btb_in[BPU_BANK_NUM]   1680 bit
//   = 合计                    22509 bit
//
// 关键结构展开：
//   q_data[BPU_BANK_NUM]         : BPU_TOP::ReadData::QueueEntrySnapshot  5408 bit
//   nlp_pred_base_entry_snapshot : BPU_TOP::ReadData::NlpEntrySnapshot      65 bit
//   type_in                      : TypePredictor::InputPayload             816 bit
//   tage_in[BPU_BANK_NUM]        : TAGE_TOP::InputPayload                19968 bit
//   btb_in[BPU_BANK_NUM]         : BTB_TOP::InputPayload                  1680 bit
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
// 自查确认：bpu_post_read_req_comb Input Bits = 7332, Output Bits = 22509。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module bpu_post_read_req_comb_top #(
    parameter W_BpuPostReadReqCombIn  = 7332,   // 实际：BPU_TOP::BpuPostReadReqCombIn
    parameter W_BpuPostReadReqCombOut = 22509   // 实际：BPU_TOP::BpuPostReadReqCombOut
) (
    input  wire [W_BpuPostReadReqCombIn-1:0]  bpu_pre_read_req_bundle,
    output wire [W_BpuPostReadReqCombOut-1:0] bpu_post_read_req_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BpuPostReadReqCombIn-1:0]  pi;
    wire [W_BpuPostReadReqCombOut-1:0] po;
    assign pi = bpu_pre_read_req_bundle;

    assign bpu_post_read_req_bundle = po;

    bpu_post_read_req_comb_bsd_top #(
        .W_BpuPostReadReqCombIn(W_BpuPostReadReqCombIn),
        .W_BpuPostReadReqCombOut(W_BpuPostReadReqCombOut)
    ) u_bpu_post_read_req_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_post_read_req_comb_bsd_top #(
    parameter W_BpuPostReadReqCombIn  = 7332,   // 实际：BPU_TOP::BpuPostReadReqCombIn
    parameter W_BpuPostReadReqCombOut = 22509   // 实际：BPU_TOP::BpuPostReadReqCombOut
) (
    input  wire [W_BpuPostReadReqCombIn-1:0]  pi,
    output wire [W_BpuPostReadReqCombOut-1:0] po
);

    localparam [W_BpuPostReadReqCombOut-1:0] BPU_POST_READ_REQ_ZERO = 0;

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = BPU_POST_READ_REQ_ZERO;

endmodule
