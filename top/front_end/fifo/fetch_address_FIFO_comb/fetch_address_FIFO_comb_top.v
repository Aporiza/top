// 前端正式 comb 边界: fetch_address_FIFO_comb.
// 源码依据: simulator-front/front-end/fifo/fetch_address_FIFO.cpp.
// 作用: 根据上一拍 FIFO 队首快照和本拍输入，生成 clear/push/pop 请求和本拍可见输出。
//
// 文件结构:
// 1. fetch_address_FIFO_comb_top 是连接层，只做变量级端口和 BSD pi/po 的拼接。
// 2. fetch_address_FIFO_comb_bsd_top 是组合层，只接收 pi/po，不接 clk/rst。
// 3. FIFO 真正的时序寄存器/存储状态不放在 comb_top 内，后续应在外层统一时序区维护。
// -----------------------------------------------------------------------------
// 端口自查
// 模块: fetch_address_FIFO_comb
// 来源: train_IO.h / fifo/fetch_address_FIFO.cpp
// 配置: simulator-front 默认 large 配置
// 接口: FetchAddrCombIn(75 bit) -> FetchAddrCombOut(70 bit)
//
// 输入 FetchAddrCombIn = 75 bit
//   = inp 36 bit
//   + rd  39 bit
//   = 合计 75 bit
//
// 输出 FetchAddrCombOut = 70 bit
//   = out_regs   35 bit
//   + clear_fifo  1 bit
//   + push_en     1 bit
//   + push_data  32 bit
//   + pop_en      1 bit
//   = 合计        70 bit
// -----------------------------------------------------------------------------

