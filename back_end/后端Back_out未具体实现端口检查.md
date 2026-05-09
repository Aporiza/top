# 后端 Back_out 外部输出未具体实现路径检查报告

## 1. 检查目的

本文档用于检查当前 `back_end/` Verilog 顶层与最新模拟器 `BackTop.cpp` 之间的 `Back_out` 外部输出路径一致性。

检查重点不是模块端口命名是否完整，而是确认：C++ 模拟器中已经写入 `Back_out` 并最终对外可见的数据线，在当前 Verilog 中是否已经有对应连线或实现逻辑。

本文档将检查结果分为三类：

| 状态 | 含义 |
|---|---|
| 已连接 | 当前 Verilog 顶层已有对应来源模块与连接关系。 |
| 未具体实现 | C++ 中存在真实赋值或计算逻辑，但当前 Verilog 为置零、缺少输入来源或缺少组合逻辑。 |
| 依赖 BSD 实现 | 总 top 已连接到对应模块 wrapper，具体字段生成依赖后续 `xxx_bsd_top` 或 slice 实现。 |

## 2. 检查依据

本次检查依据如下文件：

```text
simulator-new-lsu-tmp/back-end/include/BackTop.h
simulator-new-lsu-tmp/back-end/BackTop.cpp
simulator-new-lsu-tmp/back-end/include/IO.h
back_end/back_top.v
back_end/rob/rob_top.v
back_end/lsu/lsu_top.v
```

其中 `BackTop.h` 中 `Back_out` 定义如下：

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

## 3. Back_out 字段对比总表

| Back_out 字段 | C++ 输出来源 | 当前 Verilog 状态 | 检查结论 |
|---|---|---|---|
| `fire` | `out.fire = pre2front.fire;` | `fire = preiduqueue_out_pre2front_fire`，来自 `preiduqueue_top` | 已连接 |
| `flush` | `out.flush = rob->out.rob_bcast->flush;` | `flush = rob_out_rob_bcast_flush`，来自 `rob_top` | 已连接 |
| `fence_i` | `out.fence_i = rob->out.rob_bcast->fence_i;` | `fence_i = rob_out_rob_bcast_fence_i`，来自 `rob_top` | 已连接 |
| `itlb_flush` | `out.itlb_flush = rob->out.rob_bcast->fence;` | `itlb_flush = rob_out_rob_bcast_fence`，来自 `rob_top` | 已连接 |
| `mispred` | 正常路径来自 `dec_bcast.mispred`，flush 路径强制为 `true` | `rob_out_rob_bcast_flush ? 1'b1 : idu_out_dec_bcast_mispred` | 已连接 |
| `stall` | 非 flush 正常路径为 `!pre2front.ready` | `~preiduqueue_out_pre2front_ready` | 已连接，flush 周期语义需确认 |
| `redirect_pc` | 正常来自 `idu->br_latch.redirect_pc`；flush 时从 CSR 或 ROB 选择 | 已按 `mret/sret/exception/pc+4` 选择 | 已连接 |
| `commit_entry` | `rob_commit.commit_entry[i].uop.to_inst_entry(valid)`；flush 时覆盖 `diag_val` | `rob_top.v` 当前输出全 0 | 未具体实现 |
| `sstatus` | `csr_status.sstatus` | 来自 `csr_top` 的 `csr_out_csr_status_sstatus` | 已连接 |
| `mstatus` | `csr_status.mstatus` | 来自 `csr_top` 的 `csr_out_csr_status_mstatus` | 已连接 |
| `satp` | `csr_status.satp` | 来自 `csr_top` 的 `csr_out_csr_status_satp` | 已连接 |
| `privilege` | `csr_status.privilege` | 来自 `csr_top` 的 `csr_out_csr_status_privilege` | 已连接 |
| `peripheral_req` | `lsu->out.peripheral_req = &out.peripheral_req;` | 总 top 已接 `lsu_out_peripheral_req` | 连接已存在，具体生成依赖 LSU BSD |
| `lsu2dcache` | `lsu->out.lsu2dcache = &out.lsu2dcache;` | 总 top 已接 `lsu_out_lsu2dcache` | 连接已存在，具体生成依赖 LSU BSD |

## 4. 未具体实现项

### 4.1 `commit_entry` 整包输出未具体实现

`commit_entry` 是当前最明确的 `Back_out` 外部输出缺口。C++ 中不是直接透传 `rob_commit`，而是对 ROB commit 信息进行结构转换：

```cpp
for (int i = 0; i < COMMIT_WIDTH; i++) {
  out.commit_entry[i] =
      rob->out.rob_commit->commit_entry[i].uop.to_inst_entry(
          rob->out.rob_commit->commit_entry[i].valid);
}
```

