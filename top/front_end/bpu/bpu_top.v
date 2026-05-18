// BPU grouped top for frontend comb training boundaries.
// Source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/BPU.h.

module bpu_top #(
    parameter integer W_BpuIn = 64,
    parameter integer W_BpuOut = 64
) (
    input wire [W_BpuIn-1:0] bpu_in,
    output wire [W_BpuOut-1:0] bpu_out
);

    wire [W_BpuOut-1:0] bpu_pre_read_req_payload;
    wire [W_BpuOut-1:0] type_predictor_pre_read_payload;
    wire [W_BpuOut-1:0] tage_pre_read_payload;
    wire [W_BpuOut-1:0] btb_pre_read_payload;
    wire [W_BpuOut-1:0] bpu_post_read_req_payload;
    wire [W_BpuOut-1:0] type_pred_payload;
    wire [W_BpuOut-1:0] tage_payload;
    wire [W_BpuOut-1:0] btb_post_read_req_payload;
    wire [W_BpuOut-1:0] btb_payload;
    wire [W_BpuOut-1:0] bpu_submodule_bind_payload;
    wire [W_BpuOut-1:0] bpu_predict_main_payload;
    wire [W_BpuOut-1:0] bpu_hist_payload;
    wire [W_BpuOut-1:0] bpu_queue_payload;

    bpu_pre_read_req_comb_top #(
        .W_BpuPreReadReqCombIn(W_BpuIn),
        .W_BpuPreReadReqCombOut(W_BpuOut)
    ) u_bpu_pre_read_req_comb_top (
        .bpu_pre_read_req_comb_in(bpu_in),
        .bpu_pre_read_req_comb_out(bpu_pre_read_req_payload)
    );

    type_predictor_pre_read_comb_top #(
        .W_TypePredictorPreReadCombIn(W_BpuOut),
        .W_TypePredictorPreReadCombOut(W_BpuOut)
    ) u_type_predictor_pre_read_comb_top (
        .type_predictor_pre_read_comb_in(bpu_pre_read_req_payload),
        .type_predictor_pre_read_comb_out(type_predictor_pre_read_payload)
    );

    tage_pre_read_comb_top #(
        .W_TagePreReadCombIn(W_BpuOut),
        .W_TagePreReadCombOut(W_BpuOut)
    ) u_tage_pre_read_comb_top (
        .tage_pre_read_comb_in(bpu_pre_read_req_payload),
        .tage_pre_read_comb_out(tage_pre_read_payload)
    );

    btb_pre_read_comb_top #(
        .W_BtbPreReadCombIn(W_BpuOut),
        .W_BtbPreReadCombOut(W_BpuOut)
    ) u_btb_pre_read_comb_top (
        .btb_pre_read_comb_in(bpu_pre_read_req_payload),
        .btb_pre_read_comb_out(btb_pre_read_payload)
    );

    bpu_post_read_req_comb_top #(
        .W_BpuPostReadReqCombIn(W_BpuOut),
        .W_BpuPostReadReqCombOut(W_BpuOut)
    ) u_bpu_post_read_req_comb_top (
        .bpu_post_read_req_comb_in(bpu_pre_read_req_payload),
        .bpu_post_read_req_comb_out(bpu_post_read_req_payload)
    );

    type_pred_comb_top #(
        .W_TypePredCombIn(W_BpuOut),
        .W_TypePredCombOut(W_BpuOut)
    ) u_type_pred_comb_top (
        .type_pred_comb_in((type_predictor_pre_read_payload | bpu_post_read_req_payload)),
        .type_pred_comb_out(type_pred_payload)
    );

    tage_comb_top #(
        .W_TageCombIn(W_BpuOut),
        .W_TageCombOut(W_BpuOut)
    ) u_tage_comb_top (
        .tage_comb_in((tage_pre_read_payload | bpu_post_read_req_payload)),
        .tage_comb_out(tage_payload)
    );

    btb_post_read_req_comb_top #(
        .W_BtbPostReadReqCombIn(W_BpuOut),
        .W_BtbPostReadReqCombOut(W_BpuOut)
    ) u_btb_post_read_req_comb_top (
        .btb_post_read_req_comb_in((btb_pre_read_payload | bpu_post_read_req_payload)),
        .btb_post_read_req_comb_out(btb_post_read_req_payload)
    );

    btb_comb_top #(
        .W_BtbCombIn(W_BpuOut),
        .W_BtbCombOut(W_BpuOut)
    ) u_btb_comb_top (
        .btb_comb_in(btb_post_read_req_payload),
        .btb_comb_out(btb_payload)
    );

    bpu_submodule_bind_comb_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuOut),
        .W_BpuSubmoduleBindCombOut(W_BpuOut)
    ) u_bpu_submodule_bind_comb_top (
        .bpu_submodule_bind_comb_in((type_pred_payload | tage_payload | btb_payload)),
        .bpu_submodule_bind_comb_out(bpu_submodule_bind_payload)
    );

    bpu_predict_main_comb_top #(
        .W_BpuPredictMainCombIn(W_BpuOut),
        .W_BpuPredictMainCombOut(W_BpuOut)
    ) u_bpu_predict_main_comb_top (
        .bpu_predict_main_comb_in(bpu_submodule_bind_payload),
        .bpu_predict_main_comb_out(bpu_predict_main_payload)
    );

    bpu_hist_comb_top #(
        .W_BpuHistCombIn(W_BpuOut),
        .W_BpuHistCombOut(W_BpuOut)
    ) u_bpu_hist_comb_top (
        .bpu_hist_comb_in(bpu_predict_main_payload),
        .bpu_hist_comb_out(bpu_hist_payload)
    );

    bpu_queue_comb_top #(
        .W_BpuQueueCombIn(W_BpuOut),
        .W_BpuQueueCombOut(W_BpuOut)
    ) u_bpu_queue_comb_top (
        .bpu_queue_comb_in(bpu_predict_main_payload),
        .bpu_queue_comb_out(bpu_queue_payload)
    );

    assign bpu_out = bpu_predict_main_payload | bpu_hist_payload | bpu_queue_payload;

endmodule
