`timescale 1ns/1ps

// 前端顶层烟测 testbench。
// 目的：
// 1. 验证 front_top 在当前占位 BSD 版本下可以被仿真器展开并运行若干拍。
// 2. 验证顶层时钟、rst_n、reset、ICache 边界和宽总线连接没有明显 X/端口错误。
// 3. 该用例不验证 27 个 comb 的真实功能；真实功能等 BSD 逻辑替换后再加对拍断言。
module front_top_smoke_tb;

    parameter FETCH_WIDTH            = 16;
    parameter COMMIT_WIDTH           = 8;
    parameter TN_MAX                 = 4;
    parameter PC_BITS                = 32;
    parameter INST_BITS              = 32;
    parameter PRIVILEGE_BITS         = 2;
    parameter PCPN_BITS              = 3;
    parameter BR_TYPE_BITS           = 3;
    parameter TAGE_IDX_BITS          = 12;
    parameter TAGE_TAG_BITS          = 8;
    parameter BPU_SCL_META_NTABLE    = 8;
    parameter BPU_SCL_META_IDX_BITS  = 16;
    parameter BPU_SCL_META_SUM_BITS  = 16;
    parameter BPU_LOOP_META_IDX_BITS = 16;
    parameter BPU_LOOP_META_TAG_BITS = 16;
    parameter W_FrontTopOut          =
        1
      + (FETCH_WIDTH * PC_BITS)
      + (FETCH_WIDTH * INST_BITS)
      + FETCH_WIDTH
      + PC_BITS
      + FETCH_WIDTH
      + (2 * FETCH_WIDTH * PCPN_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (FETCH_WIDTH * TN_MAX * TAGE_IDX_BITS)
      + (FETCH_WIDTH * TN_MAX * TAGE_TAG_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (FETCH_WIDTH * BPU_SCL_META_SUM_BITS)
      + (FETCH_WIDTH * BPU_SCL_META_NTABLE * BPU_SCL_META_IDX_BITS)
      + FETCH_WIDTH
      + FETCH_WIDTH
      + FETCH_WIDTH
      + (FETCH_WIDTH * BPU_LOOP_META_IDX_BITS)
      + (FETCH_WIDTH * BPU_LOOP_META_TAG_BITS);

`ifdef FRONT_TOP_CRTL_COMPARE
    import "DPI-C" context function void cpp_front_top_oracle_reset();
    import "DPI-C" context function void cpp_front_top_oracle_step(
        input bit reset,
        input bit refetch,
        input bit itlb_flush,
        input bit fence_i,
        input int unsigned refetch_address,
        input bit FIFO_read_enable,
        input bit [COMMIT_WIDTH-1:0] back2front_valid,
        input bit [COMMIT_WIDTH*PC_BITS-1:0] predict_base_pc,
        input bit [COMMIT_WIDTH-1:0] predict_dir,
        input bit [COMMIT_WIDTH-1:0] actual_dir,
        input bit [COMMIT_WIDTH*BR_TYPE_BITS-1:0] actual_br_type,
        input bit [COMMIT_WIDTH*PC_BITS-1:0] actual_target,
        input bit [COMMIT_WIDTH-1:0] alt_pred,
        input bit [COMMIT_WIDTH*PCPN_BITS-1:0] altpcpn,
        input bit [COMMIT_WIDTH*PCPN_BITS-1:0] pcpn,
        input bit [COMMIT_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0] tage_idx,
        input bit [COMMIT_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0] tage_tag,
        input bit [COMMIT_WIDTH-1:0] sc_used,
        input bit [COMMIT_WIDTH-1:0] sc_pred,
        input bit [COMMIT_WIDTH*BPU_SCL_META_SUM_BITS-1:0] sc_sum,
        input bit [COMMIT_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS-1:0] sc_idx,
        input bit [COMMIT_WIDTH-1:0] loop_used,
        input bit [COMMIT_WIDTH-1:0] loop_hit,
        input bit [COMMIT_WIDTH-1:0] loop_pred,
        input bit [COMMIT_WIDTH*BPU_LOOP_META_IDX_BITS-1:0] loop_idx,
        input bit [COMMIT_WIDTH*BPU_LOOP_META_TAG_BITS-1:0] loop_tag,
        input int unsigned csr_status_sstatus,
        input int unsigned csr_status_mstatus,
        input int unsigned csr_status_satp,
        input bit [PRIVILEGE_BITS-1:0] csr_status_privilege,
        output bit [W_FrontTopOut-1:0] front_top_out_packed
    );
