# predecode_comb

- 分组：`Predecode`
- 源码依据：`train_IO.h / predecode.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                 | bit |
| -- | ------------------ | --- |
| 输入 | `PredecodeCombIn`  | 64  |
| 输出 | `PredecodeCombOut` | 34  |


## 输入展开

| 字段   | 类型            | 单项bit | 数量 | 合计bit | 来源                       |
| ---- | ------------- | ----- | -- | ----- | ------------------------ |
| inst | `inst_word_t` | 32    | 1  | 32    | front-end/predecode.h:22 |
| pc   | `pc_t`        | 32    | 1  | 32    | front-end/predecode.h:23 |


## 输出展开

| 字段             | 类型                 | 单项bit | 数量 | 合计bit | 来源                       |
| -------------- | ------------------ | ----- | -- | ----- | ------------------------ |
| type           | `predecode_type_t` | 2     | 1  | 2     | front-end/predecode.h:12 |
| target_address | `target_addr_t`    | 32    | 1  | 32    | front-end/predecode.h:13 |

