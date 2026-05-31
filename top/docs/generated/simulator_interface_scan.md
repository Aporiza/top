# 模拟器接口扫描报告

- 生成时间：`2026-05-20T00:14:05`
- 模拟器目录：`simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0`
- RTL/训练包目录：`top`

## 关键配置

| 名称 | 取值 | 源码位置 |
| --- | --- | --- |
| FETCH_WIDTH | 16 | include/config.h:57 |
| DECODE_WIDTH | 8 | include/config.h:58 |
| COMMIT_WIDTH | DECODE_WIDTH = 8 | include/config.h:63 |
| PRF_NUM | 2048 | include/config.h:320 |
| ROB_NUM | 2048 | include/config.h:326 |
| STQ_SIZE | 512 | include/config.h:438 |
| LDQ_SIZE | 512 | include/config.h:439 |
| FTQ_SIZE | 256 | include/config.h:334 |
| PRF_IDX_WIDTH | clog2(PRF_NUM) = 11 | include/config.h:619 |
| ROB_IDX_WIDTH | clog2(ROB_NUM) = 11 | include/config.h:620 |
| STQ_IDX_WIDTH | clog2(STQ_SIZE) = 9 | include/config.h:621 |
| LDQ_IDX_WIDTH | clog2(LDQ_SIZE) = 9 | include/config.h:622 |
| FTQ_IDX_WIDTH | clog2(FTQ_SIZE) = 8 | include/config.h:626 |
| TOTAL_FU_COUNT | calculate_total_fu_count() | include/config.h:495 |
| LSU_LOAD_WB_WIDTH | LSU_LDU_COUNT | include/config.h:448 |

## 已启用 CONFIG 宏

| 宏 | 取值 | 源码位置 |
| --- | --- | --- |
| CONFIG_DIFFTEST | 1 | include/config.h:33 |
| CONFIG_PERF_COUNTER | 1 | include/config.h:34 |
| CONFIG_BPU | 1 | include/config.h:35 |
| CONFIG_TLB_MMU | 1 | include/config.h:36 |
| CONFIG_ORACLE_STEADY_FETCH_WIDTH | 1 | include/config.h:37 |
| CONFIG_CPU_FREQ_MHZ | 500u = 500 | include/config.h:80 |
| CONFIG_DDR_SOC_LATENCY_NS | 20u = 20 | include/config.h:84 |
| CONFIG_DDR_CDC_LATENCY_NS | 12u = 12 | include/config.h:88 |
| CONFIG_DDR_CTL_LATENCY_NS | 15u = 15 | include/config.h:92 |
| CONFIG_DDR_PHY_LATENCY_NS | 13u = 13 | include/config.h:96 |
| CONFIG_DDR_CORE_FREQ_MHZ | 1600u = 1600 | include/config.h:100 |
| CONFIG_DDR_CL | 22u = 22 | include/config.h:104 |
| CONFIG_DDR_TRCD | 22u = 22 | include/config.h:108 |
| CONFIG_DDR_TRP | 22u = 22 | include/config.h:112 |
| CONFIG_DDR_BURST_TRANSFER_BEATS | 4u = 4 | include/config.h:116 |
| CONFIG_DDR_PAGE_HIT_RATE_PCT | 50u = 50 | include/config.h:120 |
| CONFIG_DDR_PAGE_EMPTY_RATE_PCT | 30u = 30 | include/config.h:124 |
| CONFIG_DDR_PAGE_MISS_RATE_PCT | 20u = 20 | include/config.h:128 |
| CONFIG_SIM_DDR_LATENCY | CONFIG_SIM_DDR_LATENCY_CALC | include/config.h:186 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_RESP_LATENCY | 1 | include/config.h:190 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_QUEUE_DEPTH | CONFIG_AXI_KIT_SIM_DDR_MAX_OUTSTANDING = 32 | include/config.h:193 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_ACCEPT_GAP | 0 | include/config.h:196 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_DATA_FIFO_DEPTH | 8 | include/config.h:199 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_DRAIN_GAP | 0 | include/config.h:202 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_DRAIN_HIGH_WATERMARK | CONFIG_AXI_KIT_SIM_DDR_WRITE_DATA_FIFO_DEPTH = 8 | include/config.h:205 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_DRAIN_LOW_WATERMARK | 0 | include/config.h:208 |
| CONFIG_AXI_KIT_SIM_DDR_READ_TO_WRITE_TURNAROUND | 0 | include/config.h:211 |
| CONFIG_AXI_KIT_SIM_DDR_WRITE_TO_READ_TURNAROUND | 0 | include/config.h:214 |
| CONFIG_AXI_KIT_SIM_DDR_BEAT_BYTES | 32 | include/config.h:217 |
| CONFIG_AXI_KIT_MAX_OUTSTANDING | 32 | include/config.h:220 |
| CONFIG_AXI_KIT_MAX_READ_OUTSTANDING_PER_MASTER | 32 | include/config.h:223 |
| CONFIG_AXI_KIT_MAX_WRITE_OUTSTANDING | CONFIG_AXI_KIT_MAX_OUTSTANDING = 32 | include/config.h:226 |
| CONFIG_AXI_KIT_MAX_WRITE_TRANSACTION_BYTES | 64 | include/config.h:229 |
| CONFIG_AXI_KIT_AXI_ID_WIDTH | 6 | include/config.h:232 |
| CONFIG_AXI_KIT_SIM_DDR_MAX_OUTSTANDING | 32 | include/config.h:235 |
| CONFIG_AXI_KIT_DEBUG | 0 | include/config.h:238 |
| CONFIG_AXI_KIT_UART_BASE | 0x10000000u | include/config.h:241 |
| CONFIG_AXI_KIT_MMIO_BASE | CONFIG_AXI_KIT_UART_BASE | include/config.h:244 |
| CONFIG_AXI_KIT_MMIO_SIZE | 0x00001000u | include/config.h:247 |
| CONFIG_ICACHE_USE_AXI_MEM_PORT | 1 | include/config.h:253 |
| CONFIG_AXI_LLC_ENABLE | 1 | include/config.h:258 |
| CONFIG_AXI_LLC_SIZE_BYTES | (8ull << 20) = 8388608 | include/config.h:262 |
| CONFIG_AXI_LLC_WAYS | 16u = 16 | include/config.h:266 |
| CONFIG_AXI_LLC_MSHR_NUM | 8u = 8 | include/config.h:270 |
| CONFIG_AXI_LLC_LOOKUP_LATENCY | 3u = 3 | include/config.h:274 |
| CONFIG_AXI_LLC_DCACHE_READ_MISS_NOALLOC | 0 | include/config.h:278 |
| CONFIG_AXI_LLC_DEBUG_LOG | 0 | include/config.h:282 |

## 入口函数与 comb 函数

| 函数 | 参数 | 源码位置 |
| --- | --- | --- |
| Isu::comb_calc_latency_next |  | back-end/Isu.cpp:199 |
| comb_calc_latency_next |  | back-end/include/Isu.h:79 |
| bpu_core_comb_calc | const InputPayload &inp, ReadData &rd, const BpuPostReadReqCombOut &post_req, BpuCombOut &comb_out | front-end/BPU/BPU.h:1459 |
| bpu_comb_calc | const InputPayload &inp, ReadData &rd, OutputPayload &out, UpdateRequest &req | front-end/BPU/BPU.h:1903 |
| tage_comb_calc | const InputPayload &inp, ReadData &rd, OutputPayload &out, CombResult &req | front-end/BPU/dir_predictor/TAGE_top.h:1479 |
| btb_comb_calc | const InputPayload &inp, ReadData &rd, OutputPayload &out, CombResult &req | front-end/BPU/target_predictor/BTB_top.h:922 |
| type_pred_comb_calc | const InputPayload &in, ReadData &rd, OutputPayload &out, CombResult &req | front-end/BPU/type_predictor/TypePredictor.h:408 |
| FrontTop::step_bpu |  | front-end/FrontTop.cpp:36 |
| FrontTop::step_oracle |  | front-end/FrontTop.cpp:41 |
| comb_calc | const PTAB_in &inp, const PTAB_read_data &rd, PTAB_out &out, PTAB_read_data &next_rd | front-end/fifo/PTAB.cpp:172 |
| PTAB_comb_calc | struct PTAB_in *in, const struct PTAB_read_data *rd, struct PTAB_out *out, struct PTAB_read_data *next_rd | front-end/fifo/PTAB.cpp:212 |
| comb_calc | const fetch_address_FIFO_in &inp, const fetch_address_FIFO_read_data &rd, fetch_address_FIFO_out &out, fetch_address_FIFO_read_data &next_rd | front-end/fifo/fetch_address_FIFO.cpp:90 |
| fetch_address_FIFO_comb_calc | struct fetch_address_FIFO_in *in, const struct fetch_address_FIFO_read_data *rd, struct fetch_address_FIFO_out *out, struct fetch_address_FI | front-end/fifo/fetch_address_FIFO.cpp:123 |
| comb_calc | const front2back_FIFO_in &inp, const front2back_FIFO_read_data &rd, front2back_FIFO_out &out, front2back_FIFO_read_data &next_rd | front-end/fifo/front2bank_FIFO.cpp:162 |
| front2back_FIFO_comb_calc | struct front2back_FIFO_in *in, const struct front2back_FIFO_read_data *rd, struct front2back_FIFO_out *out, struct front2back_FIFO_read_data | front-end/fifo/front2bank_FIFO.cpp:195 |
| comb_calc | const instruction_FIFO_in &inp, const instruction_FIFO_read_data &rd, instruction_FIFO_out &out, instruction_FIFO_read_data &next_rd | front-end/fifo/instruction_FIFO.cpp:114 |
| instruction_FIFO_comb_calc | struct instruction_FIFO_in *in, const struct instruction_FIFO_read_data *rd, struct instruction_FIFO_out *out, struct instruction_FIFO_read_ | front-end/fifo/instruction_FIFO.cpp:147 |
| icache_comb_calc | struct icache_in *in, struct icache_out *out | front-end/front_module.h:106 |
| instruction_FIFO_comb_calc | struct instruction_FIFO_in *in, const struct instruction_FIFO_read_data *rd, struct instruction_FIFO_out *out, struct instruction_FIFO_read_ | front-end/front_module.h:119 |
| PTAB_comb_calc | struct PTAB_in *in, const struct PTAB_read_data *rd, struct PTAB_out *out, struct PTAB_read_data *next_rd | front-end/front_module.h:127 |
| front_top | struct front_top_in *in, struct front_top_out *out | front-end/front_module.h:131 |
| front2back_FIFO_comb_calc | struct front2back_FIFO_in *in, const struct front2back_FIFO_read_data *rd, struct front2back_FIFO_out *out, struct front2back_FIFO_read_data | front-end/front_module.h:138 |
| fetch_address_FIFO_comb_calc | struct fetch_address_FIFO_in *in, const struct fetch_address_FIFO_read_data *rd, struct fetch_address_FIFO_out *out, struct fetch_address_FI | front-end/front_module.h:148 |
| front_comb_calc | const struct front_top_in &inp, const FrontReadData &rd, struct front_top_out &out, FrontUpdateRequest &req | front-end/front_top.cpp:920 |
| front_seq_read | const struct front_top_in &inp, FrontReadData &rd | front-end/front_top.cpp:1865 |
| front_seq_write | const struct front_top_in &inp, const FrontUpdateRequest &req, bool reset | front-end/front_top.cpp:1902 |
| front_top | struct front_top_in *in, struct front_top_out *out | front-end/front_top.cpp:1936 |
| icache_comb_calc | struct icache_in *in, struct icache_out *out | front-end/icache/icache.cpp:248 |
| step_bpu |  | include/FrontTop.h:22 |
| step_oracle |  | include/FrontTop.h:23 |
| front_cycle |  | include/SimCpu.h:39 |
| back2front_comb |  | include/SimCpu.h:40 |
| SimCpu::front_cycle |  | rv_simu_mmu_v2.cpp:639 |
| SimCpu::back2front_comb |  | rv_simu_mmu_v2.cpp:795 |

