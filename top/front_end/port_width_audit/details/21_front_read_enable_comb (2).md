# front_read_enable_comb

- 分组：`front_top glue`
- 源码依据：`train_IO.h / front_top.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                       | bit |
| -- | ------------------------ | --- |
| 输入 | `FrontReadEnableCombIn`  | 9   |
| 输出 | `FrontReadEnableCombOut` | 6   |


## 输入展开

| 字段                                   | 类型        | 单项bit | 数量 | 合计bit | 来源                       |
| ------------------------------------ | --------- | ----- | -- | ----- | ------------------------ |
| backend_fifo_read_enable             | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:280 |
| fetch_addr_fifo_empty_latch_snapshot | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:281 |
| fifo_empty_latch_snapshot            | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:282 |
| ptab_empty_latch_snapshot            | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:283 |
| front2back_fifo_full_latch_snapshot  | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:284 |
| global_reset                         | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:285 |
| global_refetch                       | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:286 |
| icache_ready                         | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:287 |
| icache_ready_2                       | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:288 |


## 输出展开

| 字段                                          | 类型        | 单项bit | 数量 | 合计bit | 来源                       |
| ------------------------------------------- | --------- | ----- | -- | ----- | ------------------------ |
| fetch_addr_fifo_read_enable_slot0           | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:292 |
| fetch_addr_fifo_read_enable_slot1_candidate | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:293 |
| predecode_can_run_old                       | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:294 |
| inst_fifo_read_enable                       | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:295 |
| ptab_read_enable                            | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:296 |
| front2back_read_enable                      | `wire1_t` | 1     | 1  | 1     | front-end/train_IO.h:297 |

