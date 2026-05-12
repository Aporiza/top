// Source struct:
//   icache_in  = {reset, refetch, itlb_flush, fence_i, invalidate_req,
//                 icache_read_valid, fetch_address, icache_read_valid_2,
//                 fetch_address_2, csr_status, run_comb_only}
//   icache_out = ready/completion/perf fields plus fetched instruction groups.
// ICache tag/data arrays, miss handling and ITLB/PTW runtime state stay internal.

module icache_top #(
    parameter integer FETCH_WIDTH = 16,
    parameter integer W_CsrStatusIO = 32 + 32 + 32 + 2,
    parameter integer W_IcacheIn =
        1 + 1 + 1 + 1 + 1 + 1 + 32 + 1 + 32 + W_CsrStatusIO + 1,
    parameter integer W_IcacheOut =
        4 + 14 + (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH +
        (32 * FETCH_WIDTH) + FETCH_WIDTH + FETCH_WIDTH + 32 + 32
) (
    input wire [W_IcacheIn-1:0] icache_in,

    output wire [W_IcacheOut-1:0] icache_out,
    output wire icache_read_ready,
    output wire icache_read_complete,
    output wire [(32 * FETCH_WIDTH)-1:0] fetch_group,
    output wire [(32 * FETCH_WIDTH)-1:0] fetch_pc_group,
    output wire [FETCH_WIDTH-1:0] page_fault_inst,
    output wire [FETCH_WIDTH-1:0] inst_valid
);

    wire [W_IcacheIn-1:0]  pi;
    wire [W_IcacheOut-1:0] po;

    wire reset;
    wire refetch;
    wire itlb_flush;
    wire fence_i;
    wire invalidate_req;
    wire icache_read_valid;
    wire [31:0] fetch_address;
    wire icache_read_valid_2;
    wire [31:0] fetch_address_2;
    wire [W_CsrStatusIO-1:0] csr_status;
    wire run_comb_only;
    assign {
        reset,
        refetch,
        itlb_flush,
        fence_i,
        invalidate_req,
        icache_read_valid,
        fetch_address,
        icache_read_valid_2,
        fetch_address_2,
        csr_status,
        run_comb_only
    } = icache_in;

    wire icache_read_ready_2;
    wire icache_read_complete_2;
    wire [13:0] perf_flags;
    wire [(32 * FETCH_WIDTH)-1:0] fetch_group_2;
    wire [FETCH_WIDTH-1:0] page_fault_inst_2;
    wire [FETCH_WIDTH-1:0] inst_valid_2;
    wire [31:0] fetch_pc;
    wire [31:0] fetch_pc_2;

    genvar fetch_lane;

    assign pi = {
        icache_in
    };

    assign {
        icache_read_ready,
        icache_read_complete,
        icache_read_ready_2,
        icache_read_complete_2,
        perf_flags,
        fetch_group,
        page_fault_inst,
        inst_valid,
        fetch_group_2,
        page_fault_inst_2,
        inst_valid_2,
        fetch_pc,
        fetch_pc_2
    } = po;

    generate
        for (fetch_lane = 0; fetch_lane < FETCH_WIDTH;
             fetch_lane = fetch_lane + 1) begin : gen_fetch_pc_group
            assign fetch_pc_group
                [(32 * (fetch_lane + 1))-1:(32 * fetch_lane)] =
                    fetch_pc + (fetch_lane * 32'd4);
        end
    endgenerate

    assign icache_out = po;

    icache_bsd_top #(
        .W_IcacheIn(W_IcacheIn),
        .W_IcacheOut(W_IcacheOut)
    ) u_icache_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
