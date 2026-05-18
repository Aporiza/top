# Frontend ff 版本交付说明

本文档面向第一次读前端代码的人。当前 `top/front_end` 的依据统一切换到：

```text
simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0
```

不要再按旧版模拟器或 `include/config.h.large` 判断接口宽度。本次训练版本以 `simulator-ffc.../include/config.h` 的生效配置为准。

## 1. 生效配置

| 项 | ff 生效值 | 源码依据 |
|---|---:|---|
| `FETCH_WIDTH` | 16 | `include/config.h:57` |
| `DECODE_WIDTH` | 8 | `include/config.h:58` |
| `COMMIT_WIDTH` | 8 | `include/config.h:63` |
| `CONFIG_BPU` | 打开 | `include/config.h:35` |
| `CONFIG_ORACLE_STEADY_FETCH_WIDTH` | 打开 | `include/config.h:37` |
| `PRF_NUM` | 2048，`PRF_IDX_WIDTH=11` | `include/config.h:320,619` |
| `ROB_NUM` | 2048，`ROB_IDX_WIDTH=11` | `include/config.h:326,620` |
| `STQ_SIZE/LDQ_SIZE` | 512，索引宽度 9 | `include/config.h:438-439,621-622` |
| `FTQ_SIZE` | 256，`FTQ_IDX_WIDTH=8` | `include/config.h:334,626` |

`config.h.large` 在这个 ff 目录里不是当前训练用的生效配置，里面 `PRF_NUM=512`、`CONFIG_BPU` 注释掉，不能拿它对端口。

## 2. 入口顺序

前端主线从 CPU 顶层进入，顺序如下：

| 步骤 | 函数 | 源码依据 | 作用 |
|---|---|---|---|
| 1 | `SimCpu::front_cycle()` | `rv_simu_mmu_v2.cpp:639-707` | 每拍设置 `front.in`，再调用 `front.step_bpu()`。stall 分支也会调用一次，只是 `FIFO_read_enable=false`。 |
| 2 | `FrontTop::step_bpu()` | `front-end/FrontTop.cpp:36-39` | 同步 ICache/PTW 运行时端口后调用 `front_top(&in, &out)`。 |
| 3 | `front_top()` | `front-end/front_top.cpp:1936-1945` | 固定执行 `front_seq_read -> front_comb_calc -> front_seq_write`。 |
| 4 | `front_seq_read()` | `front-end/front_top.cpp:1865-1899` | 读取上一拍寄存器、FIFO、PTAB、ICache/BPU 快照。 |
| 5 | `front_comb_calc()` | `front-end/front_top.cpp:920-1849` | 按顺序跑组合逻辑，只生成本拍 `out` 和 next-state 请求。 |
| 6 | `front_seq_write()` | `front-end/front_top.cpp:1902-1934` | 周期末统一写回 BPU、FIFO、PTAB、ICache 和 `front_top` 本地寄存器。 |

讲代码时可以抓住一句话：先读旧状态，再跑完整组合链，最后统一写新状态。

## 3. 组合逻辑主线

`front_comb_calc()` 内的主要组合函数按源码顺序执行：

