# 后端 Top 连接关系说明

## 1. 文档目的

本文说明 `back_end/` 目录中后端顶层和各模块 wrapper 的连接关系。本版按最新指导意见调整为两层表达：

1. `back_top.v` 只负责后端 10 个模块之间的一级接口连线，以及 `Back_in/Back_out` 的顶层出入口汇总。
2. 各模块目录下的 `xxx_top.v` 负责把本模块输入输出细化到一级子接口，再打包为 `pi/po` 连接到后续由小组提供的 `xxx_bsd_top`。
3. 由某个模块产生或接收的接口字段在该模块 wrapper 内切分。例如 `iss2prf.iss_entry.uop.dest_preg` 在 `prf_top.v` 内可见，`rob_bcast.flush` 在各使用该广播的模块内可见，`csr_status.sstatus` 在 `csr_top.v/exu_top.v/lsu_top.v` 内可见；`back_top.v` 只保留模块级主线和 `Back_out` 汇总。

本版仍是连接骨架，不展开寄存器、RAM、队列和模块内部具体逻辑。

## 2. 目录结构

```text
back_end/
|-- back_top.v
|-- preiduqueue/
|   |-- preiduqueue_top.v
|   `-- slices/
|-- idu/
|   |-- idu_top.v
|   `-- slices/
|-- ren/
|   |-- ren_top.v
|   `-- slices/
|-- dispatch/
|   |-- dispatch_top.v
|   `-- slices/
|-- isu/
|   |-- isu_top.v
|   `-- slices/
|-- prf/
|   |-- prf_top.v
|   `-- slices/
|-- exu/
|   |-- exu_top.v
|   `-- slices/
|-- rob/
|   |-- rob_top.v
|   `-- slices/
|-- csr/
|   |-- csr_top.v
|   `-- slices/
|-- lsu/
|   |-- lsu_top.v
|   `-- slices/
|-- 后端Top连接关系说明.md
`-- 后端Back_out未具体实现端口检查.md
```

当前只保留 10 个正式后端模块目录，不新建 MMU 文件夹。MMU/地址翻译相关接口暂时在 LSU 侧保留占位线，等待新版模拟器接口明确后再补。

## 3. 总顶层接口

`back_top.v` 对外只保留：

```verilog
module back_top (
    input  wire [W_Back_in-1:0]  Back_in,
    output wire [W_Back_out-1:0] Back_out
);
```

`Back_in` 拆为：

| 字段 | 去向 |
|---|---|
| `front2pre` | `preiduqueue_top.front2pre` |
| `peripheral_resp` | `lsu_top.peripheral_resp` |
| `dcache2lsu` | `lsu_top.dcache2lsu` |

`Back_out` 汇总为：

| 字段 | 来源 |
|---|---|
| `mispred` | 正常来自 `idu_top` 输出接口 `dec_bcast` 的 `idu_out_dec_bcast_mispred`；当 `rob_top` 输出接口 `rob_bcast` 的 `rob_out_rob_bcast_flush` 为 1 时强制为 `1'b1` |
| `stall` | 来自 `preiduqueue_top` 输出接口 `pre2front` 的 `preiduqueue_out_pre2front_ready`，连接形式为 `~preiduqueue_out_pre2front_ready` |
| `flush` | 来自 `rob_top` 输出接口 `rob_bcast` 的 `rob_out_rob_bcast_flush` |
| `fence_i` | 来自 `rob_top` 输出接口 `rob_bcast` 的 `rob_out_rob_bcast_fence_i` |
| `itlb_flush` | 来自 `rob_top` 输出接口 `rob_bcast` 的 `rob_out_rob_bcast_fence` |
| `fire` | 来自 `preiduqueue_top` 输出接口 `pre2front` 的 `preiduqueue_out_pre2front_fire` |
| `redirect_pc` | 正常来自 `idu_top` 输出接口 `idu_br_latch` 的 `idu_out_idu_br_latch_redirect_pc`；flush 时根据 `rob_top` 输出接口 `rob_bcast` 选择 `csr_out_csr2front_epc`、`csr_out_csr2front_trap_pc` 或 `rob_out_rob_bcast_pc + 4` |
| `commit_entry` | 来自 `rob_top` 输出的 `rob_out_rob_commit_entry_for_backout`，当前在 `rob_top.v` 内置空占位，后续需要由 ROB slice 实现 `RobCommitInst::to_inst_entry(valid)` 字段映射 |
| `sstatus/mstatus/satp/privilege` | 来自 `csr_top` 输出接口 `csr_status` 的 `csr_out_csr_status_sstatus`、`csr_out_csr_status_mstatus`、`csr_out_csr_status_satp`、`csr_out_csr_status_privilege` |
| `peripheral_req` | 来自 `lsu_top` 输出接口 `peripheral_req`，在顶层命名为 `lsu_out_peripheral_req` |
| `lsu2dcache` | 来自 `lsu_top` 输出接口 `lsu2dcache`，在顶层命名为 `lsu_out_lsu2dcache` |

