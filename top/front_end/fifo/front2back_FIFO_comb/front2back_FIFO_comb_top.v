// 前端正式 comb 边界： front2back_FIFO_comb.
// 源码依据： simulator-front/front-end/fifo/front2bank_FIFO.cpp.
// 作用：生成 front2back FIFO 请求，并更新 FIFO 状态。
//
// 位宽来源：
// front2back_FIFO_entry 按 front_IO.h/front_module.h 里的字段逐项展开。
// 默认配置：FETCH_WIDTH=16、TN_MAX=4、TAGE_IDX_WIDTH=12、TAGE_TAG_WIDTH=8、
// BPU_SCL_META_NTABLE=8、BPU_SCL_META_IDX_BITS=16、
// BPU_LOOP_META_IDX_BITS=16、BPU_LOOP_META_TAG_BITS=16。
// entry = 5392。
// front2back_FIFO_in  = reset/refetch/write/read 四个控制位 + entry = 5396。
// front2back_FIFO_out = full/empty/valid 三个状态位 + entry = 5395。
// front2back_FIFO_read_data = size(7) + head_valid(1) + entry = 5400。
// Front2BackCombIn = front2back_FIFO_in + front2back_FIFO_read_data = 10796。
// Front2BackCombOut = out_regs + clear + push_en + push_entry + pop_en = 10790。
//
// 文件结构：
// 1. front2back_FIFO_comb_top 是连接层，接收 front_top 的变量端口和上一拍队首快照。
// 2. front2back_FIFO_comb_bsd_top 在本文件内直接实现 FIFO，不再等待外部 BSD 代码。
// 3. 组合逻辑先计算本拍 read/write、旁路输出和下一拍 head/tail/count。
// 4. 时序逻辑在周期末更新 mem/head/tail/count；aresetn 是异步硬复位，reset/refetch 是同步清空。

