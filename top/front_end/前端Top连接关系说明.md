# 前端 Top 连接关系说明

## 1. 交付口径

本版前端说明按照老板/学长最新要求，采用 **comb 训练单元口径** 说明前端 top 连接关系。

需要区分两个层级：

| 层级 | 含义 | 当前用途 |
|---|---|---|
| RTL wrapper 层 | `front_top.v` 中例化的一级 wrapper，例如 `bpu_top`、`ptab_top`、`front2back_fifo_top` | 表达顶层端口打包和一级模块边界 |
| comb 训练单元层 | `TRAINING_FUNCTION_LIST.md` 中列出的 `*_comb` 函数，例如 `front_global_control_comb`、`bpu_predict_main_comb`、`PTAB_comb` | 表达老板截图中二十多个模块之间的细化连接关系 |

因此，之前“前端 8 个模块”的说法只对应 wrapper 层；本次 HTML 与说明文档重点使用 27 个正式 comb 训练单元口径。Oracle、2-Ahead/NLP、ICache slot1 和两个 bypass 分支只保留源码依据，不再单独展开为模块。

交互式图文件：

```text
top/front_end/front_top_interactive.html
```

HTML 右侧详情面板已按模块、连线和路径三类补充源码依据。点击任意连线时，会显示该连接对应的 `simulator-new/...:line` 原始实现位置，便于直接和 `front_top.cpp`、`rv_simu_mmu_v2.cpp`、BPU/FIFO/PTAB/predecode/checker 源码对照。

## 2. 主要依据

本版依据新版模拟器仓库：

```text
simulator-new/front-end/TRAINING_FUNCTION_LIST.md
simulator-new/front-end/front_top.cpp
simulator-new/front-end/front_IO.h
simulator-new/front-end/front_module.h
simulator-new/front-end/BPU/BPU.h
simulator-new/front-end/BPU/type_predictor/TypePredictor.h
simulator-new/front-end/BPU/dir_predictor/TAGE_top.h
simulator-new/front-end/BPU/target_predictor/BTB_top.h
simulator-new/front-end/fifo/*.cpp
simulator-new/front-end/predecode.cpp
simulator-new/front-end/predecode_checker.cpp
```

其中 `TRAINING_FUNCTION_LIST.md` 按 27 个正式 comb 单元作为训练边界；`bpu_nlp_comb` 与宏控制分支仅作为默认关闭/参考路径说明，不计入正式模块数。

### 2.1 27 个正式 comb 口径

本前端包以 `SimCpu::front_cycle()` 的执行顺序作为函数运行顺序标准：`CONFIG_BPU` 打开时走 `FrontTop::step_bpu()` / `front_top()`；`CONFIG_BPU` 未走硬件 BPU 时走 Oracle `step_oracle()`。HTML 主图只展示 27 个正式 comb，默认关闭分支和 Oracle 只在说明/依据中保留。

当前默认配置下的处理：

| 分支 | 默认配置状态 | 前端包处理 |
|---|---|---|
| `CONFIG_BPU` 主路径 | 打开 | HTML 和 `.v` 主线保留真实 BPU/front_top 路径 |
| Oracle `step_oracle()` | `CONFIG_BPU` 关闭时进入 | 不进入 27 模块图；只作为模拟器参考分支说明 |
| `ENABLE_2AHEAD` / NLP | 默认被 `FRONTEND_DISABLE_2AHEAD` 关闭 | `bpu_nlp_comb` 不计入 27 个正式模块；如后续打开需重新导出训练 IO |
| ICache slot1 | 默认 `FRONTEND_IDEAL_ICACHE_DUAL_REQ_ACTIVE=0` | 不进入 27 模块图；如后续打开需确认 FIFO 双读/双写 RTL |
| fetch-to-ICache bypass | 默认显式为 `0` | 不进入 27 模块图；只保留开关依据 |
| ICache-to-predecode bypass | 默认显式为 `0` | 不进入 27 模块图；只保留开关依据 |

## 3. 前端 comb 单元清单

