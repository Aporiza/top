// 前端正式 comb 边界： btb_post_read_req_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 BTB 读后请求包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：btb_post_read_req_comb
// 来源：BPU/target_predictor/BTB_top.h
// 配置：simulator-front 默认 large 配置
// 接口：BTB_TOP::BtbPostReadReqCombIn(2264 bit) -> BTB_TOP::BtbPostReadReqCombOut(45 bit)
//
// 输入 BTB_TOP::BtbPostReadReqCombIn = 2264 bit
//   = inp  105 bit
//   + rd  2159 bit
//   = 合计  2264 bit
//
// 输出 BTB_TOP::BtbPostReadReqCombOut = 45 bit
//   = pred_tc_read_valid  1 bit
//   + pred_tc_idx        11 bit
//   + upd_next_bht_data  11 bit
//   + upd_tc_read_valid   1 bit
//   + upd_tc_write_idx   11 bit
//   + upd_tc_write_tag   10 bit
//   = 合计                 45 bit
//
// 关键结构展开：
//   inp : BTB_TOP::InputPayload  105 bit
//   rd  : BTB_TOP::ReadData     2159 bit
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
// 自查确认：btb_post_read_req_comb Input Bits = 2264, Output Bits = 45。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module btb_post_read_req_comb_top #(
    parameter W_BtbPostReadReqCombIn  = 2264,  // 实际：2264, BTB_TOP::BtbPostReadReqCombIn
    parameter W_BtbPostReadReqCombOut = 45     // 实际：BTB_TOP::BtbPostReadReqCombOut
) (
    input  wire [W_BtbPostReadReqCombIn-1:0]  btb_post_read_req_input_bundle,
    output wire [W_BtbPostReadReqCombOut-1:0] btb_post_read_req_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_BtbPostReadReqCombIn-1:0]  pi;
    wire [W_BtbPostReadReqCombOut-1:0] po;
    assign pi = btb_post_read_req_input_bundle;

    assign btb_post_read_req_bundle = po;

    btb_post_read_req_comb_bsd_top #(
        .W_BtbPostReadReqCombIn(W_BtbPostReadReqCombIn),
        .W_BtbPostReadReqCombOut(W_BtbPostReadReqCombOut)
    ) u_btb_post_read_req_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module btb_post_read_req_comb_bsd_top #(
    parameter W_BtbPostReadReqCombIn  = 2264,  // 实际：2264, BTB_TOP::BtbPostReadReqCombIn
    parameter W_BtbPostReadReqCombOut = 45     // 实际：BTB_TOP::BtbPostReadReqCombOut
) (
    input  wire [W_BtbPostReadReqCombIn-1:0]  pi,
    output wire [W_BtbPostReadReqCombOut-1:0] po
);

    // 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_BtbPostReadReqCombOut{1'b0}};

endmodule
