// 前端正式 comb 边界: instruction_FIFO_comb.
// 源码依据: simulator-front/front-end/fifo/instruction_FIFO.cpp.
// 作用: 根据上一拍 instruction FIFO 队首快照和本拍输入，生成 clear/push/pop 请求和本拍可见输出。
//
// 文件结构:
// 1. instruction_FIFO_comb_top 是连接层，只做变量级端口和 BSD pi/po 的拼接。
// 2. instruction_FIFO_comb_bsd_top 是组合层，只接收 pi/po，不接 clk/rst。
// 3. FIFO 真正的时序寄存器/存储状态不放在 comb_top 内，后续应在外层统一时序区维护。
// -----------------------------------------------------------------------------
// 端口自查
// 模块: instruction_FIFO_comb
// 来源: train_IO.h / fifo/instruction_FIFO.cpp
// 配置: simulator-front 默认 large 配置
// 接口: InstructionCombIn(3275 bit) -> InstructionCombOut(3270 bit)
//
// 输入 InstructionCombIn = 3275 bit
//   = inp 1636 bit
//   + rd  1639 bit
//   = 合计 3275 bit
//
// 输出 InstructionCombOut = 3270 bit
//   = out_regs   1635 bit
//   + clear_fifo    1 bit
//   + push_en       1 bit
//   + push_entry 1632 bit
//   + pop_en        1 bit
//   = 合计       3270 bit
// -----------------------------------------------------------------------------

module instruction_FIFO_comb_top #(
    parameter W_InstructionFifoIn        = 1636,  // instruction_FIFO_in
    parameter W_InstructionFifoOut       = 1635,  // instruction_FIFO_out
    parameter W_InstructionCombIn        = 3275,  // InstructionCombIn
    parameter W_InstructionCombOut       = 3270,  // InstructionCombOut
    parameter INSTRUCTION_FIFO_SIZE_BITS = 6,     // clog2(INSTRUCTION_FIFO_SIZE + 1)
    parameter W_InstructionFifoReadData =
        INSTRUCTION_FIFO_SIZE_BITS + 1 + (W_InstructionFifoOut - 3)
) (
    input  wire [W_InstructionFifoIn-1:0]       instruction_fifo_in,
    input  wire [W_InstructionFifoReadData-1:0] fifo_rd,
    output wire [W_InstructionCombOut-1:0]      instruction_fifo_req
);

    localparam W_InstructionPayload = W_InstructionFifoOut - 3;

    // 连接层: 用语义变量拼接 pi，保持传给 bsd_top 的接口只有 pi/po。
    wire [W_InstructionCombIn-1:0]  pi;
    wire [W_InstructionCombOut-1:0] po;

    assign pi = {
        instruction_fifo_in,
        fifo_rd
    };

    assign instruction_fifo_req = po;

    instruction_FIFO_comb_bsd_top #(
        .W_InstructionCombIn(W_InstructionCombIn),
        .W_InstructionCombOut(W_InstructionCombOut)
    ) u_instruction_FIFO_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module instruction_FIFO_comb_bsd_top #(
    parameter W_InstructionCombIn  = 3275,
    parameter W_InstructionCombOut = 3270
) (
    input  wire [W_InstructionCombIn-1:0]  pi,
    output wire [W_InstructionCombOut-1:0] po
);

    localparam W_InstructionFifoIn        = 1636;
    localparam W_InstructionFifoOut       = 1635;
    localparam W_InstructionFifoLowData   = 576;
    localparam W_InstructionPayload       = 1632;
    localparam W_InstructionHighData      =
        W_InstructionPayload - W_InstructionFifoLowData;
    localparam INSTRUCTION_FIFO_SIZE      = 32;
    localparam INSTRUCTION_FIFO_SIZE_BITS = 6;
    localparam W_InstructionReadData =
        INSTRUCTION_FIFO_SIZE_BITS + 1 + W_InstructionPayload;

    wire [W_InstructionFifoIn-1:0]   fifo_in;
    wire [W_InstructionReadData-1:0] fifo_read_data;

    assign {
        fifo_in,
        fifo_read_data
    } = pi;

    // 第一阶段: 拆输入。reset/refetch 是同步清空请求，不是顶层异步复位。
    wire [W_InstructionFifoLowData-1:0] write_payload_low =
        fifo_in[W_InstructionFifoLowData-1:0];
    wire read_enable = fifo_in[W_InstructionFifoLowData];
    wire [W_InstructionHighData-1:0] write_payload_high =
        fifo_in[W_InstructionFifoLowData + W_InstructionHighData:
                W_InstructionFifoLowData + 1];
    wire write_enable =
        fifo_in[W_InstructionFifoLowData + W_InstructionHighData + 1];
    wire refetch =
        fifo_in[W_InstructionFifoLowData + W_InstructionHighData + 2];
    wire reset =
        fifo_in[W_InstructionFifoLowData + W_InstructionHighData + 3];
    wire [W_InstructionPayload-1:0] write_payload = {
        write_payload_high,
        write_payload_low
    };

    wire [INSTRUCTION_FIFO_SIZE_BITS-1:0] read_size =
        fifo_read_data[W_InstructionPayload + INSTRUCTION_FIFO_SIZE_BITS:
                       W_InstructionPayload + 1];
    wire read_valid = fifo_read_data[W_InstructionPayload];
    wire [W_InstructionPayload-1:0] read_payload =
        fifo_read_data[W_InstructionPayload-1:0];

    reg clear_fifo;
    reg push_en;
    reg pop_en;
    reg read_out_valid;
    reg [INSTRUCTION_FIFO_SIZE_BITS-1:0] next_size;
    reg next_full;
    reg next_empty;
    reg [W_InstructionPayload-1:0] output_payload;
    reg [W_InstructionFifoOut-1:0] out_regs;

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
            next_size = {INSTRUCTION_FIFO_SIZE_BITS{1'b0}};
        end else if (push_en && !pop_en) begin
            next_size = read_size + 1'b1;
        end else if (!push_en && pop_en) begin
            next_size = read_size - 1'b1;
        end
    end

    always @(*) begin
        next_full = 1'b0;
        if (next_size >= INSTRUCTION_FIFO_SIZE) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (next_size == {INSTRUCTION_FIFO_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    // 第四阶段: 生成本拍可见输出。空队列同拍写读时走 bypass。
    always @(*) begin
        output_payload = {W_InstructionPayload{1'b0}};
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
