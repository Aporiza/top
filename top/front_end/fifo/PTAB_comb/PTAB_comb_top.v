// 前端正式 comb 边界: PTAB_comb.
// 源码依据: simulator-front/front-end/fifo/PTAB.cpp.
// 作用: 根据上一拍 PTAB 队首快照和本拍输入，生成 clear/push/pop 请求和本拍可见输出。
//
// 文件结构:
// 1. PTAB_comb_top 是连接层，只做变量级端口和 BSD pi/po 的拼接。
// 2. PTAB_comb_bsd_top 是组合层，只接收 pi/po，不接 clk/rst。
// 3. PTAB 真正的时序寄存器/存储状态不放在 comb_top 内，后续应在外层统一时序区维护。
// -----------------------------------------------------------------------------
// 端口自查
// 模块: PTAB_comb
// 来源: train_IO.h / PTAB.cpp
// 配置: simulator-front 默认 large 配置
// 接口: PtabCombIn(9710 bit) -> PtabCombOut(14555 bit)
//
// 输入 PtabCombIn = 9710 bit
//   = inp 4853 bit
//   + rd  4857 bit
//   = 合计 9710 bit
//
// 输出 PtabCombOut = 14555 bit
//   = out_regs          4851 bit
//   + clear_ptab           1 bit
//   + push_write_en        1 bit
//   + push_write_entry  4850 bit
//   + push_dummy_en        1 bit
//   + push_dummy_entry  4850 bit
//   + pop_en               1 bit
//   = 合计             14555 bit
// -----------------------------------------------------------------------------

module PTAB_comb_top #(
    parameter W_PtabIn       = 4853,   // PTAB_in
    parameter W_PtabOut      = 4851,   // PTAB_out
    parameter W_PtabCombIn   = 9710,   // PtabCombIn
    parameter W_PtabCombOut  = 14555,  // PtabCombOut
    parameter PTAB_SIZE_BITS = 6,      // clog2(PTAB_SIZE + 1)
    parameter W_PtabReadData = PTAB_SIZE_BITS + 1 + (W_PtabOut - 1)
) (
    input  wire [W_PtabIn-1:0]       ptab_in,
    input  wire [W_PtabReadData-1:0] ptab_rd,
    output wire [W_PtabCombOut-1:0]  ptab_req
);

    localparam W_PtabPayload = W_PtabOut - 3;
    localparam W_PtabEntry = W_PtabOut - 1;

    // 连接层: 用语义变量拼接 pi，保持传给 bsd_top 的接口只有 pi/po。
    wire [W_PtabCombIn-1:0]  pi;
    wire [W_PtabCombOut-1:0] po;

    assign pi = {
        ptab_in,
        ptab_rd
    };

    assign ptab_req = po;

    PTAB_comb_bsd_top #(
        .W_PtabCombIn(W_PtabCombIn),
        .W_PtabCombOut(W_PtabCombOut)
    ) u_PTAB_comb_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule

