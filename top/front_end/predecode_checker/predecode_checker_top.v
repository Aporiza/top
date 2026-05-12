// Source struct:
//   predecode_checker_in  = {predict_dir, predict_next_fetch_address,
//                            predecode_type, predecode_target_address,
//                            seq_next_pc}
//   predecode_checker_out = {predict_dir_corrected,
//                            predict_next_fetch_address_corrected,
//                            predecode_flush_enable}
// Checker internal comparison logic stays inside the future slices.

module predecode_checker_top #(
    parameter integer FETCH_WIDTH = 16,
    parameter integer predecode_type_t_BITS = 2,
    parameter integer W_PredecodeCheckerIn =
        FETCH_WIDTH + 32 + (predecode_type_t_BITS * FETCH_WIDTH) +
        (32 * FETCH_WIDTH) + 32,
    parameter integer W_PredecodeCheckerOut = FETCH_WIDTH + 32 + 1
) (
    input wire [W_PredecodeCheckerIn-1:0] predecode_checker_in,

    output wire [W_PredecodeCheckerOut-1:0] predecode_checker_out,
    output wire [FETCH_WIDTH-1:0] predict_dir_corrected,
    output wire [31:0] predict_next_fetch_address_corrected,
    output wire predecode_flush_enable
);

    wire [W_PredecodeCheckerIn-1:0]  pi;
    wire [W_PredecodeCheckerOut-1:0] po;

    wire [FETCH_WIDTH-1:0] predict_dir;
    wire [31:0] predict_next_fetch_address;
    wire [(predecode_type_t_BITS * FETCH_WIDTH)-1:0] predecode_type;
    wire [(32 * FETCH_WIDTH)-1:0] predecode_target_address;
    wire [31:0] seq_next_pc;

    assign {
        predict_dir,
        predict_next_fetch_address,
        predecode_type,
        predecode_target_address,
        seq_next_pc
    } = predecode_checker_in;

    assign pi = {
        predecode_checker_in
    };

    assign {
        predict_dir_corrected,
        predict_next_fetch_address_corrected,
        predecode_flush_enable
    } = po;

    assign predecode_checker_out = po;

    predecode_checker_bsd_top #(
        .W_PredecodeCheckerIn(W_PredecodeCheckerIn),
        .W_PredecodeCheckerOut(W_PredecodeCheckerOut)
    ) u_predecode_checker_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
