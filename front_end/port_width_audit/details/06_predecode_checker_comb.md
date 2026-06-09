# predecode_checker_comb

- 分组：`Predecode`
- 源码依据：`train_IO.h / predecode_checker.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                        | bit |
| -- | ------------------------- | --- |
| 输入 | `PredecodeCheckerCombIn`  | 624 |
| 输出 | `PredecodeCheckerCombOut` | 49  |


## 输入展开

| 字段                                             | 类型                     | 单项bit | 数量 | 合计bit | 来源                               |
| ---------------------------------------------- | ---------------------- | ----- | -- | ----- | -------------------------------- |
| inp_regs                                       | `predecode_checker_in` | 624   | 1  | 624   | front-end/predecode_checker.h:23 |
| inp_regs.predict_dir[FETCH_WIDTH]              | `wire1_t`              | 1     | 16 | 16    | front-end/predecode_checker.h:7  |
| inp_regs.predict_next_fetch_address            | `fetch_addr_t`         | 32    | 1  | 32    | front-end/predecode_checker.h:9  |
| inp_regs.predecode_type[FETCH_WIDTH]           | `predecode_type_t`     | 2     | 16 | 32    | front-end/predecode_checker.h:10 |
| inp_regs.predecode_target_address[FETCH_WIDTH] | `target_addr_t`        | 32    | 16 | 512   | front-end/predecode_checker.h:12 |
| inp_regs.seq_next_pc                           | `pc_t`                 | 32    | 1  | 32    | front-end/predecode_checker.h:13 |


## 输出展开

| 字段                                   | 类型             | 单项bit | 数量 | 合计bit | 来源                               |
| ------------------------------------ | -------------- | ----- | -- | ----- | -------------------------------- |
| predict_dir_corrected[FETCH_WIDTH]   | `wire1_t`      | 1     | 16 | 16    | front-end/predecode_checker.h:17 |
| predict_next_fetch_address_corrected | `fetch_addr_t` | 32    | 1  | 32    | front-end/predecode_checker.h:18 |
| predecode_flush_enable               | `wire1_t`      | 1     | 1  | 1     | front-end/predecode_checker.h:19 |