`endif

    reg clk;
    reg rst_n;
    reg reset;
    reg refetch;
    reg itlb_flush;
    reg fence_i;
    reg [PC_BITS-1:0] refetch_address;
    reg FIFO_read_enable;

    reg [COMMIT_WIDTH-1:0]                                           back2front_valid;
    reg [COMMIT_WIDTH*PC_BITS-1:0]                                   predict_base_pc;
    reg [COMMIT_WIDTH-1:0]                                           predict_dir;
    reg [COMMIT_WIDTH-1:0]                                           actual_dir;
    reg [COMMIT_WIDTH*BR_TYPE_BITS-1:0]                              actual_br_type;
    reg [COMMIT_WIDTH*PC_BITS-1:0]                                   actual_target;
    reg [COMMIT_WIDTH-1:0]                                           alt_pred;
    reg [COMMIT_WIDTH*PCPN_BITS-1:0]                                 altpcpn;
    reg [COMMIT_WIDTH*PCPN_BITS-1:0]                                 pcpn;
    reg [COMMIT_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0]                      tage_idx;
    reg [COMMIT_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0]                      tage_tag;
    reg [COMMIT_WIDTH-1:0]                                           sc_used;
    reg [COMMIT_WIDTH-1:0]                                           sc_pred;
    reg [COMMIT_WIDTH*BPU_SCL_META_SUM_BITS-1:0]                     sc_sum;
    reg [COMMIT_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS-1:0] sc_idx;
    reg [COMMIT_WIDTH-1:0]                                           loop_used;
    reg [COMMIT_WIDTH-1:0]                                           loop_hit;
    reg [COMMIT_WIDTH-1:0]                                           loop_pred;
    reg [COMMIT_WIDTH*BPU_LOOP_META_IDX_BITS-1:0]                    loop_idx;
    reg [COMMIT_WIDTH*BPU_LOOP_META_TAG_BITS-1:0]                    loop_tag;

    reg [31:0]                      csr_status_sstatus;
    reg [31:0]                      csr_status_mstatus;
    reg [31:0]                      csr_status_satp;
    reg [PRIVILEGE_BITS-1:0]        csr_status_privilege;
    reg                             icache_read_ready;
    reg                             icache_read_complete;
    reg                             icache_read_ready_2;
    reg                             icache_read_complete_2;
    reg [FETCH_WIDTH*INST_BITS-1:0] icache_fetch_group;
    reg [FETCH_WIDTH-1:0]           icache_page_fault_inst;
    reg [FETCH_WIDTH-1:0]           icache_inst_valid;
    reg [PC_BITS-1:0]               icache_fetch_pc;
    reg [FETCH_WIDTH*INST_BITS-1:0] icache_fetch_group_2;
    reg [FETCH_WIDTH-1:0]           icache_page_fault_inst_2;
    reg [FETCH_WIDTH-1:0]           icache_inst_valid_2;
    reg [PC_BITS-1:0]               icache_fetch_pc_2;

    wire                             icache_read_valid;
    wire [PC_BITS-1:0]               fetch_address;
    wire                             icache_read_valid_2;
    wire [PC_BITS-1:0]               fetch_address_2;
    wire                             icache_reset;
    wire                             icache_refetch;
    wire                             icache_itlb_flush;
    wire                             icache_fence_i;
    wire                             icache_invalidate_req;
    wire                             icache_run_comb_only;
    wire [31:0]                      icache_csr_status_sstatus;
    wire [31:0]                      icache_csr_status_mstatus;
    wire [31:0]                      icache_csr_status_satp;
    wire [PRIVILEGE_BITS-1:0]        icache_csr_status_privilege;

    wire                                                             FIFO_valid;
    wire [FETCH_WIDTH*PC_BITS-1:0]                                   pc;
    wire [FETCH_WIDTH*INST_BITS-1:0]                                 instructions;
    wire [FETCH_WIDTH-1:0]                                           out_predict_dir;
    wire [PC_BITS-1:0]                                               predict_next_fetch_address;
    wire [FETCH_WIDTH-1:0]                                           out_alt_pred;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]                                 out_altpcpn;
    wire [FETCH_WIDTH*PCPN_BITS-1:0]                                 out_pcpn;
    wire [FETCH_WIDTH-1:0]                                           page_fault_inst;
    wire [FETCH_WIDTH-1:0]                                           inst_valid;
    wire [FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0]                      out_tage_idx;
    wire [FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0]                      out_tage_tag;
    wire [FETCH_WIDTH-1:0]                                           out_sc_used;
    wire [FETCH_WIDTH-1:0]                                           out_sc_pred;
    wire [FETCH_WIDTH*BPU_SCL_META_SUM_BITS-1:0]                     out_sc_sum;
    wire [FETCH_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS-1:0] out_sc_idx;
    wire [FETCH_WIDTH-1:0]                                           out_loop_used;
    wire [FETCH_WIDTH-1:0]                                           out_loop_hit;
    wire [FETCH_WIDTH-1:0]                                           out_loop_pred;
    wire [FETCH_WIDTH*BPU_LOOP_META_IDX_BITS-1:0]                    out_loop_idx;
    wire [FETCH_WIDTH*BPU_LOOP_META_TAG_BITS-1:0]                    out_loop_tag;

`ifdef FRONT_TOP_CRTL_COMPARE
    wire [W_FrontTopOut-1:0] rtl_front_top_out_packed = {
        FIFO_valid,
        pc,
        instructions,
        out_predict_dir,
        predict_next_fetch_address,
        out_alt_pred,
        out_altpcpn,
        out_pcpn,
        page_fault_inst,
        inst_valid,
        out_tage_idx,
        out_tage_tag,
        out_sc_used,
        out_sc_pred,
        out_sc_sum,
        out_sc_idx,
        out_loop_used,
        out_loop_hit,
        out_loop_pred,
        out_loop_idx,
        out_loop_tag
    };
    reg [W_FrontTopOut-1:0] cpp_front_top_out_packed;
    integer compare_cycle_idx;

    task automatic compare_front_top_with_cpp;
        input integer cycle_id;
        begin
            cpp_front_top_oracle_step(
                reset,
                refetch,
                itlb_flush,
                fence_i,
                refetch_address,
                FIFO_read_enable,
                back2front_valid,
                predict_base_pc,
                predict_dir,
                actual_dir,
                actual_br_type,
                actual_target,
                alt_pred,
                altpcpn,
                pcpn,
                tage_idx,
                tage_tag,
                sc_used,
                sc_pred,
                sc_sum,
                sc_idx,
                loop_used,
                loop_hit,
                loop_pred,
                loop_idx,
                loop_tag,
                csr_status_sstatus,
                csr_status_mstatus,
                csr_status_satp,
                csr_status_privilege,
                cpp_front_top_out_packed
            );
            if (rtl_front_top_out_packed !== cpp_front_top_out_packed) begin
                $display("C_RTL_MISMATCH cycle=%0d", cycle_id);
                $display("RTL FIFO_valid=%0b predict_next=0x%08x inst_valid=0x%04x",
                         FIFO_valid, predict_next_fetch_address, inst_valid);
                $display("CPP packed[127:0]=0x%032x", cpp_front_top_out_packed[127:0]);
                $display("RTL packed[127:0]=0x%032x", rtl_front_top_out_packed[127:0]);
                $fatal(1, "front_top C-RTL packed output mismatch");
            end
        end
    endtask