module fetch_address_FIFO_comb_top #(
    parameter W_FetchAddressFifoIn      = 36,  // reset/refetch/read/write + fetch_addr_t(32)
    parameter W_FetchAddressFifoOut     = 35,  // full/empty/read_valid + fetch_addr_t(32)
    parameter W_FetchAddrCombIn         = 75,  // FetchAddrCombIn
    parameter W_FetchAddrCombOut        = 70,  // FetchAddrCombOut
    parameter FETCH_ADDR_FIFO_SIZE_BITS = 6,   // clog2(FETCH_ADDR_FIFO_SIZE + 1)
    parameter W_FetchAddressFifoReadData =
        FETCH_ADDR_FIFO_SIZE_BITS + 1 + (W_FetchAddressFifoOut - 3)
) (
    input  wire [W_FetchAddressFifoIn-1:0]       fetch_addr_fifo_in,
    input  wire [W_FetchAddressFifoReadData-1:0] fetch_addr_fifo_rd,
    output wire [W_FetchAddrCombOut-1:0]         fetch_addr_fifo_req
);

    localparam W_FetchAddressPayload = W_FetchAddressFifoOut - 3;

    // 连接层: 用语义变量拼接 pi，保持传给 bsd_top 的接口只有 pi/po。
    wire [W_FetchAddrCombIn-1:0]  pi;
    wire [W_FetchAddrCombOut-1:0] po;

    assign pi = {
        fetch_addr_fifo_in,
        fetch_addr_fifo_rd
    };

    assign fetch_addr_fifo_req = po;

    fetch_address_FIFO_comb_bsd_top #(
        .W_FetchAddrCombIn(W_FetchAddrCombIn),
        .W_FetchAddrCombOut(W_FetchAddrCombOut)
    ) u_fetch_address_FIFO_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module fetch_address_FIFO_comb_bsd_top #(
    parameter W_FetchAddrCombIn  = 75,
    parameter W_FetchAddrCombOut = 70
) (
    input  wire [W_FetchAddrCombIn-1:0]  pi,
    output wire [W_FetchAddrCombOut-1:0] po
);

    localparam W_FetchAddressFifoIn      = 36;
    localparam W_FetchAddressFifoOut     = 35;
    localparam W_FetchAddressPayload     = 32;
    localparam FETCH_ADDR_FIFO_SIZE      = 32;
    localparam FETCH_ADDR_FIFO_SIZE_BITS = 6;
    localparam W_FetchAddressReadData =
        FETCH_ADDR_FIFO_SIZE_BITS + 1 + W_FetchAddressPayload;

    wire [W_FetchAddressFifoIn-1:0]   fifo_in;
    wire [W_FetchAddressReadData-1:0] fifo_read_data;

    assign {
        fifo_in,
        fifo_read_data
    } = pi;

    // 第一阶段: 拆输入。reset/refetch 是同步清空请求，不是顶层异步复位。
    wire reset = fifo_in[W_FetchAddressPayload + 3];
    wire refetch = fifo_in[W_FetchAddressPayload + 2];
    wire read_enable = fifo_in[W_FetchAddressPayload + 1];
    wire write_enable = fifo_in[W_FetchAddressPayload];
    wire [W_FetchAddressPayload-1:0] write_fetch_address =
        fifo_in[W_FetchAddressPayload-1:0];

    wire [FETCH_ADDR_FIFO_SIZE_BITS-1:0] read_size =
        fifo_read_data[W_FetchAddressPayload + FETCH_ADDR_FIFO_SIZE_BITS:
                       W_FetchAddressPayload + 1];
    wire read_valid = fifo_read_data[W_FetchAddressPayload];
    wire [W_FetchAddressPayload-1:0] read_fetch_address =
        fifo_read_data[W_FetchAddressPayload-1:0];

    reg clear_fifo;
    reg push_en;
    reg pop_en;
    reg read_out_valid;
    reg [FETCH_ADDR_FIFO_SIZE_BITS-1:0] queue_size_before;
    reg [FETCH_ADDR_FIFO_SIZE_BITS-1:0] next_size;
    reg next_full;
    reg next_empty;
    reg [W_FetchAddressPayload-1:0] output_fetch_address;
    reg [W_FetchAddressFifoOut-1:0] out_regs;

    // 第二阶段: 按本拍输入和上一拍队首快照生成 FIFO 请求。
    always @(*) begin
        clear_fifo = 1'b0;
        if (reset) begin
            clear_fifo = 1'b1;
        end else if (refetch) begin
            clear_fifo = 1'b1;
        end
    end

    always @(*) begin
        push_en = 1'b0;
        // reset 直接清空并结束；refetch 只清掉旧队列，本拍 BPU 新地址仍然允许写入。
        if (!reset) begin
            push_en = write_enable;
        end
    end

    always @(*) begin
        pop_en = 1'b0;
        if (!reset) begin
            if (read_enable) begin
                if (!refetch && read_valid) begin
                    pop_en = 1'b1;
                end else if (write_enable) begin
                    pop_en = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        read_out_valid = 1'b0;
        if (!reset) begin
            if (read_enable) begin
                if (!refetch && read_valid) begin
                    read_out_valid = 1'b1;
                end else if (write_enable) begin
                    read_out_valid = 1'b1;
                end
            end
        end
    end

    // 第三阶段: 组合估算下一拍 full/empty。真实 count 后续由外层时序区统一维护。
    always @(*) begin
        queue_size_before = read_size;
        if (refetch) begin
            queue_size_before = {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}};
        end
    end

    always @(*) begin
        next_size = queue_size_before;
        if (reset) begin
            next_size = {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}};
        end else begin
            if (push_en) begin
                next_size = next_size + 1'b1;
            end
            if (pop_en && (next_size != {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}})) begin
                next_size = next_size - 1'b1;
            end
        end
    end

    always @(*) begin
        next_full = 1'b0;
        // 对齐 simulator-front/fifo/fetch_address_FIFO.cpp:
        // out.out_regs.full = (next_size >= (FETCH_ADDR_FIFO_SIZE - 1));
        // fetch address FIFO 提前一格报满，避免 BPU 下一拍继续发请求撞满队列。
        if (next_size >= (FETCH_ADDR_FIFO_SIZE - 1)) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (next_size == {FETCH_ADDR_FIFO_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    // 第四阶段: 生成本拍可见输出。空队列同拍写读时走 bypass。
    always @(*) begin
        output_fetch_address = {W_FetchAddressPayload{1'b0}};
        if (read_out_valid) begin
            if (!refetch && read_valid) begin
                output_fetch_address = read_fetch_address;
            end else begin
                output_fetch_address = write_fetch_address;
            end
        end
    end

    always @(*) begin
        out_regs = {
            next_full,
            next_empty,
            read_out_valid,
            output_fetch_address
        };
    end

    assign po = {
        clear_fifo,
        push_en,
        write_fetch_address,
        pop_en,
        out_regs
    };

endmodule
