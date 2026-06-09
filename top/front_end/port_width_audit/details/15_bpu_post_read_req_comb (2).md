# bpu_post_read_req_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/BPU.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                      | bit   |
| -- | ----------------------- | ----- |
| 输入 | `BpuPostReadReqCombIn`  | 7332  |
| 输出 | `BpuPostReadReqCombOut` | 22509 |


## 输入展开

| 字段                                        | 类型                             | 单项bit | 数量  | 合计bit | 来源                      |
| ----------------------------------------- | ------------------------------ | ----- | --- | ----- | ----------------------- |
| refetch                                   | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:392 |
| in_update_base_pc[COMMIT_WIDTH]           | `pc_t`                         | 32    | 8   | 256   | front-end/BPU/BPU.h:393 |
| in_upd_valid[COMMIT_WIDTH]                | `wire1_t`                      | 1     | 8   | 8     | front-end/BPU/BPU.h:394 |
| in_actual_br_type[COMMIT_WIDTH]           | `br_type_t`                    | 3     | 8   | 24    | front-end/BPU/BPU.h:395 |
| ghr_snapshot[GHR_LENGTH]                  | `wire1_t`                      | 1     | 512 | 512   | front-end/BPU/BPU.h:396 |
| fh_snapshot[FH_N_MAX][TN_MAX]             | `wire32_t`                     | 32    | 12  | 384   | front-end/BPU/BPU.h:397 |
| path_snapshot                             | `tage_path_hist_t`             | 16    | 1   | 16    | front-end/BPU/BPU.h:398 |
| pred_base_pc                              | `pc_t`                         | 32    | 1   | 32    | front-end/BPU/BPU.h:399 |
| going_to_do_pred                          | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:400 |
| set_submodule_input                       | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:401 |
| do_pred_on_this_pc[FETCH_WIDTH]           | `wire1_t`                      | 1     | 16  | 16    | front-end/BPU/BPU.h:402 |
| this_pc_bank_sel[FETCH_WIDTH]             | `bpu_bank_sel_ext_t`           | 5     | 16  | 80    | front-end/BPU/BPU.h:403 |
| do_pred_for_this_pc[FETCH_WIDTH]          | `pc_t`                         | 32    | 16  | 512   | front-end/BPU/BPU.h:404 |
| going_to_do_upd[BPU_BANK_NUM]             | `wire1_t`                      | 1     | 16  | 16    | front-end/BPU/BPU.h:405 |
| q_data[BPU_BANK_NUM]                      | `ReadData::QueueEntrySnapshot` | 338   | 16  | 5408  | front-end/BPU/BPU.h:406 |
| q_data.base_pc                            | `pc_t`                         | 32    | 1   | 32    | front-end/BPU/BPU.h:179 |
| q_data.valid_mask                         | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:180 |
| q_data.actual_dir                         | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:181 |
| q_data.br_type                            | `br_type_t`                    | 3     | 1   | 3     | front-end/BPU/BPU.h:182 |
| q_data.targets                            | `target_addr_t`                | 32    | 1   | 32    | front-end/BPU/BPU.h:183 |
| q_data.pred_dir                           | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:184 |
| q_data.alt_pred                           | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:185 |
| q_data.pcpn                               | `pcpn_t`                       | 3     | 1   | 3     | front-end/BPU/BPU.h:186 |
| q_data.altpcpn                            | `pcpn_t`                       | 3     | 1   | 3     | front-end/BPU/BPU.h:187 |
| q_data.tage_tags[TN_MAX]                  | `tage_tag_t`                   | 8     | 4   | 32    | front-end/BPU/BPU.h:188 |
| q_data.tage_idxs[TN_MAX]                  | `tage_idx_t`                   | 12    | 4   | 48    | front-end/BPU/BPU.h:189 |
| q_data.sc_used                            | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:190 |
| q_data.sc_pred                            | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:191 |
| q_data.sc_sum                             | `tage_scl_meta_sum_t`          | 16    | 1   | 16    | front-end/BPU/BPU.h:192 |
| q_data.sc_idx[BPU_SCL_META_NTABLE]        | `tage_scl_meta_idx_t`          | 16    | 8   | 128   | front-end/BPU/BPU.h:193 |
| q_data.loop_used                          | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:194 |
| q_data.loop_hit                           | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:195 |
| q_data.loop_pred                          | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:196 |
| q_data.loop_idx                           | `tage_loop_meta_idx_t`         | 16    | 1   | 16    | front-end/BPU/BPU.h:197 |
| q_data.loop_tag                           | `tage_loop_meta_tag_t`         | 16    | 1   | 16    | front-end/BPU/BPU.h:198 |
| nlp_pred_base_entry_snapshot              | `ReadData::NlpEntrySnapshot`   | 65    | 1   | 65    | front-end/BPU/BPU.h:407 |
| nlp_pred_base_entry_snapshot.entry_valid  | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:201 |
| nlp_pred_base_entry_snapshot.entry_tag    | `nlp_tag_t`                    | 30    | 1   | 30    | front-end/BPU/BPU.h:202 |
| nlp_pred_base_entry_snapshot.entry_target | `target_addr_t`                | 32    | 1   | 32    | front-end/BPU/BPU.h:203 |
| nlp_pred_base_entry_snapshot.entry_conf   | `nlp_conf_t`                   | 2     | 1   | 2     | front-end/BPU/BPU.h:204 |


## 输出展开

