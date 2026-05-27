// 前端正式 comb 边界： fetch_address_FIFO_comb.
// 源码依据： simulator-front/front-end/fifo/fetch_address_FIFO.cpp.
// 作用：生成取址地址 FIFO 请求，并更新 FIFO 状态。
//
// 文件结构：
// 1. fetch_address_FIFO_comb_top 是连接层，接收 front_top 的变量端口和上一拍队首快照。
// 2. fetch_address_FIFO_comb_bsd_top 在本文件内直接实现 FIFO，不再等待外部 BSD 代码。
// 3. 组合逻辑先计算本拍 read/write、旁路输出和下一拍 head/tail/count。
// 4. 时序逻辑在周期末更新 mem/head/tail/count；aresetn 是异步硬复位，reset/refetch 是同步清空。

// -----------------------------------------------------------------------------
// 端口自查
// 模块：fetch_address_FIFO_comb
// 来源：train_IO.h / fifo/fetch_address_FIFO.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FetchAddrCombIn(75 bit) -> FetchAddrCombOut(70 bit)
//
// 输入 FetchAddrCombIn = 75 bit
//   = inp 36 bit
//   + rd  39 bit
//   = 合计  75 bit
//
// 输出 FetchAddrCombOut = 70 bit
//   = out_regs   35 bit
//   + clear_fifo  1 bit
//   + push_en     1 bit
//   + push_data  32 bit
//   + pop_en      1 bit
//   = 合计         70 bit
//
// 关键结构展开：
//   inp      : fetch_address_FIFO_in        36 bit
//   rd       : fetch_address_FIFO_read_data 39 bit
//   out_regs : fetch_address_FIFO_out       35 bit
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
// 自查确认：fetch_address_FIFO_comb Input Bits = 75, Output Bits = 70。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

module fetch_address_FIFO_comb_top #(
    parameter W_FetchAddressFifoIn       = 36,  // 实际：reset/refetch/read/write + fetch_addr_t(32)
    parameter W_FetchAddressFifoOut      = 35,  // 实际：full/empty/read_valid + fetch_addr_t(32)
    parameter W_FetchAddrCombOut         = 70,  // 实际：FetchAddrCombOut
    parameter FETCH_ADDR_FIFO_SIZE       = 32,  // 实际：frontend_feature_config.h
    parameter FETCH_ADDR_FIFO_SIZE_BITS  = 6    // 实际：clog2(FETCH_ADDR_FIFO_SIZE + 1)
) (
    input  wire                             aclk,
    input  wire                             aresetn,
    input  wire [W_FetchAddressFifoIn-1:0]  fetch_addr_fifo_in,
    input  wire [W_FetchAddressFifoOut-1:0] fetch_addr_fifo_rd,
    output wire [W_FetchAddrCombOut-1:0]    fetch_addr_fifo_req
);

    localparam W_FetchAddressPayload = W_FetchAddressFifoOut - 3;
    localparam W_FetchAddressFifoReadData =
        FETCH_ADDR_FIFO_SIZE_BITS + 1 + W_FetchAddressPayload;
    localparam W_FetchAddressFifoCombIn =
        W_FetchAddressFifoIn + W_FetchAddressFifoReadData;
    localparam W_FetchAddressFifoCombOut = W_FetchAddrCombOut;

    wire [W_FetchAddressFifoReadData-1:0] fetch_addr_fifo_read_data_view;
    wire                                  fetch_addr_fifo_head_valid_view;

    assign fetch_addr_fifo_head_valid_view = ~fetch_addr_fifo_rd[W_FetchAddressPayload + 1];
    assign fetch_addr_fifo_read_data_view = {
        {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}},
        fetch_addr_fifo_head_valid_view,
        fetch_addr_fifo_rd[W_FetchAddressPayload-1:0]
    };

    // 连接层把语义化输入和队首快照打包成 BSD pi。
    // read_data_view 对应 simulator-front 中 seq_read 看到的队首信息。
    wire [W_FetchAddressFifoCombIn-1:0]  pi;
    wire [W_FetchAddressFifoCombOut-1:0] po;

    assign pi = {
        fetch_addr_fifo_in,
        fetch_addr_fifo_read_data_view
    };

    assign fetch_addr_fifo_req = po;

    fetch_address_FIFO_comb_bsd_top #(
        .W_FetchAddressFifoIn(W_FetchAddressFifoIn),
        .W_FetchAddressFifoOut(W_FetchAddressFifoOut),
        .FETCH_ADDR_FIFO_SIZE(FETCH_ADDR_FIFO_SIZE),
        .FETCH_ADDR_FIFO_SIZE_BITS(FETCH_ADDR_FIFO_SIZE_BITS)
    ) u_fetch_address_FIFO_comb_bsd_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .pi(pi),
        .po(po)
    );

endmodule

