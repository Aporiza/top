# btb_pre_read_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/target_predictor/BTB_top.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                  | bit |
| -- | ------------------- | --- |
| 输入 | `BtbPreReadCombIn`  | 105 |
| 输出 | `BtbPreReadCombOut` | 228 |


## 输入展开

| 字段                  | 类型              | 单项bit | 数量 | 合计bit | 来源                                           |
| ------------------- | --------------- | ----- | -- | ----- | -------------------------------------------- |
| inp                 | `InputPayload`  | 105   | 1  | 105   | front-end/BPU/target_predictor/BTB_top.h:309 |
| inp.pred_pc         | `pc_t`          | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:40  |
| inp.pred_req        | `wire1_t`       | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:41  |
| inp.pred_type_in    | `br_type_t`     | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:42  |
| inp.upd_valid       | `wire1_t`       | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:43  |
| inp.upd_pc          | `pc_t`          | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:44  |
| inp.upd_actual_addr | `target_addr_t` | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:45  |
| inp.upd_br_type_in  | `br_type_t`     | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:46  |
| inp.upd_actual_dir  | `wire1_t`       | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:47  |


## 输出展开

| 字段                        | 类型                      | 单项bit | 数量 | 合计bit | 来源                                           |
| ------------------------- | ----------------------- | ----- | -- | ----- | -------------------------------------------- |
| pred_req                  | `BtbPredReadReqCombOut` | 85    | 1  | 85    | front-end/BPU/target_predictor/BTB_top.h:313 |
| pred_req.pred_read_valid  | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:253 |
| pred_req.pred_pc          | `pc_t`                  | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:254 |
| pred_req.pred_btb_idx     | `btb_idx_t`             | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:255 |
| pred_req.pred_type_idx    | `btb_type_idx_t`        | 12    | 1  | 12    | front-end/BPU/target_predictor/BTB_top.h:256 |
| pred_req.pred_bht_idx     | `bht_idx_t`             | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:257 |
| pred_req.pred_tag         | `btb_tag_t`             | 8     | 1  | 8     | front-end/BPU/target_predictor/BTB_top.h:258 |
| pred_req.pred_tc_idx      | `tc_idx_t`              | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:259 |
| upd_req                   | `BtbUpdReadReqCombOut`  | 143   | 1  | 143   | front-end/BPU/target_predictor/BTB_top.h:314 |
| upd_req.upd_read_valid    | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:267 |
| upd_req.upd_pc            | `pc_t`                  | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:268 |
| upd_req.upd_actual_addr   | `target_addr_t`         | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:269 |
| upd_req.upd_br_type_in    | `br_type_t`             | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:270 |
| upd_req.upd_actual_dir    | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:271 |
| upd_req.upd_btb_idx       | `btb_idx_t`             | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:272 |
| upd_req.upd_type_idx      | `btb_type_idx_t`        | 12    | 1  | 12    | front-end/BPU/target_predictor/BTB_top.h:273 |
| upd_req.upd_bht_idx       | `bht_idx_t`             | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:274 |
| upd_req.upd_tag           | `btb_tag_t`             | 8     | 1  | 8     | front-end/BPU/target_predictor/BTB_top.h:275 |
| upd_req.upd_next_bht_data | `bht_hist_t`            | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:276 |
| upd_req.upd_tc_read_valid | `wire1_t`               | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:277 |
| upd_req.upd_tc_write_idx  | `tc_idx_t`              | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:278 |
| upd_req.upd_tc_write_tag  | `tc_tag_t`              | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:279 |

