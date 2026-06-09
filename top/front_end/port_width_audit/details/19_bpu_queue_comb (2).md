# bpu_queue_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/BPU.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                | bit  |
| -- | ----------------- | ---- |
| 输入 | `BpuQueueCombIn`  | 3152 |
| 输出 | `BpuQueueCombOut` | 3281 |


## 输入展开

| 字段                                           | 类型                     | 单项bit | 数量 | 合计bit | 来源                      |
| -------------------------------------------- | ---------------------- | ----- | -- | ----- | ----------------------- |
| in_update_base_pc[COMMIT_WIDTH]              | `pc_t`                 | 32    | 8  | 256   | front-end/BPU/BPU.h:542 |
| in_upd_valid[COMMIT_WIDTH]                   | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:543 |
| in_actual_dir[COMMIT_WIDTH]                  | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:544 |
| in_actual_br_type[COMMIT_WIDTH]              | `br_type_t`            | 3     | 8  | 24    | front-end/BPU/BPU.h:545 |
| in_actual_targets[COMMIT_WIDTH]              | `target_addr_t`        | 32    | 8  | 256   | front-end/BPU/BPU.h:546 |
| in_pred_dir[COMMIT_WIDTH]                    | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:547 |
| in_alt_pred[COMMIT_WIDTH]                    | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:548 |
| in_pcpn[COMMIT_WIDTH]                        | `pcpn_t`               | 3     | 8  | 24    | front-end/BPU/BPU.h:549 |
| in_altpcpn[COMMIT_WIDTH]                     | `pcpn_t`               | 3     | 8  | 24    | front-end/BPU/BPU.h:550 |
| in_tage_tags[COMMIT_WIDTH][TN_MAX]           | `tage_tag_t`           | 8     | 32 | 256   | front-end/BPU/BPU.h:551 |
| in_tage_idxs[COMMIT_WIDTH][TN_MAX]           | `tage_idx_t`           | 12    | 32 | 384   | front-end/BPU/BPU.h:552 |
| in_sc_used[COMMIT_WIDTH]                     | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:553 |
| in_sc_pred[COMMIT_WIDTH]                     | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:554 |
| in_sc_sum[COMMIT_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 8  | 128   | front-end/BPU/BPU.h:555 |
| in_sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 64 | 1024  | front-end/BPU/BPU.h:556 |
| in_loop_used[COMMIT_WIDTH]                   | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:557 |
| in_loop_hit[COMMIT_WIDTH]                    | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:558 |
| in_loop_pred[COMMIT_WIDTH]                   | `wire1_t`              | 1     | 8  | 8     | front-end/BPU/BPU.h:559 |
| in_loop_idx[COMMIT_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 8  | 128   | front-end/BPU/BPU.h:560 |
| in_loop_tag[COMMIT_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 8  | 128   | front-end/BPU/BPU.h:561 |
| q_wr_ptr_snapshot[BPU_BANK_NUM]              | `queue_ptr_t`          | 9     | 16 | 144   | front-end/BPU/BPU.h:562 |
| q_rd_ptr_snapshot[BPU_BANK_NUM]              | `queue_ptr_t`          | 9     | 16 | 144   | front-end/BPU/BPU.h:563 |
| q_count_snapshot[BPU_BANK_NUM]               | `queue_count_t`        | 9     | 16 | 144   | front-end/BPU/BPU.h:564 |
| going_to_do_upd[BPU_BANK_NUM]                | `wire1_t`              | 1     | 16 | 16    | front-end/BPU/BPU.h:565 |


## 输出展开

| 字段                                       | 类型                             | 单项bit | 数量 | 合计bit | 来源                      |
| ---------------------------------------- | ------------------------------ | ----- | -- | ----- | ----------------------- |
| q_push_en[BPU_BANK_NUM]                  | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/BPU.h:569 |
| q_pop_en[BPU_BANK_NUM]                   | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/BPU.h:570 |
| q_wr_ptr_next[BPU_BANK_NUM]              | `queue_ptr_t`                  | 9     | 16 | 144   | front-end/BPU/BPU.h:571 |
| q_rd_ptr_next[BPU_BANK_NUM]              | `queue_ptr_t`                  | 9     | 16 | 144   | front-end/BPU/BPU.h:572 |
| q_count_next[BPU_BANK_NUM]               | `queue_count_t`                | 9     | 16 | 144   | front-end/BPU/BPU.h:573 |
| q_entry_we[COMMIT_WIDTH]                 | `wire1_t`                      | 1     | 8  | 8     | front-end/BPU/BPU.h:574 |
| q_entry_bank[COMMIT_WIDTH]               | `bpu_bank_sel_t`               | 4     | 8  | 32    | front-end/BPU/BPU.h:575 |
| q_entry_slot[COMMIT_WIDTH]               | `queue_ptr_t`                  | 9     | 8  | 72    | front-end/BPU/BPU.h:576 |
| q_entry_data[COMMIT_WIDTH]               | `ReadData::QueueEntrySnapshot` | 338   | 8  | 2704  | front-end/BPU/BPU.h:577 |
| q_entry_data.base_pc                     | `pc_t`                         | 32    | 1  | 32    | front-end/BPU/BPU.h:179 |
| q_entry_data.valid_mask                  | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:180 |
| q_entry_data.actual_dir                  | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:181 |
| q_entry_data.br_type                     | `br_type_t`                    | 3     | 1  | 3     | front-end/BPU/BPU.h:182 |
| q_entry_data.targets                     | `target_addr_t`                | 32    | 1  | 32    | front-end/BPU/BPU.h:183 |
| q_entry_data.pred_dir                    | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:184 |
| q_entry_data.alt_pred                    | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:185 |
| q_entry_data.pcpn                        | `pcpn_t`                       | 3     | 1  | 3     | front-end/BPU/BPU.h:186 |
| q_entry_data.altpcpn                     | `pcpn_t`                       | 3     | 1  | 3     | front-end/BPU/BPU.h:187 |
| q_entry_data.tage_tags[TN_MAX]           | `tage_tag_t`                   | 8     | 4  | 32    | front-end/BPU/BPU.h:188 |
| q_entry_data.tage_idxs[TN_MAX]           | `tage_idx_t`                   | 12    | 4  | 48    | front-end/BPU/BPU.h:189 |
| q_entry_data.sc_used                     | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:190 |
| q_entry_data.sc_pred                     | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:191 |
| q_entry_data.sc_sum                      | `tage_scl_meta_sum_t`          | 16    | 1  | 16    | front-end/BPU/BPU.h:192 |
| q_entry_data.sc_idx[BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`          | 16    | 8  | 128   | front-end/BPU/BPU.h:193 |
| q_entry_data.loop_used                   | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:194 |
| q_entry_data.loop_hit                    | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:195 |
| q_entry_data.loop_pred                   | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:196 |
| q_entry_data.loop_idx                    | `tage_loop_meta_idx_t`         | 16    | 1  | 16    | front-end/BPU/BPU.h:197 |
| q_entry_data.loop_tag                    | `tage_loop_meta_tag_t`         | 16    | 1  | 16    | front-end/BPU/BPU.h:198 |
| update_queue_full                        | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/BPU.h:578 |