// BSD 层：这里已经是可综合 FIFO RTL。
// 后续若调整 FIFO 行为，应优先对照 simulator-front 的 push/pop/clear 请求模型修改本层。
module fetch_address_FIFO_comb_bsd_top #(
    parameter W_FetchAddressFifoIn       = 36,  // 实际：reset/refetch/read/write + fetch_addr_t(32)
    parameter W_FetchAddressFifoOut      = 35,  // 实际：full/empty/read_valid + fetch_addr_t(32)
    parameter FETCH_ADDR_FIFO_SIZE       = 32,  // 实际：frontend_feature_config.h
    parameter FETCH_ADDR_FIFO_SIZE_BITS  = 6    // 实际：clog2(FETCH_ADDR_FIFO_SIZE + 1)
) (
    input  wire                                    aclk,
    input  wire                                    aresetn,
    input  wire [W_FetchAddressFifoIn + FETCH_ADDR_FIFO_SIZE_BITS + 1 + (W_FetchAddressFifoOut - 3) - 1:0] pi,
    output wire [(2 * W_FetchAddressFifoOut) - 1:0] po
);

    localparam W_FetchAddressPayload = W_FetchAddressFifoOut - 3;
    localparam W_FetchAddressFifoReadData =
        FETCH_ADDR_FIFO_SIZE_BITS + 1 + W_FetchAddressPayload;
    localparam W_FetchAddressFifoCombOut = 2 * W_FetchAddressFifoOut;
    localparam W_FetchAddressCtrlOut = W_FetchAddressFifoCombOut - W_FetchAddressFifoOut;
    localparam PTR_BITS = 5;  // FETCH_ADDR_FIFO_SIZE=32

    wire [W_FetchAddressFifoIn-1:0]       fifo_in;
    wire [W_FetchAddressFifoReadData-1:0] unused_fifo_read_data;

    assign {
        fifo_in,
        unused_fifo_read_data
    } = pi;

    // 第一阶段：拆输入。aresetn 是硬复位；reset/refetch 是前端同步控制信号。
    wire reset        = fifo_in[W_FetchAddressPayload + 3];
    wire refetch      = fifo_in[W_FetchAddressPayload + 2];
    wire read_enable  = fifo_in[W_FetchAddressPayload + 1];
    wire write_enable = fifo_in[W_FetchAddressPayload];
    wire [W_FetchAddressPayload-1:0] write_fetch_address =
        fifo_in[W_FetchAddressPayload-1:0];

    reg [W_FetchAddressPayload-1:0]       fifo_mem [0:FETCH_ADDR_FIFO_SIZE-1];
    reg [PTR_BITS-1:0]                    fifo_head;
    reg [PTR_BITS-1:0]                    fifo_tail;
    reg [FETCH_ADDR_FIFO_SIZE_BITS-1:0]   fifo_count;

    wire rd_valid = (fifo_count != {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}});
    wire [W_FetchAddressPayload-1:0] rd_fetch_address = fifo_mem[fifo_head];

    reg do_write;
    reg do_read;
    reg pop_existing;
    reg store_write;
    reg [PTR_BITS-1:0] fifo_head_next;
    reg [PTR_BITS-1:0] fifo_tail_next;
    reg [FETCH_ADDR_FIFO_SIZE_BITS-1:0] fifo_count_next;
    reg next_full;
    reg next_empty;
    reg [W_FetchAddressPayload-1:0] output_fetch_address;
    reg [W_FetchAddressFifoOut-1:0] out_regs;

    // 第二阶段：组合判断本拍是否读写。reset 和 refetch 分支分开处理。
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
            if (fifo_count < FETCH_ADDR_FIFO_SIZE) begin
                store_write = 1'b1;
            end else if (pop_existing) begin
                store_write = 1'b1;
            end
        end
    end

    // 第三阶段：组合计算 head/tail/count 的下一拍值。
    always @(*) begin
        fifo_head_next = fifo_head;
        if (reset) begin
            fifo_head_next = {PTR_BITS{1'b0}};
        end else if (refetch) begin
            fifo_head_next = {PTR_BITS{1'b0}};
        end else if (pop_existing) begin
            if (fifo_head == (FETCH_ADDR_FIFO_SIZE - 1)) begin
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
            if (fifo_tail == (FETCH_ADDR_FIFO_SIZE - 1)) begin
                fifo_tail_next = {PTR_BITS{1'b0}};
            end else begin
                fifo_tail_next = fifo_tail + 1'b1;
            end
        end
    end

    always @(*) begin
        fifo_count_next = fifo_count;
        if (reset) begin
            fifo_count_next = {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            fifo_count_next = {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}};
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

    // 第四阶段：组合生成本拍输出。
    always @(*) begin
        next_full = 1'b0;
        if (fifo_count_next >= (FETCH_ADDR_FIFO_SIZE - 1)) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (fifo_count_next == {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    always @(*) begin
        output_fetch_address = {W_FetchAddressPayload{1'b0}};
        if (do_read) begin
            if (rd_valid) begin
                output_fetch_address = rd_fetch_address;
            end else begin
                output_fetch_address = write_fetch_address;
            end
        end else if (rd_valid) begin
            output_fetch_address = rd_fetch_address;
        end
    end

    always @(*) begin
        out_regs = {
            next_full,
            next_empty,
            do_read,
            output_fetch_address
        };
    end

    assign po = {
        {W_FetchAddressCtrlOut{1'b0}},
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
            // reset：前端同步清空。
            fifo_head <= {PTR_BITS{1'b0}};
        end else if (refetch) begin
            // refetch：重取指导致的同步清空。
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
            fifo_count <= {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}};
        end else if (reset) begin
            fifo_count <= {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}};
        end else if (refetch) begin
            fifo_count <= {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}};
        end else begin
            fifo_count <= fifo_count_next;
        end
    end

    // 第八阶段：时序写数据。清空只清指针和计数，旧 mem 数据不再可见。
    always @(posedge aclk) begin
        if (reset) begin
            // reset 清空后不写 mem。
        end else if (refetch) begin
            // refetch 清空后不写 mem。
        end else if (store_write) begin
            fifo_mem[fifo_tail] <= write_fetch_address;
        end
    end

endmodule