为增强可读性，`Back_out` 相关中间线统一使用：

```text
<来源模块>_out_<来源接口>_<字段名>
```

例如：

```verilog
wire rob_out_rob_bcast_flush;
wire idu_out_dec_bcast_mispred;
wire [31:0] csr_out_csr2front_epc;

wire mispred =
    rob_out_rob_bcast_flush ? 1'b1 : idu_out_dec_bcast_mispred;
```

这样可以直接从线名看出：`mispred` 的正常路径来自 `idu_top.dec_bcast`，flush 覆盖来自 `rob_top.rob_bcast`。字段切分不在 `back_top.v` 中展开，而是在对应来源模块的 `xxx_top.v` 中完成。

## 4. 模块内部字段级切分规则

本版在每个 `xxx_top.v` 中增加模块内部字段级视图。规则如下：

| 规则 | 说明 |
|---|---|
| 命名方式 | 使用 `接口名_结构名_字段名`，例如 `iss2prf_iss_entry_uop_dest_preg`、`exe2lsu_req_uop_func3`、`rob_bcast_flush` |
| 数组表达 | 多个同类字段用 packed vector 表达，例如 `wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0] iss2prf_iss_entry_uop_dest_preg;` |
| 整包中间线 | `xxx_uop`、`xxx_entry_uop` 只作为继续拆字段的中间承载，后面会继续拆成 `xxx_uop_dest_preg`、`xxx_uop_func3` 等具体字段 |
| 打包顺序 | `pi/po` 的总线顺序保持原有 C++ struct 对应顺序，不改变模块之间的一级连接 |
| BSD 例化 | 各模块仍然在自己的 wrapper 内例化 `xxx_bsd_top`，接口保持 `.pi(pi), .po(po)` |

各模块内部字段视图示例：

```verilog
wire [ISSUE_WIDTH-1:0] iss2prf_iss_entry_valid;
wire [(PRF_IDX_WIDTH * ISSUE_WIDTH)-1:0]
    iss2prf_iss_entry_uop_dest_preg;

assign {iss2prf_iss_entry_valid,
        iss2prf_iss_entry_uop_dest_preg,
        ...} = iss2prf;
```

## 5. Back_out 细字段切分位置

| 来源模块文件 | 在模块内切分的字段 | 供 `back_top.v` 使用的字段 |
|---|---|---|
| `preiduqueue/preiduqueue_top.v` | `pre2front.fire`、`pre2front.ready` | `preiduqueue_out_pre2front_fire`、`preiduqueue_out_pre2front_ready` |
| `idu/idu_top.v` | `dec_bcast`、`idu_br_latch` | `idu_out_dec_bcast_mispred`、`idu_out_idu_br_latch_redirect_pc` |
| `rob/rob_top.v` | `rob_bcast`、ROB commit 到 `InstEntry` 的预留转换 | `rob_out_rob_bcast_flush`、`rob_out_rob_bcast_mret`、`rob_out_rob_bcast_sret`、`rob_out_rob_bcast_exception`、`rob_out_rob_bcast_fence`、`rob_out_rob_bcast_fence_i`、`rob_out_rob_bcast_pc`、`rob_out_rob_commit_entry_for_backout` |
| `csr/csr_top.v` | `csr2front`、`csr_status` | `csr_out_csr2front_epc`、`csr_out_csr2front_trap_pc`、`csr_out_csr_status_sstatus`、`csr_out_csr_status_mstatus`、`csr_out_csr_status_satp`、`csr_out_csr_status_privilege` |
| `lsu/lsu_top.v` | 一级输出接口保持整包输出 | `lsu_out_peripheral_req`、`lsu_out_lsu2dcache` |

