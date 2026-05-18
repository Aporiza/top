# 后端 Back_out 输出路径检查

本文件保留为检查记录，详细连接关系已融合到 `后端Top连接关系说明.md` 和 `back_top_interactive.html`。

## 检查结论

当前 `back_top.v` 中主要对外输出已经有明确来源：

| 输出 | 当前来源 |
|---|---|
| `mispred` | flush 时置 1，否则来自 `idu_top.dec_bcast_mispred` |
| `stall` | `~preiduqueue_out_pre2front_ready` |
| `flush` | `rob_top.rob_bcast_flush` |
| `fence_i` | `rob_top.rob_bcast_fence_i` |
| `itlb_flush` | `rob_top.rob_bcast_fence` |
| `fire` | `preiduqueue_top.pre2front_fire` |
| `redirect_pc` | 非 flush 来自 IDU；flush 时在 CSR epc、CSR trap_pc、ROB pc+4 中选择 |
| `commit_entry` | 由 `rob_commit` 拆字段后重新打包 |
| `sstatus/mstatus/satp/privilege` | `csr_top.csr_status` |
| `peripheral_req` | `lsu_top.peripheral_req` |
| `lsu2dcache` | `lsu_top.lsu2dcache` |
| `lsu2mmu_io` | `lsu_top.lsu2mmu_io` |

## ff 版本注意点

本次接口按 `simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/include/config.h`，不是 `config.h.large`。

`FrontPreIO` 不包含 `front_stall`，`front_top_out` 不包含 `commit_stall`，所以这两个旧字段不进入后端输入总线，也不进入 ROB 输入。

## 源码依据

```text
simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/back-end/include/BackTop.h
simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/back-end/BackTop.cpp:169-433
simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0/rv_simu_mmu_v2.cpp:675-695
```