`endif

    front_top u_front_top (
        .clk(clk),
        .rst_n(rst_n),
        .reset(reset),
        .refetch(refetch),
        .itlb_flush(itlb_flush),
        .fence_i(fence_i),
        .refetch_address(refetch_address),
        .FIFO_read_enable(FIFO_read_enable),
        .back2front_valid(back2front_valid),
        .predict_base_pc(predict_base_pc),
        .predict_dir(predict_dir),
        .actual_dir(actual_dir),
        .actual_br_type(actual_br_type),
        .actual_target(actual_target),
        .alt_pred(alt_pred),
        .altpcpn(altpcpn),
        .pcpn(pcpn),
        .tage_idx(tage_idx),
        .tage_tag(tage_tag),
        .sc_used(sc_used),
        .sc_pred(sc_pred),
        .sc_sum(sc_sum),
        .sc_idx(sc_idx),
        .loop_used(loop_used),
        .loop_hit(loop_hit),
        .loop_pred(loop_pred),
        .loop_idx(loop_idx),
        .loop_tag(loop_tag),
        .csr_status_sstatus(csr_status_sstatus),
        .csr_status_mstatus(csr_status_mstatus),
        .csr_status_satp(csr_status_satp),
        .csr_status_privilege(csr_status_privilege),
        .icache_read_ready(icache_read_ready),
        .icache_read_complete(icache_read_complete),
        .icache_read_ready_2(icache_read_ready_2),
        .icache_read_complete_2(icache_read_complete_2),
        .icache_fetch_group(icache_fetch_group),
        .icache_page_fault_inst(icache_page_fault_inst),
        .icache_inst_valid(icache_inst_valid),
        .icache_fetch_pc(icache_fetch_pc),
        .icache_fetch_group_2(icache_fetch_group_2),
        .icache_page_fault_inst_2(icache_page_fault_inst_2),
        .icache_inst_valid_2(icache_inst_valid_2),
        .icache_fetch_pc_2(icache_fetch_pc_2),
        .icache_read_valid(icache_read_valid),
        .fetch_address(fetch_address),
        .icache_read_valid_2(icache_read_valid_2),
        .fetch_address_2(fetch_address_2),
        .icache_reset(icache_reset),
        .icache_refetch(icache_refetch),
        .icache_itlb_flush(icache_itlb_flush),
        .icache_fence_i(icache_fence_i),
        .icache_invalidate_req(icache_invalidate_req),
        .icache_run_comb_only(icache_run_comb_only),
        .icache_csr_status_sstatus(icache_csr_status_sstatus),
        .icache_csr_status_mstatus(icache_csr_status_mstatus),
        .icache_csr_status_satp(icache_csr_status_satp),
        .icache_csr_status_privilege(icache_csr_status_privilege),
        .FIFO_valid(FIFO_valid),
        .pc(pc),
        .instructions(instructions),
        .out_predict_dir(out_predict_dir),
        .predict_next_fetch_address(predict_next_fetch_address),
        .out_alt_pred(out_alt_pred),
        .out_altpcpn(out_altpcpn),
        .out_pcpn(out_pcpn),
        .page_fault_inst(page_fault_inst),
        .inst_valid(inst_valid),
        .out_tage_idx(out_tage_idx),
        .out_tage_tag(out_tage_tag),
        .out_sc_used(out_sc_used),
        .out_sc_pred(out_sc_pred),
        .out_sc_sum(out_sc_sum),
        .out_sc_idx(out_sc_idx),
        .out_loop_used(out_loop_used),
        .out_loop_hit(out_loop_hit),
        .out_loop_pred(out_loop_pred),
        .out_loop_idx(out_loop_idx),
        .out_loop_tag(out_loop_tag)
    );

    always #5 clk = ~clk;

    initial begin
`ifdef FRONT_TOP_CRTL_COMPARE
        cpp_front_top_oracle_reset();
