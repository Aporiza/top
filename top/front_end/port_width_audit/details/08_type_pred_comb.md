# type_pred_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/type_predictor`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                | bit  |
| -- | ----------------- | ---- |
| 输入 | `TypePredCombIn`  | 2448 |
| 输出 | `TypePredCombOut` | 376  |


## 输入展开

| 字段                                              | 类型                    | 单项bit | 数量 | 合计bit | 来源                                              |
| ----------------------------------------------- | --------------------- | ----- | -- | ----- | ----------------------------------------------- |
| inp                                             | `InputPayload`        | 816   | 1  | 816   | front-end/BPU/type_predictor/TypePredictor.h:88 |
| inp.pred_valid[FETCH_WIDTH]                     | `wire1_t`             | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:9  |
| inp.pred_pc[FETCH_WIDTH]                        | `pc_t`                | 32    | 16 | 512   | front-end/BPU/type_predictor/TypePredictor.h:10 |
| inp.upd_valid[COMMIT_WIDTH]                     | `wire1_t`             | 1     | 8  | 8     | front-end/BPU/type_predictor/TypePredictor.h:11 |
| inp.upd_pc[COMMIT_WIDTH]                        | `pc_t`                | 32    | 8  | 256   | front-end/BPU/type_predictor/TypePredictor.h:12 |
| inp.upd_br_type[COMMIT_WIDTH]                   | `br_type_t`           | 3     | 8  | 24    | front-end/BPU/type_predictor/TypePredictor.h:13 |
| pre_read                                        | `PreReadCombOut`      | 672   | 1  | 672   | front-end/BPU/type_predictor/TypePredictor.h:89 |
| pre_read.pred_req                               | `PredReadReqCombOut`  | 448   | 1  | 448   | front-end/BPU/type_predictor/TypePredictor.h:83 |
| pre_read.pred_req.read_enable[FETCH_WIDTH]      | `wire1_t`             | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:69 |
| pre_read.pred_req.bank[FETCH_WIDTH]             | `bpu_bank_sel_t`      | 4     | 16 | 64    | front-end/BPU/type_predictor/TypePredictor.h:70 |
| pre_read.pred_req.set_idx[FETCH_WIDTH]          | `type_pred_set_idx_t` | 11    | 16 | 176   | front-end/BPU/type_predictor/TypePredictor.h:71 |
| pre_read.pred_req.tag[FETCH_WIDTH]              | `type_pred_tag_t`     | 12    | 16 | 192   | front-end/BPU/type_predictor/TypePredictor.h:72 |
| pre_read.upd_req                                | `UpdReadReqCombOut`   | 224   | 1  | 224   | front-end/BPU/type_predictor/TypePredictor.h:84 |
| pre_read.upd_req.read_enable[COMMIT_WIDTH]      | `wire1_t`             | 1     | 8  | 8     | front-end/BPU/type_predictor/TypePredictor.h:76 |
| pre_read.upd_req.bank[COMMIT_WIDTH]             | `bpu_bank_sel_t`      | 4     | 8  | 32    | front-end/BPU/type_predictor/TypePredictor.h:77 |
| pre_read.upd_req.set_idx[COMMIT_WIDTH]          | `type_pred_set_idx_t` | 11    | 8  | 88    | front-end/BPU/type_predictor/TypePredictor.h:78 |
| pre_read.upd_req.tag[COMMIT_WIDTH]              | `type_pred_tag_t`     | 12    | 8  | 96    | front-end/BPU/type_predictor/TypePredictor.h:79 |
| rd                                              | `ReadData`            | 960   | 1  | 960   | front-end/BPU/type_predictor/TypePredictor.h:90 |
| rd.pred_entries[FETCH_WIDTH][TYPE_PRED_WAY_NUM] | `Entry`               | 20    | 32 | 640   | front-end/BPU/type_predictor/TypePredictor.h:29 |
| rd.pred_entries.valid                           | `wire1_t`             | 1     | 1  | 1     | front-end/BPU/type_predictor/TypePredictor.h:15 |
| rd.pred_entries.tag                             | `type_pred_tag_t`     | 12    | 1  | 12    | front-end/BPU/type_predictor/TypePredictor.h:17 |
| rd.pred_entries.type                            | `br_type_t`           | 3     | 1  | 3     | front-end/BPU/type_predictor/TypePredictor.h:19 |
| rd.pred_entries.conf                            | `type_pred_conf_t`    | 2     | 1  | 2     | front-end/BPU/type_predictor/TypePredictor.h:19 |
| rd.pred_entries.age                             | `type_pred_age_t`     | 2     | 1  | 2     | front-end/BPU/type_predictor/TypePredictor.h:21 |
| rd.upd_entries[COMMIT_WIDTH][TYPE_PRED_WAY_NUM] | `Entry`               | 20    | 16 | 320   | front-end/BPU/type_predictor/TypePredictor.h:32 |
| rd.upd_entries.valid                            | `wire1_t`             | 1     | 1  | 1     | front-end/BPU/type_predictor/TypePredictor.h:15 |
| rd.upd_entries.tag                              | `type_pred_tag_t`     | 12    | 1  | 12    | front-end/BPU/type_predictor/TypePredictor.h:17 |
| rd.upd_entries.type                             | `br_type_t`           | 3     | 1  | 3     | front-end/BPU/type_predictor/TypePredictor.h:19 |
| rd.upd_entries.conf                             | `type_pred_conf_t`    | 2     | 1  | 2     | front-end/BPU/type_predictor/TypePredictor.h:19 |
| rd.upd_entries.age                              | `type_pred_age_t`     | 2     | 1  | 2     | front-end/BPU/type_predictor/TypePredictor.h:21 |


