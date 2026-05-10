# 后端 Top 连接关系说明

## 1. 版本说明

本文档说明 `back_end/` 当前版本的后端顶层连接方式。当前版本主要用于表达后端各模块之间的输入输出连线关系，不包含各模块内部寄存器、RAM、队列、切刀逻辑和具体功能实现。

当前版本遵循以下规则：

| 规则 | 说明 |
|---|---|
| 顶层端口拆开 | `back_top.v` 不使用总包 `Back_in/Back_out`，而是把已有输入输出字段拆成独立端口，方便后续与前端、DCache、外设和 MMU 连接。 |
| 只保留 10 个后端模块 | 当前保留 `preiduqueue`、`idu`、`ren`、`dispatch`、`isu`、`prf`、`exu`、`rob`、`csr`、`lsu`。 |
| 不额外新增功能端口 | 顶层端口来自 C++ 中已有结构字段或已有模块接口；如需新增端口，后续需单独说明来源和用途。 |
| BSD 在模块内部例化 | 总顶层只做模块间连线，各模块自己的 `xxx_top.v` 内部再例化 `xxx_bsd_top`。 |
| BSD 接口统一 | 各 `xxx_bsd_top` 对外接口统一使用 `pi/po`。 |

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

## 3. back_top.v 顶层接口

`back_top.v` 当前接口如下：

```verilog
module back_top (
    input  wire [W_FrontPreIO-1:0]       front2pre,
    input  wire [W_PeripheralRespIO-1:0] peripheral_resp,
    input  wire [W_DcacheLsuIO-1:0]      dcache2lsu,
    input  wire [W_MMULsuIO-1:0]         mmu2lsu_io,

    output wire                          mispred,
    output wire                          stall,
    output wire                          flush,
    output wire                          fence_i,
    output wire                          itlb_flush,
    output wire [FETCH_WIDTH-1:0]        fire,
    output wire [31:0]                   redirect_pc,
    output wire [(W_BackCommitEntry * COMMIT_WIDTH)-1:0] commit_entry,
    output wire [31:0]                   sstatus,
    output wire [31:0]                   mstatus,
    output wire [31:0]                   satp,
    output wire [1:0]                    privilege,
    output wire [W_PeripheralReqIO-1:0]  peripheral_req,
    output wire [W_LsuDcacheIO-1:0]      lsu2dcache,
    output wire [W_LsuMMUIO-1:0]         lsu2mmu_io
);
```

端口来源如下：

| 顶层端口 | 方向 | 来源 | 当前连接 |
|---|---|---|---|
| `front2pre` | input | `Back_in` 继承的 `FrontPreIO` | 输入 `preiduqueue_top`，其中 `front_stall` 同时连接 ROB。 |
| `peripheral_resp` | input | `Back_in.peripheral_resp` | 输入 `lsu_top`。 |
| `dcache2lsu` | input | `Back_in.dcache2lsu` | 输入 `lsu_top`。 |
| `mmu2lsu_io` | input | `lsu->in.mmu2lsu` | 输入 `lsu_top`，不置 0。 |
| `mispred` | output | `Back_out.mispred` | 正常来自 IDU，flush 时置 1。 |
| `stall` | output | `Back_out.stall` | 来自 `pre2front.ready` 反相。 |
| `flush` | output | `Back_out.flush` | 来自 ROB broadcast。 |
| `fence_i` | output | `Back_out.fence_i` | 来自 ROB broadcast。 |
| `itlb_flush` | output | `Back_out.itlb_flush` | 来自 ROB broadcast 的 fence 字段。 |
| `fire` | output | `Back_out.fire` | 来自 PreIduQueue。 |
| `redirect_pc` | output | `Back_out.redirect_pc` | 非 flush 来自 IDU，flush 时由 CSR/ROB 选择。 |
| `commit_entry` | output | `Back_out.commit_entry` | 由 `rob_commit` 组合打包生成；对外提交版删去 `tma/dbg` 字段。 |
| `sstatus/mstatus/satp/privilege` | output | `Back_out` 中 CSR 状态字段 | 来自 `csr_top`。 |
| `peripheral_req` | output | `lsu->out.peripheral_req` | 由 `lsu_top` 直接输出。 |
| `lsu2dcache` | output | `lsu->out.lsu2dcache` | 由 `lsu_top` 直接输出。 |
| `lsu2mmu_io` | output | `lsu->out.lsu2mmu` | 由 `lsu_top` 直接输出。 |

## 4. 外部输出来源

下表列出 `back_top.v` 对外输出由哪个模块引出：