## 6. 模块间一级连线

总顶层不再用 `PreIduQueueIn/PreIduQueueOut`、`PrfIn/PrfOut` 这类聚合中转端口连接模块，而是直接连接一级子接口。主要连接如下：

| 来源模块 | 信号 | 去向模块 |
|---|---|---|
| `Back_in` | `front2pre` | `preiduqueue_top` |
| `preiduqueue_top` | `pre_issue` | `idu_top` |
| `idu_top` | `idu_consume` | `preiduqueue_top` |
| `idu_top` | `idu_br_latch` | `preiduqueue_top` |
| `idu_top` | `dec2ren` | `ren_top` |
| `idu_top` | `dec_bcast` | `ren_top/dispatch_top/isu_top/prf_top/exu_top/rob_top/lsu_top` |
| `ren_top` | `ren2dec` | `idu_top` |
| `ren_top` | `ren2dis` | `dispatch_top` |
| `dispatch_top` | `dis2ren` | `ren_top` |
| `dispatch_top` | `dis2iss` | `isu_top` |
| `dispatch_top` | `dis2rob` | `rob_top` |
| `dispatch_top` | `dis2lsu` | `lsu_top` |
| `isu_top` | `iss2dis` | `dispatch_top` |
| `isu_top` | `iss2prf` | `prf_top` |
| `isu_top` | `iss_awake` | `dispatch_top` |
| `prf_top` | `prf2exe` | `exu_top` |
| `prf_top` | `prf_awake` | `dispatch_top/isu_top` |
| `prf_top` | `ftq_prf_pc_req` | `preiduqueue_top` |
| `preiduqueue_top` | `ftq_prf_pc_resp` | `prf_top` |
| `exu_top` | `exe2prf` | `prf_top` |
| `exu_top` | `exe2iss` | `isu_top` |
| `exu_top` | `exe2csr` | `csr_top` |
| `exu_top` | `exe2lsu` | `lsu_top` |
| `exu_top` | `exu2id` | `idu_top` |
| `exu_top` | `exu2rob` | `rob_top` |
| `rob_top` | `rob_bcast` | 多个模块 |
| `rob_top` | `rob_commit` | `preiduqueue_top/ren_top/lsu_top` |
| `rob_top` | `rob2dis` | `dispatch_top` |
| `rob_top` | `rob2csr` | `csr_top` |
| `csr_top` | `csr2exe` | `exu_top` |
| `csr_top` | `csr2rob` | `rob_top` |
| `csr_top` | `csr2front` | `back_top.v` 内部生成 `redirect_pc` |
| `csr_top` | `csr_status` | `exu_top/lsu_top/back_top.v` |
| `lsu_top` | `lsu2exe` | `exu_top` |
| `lsu_top` | `lsu2dis` | `dispatch_top` |
| `lsu_top` | `lsu2rob` | `rob_top` |
| `lsu_top` | `peripheral_req` | `Back_out` |
| `lsu_top` | `lsu2dcache` | `Back_out` |

`front_stall` 保留源码关系：

```cpp
rob->in.front_stall = &in.front_stall;
```

在当前 Verilog 中，`front_stall_from_Back_in` 从 `front2pre` 中取出后连接到 `rob_top.front_stall`。

## 7. 单模块 wrapper 规则

每个 `xxx_top.v` 的结构统一为：

```verilog
module xxx_top (
    input  wire [...] input_a,
    input  wire [...] input_b,
    output wire [...] output_a
);

    wire [W_XxxIn-1:0]  pi;
    wire [W_XxxOut-1:0] po;

    assign pi = {input_a, input_b};
    assign {output_a} = po;

    xxx_bsd_top #(
        .W_XxxIn(W_XxxIn),
        .W_XxxOut(W_XxxOut)
    ) u_xxx_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
```

