// Source struct:
//   predecode_in  = {inst, pc}
//   PredecodeResult = {type, target_address}
// The wrapper is vectorized per FETCH_WIDTH for top-level readability.

module predecode_top #(
    parameter integer FETCH_WIDTH = 16,
    parameter integer predecode_type_t_BITS = 2,
    parameter integer W_PredecodeIn = (32 * FETCH_WIDTH) + (32 * FETCH_WIDTH),
    parameter integer W_PredecodeOut =
        (predecode_type_t_BITS * FETCH_WIDTH) + (32 * FETCH_WIDTH)
) (
    input wire [W_PredecodeIn-1:0] predecode_in,

    output wire [W_PredecodeOut-1:0] predecode_out,
    output wire [(predecode_type_t_BITS * FETCH_WIDTH)-1:0] predecode_type,
    output wire [(32 * FETCH_WIDTH)-1:0] predecode_target_address
);

    wire [W_PredecodeIn-1:0]  pi;
    wire [W_PredecodeOut-1:0] po;

    wire [(32 * FETCH_WIDTH)-1:0] inst;
    wire [(32 * FETCH_WIDTH)-1:0] pc;
    assign {
        inst,
        pc
    } = predecode_in;

    assign pi = {
        predecode_in
    };

    assign {
        predecode_type,
        predecode_target_address
    } = po;

    assign predecode_out = po;

    predecode_bsd_top #(
        .W_PredecodeIn(W_PredecodeIn),
        .W_PredecodeOut(W_PredecodeOut)
    ) u_predecode_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
