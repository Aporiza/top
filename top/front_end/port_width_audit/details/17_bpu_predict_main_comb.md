# bpu_predict_main_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/BPU.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                      | bit  |
| -- | ----------------------- | ---- |
| 输入 | `BpuPredictMainCombIn`  | 5798 |
| 输出 | `BpuPredictMainCombOut` | 6502 |


## 输入展开

| 字段                                       | 类型                             | 单项bit | 数量 | 合计bit | 来源                                              |
| ---------------------------------------- | ------------------------------ | ----- | -- | ----- | ----------------------------------------------- |
| refetch                                  | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:442                         |
| refetch_address                          | `fetch_addr_t`                 | 32    | 1  | 32    | front-end/BPU/BPU.h:443                         |
| pred_base_pc                             | `pc_t`                         | 32    | 1  | 32    | front-end/BPU/BPU.h:444                         |
| boundary_addr                            | `fetch_addr_t`                 | 32    | 1  | 32    | front-end/BPU/BPU.h:445                         |
| pc_can_send_to_icache_snapshot           | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:446                         |
| going_to_do_pred                         | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:447                         |
| do_pred_on_this_pc[FETCH_WIDTH]          | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/BPU.h:448                         |
| this_pc_bank_sel[FETCH_WIDTH]            | `bpu_bank_sel_ext_t`           | 5     | 16 | 80    | front-end/BPU/BPU.h:449                         |
| do_pred_for_this_pc[FETCH_WIDTH]         | `pc_t`                         | 32    | 16 | 512   | front-end/BPU/BPU.h:450                         |
| ras_has_entry_snapshot                   | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:451                         |
| ras_top_snapshot                         | `target_addr_t`                | 32    | 1  | 32    | front-end/BPU/BPU.h:452                         |
| saved_2ahead_prediction_snapshot         | `fetch_addr_t`                 | 32    | 1  | 32    | front-end/BPU/BPU.h:453                         |
| saved_2ahead_pred_valid_snapshot         | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:454                         |
| saved_mini_flush_correct_snapshot        | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:455                         |
| saved_mini_flush_target_snapshot         | `fetch_addr_t`                 | 32    | 1  | 32    | front-end/BPU/BPU.h:456                         |
| type_out                                 | `TypePredictor::OutputPayload` | 80    | 1  | 80    | front-end/BPU/BPU.h:457                         |
| type_out.pred_type[FETCH_WIDTH]          | `br_type_t`                    | 3     | 16 | 48    | front-end/BPU/type_predictor/TypePredictor.h:25 |
| type_out.pred_hit[FETCH_WIDTH]           | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:26 |
| type_out.pred_confident[FETCH_WIDTH]     | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:27 |
| tage_out[BPU_BANK_NUM]                   | `TAGE_TOP::OutputPayload`      | 272   | 16 | 4352  | front-end/BPU/BPU.h:458                         |
| tage_out.pred_out                        | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:337      |
| tage_out.alt_pred_out                    | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:338      |
| tage_out.pcpn_out                        | `pcpn_t`                       | 3     | 1  | 3     | front-end/BPU/dir_predictor/TAGE_top.h:339      |
| tage_out.altpcpn_out                     | `pcpn_t`                       | 3     | 1  | 3     | front-end/BPU/dir_predictor/TAGE_top.h:340      |
| tage_out.tage_tag_flat_out[TN_MAX]       | `tage_tag_t`                   | 8     | 4  | 32    | front-end/BPU/dir_predictor/TAGE_top.h:341      |
| tage_out.tage_idx_flat_out[TN_MAX]       | `tage_idx_t`                   | 12    | 4  | 48    | front-end/BPU/dir_predictor/TAGE_top.h:343      |
| tage_out.sc_used_out                     | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:344      |
| tage_out.sc_pred_out                     | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:346      |
| tage_out.sc_sum_out                      | `tage_scl_meta_sum_t`          | 16    | 1  | 16    | front-end/BPU/dir_predictor/TAGE_top.h:347      |
| tage_out.sc_idx_out[BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`          | 16    | 8  | 128   | front-end/BPU/dir_predictor/TAGE_top.h:348      |
| tage_out.loop_used_out                   | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:349      |
| tage_out.loop_hit_out                    | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:350      |
| tage_out.loop_pred_out                   | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:351      |
| tage_out.loop_idx_out                    | `tage_loop_meta_idx_t`         | 16    | 1  | 16    | front-end/BPU/dir_predictor/TAGE_top.h:352      |
| tage_out.loop_tag_out                    | `tage_loop_meta_tag_t`         | 16    | 1  | 16    | front-end/BPU/dir_predictor/TAGE_top.h:353      |
| tage_out.tage_pred_out_valid             | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:354      |
| tage_out.tage_update_done                | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:356      |
| tage_out.busy                            | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:357      |
| btb_out[BPU_BANK_NUM]                    | `BTB_TOP::OutputPayload`       | 35    | 16 | 560   | front-end/BPU/BPU.h:459                         |
| btb_out.pred_target                      | `target_addr_t`                | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:51     |
| btb_out.btb_pred_out_valid               | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:52     |
| btb_out.btb_update_done                  | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:53     |
| btb_out.busy                             | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:54     |


## 输出展开

| 字段                                                  | 类型                     | 单项bit | 数量  | 合计bit | 来源                      |
| --------------------------------------------------- | ---------------------- | ----- | --- | ----- | ----------------------- |
| out                                                 | `OutputPayload`        | 4470  | 1   | 4470  | front-end/BPU/BPU.h:463 |
| out.fetch_address                                   | `fetch_addr_t`         | 32    | 1   | 32    | front-end/BPU/BPU.h:143 |
| out.icache_read_valid                               | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/BPU.h:144 |
| out.predict_next_fetch_address                      | `fetch_addr_t`         | 32    | 1   | 32    | front-end/BPU/BPU.h:145 |
| out.PTAB_write_enable                               | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/BPU.h:146 |
| out.out_pred_dir[FETCH_WIDTH]                       | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:147 |
| out.out_alt_pred[FETCH_WIDTH]                       | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:148 |
| out.out_pcpn[FETCH_WIDTH]                           | `pcpn_t`               | 3     | 16  | 48    | front-end/BPU/BPU.h:149 |
| out.out_altpcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/BPU/BPU.h:150 |
| out.out_tage_tags[FETCH_WIDTH][TN_MAX]              | `tage_tag_t`           | 8     | 64  | 512   | front-end/BPU/BPU.h:151 |
| out.out_tage_idxs[FETCH_WIDTH][TN_MAX]              | `tage_idx_t`           | 12    | 64  | 768   | front-end/BPU/BPU.h:152 |
| out.out_sc_used[FETCH_WIDTH]                        | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:153 |
| out.out_sc_pred[FETCH_WIDTH]                        | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:154 |
| out.out_sc_sum[FETCH_WIDTH]                         | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/BPU/BPU.h:155 |
| out.out_sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE]    | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/BPU/BPU.h:156 |
| out.out_loop_used[FETCH_WIDTH]                      | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:157 |
| out.out_loop_hit[FETCH_WIDTH]                       | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:158 |
| out.out_loop_pred[FETCH_WIDTH]                      | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:159 |
| out.out_loop_idx[FETCH_WIDTH]                       | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/BPU/BPU.h:160 |
| out.out_loop_tag[FETCH_WIDTH]                       | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/BPU/BPU.h:161 |
| out.out_pred_base_pc                                | `pc_t`                 | 32    | 1   | 32    | front-end/BPU/BPU.h:162 |
| out.update_queue_full                               | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/BPU.h:163 |
| out.two_ahead_valid                                 | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/BPU.h:164 |
| out.two_ahead_target                                | `fetch_addr_t`         | 32    | 1   | 32    | front-end/BPU/BPU.h:167 |
| out.mini_flush_req                                  | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/BPU.h:168 |
| out.mini_flush_correct                              | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/BPU.h:170 |
| out.mini_flush_target                               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/BPU/BPU.h:172 |
| final_pred_dir[FETCH_WIDTH]                         | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:464 |
| next_fetch_addr_calc                                | `fetch_addr_t`         | 32    | 1   | 32    | front-end/BPU/BPU.h:465 |
| final_2_ahead_address                               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/BPU/BPU.h:466 |
| tage_calc_pred_dir_latch_next[FETCH_WIDTH]          | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:467 |
| tage_calc_altpred_latch_next[FETCH_WIDTH]           | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:468 |
| tage_calc_pcpn_latch_next[FETCH_WIDTH]              | `pcpn_t`               | 3     | 16  | 48    | front-end/BPU/BPU.h:469 |
| tage_calc_altpcpn_latch_next[FETCH_WIDTH]           | `pcpn_t`               | 3     | 16  | 48    | front-end/BPU/BPU.h:470 |
| tage_pred_calc_tags_latch_next[FETCH_WIDTH][TN_MAX] | `tage_tag_t`           | 8     | 64  | 512   | front-end/BPU/BPU.h:471 |
| tage_pred_calc_idxs_latch_next[FETCH_WIDTH][TN_MAX] | `tage_idx_t`           | 12    | 64  | 768   | front-end/BPU/BPU.h:472 |
| tage_result_valid_latch_next[FETCH_WIDTH]           | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:473 |
| btb_pred_target_latch_next[FETCH_WIDTH]             | `target_addr_t`        | 32    | 16  | 512   | front-end/BPU/BPU.h:474 |
| btb_result_valid_latch_next[FETCH_WIDTH]            | `wire1_t`              | 1     | 16  | 16    | front-end/BPU/BPU.h:475 |

