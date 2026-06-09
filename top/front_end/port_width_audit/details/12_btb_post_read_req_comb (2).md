# btb_post_read_req_comb

- 分组：`BPU`
- 源码依据：`BPU/target_predictor/BTB_top.h`
- 配置口径：`simulator-front` 当前默认 large 配置

## 端口总览

| 方向 | 类型                               | bit  |
| -- | -------------------------------- | ---- |
| 输入 | `BTB_TOP::BtbPostReadReqCombIn`  | 2264 |
| 输出 | `BTB_TOP::BtbPostReadReqCombOut` | 45   |


## 输入展开

| 字段                                                 | 类型               | 单项bit | 数量 | 合计bit | 来源                                           |
| -------------------------------------------------- | ---------------- | ----- | -- | ----- | -------------------------------------------- |
| inp                                                | `InputPayload`   | 105   | 1  | 105   | front-end/BPU/target_predictor/BTB_top.h:288 |
| inp.pred_pc                                        | `pc_t`           | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:40  |
| inp.pred_req                                       | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:41  |
| inp.pred_type_in                                   | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:42  |
| inp.upd_valid                                      | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:43  |
| inp.upd_pc                                         | `pc_t`           | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:44  |
| inp.upd_actual_addr                                | `target_addr_t`  | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:45  |
| inp.upd_br_type_in                                 | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:46  |
| inp.upd_actual_dir                                 | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:47  |
| rd                                                 | `ReadData`       | 2159  | 1  | 2159  | front-end/BPU/target_predictor/BTB_top.h:289 |
| rd.state_in                                        | `StateInput`     | 166   | 1  | 166   | front-end/BPU/target_predictor/BTB_top.h:103 |
| rd.state_in.state                                  | `btb_state_t`    | 2     | 1  | 2     | front-end/BPU/target_predictor/BTB_top.h:59  |
| rd.state_in.do_pred_latch                          | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:60  |
| rd.state_in.do_upd_latch                           | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:62  |
| rd.state_in.upd_pc_latch                           | `pc_t`           | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:63  |
| rd.state_in.upd_actual_addr_latch                  | `target_addr_t`  | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:64  |
| rd.state_in.upd_br_type_latch                      | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:65  |
| rd.state_in.upd_actual_dir_latch                   | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:66  |
| rd.state_in.pred_calc_pc_latch                     | `pc_t`           | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:67  |
| rd.state_in.pred_calc_btb_tag_latch                | `btb_tag_t`      | 8     | 1  | 8     | front-end/BPU/target_predictor/BTB_top.h:69  |
| rd.state_in.pred_calc_btb_idx_latch                | `btb_idx_t`      | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:70  |
| rd.state_in.pred_calc_type_idx_latch               | `btb_type_idx_t` | 12    | 1  | 12    | front-end/BPU/target_predictor/BTB_top.h:71  |
| rd.state_in.pred_calc_bht_idx_latch                | `bht_idx_t`      | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:72  |
| rd.state_in.upd_calc_next_bht_val_latch            | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:73  |
| rd.state_in.upd_calc_hit_info_latch                | `HitCheckOut`    | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:75  |
| rd.state_in.upd_calc_hit_info_latch.hit_way        | `btb_way_sel_t`  | 2     | 1  | 2     | front-end/BPU/target_predictor/BTB_top.h:25  |
| rd.state_in.upd_calc_hit_info_latch.hit            | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:26  |
| rd.state_in.upd_calc_victim_way_latch              | `btb_way_sel_t`  | 2     | 1  | 2     | front-end/BPU/target_predictor/BTB_top.h:76  |
| rd.state_in.upd_calc_w_target_way_latch            | `tc_way_sel_t`   | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:77  |
| rd.state_in.upd_calc_next_useful_val_latch         | `wire3_t`        | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:78  |
| rd.state_in.upd_calc_writes_btb_latch              | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:79  |
| rd.idx_1                                           | `IndexResult`    | 53    | 1  | 53    | front-end/BPU/target_predictor/BTB_top.h:104 |
| rd.idx_1.btb_idx                                   | `btb_idx_t`      | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:84  |
| rd.idx_1.type_idx                                  | `btb_type_idx_t` | 12    | 1  | 12    | front-end/BPU/target_predictor/BTB_top.h:85  |
| rd.idx_1.bht_idx                                   | `bht_idx_t`      | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:86  |
| rd.idx_1.tc_idx                                    | `tc_idx_t`       | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:87  |
| rd.idx_1.tag                                       | `btb_tag_t`      | 8     | 1  | 8     | front-end/BPU/target_predictor/BTB_top.h:88  |
| rd.idx_1.read_address_valid                        | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:89  |
| rd.mem_1                                           | `MemReadResult`  | 283   | 1  | 283   | front-end/BPU/target_predictor/BTB_top.h:105 |
| rd.mem_1.r_btb_set                                 | `BtbSetData`     | 176   | 1  | 176   | front-end/BPU/target_predictor/BTB_top.h:94  |
| rd.mem_1.r_btb_set.tag[BTB_WAY_NUM]                | `btb_tag_t`      | 8     | 4  | 32    | front-end/BPU/target_predictor/BTB_top.h:11  |
| rd.mem_1.r_btb_set.bta[BTB_WAY_NUM]                | `target_addr_t`  | 32    | 4  | 128   | front-end/BPU/target_predictor/BTB_top.h:12  |
| rd.mem_1.r_btb_set.valid[BTB_WAY_NUM]              | `wire1_t`        | 1     | 4  | 4     | front-end/BPU/target_predictor/BTB_top.h:13  |
| rd.mem_1.r_btb_set.useful[BTB_WAY_NUM]             | `wire3_t`        | 3     | 4  | 12    | front-end/BPU/target_predictor/BTB_top.h:14  |
| rd.mem_1.r_tc_set                                  | `TcSetData`      | 92    | 1  | 92    | front-end/BPU/target_predictor/BTB_top.h:95  |
| rd.mem_1.r_tc_set.target[TC_WAY_NUM]               | `target_addr_t`  | 32    | 2  | 64    | front-end/BPU/target_predictor/BTB_top.h:18  |
| rd.mem_1.r_tc_set.tag[TC_WAY_NUM]                  | `tc_tag_t`       | 10    | 2  | 20    | front-end/BPU/target_predictor/BTB_top.h:19  |
| rd.mem_1.r_tc_set.valid[TC_WAY_NUM]                | `wire1_t`        | 1     | 2  | 2     | front-end/BPU/target_predictor/BTB_top.h:20  |
| rd.mem_1.r_tc_set.useful[TC_WAY_NUM]               | `wire3_t`        | 3     | 2  | 6     | front-end/BPU/target_predictor/BTB_top.h:21  |
| rd.mem_1.r_type                                    | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:96  |
| rd.mem_1.r_bht                                     | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:97  |
| rd.mem_1.read_data_valid                           | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:98  |
| rd.idx_2                                           | `IndexResult`    | 53    | 1  | 53    | front-end/BPU/target_predictor/BTB_top.h:106 |
| rd.idx_2.btb_idx                                   | `btb_idx_t`      | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:84  |
| rd.idx_2.type_idx                                  | `btb_type_idx_t` | 12    | 1  | 12    | front-end/BPU/target_predictor/BTB_top.h:85  |
| rd.idx_2.bht_idx                                   | `bht_idx_t`      | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:86  |
| rd.idx_2.tc_idx                                    | `tc_idx_t`       | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:87  |
| rd.idx_2.tag                                       | `btb_tag_t`      | 8     | 1  | 8     | front-end/BPU/target_predictor/BTB_top.h:88  |
| rd.idx_2.read_address_valid                        | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:89  |
| rd.mem_2                                           | `MemReadResult`  | 283   | 1  | 283   | front-end/BPU/target_predictor/BTB_top.h:107 |
| rd.mem_2.r_btb_set                                 | `BtbSetData`     | 176   | 1  | 176   | front-end/BPU/target_predictor/BTB_top.h:94  |
| rd.mem_2.r_btb_set.tag[BTB_WAY_NUM]                | `btb_tag_t`      | 8     | 4  | 32    | front-end/BPU/target_predictor/BTB_top.h:11  |
| rd.mem_2.r_btb_set.bta[BTB_WAY_NUM]                | `target_addr_t`  | 32    | 4  | 128   | front-end/BPU/target_predictor/BTB_top.h:12  |
| rd.mem_2.r_btb_set.valid[BTB_WAY_NUM]              | `wire1_t`        | 1     | 4  | 4     | front-end/BPU/target_predictor/BTB_top.h:13  |
| rd.mem_2.r_btb_set.useful[BTB_WAY_NUM]             | `wire3_t`        | 3     | 4  | 12    | front-end/BPU/target_predictor/BTB_top.h:14  |
| rd.mem_2.r_tc_set                                  | `TcSetData`      | 92    | 1  | 92    | front-end/BPU/target_predictor/BTB_top.h:95  |
| rd.mem_2.r_tc_set.target[TC_WAY_NUM]               | `target_addr_t`  | 32    | 2  | 64    | front-end/BPU/target_predictor/BTB_top.h:18  |
| rd.mem_2.r_tc_set.tag[TC_WAY_NUM]                  | `tc_tag_t`       | 10    | 2  | 20    | front-end/BPU/target_predictor/BTB_top.h:19  |
| rd.mem_2.r_tc_set.valid[TC_WAY_NUM]                | `wire1_t`        | 1     | 2  | 2     | front-end/BPU/target_predictor/BTB_top.h:20  |
| rd.mem_2.r_tc_set.useful[TC_WAY_NUM]               | `wire3_t`        | 3     | 2  | 6     | front-end/BPU/target_predictor/BTB_top.h:21  |
| rd.mem_2.r_type                                    | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:96  |
| rd.mem_2.r_bht                                     | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:97  |
| rd.mem_2.read_data_valid                           | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:98  |
| rd.sram_delay_active                               | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:108 |
| rd.sram_delay_counter                              | `wire32_t`       | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:110 |
| rd.sram_delayed_data                               | `MemReadResult`  | 283   | 1  | 283   | front-end/BPU/target_predictor/BTB_top.h:111 |
| rd.sram_delayed_data.r_btb_set                     | `BtbSetData`     | 176   | 1  | 176   | front-end/BPU/target_predictor/BTB_top.h:94  |
| rd.sram_delayed_data.r_btb_set.tag[BTB_WAY_NUM]    | `btb_tag_t`      | 8     | 4  | 32    | front-end/BPU/target_predictor/BTB_top.h:11  |
| rd.sram_delayed_data.r_btb_set.bta[BTB_WAY_NUM]    | `target_addr_t`  | 32    | 4  | 128   | front-end/BPU/target_predictor/BTB_top.h:12  |
| rd.sram_delayed_data.r_btb_set.valid[BTB_WAY_NUM]  | `wire1_t`        | 1     | 4  | 4     | front-end/BPU/target_predictor/BTB_top.h:13  |
| rd.sram_delayed_data.r_btb_set.useful[BTB_WAY_NUM] | `wire3_t`        | 3     | 4  | 12    | front-end/BPU/target_predictor/BTB_top.h:14  |
| rd.sram_delayed_data.r_tc_set                      | `TcSetData`      | 92    | 1  | 92    | front-end/BPU/target_predictor/BTB_top.h:95  |
| rd.sram_delayed_data.r_tc_set.target[TC_WAY_NUM]   | `target_addr_t`  | 32    | 2  | 64    | front-end/BPU/target_predictor/BTB_top.h:18  |
| rd.sram_delayed_data.r_tc_set.tag[TC_WAY_NUM]      | `tc_tag_t`       | 10    | 2  | 20    | front-end/BPU/target_predictor/BTB_top.h:19  |
| rd.sram_delayed_data.r_tc_set.valid[TC_WAY_NUM]    | `wire1_t`        | 1     | 2  | 2     | front-end/BPU/target_predictor/BTB_top.h:20  |
| rd.sram_delayed_data.r_tc_set.useful[TC_WAY_NUM]   | `wire3_t`        | 3     | 2  | 6     | front-end/BPU/target_predictor/BTB_top.h:21  |
| rd.sram_delayed_data.r_type                        | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:96  |
| rd.sram_delayed_data.r_bht                         | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:97  |
| rd.sram_delayed_data.read_data_valid               | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:98  |
| rd.new_read_valid                                  | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:112 |
| rd.new_read_data                                   | `MemReadResult`  | 283   | 1  | 283   | front-end/BPU/target_predictor/BTB_top.h:113 |
| rd.new_read_data.r_btb_set                         | `BtbSetData`     | 176   | 1  | 176   | front-end/BPU/target_predictor/BTB_top.h:94  |
| rd.new_read_data.r_btb_set.tag[BTB_WAY_NUM]        | `btb_tag_t`      | 8     | 4  | 32    | front-end/BPU/target_predictor/BTB_top.h:11  |
| rd.new_read_data.r_btb_set.bta[BTB_WAY_NUM]        | `target_addr_t`  | 32    | 4  | 128   | front-end/BPU/target_predictor/BTB_top.h:12  |
| rd.new_read_data.r_btb_set.valid[BTB_WAY_NUM]      | `wire1_t`        | 1     | 4  | 4     | front-end/BPU/target_predictor/BTB_top.h:13  |
| rd.new_read_data.r_btb_set.useful[BTB_WAY_NUM]     | `wire3_t`        | 3     | 4  | 12    | front-end/BPU/target_predictor/BTB_top.h:14  |
| rd.new_read_data.r_tc_set                          | `TcSetData`      | 92    | 1  | 92    | front-end/BPU/target_predictor/BTB_top.h:95  |
| rd.new_read_data.r_tc_set.target[TC_WAY_NUM]       | `target_addr_t`  | 32    | 2  | 64    | front-end/BPU/target_predictor/BTB_top.h:18  |
| rd.new_read_data.r_tc_set.tag[TC_WAY_NUM]          | `tc_tag_t`       | 10    | 2  | 20    | front-end/BPU/target_predictor/BTB_top.h:19  |
| rd.new_read_data.r_tc_set.valid[TC_WAY_NUM]        | `wire1_t`        | 1     | 2  | 2     | front-end/BPU/target_predictor/BTB_top.h:20  |
| rd.new_read_data.r_tc_set.useful[TC_WAY_NUM]       | `wire3_t`        | 3     | 2  | 6     | front-end/BPU/target_predictor/BTB_top.h:21  |
| rd.new_read_data.r_type                            | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:96  |
| rd.new_read_data.r_bht                             | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:97  |
| rd.new_read_data.read_data_valid                   | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:98  |
| rd.sram_prng_state                                 | `wire32_t`       | 32    | 1  | 32    | front-end/BPU/target_predictor/BTB_top.h:114 |
| rd.pred_read_valid                                 | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:115 |
| rd.pred_btb_idx                                    | `btb_idx_t`      | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:117 |
| rd.pred_type_idx                                   | `btb_type_idx_t` | 12    | 1  | 12    | front-end/BPU/target_predictor/BTB_top.h:118 |
| rd.pred_bht_idx                                    | `bht_idx_t`      | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:119 |
| rd.pred_tc_idx                                     | `tc_idx_t`       | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:120 |
| rd.pred_tag                                        | `btb_tag_t`      | 8     | 1  | 8     | front-end/BPU/target_predictor/BTB_top.h:121 |
| rd.pred_type_data                                  | `br_type_t`      | 3     | 1  | 3     | front-end/BPU/target_predictor/BTB_top.h:122 |
| rd.pred_bht_data                                   | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:123 |
| rd.pred_btb_set                                    | `BtbSetData`     | 176   | 1  | 176   | front-end/BPU/target_predictor/BTB_top.h:124 |
| rd.pred_btb_set.tag[BTB_WAY_NUM]                   | `btb_tag_t`      | 8     | 4  | 32    | front-end/BPU/target_predictor/BTB_top.h:11  |
| rd.pred_btb_set.bta[BTB_WAY_NUM]                   | `target_addr_t`  | 32    | 4  | 128   | front-end/BPU/target_predictor/BTB_top.h:12  |
| rd.pred_btb_set.valid[BTB_WAY_NUM]                 | `wire1_t`        | 1     | 4  | 4     | front-end/BPU/target_predictor/BTB_top.h:13  |
| rd.pred_btb_set.useful[BTB_WAY_NUM]                | `wire3_t`        | 3     | 4  | 12    | front-end/BPU/target_predictor/BTB_top.h:14  |
| rd.pred_tc_set                                     | `TcSetData`      | 92    | 1  | 92    | front-end/BPU/target_predictor/BTB_top.h:125 |
| rd.pred_tc_set.target[TC_WAY_NUM]                  | `target_addr_t`  | 32    | 2  | 64    | front-end/BPU/target_predictor/BTB_top.h:18  |
| rd.pred_tc_set.tag[TC_WAY_NUM]                     | `tc_tag_t`       | 10    | 2  | 20    | front-end/BPU/target_predictor/BTB_top.h:19  |
| rd.pred_tc_set.valid[TC_WAY_NUM]                   | `wire1_t`        | 1     | 2  | 2     | front-end/BPU/target_predictor/BTB_top.h:20  |
| rd.pred_tc_set.useful[TC_WAY_NUM]                  | `wire3_t`        | 3     | 2  | 6     | front-end/BPU/target_predictor/BTB_top.h:21  |
| rd.upd_read_valid                                  | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:126 |
| rd.upd_btb_idx                                     | `btb_idx_t`      | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:128 |
| rd.upd_type_idx                                    | `btb_type_idx_t` | 12    | 1  | 12    | front-end/BPU/target_predictor/BTB_top.h:129 |
| rd.upd_bht_idx                                     | `bht_idx_t`      | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:130 |
| rd.upd_tag                                         | `btb_tag_t`      | 8     | 1  | 8     | front-end/BPU/target_predictor/BTB_top.h:131 |
| rd.upd_bht_data                                    | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:132 |
| rd.upd_next_bht_data                               | `bht_hist_t`     | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:133 |
| rd.upd_btb_set                                     | `BtbSetData`     | 176   | 1  | 176   | front-end/BPU/target_predictor/BTB_top.h:134 |
| rd.upd_btb_set.tag[BTB_WAY_NUM]                    | `btb_tag_t`      | 8     | 4  | 32    | front-end/BPU/target_predictor/BTB_top.h:11  |
| rd.upd_btb_set.bta[BTB_WAY_NUM]                    | `target_addr_t`  | 32    | 4  | 128   | front-end/BPU/target_predictor/BTB_top.h:12  |
| rd.upd_btb_set.valid[BTB_WAY_NUM]                  | `wire1_t`        | 1     | 4  | 4     | front-end/BPU/target_predictor/BTB_top.h:13  |
| rd.upd_btb_set.useful[BTB_WAY_NUM]                 | `wire3_t`        | 3     | 4  | 12    | front-end/BPU/target_predictor/BTB_top.h:14  |
| rd.upd_tc_read_valid                               | `wire1_t`        | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:135 |
| rd.upd_tc_write_idx                                | `tc_idx_t`       | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:137 |
| rd.upd_tc_write_tag                                | `tc_tag_t`       | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:138 |
| rd.upd_tc_set                                      | `TcSetData`      | 92    | 1  | 92    | front-end/BPU/target_predictor/BTB_top.h:139 |
| rd.upd_tc_set.target[TC_WAY_NUM]                   | `target_addr_t`  | 32    | 2  | 64    | front-end/BPU/target_predictor/BTB_top.h:18  |
| rd.upd_tc_set.tag[TC_WAY_NUM]                      | `tc_tag_t`       | 10    | 2  | 20    | front-end/BPU/target_predictor/BTB_top.h:19  |
| rd.upd_tc_set.valid[TC_WAY_NUM]                    | `wire1_t`        | 1     | 2  | 2     | front-end/BPU/target_predictor/BTB_top.h:20  |
| rd.upd_tc_set.useful[TC_WAY_NUM]                   | `wire3_t`        | 3     | 2  | 6     | front-end/BPU/target_predictor/BTB_top.h:21  |


## 输出展开

| 字段                 | 类型           | 单项bit | 数量 | 合计bit | 来源                                           |
| ------------------ | ------------ | ----- | -- | ----- | -------------------------------------------- |
| pred_tc_read_valid | `wire1_t`    | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:293 |
| pred_tc_idx        | `tc_idx_t`   | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:294 |
| upd_next_bht_data  | `bht_hist_t` | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:295 |
| upd_tc_read_valid  | `wire1_t`    | 1     | 1  | 1     | front-end/BPU/target_predictor/BTB_top.h:296 |
| upd_tc_write_idx   | `tc_idx_t`   | 11    | 1  | 11    | front-end/BPU/target_predictor/BTB_top.h:297 |
| upd_tc_write_tag   | `tc_tag_t`   | 10    | 1  | 10    | front-end/BPU/target_predictor/BTB_top.h:298 |

