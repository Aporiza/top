# 前端 front_top 阅读入口

本文档顺着一条主线说明：

```text
代码怎么进入 front_top
front_top 内先执行哪些组合逻辑
组合逻辑如何只生成 next 请求
最后在哪里统一更新寄存器 / FIFO / RAM / 预测表状态
```

## 1. 先看哪几个 HTML

| 文件 | 用途 |
|---|---|
| `top/front_end/front_top_execution_flow.html` | 新版主入口。按一拍执行顺序平铺：入口、`front_seq_read`、13 个组合阶段、`front_seq_write`。适合第一次读代码或给老板/学长解释流程。 |
| `top/front_end/front_oracle_execution_flow.html` | Oracle 参考路径说明。只在 `CONFIG_BPU` 关闭时进入，不走 `front_top()` 三段式，而是 `front_cycle -> step_oracle -> get_oracle`。 |
| `top/front_end/front_top_interactive.html` | 旧版拓扑参考图。保留 27 个正式 comb 模块、连线和路径高亮，用来查模块之间的数据关系。 |

后续汇报建议优先打开 `front_top_execution_flow.html`。旧图不删除，是因为它仍适合查“这根线连接哪些模块”。

## 2. 一拍执行主线

默认 `CONFIG_BPU` 打开时，前端硬件主路径是：

```text
SimCpu::front_cycle()
  -> FrontTop::step_bpu()
    -> front_top(&in, &out)
      -> front_seq_read()
      -> front_comb_calc()
      -> front_seq_write()
```

| 顺序 | 函数 | 源码依据 | 做什么 |
|---|---|---|---|
| 1 | `SimCpu::front_cycle()` | `simulator-new/rv_simu_mmu_v2.cpp:652-684` | 每拍由 CPU 顶层进入前端，写 `front.in.FIFO_read_enable/refetch/refetch_address/...`，然后调用 `front.step_bpu()`。 |
| 2 | `FrontTop::step_bpu()` | `simulator-new/front-end/FrontTop.cpp:36-38` | 同步 ICache/PTW 运行时端口后，调用 `front_top(&in, &out)`。 |
| 3 | `front_top()` | `simulator-new/front-end/front_top.cpp:2068-2077` | 创建 `FrontReadData rd` 和 `FrontUpdateRequest req`，然后固定执行 `front_seq_read -> front_comb_calc -> front_seq_write`。 |
| 4 | `front_seq_read()` | `simulator-new/front-end/front_top.cpp:1997-2030` | 读取上一拍寄存器/FIFO/RAM/ICache 快照。这里读到的是旧状态。 |
| 5 | `front_comb_calc()` | `simulator-new/front-end/front_top.cpp:1002-1969` | 按固定顺序执行本拍组合逻辑，只生成 `out` 和 `req`，不直接提交状态。 |
| 6 | `front_seq_write()` | `simulator-new/front-end/front_top.cpp:2034-2062` | 周期末统一提交 BPU、FIFO、PTAB、ICache 和 `front_top` 本地状态。 |



`front_top()` 一拍内先通过 `front_seq_read()` 读旧状态，再在 `front_comb_calc()` 中按阶段顺序执行组合逻辑，所有组合逻辑只产生 `FrontUpdateRequest req` 和本拍输出，最后由 `front_seq_write()` 统一写回寄存器、FIFO、RAM 和预测表。

## 3. front_seq_read 读了什么

`front_seq_read()` 先读取 `front_top` 本地状态：

| 状态 | 含义 | 源码 |
|---|---|---|
| `predecode_refetch` | 上一拍 checker flush 延迟到本拍的 refetch 标志 | `front_top.cpp:1999` |
| `predecode_refetch_address` | 上一拍 checker 修正后的 next PC | `front_top.cpp:2000` |
| `front_sim_time` / `front_stats` | 前端统计状态 | `front_top.cpp:2001-2002` |
| `fetch_addr_fifo_full/empty_latch` | fetch address FIFO 上一拍满/空状态位 | `front_top.cpp:2003-2004` |
| `fifo_full/empty_latch` | instruction FIFO 上一拍满/空状态位 | `front_top.cpp:2005-2006` |
| `ptab_full/empty_latch` | PTAB 上一拍满/空状态位 | `front_top.cpp:2007-2008` |
| `front2back_fifo_full/empty_latch` | front2back FIFO 上一拍满/空状态位 | `front_top.cpp:2009-2010` |

然后读取子模块：

| 子模块 | 读接口 | 源码 |
|---|---|---|
| fetch address FIFO | `fetch_address_FIFO_seq_read()` | `front_top.cpp:2026` |
| instruction FIFO | `instruction_FIFO_seq_read()` | `front_top.cpp:2027` |
| PTAB | `PTAB_seq_read()` | `front_top.cpp:2028` |
| front2back FIFO | `front2back_FIFO_seq_read()` | `front_top.cpp:2029` |
| ICache | `icache_seq_read()` | `front_top.cpp:2030` |

注意：源码变量名里带 `latch`，这里汇报时建议说“上一拍状态寄存器快照”或“状态位”，不要理解成透明 latch。

