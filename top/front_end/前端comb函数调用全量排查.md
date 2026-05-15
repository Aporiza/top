# 前端 comb 函数调用流程全量排查

检查口径：按 `large` 配置，从 `SimCpu::front_cycle()` 进入前端，沿实际调用链检查 `simulator-new/front-end` 中的 `*_comb`、`*_comb_calc`、ICache comb 类函数。结论先写清楚：**27 个正式 comb 表不是全量函数表，而是训练边界表；流程里确实还有大量子级/helper comb，需要在汇报里单独说明，但不作为独立模块展开。**

## 1. 顶层调用链

```text
SimCpu::front_cycle()
  -> FrontTop::step_bpu()
    -> front_top()
      -> front_seq_read()
      -> front_comb_calc()
      -> front_seq_write()
```

源码依据：

- `simulator-new/rv_simu_mmu_v2.cpp:652` 定义 `SimCpu::front_cycle()`
- `simulator-new/rv_simu_mmu_v2.cpp:683` / `721` 调用 `front.step_bpu()`
- `simulator-new/rv_simu_mmu_v2.cpp:747` 是 Oracle 分支 `front.step_oracle()`
- `simulator-new/front-end/FrontTop.cpp:36-38`：`step_bpu()` 进入 `front_top(&in, &out)`
- `simulator-new/front-end/front_top.cpp:2068-2077`：`front_top()` 依次调用 `front_seq_read()`、`front_comb_calc()`、`front_seq_write()`

## 2. front_comb_calc 主流程

`front_comb_calc()` 是前端当拍组合调度层，源码在 `simulator-new/front-end/front_top.cpp:1002`。

```text
front_comb_calc()
  1. front_global_control_comb()
  2. icache_peek_ready()
  3. front_read_enable_comb()
  4. front_read_stage_input_comb()
  5. fetch_address_FIFO_comb_calc()
       -> fetch_address_FIFO_comb()
  6. instruction_FIFO_comb_calc()
       -> instruction_FIFO_comb()
  7. PTAB_comb_calc()
       -> PTAB_comb()
  8. front2back_FIFO_comb_calc()
       -> front2back_FIFO_comb()
  9. front_bpu_control_comb()
       -> front_bpu_input_comb()
       -> bpu_seq_read()
       -> bpu_comb_calc()
 10. fetch_address_FIFO_comb_calc() 写 BPU fetch 地址
 11. icache_comb_calc()
 12. predecode_seq_read()
       -> predecode_comb()
 13. instruction_FIFO_comb_calc() 写 ICache 返回指令
 14. front_ptab_write_comb()
       -> PTAB_comb_calc()
 15. front_checker_input_comb()
       -> predecode_checker_seq_read()
       -> predecode_checker_comb()
 16. front_front2back_write_comb()
       -> front2back_FIFO_comb_calc()
 17. icache_comb_calc() 处理 predecode flush invalidate
 18. front_output_comb()
```

主要调用行：

| 阶段 | 函数 | 调用位置 |
|---|---|---|
| 全局控制 | `front_global_control_comb` | `front_top.cpp:1099` |
| ICache ready | `icache_peek_ready` | `front_top.cpp:1140` |
| 读使能 | `front_read_enable_comb` | `front_top.cpp:1162` |
| 读阶段输入 | `front_read_stage_input_comb` | `front_top.cpp:1197` |
| fetch address FIFO | `fetch_address_FIFO_comb_calc` | `front_top.cpp:1219`, `1236`, `1403`, `1417` |
| instruction FIFO | `instruction_FIFO_comb_calc` | `front_top.cpp:1250`, `1634`, `1676` |
| PTAB | `PTAB_comb_calc` | `front_top.cpp:1255`, `1542`, `1707` |
| front2back FIFO | `front2back_FIFO_comb_calc` | `front_top.cpp:1259`, `1792` |
| BPU 控制 | `front_bpu_control_comb` | `front_top.cpp:1326` |
| BPU 主组合 | `bpu_comb_calc` | `front_top.cpp:1357` |
| ICache 主组合 | `icache_comb_calc` | `front_top.cpp:1476`, `1808` |
| 预译码 | `predecode_comb` | `front_top.cpp:1563`, `1617`, `1658` |
| PTAB 写控制 | `front_ptab_write_comb` | `front_top.cpp:1700` |
| checker 输入 | `front_checker_input_comb` | `front_top.cpp:1730` |
| checker | `predecode_checker_comb` | `front_top.cpp:1733` |
| front2back 写控制 | `front_front2back_write_comb` | `front_top.cpp:1780` |
| 最终输出 | `front_output_comb` | `front_top.cpp:1838` |