当前 Verilog 中 `rob_top.v` 虽然已经拆出了 `rob_commit_entry_valid` 和 `rob_commit_entry_uop`，但最终输出给 `Back_out` 的 `rob_commit_entry_for_backout` 仍为全 0：

```verilog
assign rob_commit_entry_for_backout =
    {(W_InstEntry * COMMIT_WIDTH){1'b0}};
```

因此当前 `Back_out.commit_entry` 下列字段均尚未真实输出：

| 外部字段 | C++ 来源 |
|---|---|
| `commit_entry[i].valid` | `rob_commit.commit_entry[i].valid` |
| `commit_entry[i].uop.diag_val` | `RobCommitInst.diag_val` |
| `commit_entry[i].uop.dest_areg` | `RobCommitInst.dest_areg` |
| `commit_entry[i].uop.dest_preg` | `RobCommitInst.dest_preg` |
| `commit_entry[i].uop.old_dest_preg` | `RobCommitInst.old_dest_preg` |
| `commit_entry[i].uop.ftq_idx` | `RobCommitInst.ftq_idx` |
| `commit_entry[i].uop.ftq_offset` | `RobCommitInst.ftq_offset` |
| `commit_entry[i].uop.ftq_is_last` | `RobCommitInst.ftq_is_last` |
| `commit_entry[i].uop.mispred` | `RobCommitInst.mispred` |
| `commit_entry[i].uop.br_taken` | `RobCommitInst.br_taken` |
| `commit_entry[i].uop.dest_en` | `RobCommitInst.dest_en` |
| `commit_entry[i].uop.func7` | `RobCommitInst.func7` |
| `commit_entry[i].uop.rob_idx` | `RobCommitInst.rob_idx` |
| `commit_entry[i].uop.rob_flag` | `RobCommitInst.rob_flag` |
| `commit_entry[i].uop.stq_idx` | `RobCommitInst.stq_idx` |
| `commit_entry[i].uop.stq_flag` | `RobCommitInst.stq_flag` |
| `commit_entry[i].uop.page_fault_inst` | `RobCommitInst.page_fault_inst` |
| `commit_entry[i].uop.page_fault_load` | `RobCommitInst.page_fault_load` |
| `commit_entry[i].uop.page_fault_store` | `RobCommitInst.page_fault_store` |
| `commit_entry[i].uop.illegal_inst` | `RobCommitInst.illegal_inst` |
| `commit_entry[i].uop.type` | `decode_inst_type(RobCommitInst.type)` |
| `commit_entry[i].uop.tma` | `RobCommitInst.tma` |
| `commit_entry[i].uop.dbg` | `RobCommitInst.dbg` |
| `commit_entry[i].uop.flush_pipe` | `RobCommitInst.flush_pipe` |

`IO.h` 中 `to_inst_entry(valid)` 的字段转换依据如下：

```cpp
InstEntry to_inst_entry(wire<1> valid) const {
  InstEntry dst;
  dst.valid = valid;
  dst.uop.diag_val = diag_val;
  dst.uop.dest_areg = dest_areg;
  dst.uop.dest_preg = dest_preg;
  dst.uop.old_dest_preg = old_dest_preg;
  dst.uop.ftq_idx = ftq_idx;
  dst.uop.ftq_offset = ftq_offset;
  dst.uop.ftq_is_last = ftq_is_last;
  dst.uop.mispred = mispred;
  dst.uop.br_taken = br_taken;
  dst.uop.dest_en = dest_en;
  dst.uop.func7 = func7;
  dst.uop.rob_idx = rob_idx;
  dst.uop.rob_flag = rob_flag;
  dst.uop.stq_idx = stq_idx;
  dst.uop.stq_flag = stq_flag;
  dst.uop.page_fault_inst = page_fault_inst;
  dst.uop.page_fault_load = page_fault_load;
  dst.uop.page_fault_store = page_fault_store;
  dst.uop.illegal_inst = illegal_inst;
  dst.uop.type = decode_inst_type(type);
  dst.uop.tma = tma;
  dst.uop.dbg = dbg;
  dst.uop.flush_pipe = flush_pipe;
  return dst;
}
```

结论：当前 `commit_entry` 只能视为端口宽度和来源信号已预留，尚未完成 `RobCommitInst -> InstEntry` 的打包实现。

### 4.2 `commit_entry[i].uop.diag_val` 的 flush 覆盖逻辑未具体实现

C++ 中 `commit_entry` 还包含 flush 场景下的特殊覆盖逻辑。若当前 commit entry 有效且本周期发生 flush，则对外输出的 `diag_val` 需要被覆盖为 `redirect_pc`：

```cpp
if (out.commit_entry[i].valid && out.flush) {
  out.commit_entry[i].uop.diag_val = out.redirect_pc;
  rob->out.rob_commit->commit_entry[i].uop.diag_val = out.redirect_pc;
}
```