| 顺序 | 模块/函数 | 源码依据 | 说明 |
|---:|---|---|---|
| 1 | `front_global_control_comb` | `front_top.cpp:613,1009` | 合并 reset、后端 refetch、上一拍 checker refetch。 |
| 2 | `front_read_enable_comb` | `front_top.cpp:624,1072` | 根据后端读请求、FIFO/PTAB 空满、ICache ready 生成读使能。 |
| 3 | `front_read_stage_input_comb` | `front_top.cpp:647,1107` | 把全局控制转换成四个队列的读控制。 |
| 4 | `front_bpu_control_comb` | `front_top.cpp:679,1210` | 组装 BPU 输入，包括后端训练反馈和 refetch。 |
| 5 | `bpu_seq_read + bpu_comb_calc` | `front_top.cpp:1253-1256`、`BPU/BPU.h` | 先读 BPU 内部表项，再计算本拍预测结果。 |
| 6 | `fetch_address_FIFO_comb` | `front_top.cpp:1290-1331` | 把 BPU 产生的 fetch address 写入取址 FIFO。 |
| 7 | `icache_comb_calc` | `front_top.cpp:1340-1382` | 用 FIFO/bypass 地址访问 ICache。当前 RTL 把 ICache 作为显式外部握手边界。 |
| 8 | `predecode_comb + instruction_FIFO_comb` | `front_top.cpp:1435-1555` | ICache 返回后做预译码，并写入 instruction FIFO。 |
| 9 | `front_ptab_write_comb + PTAB_comb` | `front_top.cpp:1574-1586` | 把 BPU 预测上下文写入 PTAB。 |
| 10 | `front_checker_input_comb + predecode_checker_comb` | `front_top.cpp:1602-1628` | 对齐 instruction FIFO 与 PTAB，检查预译码/预测是否需要修正。 |
| 11 | `front_front2back_write_comb + front2back_FIFO_comb` | `front_top.cpp:1652-1684` | 生成写给后端的前端输出包。 |
| 12 | `front_output_comb` | `front_top.cpp:863,1707` | 从 front2back FIFO 或 bypass 生成最终 `front_top_out`。 |

## 4. 27 个训练组合模块

前端交付时按 27 个正式 comb 训练单元组织。`bpu_hist_*` helper 不作为独立顶层模块展开，它们被归到 `bpu_hist_comb` 说明里。

| 分组 | 模块 |
|---|---|
| `front_top_glue` | `front_global_control_comb`、`front_read_enable_comb`、`front_read_stage_input_comb`、`front_bpu_control_comb`、`front_ptab_write_comb`、`front_checker_input_comb`、`front_front2back_write_comb`、`front_output_comb` |
| `bpu` | `bpu_pre_read_req_comb`、`bpu_post_read_req_comb`、`bpu_submodule_bind_comb`、`bpu_predict_main_comb`、`bpu_hist_comb`、`bpu_queue_comb` |
| `type_predictor` | `type_predictor_pre_read_comb`、`type_pred_comb` |
| `dir_predictor` | `tage_pre_read_comb`、`tage_comb` |
| `target_predictor` | `btb_pre_read_comb`、`btb_post_read_req_comb`、`btb_comb` |
| `fifo/predecode` | `fetch_address_FIFO_comb`、`instruction_FIFO_comb`、`PTAB_comb`、`front2back_FIFO_comb`、`predecode_comb`、`predecode_checker_comb` |

## 5. 前后端接口

ff 版本的 `front_top_out` 没有 `commit_stall`，`FrontPreIO` 也没有 `front_stall`。这两个字段是旧版模拟器的残留，不能再计入端口宽度。

前端写后端的字段来自：

```text
front-end/front_IO.h:42-64
back-end/include/IO.h:108-159
rv_simu_mmu_v2.cpp:675-695
```

当前 `top_top.v` 中按 ff 逻辑生成 `front2pre_valid_bits`：第 0 条 lane 只看 `FIFO_valid && inst_valid[0]`，后续 lane 还要保证前面没有已预测 taken 的分支。

## 6. ICache 边界

ff 源码里前端是真实 ICache/PTW 运行时边界，不是简单 ideal 取指。当前 RTL 包没有私自实现 ICache，而是在 `front_top.v` 暴露 ICache 握手端口，并在 `top_top.v` 统一抬成 `front_icache_*` 端口，避免输入悬空。

## 7. 明天讲解抓手

讲的时候按这条线走：

1. `SimCpu::front_cycle()` 决定本拍前端是否读包、是否 refetch。
2. `front.step_bpu()` 进入 `front_top()`。
3. `front_seq_read()` 先读上一拍寄存器和各队列/RAM 快照。
4. `front_comb_calc()` 按 12 个阶段从控制、BPU、取址、ICache、预译码、PTAB、checker 到 front2back 输出一路跑完。
5. `front_seq_write()` 在周期末统一更新所有寄存器、FIFO、PTAB、BPU 表项。
6. `rv_simu_mmu_v2.cpp` 再把 `front.out` 的指令、PC、预测元信息写进 `back.in`。