## 3. BPU 调用链

`front_top.cpp:1357` 调用 `bpu_instance.bpu_comb_calc(...)`，BPU 内部继续拆成 pre-read、post-read、core comb 三层。

```text
bpu_comb_calc()
  -> bpu_pre_read_req_comb()
       -> bank_sel_comb()
       -> nlp_index_comb()
  -> bpu_data_seq_read()
  -> bpu_post_read_req_comb()
       -> nlp_tag_comb()
       -> nlp_index_comb()
       -> bank_pc_comb()
  -> bpu_submodule_seq_read()
       -> TAGE_TOP::tage_comb_calc()
       -> BTB_TOP::btb_comb_calc()
       -> TypePredictor::type_pred_comb_calc()
  -> bpu_core_comb_calc()
       -> type_pred_comb_calc()
       -> bpu_submodule_bind_comb()
       -> tage_comb_calc() x BPU_BANK_NUM
       -> btb_comb_calc() x BPU_BANK_NUM
       -> bpu_predict_main_comb()
       -> bpu_nlp_comb()  // ENABLE_2AHEAD 默认关闭，不计入 27 个正式模块
       -> bpu_hist_comb()
       -> bpu_queue_comb()
```

主要源码依据：

- `simulator-new/front-end/BPU/BPU.h:2017` 定义 `bpu_comb_calc`
- `BPU.h:2034` 调用 `bpu_pre_read_req_comb`
- `BPU.h:2070` 调用 `bpu_post_read_req_comb`
- `BPU.h:2072` 调用 `bpu_core_comb_calc`
- `BPU.h:1586` 调用 `type_pred_comb_calc`
- `BPU.h:1600` 调用 `bpu_submodule_bind_comb`
- `BPU.h:1604` 调用 `tage_comb_calc`
- `BPU.h:1611` 调用 `btb_comb_calc`
- `BPU.h:1641` 调用 `bpu_predict_main_comb`
- `BPU.h:1674` 在 `ENABLE_2AHEAD` 打开时调用 `bpu_nlp_comb`，默认配置不计入 27 个正式模块
- `BPU.h:1726` 调用 `bpu_hist_comb`
- `BPU.h:1774` 调用 `bpu_queue_comb`

## 4. 正式训练边界 comb

这部分对应现有清单/HTML 中的正式训练边界。当前汇报口径固定为 **27 个正式 comb 模块**：`bpu_nlp_comb` 属于默认关闭的 2-Ahead/NLP 分支，不在 HTML 中单独展开。

| 模块 | 正式边界函数 |
|---|---|
| FIFO / PTAB | `fetch_address_FIFO_comb`, `instruction_FIFO_comb`, `PTAB_comb`, `front2back_FIFO_comb` |
| predecode | `predecode_comb`, `predecode_checker_comb` |
| TypePredictor | `pre_read_comb`, `type_pred_comb` |
| TAGE | `tage_pre_read_comb`, `tage_comb` |
| BTB | `btb_pre_read_comb`, `btb_post_read_req_comb`, `btb_comb` |
| BPU_TOP | `bpu_pre_read_req_comb`, `bpu_post_read_req_comb`, `bpu_submodule_bind_comb`, `bpu_predict_main_comb`, `bpu_hist_comb`, `bpu_queue_comb` |
| front_top glue | `front_global_control_comb`, `front_read_enable_comb`, `front_read_stage_input_comb`, `front_bpu_control_comb`, `front_ptab_write_comb`, `front_checker_input_comb`, `front_front2back_write_comb`, `front_output_comb` |

## 5. 流程内 helper / 子级 comb

这些函数**确实在流程内被调用**，但它们不是“没用”，而是被上层正式边界包住。按当前最新要求，HTML 不把它们作为模块单独展开；如果老板/学长后续要求所有子函数也列训练 IO，需要另起“子级 comb 附表”。

### 5.1 front_top helper

| helper | 调用关系 |
|---|---|
| `front_bpu_input_comb` | `front_bpu_control_comb` 内部调用，`front_top.cpp:685` |

### 5.2 BPU_TOP helper

