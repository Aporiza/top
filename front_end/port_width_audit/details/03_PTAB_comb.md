# PTAB_comb

- 分组：`FIFO/PTAB`
- 源码依据：`train_IO.h / PTAB.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型            | bit   |
| -- | ------------- | ----- |
| 输入 | `PtabCombIn`  | 9710  |
| 输出 | `PtabCombOut` | 14555 |


## 输入展开

| 字段                                                     | 类型                     | 单项bit | 数量  | 合计bit | 来源                          |
| ------------------------------------------------------ | ---------------------- | ----- | --- | ----- | --------------------------- |
| inp                                                    | `PTAB_in`              | 4853  | 1   | 4853  | front-end/train_IO.h:37     |
| inp.reset                                              | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:207    |
| inp.refetch                                            | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:208    |
| inp.write_enable                                       | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:209    |
| inp.predict_dir[FETCH_WIDTH]                           | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:211    |
| inp.predict_next_fetch_address                         | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_IO.h:212    |
| inp.predict_base_pc[FETCH_WIDTH]                       | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:213    |
| inp.alt_pred[FETCH_WIDTH]                              | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:214    |
| inp.altpcpn[FETCH_WIDTH]                               | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:216    |
| inp.pcpn[FETCH_WIDTH]                                  | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:217    |
| inp.tage_idx[FETCH_WIDTH][4]                           | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_IO.h:218    |
| inp.tage_tag[FETCH_WIDTH][4]                           | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_IO.h:219    |
| inp.sc_used[FETCH_WIDTH]                               | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:220    |
| inp.sc_pred[FETCH_WIDTH]                               | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:221    |
| inp.sc_sum[FETCH_WIDTH]                                | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_IO.h:222    |
| inp.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE]           | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_IO.h:223    |
| inp.loop_used[FETCH_WIDTH]                             | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:224    |
| inp.loop_hit[FETCH_WIDTH]                              | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:225    |
| inp.loop_pred[FETCH_WIDTH]                             | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:226    |
| inp.loop_idx[FETCH_WIDTH]                              | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_IO.h:227    |
| inp.loop_tag[FETCH_WIDTH]                              | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_IO.h:228    |
| inp.read_enable                                        | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:229    |
| inp.need_mini_flush                                    | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:231    |
| rd                                                     | `PTAB_read_data`       | 4857  | 1   | 4857  | front-end/train_IO.h:38     |
| rd.size                                                | `ptab_size_t`          | 6     | 1   | 6     | front-end/front_module.h:61 |
| rd.head_valid                                          | `wire1_t`              | 1     | 1   | 1     | front-end/front_module.h:62 |
| rd.head_entry                                          | `PTAB_entry`           | 4850  | 1   | 4850  | front-end/front_module.h:63 |
| rd.head_entry.predict_dir[FETCH_WIDTH]                 | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:39 |
| rd.head_entry.predict_next_fetch_address               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_module.h:40 |
| rd.head_entry.predict_base_pc[FETCH_WIDTH]             | `pc_t`                 | 32    | 16  | 512   | front-end/front_module.h:41 |
| rd.head_entry.alt_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:42 |
| rd.head_entry.altpcpn[FETCH_WIDTH]                     | `pcpn_t`               | 3     | 16  | 48    | front-end/front_module.h:43 |
| rd.head_entry.pcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/front_module.h:44 |
| rd.head_entry.tage_idx[FETCH_WIDTH][TN_MAX]            | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_module.h:45 |
| rd.head_entry.tage_tag[FETCH_WIDTH][TN_MAX]            | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_module.h:46 |
| rd.head_entry.sc_used[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:47 |
| rd.head_entry.sc_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:48 |
| rd.head_entry.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_module.h:49 |
| rd.head_entry.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_module.h:50 |
| rd.head_entry.loop_used[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:51 |
| rd.head_entry.loop_hit[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:52 |
| rd.head_entry.loop_pred[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:53 |
| rd.head_entry.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_module.h:54 |
| rd.head_entry.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_module.h:55 |
| rd.head_entry.need_mini_flush                          | `wire1_t`              | 1     | 1   | 1     | front-end/front_module.h:56 |
| rd.head_entry.dummy_entry                              | `wire1_t`              | 1     | 1   | 1     | front-end/front_module.h:57 |


## 输出展开

| 字段                                                        | 类型                     | 单项bit | 数量  | 合计bit | 来源                          |
| --------------------------------------------------------- | ---------------------- | ----- | --- | ----- | --------------------------- |
| out_regs                                                  | `PTAB_out`             | 4851  | 1   | 4851  | front-end/train_IO.h:42     |
| out_regs.dummy_entry                                      | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:236    |
| out_regs.full                                             | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:238    |
| out_regs.empty                                            | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:239    |
| out_regs.predict_dir[FETCH_WIDTH]                         | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:240    |
| out_regs.predict_next_fetch_address                       | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_IO.h:242    |
| out_regs.predict_base_pc[FETCH_WIDTH]                     | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:243    |
| out_regs.alt_pred[FETCH_WIDTH]                            | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:244    |
| out_regs.altpcpn[FETCH_WIDTH]                             | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:246    |
| out_regs.pcpn[FETCH_WIDTH]                                | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:247    |
| out_regs.tage_idx[FETCH_WIDTH][4]                         | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_IO.h:248    |
| out_regs.tage_tag[FETCH_WIDTH][4]                         | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_IO.h:249    |
| out_regs.sc_used[FETCH_WIDTH]                             | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:250    |
| out_regs.sc_pred[FETCH_WIDTH]                             | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:251    |
| out_regs.sc_sum[FETCH_WIDTH]                              | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_IO.h:252    |
| out_regs.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE]         | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_IO.h:253    |
| out_regs.loop_used[FETCH_WIDTH]                           | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:254    |
| out_regs.loop_hit[FETCH_WIDTH]                            | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:255    |
| out_regs.loop_pred[FETCH_WIDTH]                           | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:256    |
| out_regs.loop_idx[FETCH_WIDTH]                            | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_IO.h:257    |
| out_regs.loop_tag[FETCH_WIDTH]                            | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_IO.h:258    |
| clear_ptab                                                | `wire1_t`              | 1     | 1   | 1     | front-end/train_IO.h:43     |
| push_write_en                                             | `wire1_t`              | 1     | 1   | 1     | front-end/train_IO.h:44     |
| push_write_entry                                          | `PTAB_entry`           | 4850  | 1   | 4850  | front-end/train_IO.h:45     |
| push_write_entry.predict_dir[FETCH_WIDTH]                 | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:39 |
| push_write_entry.predict_next_fetch_address               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_module.h:40 |
| push_write_entry.predict_base_pc[FETCH_WIDTH]             | `pc_t`                 | 32    | 16  | 512   | front-end/front_module.h:41 |
| push_write_entry.alt_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:42 |
| push_write_entry.altpcpn[FETCH_WIDTH]                     | `pcpn_t`               | 3     | 16  | 48    | front-end/front_module.h:43 |
| push_write_entry.pcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/front_module.h:44 |
| push_write_entry.tage_idx[FETCH_WIDTH][TN_MAX]            | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_module.h:45 |
| push_write_entry.tage_tag[FETCH_WIDTH][TN_MAX]            | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_module.h:46 |
| push_write_entry.sc_used[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:47 |
| push_write_entry.sc_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:48 |
| push_write_entry.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_module.h:49 |
| push_write_entry.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_module.h:50 |
| push_write_entry.loop_used[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:51 |
| push_write_entry.loop_hit[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:52 |
| push_write_entry.loop_pred[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:53 |
| push_write_entry.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_module.h:54 |
| push_write_entry.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_module.h:55 |
| push_write_entry.need_mini_flush                          | `wire1_t`              | 1     | 1   | 1     | front-end/front_module.h:56 |
| push_write_entry.dummy_entry                              | `wire1_t`              | 1     | 1   | 1     | front-end/front_module.h:57 |
| push_dummy_en                                             | `wire1_t`              | 1     | 1   | 1     | front-end/train_IO.h:46     |
| push_dummy_entry                                          | `PTAB_entry`           | 4850  | 1   | 4850  | front-end/train_IO.h:47     |
| push_dummy_entry.predict_dir[FETCH_WIDTH]                 | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:39 |
| push_dummy_entry.predict_next_fetch_address               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_module.h:40 |
| push_dummy_entry.predict_base_pc[FETCH_WIDTH]             | `pc_t`                 | 32    | 16  | 512   | front-end/front_module.h:41 |
| push_dummy_entry.alt_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:42 |
| push_dummy_entry.altpcpn[FETCH_WIDTH]                     | `pcpn_t`               | 3     | 16  | 48    | front-end/front_module.h:43 |
| push_dummy_entry.pcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/front_module.h:44 |
| push_dummy_entry.tage_idx[FETCH_WIDTH][TN_MAX]            | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_module.h:45 |
| push_dummy_entry.tage_tag[FETCH_WIDTH][TN_MAX]            | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_module.h:46 |
| push_dummy_entry.sc_used[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:47 |
| push_dummy_entry.sc_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:48 |
| push_dummy_entry.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_module.h:49 |
| push_dummy_entry.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_module.h:50 |
| push_dummy_entry.loop_used[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:51 |
| push_dummy_entry.loop_hit[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:52 |
| push_dummy_entry.loop_pred[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_module.h:53 |
| push_dummy_entry.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_module.h:54 |
| push_dummy_entry.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_module.h:55 |
| push_dummy_entry.need_mini_flush                          | `wire1_t`              | 1     | 1   | 1     | front-end/front_module.h:56 |
| push_dummy_entry.dummy_entry                              | `wire1_t`              | 1     | 1   | 1     | front-end/front_module.h:57 |
| pop_en                                                    | `wire1_t`              | 1     | 1   | 1     | front-end/train_IO.h:48     |

