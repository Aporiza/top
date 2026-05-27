# front_bpu_control_comb

- 分组：`front_top glue`
- 源码依据：`train_IO.h / front_top.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                       | bit  |
| -- | ------------------------ | ---- |
| 输入 | `FrontBpuControlCombIn`  | 2775 |
| 输出 | `FrontBpuControlCombOut` | 5480 |


## 输入展开

| 字段                                                    | 类型                     | 单项bit | 数量 | 合计bit | 来源                       |
| ----------------------------------------------------- | ---------------------- | ----- | -- | ----- | ------------------------ |
| bpu_in_seed                                           | `BPU_in`               | 2739  | 1  | 2739  | front-end/train_IO.h:326 |
| bpu_in_seed.reset                                     | `wire1_t`              | 1     | 1  | 1     | front-end/front_IO.h:66  |
| bpu_in_seed.back2front_valid[COMMIT_WIDTH]            | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:67  |
| bpu_in_seed.refetch                                   | `wire1_t`              | 1     | 1  | 1     | front-end/front_IO.h:69  |
| bpu_in_seed.refetch_address                           | `fetch_addr_t`         | 32    | 1  | 32    | front-end/front_IO.h:70  |
| bpu_in_seed.predict_base_pc[COMMIT_WIDTH]             | `pc_t`                 | 32    | 8  | 256   | front-end/front_IO.h:71  |
| bpu_in_seed.predict_dir[COMMIT_WIDTH]                 | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:72  |
| bpu_in_seed.actual_dir[COMMIT_WIDTH]                  | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:73  |
| bpu_in_seed.actual_br_type[COMMIT_WIDTH]              | `br_type_t`            | 3     | 8  | 24    | front-end/front_IO.h:74  |
| bpu_in_seed.actual_target[COMMIT_WIDTH]               | `target_addr_t`        | 32    | 8  | 256   | front-end/front_IO.h:75  |
| bpu_in_seed.alt_pred[COMMIT_WIDTH]                    | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:76  |
| bpu_in_seed.altpcpn[COMMIT_WIDTH]                     | `pcpn_t`               | 3     | 8  | 24    | front-end/front_IO.h:78  |
| bpu_in_seed.pcpn[COMMIT_WIDTH]                        | `pcpn_t`               | 3     | 8  | 24    | front-end/front_IO.h:79  |
| bpu_in_seed.tage_idx[COMMIT_WIDTH][4]                 | `tage_idx_t`           | 12    | 32 | 384   | front-end/front_IO.h:80  |
| bpu_in_seed.tage_tag[COMMIT_WIDTH][4]                 | `tage_tag_t`           | 8     | 32 | 256   | front-end/front_IO.h:81  |
| bpu_in_seed.sc_used[COMMIT_WIDTH]                     | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:82  |
| bpu_in_seed.sc_pred[COMMIT_WIDTH]                     | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:83  |
| bpu_in_seed.sc_sum[COMMIT_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 8  | 128   | front-end/front_IO.h:84  |
| bpu_in_seed.sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 64 | 1024  | front-end/front_IO.h:85  |
| bpu_in_seed.loop_used[COMMIT_WIDTH]                   | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:86  |
| bpu_in_seed.loop_hit[COMMIT_WIDTH]                    | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:87  |
| bpu_in_seed.loop_pred[COMMIT_WIDTH]                   | `wire1_t`              | 1     | 8  | 8     | front-end/front_IO.h:88  |
| bpu_in_seed.loop_idx[COMMIT_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 8  | 128   | front-end/front_IO.h:89  |
| bpu_in_seed.loop_tag[COMMIT_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 8  | 128   | front-end/front_IO.h:90  |
| bpu_in_seed.icache_read_ready                         | `wire1_t`              | 1     | 1  | 1     | front-end/front_IO.h:91  |
| fetch_addr_fifo_full_latch_snapshot                   | `wire1_t`              | 1     | 1  | 1     | front-end/train_IO.h:327 |
| ptab_full_latch_snapshot                              | `wire1_t`              | 1     | 1  | 1     | front-end/train_IO.h:328 |
| global_reset                                          | `wire1_t`              | 1     | 1  | 1     | front-end/train_IO.h:329 |
| global_refetch                                        | `wire1_t`              | 1     | 1  | 1     | front-end/train_IO.h:330 |
| refetch_address                                       | `fetch_addr_t`         | 32    | 1  | 32    | front-end/train_IO.h:331 |


## 输出展开

| 字段                                                     | 类型                      | 单项bit | 数量 | 合计bit | 来源                       |
| ------------------------------------------------------ | ----------------------- | ----- | -- | ----- | ------------------------ |
| bpu_stall                                              | `wire1_t`               | 1     | 1  | 1     | front-end/train_IO.h:335 |
| bpu_can_run                                            | `wire1_t`               | 1     | 1  | 1     | front-end/train_IO.h:336 |
| bpu_icache_ready                                       | `wire1_t`               | 1     | 1  | 1     | front-end/train_IO.h:337 |
| bpu_in                                                 | `BPU_in`                | 2739  | 1  | 2739  | front-end/train_IO.h:338 |
| bpu_in.reset                                           | `wire1_t`               | 1     | 1  | 1     | front-end/front_IO.h:66  |
| bpu_in.back2front_valid[COMMIT_WIDTH]                  | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:67  |
| bpu_in.refetch                                         | `wire1_t`               | 1     | 1  | 1     | front-end/front_IO.h:69  |
| bpu_in.refetch_address                                 | `fetch_addr_t`          | 32    | 1  | 32    | front-end/front_IO.h:70  |
| bpu_in.predict_base_pc[COMMIT_WIDTH]                   | `pc_t`                  | 32    | 8  | 256   | front-end/front_IO.h:71  |
| bpu_in.predict_dir[COMMIT_WIDTH]                       | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:72  |
| bpu_in.actual_dir[COMMIT_WIDTH]                        | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:73  |
| bpu_in.actual_br_type[COMMIT_WIDTH]                    | `br_type_t`             | 3     | 8  | 24    | front-end/front_IO.h:74  |
| bpu_in.actual_target[COMMIT_WIDTH]                     | `target_addr_t`         | 32    | 8  | 256   | front-end/front_IO.h:75  |
| bpu_in.alt_pred[COMMIT_WIDTH]                          | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:76  |
| bpu_in.altpcpn[COMMIT_WIDTH]                           | `pcpn_t`                | 3     | 8  | 24    | front-end/front_IO.h:78  |
| bpu_in.pcpn[COMMIT_WIDTH]                              | `pcpn_t`                | 3     | 8  | 24    | front-end/front_IO.h:79  |
| bpu_in.tage_idx[COMMIT_WIDTH][4]                       | `tage_idx_t`            | 12    | 32 | 384   | front-end/front_IO.h:80  |
| bpu_in.tage_tag[COMMIT_WIDTH][4]                       | `tage_tag_t`            | 8     | 32 | 256   | front-end/front_IO.h:81  |
| bpu_in.sc_used[COMMIT_WIDTH]                           | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:82  |
| bpu_in.sc_pred[COMMIT_WIDTH]                           | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:83  |
| bpu_in.sc_sum[COMMIT_WIDTH]                            | `tage_scl_meta_sum_t`   | 16    | 8  | 128   | front-end/front_IO.h:84  |
| bpu_in.sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE]       | `tage_scl_meta_idx_t`   | 16    | 64 | 1024  | front-end/front_IO.h:85  |
| bpu_in.loop_used[COMMIT_WIDTH]                         | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:86  |
| bpu_in.loop_hit[COMMIT_WIDTH]                          | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:87  |
| bpu_in.loop_pred[COMMIT_WIDTH]                         | `wire1_t`               | 1     | 8  | 8     | front-end/front_IO.h:88  |
| bpu_in.loop_idx[COMMIT_WIDTH]                          | `tage_loop_meta_idx_t`  | 16    | 8  | 128   | front-end/front_IO.h:89  |
| bpu_in.loop_tag[COMMIT_WIDTH]                          | `tage_loop_meta_tag_t`  | 16    | 8  | 128   | front-end/front_IO.h:90  |
| bpu_in.icache_read_ready                               | `wire1_t`               | 1     | 1  | 1     | front-end/front_IO.h:91  |
| bpu_input                                              | `BPU_TOP::InputPayload` | 2738  | 1  | 2738  | front-end/train_IO.h:339 |
| bpu_input.refetch                                      | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/BPU.h:113  |
| bpu_input.refetch_address                              | `fetch_addr_t`          | 32    | 1  | 32    | front-end/BPU/BPU.h:115  |
| bpu_input.icache_read_ready                            | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/BPU.h:116  |
| bpu_input.in_update_base_pc[COMMIT_WIDTH]              | `pc_t`                  | 32    | 8  | 256   | front-end/BPU/BPU.h:117  |
| bpu_input.in_upd_valid[COMMIT_WIDTH]                   | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:120  |
| bpu_input.in_actual_dir[COMMIT_WIDTH]                  | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:121  |
| bpu_input.in_actual_br_type[COMMIT_WIDTH]              | `br_type_t`             | 3     | 8  | 24    | front-end/BPU/BPU.h:122  |
| bpu_input.in_actual_targets[COMMIT_WIDTH]              | `target_addr_t`         | 32    | 8  | 256   | front-end/BPU/BPU.h:123  |
| bpu_input.in_pred_dir[COMMIT_WIDTH]                    | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:124  |
| bpu_input.in_alt_pred[COMMIT_WIDTH]                    | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:126  |
| bpu_input.in_pcpn[COMMIT_WIDTH]                        | `pcpn_t`                | 3     | 8  | 24    | front-end/BPU/BPU.h:127  |
| bpu_input.in_altpcpn[COMMIT_WIDTH]                     | `pcpn_t`                | 3     | 8  | 24    | front-end/BPU/BPU.h:128  |
| bpu_input.in_tage_tags[COMMIT_WIDTH][TN_MAX]           | `tage_tag_t`            | 8     | 32 | 256   | front-end/BPU/BPU.h:129  |
| bpu_input.in_tage_idxs[COMMIT_WIDTH][TN_MAX]           | `tage_idx_t`            | 12    | 32 | 384   | front-end/BPU/BPU.h:130  |
| bpu_input.in_sc_used[COMMIT_WIDTH]                     | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:131  |
| bpu_input.in_sc_pred[COMMIT_WIDTH]                     | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:132  |
| bpu_input.in_sc_sum[COMMIT_WIDTH]                      | `tage_scl_meta_sum_t`   | 16    | 8  | 128   | front-end/BPU/BPU.h:133  |
| bpu_input.in_sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`   | 16    | 64 | 1024  | front-end/BPU/BPU.h:134  |
| bpu_input.in_loop_used[COMMIT_WIDTH]                   | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:135  |
| bpu_input.in_loop_hit[COMMIT_WIDTH]                    | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:136  |
| bpu_input.in_loop_pred[COMMIT_WIDTH]                   | `wire1_t`               | 1     | 8  | 8     | front-end/BPU/BPU.h:137  |
| bpu_input.in_loop_idx[COMMIT_WIDTH]                    | `tage_loop_meta_idx_t`  | 16    | 8  | 128   | front-end/BPU/BPU.h:138  |
| bpu_input.in_loop_tag[COMMIT_WIDTH]                    | `tage_loop_meta_tag_t`  | 16    | 8  | 128   | front-end/BPU/BPU.h:139  |

