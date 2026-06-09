# type_predictor_pre_read_comb

- 分组：`BPU`
- 源码依据：`train_IO.h / BPU/type_predictor`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                       | bit |
| -- | ------------------------ | --- |
| 输入 | `TypePredPreReadCombIn`  | 816 |
| 输出 | `TypePredPreReadCombOut` | 672 |


## 输入展开

| 字段                        | 类型          | 单项bit | 数量 | 合计bit | 来源                                              |
| ------------------------- | ----------- | ----- | -- | ----- | ----------------------------------------------- |
| pred_valid[FETCH_WIDTH]   | `wire1_t`   | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:9  |
| pred_pc[FETCH_WIDTH]      | `pc_t`      | 32    | 16 | 512   | front-end/BPU/type_predictor/TypePredictor.h:10 |
| upd_valid[COMMIT_WIDTH]   | `wire1_t`   | 1     | 8  | 8     | front-end/BPU/type_predictor/TypePredictor.h:11 |
| upd_pc[COMMIT_WIDTH]      | `pc_t`      | 32    | 8  | 256   | front-end/BPU/type_predictor/TypePredictor.h:12 |
| upd_br_type[COMMIT_WIDTH] | `br_type_t` | 3     | 8  | 24    | front-end/BPU/type_predictor/TypePredictor.h:13 |


## 输出展开

| 字段                                | 类型                    | 单项bit | 数量 | 合计bit | 来源                                              |
| --------------------------------- | --------------------- | ----- | -- | ----- | ----------------------------------------------- |
| pred_req                          | `PredReadReqCombOut`  | 448   | 1  | 448   | front-end/BPU/type_predictor/TypePredictor.h:83 |
| pred_req.read_enable[FETCH_WIDTH] | `wire1_t`             | 1     | 16 | 16    | front-end/BPU/type_predictor/TypePredictor.h:69 |
| pred_req.bank[FETCH_WIDTH]        | `bpu_bank_sel_t`      | 4     | 16 | 64    | front-end/BPU/type_predictor/TypePredictor.h:70 |
| pred_req.set_idx[FETCH_WIDTH]     | `type_pred_set_idx_t` | 11    | 16 | 176   | front-end/BPU/type_predictor/TypePredictor.h:71 |
| pred_req.tag[FETCH_WIDTH]         | `type_pred_tag_t`     | 12    | 16 | 192   | front-end/BPU/type_predictor/TypePredictor.h:72 |
| upd_req                           | `UpdReadReqCombOut`   | 224   | 1  | 224   | front-end/BPU/type_predictor/TypePredictor.h:84 |
| upd_req.read_enable[COMMIT_WIDTH] | `wire1_t`             | 1     | 8  | 8     | front-end/BPU/type_predictor/TypePredictor.h:76 |
| upd_req.bank[COMMIT_WIDTH]        | `bpu_bank_sel_t`      | 4     | 8  | 32    | front-end/BPU/type_predictor/TypePredictor.h:77 |
| upd_req.set_idx[COMMIT_WIDTH]     | `type_pred_set_idx_t` | 11    | 8  | 88    | front-end/BPU/type_predictor/TypePredictor.h:78 |
| upd_req.tag[COMMIT_WIDTH]         | `type_pred_tag_t`     | 12    | 8  | 96    | front-end/BPU/type_predictor/TypePredictor.h:79 |