## 4. front_comb_calc 组合逻辑顺序

`front_comb_calc()` 是本拍组合调度层。它用 `front_seq_read()` 给出的旧状态快照计算本拍输出和 next 请求。

| 阶段 | 组合逻辑 | 源码依据 | 作用 |
|---|---|---|---|
| 0 | 初始化临时结构 | `front_top.cpp:1029-1084` | 清空本拍临时输入输出，复制 FIFO/PTAB read snapshot。 |
| 1 | `front_global_control_comb` | `front_top.cpp:1092-1102` | 合并 reset、后端 refetch、上一拍 checker refetch。 |
| 2 | `icache_peek_ready` + `front_read_enable_comb` | `front_top.cpp:1139-1162` | 先看 ICache ready，再决定 fetch FIFO、instruction FIFO、PTAB、front2back FIFO 的读使能。 |
| 3 | `front_read_stage_input_comb` + FIFO/PTAB/front2back 读 comb | `front_top.cpp:1187-1263` | 把读使能下发到各 FIFO/PTAB，并保存读出的包。 |
| 4 | `front_bpu_control_comb` + `bpu_seq_read` + `bpu_comb_calc` | `front_top.cpp:1290-1357` | 生成 BPU 输入，读 BPU 状态，执行 BPU 预测组合逻辑。 |
| 5 | `fetch_address_FIFO_comb_calc` 写 | `front_top.cpp:1383-1424` | 将 BPU 产生的取指地址写入 fetch address FIFO。 |
| 6 | `icache_comb_calc` | `front_top.cpp:1434-1476` | 用 fetch FIFO 输出或旁路地址访问 ICache。 |
| 7 | `predecode_comb` + `instruction_FIFO_comb_calc` | `front_top.cpp:1528-1680` | ICache 返回后预解码，并写入 instruction FIFO。 |
| 8 | `front_ptab_write_comb` + `PTAB_comb_calc` | `front_top.cpp:1697-1707` | 将 BPU 预测方向、next PC、base PC、训练元信息写入 PTAB。 |
| 9 | `front_checker_input_comb` + `predecode_checker_comb` | `front_top.cpp:1719-1744` | 对齐 instruction FIFO 和 PTAB，检查预测是否需要 flush。 |
| 10 | `front_front2back_write_comb` + `front2back_FIFO_comb_calc` | `front_top.cpp:1749-1797` | 汇总指令、预测、checker 修正结果，写入 front2back FIFO。 |
| 11 | flush 状态请求生成 | `front_top.cpp:1802-1816` | checker flush 时向 ICache 发 invalidate-only 请求，并设置下一拍 `predecode_refetch`。 |
| 12 | `front_output_comb` | `front_top.cpp:1822-1841` | 刷新 FIFO full/empty next 状态，生成最终 `front_top_out`。 |

这里要抓住一个核心点：这些阶段都还在组合逻辑里。它们可以写 `req.fetch_addr_fifo_req`、`req.ptab_req`、`req.front_state.next_*`，但不直接改寄存器本体。

## 5. front_seq_write 统一写回

真正改变状态的位置集中在 `front_seq_write()`：

| 写回对象 | 写回代码 | 源码 |
|---|---|---|
| BPU 内部寄存器、队列、预测表 | `bpu_instance.bpu_seq_write(...)` | `front_top.cpp:2040-2042` |
| fetch address FIFO | `fetch_address_FIFO_seq_write(...)` | `front_top.cpp:2043` |
| instruction FIFO | `instruction_FIFO_seq_write(...)` | `front_top.cpp:2044` |
| PTAB | `PTAB_seq_write(...)` | `front_top.cpp:2045` |
| front2back FIFO | `front2back_FIFO_seq_write(...)` | `front_top.cpp:2046` |
| predecode checker | `predecode_checker_seq_write()` | `front_top.cpp:2047` |
| ICache | `icache_seq_write()` | `front_top.cpp:2048` |
| `front_top` 本地状态 | `front_sim_time/front_stats/predecode_refetch/FIFO full-empty 状态位` | `front_top.cpp:2050-2062` |

所以时序/组合分离可以这样讲：

```text
seq_read 读旧值
comb_calc 只算 next
seq_write 才统一提交 next
```

## 6. 寄存器、RAM、FIFO 在哪里

| 类型 | 位置 | 说明 |
|---|---|---|
| `front_top` 本地状态寄存器 | `simulator-new/front-end/front_top.cpp:25-37` | `predecode_refetch`、`predecode_refetch_address`、FIFO full/empty 状态位、统计状态。 |
| BPU 寄存器/队列 | `simulator-new/front-end/BPU/BPU.h:638-691` | `pc_reg`、`state`、RAS、update queue、NLP 表等。 |
| BPU 状态读写接口 | `simulator-new/front-end/BPU/BPU.h:740-947`、`1827-1927` | `bpu_seq_read()` 读旧状态，`bpu_seq_write()` 写回 next 状态。 |
| TypePredictor RAM | `simulator-new/front-end/BPU/type_predictor/TypePredictor.h:142` | 类型预测表。 |
| TAGE RAM/状态 | `simulator-new/front-end/BPU/dir_predictor/TAGE_top.h:681-705` | base counter、tag/cnt/useful 表、loop table。 |
| BTB/BHT/TC RAM | `simulator-new/front-end/BPU/target_predictor/BTB_top.h:454-463` | 目标预测、方向历史、target cache 相关表。 |
| 四个 FIFO/PTAB | `simulator-new/front-end/fifo/*.cpp` | `fetch_address_FIFO`、`instruction_FIFO`、`PTAB`、`front2back_FIFO` 的 entries/size 状态。 |
| ICache 寄存器/RAM | `simulator-new/front-end/icache/include/icache_module.h:119-144`、`icache.cpp:256-258` | ICache 控制状态和 data/tag/valid table。 |