| helper | 调用关系 |
|---|---|
| `bank_sel_comb` | `bpu_pre_read_req_comb` 调用，`BPU.h:833`；`bpu_queue_comb` 调用，`BPU.h:1424` |
| `bank_pc_comb` | `bpu_post_read_req_comb` 调用，`BPU.h:992`, `1008` |
| `nlp_index_comb` | `bpu_pre_read_req_comb` / `bpu_post_read_req_comb` / `bpu_nlp_comb` 调用，`BPU.h:853`, `974`, `1231` |
| `nlp_tag_comb` | `bpu_post_read_req_comb` / `bpu_nlp_comb` 调用，`BPU.h:962`, `1190`, `1202`, `1232` |

### 5.3 TypePredictor helper

| helper | 调用关系 |
|---|---|
| `pred_read_req_comb` | `pre_read_comb` 调用，`TypePredictor.h:322` |
| `upd_read_req_comb` | `pre_read_comb` 调用，`TypePredictor.h:323` |
| `type_pred_bank_sel_comb` | `pred_read_req_comb` / `upd_read_req_comb` 调用，`TypePredictor.h:202`, `221` |
| `type_pred_bank_pc_comb` | `pred_read_req_comb` / `upd_read_req_comb` 调用，`TypePredictor.h:203`, `222` |
| `type_pred_req_comb` | `pred_read_req_comb` / `upd_read_req_comb` 调用，`TypePredictor.h:204`, `223` |
| `hit_comb` | `type_pred_update_comb` / `type_pred_comb` 调用，`TypePredictor.h:282`, `365` |
| `select_comb` | `type_pred_comb` 调用，`TypePredictor.h:372` |
| `victim_comb` | `type_pred_update_comb` 调用，`TypePredictor.h:289` |
| `type_pred_update_comb` | `type_pred_comb` 调用，`TypePredictor.h:389` |

### 5.4 TAGE helper

| helper | 调用关系 |
|---|---|
| `tage_pred_read_req_comb` | `tage_pre_read_comb` 调用，`TAGE_top.h:936` |
| `tage_upd_read_req_comb` | `tage_pre_read_comb` 调用，`TAGE_top.h:937` |
| `tage_useful_reset_read_req_comb` | `tage_pre_read_comb` 调用，`TAGE_top.h:938` |
| `tage_gen_index_comb` | `tage_pre_read_comb` 调用，`TAGE_top.h:941` |
| `tage_pred_index_comb` | `tage_pred_read_req_comb` 调用，`TAGE_top.h:855` |
| `tage_pred_select_comb` | `tage_comb` 调用，`TAGE_top.h:969` |
| `lsfr_update_comb` | `tage_comb` 调用，`TAGE_top.h:1099` |
| `tage_update_comb` | `tage_comb` 调用，`TAGE_top.h:1106` |
| `sat_inc_3bit_comb` / `sat_dec_3bit_comb` | 经 `sat_*_value` 被 `tage_update_comb` 使用，`TAGE_top.h:1745`, `1747` |
| `sat_inc_2bit_comb` / `sat_dec_2bit_comb` | 经 `sat_*_value` 被 `tage_update_comb` 使用，`TAGE_top.h:1725-1736`, `1783-1785`, `1817`, `1855-1856` |
| `tage_ghr_update_comb` | 经 `tage_ghr_update_apply` 被 `bpu_hist_comb` 使用，`BPU.h:1298`, `1362` |
| `tage_fh_update_comb` | 经 `tage_fh_update_apply` 被 `bpu_hist_comb` 使用，`BPU.h:1299`, `1363` |

### 5.5 BTB helper

