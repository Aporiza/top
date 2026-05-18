// Frontend 27-comb structural top.
//
// Canonical execution reference:
//   simulator-new/front-end/front_top.cpp::front_comb_calc()
//   simulator-new/rv_simu_mmu_v2.cpp::SimCpu::front_cycle()
//
// Packaging policy:
//   - Do not hide the training units inside eight coarse groups.
//   - Keep the 27 formal comb units as one folder and one Verilog module each.
//   - front_top only wires those 27 units in the same order used by the
//     front_cycle/front_top explanation documents.
//   - The stage-0 initialization/defaulting code lives in this top and is not
//     counted as a formal comb module.
//
// The comb modules are currently synthesizable pass-through boundary shells.
// Replace each shell body with the generated/trained RTL for that unit when
// it is ready.

module front_top #(
    parameter integer LINK_WIDTH = 64
) (
    input wire [LINK_WIDTH-1:0] pi,
    output wire [LINK_WIDTH-1:0] po
);
    wire [LINK_WIDTH-1:0] comb_link_00;
    wire [LINK_WIDTH-1:0] comb_link_01;
    wire [LINK_WIDTH-1:0] comb_link_02;
    wire [LINK_WIDTH-1:0] comb_link_03;
    wire [LINK_WIDTH-1:0] comb_link_04;
    wire [LINK_WIDTH-1:0] comb_link_05;
    wire [LINK_WIDTH-1:0] comb_link_06;
    wire [LINK_WIDTH-1:0] comb_link_07;
    wire [LINK_WIDTH-1:0] comb_link_08;
    wire [LINK_WIDTH-1:0] comb_link_09;
    wire [LINK_WIDTH-1:0] comb_link_10;
    wire [LINK_WIDTH-1:0] comb_link_11;
    wire [LINK_WIDTH-1:0] comb_link_12;
    wire [LINK_WIDTH-1:0] comb_link_13;
    wire [LINK_WIDTH-1:0] comb_link_14;
    wire [LINK_WIDTH-1:0] comb_link_15;
    wire [LINK_WIDTH-1:0] comb_link_16;
    wire [LINK_WIDTH-1:0] comb_link_17;
    wire [LINK_WIDTH-1:0] comb_link_18;
    wire [LINK_WIDTH-1:0] comb_link_19;
    wire [LINK_WIDTH-1:0] comb_link_20;
    wire [LINK_WIDTH-1:0] comb_link_21;
    wire [LINK_WIDTH-1:0] comb_link_22;
    wire [LINK_WIDTH-1:0] comb_link_23;
    wire [LINK_WIDTH-1:0] comb_link_24;
    wire [LINK_WIDTH-1:0] comb_link_25;
    wire [LINK_WIDTH-1:0] comb_link_26;
    wire [LINK_WIDTH-1:0] comb_link_27;
    wire [LINK_WIDTH-1:0] front_comb_init_default;

    // Stage 0: front_comb_calc() first clears the temporary input/output and
    // request bundles before the formal comb functions run. Model that as a
    // top-level default layer, then overlay the incoming training packet.
    assign front_comb_init_default = {LINK_WIDTH{1'b0}};
    assign comb_link_00 = front_comb_init_default | pi;

    front_global_control_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_00_front_global_control_comb (
        .pi(comb_link_00),
        .po(comb_link_01)
    );

    front_read_enable_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_01_front_read_enable_comb (
        .pi(comb_link_01),
        .po(comb_link_02)
    );

    front_read_stage_input_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_02_front_read_stage_input_comb (
        .pi(comb_link_02),
        .po(comb_link_03)
    );

    front_bpu_control_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_03_front_bpu_control_comb (
        .pi(comb_link_03),
        .po(comb_link_04)
    );

    bpu_pre_read_req_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_04_bpu_pre_read_req_comb (
        .pi(comb_link_04),
        .po(comb_link_05)
    );

    type_predictor_pre_read_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_05_type_predictor_pre_read_comb (
        .pi(comb_link_05),
        .po(comb_link_06)
    );

    tage_pre_read_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_06_tage_pre_read_comb (
        .pi(comb_link_06),
        .po(comb_link_07)
    );

    btb_pre_read_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_07_btb_pre_read_comb (
        .pi(comb_link_07),
        .po(comb_link_08)
    );

    bpu_post_read_req_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_08_bpu_post_read_req_comb (
        .pi(comb_link_08),
        .po(comb_link_09)
    );

    type_pred_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_09_type_pred_comb (
        .pi(comb_link_09),
        .po(comb_link_10)
    );

    tage_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_10_tage_comb (
        .pi(comb_link_10),
        .po(comb_link_11)
    );

    btb_post_read_req_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_11_btb_post_read_req_comb (
        .pi(comb_link_11),
        .po(comb_link_12)
    );

    btb_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_12_btb_comb (
        .pi(comb_link_12),
        .po(comb_link_13)
    );

    bpu_submodule_bind_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_13_bpu_submodule_bind_comb (
        .pi(comb_link_13),
        .po(comb_link_14)
    );

    bpu_predict_main_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_14_bpu_predict_main_comb (
        .pi(comb_link_14),
        .po(comb_link_15)
    );

    bpu_hist_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_15_bpu_hist_comb (
        .pi(comb_link_15),
        .po(comb_link_16)
    );

    bpu_queue_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_16_bpu_queue_comb (
        .pi(comb_link_16),
        .po(comb_link_17)
    );

    fetch_address_FIFO_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_17_fetch_address_FIFO_comb (
        .pi(comb_link_17),
        .po(comb_link_18)
    );

    predecode_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_18_predecode_comb (
        .pi(comb_link_18),
        .po(comb_link_19)
    );

    instruction_FIFO_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_19_instruction_FIFO_comb (
        .pi(comb_link_19),
        .po(comb_link_20)
    );

    front_ptab_write_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_20_front_ptab_write_comb (
        .pi(comb_link_20),
        .po(comb_link_21)
    );

    PTAB_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_21_PTAB_comb (
        .pi(comb_link_21),
        .po(comb_link_22)
    );

    front_checker_input_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_22_front_checker_input_comb (
        .pi(comb_link_22),
        .po(comb_link_23)
    );

    predecode_checker_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_23_predecode_checker_comb (
        .pi(comb_link_23),
        .po(comb_link_24)
    );

    front_front2back_write_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_24_front_front2back_write_comb (
        .pi(comb_link_24),
        .po(comb_link_25)
    );

    front2back_FIFO_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_25_front2back_FIFO_comb (
        .pi(comb_link_25),
        .po(comb_link_26)
    );

    front_output_comb #(.W_IN(LINK_WIDTH), .W_OUT(LINK_WIDTH))
    u_26_front_output_comb (
        .pi(comb_link_26),
        .po(comb_link_27)
    );

    assign po = comb_link_27;
endmodule