当前 Verilog 中 `commit_entry` 整包仍为 0，因此该覆盖逻辑也未实现。后续补全字段映射时，还需要对 `diag_val` 增加选择逻辑：

```text
commit_entry[i].uop.diag_val =
    commit_entry[i].valid && flush ? redirect_pc : rob_commit_entry[i].uop.diag_val
```

结论：该项应与 `commit_entry` 字段映射一起补充，否则 flush 场景下提交信息中的 next-PC 可能与 C++ 行为不一致。

### 4.3 restore/checkpoint 对 `flush` 和 `redirect_pc` 的强制输出未具体实现

C++ 除正常 `comb()` 路径外，还有恢复参考模型和恢复 checkpoint 的路径。这两处会直接对 `Back_out.flush` 和 `Back_out.redirect_pc` 赋值：

```cpp
void BackTop::restore_from_ref() {
  ...
  out.flush = true;
  out.redirect_pc = state.pc;
}
```

```cpp
void BackTop::restore_checkpoint(const std::string &filename) {
  ...
  out.flush = true;
  out.redirect_pc = state.pc;
}
```

当前 `back_top.v` 的 `flush` 和 `redirect_pc` 只覆盖正常组合路径：

```verilog
wire flush = rob_out_rob_bcast_flush;
wire [31:0] redirect_pc =
    (!rob_out_rob_bcast_flush) ? idu_out_idu_br_latch_redirect_pc :
    ((rob_out_rob_bcast_mret || rob_out_rob_bcast_sret) ?
        csr_out_csr2front_epc :
     (rob_out_rob_bcast_exception ?
        csr_out_csr2front_trap_pc :
        (rob_out_rob_bcast_pc + 32'd4)));
```

当前顶层没有 `restore_valid`、`restore_pc` 或 checkpoint/ref restore 相关输入，因此无法表达 C++ 中这条仿真恢复输出路径。

结论：若 RTL top 也需要覆盖模拟器恢复/refetch 行为，需要新增恢复相关输入；若本阶段只描述硬件主线连接，则该路径可标记为仿真辅助路径，不进入当前 RTL top。

### 4.4 MMU/DTLB 到 LSU 的返回路径当前置空

C++ 中 LSU 与 MMU/DTLB 存在真实交互。`comb_lsu_mmu()` 根据 LSU 发出的 `lsu2mmu_io.ldq_req/stq_req` 做地址翻译，并将结果写回 `mmu2lsu_io.ldq_resp/stq_resp`：

```cpp
void BackTop::comb_lsu_mmu() {
  mmu2lsu_io = {};
  if (dtlb_mmu == nullptr) {
    return;
  }

  if (rob_bcast.fence) {
    dtlb_mmu->flush();
    return;
  }
  if (rob_bcast.flush || dec_bcast.mispred) {
    dtlb_mmu->cancel_pending_walk();
    return;
  }

  auto translate = [&](const MMUReq &req, MMUResp &resp, uint32_t type) {
    if (!req.valid) {
      return;
    }
    uint32_t paddr = 0;
    const TlbMmu::Result result =
        dtlb_mmu->translate(paddr, req.vaddr, type, &lsu2mmu_io.csr_status);
    resp.valid = true;
    resp.result = to_lsu_mmu_result(result);
    resp.paddr = result == TlbMmu::Result::OK ? paddr : 0;
  };

  for (int i = 0; i < LSU_LDU_COUNT; i++) {
    translate(lsu2mmu_io.ldq_req[i], mmu2lsu_io.ldq_resp[i], 1);
  }
  for (int i = 0; i < LSU_STA_COUNT; i++) {
    translate(lsu2mmu_io.stq_req[i], mmu2lsu_io.stq_resp[i], 2);
  }
}
```

当前 Verilog 中 MMU 暂作为空边界保留，`mmu2lsu_io` 直接置 0：

```verilog
assign mmu2lsu_io = {W_MMULsuIO{1'b0}};
```

该项不直接属于 `Back_out` 字段，但会影响 LSU 最终对外输出：

| 被影响的外部字段 | 影响原因 |
|---|---|
| `Back_out.lsu2dcache` | DCache 请求可能依赖地址翻译结果、page fault 结果或取消结果。 |
| `Back_out.peripheral_req` | MMIO/访存请求是否继续发出，可能依赖 LSU 内部地址与异常判断。 |

当前未具体实现的 MMU/DTLB 返回字段如下：

