// Formal frontend comb boundary: predecode_comb.
// Source: simulator-ff/front-end predecode comb calculation.
// Role: predecode result construction.
//
// The parent module connects this wrapper with bsd_pi/bsd_po.
// This wrapper unpacks the buses into semantic variable names before the BSD layer.

module predecode_comb_top #(
    parameter integer FETCH_WIDTH        = 16,
    parameter integer INST_BITS          = 32,
    parameter integer PC_BITS            = 32,
    parameter integer W_PredecodeOut     = 64,
    parameter integer W_PredecodeCombIn  = (FETCH_WIDTH * INST_BITS) + (FETCH_WIDTH * PC_BITS),
    parameter integer W_PredecodeCombOut = W_PredecodeOut
) (
    input  wire [W_PredecodeCombIn-1:0]  bsd_pi,
    output wire [W_PredecodeCombOut-1:0] bsd_po
);

    // Semantic view of the packed BSD input/output buses.
    wire [FETCH_WIDTH*INST_BITS-1:0] icache_fetch_group;
    wire [FETCH_WIDTH*PC_BITS-1:0]   predecode_fetch_pc_group;
    wire [W_PredecodeOut-1:0]        predecode_result;
    wire [W_PredecodeCombIn-1:0]     predecode_comb_bsd_pi;
    wire [W_PredecodeCombOut-1:0]    predecode_comb_bsd_po;

    assign {
        icache_fetch_group,
        predecode_fetch_pc_group
    } = bsd_pi;

    assign predecode_comb_bsd_pi = {
        icache_fetch_group,
        predecode_fetch_pc_group
    };

    assign {
        predecode_result
    } = predecode_comb_bsd_po;

    assign bsd_po = {
        predecode_result
    };

    predecode_comb_bsd_top #(
        .W_PredecodeCombIn(W_PredecodeCombIn),
        .W_PredecodeCombOut(W_PredecodeCombOut)
    ) u_predecode_comb_bsd_top (
        .bsd_pi(predecode_comb_bsd_pi),
        .bsd_po(predecode_comb_bsd_po)
    );

endmodule

module predecode_comb_bsd_top #(
    parameter integer W_PredecodeCombIn  = 64,
    parameter integer W_PredecodeCombOut = 64
) (
    input  wire [W_PredecodeCombIn-1:0]  bsd_pi,
    output wire [W_PredecodeCombOut-1:0] bsd_po
);

    assign bsd_po = {W_PredecodeCombOut{1'b0}};

endmodule
