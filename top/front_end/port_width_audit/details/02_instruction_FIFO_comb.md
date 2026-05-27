# instruction_FIFO_comb

- 分组：`FIFO/PTAB`
- 源码依据：`train_IO.h / fifo/instruction_FIFO.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                   | bit  |
| -- | -------------------- | ---- |
| 输入 | `InstructionCombIn`  | 3275 |
| 输出 | `InstructionCombOut` | 3270 |


## 输入展开

| 字段                                                  | 类型                           | 单项bit | 数量 | 合计bit | 来源                          |
| --------------------------------------------------- | ---------------------------- | ----- | -- | ----- | --------------------------- |
| inp                                                 | `instruction_FIFO_in`        | 1636  | 1  | 1636  | front-end/train_IO.h:24     |
| inp.reset                                           | `wire1_t`                    | 1     | 1  | 1     | front-end/front_IO.h:176    |
| inp.refetch                                         | `wire1_t`                    | 1     | 1  | 1     | front-end/front_IO.h:177    |
| inp.write_enable                                    | `wire1_t`                    | 1     | 1  | 1     | front-end/front_IO.h:178    |
| inp.fetch_group[FETCH_WIDTH]                        | `inst_word_t`                | 32    | 16 | 512   | front-end/front_IO.h:180    |
| inp.pc[FETCH_WIDTH]                                 | `pc_t`                       | 32    | 16 | 512   | front-end/front_IO.h:181    |
| inp.page_fault_inst[FETCH_WIDTH]                    | `wire1_t`                    | 1     | 16 | 16    | front-end/front_IO.h:182    |
| inp.inst_valid[FETCH_WIDTH]                         | `wire1_t`                    | 1     | 16 | 16    | front-end/front_IO.h:183    |
| inp.read_enable                                     | `wire1_t`                    | 1     | 1  | 1     | front-end/front_IO.h:184    |
| inp.predecode_type[FETCH_WIDTH]                     | `predecode_type_t`           | 2     | 16 | 32    | front-end/front_IO.h:186    |
| inp.predecode_target_address[FETCH_WIDTH]           | `target_addr_t`              | 32    | 16 | 512   | front-end/front_IO.h:188    |
| inp.seq_next_pc                                     | `pc_t`                       | 32    | 1  | 32    | front-end/front_IO.h:189    |
| rd                                                  | `instruction_FIFO_read_data` | 1639  | 1  | 1639  | front-end/train_IO.h:25     |
| rd.size                                             | `instruction_fifo_size_t`    | 6     | 1  | 6     | front-end/front_module.h:33 |
| rd.head_valid                                       | `wire1_t`                    | 1     | 1  | 1     | front-end/front_module.h:34 |
| rd.head_entry                                       | `instruction_FIFO_entry`     | 1632  | 1  | 1632  | front-end/front_module.h:35 |
| rd.head_entry.instructions[FETCH_WIDTH]             | `inst_word_t`                | 32    | 16 | 512   | front-end/front_module.h:23 |
| rd.head_entry.pc[FETCH_WIDTH]                       | `pc_t`                       | 32    | 16 | 512   | front-end/front_module.h:24 |
| rd.head_entry.page_fault_inst[FETCH_WIDTH]          | `wire1_t`                    | 1     | 16 | 16    | front-end/front_module.h:25 |
| rd.head_entry.inst_valid[FETCH_WIDTH]               | `wire1_t`                    | 1     | 16 | 16    | front-end/front_module.h:26 |
| rd.head_entry.predecode_type[FETCH_WIDTH]           | `predecode_type_t`           | 2     | 16 | 32    | front-end/front_module.h:27 |
| rd.head_entry.predecode_target_address[FETCH_WIDTH] | `target_addr_t`              | 32    | 16 | 512   | front-end/front_module.h:28 |
| rd.head_entry.seq_next_pc                           | `pc_t`                       | 32    | 1  | 32    | front-end/front_module.h:29 |


## 输出展开

| 字段                                               | 类型                       | 单项bit | 数量 | 合计bit | 来源                          |
| ------------------------------------------------ | ------------------------ | ----- | -- | ----- | --------------------------- |
| out_regs                                         | `instruction_FIFO_out`   | 1635  | 1  | 1635  | front-end/train_IO.h:29     |
| out_regs.full                                    | `wire1_t`                | 1     | 1  | 1     | front-end/front_IO.h:193    |
| out_regs.empty                                   | `wire1_t`                | 1     | 1  | 1     | front-end/front_IO.h:194    |
| out_regs.FIFO_valid                              | `wire1_t`                | 1     | 1  | 1     | front-end/front_IO.h:195    |
| out_regs.instructions[FETCH_WIDTH]               | `inst_word_t`            | 32    | 16 | 512   | front-end/front_IO.h:197    |
| out_regs.pc[FETCH_WIDTH]                         | `pc_t`                   | 32    | 16 | 512   | front-end/front_IO.h:198    |
| out_regs.page_fault_inst[FETCH_WIDTH]            | `wire1_t`                | 1     | 16 | 16    | front-end/front_IO.h:199    |
| out_regs.inst_valid[FETCH_WIDTH]                 | `wire1_t`                | 1     | 16 | 16    | front-end/front_IO.h:200    |
| out_regs.predecode_type[FETCH_WIDTH]             | `predecode_type_t`       | 2     | 16 | 32    | front-end/front_IO.h:201    |
| out_regs.predecode_target_address[FETCH_WIDTH]   | `target_addr_t`          | 32    | 16 | 512   | front-end/front_IO.h:202    |
| out_regs.seq_next_pc                             | `pc_t`                   | 32    | 1  | 32    | front-end/front_IO.h:203    |
| clear_fifo                                       | `wire1_t`                | 1     | 1  | 1     | front-end/train_IO.h:30     |
| push_en                                          | `wire1_t`                | 1     | 1  | 1     | front-end/train_IO.h:31     |
| push_entry                                       | `instruction_FIFO_entry` | 1632  | 1  | 1632  | front-end/train_IO.h:32     |
| push_entry.instructions[FETCH_WIDTH]             | `inst_word_t`            | 32    | 16 | 512   | front-end/front_module.h:23 |
| push_entry.pc[FETCH_WIDTH]                       | `pc_t`                   | 32    | 16 | 512   | front-end/front_module.h:24 |
| push_entry.page_fault_inst[FETCH_WIDTH]          | `wire1_t`                | 1     | 16 | 16    | front-end/front_module.h:25 |
| push_entry.inst_valid[FETCH_WIDTH]               | `wire1_t`                | 1     | 16 | 16    | front-end/front_module.h:26 |
| push_entry.predecode_type[FETCH_WIDTH]           | `predecode_type_t`       | 2     | 16 | 32    | front-end/front_module.h:27 |
| push_entry.predecode_target_address[FETCH_WIDTH] | `target_addr_t`          | 32    | 16 | 512   | front-end/front_module.h:28 |
| push_entry.seq_next_pc                           | `pc_t`                   | 32    | 1  | 32    | front-end/front_module.h:29 |
| pop_en                                           | `wire1_t`                | 1     | 1  | 1     | front-end/train_IO.h:33     |

