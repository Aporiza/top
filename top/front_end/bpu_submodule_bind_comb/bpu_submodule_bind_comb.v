// Formal frontend comb training unit: bpu_submodule_bind_comb.
// Canonical source: simulator-new/front-end/BPU/BPU.h:31219 area; binds predictor submodule outputs.
//
// This file is a synthesizable boundary shell. The pass-through body keeps
// the 27-comb structure connected; replace this body with generated/trained
// RTL when the implementation is available.

module bpu_submodule_bind_comb #(
    parameter integer W_IN = 64,
    parameter integer W_OUT = 64
) (
    input wire [W_IN-1:0] pi,
    output wire [W_OUT-1:0] po
);
    generate
        if (W_OUT <= W_IN) begin : gen_truncate_or_equal
            assign po = pi[W_OUT-1:0];
        end else begin : gen_zero_extend
            assign po = {{(W_OUT - W_IN){1'b0}}, pi};
        end
    endgenerate
endmodule