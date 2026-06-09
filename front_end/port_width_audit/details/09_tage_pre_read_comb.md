# tage_pre_read_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/dir_predictor/TAGE_top.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                   | bit  |
| -- | -------------------- | ---- |
| 输入 | `TagePreReadCombIn`  | 2528 |
| 输出 | `TagePreReadCombOut` | 579  |


## 输入展开

| 字段                                                 | 类型                     | 单项bit | 数量  | 合计bit | 来源                                         |
| -------------------------------------------------- | ---------------------- | ----- | --- | ----- | ------------------------------------------ |
| inp                                                | `InputPayload`         | 1248  | 1   | 1248  | front-end/BPU/dir_predictor/TAGE_top.h:591 |
| inp.pred_req                                       | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:311 |
| inp.pc_pred_in                                     | `pc_t`                 | 32    | 1   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:312 |
| inp.ghr_in[GHR_LENGTH]                             | `wire1_t`              | 1     | 512 | 512   | front-end/BPU/dir_predictor/TAGE_top.h:313 |
| inp.fh_in[FH_N_MAX][TN_MAX]                        | `wire32_t`             | 32    | 12  | 384   | front-end/BPU/dir_predictor/TAGE_top.h:314 |
| inp.path_in                                        | `tage_path_hist_t`     | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:315 |
| inp.update_en                                      | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:316 |
| inp.pc_update_in                                   | `pc_t`                 | 32    | 1   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:317 |
| inp.real_dir                                       | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:318 |
| inp.pred_in                                        | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:319 |
| inp.alt_pred_in                                    | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:320 |
| inp.pcpn_in                                        | `pcpn_t`               | 3     | 1   | 3     | front-end/BPU/dir_predictor/TAGE_top.h:321 |
| inp.altpcpn_in                                     | `pcpn_t`               | 3     | 1   | 3     | front-end/BPU/dir_predictor/TAGE_top.h:322 |
| inp.tage_tag_flat_in[TN_MAX]                       | `tage_tag_t`           | 8     | 4   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:323 |
| inp.tage_idx_flat_in[TN_MAX]                       | `tage_idx_t`           | 12    | 4   | 48    | front-end/BPU/dir_predictor/TAGE_top.h:324 |
| inp.sc_used_in                                     | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:325 |
| inp.sc_pred_in                                     | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:326 |
| inp.sc_sum_in                                      | `tage_scl_meta_sum_t`  | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:327 |
| inp.sc_idx_in[BPU_SCL_META_NTABLE]                 | `tage_scl_meta_idx_t`  | 16    | 8   | 128   | front-end/BPU/dir_predictor/TAGE_top.h:328 |
| inp.loop_used_in                                   | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:329 |
| inp.loop_hit_in                                    | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:330 |
| inp.loop_pred_in                                   | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:331 |
| inp.loop_idx_in                                    | `tage_loop_meta_idx_t` | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:332 |
| inp.loop_tag_in                                    | `tage_loop_meta_tag_t` | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:333 |
| state_in                                           | `StateInput`           | 1280  | 1   | 1280  | front-end/BPU/dir_predictor/TAGE_top.h:592 |
| state_in.state                                     | `tage_state_t`         | 2     | 1   | 2     | front-end/BPU/dir_predictor/TAGE_top.h:362 |
| state_in.FH[FH_N_MAX][TN_MAX]                      | `wire32_t`             | 32    | 12  | 384   | front-end/BPU/dir_predictor/TAGE_top.h:363 |
| state_in.GHR[GHR_LENGTH]                           | `wire1_t`              | 1     | 512 | 512   | front-end/BPU/dir_predictor/TAGE_top.h:364 |
| state_in.LSFR[4]                                   | `wire1_t`              | 1     | 4   | 4     | front-end/BPU/dir_predictor/TAGE_top.h:365 |
| state_in.reset_cnt_reg                             | `tage_reset_ctr_t`     | 23    | 1   | 23    | front-end/BPU/dir_predictor/TAGE_top.h:366 |
| state_in.use_alt_ctr_reg                           | `tage_use_alt_ctr_t`   | 4     | 1   | 4     | front-end/BPU/dir_predictor/TAGE_top.h:367 |
| state_in.scl_theta_reg                             | `tage_scl_theta_t`     | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:369 |
| state_in.do_pred_latch                             | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:371 |
| state_in.do_upd_latch                              | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:374 |
| state_in.upd_real_dir_latch                        | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:375 |
| state_in.upd_pc_latch                              | `pc_t`                 | 32    | 1   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:376 |
| state_in.upd_pred_in_latch                         | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:377 |
| state_in.upd_alt_pred_in_latch                     | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:378 |
| state_in.upd_pcpn_in_latch                         | `pcpn_t`               | 3     | 1   | 3     | front-end/BPU/dir_predictor/TAGE_top.h:379 |
| state_in.upd_altpcpn_in_latch                      | `pcpn_t`               | 3     | 1   | 3     | front-end/BPU/dir_predictor/TAGE_top.h:380 |
| state_in.upd_tage_tag_flat_latch[TN_MAX]           | `tage_tag_t`           | 8     | 4   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:381 |
| state_in.upd_tage_idx_flat_latch[TN_MAX]           | `tage_idx_t`           | 12    | 4   | 48    | front-end/BPU/dir_predictor/TAGE_top.h:382 |
| state_in.pred_calc_base_idx_latch                  | `tage_base_idx_t`      | 11    | 1   | 11    | front-end/BPU/dir_predictor/TAGE_top.h:383 |
| state_in.pred_calc_tage_idx_latch[TN_MAX]          | `tage_idx_t`           | 12    | 4   | 48    | front-end/BPU/dir_predictor/TAGE_top.h:385 |
| state_in.pred_calc_tage_tag_latch[TN_MAX]          | `tage_tag_t`           | 8     | 4   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:386 |
| state_in.pred_pc_latch                             | `pc_t`                 | 32    | 1   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:387 |
| state_in.upd_calc_winfo_latch                      | `UpdateRequest`        | 89    | 1   | 89    | front-end/BPU/dir_predictor/TAGE_top.h:388 |
| state_in.upd_calc_winfo_latch.cnt_we[TN_MAX]       | `wire1_t`              | 1     | 4   | 4     | front-end/BPU/dir_predictor/TAGE_top.h:44  |
| state_in.upd_calc_winfo_latch.cnt_wdata[TN_MAX]    | `tage_cnt_t`           | 3     | 4   | 12    | front-end/BPU/dir_predictor/TAGE_top.h:45  |
| state_in.upd_calc_winfo_latch.useful_we[TN_MAX]    | `wire1_t`              | 1     | 4   | 4     | front-end/BPU/dir_predictor/TAGE_top.h:46  |
| state_in.upd_calc_winfo_latch.useful_wdata[TN_MAX] | `tage_useful_t`        | 2     | 4   | 8     | front-end/BPU/dir_predictor/TAGE_top.h:47  |
| state_in.upd_calc_winfo_latch.tag_we[TN_MAX]       | `wire1_t`              | 1     | 4   | 4     | front-end/BPU/dir_predictor/TAGE_top.h:48  |
| state_in.upd_calc_winfo_latch.tag_wdata[TN_MAX]    | `tage_tag_t`           | 8     | 4   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:49  |
| state_in.upd_calc_winfo_latch.base_we              | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:50  |
| state_in.upd_calc_winfo_latch.base_wdata           | `tage_base_cnt_t`      | 2     | 1   | 2     | front-end/BPU/dir_predictor/TAGE_top.h:51  |
| state_in.upd_calc_winfo_latch.sc_we                | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:52  |
| state_in.upd_calc_winfo_latch.sc_wdata             | `tage_sc_ctr_t`        | 2     | 1   | 2     | front-end/BPU/dir_predictor/TAGE_top.h:53  |
| state_in.upd_calc_winfo_latch.reset_we             | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:54  |
| state_in.upd_calc_winfo_latch.reset_row_idx        | `tage_idx_t`           | 12    | 1   | 12    | front-end/BPU/dir_predictor/TAGE_top.h:55  |
| state_in.upd_calc_winfo_latch.reset_msb_only       | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:56  |
| state_in.upd_calc_winfo_latch.use_alt_ctr_we       | `wire1_t`              | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:57  |
| state_in.upd_calc_winfo_latch.use_alt_ctr_wdata    | `tage_use_alt_ctr_t`   | 4     | 1   | 4     | front-end/BPU/dir_predictor/TAGE_top.h:58  |


