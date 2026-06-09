# bpu_pre_read_req_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/BPU.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                     | bit |
| -- | ---------------------- | --- |
| 输入 | `BpuPreReadReqCombIn`  | 369 |
| 输出 | `BpuPreReadReqCombOut` | 875 |


## 输入展开

| 字段                              | 类型              | 单项bit | 数量 | 合计bit | 来源                      |
| ------------------------------- | --------------- | ----- | -- | ----- | ----------------------- |
| refetch                         | `wire1_t`       | 1     | 1  | 1     | front-end/BPU/BPU.h:360 |
| refetch_address                 | `fetch_addr_t`  | 32    | 1  | 32    | front-end/BPU/BPU.h:361 |
| icache_read_ready               | `wire1_t`       | 1     | 1  | 1     | front-end/BPU/BPU.h:362 |
| pc_reg_snapshot                 | `pc_t`          | 32    | 1  | 32    | front-end/BPU/BPU.h:363 |
| pc_can_send_to_icache_snapshot  | `wire1_t`       | 1     | 1  | 1     | front-end/BPU/BPU.h:364 |
| q_count_snapshot[BPU_BANK_NUM]  | `queue_count_t` | 9     | 16 | 144   | front-end/BPU/BPU.h:365 |
| q_rd_ptr_snapshot[BPU_BANK_NUM] | `queue_ptr_t`   | 9     | 16 | 144   | front-end/BPU/BPU.h:366 |
| Arch_ras_count_snapshot         | `ras_count_t`   | 7     | 1  | 7     | front-end/BPU/BPU.h:367 |
| Spec_ras_count_snapshot         | `ras_count_t`   | 7     | 1  | 7     | front-end/BPU/BPU.h:368 |


## 输出展开

| 字段                               | 类型                   | 单项bit | 数量 | 合计bit | 来源                      |
| -------------------------------- | -------------------- | ----- | -- | ----- | ----------------------- |
| use_arch_ras_snapshot            | `wire1_t`            | 1     | 1  | 1     | front-end/BPU/BPU.h:372 |
| ras_count_snapshot               | `ras_count_t`        | 7     | 1  | 7     | front-end/BPU/BPU.h:373 |
| ras_has_entry_snapshot           | `wire1_t`            | 1     | 1  | 1     | front-end/BPU/BPU.h:374 |
| ras_top_index                    | `ras_index_t`        | 6     | 1  | 6     | front-end/BPU/BPU.h:375 |
| pred_base_pc                     | `pc_t`               | 32    | 1  | 32    | front-end/BPU/BPU.h:376 |
| boundary_addr                    | `fetch_addr_t`       | 32    | 1  | 32    | front-end/BPU/BPU.h:377 |
| do_pred_on_this_pc[FETCH_WIDTH]  | `wire1_t`            | 1     | 16 | 16    | front-end/BPU/BPU.h:378 |
| this_pc_bank_sel[FETCH_WIDTH]    | `bpu_bank_sel_ext_t` | 5     | 16 | 80    | front-end/BPU/BPU.h:379 |
| do_pred_for_this_pc[FETCH_WIDTH] | `pc_t`               | 32    | 16 | 512   | front-end/BPU/BPU.h:380 |
| q_read_slot[BPU_BANK_NUM]        | `queue_ptr_t`        | 9     | 16 | 144   | front-end/BPU/BPU.h:381 |
| going_to_do_pred                 | `wire1_t`            | 1     | 1  | 1     | front-end/BPU/BPU.h:382 |
| going_to_do_upd[BPU_BANK_NUM]    | `wire1_t`            | 1     | 16 | 16    | front-end/BPU/BPU.h:383 |
| set_submodule_input              | `wire1_t`            | 1     | 1  | 1     | front-end/BPU/BPU.h:384 |
| nlp_pred_base_re                 | `wire1_t`            | 1     | 1  | 1     | front-end/BPU/BPU.h:385 |
| nlp_pred_base_idx                | `nlp_index_t`        | 12    | 1  | 12    | front-end/BPU/BPU.h:386 |
| nlp_train_re                     | `wire1_t`            | 1     | 1  | 1     | front-end/BPU/BPU.h:387 |
| nlp_train_idx                    | `nlp_index_t`        | 12    | 1  | 12    | front-end/BPU/BPU.h:388 |

