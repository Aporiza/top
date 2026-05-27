# bpu_submodule_bind_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/BPU.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                        | bit  |
| -- | ------------------------- | ---- |
| 输入 | `BpuSubmoduleBindCombIn`  | 1856 |
| 输出 | `BpuSubmoduleBindCombOut` | 1680 |


## 输入展开

| 字段                                   | 类型                             | 单项bit | 数量 | 合计bit | 来源                                              |
| ------------------------------------ | ------------------------------ | ----- | -- | ----- | ----------------------------------------------- |
| do_pred_on_this_pc[FETCH_WIDTH]      | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/BPU.h:431                         |
| this_pc_bank_sel[FETCH_WIDTH]        | `bpu_bank_sel_ext_t`           | 5     | 16 | 80    | front-end/BPU/BPU.h:432                         |
| btb_in[BPU_BANK_NUM]                 | `BTB_TOP::InputPayload`        | 105   | 16 | 1680  | front-end/BPU/BPU.h:433                         |
| btb_in.pred_pc                       | `pc_t`                         | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:40     |
| btb_in.pred_req                      | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:41     |
| btb_in.pred_type_in                  | `br_type_t`                    | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:42     |
| btb_in.upd_valid                     | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:43     |
| btb_in.upd_pc                        | `pc_t`                         | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:44     |
| btb_in.upd_actual_addr               | `target_addr_t`                | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:45     |
| btb_in.upd_br_type_in                | `br_type_t`                    | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:46     |
| btb_in.upd_actual_dir                | `wire1_t`                      | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:47     |
| type_out                             | `TypePredictor::OutputPayload` | 80    | 1  | 80    | front-end/BPU/BPU.h:434                         |
| type_out.pred_type[FETCH_WIDTH]      | `br_type_t`                    | 3     | 16 | 48    | front-end/BPU/type_predictor/TypePredictor.h:25 |
| type_out.pred_hit[FETCH_WIDTH]       | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:26 |
| type_out.pred_confident[FETCH_WIDTH] | `wire1_t`                      | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:27 |


## 输出展开

| 字段                               | 类型                      | 单项bit | 数量 | 合计bit | 来源                                          |
| -------------------------------- | ----------------------- | ----- | -- | ----- | ------------------------------------------- |
| btb_in_with_type[BPU_BANK_NUM]   | `BTB_TOP::InputPayload` | 105   | 16 | 1680  | front-end/BPU/BPU.h:438                     |
| btb_in_with_type.pred_pc         | `pc_t`                  | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:40 |
| btb_in_with_type.pred_req        | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:41 |
| btb_in_with_type.pred_type_in    | `br_type_t`             | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:42 |
| btb_in_with_type.upd_valid       | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:43 |
| btb_in_with_type.upd_pc          | `pc_t`                  | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:44 |
| btb_in_with_type.upd_actual_addr | `target_addr_t`         | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:45 |
| btb_in_with_type.upd_br_type_in  | `br_type_t`             | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:46 |
| btb_in_with_type.upd_actual_dir  | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:47 |