`endif
        clk = 1'b0;
        rst_n = 1'b0;
        reset = 1'b0;
        refetch = 1'b0;
        itlb_flush = 1'b0;
        fence_i = 1'b0;
        refetch_address = {PC_BITS{1'b0}};
        FIFO_read_enable = 1'b0;

        back2front_valid = {COMMIT_WIDTH{1'b0}};
        predict_base_pc = {(COMMIT_WIDTH*PC_BITS){1'b0}};
        predict_dir = {COMMIT_WIDTH{1'b0}};
        actual_dir = {COMMIT_WIDTH{1'b0}};
        actual_br_type = {(COMMIT_WIDTH*BR_TYPE_BITS){1'b0}};
        actual_target = {(COMMIT_WIDTH*PC_BITS){1'b0}};
        alt_pred = {COMMIT_WIDTH{1'b0}};
        altpcpn = {(COMMIT_WIDTH*PCPN_BITS){1'b0}};
        pcpn = {(COMMIT_WIDTH*PCPN_BITS){1'b0}};
        tage_idx = {(COMMIT_WIDTH*TN_MAX*TAGE_IDX_BITS){1'b0}};
        tage_tag = {(COMMIT_WIDTH*TN_MAX*TAGE_TAG_BITS){1'b0}};
        sc_used = {COMMIT_WIDTH{1'b0}};
        sc_pred = {COMMIT_WIDTH{1'b0}};
        sc_sum = {(COMMIT_WIDTH*BPU_SCL_META_SUM_BITS){1'b0}};
        sc_idx = {(COMMIT_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS){1'b0}};
        loop_used = {COMMIT_WIDTH{1'b0}};
        loop_hit = {COMMIT_WIDTH{1'b0}};
        loop_pred = {COMMIT_WIDTH{1'b0}};
        loop_idx = {(COMMIT_WIDTH*BPU_LOOP_META_IDX_BITS){1'b0}};
        loop_tag = {(COMMIT_WIDTH*BPU_LOOP_META_TAG_BITS){1'b0}};

        csr_status_sstatus = 32'h0000_0001;
        csr_status_mstatus = 32'h0000_0002;
        csr_status_satp = 32'h0000_0003;
        csr_status_privilege = 2'b11;
        icache_read_ready = 1'b1;
        icache_read_complete = 1'b0;
        icache_read_ready_2 = 1'b0;
        icache_read_complete_2 = 1'b0;
        icache_fetch_group = {FETCH_WIDTH{32'h0000_0013}};
        icache_page_fault_inst = {FETCH_WIDTH{1'b0}};
        icache_inst_valid = {FETCH_WIDTH{1'b0}};
        icache_fetch_pc = 32'h8000_0000;
        icache_fetch_group_2 = {(FETCH_WIDTH*INST_BITS){1'b0}};
        icache_page_fault_inst_2 = {FETCH_WIDTH{1'b0}};
        icache_inst_valid_2 = {FETCH_WIDTH{1'b0}};
        icache_fetch_pc_2 = {PC_BITS{1'b0}};

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        reset = 1'b1;
        @(posedge clk);
        #1;

        if (icache_read_valid_2 !== 1'b0) begin
            $fatal(1, "slot1 ICache request should stay disabled in current config");
        end
        if (fetch_address_2 !== {PC_BITS{1'b0}}) begin
            $fatal(1, "slot1 fetch address should stay zero in current config");
        end
        if (icache_run_comb_only !== 1'b0) begin
            $fatal(1, "icache_run_comb_only should stay zero in this wrapper");
        end
`ifdef FRONT_TOP_CRTL_COMPARE
        compare_front_top_with_cpp(0);
