# front_output_comb

- 分组：`front_top glue`
- 源码依据：`train_IO.h / front_top.cpp`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                   | bit   |
| -- | -------------------- | ----- |
| 输入 | `FrontOutputCombIn`  | 10791 |
| 输出 | `FrontOutputCombOut` | 5393  |


## 输入展开

| 字段                                                                  | 类型                     | 单项bit | 数量  | 合计bit | 来源                       |
| ------------------------------------------------------------------- | ---------------------- | ----- | --- | ----- | ------------------------ |
| saved_front2back_fifo_out                                           | `front2back_FIFO_out`  | 5395  | 1   | 5395  | front-end/train_IO.h:383 |
| saved_front2back_fifo_out.full                                      | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:291 |
| saved_front2back_fifo_out.empty                                     | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:292 |
| saved_front2back_fifo_out.front2back_FIFO_valid                     | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:293 |
| saved_front2back_fifo_out.fetch_group[FETCH_WIDTH]                  | `inst_word_t`          | 32    | 16  | 512   | front-end/front_IO.h:295 |
| saved_front2back_fifo_out.page_fault_inst[FETCH_WIDTH]              | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:296 |
| saved_front2back_fifo_out.inst_valid[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:297 |
| saved_front2back_fifo_out.predict_dir_corrected[FETCH_WIDTH]        | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:298 |
| saved_front2back_fifo_out.predict_next_fetch_address_corrected      | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_IO.h:299 |
| saved_front2back_fifo_out.predict_base_pc[FETCH_WIDTH]              | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:300 |
| saved_front2back_fifo_out.alt_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:301 |
| saved_front2back_fifo_out.altpcpn[FETCH_WIDTH]                      | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:302 |
| saved_front2back_fifo_out.pcpn[FETCH_WIDTH]                         | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:303 |
| saved_front2back_fifo_out.tage_idx[FETCH_WIDTH][4]                  | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_IO.h:304 |
| saved_front2back_fifo_out.tage_tag[FETCH_WIDTH][4]                  | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_IO.h:305 |
| saved_front2back_fifo_out.sc_used[FETCH_WIDTH]                      | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:306 |
| saved_front2back_fifo_out.sc_pred[FETCH_WIDTH]                      | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:307 |
| saved_front2back_fifo_out.sc_sum[FETCH_WIDTH]                       | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_IO.h:308 |
| saved_front2back_fifo_out.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE]  | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_IO.h:309 |
| saved_front2back_fifo_out.loop_used[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:310 |
| saved_front2back_fifo_out.loop_hit[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:311 |
| saved_front2back_fifo_out.loop_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:312 |
| saved_front2back_fifo_out.loop_idx[FETCH_WIDTH]                     | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_IO.h:313 |
| saved_front2back_fifo_out.loop_tag[FETCH_WIDTH]                     | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_IO.h:314 |
| bypass_front2back_fifo_out                                          | `front2back_FIFO_out`  | 5395  | 1   | 5395  | front-end/train_IO.h:384 |
| bypass_front2back_fifo_out.full                                     | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:291 |
| bypass_front2back_fifo_out.empty                                    | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:292 |
| bypass_front2back_fifo_out.front2back_FIFO_valid                    | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:293 |
| bypass_front2back_fifo_out.fetch_group[FETCH_WIDTH]                 | `inst_word_t`          | 32    | 16  | 512   | front-end/front_IO.h:295 |
| bypass_front2back_fifo_out.page_fault_inst[FETCH_WIDTH]             | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:296 |
| bypass_front2back_fifo_out.inst_valid[FETCH_WIDTH]                  | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:297 |
| bypass_front2back_fifo_out.predict_dir_corrected[FETCH_WIDTH]       | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:298 |
| bypass_front2back_fifo_out.predict_next_fetch_address_corrected     | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_IO.h:299 |
| bypass_front2back_fifo_out.predict_base_pc[FETCH_WIDTH]             | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:300 |
| bypass_front2back_fifo_out.alt_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:301 |
| bypass_front2back_fifo_out.altpcpn[FETCH_WIDTH]                     | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:302 |
| bypass_front2back_fifo_out.pcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:303 |
| bypass_front2back_fifo_out.tage_idx[FETCH_WIDTH][4]                 | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_IO.h:304 |
| bypass_front2back_fifo_out.tage_tag[FETCH_WIDTH][4]                 | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_IO.h:305 |
| bypass_front2back_fifo_out.sc_used[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:306 |
| bypass_front2back_fifo_out.sc_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:307 |
| bypass_front2back_fifo_out.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_IO.h:308 |
| bypass_front2back_fifo_out.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_IO.h:309 |
| bypass_front2back_fifo_out.loop_used[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:310 |
| bypass_front2back_fifo_out.loop_hit[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:311 |
| bypass_front2back_fifo_out.loop_pred[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:312 |
| bypass_front2back_fifo_out.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_IO.h:313 |
| bypass_front2back_fifo_out.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_IO.h:314 |
| use_front2back_output_bypass                                        | `wire1_t`              | 1     | 1   | 1     | front-end/train_IO.h:385 |


## 输出展开

| 字段                                           | 类型                     | 单项bit | 数量  | 合计bit | 来源                       |
| -------------------------------------------- | ---------------------- | ----- | --- | ----- | ------------------------ |
| out                                          | `front_top_out`        | 5393  | 1   | 5393  | front-end/train_IO.h:389 |
| out.FIFO_valid                               | `wire1_t`              | 1     | 1   | 1     | front-end/front_IO.h:41  |
| out.pc[FETCH_WIDTH]                          | `pc_t`                 | 32    | 16  | 512   | front-end/front_IO.h:43  |
| out.instructions[FETCH_WIDTH]                | `inst_word_t`          | 32    | 16  | 512   | front-end/front_IO.h:44  |
| out.predict_dir[FETCH_WIDTH]                 | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:45  |
| out.predict_next_fetch_address               | `fetch_addr_t`         | 32    | 1   | 32    | front-end/front_IO.h:46  |
| out.alt_pred[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:47  |
| out.altpcpn[FETCH_WIDTH]                     | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:48  |
| out.pcpn[FETCH_WIDTH]                        | `pcpn_t`               | 3     | 16  | 48    | front-end/front_IO.h:49  |
| out.page_fault_inst[FETCH_WIDTH]             | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:50  |
| out.inst_valid[FETCH_WIDTH]                  | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:51  |
| out.tage_idx[FETCH_WIDTH][4]                 | `tage_idx_t`           | 12    | 64  | 768   | front-end/front_IO.h:52  |
| out.tage_tag[FETCH_WIDTH][4]                 | `tage_tag_t`           | 8     | 64  | 512   | front-end/front_IO.h:53  |
| out.sc_used[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:54  |
| out.sc_pred[FETCH_WIDTH]                     | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:55  |
| out.sc_sum[FETCH_WIDTH]                      | `tage_scl_meta_sum_t`  | 16    | 16  | 256   | front-end/front_IO.h:56  |
| out.sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] | `tage_scl_meta_idx_t`  | 16    | 128 | 2048  | front-end/front_IO.h:57  |
| out.loop_used[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:58  |
| out.loop_hit[FETCH_WIDTH]                    | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:59  |
| out.loop_pred[FETCH_WIDTH]                   | `wire1_t`              | 1     | 16  | 16    | front-end/front_IO.h:60  |
| out.loop_idx[FETCH_WIDTH]                    | `tage_loop_meta_idx_t` | 16    | 16  | 256   | front-end/front_IO.h:61  |
| out.loop_tag[FETCH_WIDTH]                    | `tage_loop_meta_tag_t` | 16    | 16  | 256   | front-end/front_IO.h:62  |

