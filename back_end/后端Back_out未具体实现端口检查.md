# 后端外部输出路径检查报告

## 1. 检查说明

本文档用于说明当前 `back_end/` Verilog 顶层中，后端对外输出路径与最新模拟器 `BackTop.cpp/BackTop.h` 的对应关系。

检查原则如下：

| 原则 | 说明 |
|---|---|
| 不自行扩展接口 | 当前只保留 C++ 中已有结构字段或已有模块接口，不额外添加无依据端口。 |
| 明确来源模块 | 每个外部输出都说明由哪个模块引出，避免只看到一个总输出包而不清楚来源。 |
| 只保留关键问题 | 由于模块内部实现尚未完全展开，本文只保留会影响后续接口方向的重点待确认项。 |

## 2. 主要依据

参考文件如下：

```text
simulator-new-lsu-tmp/back-end/include/BackTop.h
simulator-new-lsu-tmp/back-end/BackTop.cpp
simulator-new-lsu-tmp/back-end/Lsu/include/RealLsu.h
simulator-new-lsu-tmp/back-end/Lsu/RealLsu.cpp
back_end/back_top.v
```

`BackTop.h` 中 `Back_out` 主要字段包括：

```cpp
struct Back_out {
  bool mispred;
  bool stall;
  bool flush;
  bool fence_i;
  bool itlb_flush;
  wire<1> *fire;
  uint32_t redirect_pc;
  InstEntry commit_entry[COMMIT_WIDTH];

  wire<32> sstatus;
  wire<32> mstatus;
  wire<32> satp;
  wire<2> privilege;

  PeripheralReqIO peripheral_req;
  LsuDcacheIO lsu2dcache;
};
```

另外，LSU 和 MMU/DTLB 的交互在 `BackTop.cpp` 中也有明确连接：

```cpp
lsu->in.mmu2lsu = &mmu2lsu_io;
lsu->out.lsu2mmu = &lsu2mmu_io;
```

因此当前 Verilog 保留 `mmu2lsu_io` 和 `lsu2mmu_io`，但不新建独立 MMU 模块。

## 3. 外部输出路径检查结果

| 输出端口 | C++ 对应关系 | Verilog 当前来源 | 检查结论 |
|---|---|---|---|
| `fire` | `out.fire = pre2front.fire` | `preiduqueue_top` | 已连接 |
| `flush` | `out.flush = rob->out.rob_bcast->flush` | `rob_top` | 已连接 |
| `fence_i` | `out.fence_i = rob->out.rob_bcast->fence_i` | `rob_top` | 已连接 |
| `itlb_flush` | `out.itlb_flush = rob->out.rob_bcast->fence` | `rob_top` | 已连接 |
| `mispred` | 非 flush 来自 IDU，flush 时为 true | `idu_top/rob_top` | 已连接 |
| `stall` | `out.stall = !pre2front.ready` | `preiduqueue_top` | 已连接 |
| `redirect_pc` | 非 flush 来自 IDU，flush 时来自 CSR/ROB | `idu_top/csr_top/rob_top` | 已连接 |
| `commit_entry` | 由 `rob_commit` 转为 `InstEntry` | `rob_top/back_top.v` | 已连接，能从 `RobCommitInst` 取得的字段均已连接，无来源字段按 C++ 默认清零语义处理 |
| `sstatus` | `csr_status.sstatus` | `csr_top` | 已连接 |
| `mstatus` | `csr_status.mstatus` | `csr_top` | 已连接 |
| `satp` | `csr_status.satp` | `csr_top` | 已连接 |
| `privilege` | `csr_status.privilege` | `csr_top` | 已连接 |
| `peripheral_req` | `lsu->out.peripheral_req = &out.peripheral_req` | `lsu_top` | 已连接 |
| `lsu2dcache` | `lsu->out.lsu2dcache = &out.lsu2dcache` | `lsu_top` | 已连接 |
| `lsu2mmu_io` | `lsu->out.lsu2mmu = &lsu2mmu_io` | `lsu_top` | 已连接 |

当前 `mmu2lsu_io` 作为顶层输入接入 LSU：

```verilog
input wire [W_MMULsuIO-1:0] mmu2lsu_io;

lsu_top lsu (
    ...
    .mmu2lsu_io(mmu2lsu_io),
    ...
);
```

## 4. 关键路径说明

### 4.1 控制输出

`flush`、`fence_i`、`itlb_flush` 来自 ROB broadcast；`mispred` 正常来自 IDU，在 flush 场景下按 C++ 行为输出为 1；`redirect_pc` 在非 flush 时来自 IDU，在 flush 时从 CSR/ROB 路径选择。

### 4.2 LSU 外部输出

`peripheral_req`、`lsu2dcache`、`lsu2mmu_io` 均由 `lsu_top` 直接输出到 `back_top.v` 顶层，不再置 0。

### 4.3 commit_entry

`commit_entry` 当前由 `rob_commit` 拆字段后组合打包生成，并处理 flush 场景下 `diag_val = redirect_pc` 的逻辑。能从 `RobCommitInst` 取得的字段均已连接；`InstEntry` 中存在但 `RobCommitInst` 没有来源的字段，按 C++ 中 `InstEntry dst` 默认初始化后的语义填 0，保持总线宽度一致。

## 5. 当前重要待确认项

| 问题 | 当前处理 | 影响 |
|---|---|---|
| MMU/DTLB 是否后续独立成模块 | 当前不新建 MMU，只保留 `mmu2lsu_io/lsu2mmu_io` 与 LSU 交互。 | 如果后续需要独立 MMU，需要新增模块目录和顶层连接说明。 |

## 6. 不纳入当前 RTL top 的路径

`restore_from_ref/restore_checkpoint` 属于 C++ 仿真恢复流程。根据当前反馈，这两个函数不在本版 RTL top 中实现，因此不添加 `restore_valid/restore_pc` 等端口，也不在 Verilog 中表达由 restore 强制产生的 `flush/redirect_pc`。

## 7. 检查结论

当前 `back_top.v` 已把 C++ 中主要外部输出路径拆成明确的顶层端口，并标明来源模块。`mmu2lsu_io`、`lsu2mmu_io`、`peripheral_req`、`lsu2dcache` 和 `commit_entry` 均已从旧的占位/不明确状态调整为明确连接状态。后续主要等待 MMU/DTLB 组织方式确认。