`endif

        reset = 1'b0;
        itlb_flush = 1'b1;
        fence_i = 1'b1;
        csr_status_sstatus = 32'h1111_0001;
        csr_status_mstatus = 32'h2222_0002;
        csr_status_satp = 32'h3333_0003;
        csr_status_privilege = 2'b01;
        #1;

        if (icache_itlb_flush !== itlb_flush) begin
            $fatal(1, "ICache itlb_flush boundary is not connected");
        end
        if (icache_fence_i !== fence_i) begin
            $fatal(1, "ICache fence_i boundary is not connected");
        end
        if (icache_csr_status_sstatus !== csr_status_sstatus) begin
            $fatal(1, "ICache sstatus boundary is not connected");
        end
        if (icache_csr_status_mstatus !== csr_status_mstatus) begin
            $fatal(1, "ICache mstatus boundary is not connected");
        end
        if (icache_csr_status_satp !== csr_status_satp) begin
            $fatal(1, "ICache satp boundary is not connected");
        end
        if (icache_csr_status_privilege !== csr_status_privilege) begin
            $fatal(1, "ICache privilege boundary is not connected");
        end
`ifdef FRONT_TOP_CRTL_COMPARE
        compare_front_top_with_cpp(1);
`endif

        @(posedge clk);
        #1;
        refetch = 1'b1;
        refetch_address = 32'h8000_1000;
`ifdef FRONT_TOP_CRTL_COMPARE
        icache_read_complete = 1'b0;
        icache_inst_valid = {FETCH_WIDTH{1'b0}};
        compare_front_top_with_cpp(2);
`else
        icache_read_complete = 1'b1;
        icache_inst_valid = {FETCH_WIDTH{1'b1}};
`endif
        @(posedge clk);
        #1;

        if ($isunknown({
            FIFO_valid,
            pc,
            instructions,
            out_predict_dir,
            predict_next_fetch_address,
            out_alt_pred,
            out_altpcpn,
            out_pcpn,
            page_fault_inst,
            inst_valid,
            out_tage_idx,
            out_tage_tag,
            out_sc_used,
            out_sc_pred,
            out_sc_sum,
            out_sc_idx,
            out_loop_used,
            out_loop_hit,
            out_loop_pred,
            out_loop_idx,
            out_loop_tag,
            icache_read_valid,
            fetch_address,
            icache_invalidate_req
        })) begin
            $fatal(1, "front_top smoke outputs contain unknown value");
        end
`ifdef FRONT_TOP_CRTL_COMPARE
        compare_front_top_with_cpp(3);
`endif

        refetch = 1'b0;
        itlb_flush = 1'b0;
        fence_i = 1'b0;
        icache_read_complete = 1'b0;
        FIFO_read_enable = 1'b1;
`ifdef FRONT_TOP_CRTL_COMPARE
        for (compare_cycle_idx = 4; compare_cycle_idx < 8; compare_cycle_idx = compare_cycle_idx + 1) begin
            compare_front_top_with_cpp(compare_cycle_idx);
            @(posedge clk);
            #1;
        end
`else
        repeat (4) @(posedge clk);
`endif

        $display("FRONT_TOP_SMOKE_PASS");
        $finish;
    end

endmodule