| 当前置空字段 | C++ 真实来源 |
|---|---|
| `mmu2lsu_io.ldq_resp[i].valid` | `translate(lsu2mmu_io.ldq_req[i], ...)` |
| `mmu2lsu_io.ldq_resp[i].paddr` | `dtlb_mmu->translate(...)` 的物理地址结果 |
| `mmu2lsu_io.ldq_resp[i].result` | `to_lsu_mmu_result(result)` |
| `mmu2lsu_io.stq_resp[i].valid` | `translate(lsu2mmu_io.stq_req[i], ...)` |
| `mmu2lsu_io.stq_resp[i].paddr` | `dtlb_mmu->translate(...)` 的物理地址结果 |
| `mmu2lsu_io.stq_resp[i].result` | `to_lsu_mmu_result(result)` |

结论：若当前阶段继续按“只保留十个后端模块，MMU 暂置空”的要求处理，则该项属于已知占位；若要求完全对齐 `BackTop.cpp` 行为，则后续需要补充 MMU/DTLB 返回路径。

## 5. 已连接但依赖 BSD 具体实现的外部输出

`peripheral_req` 和 `lsu2dcache` 在总 top 中已经接入 LSU wrapper，对应 C++ 连接如下：

```cpp
lsu->out.peripheral_req = &out.peripheral_req;
lsu->out.lsu2dcache = &out.lsu2dcache;
```

当前 Verilog 对应如下：

```verilog
lsu_top lsu (
    ...
    .peripheral_req(lsu_out_peripheral_req),
    .lsu2dcache(lsu_out_lsu2dcache),
    ...
);

assign Back_out =
    {mispred, stall, flush, fence_i, itlb_flush, fire, redirect_pc,
     commit_entry, sstatus, mstatus, satp, privilege,
     lsu_out_peripheral_req, lsu_out_lsu2dcache};
```

因此这两项不是总 top 漏接，而是需要等待 LSU 内部 `lsu_bsd_top` 或相关 slice 生成具体字段：

| 字段 | 当前状态 |
|---|---|
| `peripheral_req` | 总 top 已接 LSU 输出；具体 `is_mmio/wen/mmio_addr/mmio_wdata/mmio_fun3` 由 LSU BSD 实现。 |
| `lsu2dcache` | 总 top 已接 LSU 输出；具体 `req_ports/icache_req` 由 LSU BSD 实现。 |

## 6. 待确认事项

| 序号 | 待确认问题 | 影响范围 |
|---|---|---|
| 1 | `commit_entry` 的 `RobCommitInst -> InstEntry` 打包逻辑是否由 ROB wrapper 完成，还是由后续 ROB slice/BSD 提供。 | `Back_out.commit_entry` |
| 2 | `decode_inst_type(type)` 这类 C++ 枚举转换是否需要在当前 Verilog top 中显式展开。 | `commit_entry[i].uop.type` |
| 3 | flush 时 `commit_entry[i].uop.diag_val = redirect_pc` 是否要求当前阶段同步实现。 | Difftest/提交信息 |
| 4 | `restore_from_ref/restore_checkpoint` 属于仿真辅助流程还是也需要进入 RTL top 接口。 | `flush`、`redirect_pc` |
| 5 | MMU/DTLB 返回路径是否继续按当前要求置空，还是需要补为独立模块或 LSU 内部逻辑。 | `mmu2lsu_io`、`lsu2dcache`、`peripheral_req` |
| 6 | `stall` 在 flush 周期是否需要严格保持 C++ 的“仅非 flush 分支赋值”语义。 | `Back_out.stall` |

## 7. 检查结论

当前 `Back_out` 大部分控制类输出已经在 `back_top.v` 中有明确来源，包括 `fire`、`mispred`、`flush`、`fence_i`、`itlb_flush`、`redirect_pc`、CSR 状态字段等。

当前主要未具体实现内容集中在四类：

| 序号 | 未具体实现内容 | 涉及字段 |
|---|---|---|
| 1 | `RobCommitInst -> InstEntry` 转换未实现，当前为全 0 占位。 | `commit_entry` |
| 2 | flush 时 `diag_val` 覆盖为 `redirect_pc` 的逻辑未实现。 | `commit_entry[i].uop.diag_val` |
| 3 | restore/checkpoint 强制输出 `flush/redirect_pc` 的仿真恢复路径未进入当前 Verilog top。 | `flush`、`redirect_pc` |
| 4 | MMU/DTLB 到 LSU 的返回路径当前置空，可能间接影响 LSU 对外访存输出。 | `mmu2lsu_io`、`lsu2dcache`、`peripheral_req` |

总体结论：当前 Verilog 已完成 `Back_out` 主要外部输出端口的结构连接，但仍存在上述未具体实现或待确认路径。后续补全时应优先处理 `commit_entry` 打包与 flush 覆盖逻辑，其次根据最终要求决定是否加入 restore/checkpoint 和 MMU/DTLB 相关路径。
