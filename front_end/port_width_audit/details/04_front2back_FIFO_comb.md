# front2back_FIFO_comb

- 分组：`FIFO/PTAB`
- 源码依据：`train_IO.h / fifo/front2back_FIFO.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                  | bit   |
| -- | ------------------- | ----- |
| 输入 | `Front2BackCombIn`  | 10796 |
| 输出 | `Front2BackCombOut` | 10790 |


## 输入展开

| 字段                                                     | 类型                          | 单项bit | 数量  | 合计bit | 来源                          |
| ------------------------------------------------------ | --------------------------- | ----- | --- | ----- | --------------------------- |
| inp                                                    | `front2back_FIFO_in`        | 5396  | 1   | 5396  | front-end/train_IO.h:52     |
| inp.reset                                              | `wire1_t`                   | 1     | 1   | 1     | front-end/front_IO.h:262    |
| inp.refetch                                            | `wire1_t`                   | 1     | 1   | 1     | front-end/front_IO.h:263    |
| inp.write_enable                                       | `wire1_t`                   | 1     | 1   | 1     | front-end/front_IO.h:264    |
| inp.read_enable                                        | `wire1_t`                   | 1     | 1   | 1     | front-end/front_IO.h:265    |
| inp.fetch_group[FETCH_WIDTH]                           | `inst_word_t`               | 32    | 16  | 512   | front-end/front_IO.h:266    |
| inp.page_fault_inst[FETCH_WIDTH]                       | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:267    |
| inp.inst_valid[FETCH_WIDTH]                            | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:268    |
| inp.predict_dir_corrected[FETCH_WIDTH]                 | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:269    |
| inp.predict_next_fetch_address_corrected               | `fetch_addr_t`              | 32    | 1   | 32    | front-end/front_IO.h:271    |
| inp.predict_base_pc[FETCH_WIDTH]                       | `pc_t`                      | 32    | 16  | 512   | front-end/front_IO.h:272    |
| inp.alt_pred[FETCH_WIDTH]                              | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:273    |
| inp.altpcpn[FETCH_WIDTH]                               | `pcpn_t`                    | 3     | 16  | 48    | front-end/front_IO.h:275    |
| inp.pcpn[FETCH_WIDTH]                                  | `pcpn_t`                    | 3     | 16  | 48    | front-end/front_IO.h:276    |
| inp.tage_idx[FETCH_WIDTH][4]                           | `tage_idx_t`                | 12    | 64  | 768   | front-end/front_IO.h:277    |
| inp.tage_tag[FETCH_WIDTH][4]                           | `tage_tag_t`                | 8     | 64  | 512   | front-end/front_IO.h:278    |
| inp.sc_used[FETCH_WIDTH]                               | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:279    |
| inp.sc_pred[FETCH_WIDTH]                               | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:280    |
| inp.sc_sum[FETCH_WIDTH]                                | `tage_scl_meta_sum_t`       | 16    | 16  | 256   | front-end/front_IO.h:281    |
| inp.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE]           | `tage_scl_meta_idx_t`       | 16    | 128 | 2048  | front-end/front_IO.h:282    |
| inp.loop_used[FETCH_WIDTH]                             | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:283    |
| inp.loop_hit[FETCH_WIDTH]                              | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:284    |
| inp.loop_pred[FETCH_WIDTH]                             | `wire1_t`                   | 1     | 16  | 16    | front-end/front_IO.h:285    |
| inp.loop_idx[FETCH_WIDTH]                              | `tage_loop_meta_idx_t`      | 16    | 16  | 256   | front-end/front_IO.h:286    |
| inp.loop_tag[FETCH_WIDTH]                              | `tage_loop_meta_tag_t`      | 16    | 16  | 256   | front-end/front_IO.h:287    |
| rd                                                     | `front2back_FIFO_read_data` | 5400  | 1   | 5400  | front-end/train_IO.h:53     |
| rd.size                                                | `front2back_fifo_size_t`    | 7     | 1   | 7     | front-end/front_module.h:90 |
| rd.head_valid                                          | `wire1_t`                   | 1     | 1   | 1     | front-end/front_module.h:91 |
| rd.head_entry                                          | `front2back_FIFO_entry`     | 5392  | 1   | 5392  | front-end/front_module.h:92 |
| rd.head_entry.fetch_group[FETCH_WIDTH]                 | `inst_word_t`               | 32    | 16  | 512   | front-end/front_module.h:67 |
| rd.head_entry.page_fault_inst[FETCH_WIDTH]             | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:68 |
| rd.head_entry.inst_valid[FETCH_WIDTH]                  | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:69 |
| rd.head_entry.predict_dir_corrected[FETCH_WIDTH]       | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:70 |
| rd.head_entry.predict_next_fetch_address_corrected     | `fetch_addr_t`              | 32    | 1   | 32    | front-end/front_module.h:71 |
| rd.head_entry.predict_base_pc[FETCH_WIDTH]             | `pc_t`                      | 32    | 16  | 512   | front-end/front_module.h:72 |
| rd.head_entry.alt_pred[FETCH_WIDTH]                    | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:73 |
| rd.head_entry.altpcpn[FETCH_WIDTH]                     | `pcpn_t`                    | 3     | 16  | 48    | front-end/front_module.h:74 |
| rd.head_entry.pcpn[FETCH_WIDTH]                        | `pcpn_t`                    | 3     | 16  | 48    | front-end/front_module.h:75 |
| rd.head_entry.tage_idx[FETCH_WIDTH][TN_MAX]            | `tage_idx_t`                | 12    | 64  | 768   | front-end/front_module.h:76 |
| rd.head_entry.tage_tag[FETCH_WIDTH][TN_MAX]            | `tage_tag_t`                | 8     | 64  | 512   | front-end/front_module.h:77 |
| rd.head_entry.sc_used[FETCH_WIDTH]                     | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:78 |
| rd.head_entry.sc_pred[FETCH_WIDTH]                     | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:79 |
| rd.head_entry.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`       | 16    | 16  | 256   | front-end/front_module.h:80 |
| rd.head_entry.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`       | 16    | 128 | 2048  | front-end/front_module.h:81 |
| rd.head_entry.loop_used[FETCH_WIDTH]                   | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:82 |
| rd.head_entry.loop_hit[FETCH_WIDTH]                    | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:83 |
| rd.head_entry.loop_pred[FETCH_WIDTH]                   | `wire1_t`                   | 1     | 16  | 16    | front-end/front_module.h:84 |
| rd.head_entry.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t`      | 16    | 16  | 256   | front-end/front_module.h:85 |
| rd.head_entry.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t`      | 16    | 16  | 256   | front-end/front_module.h:86 |


## 输出展开

| 字段                                                  | 类型                      | 单项bit | 数量  | 合计bit | 来源                          |
| --------------------------------------------------- | ----------------------- | ----- | --- | ----- | --------------------------- |
| out_regs                                            | `front2back_FIFO_out`   | 5395  | 1   | 5395  | front-end/train_IO.h:57     |
| out_regs.full                                       | `wire1_t`               | 1     | 1   | 1     | front-end/front_IO.h:291    |
| out_regs.empty                                      | `wire1_t`               | 1     | 1   | 1     | front-end/front_IO.h:292    |
| out_regs.front2back_FIFO_valid                      | `wire1_t`               | 1     | 1   | 1     | front-end/front_IO.h:293    |
| out_regs.fetch_group[FETCH_WIDTH]                   | `inst_word_t`           | 32    | 16  | 512   | front-end/front_IO.h:295    |
| out_regs.page_fault_inst[FETCH_WIDTH]               | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:296    |
| out_regs.inst_valid[FETCH_WIDTH]                    | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:297    |
| out_regs.predict_dir_corrected[FETCH_WIDTH]         | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:298    |
| out_regs.predict_next_fetch_address_corrected       | `fetch_addr_t`          | 32    | 1   | 32    | front-end/front_IO.h:299    |
| out_regs.predict_base_pc[FETCH_WIDTH]               | `pc_t`                  | 32    | 16  | 512   | front-end/front_IO.h:300    |
| out_regs.alt_pred[FETCH_WIDTH]                      | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:301    |
| out_regs.altpcpn[FETCH_WIDTH]                       | `pcpn_t`                | 3     | 16  | 48    | front-end/front_IO.h:302    |
| out_regs.pcpn[FETCH_WIDTH]                          | `pcpn_t`                | 3     | 16  | 48    | front-end/front_IO.h:303    |
| out_regs.tage_idx[FETCH_WIDTH][4]                   | `tage_idx_t`            | 12    | 64  | 768   | front-end/front_IO.h:304    |
| out_regs.tage_tag[FETCH_WIDTH][4]                   | `tage_tag_t`            | 8     | 64  | 512   | front-end/front_IO.h:305    |
| out_regs.sc_used[FETCH_WIDTH]                       | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:306    |
| out_regs.sc_pred[FETCH_WIDTH]                       | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:307    |
| out_regs.sc_sum[FETCH_WIDTH]                        | `tage_scl_meta_sum_t`   | 16    | 16  | 256   | front-end/front_IO.h:308    |
| out_regs.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE]   | `tage_scl_meta_idx_t`   | 16    | 128 | 2048  | front-end/front_IO.h:309    |
| out_regs.loop_used[FETCH_WIDTH]                     | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:310    |
| out_regs.loop_hit[FETCH_WIDTH]                      | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:311    |
| out_regs.loop_pred[FETCH_WIDTH]                     | `wire1_t`               | 1     | 16  | 16    | front-end/front_IO.h:312    |
| out_regs.loop_idx[FETCH_WIDTH]                      | `tage_loop_meta_idx_t`  | 16    | 16  | 256   | front-end/front_IO.h:313    |
| out_regs.loop_tag[FETCH_WIDTH]                      | `tage_loop_meta_tag_t`  | 16    | 16  | 256   | front-end/front_IO.h:314    |
| clear_fifo                                          | `wire1_t`               | 1     | 1   | 1     | front-end/train_IO.h:58     |
| push_en                                             | `wire1_t`               | 1     | 1   | 1     | front-end/train_IO.h:59     |
| push_entry                                          | `front2back_FIFO_entry` | 5392  | 1   | 5392  | front-end/train_IO.h:60     |
| push_entry.fetch_group[FETCH_WIDTH]                 | `inst_word_t`           | 32    | 16  | 512   | front-end/front_module.h:67 |
| push_entry.page_fault_inst[FETCH_WIDTH]             | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:68 |
| push_entry.inst_valid[FETCH_WIDTH]                  | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:69 |
| push_entry.predict_dir_corrected[FETCH_WIDTH]       | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:70 |
| push_entry.predict_next_fetch_address_corrected     | `fetch_addr_t`          | 32    | 1   | 32    | front-end/front_module.h:71 |
| push_entry.predict_base_pc[FETCH_WIDTH]             | `pc_t`                  | 32    | 16  | 512   | front-end/front_module.h:72 |
| push_entry.alt_pred[FETCH_WIDTH]                    | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:73 |
| push_entry.altpcpn[FETCH_WIDTH]                     | `pcpn_t`                | 3     | 16  | 48    | front-end/front_module.h:74 |
| push_entry.pcpn[FETCH_WIDTH]                        | `pcpn_t`                | 3     | 16  | 48    | front-end/front_module.h:75 |
| push_entry.tage_idx[FETCH_WIDTH][TN_MAX]            | `tage_idx_t`            | 12    | 64  | 768   | front-end/front_module.h:76 |
| push_entry.tage_tag[FETCH_WIDTH][TN_MAX]            | `tage_tag_t`            | 8     | 64  | 512   | front-end/front_module.h:77 |
| push_entry.sc_used[FETCH_WIDTH]                     | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:78 |
| push_entry.sc_pred[FETCH_WIDTH]                     | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:79 |
| push_entry.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`   | 16    | 16  | 256   | front-end/front_module.h:80 |
| push_entry.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`   | 16    | 128 | 2048  | front-end/front_module.h:81 |
| push_entry.loop_used[FETCH_WIDTH]                   | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:82 |
| push_entry.loop_hit[FETCH_WIDTH]                    | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:83 |
| push_entry.loop_pred[FETCH_WIDTH]                   | `wire1_t`               | 1     | 16  | 16    | front-end/front_module.h:84 |
| push_entry.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t`  | 16    | 16  | 256   | front-end/front_module.h:85 |
| push_entry.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t`  | 16    | 16  | 256   | front-end/front_module.h:86 |
| pop_en                                              | `wire1_t`               | 1     | 1   | 1     | front-end/train_IO.h:61     |