## 7. 27 个 comb 和这条主线的关系

本包仍然保留 27 个正式 comb 训练边界口径。区别是：

| 视角 | 作用 |
|---|---|
| `front_top_execution_flow.html` | 按执行顺序解释代码怎么跑，一拍内先后做什么。 |
| `front_top_interactive.html` | 按模块/连线解释 27 个正式 comb 之间的数据关系。 |
| `front_top.v` | 总 top，只负责把 27 个正式 comb 按 `comb_link_00 -> comb_link_27` 串起来。 |
| `*/<同名>.v` | 每个正式 comb 一个子文件夹、一个同名 `.v`，目录和 generated 列表一一对应。 |
| `filelist.f` | 编译/检查用文件列表，先列 27 个 comb，再列 `front_top.v`。 |

注意：这里的 `front_top.v` 是训练包的结构顶层，目标是把 27 个 comb 边界清楚包起来；它不是完整复刻 `front_IO.h` 的功能端口。后续如果要接回真实 CPU 前端，需要再把 `pi/po` 训练总线替换成各 comb 的真实输入输出字段。

`front_comb_calc()` 的初始化阶段已经放在 `front_top.v` 里，但不单独计入 27 个正式 comb。对应源码是 `front_top.cpp:1029-1084`：先清空本拍临时输入、输出、request/default bundle，再进入 `front_global_control_comb`。RTL 包里对应的是 `front_comb_init_default` 和 `comb_link_00` 的赋值。

现在的 RTL 链接口径是：

```text
front_top.v
  -> stage 0 init/default layer
  -> front_global_control_comb
  -> front_read_enable_comb
  -> front_read_stage_input_comb
  -> front_bpu_control_comb
  -> bpu_pre_read_req_comb
  -> type_predictor_pre_read_comb
  -> tage_pre_read_comb
  -> btb_pre_read_comb
  -> bpu_post_read_req_comb
  -> type_pred_comb
  -> tage_comb
  -> btb_post_read_req_comb
  -> btb_comb
  -> bpu_submodule_bind_comb
  -> bpu_predict_main_comb
  -> bpu_hist_comb
  -> bpu_queue_comb
  -> fetch_address_FIFO_comb
  -> predecode_comb
  -> instruction_FIFO_comb
  -> front_ptab_write_comb
  -> PTAB_comb
  -> front_checker_input_comb
  -> predecode_checker_comb
  -> front_front2back_write_comb
  -> front2back_FIFO_comb
  -> front_output_comb
```

正式计数按 27 个 comb 模块。`bpu_hist_commit_ctrl_comb`、`bpu_hist_pred_ctrl_comb`、`bpu_hist_ras_step_comb`、`bpu_hist_step_comb` 属于 `bpu_hist_comb` 的内部 helper/子函数说明，不单独建文件夹，也不把正式模块数从 27 改成 30。

默认关闭但保留依据的分支包括：

| 分支 | 当前处理 |
|---|---|
| Oracle `step_oracle()` | 模拟器参考分支，不进入 27 个正式 comb 主图；单独说明见 `front_oracle_execution_flow.html`。 |
| `ENABLE_2AHEAD` / NLP | 默认关闭，不计入正式模块。 |
| ICache slot1 | 默认 true ICache 主线只走 slot0，slot1 只保留源码依据。 |
| fetch-to-ICache bypass | 默认关闭，只保留源码依据。 |
| ICache-to-predecode bypass | 默认关闭，只保留源码依据。 |

## 8. 短版说法

`front_top()` 的结构是典型的“读旧状态 - 组合计算 - 统一写回”。CPU 顶层从 `SimCpu::front_cycle()` 进入 `FrontTop::step_bpu()`，再调用 `front_top(&in, &out)`。`front_top()` 先用 `front_seq_read()` 把上一拍寄存器、FIFO、RAM、ICache 状态读到 `FrontReadData rd`，再在 `front_comb_calc()` 里按固定阶段执行全局控制、读使能、FIFO/PTAB 读、BPU、fetch FIFO 写、ICache、predecode、PTAB 写、checker、front2back 写和输出选择。组合阶段只生成 `FrontUpdateRequest req` 和 `front_top_out`，最后 `front_seq_write()` 才统一把 BPU、FIFO、PTAB、ICache 和 `front_top` 自身状态写回。