## 输出展开

| 字段                                                  | 类型                              | 单项bit | 数量 | 合计bit | 来源                                         |
| --------------------------------------------------- | ------------------------------- | ----- | -- | ----- | ------------------------------------------ |
| pred_req                                            | `TagePredReadReqCombOut`        | 262   | 1  | 262   | front-end/BPU/dir_predictor/TAGE_top.h:596 |
| pred_req.pred_read_valid                            | `wire1_t`                       | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:548 |
| pred_req.pred_idx_tag                               | `TageIndexTag`                  | 91    | 1  | 91    | front-end/BPU/dir_predictor/TAGE_top.h:549 |
| pred_req.pred_idx_tag.index_info                    | `TageIndex`                     | 80    | 1  | 80    | front-end/BPU/dir_predictor/TAGE_top.h:24  |
| pred_req.pred_idx_tag.index_info.tage_index[TN_MAX] | `tage_idx_t`                    | 12    | 4  | 48    | front-end/BPU/dir_predictor/TAGE_top.h:18  |
| pred_req.pred_idx_tag.index_info.tag[TN_MAX]        | `tage_tag_t`                    | 8     | 4  | 32    | front-end/BPU/dir_predictor/TAGE_top.h:19  |
| pred_req.pred_idx_tag.base_idx                      | `tage_base_idx_t`               | 11    | 1  | 11    | front-end/BPU/dir_predictor/TAGE_top.h:25  |
| pred_req.pred_sc_idx                                | `tage_sc_idx_t`                 | 10    | 1  | 10    | front-end/BPU/dir_predictor/TAGE_top.h:550 |
| pred_req.pred_scl_idx[BPU_SCL_META_NTABLE]          | `tage_scl_meta_idx_t`           | 16    | 8  | 128   | front-end/BPU/dir_predictor/TAGE_top.h:551 |
| pred_req.pred_loop_idx                              | `tage_loop_meta_idx_t`          | 16    | 1  | 16    | front-end/BPU/dir_predictor/TAGE_top.h:552 |
| pred_req.pred_loop_tag                              | `tage_loop_meta_tag_t`          | 16    | 1  | 16    | front-end/BPU/dir_predictor/TAGE_top.h:553 |
| upd_req                                             | `TageUpdReadReqCombOut`         | 244   | 1  | 244   | front-end/BPU/dir_predictor/TAGE_top.h:597 |
| upd_req.upd_read_valid                              | `wire1_t`                       | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:562 |
| upd_req.upd_base_idx                                | `tage_base_idx_t`               | 11    | 1  | 11    | front-end/BPU/dir_predictor/TAGE_top.h:563 |
| upd_req.upd_sc_idx                                  | `tage_sc_idx_t`                 | 10    | 1  | 10    | front-end/BPU/dir_predictor/TAGE_top.h:564 |
| upd_req.upd_tage_idx_flat[TN_MAX]                   | `tage_idx_t`                    | 12    | 4  | 48    | front-end/BPU/dir_predictor/TAGE_top.h:565 |
| upd_req.upd_scl_idx[BPU_SCL_META_NTABLE]            | `tage_scl_meta_idx_t`           | 16    | 8  | 128   | front-end/BPU/dir_predictor/TAGE_top.h:566 |
| upd_req.upd_loop_idx                                | `tage_loop_meta_idx_t`          | 16    | 1  | 16    | front-end/BPU/dir_predictor/TAGE_top.h:567 |
| upd_req.upd_loop_tag                                | `tage_loop_meta_tag_t`          | 16    | 1  | 16    | front-end/BPU/dir_predictor/TAGE_top.h:568 |
| upd_req.upd_loop_read_valid                         | `wire1_t`                       | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:569 |
| upd_req.upd_reset_row_valid                         | `wire1_t`                       | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:570 |
| upd_req.upd_reset_row_idx                           | `tage_idx_t`                    | 12    | 1  | 12    | front-end/BPU/dir_predictor/TAGE_top.h:571 |
| useful_reset_req                                    | `TageUsefulResetReadReqCombOut` | 13    | 1  | 13    | front-end/BPU/dir_predictor/TAGE_top.h:598 |
| useful_reset_req.useful_reset_row_data_valid        | `wire1_t`                       | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:579 |
| useful_reset_req.useful_reset_row_idx               | `tage_idx_t`                    | 12    | 1  | 12    | front-end/BPU/dir_predictor/TAGE_top.h:580 |
| idx                                                 | `IndexResult`                   | 60    | 1  | 60    | front-end/BPU/dir_predictor/TAGE_top.h:599 |
| idx.table_base_idx                                  | `tage_base_idx_t`               | 11    | 1  | 11    | front-end/BPU/dir_predictor/TAGE_top.h:393 |
| idx.table_tage_idx[TN_MAX]                          | `tage_idx_t`                    | 12    | 4  | 48    | front-end/BPU/dir_predictor/TAGE_top.h:394 |
| idx.table_read_address_valid                        | `wire1_t`                       | 1     | 1  | 1     | front-end/BPU/dir_predictor/TAGE_top.h:395 |

