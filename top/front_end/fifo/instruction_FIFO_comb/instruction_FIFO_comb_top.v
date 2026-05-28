// 前端正式 comb 边界： instruction_FIFO_comb.
// 源码依据： simulator-front/front-end/fifo/instruction_FIFO.cpp.
// 作用：生成 instruction FIFO 请求，并更新 FIFO 状态。
//
// 文件结构：
// 1. instruction_FIFO_comb_top 是连接层，接收 front_top 的变量端口和上一拍队首快照。
// 2. instruction_FIFO_comb_bsd_top 在本文件内直接实现 FIFO，不再等待外部 BSD 代码。
// 3. 组合逻辑先计算本拍 read/write、旁路输出和下一拍 head/tail/count。
// 4. 时序逻辑在周期末更新 mem/head/tail/count；aresetn 是异步硬复位，reset/refetch 是同步清空。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：instruction_FIFO_comb
// 来源：train_IO.h / fifo/instruction_FIFO.cpp
// 配置：simulator-front 默认 large 配置
// 接口：InstructionCombIn(3275 bit) -> InstructionCombOut(3270 bit)
//
// 输入 InstructionCombIn = 3275 bit
//   = inp 1636 bit
//   + rd  1639 bit
//   = 合计  3275 bit
//
// 输出 InstructionCombOut = 3270 bit
//   = out_regs   1635 bit
//   + clear_fifo    1 bit
//   + push_en       1 bit
//   + push_entry 1632 bit
//   + pop_en        1 bit
//   = 合计         3270 bit
//
// 关键结构展开：
//   inp        : instruction_FIFO_in        1636 bit
//   rd         : instruction_FIFO_read_data 1639 bit
//   out_regs   : instruction_FIFO_out       1635 bit
//   push_entry : instruction_FIFO_entry     1632 bit
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
// 自查确认：instruction_FIFO_comb Input Bits = 3275, Output Bits = 3270。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module instruction_FIFO_comb_top #(
    parameter W_InstructionFifoIn       = 1636,  // 实际：instruction_FIFO_in
    parameter W_InstructionFifoOut      = 1635,  // 实际：instruction_FIFO_out
    parameter W_InstructionCombOut      = 3270,  // 实际：InstructionCombOut
    parameter W_InstructionFifoLowData  = 576,   // 实际：predecode_result + seq_next_pc
    parameter INSTRUCTION_FIFO_SIZE     = 32,    // 实际：frontend_feature_config.h
    parameter INSTRUCTION_FIFO_SIZE_BITS = 6     // 实际：clog2(INSTRUCTION_FIFO_SIZE + 1)
) (
    input  wire                            aclk,
    input  wire                            aresetn,
    input  wire [W_InstructionFifoIn-1:0]  instruction_fifo_in,
    input  wire [W_InstructionFifoOut-1:0] fifo_rd,
    output wire [W_InstructionCombOut-1:0] instruction_fifo_req
);

    localparam W_InstructionPayload = W_InstructionFifoOut - 3;
    localparam W_InstructionFifoReadData =
        INSTRUCTION_FIFO_SIZE_BITS + 1 + W_InstructionPayload;
    localparam W_InstructionFifoCombIn =
        W_InstructionFifoIn + W_InstructionFifoReadData;
    localparam W_InstructionFifoCombOut = W_InstructionCombOut;

    wire [W_InstructionFifoReadData-1:0] fifo_read_data_view;
    wire                                 fifo_head_valid_view;

    assign fifo_head_valid_view = ~fifo_rd[W_InstructionPayload + 1];
    assign fifo_read_data_view = {
        {INSTRUCTION_FIFO_SIZE_BITS{1'b0}},
        fifo_head_valid_view,
        fifo_rd[W_InstructionPayload-1:0]
    };

    // 连接层把语义化输入和队首快照打包成 BSD pi。
    // read_data_view 对应 simulator-front 中 seq_read 看到的队首信息。
    wire [W_InstructionFifoCombIn-1:0]  pi;
    wire [W_InstructionFifoCombOut-1:0] po;

    assign pi = {
        instruction_fifo_in,
        fifo_read_data_view
    };

    assign instruction_fifo_req = po;

    instruction_FIFO_comb_bsd_top #(
        .W_InstructionFifoIn(W_InstructionFifoIn),
        .W_InstructionFifoOut(W_InstructionFifoOut),
        .W_InstructionFifoLowData(W_InstructionFifoLowData),
        .INSTRUCTION_FIFO_SIZE(INSTRUCTION_FIFO_SIZE),
        .INSTRUCTION_FIFO_SIZE_BITS(INSTRUCTION_FIFO_SIZE_BITS)
    ) u_instruction_FIFO_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

// BSD 层：这里已经是可综合 FIFO RTL。
// 后续若调整 FIFO 行为，应优先对照 simulator-front 的 push/pop/clear 请求模型修改本层。
module instruction_FIFO_comb_bsd_top #(
    parameter W_InstructionFifoIn       = 1636,  // 实际：instruction_FIFO_in
    parameter W_InstructionFifoOut      = 1635,  // 实际：instruction_FIFO_out
    parameter W_InstructionFifoLowData  = 576,   // 实际：predecode_result + seq_next_pc
    parameter INSTRUCTION_FIFO_SIZE     = 32,    // 实际：frontend_feature_config.h
    parameter INSTRUCTION_FIFO_SIZE_BITS = 6     // 实际：clog2(INSTRUCTION_FIFO_SIZE + 1)
) (
    input  wire                                   aclk,
    input  wire                                   aresetn,
    input  wire [W_InstructionFifoIn + INSTRUCTION_FIFO_SIZE_BITS + 1 + (W_InstructionFifoOut - 3) - 1:0] pi,
    output wire [(2 * W_InstructionFifoOut) - 1:0] po
);

    localparam W_InstructionPayload = W_InstructionFifoOut - 3;
    localparam W_InstructionFifoReadData =
        INSTRUCTION_FIFO_SIZE_BITS + 1 + W_InstructionPayload;
    localparam W_InstructionFifoCombOut = 2 * W_InstructionFifoOut;
    localparam W_InstructionHighData = W_InstructionPayload - W_InstructionFifoLowData;
    localparam W_InstructionCtrlOut = W_InstructionFifoCombOut - W_InstructionFifoOut;
    localparam PTR_BITS = 5;  // INSTRUCTION_FIFO_SIZE=32
    localparam [PTR_BITS-1:0] INSTRUCTION_FIFO_LAST_PTR = {PTR_BITS{1'b1}};

    wire [W_InstructionFifoIn-1:0]       fifo_in;
    wire [W_InstructionFifoReadData-1:0] unused_fifo_read_data;

    assign {
        fifo_in,
        unused_fifo_read_data
    } = pi;

    // 第一阶段：拆输入。reset/refetch 是同步控制，aresetn 是硬复位。
    wire [W_InstructionFifoLowData-1:0] write_payload_low =
        fifo_in[W_InstructionFifoLowData-1:0];
    wire read_enable = fifo_in[W_InstructionFifoLowData];
    wire [W_InstructionHighData-1:0] write_payload_high =
        fifo_in[W_InstructionFifoLowData + W_InstructionHighData:
                W_InstructionFifoLowData + 1];
    wire write_enable =
        fifo_in[W_InstructionFifoLowData + 1 + W_InstructionHighData];
    wire refetch =
        fifo_in[W_InstructionFifoLowData + 2 + W_InstructionHighData];
    wire reset =
        fifo_in[W_InstructionFifoLowData + 3 + W_InstructionHighData];

    wire [W_InstructionPayload-1:0] write_payload = {
        write_payload_high,
        write_payload_low
    };

    reg [W_InstructionPayload-1:0]       fifo_mem [0:INSTRUCTION_FIFO_SIZE-1];
    reg [PTR_BITS-1:0]                   fifo_head;
    reg [PTR_BITS-1:0]                   fifo_tail;
    reg [INSTRUCTION_FIFO_SIZE_BITS-1:0] fifo_count;

    wire rd_valid = (fifo_count != {INSTRUCTION_FIFO_SIZE_BITS{1'b0}});
    wire [W_InstructionPayload-1:0] rd_payload = fifo_mem[fifo_head];

    reg do_write;
    reg do_read;
    reg pop_existing;
    reg store_write;
    reg [PTR_BITS-1:0] fifo_head_next;
    reg [PTR_BITS-1:0] fifo_tail_next;
    reg [INSTRUCTION_FIFO_SIZE_BITS-1:0] fifo_count_next;
    reg next_full;
    reg next_empty;
    reg [W_InstructionPayload-1:0] output_payload;
    reg [W_InstructionFifoOut-1:0] out_regs;

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
        store_write = 1'b0;
        if (do_write) begin
            if (fifo_count < INSTRUCTION_FIFO_SIZE) begin
                store_write = 1'b1;
            end else if (pop_existing) begin
                store_write = 1'b1;
            end
        end
    end

    // 第三阶段：组合计算下一拍指针和计数。
    always @(*) begin
        fifo_head_next = fifo_head;
        if (reset) begin
            fifo_head_next = {PTR_BITS{1'b0}};
        end else if (refetch) begin
            fifo_head_next = {PTR_BITS{1'b0}};
        end else if (pop_existing) begin
            if (fifo_head == INSTRUCTION_FIFO_LAST_PTR) begin
                fifo_head_next = {PTR_BITS{1'b0}};
            end else begin
                fifo_head_next = fifo_head + 1'b1;
            end
        end
    end

    always @(*) begin
        fifo_tail_next = fifo_tail;
        if (reset) begin
            fifo_tail_next = {PTR_BITS{1'b0}};
        end else if (refetch) begin
            fifo_tail_next = {PTR_BITS{1'b0}};
        end else if (store_write) begin
            if (fifo_tail == INSTRUCTION_FIFO_LAST_PTR) begin
                fifo_tail_next = {PTR_BITS{1'b0}};
            end else begin
                fifo_tail_next = fifo_tail + 1'b1;
            end
        end
    end

    always @(*) begin
        fifo_count_next = fifo_count;
        if (reset) begin
            fifo_count_next = {INSTRUCTION_FIFO_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            fifo_count_next = {INSTRUCTION_FIFO_SIZE_BITS{1'b0}};
        end else begin
            if (store_write) begin
                if (!pop_existing) begin
                    fifo_count_next = fifo_count + 1'b1;
                end
            end else if (pop_existing) begin
                fifo_count_next = fifo_count - 1'b1;
            end
        end
    end

    // 第四阶段：组合生成 FIFO 输出。
    always @(*) begin
        next_full = 1'b0;
        if (fifo_count_next >= INSTRUCTION_FIFO_SIZE) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (fifo_count_next == {INSTRUCTION_FIFO_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    always @(*) begin
        output_payload = {W_InstructionPayload{1'b0}};
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
            next_full,
            next_empty,
            do_read,
            output_payload
        };
    end

    assign po = {
        {W_InstructionCtrlOut{1'b0}},
        out_regs
    };

    // 下面几个时序块里，三个分支对本寄存器都写 0，但信号语义不同：
    // aresetn 是异步硬复位；reset 是前端同步清空；refetch 是重取路径同步冲刷。
    // 优先级按代码顺序处理。
    // 第五阶段：时序更新 head。
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            fifo_head <= {PTR_BITS{1'b0}};
        end else if (reset) begin
            // reset：同步清空。
            fifo_head <= {PTR_BITS{1'b0}};
        end else if (refetch) begin
            // refetch：重取后同步清空。
            fifo_head <= {PTR_BITS{1'b0}};
        end else begin
            fifo_head <= fifo_head_next;
        end
    end

    // 第六阶段：时序更新 tail。
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            fifo_tail <= {PTR_BITS{1'b0}};
        end else if (reset) begin
            fifo_tail <= {PTR_BITS{1'b0}};
        end else if (refetch) begin
            fifo_tail <= {PTR_BITS{1'b0}};
        end else begin
            fifo_tail <= fifo_tail_next;
        end
    end

    // 第七阶段：时序更新 count。
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            fifo_count <= {INSTRUCTION_FIFO_SIZE_BITS{1'b0}};
        end else if (reset) begin
            fifo_count <= {INSTRUCTION_FIFO_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            fifo_count <= {INSTRUCTION_FIFO_SIZE_BITS{1'b0}};
        end else begin
            fifo_count <= fifo_count_next;
        end
    end

    // 第八阶段：时序写数据。清空只让队列不可见，不依赖清整块 mem。
    always @(posedge aclk) begin
        if (reset) begin
            // reset 清空后不写 mem。
        end else if (refetch) begin
            // refetch 清空后不写 mem。
        end else if (store_write) begin
            fifo_mem[fifo_tail] <= write_payload;
        end
    end

endmodule
