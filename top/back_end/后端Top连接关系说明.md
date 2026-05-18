# 后端 Top 连接关系说明

本文说明 `top/back_end/back_top.v` 的当前交付版。源码依据统一使用：

```text
simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0
```

## 1. 交付范围

后端顶层只展开一级模块连接，不展开模块内部寄存器、RAM、队列和具体功能逻辑。模块内部后续由各组员在 `slices/` 中补具体实现。

当前保留 10 个后端一级模块：

```text
preiduqueue / idu / ren / dispatch / isu / prf / exu / rob / csr / lsu
```

## 2. ff 接口修正

ff 版本与旧版模拟器最大差异之一是：

| 字段 | ff 状态 | 依据 |
|---|---|---|
| `front_top_out.commit_stall` | 不存在 | `front-end/front_IO.h:42-64` |
| `FrontPreIO.front_stall` | 不存在 | `back-end/include/IO.h:108-159` |
| `RobIn.front_stall` | 不存在 | `back-end/include/Rob.h` |

因此当前 `back_top.v` 不再接收旧的 packed `front2pre` 总包作为唯一端口，而是先把 `FrontPreIO` 字段拆成可读端口，再在 `back_top.v` 内部重新打包给 `preiduqueue_top`。

## 3. 顶层输入输出

`back_top.v` 对外输入：

| 输入 | 说明 |
|---|---|
| `front2pre_inst/pc/valid` | 前端送来的指令、PC、有效位 |
| `front2pre_predict_dir` | 预测方向 |
| `front2pre_alt_pred/altpcpn/pcpn` | BPU 方向预测元信息 |
| `front2pre_predict_next_fetch_address` | 下一取指地址，按 lane 展开 |
| `front2pre_tage_idx/tage_tag` | TAGE 元信息 |
| `front2pre_sc_*` | SC 元信息 |
| `front2pre_loop_*` | loop predictor 元信息 |
| `front2pre_page_fault_inst` | 前端取指页异常位 |
| `peripheral_resp` | 外设响应到 LSU |
| `dcache2lsu` | DCache 响应到 LSU |
| `mmu2lsu_io` | MMU/DTLB 响应到 LSU |

`back_top.v` 对外输出：

| 输出 | 来源 |
|---|---|
| `mispred` | 正常来自 IDU，flush 时置 1 |
| `stall` | `~pre2front.ready` |
| `flush` | ROB broadcast |
| `fence_i/itlb_flush` | ROB broadcast |
| `fire` | PreIduQueue 返回前端的消费信息 |
| `redirect_pc` | 非 flush 来自 IDU；flush 时在 CSR/ROB 路径中选择 |
| `commit_entry` | 由 `rob_commit` 在 `back_top.v` 中重新打包 |
| `sstatus/mstatus/satp/privilege` | CSR 状态 |
| `peripheral_req/lsu2dcache/lsu2mmu_io` | LSU 外部接口 |

## 4. 后端组合调用顺序

源码依据是 `simulator-ffc.../back-end/BackTop.cpp:169-433`。主要顺序如下：

1. `comb_begin()` 清各模块本拍组合输出。
2. `pre->comb_accept_front()` 接收前端 `FrontPreIO`。
3. `idu->comb_decode()` 解码。
4. `csr->comb_interrupt()`、`rename->comb_alloc()`、`prf->comb_complete/awake/write()`、`isu->comb_ready()`、`lsu->comb_cal()`。
5. `idu->comb_branch()` 生成分支广播。
6. `rob->comb_ready()`、`rob/exu` 发 FTQ PC 请求，`pre->comb_ftq_lookup()` 返回查表结果。
7. `rob->comb_commit()`、`dis->comb_alloc()`、`lsu->comb_load_res()`。
8. `exu/csr/rob` 执行、完成、异常与 CSR 写。
9. `isu->comb_issue()`、`prf->comb_read()`、`rename->comb_rename()`、`dis->comb_dispatch()`。
10. 组装 `Back_out`：`flush/mispred/stall/redirect_pc/commit_entry`。
11. 周期后段执行 `comb_fire/comb_flush/comb_pipeline`，为时序写回准备 next-state。

讲解时重点是：后端也是先组合计算，再在 `BackTop::seq()` 中统一时序更新。

## 5. 一级模块连线

| 来源 | 信号 | 去向 |
|---|---|---|
| 外部前端 | `front2pre` 内部总包 | `preiduqueue_top` |
| `preiduqueue_top` | `pre_issue` | `idu_top` |
| `idu_top` | `idu_consume`、`idu_br_latch` | `preiduqueue_top` |
| `idu_top` | `dec2ren` | `ren_top` |
| `idu_top` | `dec_bcast` | `ren/dispatch/isu/prf/exu/rob/lsu` |
| `ren_top` | `ren2dec` | `idu_top` |
| `ren_top` | `ren2dis` | `dispatch_top` |
| `dispatch_top` | `dis2ren/dis2iss/dis2rob/dis2lsu` | `ren/isu/rob/lsu` |
| `isu_top` | `iss2dis/iss2prf/iss_awake` | `dispatch/prf/dispatch+isu` |
| `prf_top` | `prf2exe/prf_awake/ftq_prf_pc_req` | `exu/dispatch+isu/preiduqueue` |
| `preiduqueue_top` | `ftq_prf_pc_resp` | `prf_top` |
| `exu_top` | `exe2prf/exe2iss/exe2csr/exe2lsu/exu2id/exu2rob` | `prf/isu/csr/lsu/idu/rob` |
| `rob_top` | `rob_bcast/rob_commit/rob2dis/rob2csr` | 多模块广播、commit、dispatch、CSR |
| `csr_top` | `csr2exe/csr2rob/csr2front/csr_status` | `exu/rob/back_top/exu+lsu+back_top` |
| `lsu_top` | `lsu2exe/lsu2dis/lsu2rob/peripheral_req/lsu2dcache/lsu2mmu_io` | `exu/dispatch/rob/外部` |

## 6. 位宽口径

本次后端参数已按 ff 生效配置对齐：

| 参数 | 当前值 |
|---|---:|
| `PRF_IDX_WIDTH` | 11 |
| `ROB_IDX_WIDTH` | 11 |
| `STQ_IDX_WIDTH` | 9 |
| `LDQ_IDX_WIDTH` | 9 |
| `FTQ_IDX_WIDTH` | 8 |
| `IQ_READY_NUM_WIDTH` | 11 |
| `MAX_WAKEUP_PORTS` | 16 |
| `ISSUE_WIDTH` | 24 |
| `TOTAL_FU_COUNT` | 30 |
| `LSU_LOAD_WB_WIDTH` | 4 |
| `W_STQ_COUNT/W_LDQ_COUNT` | 10 / 10 |

这些值来自 `simulator-ffc.../include/config.h`，不是 `config.h.large`。

## 7. HTML

交互说明页保留在：

```text
top/back_end/back_top_interactive.html
```

其中代码依据应按 ff 路径理解，核心入口是：

```text
simulator-ffc.../back-end/BackTop.cpp:39
simulator-ffc.../back-end/BackTop.cpp:169-433
simulator-ffc.../rv_simu_mmu_v2.cpp:675-695
```
