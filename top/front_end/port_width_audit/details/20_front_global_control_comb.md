# front_global_control_comb

- 分组：`front_top glue`
- 源码依据：`train_IO.h / front_top.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                          | bit |
| -- | --------------------------- | --- |
| 输入 | `FrontGlobalControlCombIn`  | 67  |
| 输出 | `FrontGlobalControlCombOut` | 34  |


## 输入展开

| 字段                                 | 类型             | 单项bit | 数量 | 合计bit | 来源                       |
| ---------------------------------- | -------------- | ----- | -- | ----- | ------------------------ |
| reset                              | `wire1_t`      | 1     | 1  | 1     | front-end/train_IO.h:266 |
| backend_refetch                    | `wire1_t`      | 1     | 1  | 1     | front-end/train_IO.h:267 |
| backend_refetch_address            | `fetch_addr_t` | 32    | 1  | 32    | front-end/train_IO.h:268 |
| predecode_refetch_snapshot         | `wire1_t`      | 1     | 1  | 1     | front-end/train_IO.h:269 |
| predecode_refetch_address_snapshot | `fetch_addr_t` | 32    | 1  | 32    | front-end/train_IO.h:270 |


## 输出展开

| 字段              | 类型             | 单项bit | 数量 | 合计bit | 来源                       |
| --------------- | -------------- | ----- | -- | ----- | ------------------------ |
| global_reset    | `wire1_t`      | 1     | 1  | 1     | front-end/train_IO.h:274 |
| global_refetch  | `wire1_t`      | 1     | 1  | 1     | front-end/train_IO.h:275 |
| refetch_address | `fetch_addr_t` | 32    | 1  | 32    | front-end/train_IO.h:276 |

