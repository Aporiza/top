# front_read_stage_input_comb

- 分组：`front_top glue`
- 源码依据：`train_IO.h / front_top.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                           | bit |
| -- | ---------------------------- | --- |
| 输入 | `FrontReadStageInputCombIn`  | 7   |
| 输出 | `FrontReadStageInputCombOut` | 12  |


## 输入展开

| 字段                                | 类型        | 单项bit | 数量 | 合计bit | 来源                       |
| --------------------------------- | --------- | ----- | -- | ----- | ------------------------ |
| backend_refetch                   | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:301 |
| global_reset                      | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:302 |
| global_refetch                    | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:303 |
| fetch_addr_fifo_read_enable_slot0 | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:304 |
| inst_fifo_read_enable             | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:305 |
| ptab_read_enable                  | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:306 |
| front2back_read_enable            | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:307 |


## 输出展开

| 字段                          | 类型        | 单项bit | 数量 | 合计bit | 来源                       |
| --------------------------- | --------- | ----- | -- | ----- | ------------------------ |
| fetch_addr_fifo_reset       | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:311 |
| fetch_addr_fifo_refetch     | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:312 |
| fetch_addr_fifo_read_enable | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:313 |
| fifo_reset                  | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:314 |
| fifo_refetch                | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:315 |
| fifo_read_enable            | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:316 |
| ptab_reset                  | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:317 |
| ptab_refetch                | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:318 |
| ptab_read_enable            | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:319 |
| front2back_fifo_reset       | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:320 |
| front2back_fifo_refetch     | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:321 |
| front2back_fifo_read_enable | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:322 |

