// Formal frontend comb boundary: bpu_submodule_bind_comb.
// Source: simulator-front/front-end/BPU related comb calculation.
// Role: BPU predictor submodule result binding.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module bpu_submodule_bind_comb_top #(
    parameter integer W_BpuSubmoduleBindCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuSubmoduleBindCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuSubmoduleBindCombIn-1:0]  bpu_submodule_bind_input_bundle,
    output wire [W_BpuSubmoduleBindCombOut-1:0] bpu_submodule_bind_bundle
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_BpuSubmoduleBindCombIn-1:0]  pi;
    wire [W_BpuSubmoduleBindCombOut-1:0] po;
    assign pi = {
        bpu_submodule_bind_input_bundle
    };

    assign {
        bpu_submodule_bind_bundle
    } = po;

    bpu_submodule_bind_comb_bsd_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuSubmoduleBindCombIn),
        .W_BpuSubmoduleBindCombOut(W_BpuSubmoduleBindCombOut)
    ) u_bpu_submodule_bind_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module bpu_submodule_bind_comb_bsd_top #(
    parameter integer W_BpuSubmoduleBindCombIn  = 4949,  // actual: 4949, from bpu_top W_BpuOut
    parameter integer W_BpuSubmoduleBindCombOut = 4949    // actual: 4949, from bpu_top W_BpuOut
) (
    input  wire [W_BpuSubmoduleBindCombIn-1:0]  pi,
    output wire [W_BpuSubmoduleBindCombOut-1:0] po
);

    assign po = {W_BpuSubmoduleBindCombOut{1'b0}};

endmodule