| # | comb 单元 | 所属模块 | 主要作用 |
|---|---|---|---|
| 1 | `fetch_address_FIFO_comb` | `fetch_address_FIFO` | 缓存 BPU 产生的取指地址 |
| 2 | `instruction_FIFO_comb` | `instruction_FIFO` | 缓存指令组、PC、有效位、异常位和预解码结果 |
| 3 | `PTAB_comb` | `PTAB` | 缓存预测方向、下一取指地址、base PC 和训练元信息 |
| 4 | `front2back_FIFO_comb` | `front2back_FIFO` | 缓存并输出最终前端包 |
| 5 | `predecode_comb` | `predecode` | 根据指令生成预解码类型和目标地址 |
| 6 | `predecode_checker_comb` | `predecode_checker` | 修正预测方向和下一取指地址，必要时发出 flush |
| 7 | `TypePredictor::pre_read_comb` | `TypePredictor` | 类型预测器预读阶段 |
| 8 | `type_pred_comb` | `TypePredictor` | 类型预测组合计算 |
| 9 | `tage_pre_read_comb` | `TAGE_TOP` | TAGE 预读阶段 |
| 10 | `tage_comb` | `TAGE_TOP` | TAGE 方向预测组合计算 |
| 11 | `btb_pre_read_comb` | `BTB_TOP` | BTB 预读阶段 |
| 12 | `btb_post_read_req_comb` | `BTB_TOP` | BTB 后读请求整理 |
| 13 | `btb_comb` | `BTB_TOP` | BTB 目标预测组合计算 |
| 14 | `bpu_predict_main_comb` | `BPU_TOP` | BPU 主预测输出生成 |
| 15 | `bpu_hist_comb` | `BPU_TOP` | BPU 历史状态更新 |
| 16 | `bpu_queue_comb` | `BPU_TOP` | BPU 更新队列和回压状态 |
| 17 | `bpu_pre_read_req_comb` | `BPU_TOP` | BPU 子模块预读请求生成 |
| 18 | `bpu_post_read_req_comb` | `BPU_TOP` | BPU 子模块后读信息整理 |
| 19 | `bpu_submodule_bind_comb` | `BPU_TOP` | 汇总 Type/TAGE/BTB 子模块结果 |
| 20 | `front_global_control_comb` | `front_top` | 合并后端 refetch 与前端 checker flush |
| 21 | `front_read_enable_comb` | `front_top` | 生成各 FIFO/PTAB 读使能 |
| 22 | `front_read_stage_input_comb` | `front_top` | 生成读阶段各模块输入 |
| 23 | `front_bpu_control_comb` | `front_top` | 生成 BPU 输入和 BPU stall/can_run |
| 24 | `front_ptab_write_comb` | `front_top` | 将 BPU 预测输出整理为 PTAB 写入包 |
| 25 | `front_checker_input_comb` | `front_top` | 将 instruction FIFO 与 PTAB 输出整理为 checker 输入 |
| 26 | `front_front2back_write_comb` | `front_top` | 汇总指令、预测、checker 结果并写入 front2back FIFO |
| 27 | `front_output_comb` | `front_top` | 生成最终 `front_top_out` |

## 4. bpu_hist 展开说明

`TRAINING_FUNCTION_LIST.md` 正式清单中保留的是：

```text
bpu_hist_comb
```

学长截图中的：

```text
bpu_hist_commit_ctrl_comb
bpu_hist_pred_ctrl_comb
bpu_hist_ras_step_comb
bpu_hist_step_comb
```

属于 `bpu_hist_comb` 的生成细分子块。本次 HTML 图中不再将这些子块挂成独立模块，只在 `bpu_hist_comb` 的源码依据里说明。

## 5. comb 连接主线

### 5.1 全局控制路径

```text
front_top_in
  -> front_global_control_comb
  -> front_read_enable_comb
  -> front_read_stage_input_comb
```

含义：

- `front_global_control_comb` 合并后端 `refetch` 与上一拍 checker 写回的 `predecode_refetch_snapshot`。
- `front_read_enable_comb` 在 `USE_TRUE_ICACHE` 路径下先依赖 ICache `peek_ready`，再根据 FIFO/PTAB/front2back 状态生成读使能。
- `front_read_stage_input_comb` 将这些控制拆到 fetch address FIFO、instruction FIFO、PTAB、front2back FIFO。

### 5.2 BPU 预测内部路径

```text
front_bpu_control_comb
  -> bpu_pre_read_req_comb
  -> TypePredictor::pre_read_comb
  -> type_pred_comb
  -> bpu_submodule_bind_comb
  -> bpu_predict_main_comb
```

同时还有：

```text
bpu_pre_read_req_comb
  -> tage_pre_read_comb
  -> tage_comb
  -> bpu_submodule_bind_comb
```

以及：

```text
bpu_pre_read_req_comb
  -> btb_pre_read_comb
  -> btb_post_read_req_comb
  -> btb_comb
  -> bpu_submodule_bind_comb
```

含义：

- TypePredictor 负责类型预测。
- TAGE 负责方向预测。
- BTB 负责目标地址预测。
- `bpu_submodule_bind_comb` 将这些预测子模块结果汇总。
- `bpu_predict_main_comb` 生成最终 BPU 预测输出。