## 输出展开

| 字段                                   | 类型                    | 单项bit | 数量 | 合计bit | 来源                                              |
| ------------------------------------ | --------------------- | ----- | -- | ----- | ----------------------------------------------- |
| out_regs                             | `OutputPayload`       | 80    | 1  | 80    | front-end/BPU/type_predictor/TypePredictor.h:94 |
| out_regs.pred_type[FETCH_WIDTH]      | `br_type_t`           | 3     | 16 | 48    | front-end/BPU/type_predictor/TypePredictor.h:25 |
| out_regs.pred_hit[FETCH_WIDTH]       | `wire1_t`             | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:26 |
| out_regs.pred_confident[FETCH_WIDTH] | `wire1_t`             | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:27 |
| req                                  | `CombResult`          | 296   | 1  | 296   | front-end/BPU/type_predictor/TypePredictor.h:95 |
| req.write_en[COMMIT_WIDTH]           | `wire1_t`             | 1     | 8  | 8     | front-end/BPU/type_predictor/TypePredictor.h:36 |
| req.write_bank[COMMIT_WIDTH]         | `bpu_bank_sel_t`      | 4     | 8  | 32    | front-end/BPU/type_predictor/TypePredictor.h:37 |
| req.write_set[COMMIT_WIDTH]          | `type_pred_set_idx_t` | 11    | 8  | 88    | front-end/BPU/type_predictor/TypePredictor.h:38 |
| req.write_way[COMMIT_WIDTH]          | `type_pred_way_t`     | 1     | 8  | 8     | front-end/BPU/type_predictor/TypePredictor.h:39 |
| req.write_entry[COMMIT_WIDTH]        | `Entry`               | 20    | 8  | 160   | front-end/BPU/type_predictor/TypePredictor.h:40 |
| req.write_entry.valid                | `wire1_t`             | 1     | 1  | 1     | front-end/BPU/type_predictor/TypePredictor.h:15 |
| req.write_entry.tag                  | `type_pred_tag_t`     | 12    | 1  | 12    | front-end/BPU/type_predictor/TypePredictor.h:17 |
| req.write_entry.type                 | `br_type_t`           | 3     | 1  | 3     | front-end/BPU/type_predictor/TypePredictor.h:19 |
| req.write_entry.conf                 | `type_pred_conf_t`    | 2     | 1  | 2     | front-end/BPU/type_predictor/TypePredictor.h:19 |
| req.write_entry.age                  | `type_pred_age_t`     | 2     | 1  | 2     | front-end/BPU/type_predictor/TypePredictor.h:21 |