| 输出端口 | 来源模块 | 说明 |
|---|---|---|
| `fire` | `preiduqueue_top` | 后端返回给前端的取指消费信息。 |
| `mispred` | `idu_top/rob_top` | 非 flush 来自 IDU，flush 时由 ROB 路径置 1。 |
| `stall` | `preiduqueue_top` | 由 `pre2front.ready` 反相得到。 |
| `flush` | `rob_top` | 来自 ROB broadcast。 |
| `fence_i` | `rob_top` | 来自 ROB broadcast。 |
| `itlb_flush` | `rob_top` | 来自 ROB broadcast 的 fence 字段。 |
| `redirect_pc` | `idu_top/csr_top/rob_top` | 根据 flush 状态在 IDU、CSR、ROB 来源之间选择。 |
| `commit_entry` | `rob_top/back_top.v` | `rob_top` 输出 `rob_commit`，`back_top.v` 做组合打包；对外提交版不包含 `tma/dbg`。 |
| `sstatus/mstatus/satp/privilege` | `csr_top` | CSR 状态信息。 |
| `peripheral_req` | `lsu_top` | LSU 发给外设。 |
| `lsu2dcache` | `lsu_top` | LSU 发给 DCache。 |
| `lsu2mmu_io` | `lsu_top` | LSU 发给 MMU/DTLB。 |

## 5. 模块间一级连线

总顶层只连接各模块一级接口，不展开模块内部结构。

| 来源模块/外部 | 信号 | 去向模块/外部 |
|---|---|---|
| 外部 | `front2pre` | `preiduqueue_top` |
| `preiduqueue_top` | `pre_issue` | `idu_top` |
| `idu_top` | `idu_consume`、`idu_br_latch` | `preiduqueue_top` |
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
| `rob_top` | `rob_bcast` | 多个后端模块 |
| `rob_top` | `rob_commit` | `preiduqueue_top/ren_top/lsu_top/back_top.v` |
| `rob_top` | `rob2dis` | `dispatch_top` |
| `rob_top` | `rob2csr` | `csr_top` |
| `csr_top` | `csr2exe` | `exu_top` |
| `csr_top` | `csr2rob` | `rob_top` |
| `csr_top` | `csr2front` | `back_top.v` 生成 `redirect_pc` 时使用 |
| `csr_top` | `csr_status` | `exu_top/lsu_top/back_top.v` |
| 外部 | `peripheral_resp`、`dcache2lsu`、`mmu2lsu_io` | `lsu_top` |
| `lsu_top` | `lsu2exe` | `exu_top` |
| `lsu_top` | `lsu2dis` | `dispatch_top` |
| `lsu_top` | `lsu2rob` | `rob_top` |
| `lsu_top` | `peripheral_req`、`lsu2dcache`、`lsu2mmu_io` | 外部 |

`front_stall` 保留 C++ 中的关系：

```cpp
rob->in.front_stall = &in.front_stall;
```

当前在 Verilog 中从 `front2pre` 中拆出 `front_stall_from_front2pre`，再连接到 `rob_top.front_stall`。

## 6. 单模块 wrapper 规则

每个模块目录下的 `xxx_top.v` 采用统一规则：

| 内容 | 说明 |
|---|---|
| 对外接口 | 暴露该模块已有的一级输入输出接口。 |
| 内部处理 | 在本模块文件中完成必要字段切分和 `pi/po` 打包。 |
| BSD 例化 | 在本模块文件中例化 `xxx_bsd_top`，不放在 `back_top.v` 中。 |
| 内部结构 | 寄存器、RAM、队列、切刀逻辑不作为模块对外端口。 |

示例结构：

```verilog
wire [W_XxxIn-1:0]  pi;
wire [W_XxxOut-1:0] po;

assign pi = {input_a, input_b};
assign {output_a} = po;

xxx_bsd_top u_xxx_bsd_top (
    .pi(pi),
    .po(po)
);
```

## 7. 当前未纳入内容

| 内容 | 当前处理 |
|---|---|
| 独立 MMU 模块 | 暂不新建，只保留 LSU 已有的 `mmu2lsu_io/lsu2mmu_io` 端口。 |
| `restore_from_ref/restore_checkpoint` | 按当前反馈不进入 RTL top，不添加 `restore_valid/restore_pc`。 |
| 模块内部寄存器/RAM 接口 | 不作为顶层或模块 wrapper 的对外端口。 |

## 8. 格式要求

所有 `.v` 文件中不使用以下模板语句：

```verilog
`ifndef ...
`define ...
`endif
`default_nettype none
`default_nettype wire
```
