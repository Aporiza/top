# bpu_hist_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/BPU.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型               | bit  |
| -- | ---------------- | ---- |
| 输入 | `BpuHistCombIn`  | 6944 |
| 输出 | `BpuHistCombOut` | 5935 |


## 输入展开

| 字段                                   | 类型                             | 单项bit | 数量  | 合计bit | 来源                                              |
| ------------------------------------ | ------------------------------ | ----- | --- | ----- | ----------------------------------------------- |
| refetch                              | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:503                         |
| in_update_base_pc[COMMIT_WIDTH]      | `pc_t`                         | 32    | 8   | 256   | front-end/BPU/BPU.h:504                         |
| in_upd_valid[COMMIT_WIDTH]           | `wire1_t`                      | 1     | 8   | 8     | front-end/BPU/BPU.h:505                         |
| in_actual_dir[COMMIT_WIDTH]          | `wire1_t`                      | 1     | 8   | 8     | front-end/BPU/BPU.h:506                         |
| in_actual_br_type[COMMIT_WIDTH]      | `br_type_t`                    | 3     | 8   | 24    | front-end/BPU/BPU.h:507                         |
| in_pred_dir[COMMIT_WIDTH]            | `wire1_t`                      | 1     | 8   | 8     | front-end/BPU/BPU.h:508                         |
| going_to_do_pred                     | `wire1_t`                      | 1     | 1   | 1     | front-end/BPU/BPU.h:509                         |
| do_pred_on_this_pc[FETCH_WIDTH]      | `wire1_t`                      | 1     | 16  | 16    | front-end/BPU/BPU.h:510                         |
| this_pc_bank_sel[FETCH_WIDTH]        | `bpu_bank_sel_ext_t`           | 5     | 16  | 80    | front-end/BPU/BPU.h:511                         |
| do_pred_for_this_pc[FETCH_WIDTH]     | `pc_t`                         | 32    | 16  | 512   | front-end/BPU/BPU.h:512                         |
| Spec_GHR_snapshot[GHR_LENGTH]        | `wire1_t`                      | 1     | 512 | 512   | front-end/BPU/BPU.h:513                         |
| Spec_FH_snapshot[FH_N_MAX][TN_MAX]   | `wire32_t`                     | 32    | 12  | 384   | front-end/BPU/BPU.h:514                         |
| Arch_GHR_snapshot[GHR_LENGTH]        | `wire1_t`                      | 1     | 512 | 512   | front-end/BPU/BPU.h:515                         |
| Arch_FH_snapshot[FH_N_MAX][TN_MAX]   | `wire32_t`                     | 32    | 12  | 384   | front-end/BPU/BPU.h:516                         |
| Spec_PATH_snapshot                   | `tage_path_hist_t`             | 16    | 1   | 16    | front-end/BPU/BPU.h:517                         |
| Arch_PATH_snapshot                   | `tage_path_hist_t`             | 16    | 1   | 16    | front-end/BPU/BPU.h:518                         |
| Arch_ras_stack_snapshot[RAS_DEPTH]   | `target_addr_t`                | 32    | 64  | 2048  | front-end/BPU/BPU.h:519                         |
| Arch_ras_count_snapshot              | `ras_count_t`                  | 7     | 1   | 7     | front-end/BPU/BPU.h:520                         |
| Spec_ras_stack_snapshot[RAS_DEPTH]   | `target_addr_t`                | 32    | 64  | 2048  | front-end/BPU/BPU.h:521                         |
| Spec_ras_count_snapshot              | `ras_count_t`                  | 7     | 1   | 7     | front-end/BPU/BPU.h:522                         |
| type_out                             | `TypePredictor::OutputPayload` | 80    | 1   | 80    | front-end/BPU/BPU.h:523                         |
| type_out.pred_type[FETCH_WIDTH]      | `br_type_t`                    | 3     | 16  | 48    | front-end/BPU/type_predictor/TypePredictor.h:25 |
| type_out.pred_hit[FETCH_WIDTH]       | `wire1_t`                      | 1     | 16  | 16    | front-end/BPU/type_predictor/TypePredictor.h:26 |
| type_out.pred_confident[FETCH_WIDTH] | `wire1_t`                      | 1     | 16  | 16    | front-end/BPU/type_predictor/TypePredictor.h:27 |
| final_pred_dir[FETCH_WIDTH]          | `wire1_t`                      | 1     | 16  | 16    | front-end/BPU/BPU.h:524                         |


## 输出展开

| 字段                             | 类型                 | 单项bit | 数量  | 合计bit | 来源                      |
| ------------------------------ | ------------------ | ----- | --- | ----- | ----------------------- |
| should_update_spec_hist        | `wire1_t`          | 1     | 1   | 1     | front-end/BPU/BPU.h:528 |
| Spec_GHR_next[GHR_LENGTH]      | `wire1_t`          | 1     | 512 | 512   | front-end/BPU/BPU.h:529 |
| Spec_FH_next[FH_N_MAX][TN_MAX] | `wire32_t`         | 32    | 12  | 384   | front-end/BPU/BPU.h:530 |
| Arch_GHR_next[GHR_LENGTH]      | `wire1_t`          | 1     | 512 | 512   | front-end/BPU/BPU.h:531 |
| Arch_FH_next[FH_N_MAX][TN_MAX] | `wire32_t`         | 32    | 12  | 384   | front-end/BPU/BPU.h:532 |
| Spec_PATH_next                 | `tage_path_hist_t` | 16    | 1   | 16    | front-end/BPU/BPU.h:533 |
| Arch_PATH_next                 | `tage_path_hist_t` | 16    | 1   | 16    | front-end/BPU/BPU.h:534 |
| Arch_ras_stack_next[RAS_DEPTH] | `target_addr_t`    | 32    | 64  | 2048  | front-end/BPU/BPU.h:535 |
| Arch_ras_count_next            | `ras_count_t`      | 7     | 1   | 7     | front-end/BPU/BPU.h:536 |
| Spec_ras_stack_next[RAS_DEPTH] | `target_addr_t`    | 32    | 64  | 2048  | front-end/BPU/BPU.h:537 |
| Spec_ras_count_next            | `ras_count_t`      | 7     | 1   | 7     | front-end/BPU/BPU.h:538 |