module front2back_FIFO_comb_top #(
    parameter W_Front2BackFifoIn       = 5396,   // 实际： front2back_FIFO_in
    parameter W_Front2BackFifoOut      = 5395,   // 实际： front2back_FIFO_out
    parameter W_Front2BackCombOut      = 10790,  // 实际： Front2BackCombOut
    parameter FRONT2BACK_FIFO_SIZE     = 64,     // 实际： frontend_feature_config.h
    parameter FRONT2BACK_FIFO_SIZE_BITS = 7,     // 实际： clog2(FRONT2BACK_FIFO_SIZE + 1)
    parameter W_Front2BackFifoEntry    = W_Front2BackFifoOut - 3,
    parameter W_Front2BackFifoReadData = FRONT2BACK_FIFO_SIZE_BITS + 1 + W_Front2BackFifoEntry,
    parameter W_Front2backFifoCombIn   = W_Front2BackFifoIn + W_Front2BackFifoReadData,  // 实际： 10796
    parameter W_Front2backFifoCombOut  = W_Front2BackCombOut    // 实际： 10790
) (
    input  wire                           aclk,
    input  wire                           aresetn,
    input  wire [W_Front2BackFifoIn-1:0]  front2back_fifo_in,
    input  wire [W_Front2BackFifoOut-1:0] front2back_fifo_rd,
    output wire [W_Front2BackCombOut-1:0] front2back_fifo_req
);

    localparam W_Front2BackPayload = W_Front2BackFifoOut - 3;

    wire [W_Front2BackFifoReadData-1:0] front2back_fifo_read_data_view;
    wire                                front2back_fifo_head_valid_view;

    assign front2back_fifo_head_valid_view = ~front2back_fifo_rd[W_Front2BackPayload + 1];
    assign front2back_fifo_read_data_view = {
        {FRONT2BACK_FIFO_SIZE_BITS{1'b0}},
        front2back_fifo_head_valid_view,
        front2back_fifo_rd[W_Front2BackPayload-1:0]
    };

    // 连接层把语义化输入和队首快照打包成 BSD pi。
    // read_data_view 对应 simulator-front 中 seq_read 看到的队首信息。
    wire [W_Front2backFifoCombIn-1:0]  pi;
    wire [W_Front2backFifoCombOut-1:0] po;

    assign pi = {
        front2back_fifo_in,
        front2back_fifo_read_data_view
    };

    assign front2back_fifo_req = po;

    front2back_FIFO_comb_bsd_top #(
        .W_Front2BackFifoIn(W_Front2BackFifoIn),
        .W_Front2BackFifoOut(W_Front2BackFifoOut),
        .FRONT2BACK_FIFO_SIZE(FRONT2BACK_FIFO_SIZE),
        .FRONT2BACK_FIFO_SIZE_BITS(FRONT2BACK_FIFO_SIZE_BITS),
        .W_Front2BackFifoEntry(W_Front2BackFifoEntry),
        .W_Front2BackFifoReadData(W_Front2BackFifoReadData),
        .W_Front2backFifoCombIn(W_Front2backFifoCombIn),
        .W_Front2backFifoCombOut(W_Front2backFifoCombOut)
    ) u_front2back_FIFO_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

// BSD 层：这里已经是可综合 FIFO RTL。
// 后续若调整 FIFO 行为，应优先对照 simulator-front 的 push/pop/clear 请求模型修改本层。
module front2back_FIFO_comb_bsd_top #(
    parameter W_Front2BackFifoIn       = 5396,   // 实际： front2back_FIFO_in
    parameter W_Front2BackFifoOut      = 5395,   // 实际： front2back_FIFO_out
    parameter FRONT2BACK_FIFO_SIZE     = 64,     // 实际： frontend_feature_config.h
    parameter FRONT2BACK_FIFO_SIZE_BITS = 7,     // 实际： clog2(FRONT2BACK_FIFO_SIZE + 1)
    parameter W_Front2BackFifoEntry    = W_Front2BackFifoOut - 3,
    parameter W_Front2BackFifoReadData = FRONT2BACK_FIFO_SIZE_BITS + 1 + W_Front2BackFifoEntry,
    parameter W_Front2backFifoCombIn   = 10796,  // 实际： Front2BackCombIn
    parameter W_Front2backFifoCombOut  = 10790   // 实际： Front2BackCombOut
) (
    input  wire                                   aclk,
    input  wire                                   aresetn,
    input  wire [W_Front2backFifoCombIn-1:0]      pi,
    output wire [W_Front2backFifoCombOut-1:0]     po
);

    localparam W_Front2BackPayload = W_Front2BackFifoOut - 3;
    localparam W_Front2BackCtrlOut = W_Front2backFifoCombOut - W_Front2BackFifoOut;
    localparam PTR_BITS = 6;  // FRONT2BACK_FIFO_SIZE=64

    wire [W_Front2BackFifoIn-1:0]       fifo_in;
    wire [W_Front2BackFifoReadData-1:0] unused_fifo_read_data;

    assign {
        fifo_in,
        unused_fifo_read_data
    } = pi;

    // 第一阶段：拆输入。reset/refetch 是同步控制，aresetn 是硬复位。
    wire [W_Front2BackPayload-1:0] write_payload =
        fifo_in[W_Front2BackPayload-1:0];
    wire read_enable = fifo_in[W_Front2BackPayload];
    wire write_enable = fifo_in[W_Front2BackPayload + 1];
    wire refetch = fifo_in[W_Front2BackPayload + 2];
    wire reset = fifo_in[W_Front2BackPayload + 3];

    reg [W_Front2BackPayload-1:0]       fifo_mem [0:FRONT2BACK_FIFO_SIZE-1];
    reg [PTR_BITS-1:0]                  fifo_head;
    reg [PTR_BITS-1:0]                  fifo_tail;
    reg [FRONT2BACK_FIFO_SIZE_BITS-1:0] fifo_count;

    wire rd_valid = (fifo_count != {FRONT2BACK_FIFO_SIZE_BITS{1'b0}});
    wire [W_Front2BackPayload-1:0] rd_payload = fifo_mem[fifo_head];

    reg do_write;
    reg do_read;
    reg pop_existing;
    reg store_write;
    reg [PTR_BITS-1:0] fifo_head_next;
    reg [PTR_BITS-1:0] fifo_tail_next;
    reg [FRONT2BACK_FIFO_SIZE_BITS-1:0] fifo_count_next;
    reg next_full;
    reg next_empty;
    reg [W_Front2BackPayload-1:0] output_payload;
    reg [W_Front2BackFifoOut-1:0] out_regs;

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
            if (fifo_count < FRONT2BACK_FIFO_SIZE) begin
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
            if (fifo_head == (FRONT2BACK_FIFO_SIZE - 1)) begin
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
            if (fifo_tail == (FRONT2BACK_FIFO_SIZE - 1)) begin
                fifo_tail_next = {PTR_BITS{1'b0}};
            end else begin
                fifo_tail_next = fifo_tail + 1'b1;
            end
        end
    end

    always @(*) begin
        fifo_count_next = fifo_count;
        if (reset) begin
            fifo_count_next = {FRONT2BACK_FIFO_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            fifo_count_next = {FRONT2BACK_FIFO_SIZE_BITS{1'b0}};
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
        if (fifo_count_next >= FRONT2BACK_FIFO_SIZE) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (fifo_count_next == {FRONT2BACK_FIFO_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    always @(*) begin
        output_payload = {W_Front2BackPayload{1'b0}};
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
        {W_Front2BackCtrlOut{1'b0}},
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
            fifo_head <= {PTR_BITS{1'b0}};
        end else if (refetch) begin
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
            fifo_count <= {FRONT2BACK_FIFO_SIZE_BITS{1'b0}};
        end else if (reset) begin
            fifo_count <= {FRONT2BACK_FIFO_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            fifo_count <= {FRONT2BACK_FIFO_SIZE_BITS{1'b0}};
        end else begin
            fifo_count <= fifo_count_next;
        end
    end

    // 第八阶段：时序写数据。清空只清指针和计数。
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