| helper | 调用关系 |
|---|---|
| `btb_pred_read_req_comb` | `btb_pre_read_comb` 调用，`BTB_top.h:678` |
| `btb_upd_read_req_comb` | `btb_pre_read_comb` 调用，`BTB_top.h:679` |
| `btb_get_idx_comb` | 经 `btb_get_idx_value` 被 pre/update 读请求使用，`BTB_top.h:647`, `666` |
| `btb_get_tag_comb` | 经 `btb_get_tag_value` 被 pre/update 读请求使用，`BTB_top.h:649`, `668` |
| `btb_get_type_idx_comb` | 经 `btb_get_type_idx_value` 在旧 helper 内使用，当前主流程未调用该旧 helper |
| `bht_get_idx_comb` | 经 `bht_get_idx_value` 被 pre/update 读请求使用，`BTB_top.h:648`, `667` |
| `tc_get_idx_comb` | 经 `tc_get_idx_value` 被 `btb_post_read_req_comb` 使用，`BTB_top.h:688`, `703` |
| `tc_get_tag_comb` | 经 `tc_get_tag_value` 被 `btb_post_read_req_comb` / `btb_pred_output_comb` 使用，`BTB_top.h:704`, `1169` |
| `bht_next_state_comb` | 经 `bht_next_state_value` 被 `btb_post_read_req_comb` 使用，`BTB_top.h:697` |
| `btb_hit_check_comb` | `btb_comb` 调用，`BTB_top.h:727`, `745` |
| `btb_pred_output_comb` | `btb_comb` 调用，`BTB_top.h:729` |
| `btb_victim_select_comb` | `btb_comb` 调用，`BTB_top.h:747` |
| `useful_next_state_comb` | `btb_comb` 调用，`BTB_top.h:765`, `792` |
| `tc_hit_check_comb` | `btb_comb` 调用，`BTB_top.h:781` |
| `tc_victim_select_comb` | `btb_comb` 调用，`BTB_top.h:783` |

## 6. 定义了但当前主流程没有调用到的 comb

这些是最容易被问到的“是不是漏了”的点。静态搜索结果显示它们在当前主流程没有直接调用者；其中 `tage_xorshift32_comb` / `btb_xorshift32_comb` 只出现在 `frontend_stats.cpp` 的统计表里。

| 函数 | 位置 | 当前判断 |
|---|---|---|
| `tage_xorshift32_comb` | `TAGE_top.h:1601` | 当前 TAGE 主流程未调用；统计表仍列了它 |
| `btb_xorshift32_comb` | `BTB_top.h:998` | 当前 BTB 主流程未调用；统计表仍列了它 |
| `btb_gen_index_pre_comb` | `BTB_top.h:547` | 当前 `btb_pre_read_comb` 未调用它，疑似旧拆分残留 |
| `btb_mem_read_pre_comb` | `BTB_top.h:586` | 当前主流程未调用，疑似旧拆分残留 |
| `btb_gen_index_post_comb` | `BTB_top.h:606` | 当前 `btb_post_read_req_comb` 未调用它，疑似旧拆分残留 |

## 7. ICache 相关函数

ICache 不在现有 27 个 `*_comb` 训练边界表里，但它在 `front_comb_calc()` 流程中明确被调用：

| 函数 | 调用位置 | 说明 |
|---|---|---|
| `icache_peek_ready` | `front_top.cpp:1140` | 阶段 2 先读取 ICache ready |
| `icache_comb_calc` | `front_top.cpp:1476` | 阶段 6 正常 ICache 请求/返回 |
| `icache_comb_calc` | `front_top.cpp:1808` | predecode flush 时发 invalidate-only 请求 |

如果前端训练范围包含 ICache 内部逻辑，还需要把 `simulator-new/front-end/icache/*.cpp` 的 `comb()` / `comb_core()` / `comb_lookup_*()` 单独列成 ICache 子流程；如果 ICache 只作为前端环境模块，则需要在文档中明确“不计入前端 comb 训练边界，只保留路径依据”。

## 8. 本次排查结论

1. **学长的担心是成立的**：只报 27 个正式 comb，确实不能代表“流程里所有函数”。流程里还有 40 多个已调用的 helper/子级 comb，但当前不作为独立模块展开。
2. `bpu_predict_main_comb` 内部没有直接调用 `bank_sel_comb`；`bank_sel_comb` 的真实调用点在 `bpu_pre_read_req_comb` 和 `bpu_queue_comb`。
3. 当前正式边界表可以继续保留，但汇报时应改成“两层口径”：
   - 正式训练边界：27 个。
   - 流程内子函数/helper：本报告第 5 节列出，作为补充表。
4. 需要向老板/学长确认三个口径问题：
   - helper comb 是否需要独立导出训练 IO，还是只随父级正式 comb 一起覆盖。
   - `tage_xorshift32_comb`、`btb_xorshift32_comb`、`btb_gen_index_*` 这类“定义/统计存在但主流程未调用”的函数，是保留为历史统计、删除，还是重新接回流程。
   - ICache 是否纳入本次前端训练边界；若纳入，应补 ICache comb 子流程和 IO 统计。