## C++ 接口结构体

| 结构体/类 | 字段数 | 源码位置 |
| --- | --- | --- |
| front_top_in | 27 | front-end/front_IO.h:11 |
| front_top_out | 21 | front-end/front_IO.h:42 |
| BPU_in | 24 | front-end/front_IO.h:67 |
| BPU_out | 25 | front-end/front_IO.h:97 |
| FrontPreIO | 20 | back-end/include/IO.h:108 |
| PreFrontIO | 2 | back-end/include/IO.h:96 |
| CsrStatusIO | 4 | back-end/include/IO.h:997 |
| icache_in | 11 | front-end/front_IO.h:129 |
| icache_out | 26 | front-end/front_IO.h:145 |
| instruction_FIFO_in | 11 | front-end/front_IO.h:177 |
| instruction_FIFO_out | 10 | front-end/front_IO.h:194 |
| PTAB_in | 22 | front-end/front_IO.h:208 |
| PTAB_out | 20 | front-end/front_IO.h:237 |
| front2back_FIFO_in | 24 | front-end/front_IO.h:263 |
| front2back_FIFO_out | 23 | front-end/front_IO.h:292 |
| fetch_address_FIFO_in | 5 | front-end/front_IO.h:319 |
| fetch_address_FIFO_out | 4 | front-end/front_IO.h:327 |
| FetchAddrCombIn | 2 | front-end/train_IO.h:12 |
| FetchAddrCombOut | 5 | front-end/train_IO.h:17 |
| InstructionCombIn | 2 | front-end/train_IO.h:25 |
| InstructionCombOut | 5 | front-end/train_IO.h:30 |
| PtabCombIn | 2 | front-end/train_IO.h:38 |
| PtabCombOut | 7 | front-end/train_IO.h:43 |
| Front2BackCombIn | 2 | front-end/train_IO.h:53 |
| Front2BackCombOut | 5 | front-end/train_IO.h:58 |
| FrontUpdateRequest | 3 | front-end/train_IO.h:246 |
| FrontBpuInputCombIn | 4 | front-end/train_IO.h:256 |
| FrontBpuInputCombOut | 1 | front-end/train_IO.h:263 |
| FrontGlobalControlCombIn | 5 | front-end/train_IO.h:267 |
| FrontGlobalControlCombOut | 3 | front-end/train_IO.h:275 |
| FrontReadEnableCombIn | 9 | front-end/train_IO.h:281 |
| FrontReadEnableCombOut | 6 | front-end/train_IO.h:293 |
| FrontReadStageInputCombIn | 7 | front-end/train_IO.h:302 |
| FrontReadStageInputCombOut | 4 | front-end/train_IO.h:312 |
| FrontBpuControlCombIn | 6 | front-end/train_IO.h:319 |
| FrontBpuControlCombOut | 5 | front-end/train_IO.h:328 |
| FrontBpuOutputCombIn | 1 | front-end/train_IO.h:336 |
| FrontBpuOutputCombOut | 1 | front-end/train_IO.h:340 |
| FrontPtabWriteCombIn | 4 | front-end/train_IO.h:344 |
| FrontPtabWriteCombOut | 1 | front-end/train_IO.h:351 |
| FrontCheckerInputCombIn | 2 | front-end/train_IO.h:355 |
| FrontCheckerInputCombOut | 1 | front-end/train_IO.h:360 |
| FrontFront2backWriteCombIn | 4 | front-end/train_IO.h:364 |
| FrontFront2backWriteCombOut | 2 | front-end/train_IO.h:371 |
| FrontOutputCombIn | 3 | front-end/train_IO.h:376 |
| FrontOutputCombOut | 1 | front-end/train_IO.h:382 |
| DecRenIO | 28 | back-end/include/IO.h:12 |
| DecRenInst | 26 | back-end/include/IO.h:13 |
| RenDecIO | 1 | back-end/include/IO.h:80 |
| IduConsumeIO | 1 | back-end/include/IO.h:88 |
| DecBroadcastIO | 5 | back-end/include/IO.h:181 |
| FtqPcReadReq | 3 | back-end/include/IO.h:199 |
| FtqPcReadResp | 5 | back-end/include/IO.h:211 |
| FtqExuPcReqIO | 1 | back-end/include/IO.h:227 |
| FtqExuPcRespIO | 1 | back-end/include/IO.h:236 |
| FtqRobPcReqIO | 1 | back-end/include/IO.h:245 |
| FtqRobPcRespIO | 1 | back-end/include/IO.h:254 |
| PreIssueIO | 1 | back-end/include/IO.h:263 |
| RobCommitIO | 28 | back-end/include/IO.h:276 |
| RobCommitInst | 25 | back-end/include/IO.h:277 |
| RobDisIO | 9 | back-end/include/IO.h:374 |
| TmaMeta | 3 | back-end/include/IO.h:375 |
| DisRobIO | 32 | back-end/include/IO.h:399 |
| DisRobInst | 29 | back-end/include/IO.h:400 |
| RenDisIO | 36 | back-end/include/IO.h:476 |
| RenDisInst | 34 | back-end/include/IO.h:477 |
| DisRenIO | 1 | back-end/include/IO.h:582 |
| PrfAwakeIO | 1 | back-end/include/IO.h:589 |
| DisIssIO | 29 | back-end/include/IO.h:599 |
| DisIssReq | 2 | back-end/include/IO.h:635 |
| IssDisIO | 1 | back-end/include/IO.h:648 |
| IssAwakeIO | 1 | back-end/include/IO.h:658 |
| RobBroadcastIO | 18 | back-end/include/IO.h:668 |
| IssPrfIO | 27 | back-end/include/IO.h:714 |
| PrfExeIO | 31 | back-end/include/IO.h:760 |
| ExePrfIO | 11 | back-end/include/IO.h:837 |
| ExeIssIO | 2 | back-end/include/IO.h:875 |
| ExuRobIO | 16 | back-end/include/IO.h:888 |
| ExuIdIO | 4 | back-end/include/IO.h:934 |
| ExeCsrIO | 5 | back-end/include/IO.h:955 |

### 字段明细

#### `front_top_in`

