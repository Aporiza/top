// 前端正式 comb 边界： tage_pre_read_comb.
// 源码依据： simulator-front/front-end/BPU 相关 comb 计算。
// 作用：生成 TAGE 预读请求包。
//
// 文件结构：
// 1. *_comb_top 是可读连接层，父模块使用具名变量/语义 bundle 连接。
// 2. 本层只按源码字段顺序打包 pi、拆包 po，不在这里实现真实算法。
// 3. *_comb_bsd_top 是后续补真实组合逻辑的交付层，对外统一保持 pi/po。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：tage_pre_read_comb
// 来源：train_IO.h / BPU/dir_predictor/TAGE_top.h
// 配置：simulator-front 默认 large 配置
// 接口：TagePreReadCombIn(2528 bit) -> TagePreReadCombOut(579 bit)
//
// 输入 TagePreReadCombIn = 2528 bit
//   = inp      1248 bit
//   + state_in 1280 bit
//   = 合计       2528 bit
//
// 输出 TagePreReadCombOut = 579 bit
//   = pred_req         262 bit
//   + upd_req          244 bit
//   + useful_reset_req  13 bit
//   + idx               60 bit
//   = 合计               579 bit
//
// 关键结构展开：
//   inp              : TAGE_TOP::InputPayload                  1248 bit
//   state_in         : TAGE_TOP::StateInput                    1280 bit
//   pred_req         : TAGE_TOP::TagePredReadReqCombOut         262 bit
//   upd_req          : TAGE_TOP::TageUpdReadReqCombOut          244 bit
//   useful_reset_req : TAGE_TOP::TageUsefulResetReadReqCombOut   13 bit
//   idx              : TAGE_TOP::IndexResult                     60 bit
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
// 自查确认：tage_pre_read_comb Input Bits = 2528, Output Bits = 579。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module tage_pre_read_comb_top #(
    parameter W_TagePreReadCombIn  = 2528,  // 实际：2528, TAGE_TOP::TagePreReadCombIn
    parameter W_TagePreReadCombOut = 579    // 实际：TAGE_TOP::TagePreReadCombOut
) (
    input  wire [W_TagePreReadCombIn-1:0]  bpu_pre_read_req_bundle,
    output wire [W_TagePreReadCombOut-1:0] tage_pre_read_bundle
);

    // BSD 实现层的 pi/po 打包桥接。
    wire [W_TagePreReadCombIn-1:0]  pi;
    wire [W_TagePreReadCombOut-1:0] po;
    assign pi = bpu_pre_read_req_bundle;

    assign tage_pre_read_bundle = po;

    tage_pre_read_comb_bsd_top #(
        .W_TagePreReadCombIn(W_TagePreReadCombIn),
        .W_TagePreReadCombOut(W_TagePreReadCombOut)
    ) u_tage_pre_read_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module tage_pre_read_comb_bsd_top #(
    parameter W_TagePreReadCombIn  = 2528,  // 实际：2528, TAGE_TOP::TagePreReadCombIn
    parameter W_TagePreReadCombOut = 579    // 实际：TAGE_TOP::TagePreReadCombOut
) (
    input  wire [W_TagePreReadCombIn-1:0]  pi,
    output wire [W_TagePreReadCombOut-1:0] po
);


`ifdef USE_CPP_GOLDEN_BSD
    `include "slices/cpp_golden/cpp_golden_bsd_macros.vh"
    `CPP_GOLDEN_BSD(tage_pre_read_comb, W_TagePreReadCombIn, W_TagePreReadCombOut)
`else
// 当前是占位输出；后续真实 BSD 组合逻辑应替换这一行。
    assign po = {W_TagePreReadCombOut{1'b0}};
`endif


endmodule