也就是说，`xxx_bsd_top` 的接口统一命名为 `pi/po`，不再使用 `.PrfIn(...)`、`.PrfOut(...)`、`.CsrIn(...)`、`.CsrOut(...)` 这类端口名。

各模块一级接口拆分如下：

| 模块 | 输入一级接口 | 输出一级接口 |
|---|---|---|
| `preiduqueue_top` | `front2pre`、`idu_consume`、`rob_bcast`、`rob_commit`、`idu_br_latch`、`ftq_prf_pc_req`、`ftq_rob_pc_req` | `pre2front`、`pre_issue`、`ftq_prf_pc_resp`、`ftq_rob_pc_resp` |
| `idu_top` | `pre_issue`、`ren2dec`、`rob_bcast`、`exu2id` | `dec2ren`、`dec_bcast`、`idu_consume`、`idu_br_latch` |
| `ren_top` | `dec2ren`、`dec_bcast`、`dis2ren`、`rob_bcast`、`rob_commit` | `ren2dec`、`ren2dis` |
| `dispatch_top` | `ren2dis`、`rob2dis`、`iss2dis`、`lsu2dis`、`prf_awake`、`iss_awake`、`rob_bcast`、`dec_bcast` | `dis2ren`、`dis2rob`、`dis2iss`、`dis2lsu` |
| `isu_top` | `dis2iss`、`prf_awake`、`exe2iss`、`rob_bcast`、`dec_bcast` | `iss2prf`、`iss2dis`、`iss_awake` |
| `prf_top` | `iss2prf`、`exe2prf`、`dec_bcast`、`rob_bcast`、`ftq_prf_pc_resp` | `prf2exe`、`prf_awake`、`ftq_prf_pc_req` |
| `exu_top` | `prf2exe`、`dec_bcast`、`rob_bcast`、`csr2exe`、`lsu2exe`、`csr_status` | `exe2prf`、`exe2iss`、`exe2csr`、`exe2lsu`、`exu2id`、`exu2rob` |
| `rob_top` | `dis2rob`、`csr2rob`、`lsu2rob`、`dec_bcast`、`exu2rob`、`ftq_rob_pc_resp`、`front_stall` | `rob2dis`、`rob2csr`、`rob_commit`、`rob_bcast`、`ftq_rob_pc_req` |
| `csr_top` | `exe2csr`、`rob2csr`、`rob_bcast` | `csr2exe`、`csr2rob`、`csr2front`、`csr_status` |
| `lsu_top` | `rob_commit`、`rob_bcast`、`dec_bcast`、`csr_status`、`dis2lsu`、`exe2lsu`、`peripheral_resp`、`dcache2lsu`、`mmu2lsu_io` | `lsu2dis`、`lsu2rob`、`lsu2exe`、`peripheral_req`、`lsu2dcache`、`lsu2mmu_io` |

此外，各模块 wrapper 内部还会继续把本模块用到的一级接口拆到字段级，方便查看模块输入输出的具体字段来源。

## 8. MMU 占位

当前不新建 MMU 目录，不把 MMU 算入 10 个正式后端模块。由于 LSU 源码接口中存在：

```cpp
lsu->in.mmu2lsu = &mmu2lsu_io;
lsu->out.lsu2mmu = &lsu2mmu_io;
```

因此 `back_top.v` 保留 `mmu2lsu_io` 和 `lsu2mmu_io` 两根占位线。当前 `mmu2lsu_io` 置零：

```verilog
assign mmu2lsu_io = {W_MMULsuIO{1'b0}};
```

后续等新版模拟器明确 MMU 输入输出后，再决定是否新增正式 MMU 模块或补充具体连接。

## 9. 已删除的模板语句

按最新要求，所有 `.v` 文件中已删除以下模板语句：

```verilog
`ifndef ...
`define ...
`endif
`default_nettype none
`default_nettype wire
```

当前文件只保留模块定义、参数、端口、连线和必要说明注释。
