// Formal frontend comb boundary: bpu_submodule_bind_comb.
// Canonical source: simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/front-end/BPU/BPU.h:1006,1560.
// Role: bind Type/TAGE/BTB outputs.
//
// This top keeps a semantic packed boundary around the BSD pi/po interface.
// The slices/ directory next to this file is reserved for future concrete RTL.

module bpu_submodule_bind_comb_top #(
    parameter integer W_BpuSubmoduleBindCombIn = 64,
    parameter integer W_BpuSubmoduleBindCombOut = 64
) (
    input wire [W_BpuSubmoduleBindCombIn-1:0] bpu_submodule_bind_comb_in,
    output wire [W_BpuSubmoduleBindCombOut-1:0] bpu_submodule_bind_comb_out
);

    wire [W_BpuSubmoduleBindCombIn-1:0] bpu_submodule_bind_comb_pi;
    wire [W_BpuSubmoduleBindCombOut-1:0] bpu_submodule_bind_comb_po;

    assign bpu_submodule_bind_comb_pi = bpu_submodule_bind_comb_in;
    assign bpu_submodule_bind_comb_out = bpu_submodule_bind_comb_po;

    bpu_submodule_bind_comb_bsd_top #(
        .W_BpuSubmoduleBindCombIn(W_BpuSubmoduleBindCombIn),
        .W_BpuSubmoduleBindCombOut(W_BpuSubmoduleBindCombOut)
    ) u_bpu_submodule_bind_comb_bsd_top (
        .pi(bpu_submodule_bind_comb_pi),
        .po(bpu_submodule_bind_comb_po)
    );

endmodule

module bpu_submodule_bind_comb_bsd_top #(
    parameter integer W_BpuSubmoduleBindCombIn = 64,
    parameter integer W_BpuSubmoduleBindCombOut = 64
) (
    input wire [W_BpuSubmoduleBindCombIn-1:0] pi,
    output wire [W_BpuSubmoduleBindCombOut-1:0] po
);
    assign po = {W_BpuSubmoduleBindCombOut{1'b0}};
endmodule
