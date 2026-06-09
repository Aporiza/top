# front_checker_input_comb

- 分组：`front_top glue`
- 源码依据：`train_IO.h / front_top.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                         | bit  |
| -- | -------------------------- | ---- |
| 输入 | `FrontCheckerInputCombIn`  | 6486 |
| 输出 | `FrontCheckerInputCombOut` | 624  |


## 输入展开

| 字段                                                | 类型                     | 单项bit | 数量  | 合计bit | 来源                       |
| ------------------------------------------------- | ---------------------- | ----- | --- | ----- | ------------------------ |
| fifo_out                                          | `instruction_FIFO_out` | 1635  | 1   | 1635  | front-end/train_IO.h:362 |
| fifo_out.full                                     | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:193 |
| fifo_out.empty                                    | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:194 |
| fifo_out.FIFO_valid                               | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:195 |
| fifo_out.instructions[FETCH_WIDTH]                | `inst_word_t`          | 32    | 16  | 512   | front-end/front_IO.h:197 |
| fifo_out.pc[FETCH_WIDTH]                          | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:198 |
| fifo_out.page_fault_inst[FETCH_WIDTH]             | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:199 |
| fifo_out.inst_valid[FETCH_WIDTH]                  | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:200 |
| fifo_out.predecode_type[FETCH_WIDTH]              | `predecode_type_t`     | 2     | 16  | 32    | front-end/front_IO.h:201 |
| fifo_out.predecode_target_address[FETCH_WIDTH]    | `target_addr_t`        | 32    | 16  | 512   | front-end/front_IO.h:202 |
| fifo_out.seq_next_pc                              | `pc_t`                 | 32    | 1   | 32    | front-end/front_IO.h:203 |
| ptab_out                                          | `PTAB_out`             | 4851  | 1   | 4851  | front-end/train_IO.h:363 |
| ptab_out.dummy_entry                              | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:236 |
| ptab_out.full                                     | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:238 |
| ptab_out.empty                                    | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:239 |
| ptab_out.predict_dir[FETCH_WIDTH]                 | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:240 |
| ptab_out.predict_next_fetch_address               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_IO.h:242 |
| ptab_out.predict_base_pc[FETCH_WIDTH]             | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:243 |
| ptab_out.alt_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:244 |
| ptab_out.altpcpn[FETCH_WIDTH]                     | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:246 |
| ptab_out.pcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:247 |
| ptab_out.tage_idx[FETCH_WIDTH][4]                 | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_IO.h:248 |
| ptab_out.tage_tag[FETCH_WIDTH][4]                 | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_IO.h:249 |
| ptab_out.sc_used[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:250 |
| ptab_out.sc_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:251 |
| ptab_out.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_IO.h:252 |
| ptab_out.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_IO.h:253 |
| ptab_out.loop_used[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:254 |
| ptab_out.loop_hit[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:255 |
| ptab_out.loop_pred[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:256 |
| ptab_out.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_IO.h:257 |
| ptab_out.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_IO.h:258 |


## 输出展开

| 字段                                               | 类型                     | 单项bit | 数量 | 合计bit | 来源                               |
| ------------------------------------------------ | ---------------------- | ----- | -- | ----- | -------------------------------- |
| checker_in                                       | `predecode_checker_in` | 624   | 1  | 624   | front-end/train_IO.h:367         |
| checker_in.predict_dir[FETCH_WIDTH]              | `wire1_t`              | 1     | 16 | 16    | front-end/predecode_checker.h:7  |
| checker_in.predict_next_fetch_address            | `fetch_addr_t`         | 32    | 1  | 32    | front-end/predecode_checker.h:9  |
| checker_in.predecode_type[FETCH_WIDTH]           | `predecode_type_t`     | 2     | 16 | 32    | front-end/predecode_checker.h:10 |
| checker_in.predecode_target_address[FETCH_WIDTH] | `target_addr_t`        | 32    | 16 | 512   | front-end/predecode_checker.h:12 |
| checker_in.seq_next_pc                           | `pc_t`                 | 32    | 1  | 32    | front-end/predecode_checker.h:13 |

