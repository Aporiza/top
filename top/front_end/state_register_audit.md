# 前端寄存器和状态自查

本文档用于说明当前前端包里哪些状态已经有 Verilog RTL，哪些状态仍缺失。结论按 `simulator-front` 源码口径整理。

## 1. 总结

- `front_top.v` 已经有顶层周期寄存器，用于保存 refetch、统计计数、FIFO 状态快照等。
- `fifo/` 下四个模块不再等待外部 BSD 代码，已经直接在 `*_comb_bsd_top` 内实现 Verilog FIFO/PTAB 状态。
- `bpu_top.v` 已补 BPU 顶层状态寄存器壳，按 `BPU_TOP::reset_internal_all()` 的口径初始化 `pc_reg`、GHR/FH、RAS、2-ahead、NLP、queue 指针等状态。
- BPU 的真实 next-state 还没有从 13 个 BPU comb 接入，因为这些 `*_bsd_top` 仍是零输出占位；后续补 comb 时要把 `BPU_TOP::UpdateRequest` 里的 next 字段接到 `bpu_top.v` 的周期写回处。
- predecode、predecode_checker 当前仍是零输出占位；它们自身不是主要状态存储点，但其输出会影响 `front_top.v` 内的 `predecode_refetch` 和 `predecode_refetch_address` 寄存器。
- ICache 仍是上层边界，不在本前端包内实现内部 cache RAM。

## 2. 已有状态

| 文件 | 已有状态 | 来源依据 |
|---|---|---|
| `front_top.v` | `predecode_refetch`、`predecode_refetch_address`、`front_sim_time`、`front_stats_cycles`、四类 FIFO full/empty latch、四类 FIFO 读出快照 | `front_top.cpp:front_seq_read/front_seq_write` |
| `bpu/bpu_top.v` | BPU 顶层状态壳：`pc_reg`、`state_reg`、`do_pred/do_upd` latch、TAGE/BTB done latch、预测结果 latch、Arch/Spec GHR/FH/PATH/RAS、queue 指针/count、NLP 表、2-ahead/miniflush 状态 | `BPU.h:BPU_TOP::Registers & Memory`、`BPU_TOP::reset_internal_all`、`BPU_TOP::bpu_seq_write` |
| `fifo/fetch_address_FIFO_comb/fetch_address_FIFO_comb_top.v` | `fifo_mem`、`fifo_head`、`fifo_tail`、`fifo_count`，深度 32 | `frontend_feature_config.h:FETCH_ADDR_FIFO_SIZE = 32` |
| `fifo/instruction_FIFO_comb/instruction_FIFO_comb_top.v` | `fifo_mem`、`fifo_head`、`fifo_tail`、`fifo_count`，深度 32 | `frontend_feature_config.h:INSTRUCTION_FIFO_SIZE = 32` |
| `fifo/PTAB_comb/PTAB_comb_top.v` | `ptab_mem`、`ptab_dummy_mem`、`ptab_head`、`ptab_tail`、`ptab_count`，深度 32 | `frontend_feature_config.h:PTAB_SIZE = 32` |
| `fifo/front2back_FIFO_comb/front2back_FIFO_comb_top.v` | `fifo_mem`、`fifo_head`、`fifo_tail`、`fifo_count`，深度 64 | `frontend_feature_config.h:FRONT2BACK_FIFO_SIZE = 64` |

## 3. 仍缺失的状态

### BPU

源码中 BPU 在 `front_seq_write()` 阶段调用：

```text
front_top.cpp: bpu_instance.bpu_seq_write(...)
```

当前 `bpu_top.v` 已有寄存器壳和周期写回位置，但 BPU comb 还没有产生真实 next-state。后续 RTL 需要继续补：

- BPU 顶层状态的真实 next-state 连接：`pc_reg`、two-ahead 相关保存值、预测输出寄存器、队列/历史控制状态。
- TypePredictor：`table[BPU_BANK_NUM][TYPE_PRED_SET_NUM][TYPE_PRED_WAY_NUM]`。
- TAGE：base counter、tag/cnt/useful 表、GHR/FH、`reset_cnt_reg`、`use_alt_ctr_reg`、SC/loop 相关表项。
- BTB：BTB tag/BTA/valid/useful 表、TC 表、BHT 状态、SRAM 延迟寄存器、随机替换状态。
- `bpu_hist_comb` 和 `bpu_queue_comb` 相关历史与队列状态。

### front glue / predecode

这些模块当前仍是零输出占位，需要补组合逻辑；它们本身主要对应 `front_comb_calc()` 里的组合函数，状态写回集中在 `front_top.v` 周期末。

## 4. 零输出占位清单

当前静态扫描仍能看到 23 个 `assign po = {W_xxx{1'b0}}`：

| 分组 | 模块 |
|---|---|
| front_top_glue | `front_global_control_comb`、`front_read_enable_comb`、`front_read_stage_input_comb`、`front_bpu_control_comb`、`front_ptab_write_comb`、`front_checker_input_comb`、`front_front2back_write_comb`、`front_output_comb` |
| predecode/checker | `predecode_comb`、`predecode_checker_comb` |
| BPU top | `bpu_pre_read_req_comb`、`bpu_post_read_req_comb`、`bpu_submodule_bind_comb`、`bpu_predict_main_comb`、`bpu_hist_comb`、`bpu_queue_comb` |
| predictor | `type_predictor_pre_read_comb`、`type_pred_comb`、`tage_pre_read_comb`、`tage_comb`、`btb_pre_read_comb`、`btb_post_read_req_comb`、`btb_comb` |

这些模块的组合逻辑和 BPU next-state 连接需要继续补齐。四个 FIFO/PTAB 已经不在这个占位清单里。

### ICache

`front_top.v` 只暴露 ICache 请求/返回端口。ICache RAM、miss/refill/PTW 等状态不在当前前端包内。

## 5. 当前可交付口径

四个 FIFO/PTAB 已经是前端包内 Verilog RTL，可以直接保留在交付包中。BPU 顶层状态壳已经补上，但 BPU/TAGE/BTB/TypePredictor 的真实表项更新和 comb 输出仍未完成，不能把当前 BPU 说成完整可运行预测器。
