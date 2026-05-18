// Formal frontend comb training unit: btb_post_read_req_comb.
// Canonical source: simulator-new/front-end/BTB_top.h; BTB post-read register comb.
//
// This file is a synthesizable boundary shell. The pass-through body keeps
// the 27-comb structure connected; replace this body with generated/trained
// RTL when the implementation is available.

module btb_post_read_req_comb #(
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