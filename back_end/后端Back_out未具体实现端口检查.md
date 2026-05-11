# 后端外部输出路径检查报告

## 1. 检查目的

本文档用于检查当前 `back_end/` Verilog 顶层中，后端对外输出路径是否已经和最新模拟器 `BackTop.cpp/BackTop.h` 中的主要连接关系对齐。

检查重点有三类：

| 检查点 | 说明 |
|---|---|
| 是否有来源模块 | 每个外部输出都需要能说明由哪个后端模块引出。 |
| 是否仍是占位连接 | 重点检查 `peripheral_req`、`lsu2dcache`、`lsu2mmu_io`、`commit_entry` 等之前容易置空或遗漏的路径。 |
| 是否自行扩展接口 | 当前不主动新增无依据端口；如果后续必须新增，需要在文档中单独说明。 |

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

LSU 和 MMU/DTLB 的交互在 `BackTop.cpp` 中还有独立连接：

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
| `commit_entry` | 由 `rob_commit` 转为提交输出 | `rob_top/back_top.v` | 已连接；对外提交版只保留功能字段 |
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

| 输出 | 来源 | 当前 Verilog 表达 |
|---|---|---|
| `flush` | ROB broadcast | `assign flush = rob_out_rob_bcast_flush;` |
| `fence_i` | ROB broadcast | `assign fence_i = rob_out_rob_bcast_fence_i;` |
| `itlb_flush` | ROB broadcast fence 字段 | `assign itlb_flush = rob_out_rob_bcast_fence;` |
| `mispred` | IDU 或 ROB flush | flush 时输出 1，否则取 `idu_out_dec_bcast_mispred`。 |
| `stall` | PreIduQueue ready | `assign stall = ~preiduqueue_out_pre2front_ready;` |

### 4.2 redirect_pc

`redirect_pc` 当前分成两条路径，便于和 C++ 行为对照：

| 场景 | 当前来源 |
|---|---|
| 非 flush | `idu_top` 输出的 `idu_br_latch_redirect_pc` |
| flush 且 mret/sret | `csr_top` 输出的 `csr2front_epc` |
| flush 且 exception | `csr_top` 输出的 `csr2front_trap_pc` |
| flush 的其他情况 | `rob_top` 输出的 `rob_bcast_pc + 4` |

### 4.3 LSU 外部输出

`peripheral_req`、`lsu2dcache`、`lsu2mmu_io` 均由 `lsu_top` 直接输出到 `back_top.v` 顶层，不再置 0。

| 输出 | Verilog 连接 |
|---|---|
| `peripheral_req` | `lsu_top.peripheral_req -> back_top.peripheral_req` |
| `lsu2dcache` | `lsu_top.lsu2dcache -> back_top.lsu2dcache` |
| `lsu2mmu_io` | `lsu_top.lsu2mmu_io -> back_top.lsu2mmu_io` |

### 4.4 commit_entry

`commit_entry` 由 `rob_commit` 拆字段后组合打包生成，并处理 flush 场景下 `diag_val = redirect_pc` 的逻辑。

| 字段类型 | 当前处理 |
|---|---|
| 可从 `RobCommitInst` 取得的字段 | 直接由 `rob_commit` 拆出后连接。 |
| `RobCommitInst` 没有来源的字段 | 按 C++ 默认清零行为补 0。 |
| `diag_val` | 正常来自 `rob_commit`，flush 且 valid 时改为 `redirect_pc`。 |

## 5. 当前重要待确认项

| 问题 | 当前处理 | 影响 |
|---|---|---|
| MMU/DTLB 后续是否独立成模块 | 当前不新建 MMU，只保留 `mmu2lsu_io/lsu2mmu_io` 与 LSU 交互。 | 如果后续新版模拟器要求 MMU 独立成模块，需要新增模块目录和顶层连接说明。 |

## 6. 不纳入当前 RTL top 的路径

`restore_from_ref/restore_checkpoint` 属于 C++ 仿真恢复流程。根据当前反馈，这两个函数不在本版 RTL top 中实现。

因此当前不添加 `restore_valid/restore_pc` 等端口，也不在 Verilog 中表达由 restore 强制产生的 `flush/redirect_pc`。

## 7. 检查结论

当前 `back_top.v` 已把 C++ 中主要外部输出路径拆成明确的顶层端口，并标明来源模块。

`mmu2lsu_io`、`lsu2mmu_io`、`peripheral_req`、`lsu2dcache` 和 `commit_entry` 均已从旧的占位或不明确状态调整为明确连接状态。后续主要等待 MMU/DTLB 组织方式确认。
