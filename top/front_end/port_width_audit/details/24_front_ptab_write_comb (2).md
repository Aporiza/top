# front_ptab_write_comb

- 分组：`front_top glue`
- 源码依据：`train_IO.h / front_top.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                      | bit  |
| -- | ----------------------- | ---- |
| 输入 | `FrontPtabWriteCombIn`  | 4473 |
| 输出 | `FrontPtabWriteCombOut` | 4853 |


## 输入展开

| 字段                                                      | 类型                       | 单项bit | 数量  | 合计bit | 来源                       |
| ------------------------------------------------------- | ------------------------ | ----- | --- | ----- | ------------------------ |
| bpu_output                                              | `BPU_TOP::OutputPayload` | 4470  | 1   | 4470  | front-end/train_IO.h:351 |
| bpu_output.fetch_address                                | `fetch_addr_t`           | 32    | 1   | 32    | front-end/BPU/BPU.h:143  |
| bpu_output.icache_read_valid                            | `wire1_t`                | 1     | 1   | 1     | front-end/BPU/BPU.h:144  |
| bpu_output.predict_next_fetch_address                   | `fetch_addr_t`           | 32    | 1   | 32    | front-end/BPU/BPU.h:145  |
| bpu_output.PTAB_write_enable                            | `wire1_t`                | 1     | 1   | 1     | front-end/BPU/BPU.h:146  |
| bpu_output.out_pred_dir[FETCH_WIDTH]                    | `wire1_t`                | 1     | 16  | 16    | front-end/BPU/BPU.h:147  |
| bpu_output.out_alt_pred[FETCH_WIDTH]                    | `wire1_t`                | 1     | 16  | 16    | front-end/BPU/BPU.h:148  |
| bpu_output.out_pcpn[FETCH_WIDTH]                        | `pcpn_t`                 | 3     | 16  | 48    | front-end/BPU/BPU.h:149  |
| bpu_output.out_altpcpn[FETCH_WIDTH]                     | `pcpn_t`                 | 3     | 16  | 48    | front-end/BPU/BPU.h:150  |
| bpu_output.out_tage_tags[FETCH_WIDTH][TN_MAX]           | `tage_tag_t`             | 8     | 64  | 512   | front-end/BPU/BPU.h:151  |
| bpu_output.out_tage_idxs[FETCH_WIDTH][TN_MAX]           | `tage_idx_t`             | 12    | 64  | 768   | front-end/BPU/BPU.h:152  |
| bpu_output.out_sc_used[FETCH_WIDTH]                     | `wire1_t`                | 1     | 16  | 16    | front-end/BPU/BPU.h:153  |
| bpu_output.out_sc_pred[FETCH_WIDTH]                     | `wire1_t`                | 1     | 16  | 16    | front-end/BPU/BPU.h:154  |
| bpu_output.out_sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`    | 16    | 16  | 256   | front-end/BPU/BPU.h:155  |
| bpu_output.out_sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`    | 16    | 128 | 2048  | front-end/BPU/BPU.h:156  |
| bpu_output.out_loop_used[FETCH_WIDTH]                   | `wire1_t`                | 1     | 16  | 16    | front-end/BPU/BPU.h:157  |
| bpu_output.out_loop_hit[FETCH_WIDTH]                    | `wire1_t`                | 1     | 16  | 16    | front-end/BPU/BPU.h:158  |
| bpu_output.out_loop_pred[FETCH_WIDTH]                   | `wire1_t`                | 1     | 16  | 16    | front-end/BPU/BPU.h:159  |
| bpu_output.out_loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t`   | 16    | 16  | 256   | front-end/BPU/BPU.h:160  |
| bpu_output.out_loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t`   | 16    | 16  | 256   | front-end/BPU/BPU.h:161  |
| bpu_output.out_pred_base_pc                             | `pc_t`                   | 32    | 1   | 32    | front-end/BPU/BPU.h:162  |
| bpu_output.update_queue_full                            | `wire1_t`                | 1     | 1   | 1     | front-end/BPU/BPU.h:163  |
| bpu_output.two_ahead_valid                              | `wire1_t`                | 1     | 1   | 1     | front-end/BPU/BPU.h:164  |
| bpu_output.two_ahead_target                             | `fetch_addr_t`           | 32    | 1   | 32    | front-end/BPU/BPU.h:167  |
| bpu_output.mini_flush_req                               | `wire1_t`                | 1     | 1   | 1     | front-end/BPU/BPU.h:168  |
| bpu_output.mini_flush_correct                           | `wire1_t`                | 1     | 1   | 1     | front-end/BPU/BPU.h:170  |
| bpu_output.mini_flush_target                            | `fetch_addr_t`           | 32    | 1   | 32    | front-end/BPU/BPU.h:172  |
| global_reset                                            | `wire1_t`                | 1     | 1   | 1     | front-end/train_IO.h:352 |
| global_refetch                                          | `wire1_t`                | 1     | 1   | 1     | front-end/train_IO.h:353 |
| ptab_can_write                                          | `wire1_t`                | 1     | 1   | 1     | front-end/train_IO.h:354 |


## 输出展开

| 字段                                               | 类型                     | 单项bit | 数量  | 合计bit | 来源                       |
| ------------------------------------------------ | ---------------------- | ----- | --- | ----- | ------------------------ |
| ptab_in                                          | `PTAB_in`              | 4853  | 1   | 4853  | front-end/train_IO.h:358 |
| ptab_in.reset                                    | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:207 |
| ptab_in.refetch                                  | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:208 |
| ptab_in.write_enable                             | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:209 |
| ptab_in.predict_dir[FETCH_WIDTH]                 | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:211 |
| ptab_in.predict_next_fetch_address               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_IO.h:212 |
| ptab_in.predict_base_pc[FETCH_WIDTH]             | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:213 |
| ptab_in.alt_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:214 |
| ptab_in.altpcpn[FETCH_WIDTH]                     | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:216 |
| ptab_in.pcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:217 |
| ptab_in.tage_idx[FETCH_WIDTH][4]                 | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_IO.h:218 |
| ptab_in.tage_tag[FETCH_WIDTH][4]                 | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_IO.h:219 |
| ptab_in.sc_used[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:220 |
| ptab_in.sc_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:221 |
| ptab_in.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_IO.h:222 |
| ptab_in.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_IO.h:223 |
| ptab_in.loop_used[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:224 |
| ptab_in.loop_hit[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:225 |
| ptab_in.loop_pred[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:226 |
| ptab_in.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_IO.h:227 |
| ptab_in.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_IO.h:228 |
| ptab_in.read_enable                              | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:229 |
| ptab_in.need_mini_flush                          | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:231 |

