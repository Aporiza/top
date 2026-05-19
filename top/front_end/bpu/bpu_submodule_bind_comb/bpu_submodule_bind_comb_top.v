// Formal frontend comb boundary: bpu_submodule_bind_comb.
// Source: simulator-ff/front-end/BPU related comb calculation.
// Role: BPU predictor submodule result binding.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module bpu_submodule_bind_comb_top #(
    parameter integer W_BpuSubmoduleBindCombIn  = 64,
    parameter integer W_BpuSubmoduleBindCombOut = 64
) (
    input  wire [W_BpuSubmoduleBindCombIn-1:0]  bsd_pi,
    output wire [W_BpuSubmoduleBindCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [W_BpuSubmoduleBindCombIn-1:0]  bpu_submodule_bind_input_bundle;
    wire [W_BpuSubmoduleBindCombOut-1:0] bpu_submodule_bind_bundle;
    wire [W_BpuSubmoduleBindCombIn-1:0]  bpu_submodule_bind_comb_bsd_pi;
    wire [W_BpuSubmoduleBindCombOut-1:0] bpu_submodule_bind_comb_bsd_po;

    assign {
        bpu_submodule_bind_input_bundle
    } = bsd_pi;

    assign bpu_submodule_bind_comb_bsd_pi = {
        bpu_submodule_bind_input_bundle
    };

    assign {
        bpu_submodule_bind_bundle
    } = bpu_submodule_bind_comb_bsd_po;

    assign bsd_po = {
        bpu_submodule_bind_bundle
    };

    bpu_submodule_bind_comb_bsd_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuSubmoduleBindCombIn),
        .W_BpuSubmoduleBindCombOut(W_BpuSubmoduleBindCombOut)
    ) u_bpu_submodule_bind_comb_bsd_top (
        .bsd_pi(bpu_submodule_bind_comb_bsd_pi),
        .bsd_po(bpu_submodule_bind_comb_bsd_po)
    );

endmodule

module bpu_submodule_bind_comb_bsd_top #(
    parameter integer W_BpuSubmoduleBindCombIn  = 64,
    parameter integer W_BpuSubmoduleBindCombOut = 64
) (
    input  wire [W_BpuSubmoduleBindCombIn-1:0]  bsd_pi,
    output wire [W_BpuSubmoduleBindCombOut-1:0] bsd_po
);

    assign bsd_po = {W_BpuSubmoduleBindCombOut{1'b0}};

endmodule
