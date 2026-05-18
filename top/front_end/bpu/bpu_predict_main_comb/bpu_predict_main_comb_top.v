// Formal frontend comb boundary: bpu_predict_main_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/BPU.h:1029,1585.
// Role: main prediction output.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module bpu_predict_main_comb_top #(
    parameter integer W_BpuPredictMainCombIn = 64,
    parameter integer W_BpuPredictMainCombOut = 64
) (
    input wire [W_BpuPredictMainCombIn-1:0] bpu_predict_main_comb_in,
    output wire [W_BpuPredictMainCombOut-1:0] bpu_predict_main_comb_out
);

    wire [W_BpuPredictMainCombIn-1:0] bpu_predict_main_comb_pi;
    wire [W_BpuPredictMainCombOut-1:0] bpu_predict_main_comb_po;

    assign bpu_predict_main_comb_pi = bpu_predict_main_comb_in;
    assign bpu_predict_main_comb_out = bpu_predict_main_comb_po;

    bpu_predict_main_comb_bsd_top #(
        .W_BpuPredictMainCombIn(W_BpuPredictMainCombIn),
        .W_BpuPredictMainCombOut(W_BpuPredictMainCombOut)
    ) u_bpu_predict_main_comb_bsd_top (
        .pi(bpu_predict_main_comb_pi),
        .po(bpu_predict_main_comb_po)
    );

endmodule

module bpu_predict_main_comb_bsd_top #(
    parameter integer W_BpuPredictMainCombIn = 64,
    parameter integer W_BpuPredictMainCombOut = 64
) (
    input wire [W_BpuPredictMainCombIn-1:0] pi,
    output wire [W_BpuPredictMainCombOut-1:0] po
);
    assign po = {W_BpuPredictMainCombOut{1'b0}};
endmodule
