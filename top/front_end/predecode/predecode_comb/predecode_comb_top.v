// Formal frontend comb boundary: predecode_comb.
// Source: simulator-front/front-end predecode comb calculation.
// Role: predecode result construction.
//
// The parent module connects this wrapper with semantic variable ports.
// Only the BSD implementation layer keeps the packed pi/po interface.

module predecode_comb_top #(
    parameter integer FETCH_WIDTH        = 16,
    parameter integer INST_BITS          = 32,
    parameter integer PC_BITS            = 32,
    parameter integer W_PredecodeOut     = 544,  // actual: 544, from front_top W_PredecodeOut
    parameter integer W_PredecodeCombIn  = (FETCH_WIDTH * INST_BITS) + (FETCH_WIDTH * PC_BITS),  // actual: 1024, from front_top W_PredecodeIn
    parameter integer W_PredecodeCombOut = W_PredecodeOut    // actual: 544, from front_top W_PredecodeOut
) (
    input  wire [FETCH_WIDTH*INST_BITS-1:0] icache_fetch_group,
    input  wire [FETCH_WIDTH*PC_BITS-1:0]   predecode_fetch_pc_group,
    output wire [W_PredecodeOut-1:0]        predecode_result
);

    // Packed pi/po bridge for the BSD implementation layer.
    wire [W_PredecodeCombIn-1:0]     pi;
    wire [W_PredecodeCombOut-1:0]    po;
    assign pi = {
        icache_fetch_group,
        predecode_fetch_pc_group
    };

    assign {
        predecode_result
    } = po;

    predecode_comb_bsd_top #(
        .W_PredecodeCombIn(W_PredecodeCombIn),
        .W_PredecodeCombOut(W_PredecodeCombOut)
    ) u_predecode_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module predecode_comb_bsd_top #(
    parameter integer W_PredecodeCombIn  = 1024,  // actual: 1024, from front_top W_PredecodeIn
    parameter integer W_PredecodeCombOut = 544    // actual: 544, from front_top W_PredecodeOut
) (
    input  wire [W_PredecodeCombIn-1:0]  pi,
    output wire [W_PredecodeCombOut-1:0] po
);

    assign po = {W_PredecodeCombOut{1'b0}};

endmodule
