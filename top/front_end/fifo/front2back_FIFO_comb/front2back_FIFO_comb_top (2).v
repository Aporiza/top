// 前端正式 comb 边界: front2back_FIFO_comb.
// 源码依据: simulator-front/front-end/fifo/front2back_FIFO.cpp.
// 作用: 根据上一拍 front2back FIFO 队首快照和本拍输入，生成 clear/push/pop 请求和本拍可见输出。
//
// 文件结构:
// 1. front2back_FIFO_comb_top 是连接层，只做变量级端口和 BSD pi/po 的拼接。
// 2. front2back_FIFO_comb_bsd_top 是组合层，只接收 pi/po，不接 clk/rst。
// 3. FIFO 真正的时序寄存器/存储状态不放在 comb_top 内，后续应在外层统一时序区维护。
// -----------------------------------------------------------------------------
// 端口自查
// 模块: front2back_FIFO_comb
// 来源: train_IO.h / fifo/front2back_FIFO.cpp
// 配置: simulator-front 默认 large 配置
// 接口: Front2BackCombIn(10796 bit) -> Front2BackCombOut(10790 bit)
//
// 输入 Front2BackCombIn = 10796 bit
//   = inp 5396 bit
//   + rd  5400 bit
//   = 合计 10796 bit
//
// 输出 Front2BackCombOut = 10790 bit
//   = out_regs    5395 bit
//   + clear_fifo     1 bit
//   + push_en        1 bit
//   + push_entry  5392 bit
//   + pop_en         1 bit
//   = 合计       10790 bit
// -----------------------------------------------------------------------------

module front2back_FIFO_comb_top #(
    parameter W_Front2BackFifoIn        = 5396,   // front2back_FIFO_in
    parameter W_Front2BackFifoOut       = 5395,   // front2back_FIFO_out
    parameter W_Front2BackCombIn        = 10796,  // Front2BackCombIn
    parameter W_Front2BackCombOut       = 10790,  // Front2BackCombOut
    parameter FRONT2BACK_FIFO_SIZE_BITS = 7,      // clog2(FRONT2BACK_FIFO_SIZE + 1)
    parameter W_Front2BackFifoReadData =
        FRONT2BACK_FIFO_SIZE_BITS + 1 + (W_Front2BackFifoOut - 3)
) (
    input  wire [W_Front2BackFifoIn-1:0]       front2back_fifo_in,
    input  wire [W_Front2BackFifoReadData-1:0] front2back_fifo_rd,
    output wire [W_Front2BackCombOut-1:0]      front2back_fifo_req
);

    localparam W_Front2BackPayload = W_Front2BackFifoOut - 3;

    // 连接层: 用语义变量拼接 pi，保持传给 bsd_top 的接口只有 pi/po。
    wire [W_Front2BackCombIn-1:0]  pi;
    wire [W_Front2BackCombOut-1:0] po;

    assign pi = {
        front2back_fifo_in,
        front2back_fifo_rd
    };

    assign front2back_fifo_req = po;

    front2back_FIFO_comb_bsd_top #(
        .W_Front2BackCombIn(W_Front2BackCombIn),
        .W_Front2BackCombOut(W_Front2BackCombOut)
    ) u_front2back_FIFO_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module front2back_FIFO_comb_bsd_top #(
    parameter W_Front2BackCombIn  = 10796,
    parameter W_Front2BackCombOut = 10790
) (
    input  wire [W_Front2BackCombIn-1:0]  pi,
    output wire [W_Front2BackCombOut-1:0] po
);

    localparam W_Front2BackFifoIn        = 5396;
    localparam W_Front2BackFifoOut       = 5395;
    localparam W_Front2BackPayload       = 5392;
    localparam FRONT2BACK_FIFO_SIZE      = 64;
    localparam FRONT2BACK_FIFO_SIZE_BITS = 7;
    localparam W_Front2BackReadData =
        FRONT2BACK_FIFO_SIZE_BITS + 1 + W_Front2BackPayload;

    wire [W_Front2BackFifoIn-1:0]   fifo_in;
    wire [W_Front2BackReadData-1:0] fifo_read_data;

    assign {
        fifo_in,
        fifo_read_data
    } = pi;

    // 第一阶段: 拆输入。reset/refetch 是同步清空请求，不是顶层异步复位。
    wire reset = fifo_in[W_Front2BackPayload + 3];
    wire refetch = fifo_in[W_Front2BackPayload + 2];
    wire write_enable = fifo_in[W_Front2BackPayload + 1];
    wire read_enable = fifo_in[W_Front2BackPayload];
    wire [W_Front2BackPayload-1:0] write_payload =
        fifo_in[W_Front2BackPayload-1:0];

    wire [FRONT2BACK_FIFO_SIZE_BITS-1:0] read_size =
        fifo_read_data[W_Front2BackPayload + FRONT2BACK_FIFO_SIZE_BITS:
                       W_Front2BackPayload + 1];
    wire read_valid = fifo_read_data[W_Front2BackPayload];
    wire [W_Front2BackPayload-1:0] read_payload =
        fifo_read_data[W_Front2BackPayload-1:0];

    reg clear_fifo;
    reg push_en;
    reg pop_en;
    reg read_out_valid;
    reg [FRONT2BACK_FIFO_SIZE_BITS-1:0] next_size;
    reg next_full;
    reg next_empty;
    reg [W_Front2BackPayload-1:0] output_payload;
    reg [W_Front2BackFifoOut-1:0] out_regs;

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
        if (!clear_fifo) begin
            push_en = write_enable;
        end
    end

    always @(*) begin
        pop_en = 1'b0;
        if (!clear_fifo) begin
            if (read_enable) begin
                if (read_valid) begin
                    pop_en = 1'b1;
                end else if (write_enable) begin
                    pop_en = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        read_out_valid = 1'b0;
        if (!clear_fifo) begin
            if (read_enable) begin
                if (read_valid) begin
                    read_out_valid = 1'b1;
                end else if (write_enable) begin
                    read_out_valid = 1'b1;
                end
            end
        end
    end

    // 第三阶段: 组合估算下一拍 full/empty。真实 count 后续由外层时序区统一维护。
    always @(*) begin
        next_size = read_size;
        if (clear_fifo) begin
            next_size = {FRONT2BACK_FIFO_SIZE_BITS{1'b0}};
        end else if (push_en && !pop_en) begin
            next_size = read_size + 1'b1;
        end else if (!push_en && pop_en) begin
            next_size = read_size - 1'b1;
        end
    end

    always @(*) begin
        next_full = 1'b0;
        if (next_size >= FRONT2BACK_FIFO_SIZE) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (next_size == {FRONT2BACK_FIFO_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    // 第四阶段: 生成本拍可见输出。空队列同拍写读时走 bypass。
    always @(*) begin
        output_payload = {W_Front2BackPayload{1'b0}};
        if (read_out_valid) begin
            if (read_valid) begin
                output_payload = read_payload;
            end else begin
                output_payload = write_payload;
            end
        end
    end

    always @(*) begin
        out_regs = {
            next_full,
            next_empty,
            read_out_valid,
            output_payload
        };
    end

    assign po = {
        clear_fifo,
        push_en,
        write_payload,
        pop_en,
        out_regs
    };

endmodule
