// 前端正式 comb 边界： PTAB_comb.
// 源码依据： simulator-front/front-end/fifo/PTAB.cpp.
// 作用：生成 PTAB 请求，并更新 PTAB 状态。
//
// 文件结构：
// 1. PTAB_comb_top 是连接层，接收 front_top 的变量端口和上一拍 PTAB 队首快照。
// 2. PTAB_comb_bsd_top 在本文件内直接实现 PTAB 队列，不再等待外部 BSD 代码。
// 3. 组合逻辑先计算本拍写入、读出、dummy 项和 mini flush 相关请求。
// 4. 时序逻辑在周期末更新 mem/dummy_mem/head/tail/count；aresetn 是异步硬复位，reset/refetch 是同步清空。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：PTAB_comb
// 来源：train_IO.h / PTAB.cpp
// 配置：simulator-front 默认 large 配置
// 接口：PtabCombIn(9710 bit) -> PtabCombOut(14555 bit)
//
// 输入 PtabCombIn = 9710 bit
//   = inp 4853 bit
//   + rd  4857 bit
//   = 合计  9710 bit
//
// 输出 PtabCombOut = 14555 bit
//   = out_regs          4851 bit
//   + clear_ptab           1 bit
//   + push_write_en        1 bit
//   + push_write_entry  4850 bit
//   + push_dummy_en        1 bit
//   + push_dummy_entry  4850 bit
//   + pop_en               1 bit
//   = 合计               14555 bit
//
// 关键结构展开：
//   inp              : PTAB_in        4853 bit
//   rd               : PTAB_read_data 4857 bit
//   out_regs         : PTAB_out       4851 bit
//   push_write_entry : PTAB_entry     4850 bit
//   push_dummy_entry : PTAB_entry     4850 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：PTAB_comb Input Bits = 9710, Output Bits = 14555。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module PTAB_comb_top #(
    parameter W_PtabIn       = 4853,   // 实际：PTAB_in
    parameter W_PtabOut      = 4851,   // 实际：PTAB_out
    parameter W_PtabCombOut  = 14555,  // 实际：PtabCombOut
    parameter PTAB_SIZE      = 32,     // 实际：frontend_feature_config.h
    parameter PTAB_SIZE_BITS = 6       // 实际：clog2(PTAB_SIZE + 1)
) (
    input  wire                     aclk,
    input  wire                     aresetn,
    input  wire [W_PtabIn-1:0]      ptab_in,
    input  wire [W_PtabOut-1:0]     ptab_rd,
    output wire [W_PtabCombOut-1:0] ptab_req
);

    localparam W_PtabPayload = W_PtabOut - 3;
    localparam W_PtabEntry = W_PtabOut - 1;
    localparam W_PtabReadData = PTAB_SIZE_BITS + 1 + W_PtabEntry;
    localparam W_PtabCombIn = W_PtabIn + W_PtabReadData;
    localparam W_PtabCombOutLocal =
        W_PtabOut + 1 + 1 + W_PtabEntry + 1 + W_PtabEntry + 1;

    wire [W_PtabReadData-1:0] ptab_read_data_view;
    wire [W_PtabEntry-1:0]    ptab_head_entry_view;
    wire                      ptab_head_valid_view;
    wire                      ptab_dummy_entry_view;

    assign ptab_dummy_entry_view = ptab_rd[W_PtabPayload + 2];
    assign ptab_head_valid_view = ~ptab_rd[W_PtabPayload];
    assign ptab_head_entry_view = {
        ptab_rd[W_PtabPayload-1:0],
        1'b0,
        ptab_dummy_entry_view
    };
    assign ptab_read_data_view = {
        {PTAB_SIZE_BITS{1'b0}},
        ptab_head_valid_view,
        ptab_head_entry_view
    };

    // 连接层把语义化输入和 PTAB 队首快照打包成 BSD pi。
    // read_data_view 对应 simulator-front 中 seq_read 看到的 PTAB head_valid/head_entry。
    wire [W_PtabCombIn-1:0]  pi;
    wire [W_PtabCombOutLocal-1:0] po;

    assign pi = {
        ptab_in,
        ptab_read_data_view
    };

    assign ptab_req = po;

    PTAB_comb_bsd_top #(
        .W_PtabIn(W_PtabIn),
        .W_PtabOut(W_PtabOut),
        .W_PtabCombOut(W_PtabCombOut),
        .PTAB_SIZE(PTAB_SIZE),
        .PTAB_SIZE_BITS(PTAB_SIZE_BITS)
    ) u_PTAB_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

// BSD 层：这里已经是可综合 PTAB 队列 RTL。
// 后续若调整 PTAB 行为，应优先对照 simulator-front 的 push/pop/clear/dummy 请求模型修改本层。
module PTAB_comb_bsd_top #(
    parameter W_PtabIn       = 4853,   // 实际：PTAB_in
    parameter W_PtabOut      = 4851,   // 实际：PTAB_out
    parameter W_PtabCombOut  = 14555,  // 实际：PtabCombOut
    parameter PTAB_SIZE      = 32,     // 实际：frontend_feature_config.h
    parameter PTAB_SIZE_BITS = 6       // 实际：clog2(PTAB_SIZE + 1)
) (
    input  wire                         aclk,
    input  wire                         aresetn,
    input  wire [W_PtabIn + PTAB_SIZE_BITS + 1 + (W_PtabOut - 1) - 1:0] pi,
    output wire [W_PtabCombOut-1:0] po
);

    localparam W_PtabPayload = W_PtabOut - 3;
    localparam W_PtabEntry = W_PtabOut - 1;
    localparam W_PtabReadData = PTAB_SIZE_BITS + 1 + W_PtabEntry;
    localparam W_PtabCombOutLocal =
        W_PtabOut + 1 + 1 + W_PtabEntry + 1 + W_PtabEntry + 1;
    localparam W_PtabCtrlOut = W_PtabCombOutLocal - W_PtabOut;
    localparam PTR_BITS = 5;  // PTAB_SIZE=32

    wire [W_PtabIn-1:0]       ptab_in;
    wire [W_PtabReadData-1:0] unused_ptab_read_data;

    assign {
        ptab_in,
        unused_ptab_read_data
    } = pi;

    // 第一阶段：拆输入。reset/refetch 是同步控制，aresetn 是硬复位。
    wire need_mini_flush = ptab_in[0];
    wire read_enable = ptab_in[1];
    wire [W_PtabPayload-1:0] write_payload =
        ptab_in[W_PtabPayload + 1:2];
    wire write_enable = ptab_in[W_PtabPayload + 2];
    wire refetch = ptab_in[W_PtabPayload + 3];
    wire reset = ptab_in[W_PtabPayload + 4];

    reg [W_PtabPayload-1:0] ptab_mem [0:PTAB_SIZE-1];
    reg                     ptab_dummy_mem [0:PTAB_SIZE-1];
    reg [PTR_BITS-1:0]      ptab_head;
    reg [PTR_BITS-1:0]      ptab_tail;
    reg [PTAB_SIZE_BITS-1:0] ptab_count;

    wire rd_valid = (ptab_count != {PTAB_SIZE_BITS{1'b0}});
    wire rd_dummy = ptab_dummy_mem[ptab_head];
    wire [W_PtabPayload-1:0] rd_payload = ptab_mem[ptab_head];

    reg do_write;
    reg push_dummy;
    reg do_read;
    reg pop_existing;
    reg bypass_write;
    reg store_write;
    reg store_dummy;
    reg [PTR_BITS-1:0] ptab_head_next;
    reg [PTR_BITS-1:0] ptab_tail_next;
    reg [PTR_BITS-1:0] ptab_tail_plus_one;
    reg [PTR_BITS-1:0] ptab_tail_plus_two;
    reg [PTR_BITS-1:0] ptab_dummy_write_ptr;
    reg [PTAB_SIZE_BITS-1:0] ptab_count_after_write;
    reg [PTAB_SIZE_BITS-1:0] ptab_count_next;
    reg next_full;
    reg next_empty;
    reg output_dummy;
    reg [W_PtabPayload-1:0] output_payload;
    reg [W_PtabOut-1:0] out_regs;

    // 第二阶段：组合判断本拍读写请求。
    always @(*) begin
        do_write = 1'b0;
        if (reset) begin
            do_write = 1'b0;
        end else if (refetch) begin
            do_write = 1'b0;
        end else begin
            do_write = write_enable;
        end
    end

    always @(*) begin
        push_dummy = 1'b0;
        if (do_write) begin
            if (need_mini_flush) begin
                push_dummy = 1'b1;
            end
        end
    end

    always @(*) begin
        do_read = 1'b0;
        if (reset) begin
            do_read = 1'b0;
        end else if (refetch) begin
            do_read = 1'b0;
        end else if (read_enable) begin
            if (rd_valid) begin
                do_read = 1'b1;
            end else if (do_write) begin
                do_read = 1'b1;
            end else if (push_dummy) begin
                do_read = 1'b1;
            end
        end
    end

    always @(*) begin
        pop_existing = 1'b0;
        if (do_read) begin
            if (rd_valid) begin
                pop_existing = 1'b1;
            end
        end
    end

    always @(*) begin
        bypass_write = 1'b0;
        if (do_read) begin
            if (!rd_valid) begin
                if (do_write) begin
                    bypass_write = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        store_write = 1'b0;
        if (do_write) begin
            if (!bypass_write) begin
                if (ptab_count < PTAB_SIZE) begin
                    store_write = 1'b1;
                end else if (pop_existing) begin
                    store_write = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        ptab_count_after_write = ptab_count;
        if (store_write) begin
            ptab_count_after_write = ptab_count + 1'b1;
        end
    end

    always @(*) begin
        store_dummy = 1'b0;
        if (push_dummy) begin
            if (ptab_count_after_write < PTAB_SIZE) begin
                store_dummy = 1'b1;
            end else if (pop_existing) begin
                store_dummy = 1'b1;
            end
        end
    end

    // 第三阶段：组合计算下一拍指针和计数。
    always @(*) begin
        ptab_tail_plus_one = ptab_tail;
        if (ptab_tail == (PTAB_SIZE - 1)) begin
            ptab_tail_plus_one = {PTR_BITS{1'b0}};
        end else begin
            ptab_tail_plus_one = ptab_tail + 1'b1;
        end
    end

    always @(*) begin
        ptab_tail_plus_two = ptab_tail_plus_one;
        if (ptab_tail_plus_one == (PTAB_SIZE - 1)) begin
            ptab_tail_plus_two = {PTR_BITS{1'b0}};
        end else begin
            ptab_tail_plus_two = ptab_tail_plus_one + 1'b1;
        end
    end

    always @(*) begin
        ptab_dummy_write_ptr = ptab_tail;
        if (store_write) begin
            ptab_dummy_write_ptr = ptab_tail_plus_one;
        end
    end

    always @(*) begin
        ptab_head_next = ptab_head;
        if (reset) begin
            ptab_head_next = {PTR_BITS{1'b0}};
        end else if (refetch) begin
            ptab_head_next = {PTR_BITS{1'b0}};
        end else if (pop_existing) begin
            if (ptab_head == (PTAB_SIZE - 1)) begin
                ptab_head_next = {PTR_BITS{1'b0}};
            end else begin
                ptab_head_next = ptab_head + 1'b1;
            end
        end
    end

    always @(*) begin
        ptab_tail_next = ptab_tail;
        if (reset) begin
            ptab_tail_next = {PTR_BITS{1'b0}};
        end else if (refetch) begin
            ptab_tail_next = {PTR_BITS{1'b0}};
        end else begin
            if (store_write) begin
                ptab_tail_next = ptab_tail_plus_one;
            end
            if (store_dummy) begin
                if (store_write) begin
                    ptab_tail_next = ptab_tail_plus_two;
                end else begin
                    ptab_tail_next = ptab_tail_plus_one;
                end
            end
        end
    end

    always @(*) begin
        ptab_count_next = ptab_count;
        if (reset) begin
            ptab_count_next = {PTAB_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            ptab_count_next = {PTAB_SIZE_BITS{1'b0}};
        end else begin
            if (store_write) begin
                ptab_count_next = ptab_count_next + 1'b1;
            end
            if (store_dummy) begin
                ptab_count_next = ptab_count_next + 1'b1;
            end
            if (pop_existing) begin
                if (ptab_count_next != {PTAB_SIZE_BITS{1'b0}}) begin
                    ptab_count_next = ptab_count_next - 1'b1;
                end
            end
        end
    end

    // 第四阶段：组合生成 PTAB 输出。
    always @(*) begin
        next_full = 1'b0;
        if (ptab_count_next >= (PTAB_SIZE - 1)) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (ptab_count_next == {PTAB_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    always @(*) begin
        output_dummy = 1'b0;
        if (do_read) begin
            if (rd_valid) begin
                output_dummy = rd_dummy;
            end
        end else if (rd_valid) begin
            output_dummy = rd_dummy;
        end
    end

    always @(*) begin
        output_payload = {W_PtabPayload{1'b0}};
        if (do_read) begin
            if (rd_valid) begin
                output_payload = rd_payload;
            end else begin
                output_payload = write_payload;
            end
        end else if (rd_valid) begin
            output_payload = rd_payload;
        end
    end

    always @(*) begin
        out_regs = {
            output_dummy,
            next_full,
            next_empty,
            output_payload
        };
    end

    assign po = {
        {W_PtabCtrlOut{1'b0}},
        out_regs
    };

    // 下面几个时序块里，三个分支对本寄存器都写 0，但信号语义不同：
    // aresetn 是异步硬复位；reset 是前端同步清空；refetch 是重取路径同步冲刷。
    // 优先级按代码顺序处理。
    // 第五阶段：时序更新 head。
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ptab_head <= {PTR_BITS{1'b0}};
        end else if (reset) begin
            ptab_head <= {PTR_BITS{1'b0}};
        end else if (refetch) begin
            ptab_head <= {PTR_BITS{1'b0}};
        end else begin
            ptab_head <= ptab_head_next;
        end
    end

    // 第六阶段：时序更新 tail。
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ptab_tail <= {PTR_BITS{1'b0}};
        end else if (reset) begin
            ptab_tail <= {PTR_BITS{1'b0}};
        end else if (refetch) begin
            ptab_tail <= {PTR_BITS{1'b0}};
        end else begin
            ptab_tail <= ptab_tail_next;
        end
    end

    // 第七阶段：时序更新 count。
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ptab_count <= {PTAB_SIZE_BITS{1'b0}};
        end else if (reset) begin
            ptab_count <= {PTAB_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            ptab_count <= {PTAB_SIZE_BITS{1'b0}};
        end else begin
            ptab_count <= ptab_count_next;
        end
    end

    // 第八阶段：时序写 PTAB 数据。清空只清指针和计数。
    always @(posedge aclk) begin
        if (reset) begin
            // reset 清空后不写 PTAB mem。
        end else if (refetch) begin
            // refetch 清空后不写 PTAB mem。
        end else begin
            if (store_write) begin
                ptab_mem[ptab_tail] <= write_payload;
            end
            if (store_dummy) begin
                ptab_mem[ptab_dummy_write_ptr] <= {W_PtabPayload{1'b0}};
            end
        end
    end

    // 第九阶段：时序写 dummy 标记。
    always @(posedge aclk) begin
        if (reset) begin
            // reset 清空后不写 dummy mem。
        end else if (refetch) begin
            // refetch 清空后不写 dummy mem。
        end else begin
            if (store_write) begin
                ptab_dummy_mem[ptab_tail] <= 1'b0;
            end
            if (store_dummy) begin
                ptab_dummy_mem[ptab_dummy_write_ptr] <= 1'b1;
            end
        end
    end

endmodule
