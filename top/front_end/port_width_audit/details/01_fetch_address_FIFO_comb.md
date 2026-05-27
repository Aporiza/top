# fetch_address_FIFO_comb

- 分组：`FIFO/PTAB`
- 源码依据：`train_IO.h / fifo/fetch_address_FIFO.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                 | bit |
| -- | ------------------ | --- |
| 输入 | `FetchAddrCombIn`  | 75  |
| 输出 | `FetchAddrCombOut` | 70  |


## 输入展开

| 字段                | 类型                             | 单项bit | 数量 | 合计bit | 来源                          |
| ----------------- | ------------------------------ | ----- | -- | ----- | --------------------------- |
| inp               | `fetch_address_FIFO_in`        | 36    | 1  | 36    | front-end/train_IO.h:11     |
| inp.reset         | `wire1_t`                      | 1     | 1  | 1     | front-end/front_IO.h:318    |
| inp.refetch       | `wire1_t`                      | 1     | 1  | 1     | front-end/front_IO.h:319    |
| inp.read_enable   | `wire1_t`                      | 1     | 1  | 1     | front-end/front_IO.h:320    |
| inp.write_enable  | `wire1_t`                      | 1     | 1  | 1     | front-end/front_IO.h:321    |
| inp.fetch_address | `fetch_addr_t`                 | 32    | 1  | 32    | front-end/front_IO.h:322    |
| rd                | `fetch_address_FIFO_read_data` | 39    | 1  | 39    | front-end/train_IO.h:12     |
| rd.size           | `fetch_addr_fifo_size_t`       | 6     | 1  | 6     | front-end/front_module.h:17 |
| rd.head_valid     | `wire1_t`                      | 1     | 1  | 1     | front-end/front_module.h:18 |
| rd.head_entry     | `fetch_addr_t`                 | 32    | 1  | 32    | front-end/front_module.h:19 |


## 输出展开

| 字段                     | 类型                       | 单项bit | 数量 | 合计bit | 来源                       |
| ---------------------- | ------------------------ | ----- | -- | ----- | ------------------------ |
| out_regs               | `fetch_address_FIFO_out` | 35    | 1  | 35    | front-end/train_IO.h:16  |
| out_regs.full          | `wire1_t`                | 1     | 1  | 1     | front-end/front_IO.h:326 |
| out_regs.empty         | `wire1_t`                | 1     | 1  | 1     | front-end/front_IO.h:327 |
| out_regs.read_valid    | `wire1_t`                | 1     | 1  | 1     | front-end/front_IO.h:328 |
| out_regs.fetch_address | `fetch_addr_t`           | 32    | 1  | 32    | front-end/front_IO.h:329 |
| clear_fifo             | `wire1_t`                | 1     | 1  | 1     | front-end/train_IO.h:17  |
| push_en                | `wire1_t`                | 1     | 1  | 1     | front-end/train_IO.h:18  |
| push_data              | `fetch_addr_t`           | 32    | 1  | 32    | front-end/train_IO.h:19  |
| pop_en                 | `wire1_t`                | 1     | 1  | 1     | front-end/train_IO.h:20  |