源码位置：`front-end/front_IO.h:11`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | back2front_valid[COMMIT_WIDTH] |
| wire1_t | refetch |
| wire1_t | itlb_flush |
| wire1_t | fence_i |
| fetch_addr_t | refetch_address |
| pc_t | predict_base_pc[COMMIT_WIDTH] |
| wire1_t | predict_dir[COMMIT_WIDTH] |
| wire1_t | actual_dir[COMMIT_WIDTH] |
| br_type_t | actual_br_type[COMMIT_WIDTH] |
| target_addr_t | actual_target[COMMIT_WIDTH] |
| wire1_t | alt_pred[COMMIT_WIDTH] |
| pcpn_t | altpcpn[COMMIT_WIDTH] |
| pcpn_t | pcpn[COMMIT_WIDTH] |
| tage_idx_t | tage_idx[COMMIT_WIDTH][4] |
| tage_tag_t | tage_tag[COMMIT_WIDTH][4] |
| wire1_t | sc_used[COMMIT_WIDTH] |
| wire1_t | sc_pred[COMMIT_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[COMMIT_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[COMMIT_WIDTH] |
| wire1_t | loop_hit[COMMIT_WIDTH] |
| wire1_t | loop_pred[COMMIT_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[COMMIT_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[COMMIT_WIDTH] |
| wire1_t | FIFO_read_enable |
| CsrStatusIO | csr_status |

#### `front_top_out`

源码位置：`front-end/front_IO.h:42`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | FIFO_valid |
| pc_t | pc[FETCH_WIDTH] |
| inst_word_t | instructions[FETCH_WIDTH] |
| wire1_t | predict_dir[FETCH_WIDTH] |
| fetch_addr_t | predict_next_fetch_address |
| wire1_t | alt_pred[FETCH_WIDTH] |
| pcpn_t | altpcpn[FETCH_WIDTH] |
| pcpn_t | pcpn[FETCH_WIDTH] |
| wire1_t | page_fault_inst[FETCH_WIDTH] |
| wire1_t | inst_valid[FETCH_WIDTH] |
| tage_idx_t | tage_idx[FETCH_WIDTH][4] |
| tage_tag_t | tage_tag[FETCH_WIDTH][4] |
| wire1_t | sc_used[FETCH_WIDTH] |
| wire1_t | sc_pred[FETCH_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[FETCH_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[FETCH_WIDTH] |
| wire1_t | loop_hit[FETCH_WIDTH] |
| wire1_t | loop_pred[FETCH_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[FETCH_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[FETCH_WIDTH] |

#### `BPU_in`

源码位置：`front-end/front_IO.h:67`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | back2front_valid[COMMIT_WIDTH] |
| wire1_t | refetch |
| fetch_addr_t | refetch_address |
| pc_t | predict_base_pc[COMMIT_WIDTH] |
| wire1_t | predict_dir[COMMIT_WIDTH] |
| wire1_t | actual_dir[COMMIT_WIDTH] |
| br_type_t | actual_br_type[COMMIT_WIDTH] |
| target_addr_t | actual_target[COMMIT_WIDTH] |
| wire1_t | alt_pred[COMMIT_WIDTH] |
| pcpn_t | altpcpn[COMMIT_WIDTH] |
| pcpn_t | pcpn[COMMIT_WIDTH] |
| tage_idx_t | tage_idx[COMMIT_WIDTH][4] |
| tage_tag_t | tage_tag[COMMIT_WIDTH][4] |
| wire1_t | sc_used[COMMIT_WIDTH] |
| wire1_t | sc_pred[COMMIT_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[COMMIT_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[COMMIT_WIDTH] |
| wire1_t | loop_hit[COMMIT_WIDTH] |
| wire1_t | loop_pred[COMMIT_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[COMMIT_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[COMMIT_WIDTH] |
| wire1_t | icache_read_ready |

#### `BPU_out`

源码位置：`front-end/front_IO.h:97`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | icache_read_valid |
| fetch_addr_t | fetch_address |
| wire1_t | PTAB_write_enable |
| wire1_t | predict_dir[FETCH_WIDTH] |
| fetch_addr_t | predict_next_fetch_address |
| pc_t | predict_base_pc[FETCH_WIDTH] |
| wire1_t | alt_pred[FETCH_WIDTH] |
| pcpn_t | altpcpn[FETCH_WIDTH] |
| pcpn_t | pcpn[FETCH_WIDTH] |
| tage_idx_t | tage_idx[FETCH_WIDTH][4] |
| tage_tag_t | tage_tag[FETCH_WIDTH][4] |
| wire1_t | sc_used[FETCH_WIDTH] |
| wire1_t | sc_pred[FETCH_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[FETCH_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[FETCH_WIDTH] |
| wire1_t | loop_hit[FETCH_WIDTH] |
| wire1_t | loop_pred[FETCH_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[FETCH_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[FETCH_WIDTH] |
| wire1_t | two_ahead_valid |
| fetch_addr_t | two_ahead_target |
| wire1_t | mini_flush_req |
| wire1_t | mini_flush_correct |
| fetch_addr_t | mini_flush_target |

#### `FrontPreIO`

源码位置：`back-end/include/IO.h:108`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | inst[FETCH_WIDTH] |
| wire<32> | pc[FETCH_WIDTH] |
| wire<1> | valid[FETCH_WIDTH] |
| wire<1> | predict_dir[FETCH_WIDTH] |
| wire<1> | alt_pred[FETCH_WIDTH] |
| pcpn_t | altpcpn[FETCH_WIDTH] |
| pcpn_t | pcpn[FETCH_WIDTH] |
| wire<32> | predict_next_fetch_address[FETCH_WIDTH] |
| tage_idx_t | tage_idx[FETCH_WIDTH][4] |
| tage_tag_t | tage_tag[FETCH_WIDTH][4] |
| wire<1> | sc_used[FETCH_WIDTH] |
| wire<1> | sc_pred[FETCH_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[FETCH_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] |
| wire<1> | loop_used[FETCH_WIDTH] |
| wire<1> | loop_hit[FETCH_WIDTH] |
| wire<1> | loop_pred[FETCH_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[FETCH_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[FETCH_WIDTH] |
| wire<1> | page_fault_inst[FETCH_WIDTH] |

#### `PreFrontIO`

源码位置：`back-end/include/IO.h:96`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | fire[FETCH_WIDTH] |
| wire<1> | ready |

#### `CsrStatusIO`

源码位置：`back-end/include/IO.h:997`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | sstatus |
| wire<32> | mstatus |
| wire<32> | satp |
| wire<2> | privilege |

#### `icache_in`

源码位置：`front-end/front_IO.h:129`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | refetch |
| wire1_t | itlb_flush |
| wire1_t | fence_i |
| wire1_t | invalidate_req |
| wire1_t | icache_read_valid |
| fetch_addr_t | fetch_address |
| wire1_t | icache_read_valid_2 |
| fetch_addr_t | fetch_address_2 |
| CsrStatusIO | csr_status |
| wire1_t | run_comb_only |

#### `icache_out`

源码位置：`front-end/front_IO.h:145`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | icache_read_ready |
| wire1_t | icache_read_complete |
| wire1_t | icache_read_ready_2 |
| wire1_t | icache_read_complete_2 |
| wire1_t | perf_req_fire |
| wire1_t | perf_req_blocked |
| wire1_t | perf_resp_fire |
| wire1_t | perf_miss_event |
| wire1_t | perf_miss_busy |
| wire1_t | perf_outstanding_req |
| wire1_t | perf_itlb_hit |
| wire1_t | perf_itlb_miss |
| wire1_t | perf_itlb_fault |
| wire1_t | perf_itlb_retry |
| wire1_t | perf_itlb_retry_other_walk |
| wire1_t | perf_itlb_retry_walk_req_blocked |
| wire1_t | perf_itlb_retry_wait_walk_resp |
| wire1_t | perf_itlb_retry_local_walker_busy |
| inst_word_t | fetch_group[FETCH_WIDTH] |
| wire1_t | page_fault_inst[FETCH_WIDTH] |
| wire1_t | inst_valid[FETCH_WIDTH] |
| inst_word_t | fetch_group_2[FETCH_WIDTH] |
| wire1_t | page_fault_inst_2[FETCH_WIDTH] |
| wire1_t | inst_valid_2[FETCH_WIDTH] |
| pc_t | fetch_pc |
| pc_t | fetch_pc_2 |

#### `instruction_FIFO_in`

源码位置：`front-end/front_IO.h:177`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | refetch |
| wire1_t | write_enable |
| inst_word_t | fetch_group[FETCH_WIDTH] |
| pc_t | pc[FETCH_WIDTH] |
| wire1_t | page_fault_inst[FETCH_WIDTH] |
| wire1_t | inst_valid[FETCH_WIDTH] |
| wire1_t | read_enable |
| predecode_type_t | predecode_type[FETCH_WIDTH] |
| target_addr_t | predecode_target_address[FETCH_WIDTH] |
| pc_t | seq_next_pc |

#### `instruction_FIFO_out`

源码位置：`front-end/front_IO.h:194`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | full |
| wire1_t | empty |
| wire1_t | FIFO_valid |
| inst_word_t | instructions[FETCH_WIDTH] |
| pc_t | pc[FETCH_WIDTH] |
| wire1_t | page_fault_inst[FETCH_WIDTH] |
| wire1_t | inst_valid[FETCH_WIDTH] |
| predecode_type_t | predecode_type[FETCH_WIDTH] |
| target_addr_t | predecode_target_address[FETCH_WIDTH] |
| pc_t | seq_next_pc |

#### `PTAB_in`

源码位置：`front-end/front_IO.h:208`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | refetch |
| wire1_t | write_enable |
| wire1_t | predict_dir[FETCH_WIDTH] |
| fetch_addr_t | predict_next_fetch_address |
| pc_t | predict_base_pc[FETCH_WIDTH] |
| wire1_t | alt_pred[FETCH_WIDTH] |
| pcpn_t | altpcpn[FETCH_WIDTH] |
| pcpn_t | pcpn[FETCH_WIDTH] |
| tage_idx_t | tage_idx[FETCH_WIDTH][4] |
| tage_tag_t | tage_tag[FETCH_WIDTH][4] |
| wire1_t | sc_used[FETCH_WIDTH] |
| wire1_t | sc_pred[FETCH_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[FETCH_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[FETCH_WIDTH] |
| wire1_t | loop_hit[FETCH_WIDTH] |
| wire1_t | loop_pred[FETCH_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[FETCH_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[FETCH_WIDTH] |
| wire1_t | read_enable |
| wire1_t | need_mini_flush |

#### `PTAB_out`

源码位置：`front-end/front_IO.h:237`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | dummy_entry |
| wire1_t | full |
| wire1_t | empty |
| wire1_t | predict_dir[FETCH_WIDTH] |
| fetch_addr_t | predict_next_fetch_address |
| pc_t | predict_base_pc[FETCH_WIDTH] |
| wire1_t | alt_pred[FETCH_WIDTH] |
| pcpn_t | altpcpn[FETCH_WIDTH] |
| pcpn_t | pcpn[FETCH_WIDTH] |
| tage_idx_t | tage_idx[FETCH_WIDTH][4] |
| tage_tag_t | tage_tag[FETCH_WIDTH][4] |
| wire1_t | sc_used[FETCH_WIDTH] |
| wire1_t | sc_pred[FETCH_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[FETCH_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[FETCH_WIDTH] |
| wire1_t | loop_hit[FETCH_WIDTH] |
| wire1_t | loop_pred[FETCH_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[FETCH_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[FETCH_WIDTH] |

#### `front2back_FIFO_in`

源码位置：`front-end/front_IO.h:263`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | refetch |
| wire1_t | write_enable |
| wire1_t | read_enable |
| inst_word_t | fetch_group[FETCH_WIDTH] |
| wire1_t | page_fault_inst[FETCH_WIDTH] |
| wire1_t | inst_valid[FETCH_WIDTH] |
| wire1_t | predict_dir_corrected[FETCH_WIDTH] |
| fetch_addr_t | predict_next_fetch_address_corrected |
| pc_t | predict_base_pc[FETCH_WIDTH] |
| wire1_t | alt_pred[FETCH_WIDTH] |
| pcpn_t | altpcpn[FETCH_WIDTH] |
| pcpn_t | pcpn[FETCH_WIDTH] |
| tage_idx_t | tage_idx[FETCH_WIDTH][4] |
| tage_tag_t | tage_tag[FETCH_WIDTH][4] |
| wire1_t | sc_used[FETCH_WIDTH] |
| wire1_t | sc_pred[FETCH_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[FETCH_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[FETCH_WIDTH] |
| wire1_t | loop_hit[FETCH_WIDTH] |
| wire1_t | loop_pred[FETCH_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[FETCH_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[FETCH_WIDTH] |

#### `front2back_FIFO_out`

源码位置：`front-end/front_IO.h:292`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | full |
| wire1_t | empty |
| wire1_t | front2back_FIFO_valid |
| inst_word_t | fetch_group[FETCH_WIDTH] |
| wire1_t | page_fault_inst[FETCH_WIDTH] |
| wire1_t | inst_valid[FETCH_WIDTH] |
| wire1_t | predict_dir_corrected[FETCH_WIDTH] |
| fetch_addr_t | predict_next_fetch_address_corrected |
| pc_t | predict_base_pc[FETCH_WIDTH] |
| wire1_t | alt_pred[FETCH_WIDTH] |
| pcpn_t | altpcpn[FETCH_WIDTH] |
| pcpn_t | pcpn[FETCH_WIDTH] |
| tage_idx_t | tage_idx[FETCH_WIDTH][4] |
| tage_tag_t | tage_tag[FETCH_WIDTH][4] |
| wire1_t | sc_used[FETCH_WIDTH] |
| wire1_t | sc_pred[FETCH_WIDTH] |
| tage_scl_meta_sum_t | sc_sum[FETCH_WIDTH] |
| tage_scl_meta_idx_t | sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE] |
| wire1_t | loop_used[FETCH_WIDTH] |
| wire1_t | loop_hit[FETCH_WIDTH] |
| wire1_t | loop_pred[FETCH_WIDTH] |
| tage_loop_meta_idx_t | loop_idx[FETCH_WIDTH] |
| tage_loop_meta_tag_t | loop_tag[FETCH_WIDTH] |

#### `fetch_address_FIFO_in`

源码位置：`front-end/front_IO.h:319`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | refetch |
| wire1_t | read_enable |
| wire1_t | write_enable |
| fetch_addr_t | fetch_address |

#### `fetch_address_FIFO_out`

源码位置：`front-end/front_IO.h:327`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | full |
| wire1_t | empty |
| wire1_t | read_valid |
| fetch_addr_t | fetch_address |

#### `FetchAddrCombIn`

源码位置：`front-end/train_IO.h:12`

| 类型 | 字段名 |
| --- | --- |
| fetch_address_FIFO_in | inp |
| fetch_address_FIFO_read_data | rd |

#### `FetchAddrCombOut`

源码位置：`front-end/train_IO.h:17`

| 类型 | 字段名 |
| --- | --- |
| fetch_address_FIFO_out | out_regs |
| wire1_t | clear_fifo |
| wire1_t | push_en |
| fetch_addr_t | push_data |
| wire1_t | pop_en |

#### `InstructionCombIn`

源码位置：`front-end/train_IO.h:25`

| 类型 | 字段名 |
| --- | --- |
| instruction_FIFO_in | inp |
| instruction_FIFO_read_data | rd |

#### `InstructionCombOut`

源码位置：`front-end/train_IO.h:30`

| 类型 | 字段名 |
| --- | --- |
| instruction_FIFO_out | out_regs |
| wire1_t | clear_fifo |
| wire1_t | push_en |
| instruction_FIFO_entry | push_entry |
| wire1_t | pop_en |

#### `PtabCombIn`

源码位置：`front-end/train_IO.h:38`

| 类型 | 字段名 |
| --- | --- |
| PTAB_in | inp |
| PTAB_read_data | rd |

#### `PtabCombOut`

源码位置：`front-end/train_IO.h:43`

| 类型 | 字段名 |
| --- | --- |
| PTAB_out | out_regs |
| wire1_t | clear_ptab |
| wire1_t | push_write_en |
| PTAB_entry | push_write_entry |
| wire1_t | push_dummy_en |
| PTAB_entry | push_dummy_entry |
| wire1_t | pop_en |

#### `Front2BackCombIn`

源码位置：`front-end/train_IO.h:53`

| 类型 | 字段名 |
| --- | --- |
| front2back_FIFO_in | inp |
| front2back_FIFO_read_data | rd |

#### `Front2BackCombOut`

源码位置：`front-end/train_IO.h:58`

| 类型 | 字段名 |
| --- | --- |
| front2back_FIFO_out | out_regs |
| wire1_t | clear_fifo |
| wire1_t | push_en |
| front2back_FIFO_entry | push_entry |
| wire1_t | pop_en |

#### `FrontUpdateRequest`

源码位置：`front-end/train_IO.h:246`

| 类型 | 字段名 |
| --- | --- |
| front_top_out | out_regs |
| PendingBpuSeqTxn | bpu_seq_txn |
| PendingFrontState | front_state |

#### `FrontBpuInputCombIn`

源码位置：`front-end/train_IO.h:256`

| 类型 | 字段名 |
| --- | --- |
| BPU_in | bpu_seed |
| wire1_t | do_refetch |
| fetch_addr_t | refetch_addr |
| wire1_t | icache_ready |

#### `FrontBpuInputCombOut`

源码位置：`front-end/train_IO.h:263`

| 类型 | 字段名 |
| --- | --- |
| BPU_in | bpu_in |

#### `FrontGlobalControlCombIn`

源码位置：`front-end/train_IO.h:267`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | reset |
| wire1_t | backend_refetch |
| fetch_addr_t | backend_refetch_address |
| wire1_t | predecode_refetch_snapshot |
| fetch_addr_t | predecode_refetch_address_snapshot |

#### `FrontGlobalControlCombOut`

源码位置：`front-end/train_IO.h:275`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | global_reset |
| wire1_t | global_refetch |
| fetch_addr_t | refetch_address |

#### `FrontReadEnableCombIn`

源码位置：`front-end/train_IO.h:281`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | backend_fifo_read_enable |
| wire1_t | fetch_addr_fifo_empty_latch_snapshot |
| wire1_t | fifo_empty_latch_snapshot |
| wire1_t | ptab_empty_latch_snapshot |
| wire1_t | front2back_fifo_full_latch_snapshot |
| wire1_t | global_reset |
| wire1_t | global_refetch |
| wire1_t | icache_ready |
| wire1_t | icache_ready_2 |

#### `FrontReadEnableCombOut`

源码位置：`front-end/train_IO.h:293`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | fetch_addr_fifo_read_enable_slot0 |
| wire1_t | fetch_addr_fifo_read_enable_slot1_candidate |
| wire1_t | predecode_can_run_old |
| wire1_t | inst_fifo_read_enable |
| wire1_t | ptab_read_enable |
| wire1_t | front2back_read_enable |

#### `FrontReadStageInputCombIn`

源码位置：`front-end/train_IO.h:302`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | backend_refetch |
| wire1_t | global_reset |
| wire1_t | global_refetch |
| wire1_t | fetch_addr_fifo_read_enable_slot0 |
| wire1_t | inst_fifo_read_enable |
| wire1_t | ptab_read_enable |
| wire1_t | front2back_read_enable |

#### `FrontReadStageInputCombOut`

源码位置：`front-end/train_IO.h:312`

| 类型 | 字段名 |
| --- | --- |
| fetch_address_FIFO_in | fetch_addr_fifo_in |
| instruction_FIFO_in | fifo_in |
| PTAB_in | ptab_in |
| front2back_FIFO_in | front2back_fifo_in |

#### `FrontBpuControlCombIn`

源码位置：`front-end/train_IO.h:319`

| 类型 | 字段名 |
| --- | --- |
| BPU_in | bpu_in_seed |
| wire1_t | fetch_addr_fifo_full_latch_snapshot |
| wire1_t | ptab_full_latch_snapshot |
| wire1_t | global_reset |
| wire1_t | global_refetch |
| fetch_addr_t | refetch_address |

#### `FrontBpuControlCombOut`

源码位置：`front-end/train_IO.h:328`

| 类型 | 字段名 |
| --- | --- |
| wire1_t | bpu_stall |
| wire1_t | bpu_can_run |
| wire1_t | bpu_icache_ready |
| BPU_in | bpu_in |
| BPU_TOP::InputPayload | bpu_input |

#### `FrontBpuOutputCombIn`

源码位置：`front-end/train_IO.h:336`

| 类型 | 字段名 |
| --- | --- |
| BPU_TOP::OutputPayload | bpu_output |

#### `FrontBpuOutputCombOut`

源码位置：`front-end/train_IO.h:340`

| 类型 | 字段名 |
| --- | --- |
| BPU_out | bpu_out |

#### `FrontPtabWriteCombIn`

源码位置：`front-end/train_IO.h:344`

| 类型 | 字段名 |
| --- | --- |
| BPU_TOP::OutputPayload | bpu_output |
| wire1_t | global_reset |
| wire1_t | global_refetch |
| wire1_t | ptab_can_write |

#### `FrontPtabWriteCombOut`

源码位置：`front-end/train_IO.h:351`

| 类型 | 字段名 |
| --- | --- |
| PTAB_in | ptab_in |

#### `FrontCheckerInputCombIn`

源码位置：`front-end/train_IO.h:355`

| 类型 | 字段名 |
| --- | --- |
| instruction_FIFO_out | fifo_out |
| PTAB_out | ptab_out |

#### `FrontCheckerInputCombOut`

源码位置：`front-end/train_IO.h:360`

| 类型 | 字段名 |
| --- | --- |
| predecode_checker_in | checker_in |

#### `FrontFront2backWriteCombIn`

源码位置：`front-end/train_IO.h:364`

| 类型 | 字段名 |
| --- | --- |
| instruction_FIFO_out | fifo_out |
| PTAB_out | ptab_out |
| predecode_checker_out | checker_out |
| wire1_t | use_front2back_output_bypass |

#### `FrontFront2backWriteCombOut`

源码位置：`front-end/train_IO.h:371`

| 类型 | 字段名 |
| --- | --- |
| front2back_FIFO_in | front2back_fifo_in |
| front2back_FIFO_out | bypass_front2back_fifo_out |

#### `FrontOutputCombIn`

源码位置：`front-end/train_IO.h:376`

| 类型 | 字段名 |
| --- | --- |
| front2back_FIFO_out | saved_front2back_fifo_out |
| front2back_FIFO_out | bypass_front2back_fifo_out |
| wire1_t | use_front2back_output_bypass |

#### `FrontOutputCombOut`

源码位置：`front-end/train_IO.h:382`

| 类型 | 字段名 |
| --- | --- |
| front_top_out | out |

#### `DecRenIO`

源码位置：`back-end/include/IO.h:12`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<AREG_IDX_WIDTH> | src1_areg |
| wire<AREG_IDX_WIDTH> | src2_areg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<INST_TYPE_WIDTH> | type |
| wire<1> | dest_en |
| wire<1> | src1_en |
| wire<1> | src2_en |
| wire<1> | is_atomic |
| wire<1> | src1_is_pc |
| wire<1> | src2_is_imm |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_TAG_WIDTH> | br_id |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<CSR_IDX_WIDTH> | csr_idx |
| wire<ROB_CPLT_MASK_WIDTH> | expect_mask |
| wire<ROB_CPLT_MASK_WIDTH> | cplt_mask |
| wire<1> | page_fault_inst |
| wire<1> | illegal_inst |
| TmaMeta | tma |
| DebugMeta | dbg |
| DecRenInst | uop[DECODE_WIDTH] |
| wire<1> | valid[DECODE_WIDTH] |

#### `DecRenInst`

源码位置：`back-end/include/IO.h:13`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<AREG_IDX_WIDTH> | src1_areg |
| wire<AREG_IDX_WIDTH> | src2_areg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<INST_TYPE_WIDTH> | type |
| wire<1> | dest_en |
| wire<1> | src1_en |
| wire<1> | src2_en |
| wire<1> | is_atomic |
| wire<1> | src1_is_pc |
| wire<1> | src2_is_imm |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_TAG_WIDTH> | br_id |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<CSR_IDX_WIDTH> | csr_idx |
| wire<ROB_CPLT_MASK_WIDTH> | expect_mask |
| wire<ROB_CPLT_MASK_WIDTH> | cplt_mask |
| wire<1> | page_fault_inst |
| wire<1> | illegal_inst |
| TmaMeta | tma |
| DebugMeta | dbg |

#### `RenDecIO`

源码位置：`back-end/include/IO.h:80`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | ready |

#### `IduConsumeIO`

源码位置：`back-end/include/IO.h:88`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | fire[DECODE_WIDTH] |

#### `DecBroadcastIO`

源码位置：`back-end/include/IO.h:181`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | mispred |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<BR_TAG_WIDTH> | br_id |
| wire<ROB_IDX_WIDTH> | redirect_rob_idx |
| wire<BR_MASK_WIDTH> | clear_mask |

#### `FtqPcReadReq`

源码位置：`back-end/include/IO.h:199`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | valid |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |

#### `FtqPcReadResp`

源码位置：`back-end/include/IO.h:211`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | valid |
| wire<1> | entry_valid |
| wire<32> | pc |
| wire<1> | pred_taken |
| wire<32> | next_pc |

#### `FtqExuPcReqIO`

源码位置：`back-end/include/IO.h:227`

| 类型 | 字段名 |
| --- | --- |
| FtqPcReadReq | req[FTQ_EXU_PC_PORT_NUM] |

#### `FtqExuPcRespIO`

源码位置：`back-end/include/IO.h:236`

| 类型 | 字段名 |
| --- | --- |
| FtqPcReadResp | resp[FTQ_EXU_PC_PORT_NUM] |

#### `FtqRobPcReqIO`

源码位置：`back-end/include/IO.h:245`

| 类型 | 字段名 |
| --- | --- |
| FtqPcReadReq | req[FTQ_ROB_PC_PORT_NUM] |

#### `FtqRobPcRespIO`

源码位置：`back-end/include/IO.h:254`

| 类型 | 字段名 |
| --- | --- |
| FtqPcReadResp | resp[FTQ_ROB_PC_PORT_NUM] |

#### `PreIssueIO`

源码位置：`back-end/include/IO.h:263`

| 类型 | 字段名 |
| --- | --- |
| InstructionBufferEntry | entries[DECODE_WIDTH] |

#### `RobCommitIO`

源码位置：`back-end/include/IO.h:276`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | old_dest_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<1> | mispred |
| wire<1> | br_taken |
| wire<1> | dest_en |
| wire<7> | func7 |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<1> | rob_flag |
| wire<STQ_IDX_WIDTH> | stq_idx |
| wire<1> | stq_flag |
| wire<1> | page_fault_inst |
| wire<1> | page_fault_load |
| wire<1> | page_fault_store |
| wire<1> | illegal_inst |
| wire<INST_TYPE_WIDTH> | type |
| TmaMeta | tma |
| DebugMeta | dbg |
| wire<1> | flush_pipe |
| InstEntry | dst |
| return | dst |
| wire<1> | valid |
| RobCommitInst | uop |
| RobCommitEntry | commit_entry[COMMIT_WIDTH] |

#### `RobCommitInst`

源码位置：`back-end/include/IO.h:277`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | old_dest_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<1> | mispred |
| wire<1> | br_taken |
| wire<1> | dest_en |
| wire<7> | func7 |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<1> | rob_flag |
| wire<STQ_IDX_WIDTH> | stq_idx |
| wire<1> | stq_flag |
| wire<1> | page_fault_inst |
| wire<1> | page_fault_load |
| wire<1> | page_fault_store |
| wire<1> | illegal_inst |
| wire<INST_TYPE_WIDTH> | type |
| TmaMeta | tma |
| DebugMeta | dbg |
| wire<1> | flush_pipe |
| InstEntry | dst |
| return | dst |

#### `RobDisIO`

源码位置：`back-end/include/IO.h:374`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | head_is_memory |
| wire<1> | head_is_miss |
| wire<1> | head_not_ready |
| } | tma |
| wire<1> | ready |
| wire<1> | empty |
| wire<1> | stall |
| wire<ROB_IDX_WIDTH> | enq_idx |
| wire<1> | rob_flag |

#### `TmaMeta`

源码位置：`back-end/include/IO.h:375`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | head_is_memory |
| wire<1> | head_is_miss |
| wire<1> | head_not_ready |

#### `DisRobIO`

源码位置：`back-end/include/IO.h:399`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<AREG_IDX_WIDTH> | src1_areg |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | old_dest_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<1> | mispred |
| wire<1> | br_taken |
| wire<INST_TYPE_WIDTH> | type |
| wire<1> | dest_en |
| wire<1> | is_atomic |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<STQ_IDX_WIDTH> | stq_idx |
| wire<1> | stq_flag |
| wire<LDQ_IDX_WIDTH> | ldq_idx |
| wire<ROB_CPLT_MASK_WIDTH> | expect_mask |
| wire<ROB_CPLT_MASK_WIDTH> | cplt_mask |
| wire<1> | rob_flag |
| wire<1> | page_fault_inst |
| wire<1> | illegal_inst |
| wire<1> | flush_pipe |
| TmaMeta | tma |
| DebugMeta | dbg |
| DisRobInst | uop[DECODE_WIDTH] |
| wire<1> | valid[DECODE_WIDTH] |
| wire<1> | dis_fire[DECODE_WIDTH] |

#### `DisRobInst`

源码位置：`back-end/include/IO.h:400`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<AREG_IDX_WIDTH> | src1_areg |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | old_dest_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<1> | mispred |
| wire<1> | br_taken |
| wire<INST_TYPE_WIDTH> | type |
| wire<1> | dest_en |
| wire<1> | is_atomic |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<STQ_IDX_WIDTH> | stq_idx |
| wire<1> | stq_flag |
| wire<LDQ_IDX_WIDTH> | ldq_idx |
| wire<ROB_CPLT_MASK_WIDTH> | expect_mask |
| wire<ROB_CPLT_MASK_WIDTH> | cplt_mask |
| wire<1> | rob_flag |
| wire<1> | page_fault_inst |
| wire<1> | illegal_inst |
| wire<1> | flush_pipe |
| TmaMeta | tma |
| DebugMeta | dbg |

#### `RenDisIO`

源码位置：`back-end/include/IO.h:476`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<AREG_IDX_WIDTH> | src1_areg |
| wire<AREG_IDX_WIDTH> | src2_areg |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | src1_preg |
| wire<PRF_IDX_WIDTH> | src2_preg |
| wire<PRF_IDX_WIDTH> | old_dest_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<INST_TYPE_WIDTH> | type |
| wire<1> | dest_en |
| wire<1> | src1_en |
| wire<1> | src2_en |
| wire<1> | is_atomic |
| wire<1> | src1_busy |
| wire<1> | src2_busy |
| wire<1> | src1_is_pc |
| wire<1> | src2_is_imm |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_TAG_WIDTH> | br_id |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<CSR_IDX_WIDTH> | csr_idx |
| wire<ROB_CPLT_MASK_WIDTH> | expect_mask |
| wire<ROB_CPLT_MASK_WIDTH> | cplt_mask |
| wire<1> | page_fault_inst |
| wire<1> | illegal_inst |
| TmaMeta | tma |
| DebugMeta | dbg |
| RenDisInst | dst |
| return | dst |
| RenDisInst | uop[DECODE_WIDTH] |
| wire<1> | valid[DECODE_WIDTH] |

#### `RenDisInst`

源码位置：`back-end/include/IO.h:477`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<AREG_IDX_WIDTH> | dest_areg |
| wire<AREG_IDX_WIDTH> | src1_areg |
| wire<AREG_IDX_WIDTH> | src2_areg |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | src1_preg |
| wire<PRF_IDX_WIDTH> | src2_preg |
| wire<PRF_IDX_WIDTH> | old_dest_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | ftq_is_last |
| wire<INST_TYPE_WIDTH> | type |
| wire<1> | dest_en |
| wire<1> | src1_en |
| wire<1> | src2_en |
| wire<1> | is_atomic |
| wire<1> | src1_busy |
| wire<1> | src2_busy |
| wire<1> | src1_is_pc |
| wire<1> | src2_is_imm |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_TAG_WIDTH> | br_id |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<CSR_IDX_WIDTH> | csr_idx |
| wire<ROB_CPLT_MASK_WIDTH> | expect_mask |
| wire<ROB_CPLT_MASK_WIDTH> | cplt_mask |
| wire<1> | page_fault_inst |
| wire<1> | illegal_inst |
| TmaMeta | tma |
| DebugMeta | dbg |
| RenDisInst | dst |
| return | dst |

#### `DisRenIO`

源码位置：`back-end/include/IO.h:582`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | ready |

#### `PrfAwakeIO`

源码位置：`back-end/include/IO.h:589`

| 类型 | 字段名 |
| --- | --- |
| WakeInfo | wake[LSU_LOAD_WB_WIDTH] |

#### `DisIssIO`

源码位置：`back-end/include/IO.h:599`

| 类型 | 字段名 |
| --- | --- |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | src1_preg |
| wire<PRF_IDX_WIDTH> | src2_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | is_atomic |
| wire<1> | dest_en |
| wire<1> | src1_en |
| wire<1> | src2_en |
| wire<1> | src1_busy |
| wire<1> | src2_busy |
| wire<1> | src1_is_pc |
| wire<1> | src2_is_imm |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_TAG_WIDTH> | br_id |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<CSR_IDX_WIDTH> | csr_idx |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<STQ_IDX_WIDTH> | stq_idx |
| wire<1> | stq_flag |
| wire<LDQ_IDX_WIDTH> | ldq_idx |
| wire<1> | rob_flag |
| wire<UOP_TYPE_WIDTH> | op |
| DebugMeta | dbg |
| wire<1> | valid |
| DisIssUop | uop |
| DisIssReq | req[IQ_NUM][MAX_IQ_DISPATCH_WIDTH] |

#### `DisIssReq`

源码位置：`back-end/include/IO.h:635`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | valid |
| DisIssUop | uop |

#### `IssDisIO`

源码位置：`back-end/include/IO.h:648`

| 类型 | 字段名 |
| --- | --- |
| wire<IQ_READY_NUM_WIDTH> | ready_num[IQ_NUM] |

#### `IssAwakeIO`

源码位置：`back-end/include/IO.h:658`

| 类型 | 字段名 |
| --- | --- |
| WakeInfo | wake[MAX_WAKEUP_PORTS] |

#### `RobBroadcastIO`

源码位置：`back-end/include/IO.h:668`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | flush |
| wire<1> | mret |
| wire<1> | sret |
| wire<1> | ecall |
| wire<1> | exception |
| wire<1> | fence |
| wire<1> | fence_i |
| wire<1> | page_fault_inst |
| wire<1> | page_fault_load |
| wire<1> | page_fault_store |
| wire<1> | illegal_inst |
| wire<1> | interrupt |
| wire<32> | trap_val |
| wire<32> | pc |
| wire<ROB_IDX_WIDTH> | head_rob_idx |
| wire<1> | head_valid |
| wire<ROB_IDX_WIDTH> | head_incomplete_rob_idx |
| wire<1> | head_incomplete_valid |

#### `IssPrfIO`

源码位置：`back-end/include/IO.h:714`

| 类型 | 字段名 |
| --- | --- |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | src1_preg |
| wire<PRF_IDX_WIDTH> | src2_preg |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | is_atomic |
| wire<1> | dest_en |
| wire<1> | src1_en |
| wire<1> | src2_en |
| wire<1> | src1_is_pc |
| wire<1> | src2_is_imm |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_TAG_WIDTH> | br_id |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<CSR_IDX_WIDTH> | csr_idx |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<STQ_IDX_WIDTH> | stq_idx |
| wire<1> | stq_flag |
| wire<LDQ_IDX_WIDTH> | ldq_idx |
| wire<1> | rob_flag |
| wire<UOP_TYPE_WIDTH> | op |
| DebugMeta | dbg |
| wire<1> | valid |
| IssPrfUop | uop |
| IssPrfEntry | iss_entry[ISSUE_WIDTH] |

#### `PrfExeIO`

源码位置：`back-end/include/IO.h:760`

| 类型 | 字段名 |
| --- | --- |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<PRF_IDX_WIDTH> | src1_preg |
| wire<PRF_IDX_WIDTH> | src2_preg |
| wire<32> | src1_rdata |
| wire<32> | src2_rdata |
| wire<FTQ_IDX_WIDTH> | ftq_idx |
| wire<FTQ_OFFSET_WIDTH> | ftq_offset |
| wire<1> | is_atomic |
| wire<1> | dest_en |
| wire<1> | src1_en |
| wire<1> | src2_en |
| wire<1> | src1_is_pc |
| wire<1> | src2_is_imm |
| wire<3> | func3 |
| wire<7> | func7 |
| wire<32> | imm |
| wire<BR_TAG_WIDTH> | br_id |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<CSR_IDX_WIDTH> | csr_idx |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<STQ_IDX_WIDTH> | stq_idx |
| wire<1> | stq_flag |
| wire<LDQ_IDX_WIDTH> | ldq_idx |
| wire<1> | rob_flag |
| wire<UOP_TYPE_WIDTH> | op |
| DebugMeta | dbg |
| PrfExeUop | dst |
| return | dst |
| wire<1> | valid |
| PrfExeUop | uop |
| PrfExeEntry | iss_entry[ISSUE_WIDTH] |

#### `ExePrfIO`

源码位置：`back-end/include/IO.h:837`

| 类型 | 字段名 |
| --- | --- |
| wire<PRF_IDX_WIDTH> | dest_preg |
| wire<32> | result |
| wire<BR_MASK_WIDTH> | br_mask |
| wire<1> | dest_en |
| wire<UOP_TYPE_WIDTH> | op |
| ExePrfWbUop | dst |
| return | dst |
| wire<1> | valid |
| ExePrfWbUop | uop |
| ExePrfEntry | entry[ISSUE_WIDTH] |
| ExePrfEntry | bypass[TOTAL_FU_COUNT] |

#### `ExeIssIO`

源码位置：`back-end/include/IO.h:875`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | ready[ISSUE_WIDTH] |
| wire<MAX_UOP_TYPE> | fu_ready_mask[ISSUE_WIDTH] |

#### `ExuRobIO`

源码位置：`back-end/include/IO.h:888`

| 类型 | 字段名 |
| --- | --- |
| wire<32> | diag_val |
| wire<32> | result |
| wire<ROB_IDX_WIDTH> | rob_idx |
| wire<1> | mispred |
| wire<1> | br_taken |
| wire<1> | page_fault_inst |
| wire<1> | page_fault_load |
| wire<1> | page_fault_store |
| wire<UOP_TYPE_WIDTH> | op |
| DebugMeta | dbg |
| wire<1> | flush_pipe |
| ExuRobUop | dst |
| return | dst |
| wire<1> | valid |
| ExuRobUop | uop |
| ExuRobEntry | entry[ISSUE_WIDTH] |

#### `ExuIdIO`

源码位置：`back-end/include/IO.h:934`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | mispred |
| wire<32> | redirect_pc |
| wire<ROB_IDX_WIDTH> | redirect_rob_idx |
| wire<BR_TAG_WIDTH> | br_id |

#### `ExeCsrIO`

源码位置：`back-end/include/IO.h:955`

| 类型 | 字段名 |
| --- | --- |
| wire<1> | we |
| wire<1> | re |
| wire<12> | idx |
| wire<32> | wdata |
| wire<32> | wcmd |

## Verilog 模块与端口

| 模块 | 输入端口数 | 输出端口数 | 源码位置 |
| --- | --- | --- | --- |
| axi_ddr_top | 1 | 1 | axi_end/axi_ddr/axi_ddr_top.v:4 |
| axi_interconnect_top | 6 | 5 | axi_end/axi_interconnect/axi_interconnect_top.v:6 |
| axi_mmio_top | 1 | 1 | axi_end/axi_mmio/axi_mmio_top.v:5 |
| axi_router_top | 1 | 1 | axi_end/axi_router/axi_router_top.v:5 |
| axi_top | 8 | 7 | axi_end/axi_top.v:11 |
| mem_axi_bridge_top | 8 | 8 | axi_end/mem_axi_bridge/mem_axi_bridge_top.v:10 |
| back_top | 23 | 15 | back_end/back_top.v:12 |
| csr_top | 3 | 10 | back_end/csr/csr_top.v:6 |
| dispatch_top | 8 | 4 | back_end/dispatch/dispatch_top.v:7 |
| exu_top | 6 | 6 | back_end/exu/exu_top.v:7 |
| idu_top | 4 | 15 | back_end/idu/idu_top.v:8 |
| isu_top | 5 | 3 | back_end/isu/isu_top.v:6 |
| lsu_top | 9 | 6 | back_end/lsu/lsu_top.v:8 |
| preiduqueue_top | 7 | 6 | back_end/preiduqueue/preiduqueue_top.v:7 |
| prf_top | 5 | 3 | back_end/prf/prf_top.v:6 |
| ren_top | 5 | 2 | back_end/ren/ren_top.v:6 |
| rob_top | 6 | 23 | back_end/rob/rob_top.v:6 |
| bpu_hist_comb_top | 1 | 1 | front_end/bpu/bpu_hist_comb/bpu_hist_comb_top.v:8 |
| bpu_hist_comb_bsd_top | 1 | 1 | front_end/bpu/bpu_hist_comb/bpu_hist_comb_top.v:48 |
| bpu_post_read_req_comb_top | 1 | 1 | front_end/bpu/bpu_post_read_req_comb/bpu_post_read_req_comb_top.v:8 |
| bpu_post_read_req_comb_bsd_top | 1 | 1 | front_end/bpu/bpu_post_read_req_comb/bpu_post_read_req_comb_top.v:48 |
| bpu_pre_read_req_comb_top | 1 | 1 | front_end/bpu/bpu_pre_read_req_comb/bpu_pre_read_req_comb_top.v:8 |
| bpu_pre_read_req_comb_bsd_top | 1 | 1 | front_end/bpu/bpu_pre_read_req_comb/bpu_pre_read_req_comb_top.v:48 |
| bpu_predict_main_comb_top | 1 | 1 | front_end/bpu/bpu_predict_main_comb/bpu_predict_main_comb_top.v:8 |
| bpu_predict_main_comb_bsd_top | 1 | 1 | front_end/bpu/bpu_predict_main_comb/bpu_predict_main_comb_top.v:48 |
| bpu_queue_comb_top | 1 | 1 | front_end/bpu/bpu_queue_comb/bpu_queue_comb_top.v:8 |
| bpu_queue_comb_bsd_top | 1 | 1 | front_end/bpu/bpu_queue_comb/bpu_queue_comb_top.v:48 |
| bpu_submodule_bind_comb_top | 1 | 1 | front_end/bpu/bpu_submodule_bind_comb/bpu_submodule_bind_comb_top.v:8 |
| bpu_submodule_bind_comb_bsd_top | 1 | 1 | front_end/bpu/bpu_submodule_bind_comb/bpu_submodule_bind_comb_top.v:48 |
| bpu_top | 1 | 1 | front_end/bpu/bpu_top.v:5 |
| tage_comb_top | 1 | 1 | front_end/bpu/dir_predictor/tage_comb/tage_comb_top.v:8 |
| tage_comb_bsd_top | 1 | 1 | front_end/bpu/dir_predictor/tage_comb/tage_comb_top.v:48 |
| tage_pre_read_comb_top | 1 | 1 | front_end/bpu/dir_predictor/tage_pre_read_comb/tage_pre_read_comb_top.v:8 |
| tage_pre_read_comb_bsd_top | 1 | 1 | front_end/bpu/dir_predictor/tage_pre_read_comb/tage_pre_read_comb_top.v:48 |
| btb_comb_top | 1 | 1 | front_end/bpu/target_predictor/btb_comb/btb_comb_top.v:8 |
| btb_comb_bsd_top | 1 | 1 | front_end/bpu/target_predictor/btb_comb/btb_comb_top.v:48 |
| btb_post_read_req_comb_top | 1 | 1 | front_end/bpu/target_predictor/btb_post_read_req_comb/btb_post_read_req_comb_top.v:8 |
| btb_post_read_req_comb_bsd_top | 1 | 1 | front_end/bpu/target_predictor/btb_post_read_req_comb/btb_post_read_req_comb_top.v:48 |
| btb_pre_read_comb_top | 1 | 1 | front_end/bpu/target_predictor/btb_pre_read_comb/btb_pre_read_comb_top.v:8 |
| btb_pre_read_comb_bsd_top | 1 | 1 | front_end/bpu/target_predictor/btb_pre_read_comb/btb_pre_read_comb_top.v:48 |
| type_pred_comb_top | 1 | 1 | front_end/bpu/type_predictor/type_pred_comb/type_pred_comb_top.v:8 |
| type_pred_comb_bsd_top | 1 | 1 | front_end/bpu/type_predictor/type_pred_comb/type_pred_comb_top.v:48 |
| type_predictor_pre_read_comb_top | 1 | 1 | front_end/bpu/type_predictor/type_predictor_pre_read_comb/type_predictor_pre_read_comb_top.v:8 |
| type_predictor_pre_read_comb_bsd_top | 1 | 1 | front_end/bpu/type_predictor/type_predictor_pre_read_comb/type_predictor_pre_read_comb_top.v:48 |
| PTAB_comb_top | 1 | 1 | front_end/fifo/PTAB_comb/PTAB_comb_top.v:8 |
| PTAB_comb_bsd_top | 1 | 1 | front_end/fifo/PTAB_comb/PTAB_comb_top.v:53 |
| fetch_address_FIFO_comb_top | 1 | 1 | front_end/fifo/fetch_address_FIFO_comb/fetch_address_FIFO_comb_top.v:8 |
| fetch_address_FIFO_comb_bsd_top | 1 | 1 | front_end/fifo/fetch_address_FIFO_comb/fetch_address_FIFO_comb_top.v:54 |
| front2back_FIFO_comb_top | 1 | 1 | front_end/fifo/front2back_FIFO_comb/front2back_FIFO_comb_top.v:8 |
| front2back_FIFO_comb_bsd_top | 1 | 1 | front_end/fifo/front2back_FIFO_comb/front2back_FIFO_comb_top.v:54 |
| instruction_FIFO_comb_top | 1 | 1 | front_end/fifo/instruction_FIFO_comb/instruction_FIFO_comb_top.v:8 |
| instruction_FIFO_comb_bsd_top | 1 | 1 | front_end/fifo/instruction_FIFO_comb/instruction_FIFO_comb_top.v:54 |
| front_top | 44 | 27 | front_end/front_top.v:7 |
| front_bpu_control_comb_top | 1 | 1 | front_end/front_top_glue/front_bpu_control_comb/front_bpu_control_comb_top.v:8 |
| front_bpu_control_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_bpu_control_comb/front_bpu_control_comb_top.v:77 |
| front_checker_input_comb_top | 1 | 1 | front_end/front_top_glue/front_checker_input_comb/front_checker_input_comb_top.v:8 |
| front_checker_input_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_checker_input_comb/front_checker_input_comb_top.v:54 |
| front_front2back_write_comb_top | 1 | 1 | front_end/front_top_glue/front_front2back_write_comb/front_front2back_write_comb_top.v:8 |
| front_front2back_write_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_front2back_write_comb/front_front2back_write_comb_top.v:65 |
| front_global_control_comb_top | 1 | 1 | front_end/front_top_glue/front_global_control_comb/front_global_control_comb_top.v:8 |
| front_global_control_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_global_control_comb/front_global_control_comb_top.v:67 |
| front_output_comb_top | 1 | 1 | front_end/front_top_glue/front_output_comb/front_output_comb_top.v:8 |
| front_output_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_output_comb/front_output_comb_top.v:56 |
| front_ptab_write_comb_top | 1 | 1 | front_end/front_top_glue/front_ptab_write_comb/front_ptab_write_comb_top.v:8 |
| front_ptab_write_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_ptab_write_comb/front_ptab_write_comb_top.v:59 |
| front_read_enable_comb_top | 1 | 1 | front_end/front_top_glue/front_read_enable_comb/front_read_enable_comb_top.v:8 |
| front_read_enable_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_read_enable_comb/front_read_enable_comb_top.v:87 |
| front_read_stage_input_comb_top | 1 | 1 | front_end/front_top_glue/front_read_stage_input_comb/front_read_stage_input_comb_top.v:8 |
| front_read_stage_input_comb_bsd_top | 1 | 1 | front_end/front_top_glue/front_read_stage_input_comb/front_read_stage_input_comb_top.v:99 |
| predecode_comb_top | 1 | 1 | front_end/predecode/predecode_comb/predecode_comb_top.v:8 |
| predecode_comb_bsd_top | 1 | 1 | front_end/predecode/predecode_comb/predecode_comb_top.v:55 |
| predecode_checker_comb_top | 1 | 1 | front_end/predecode_checker/predecode_checker_comb/predecode_checker_comb_top.v:8 |
| predecode_checker_comb_bsd_top | 1 | 1 | front_end/predecode_checker/predecode_checker_comb/predecode_checker_comb_top.v:50 |
| top_top | 44 | 28 | top_top.v:14 |

### `bpu_hist_comb_top`

源码位置：`front_end/bpu/bpu_hist_comb/bpu_hist_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BpuHistCombIn-1:0] | bsd_pi |
| 输出 | [W_BpuHistCombOut-1:0] | bsd_po |

### `bpu_post_read_req_comb_top`

源码位置：`front_end/bpu/bpu_post_read_req_comb/bpu_post_read_req_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BpuPostReadReqCombIn-1:0] | bsd_pi |
| 输出 | [W_BpuPostReadReqCombOut-1:0] | bsd_po |

### `bpu_pre_read_req_comb_top`

源码位置：`front_end/bpu/bpu_pre_read_req_comb/bpu_pre_read_req_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BpuPreReadReqCombIn-1:0] | bsd_pi |
| 输出 | [W_BpuPreReadReqCombOut-1:0] | bsd_po |

### `bpu_predict_main_comb_top`

源码位置：`front_end/bpu/bpu_predict_main_comb/bpu_predict_main_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BpuPredictMainCombIn-1:0] | bsd_pi |
| 输出 | [W_BpuPredictMainCombOut-1:0] | bsd_po |

### `bpu_queue_comb_top`

源码位置：`front_end/bpu/bpu_queue_comb/bpu_queue_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BpuQueueCombIn-1:0] | bsd_pi |
| 输出 | [W_BpuQueueCombOut-1:0] | bsd_po |

### `bpu_submodule_bind_comb_top`

源码位置：`front_end/bpu/bpu_submodule_bind_comb/bpu_submodule_bind_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BpuSubmoduleBindCombIn-1:0] | bsd_pi |
| 输出 | [W_BpuSubmoduleBindCombOut-1:0] | bsd_po |

### `bpu_top`

源码位置：`front_end/bpu/bpu_top.v:5`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BpuIn-1:0] | bpu_in |
| 输出 | [W_BpuOut-1:0] | bpu_out |

### `tage_comb_top`

源码位置：`front_end/bpu/dir_predictor/tage_comb/tage_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_TageCombIn-1:0] | bsd_pi |
| 输出 | [W_TageCombOut-1:0] | bsd_po |

### `tage_pre_read_comb_top`

源码位置：`front_end/bpu/dir_predictor/tage_pre_read_comb/tage_pre_read_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_TagePreReadCombIn-1:0] | bsd_pi |
| 输出 | [W_TagePreReadCombOut-1:0] | bsd_po |

### `btb_comb_top`

源码位置：`front_end/bpu/target_predictor/btb_comb/btb_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BtbCombIn-1:0] | bsd_pi |
| 输出 | [W_BtbCombOut-1:0] | bsd_po |

### `btb_post_read_req_comb_top`

源码位置：`front_end/bpu/target_predictor/btb_post_read_req_comb/btb_post_read_req_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BtbPostReadReqCombIn-1:0] | bsd_pi |
| 输出 | [W_BtbPostReadReqCombOut-1:0] | bsd_po |

### `btb_pre_read_comb_top`

源码位置：`front_end/bpu/target_predictor/btb_pre_read_comb/btb_pre_read_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_BtbPreReadCombIn-1:0] | bsd_pi |
| 输出 | [W_BtbPreReadCombOut-1:0] | bsd_po |

### `type_pred_comb_top`

源码位置：`front_end/bpu/type_predictor/type_pred_comb/type_pred_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_TypePredCombIn-1:0] | bsd_pi |
| 输出 | [W_TypePredCombOut-1:0] | bsd_po |

### `type_predictor_pre_read_comb_top`

源码位置：`front_end/bpu/type_predictor/type_predictor_pre_read_comb/type_predictor_pre_read_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_TypePredictorPreReadCombIn-1:0] | bsd_pi |
| 输出 | [W_TypePredictorPreReadCombOut-1:0] | bsd_po |

### `PTAB_comb_top`

源码位置：`front_end/fifo/PTAB_comb/PTAB_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_PtabCombIn-1:0] | bsd_pi |
| 输出 | [W_PtabCombOut-1:0] | bsd_po |

### `fetch_address_FIFO_comb_top`

源码位置：`front_end/fifo/fetch_address_FIFO_comb/fetch_address_FIFO_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FetchAddressFifoCombIn-1:0] | bsd_pi |
| 输出 | [W_FetchAddressFifoCombOut-1:0] | bsd_po |

### `front2back_FIFO_comb_top`

源码位置：`front_end/fifo/front2back_FIFO_comb/front2back_FIFO_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_Front2backFifoCombIn-1:0] | bsd_pi |
| 输出 | [W_Front2backFifoCombOut-1:0] | bsd_po |

### `instruction_FIFO_comb_top`

源码位置：`front_end/fifo/instruction_FIFO_comb/instruction_FIFO_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_InstructionFifoCombIn-1:0] | bsd_pi |
| 输出 | [W_InstructionFifoCombOut-1:0] | bsd_po |

### `front_top`

源码位置：`front_end/front_top.v:7`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | 1 | clk |
| 输入 | 1 | rst_n |
| 输入 | 1 | reset |
| 输入 | 1 | refetch |
| 输入 | 1 | itlb_flush |
| 输入 | 1 | fence_i |
| 输入 | [PC_BITS-1:0] | refetch_address |
| 输入 | 1 | FIFO_read_enable |
| 输入 | [COMMIT_WIDTH-1:0] | back2front_valid |
| 输入 | [COMMIT_WIDTH*PC_BITS-1:0] | predict_base_pc |
| 输入 | [COMMIT_WIDTH-1:0] | predict_dir |
| 输入 | [COMMIT_WIDTH-1:0] | actual_dir |
| 输入 | [COMMIT_WIDTH*BR_TYPE_BITS-1:0] | actual_br_type |
| 输入 | [COMMIT_WIDTH*PC_BITS-1:0] | actual_target |
| 输入 | [COMMIT_WIDTH-1:0] | alt_pred |
| 输入 | [COMMIT_WIDTH*PCPN_BITS-1:0] | altpcpn |
| 输入 | [COMMIT_WIDTH*PCPN_BITS-1:0] | pcpn |
| 输入 | [COMMIT_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0] | tage_idx |
| 输入 | [COMMIT_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0] | tage_tag |
| 输入 | [COMMIT_WIDTH-1:0] | sc_used |
| 输入 | [COMMIT_WIDTH-1:0] | sc_pred |
| 输入 | [COMMIT_WIDTH*BPU_SCL_META_SUM_BITS-1:0] | sc_sum |
| 输入 | [COMMIT_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS-1:0] | sc_idx |
| 输入 | [COMMIT_WIDTH-1:0] | loop_used |
| 输入 | [COMMIT_WIDTH-1:0] | loop_hit |
| 输入 | [COMMIT_WIDTH-1:0] | loop_pred |
| 输入 | [COMMIT_WIDTH*BPU_LOOP_META_IDX_BITS-1:0] | loop_idx |
| 输入 | [COMMIT_WIDTH*BPU_LOOP_META_TAG_BITS-1:0] | loop_tag |
| 输入 | [31:0] | csr_status_sstatus |
| 输入 | [31:0] | csr_status_mstatus |
| 输入 | [31:0] | csr_status_satp |
| 输入 | [PRIVILEGE_BITS-1:0] | csr_status_privilege |
| 输入 | 1 | icache_read_ready |
| 输入 | 1 | icache_read_complete |
| 输入 | 1 | icache_read_ready_2 |
| 输入 | 1 | icache_read_complete_2 |
| 输入 | [FETCH_WIDTH*INST_BITS-1:0] | icache_fetch_group |
| 输入 | [FETCH_WIDTH-1:0] | icache_page_fault_inst |
| 输入 | [FETCH_WIDTH-1:0] | icache_inst_valid |
| 输入 | [PC_BITS-1:0] | icache_fetch_pc |
| 输入 | [FETCH_WIDTH*INST_BITS-1:0] | icache_fetch_group_2 |
| 输入 | [FETCH_WIDTH-1:0] | icache_page_fault_inst_2 |
| 输入 | [FETCH_WIDTH-1:0] | icache_inst_valid_2 |
| 输入 | [PC_BITS-1:0] | icache_fetch_pc_2 |
| 输出 | 1 | icache_read_valid |
| 输出 | [PC_BITS-1:0] | fetch_address |
| 输出 | 1 | icache_read_valid_2 |
| 输出 | [PC_BITS-1:0] | fetch_address_2 |
| 输出 | 1 | icache_invalidate_req |
| 输出 | 1 | icache_run_comb_only |
| 输出 | 1 | FIFO_valid |
| 输出 | [FETCH_WIDTH*PC_BITS-1:0] | pc |
| 输出 | [FETCH_WIDTH*INST_BITS-1:0] | instructions |
| 输出 | [FETCH_WIDTH-1:0] | out_predict_dir |
| 输出 | [PC_BITS-1:0] | predict_next_fetch_address |
| 输出 | [FETCH_WIDTH-1:0] | out_alt_pred |
| 输出 | [FETCH_WIDTH*PCPN_BITS-1:0] | out_altpcpn |
| 输出 | [FETCH_WIDTH*PCPN_BITS-1:0] | out_pcpn |
| 输出 | [FETCH_WIDTH-1:0] | page_fault_inst |
| 输出 | [FETCH_WIDTH-1:0] | inst_valid |
| 输出 | [FETCH_WIDTH*TN_MAX*TAGE_IDX_BITS-1:0] | out_tage_idx |
| 输出 | [FETCH_WIDTH*TN_MAX*TAGE_TAG_BITS-1:0] | out_tage_tag |
| 输出 | [FETCH_WIDTH-1:0] | out_sc_used |
| 输出 | [FETCH_WIDTH-1:0] | out_sc_pred |
| 输出 | [FETCH_WIDTH*BPU_SCL_META_SUM_BITS-1:0] | out_sc_sum |
| 输出 | [FETCH_WIDTH*BPU_SCL_META_NTABLE*BPU_SCL_META_IDX_BITS-1:0] | out_sc_idx |
| 输出 | [FETCH_WIDTH-1:0] | out_loop_used |
| 输出 | [FETCH_WIDTH-1:0] | out_loop_hit |
| 输出 | [FETCH_WIDTH-1:0] | out_loop_pred |
| 输出 | [FETCH_WIDTH*BPU_LOOP_META_IDX_BITS-1:0] | out_loop_idx |
| 输出 | [FETCH_WIDTH*BPU_LOOP_META_TAG_BITS-1:0] | out_loop_tag |

### `front_bpu_control_comb_top`

源码位置：`front_end/front_top_glue/front_bpu_control_comb/front_bpu_control_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontBpuControlCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontBpuControlCombOut-1:0] | bsd_po |

### `front_checker_input_comb_top`

源码位置：`front_end/front_top_glue/front_checker_input_comb/front_checker_input_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontCheckerInputCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontCheckerInputCombOut-1:0] | bsd_po |

### `front_front2back_write_comb_top`

源码位置：`front_end/front_top_glue/front_front2back_write_comb/front_front2back_write_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontFront2backWriteCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontFront2backWriteCombOut-1:0] | bsd_po |

### `front_global_control_comb_top`

源码位置：`front_end/front_top_glue/front_global_control_comb/front_global_control_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontGlobalControlCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontGlobalControlCombOut-1:0] | bsd_po |

### `front_output_comb_top`

源码位置：`front_end/front_top_glue/front_output_comb/front_output_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontOutputCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontOutputCombOut-1:0] | bsd_po |

### `front_ptab_write_comb_top`

源码位置：`front_end/front_top_glue/front_ptab_write_comb/front_ptab_write_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontPtabWriteCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontPtabWriteCombOut-1:0] | bsd_po |

### `front_read_enable_comb_top`

源码位置：`front_end/front_top_glue/front_read_enable_comb/front_read_enable_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontReadEnableCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontReadEnableCombOut-1:0] | bsd_po |

### `front_read_stage_input_comb_top`

源码位置：`front_end/front_top_glue/front_read_stage_input_comb/front_read_stage_input_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_FrontReadStageInputCombIn-1:0] | bsd_pi |
| 输出 | [W_FrontReadStageInputCombOut-1:0] | bsd_po |

### `predecode_comb_top`

源码位置：`front_end/predecode/predecode_comb/predecode_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_PredecodeCombIn-1:0] | bsd_pi |
| 输出 | [W_PredecodeCombOut-1:0] | bsd_po |

### `predecode_checker_comb_top`

源码位置：`front_end/predecode_checker/predecode_checker_comb/predecode_checker_comb_top.v:8`

| 方向 | 位宽 | 端口名 |
| --- | --- | --- |
| 输入 | [W_PredecodeCheckerCombIn-1:0] | bsd_pi |
| 输出 | [W_PredecodeCheckerCombOut-1:0] | bsd_po |

## 如何喂给 Codex

当模拟器更新后，先重新运行本脚本，再把 `codex_quick_context.md` 的内容交给 Codex。这样 Codex 能先知道新的配置、接口结构体、入口函数和当前 RTL 端口，再继续更新前端/后端训练包。

```powershell
python top/tools/scan_simulator_interfaces.py simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0
```