### 5.3 取指路径

```text
bpu_predict_main_comb
  -> fetch_address_FIFO_comb
  -> predecode_comb
  -> instruction_FIFO_comb
```

说明：

- `bpu_predict_main_comb` 产生取指地址。
- `fetch_address_FIFO_comb` 缓存取指地址；fetch-to-ICache bypass 也在 HTML 和 `.v` 中作为独立训练分支展开。
- ICache 主线采用 slot0 路径；slot1 双请求和 ICache-to-predecode bypass 已作为独立路径展开，图中点击对应连线可以查看 `front_top.cpp` 源码依据。
- `predecode_comb` 处理取回指令。
- `instruction_FIFO_comb` 缓存指令、PC、有效位、异常位和预解码结果。

### 5.4 PTAB 预测信息路径

```text
bpu_predict_main_comb
  -> front_ptab_write_comb
  -> PTAB_comb
```

说明：

- `front_ptab_write_comb` 将 BPU 预测方向、下一取指地址、base PC 和训练元信息整理成 PTAB 写入包。
- `PTAB_comb` 缓存预测上下文，等待与 instruction FIFO 的指令流重新对齐。

### 5.5 checker 修正路径

```text
instruction_FIFO_comb
  -> front_checker_input_comb
PTAB_comb
  -> front_checker_input_comb
front_checker_input_comb
  -> predecode_checker_comb
predecode_checker_comb
  -> front_global_control_comb
```

说明：

- `instruction_FIFO_comb` 提供预解码侧信息。
- `PTAB_comb` 提供预测侧信息。
- `predecode_checker_comb` 比较两侧结果，输出修正后的预测方向和下一取指地址。
- 当修正后的下一取指地址与原预测不一致时，checker flush 回到全局控制路径。

### 5.6 前端输出路径

```text
instruction_FIFO_comb
PTAB_comb
predecode_checker_comb
  -> front_front2back_write_comb
  -> front2back_FIFO_comb
  -> front_output_comb
  -> front_top_out
```

说明：

- 指令、PC、异常位、有效位来自 instruction FIFO。
- 预测 base PC 与训练元信息来自 PTAB。
- 修正后的预测方向和下一取指地址来自 checker。
- `front_front2back_write_comb` 将三路信息汇总。
- `front2back_FIFO_comb` 缓冲最终前端输出包。
- `front_output_comb` 生成最终 `front_top_out`。

## 6. 与 RTL wrapper 层的对应关系

| comb 口径 | RTL wrapper 口径 |
|---|---|
| `bpu_pre_read_req_comb`、`bpu_post_read_req_comb`、`bpu_submodule_bind_comb`、`bpu_predict_main_comb`、`bpu_hist_comb`、`bpu_queue_comb`、Type/TAGE/BTB 相关 comb | `bpu_top` |
| `fetch_address_FIFO_comb` | `fetch_address_fifo_top` |
| ICache 取指返回路径 | `icache_top`，但 ICache 内部未列入当前训练清单 |
| `predecode_comb` | `predecode_top` |
| `instruction_FIFO_comb` | `instruction_fifo_top` |
| `PTAB_comb` | `ptab_top` |
| `predecode_checker_comb` | `predecode_checker_top` |
| `front2back_FIFO_comb` | `front2back_fifo_top` |
| `front_global_control_comb` 等 `front_*_comb` 胶水逻辑 | `front_top.v` 顶层组合胶水 |

## 7. 当前交付文件

```text
top/front_end/front_top.v
top/front_end/front_top_interactive.html
top/front_end/前端交互式Top图说明.md
top/front_end/前端Top连接关系说明.md
top/front_end/前端Top模块连接示意图.md
top/front_end/前端输出路径检查报告.md
```

其中：

- `front_top.v` 表达 RTL wrapper 层连接骨架。
- `front_top_interactive.html` 表达老板要求的 comb 训练单元层交互拓扑图，并在模块、连线、路径详情中展示源码依据。
- 本文档解释两种层级之间的对应关系和当前主要数据路径。

## 8. 汇报用结论

前端 top 现在按两层理解：

- 外层是 8 个 RTL wrapper，用来组织端口打包和模块边界。
- 内层展开为 27 个正式训练 comb 单元，用来表达老板截图中需要看的细粒度 top 连接。

数据流上，BPU 内部预测结果一边进入取指路径，一边写入 PTAB 预测上下文；取指返回后的指令流进入 instruction FIFO，预测流进入 PTAB，二者在 checker 处对齐并修正，最后由 front2back FIFO 和 `front_output_comb` 输出给后端。