module PTAB_comb_bsd_top #(
    parameter W_PtabCombIn  = 9710,
    parameter W_PtabCombOut = 14555
) (
    input  wire [W_PtabCombIn-1:0]  pi,
    output wire [W_PtabCombOut-1:0] po
);

    localparam W_PtabIn       = 4853;
    localparam W_PtabOut      = 4851;
    localparam W_PtabPayload  = 4848;
    localparam W_PtabEntry    = 4850;
    localparam PTAB_SIZE      = 32;
    localparam PTAB_SIZE_BITS = 6;
    localparam W_PtabReadData = PTAB_SIZE_BITS + 1 + W_PtabEntry;

    wire [W_PtabIn-1:0]       ptab_in;
    wire [W_PtabReadData-1:0] ptab_read_data;

    assign {
        ptab_in,
        ptab_read_data
    } = pi;

    // 第一阶段: 拆输入。reset/refetch 是同步清空请求，不是顶层异步复位。
    wire need_mini_flush = ptab_in[0];
    wire read_enable = ptab_in[1];
    wire [W_PtabPayload-1:0] write_payload =
        ptab_in[W_PtabPayload + 1:2];
    wire write_enable = ptab_in[W_PtabPayload + 2];
    wire refetch = ptab_in[W_PtabPayload + 3];
    wire reset = ptab_in[W_PtabPayload + 4];

    wire [PTAB_SIZE_BITS-1:0] read_size =
        ptab_read_data[W_PtabEntry + PTAB_SIZE_BITS:
                       W_PtabEntry + 1];
    wire read_valid = ptab_read_data[W_PtabEntry];
    wire [W_PtabEntry-1:0] read_entry = ptab_read_data[W_PtabEntry-1:0];
    wire read_dummy = read_entry[0];
    wire [W_PtabPayload-1:0] read_payload =
        read_entry[W_PtabEntry-1:2];

    reg clear_ptab;
    reg push_write_en;
    reg push_dummy_en;
    reg pop_en;
    reg [PTAB_SIZE_BITS-1:0] next_size;
    reg next_full;
    reg next_empty;
    reg output_dummy;
    reg [W_PtabPayload-1:0] output_payload;
    reg [W_PtabOut-1:0] out_regs;

    wire [W_PtabEntry-1:0] push_write_entry = {
        write_payload,
        1'b0,
        1'b0
    };
    wire [W_PtabEntry-1:0] push_dummy_entry = {
        {W_PtabPayload{1'b0}},
        1'b0,
        1'b1
    };

    // 第二阶段: 按本拍输入和上一拍队首快照生成 PTAB 请求。
    always @(*) begin
        clear_ptab = 1'b0;
        if (reset) begin
            clear_ptab = 1'b1;
        end else if (refetch) begin
            clear_ptab = 1'b1;
        end
    end

    always @(*) begin
        push_write_en = 1'b0;
        if (!clear_ptab) begin
            push_write_en = write_enable;
        end
    end

    always @(*) begin
        push_dummy_en = 1'b0;
        if (!clear_ptab) begin
            if (write_enable) begin
                if (need_mini_flush) begin
                    push_dummy_en = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        pop_en = 1'b0;
        if (!clear_ptab) begin
            if (read_enable) begin
                if (read_valid) begin
                    pop_en = 1'b1;
                end else if (write_enable) begin
                    pop_en = 1'b1;
                end
            end
        end
    end

    // 第三阶段: 组合估算下一拍 full/empty。真实 count 后续由外层时序区统一维护。
    always @(*) begin
        next_size = read_size;
        if (clear_ptab) begin
            next_size = {PTAB_SIZE_BITS{1'b0}};
        end else begin
            if (push_write_en) begin
                next_size = next_size + 1'b1;
            end
            if (push_dummy_en) begin
                next_size = next_size + 1'b1;
            end
            if (pop_en) begin
                next_size = next_size - 1'b1;
            end
        end
    end

    always @(*) begin
        next_full = 1'b0;
        // 对齐 simulator-front/fifo/PTAB.cpp:
        // out.out_regs.full = (next_size >= (PTAB_SIZE - 1));
        // PTAB 预留一格空间，避免本拍普通写入和 dummy 写入把队列推到边界外。
        if (next_size >= (PTAB_SIZE - 1)) begin
            next_full = 1'b1;
        end
    end

    always @(*) begin
        next_empty = 1'b0;
        if (next_size == {PTAB_SIZE_BITS{1'b0}}) begin
            next_empty = 1'b1;
        end
    end

    // 第四阶段: 生成本拍可见输出。空队列同拍写读时走写入旁路。
    always @(*) begin
        output_dummy = 1'b0;
        if (read_enable) begin
            if (read_valid) begin
                output_dummy = read_dummy;
            end
        end
    end

    always @(*) begin
        output_payload = {W_PtabPayload{1'b0}};
        if (read_enable) begin
            if (read_valid) begin
                output_payload = read_payload;
            end else if (write_enable) begin
                output_payload = write_payload;
            end
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
        clear_ptab,
        push_write_en,
        push_write_entry,
        push_dummy_en,
        push_dummy_entry,
        pop_en,
        out_regs
    };

endmodule