| 字段                                     | 类型                            | 单项bit | 数量  | 合计bit | 来源                                              |
| -------------------------------------- | ----------------------------- | ----- | --- | ----- | ----------------------------------------------- |
| nlp_s1_re                              | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/BPU.h:411                         |
| nlp_s1_idx                             | `nlp_index_t`                 | 12    | 1   | 12    | front-end/BPU/BPU.h:412                         |
| nlp_s1_req_pc                          | `fetch_addr_t`                | 32    | 1   | 32    | front-end/BPU/BPU.h:413                         |
| type_in                                | `TypePredictor::InputPayload` | 816   | 1   | 816   | front-end/BPU/BPU.h:414                         |
| type_in.pred_valid[FETCH_WIDTH]        | `wire1_t`                     | 1     | 16  | 16    | front-end/BPU/type_predictor/TypePredictor.h:9  |
| type_in.pred_pc[FETCH_WIDTH]           | `pc_t`                        | 32    | 16  | 512   | front-end/BPU/type_predictor/TypePredictor.h:10 |
| type_in.upd_valid[COMMIT_WIDTH]        | `wire1_t`                     | 1     | 8   | 8     | front-end/BPU/type_predictor/TypePredictor.h:11 |
| type_in.upd_pc[COMMIT_WIDTH]           | `pc_t`                        | 32    | 8   | 256   | front-end/BPU/type_predictor/TypePredictor.h:12 |
| type_in.upd_br_type[COMMIT_WIDTH]      | `br_type_t`                   | 3     | 8   | 24    | front-end/BPU/type_predictor/TypePredictor.h:13 |
| tage_in[BPU_BANK_NUM]                  | `TAGE_TOP::InputPayload`      | 1248  | 16  | 19968 | front-end/BPU/BPU.h:415                         |
| tage_in.pred_req                       | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:311      |
| tage_in.pc_pred_in                     | `pc_t`                        | 32    | 1   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:312      |
| tage_in.ghr_in[GHR_LENGTH]             | `wire1_t`                     | 1     | 512 | 512   | front-end/BPU/dir_predictor/TAGE_top.h:313      |
| tage_in.fh_in[FH_N_MAX][TN_MAX]        | `wire32_t`                    | 32    | 12  | 384   | front-end/BPU/dir_predictor/TAGE_top.h:314      |
| tage_in.path_in                        | `tage_path_hist_t`            | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:315      |
| tage_in.update_en                      | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:316      |
| tage_in.pc_update_in                   | `pc_t`                        | 32    | 1   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:317      |
| tage_in.real_dir                       | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:318      |
| tage_in.pred_in                        | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:319      |
| tage_in.alt_pred_in                    | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:320      |
| tage_in.pcpn_in                        | `pcpn_t`                      | 3     | 1   | 3     | front-end/BPU/dir_predictor/TAGE_top.h:321      |
| tage_in.altpcpn_in                     | `pcpn_t`                      | 3     | 1   | 3     | front-end/BPU/dir_predictor/TAGE_top.h:322      |
| tage_in.tage_tag_flat_in[TN_MAX]       | `tage_tag_t`                  | 8     | 4   | 32    | front-end/BPU/dir_predictor/TAGE_top.h:323      |
| tage_in.tage_idx_flat_in[TN_MAX]       | `tage_idx_t`                  | 12    | 4   | 48    | front-end/BPU/dir_predictor/TAGE_top.h:324      |
| tage_in.sc_used_in                     | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:325      |
| tage_in.sc_pred_in                     | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:326      |
| tage_in.sc_sum_in                      | `tage_scl_meta_sum_t`         | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:327      |
| tage_in.sc_idx_in[BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`         | 16    | 8   | 128   | front-end/BPU/dir_predictor/TAGE_top.h:328      |
| tage_in.loop_used_in                   | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:329      |
| tage_in.loop_hit_in                    | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:330      |
| tage_in.loop_pred_in                   | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/dir_predictor/TAGE_top.h:331      |
| tage_in.loop_idx_in                    | `tage_loop_meta_idx_t`        | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:332      |
| tage_in.loop_tag_in                    | `tage_loop_meta_tag_t`        | 16    | 1   | 16    | front-end/BPU/dir_predictor/TAGE_top.h:333      |
| btb_in[BPU_BANK_NUM]                   | `BTB_TOP::InputPayload`       | 105   | 16  | 1680  | front-end/BPU/BPU.h:416                         |
| btb_in.pred_pc                         | `pc_t`                        | 32    | 1   | 32    | front-end/BPU/target_predictor/BTB_top.h:40     |
| btb_in.pred_req                        | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/target_predictor/BTB_top.h:41     |
| btb_in.pred_type_in                    | `br_type_t`                   | 3     | 1   | 3     | front-end/BPU/target_predictor/BTB_top.h:42     |
| btb_in.upd_valid                       | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/target_predictor/BTB_top.h:43     |
| btb_in.upd_pc                          | `pc_t`                        | 32    | 1   | 32    | front-end/BPU/target_predictor/BTB_top.h:44     |
| btb_in.upd_actual_addr                 | `target_addr_t`               | 32    | 1   | 32    | front-end/BPU/target_predictor/BTB_top.h:45     |
| btb_in.upd_br_type_in                  | `br_type_t`                   | 3     | 1   | 3     | front-end/BPU/target_predictor/BTB_top.h:46     |
| btb_in.upd_actual_dir                  | `wire1_t`                     | 1     | 1   | 1     | front-end/BPU/target_predictor/BTB_top.h:47     |

