# Codex 快速上下文：模拟器接口

模拟器目录：`simulator-front`
RTL/训练包目录：`top`

## 生效配置
- `FETCH_WIDTH` = `16`，来源：`include/config.h:57`
- `DECODE_WIDTH` = `8`，来源：`include/config.h:58`
- `COMMIT_WIDTH` = `DECODE_WIDTH = 8`，来源：`include/config.h:63`
- `PRF_NUM` = `2048`，来源：`include/config.h:320`
- `ROB_NUM` = `2048`，来源：`include/config.h:326`
- `STQ_SIZE` = `512`，来源：`include/config.h:438`
- `LDQ_SIZE` = `512`，来源：`include/config.h:439`
- `FTQ_SIZE` = `256`，来源：`include/config.h:334`
- `PRF_IDX_WIDTH` = `clog2(PRF_NUM) = 11`，来源：`include/config.h:619`
- `ROB_IDX_WIDTH` = `clog2(ROB_NUM) = 11`，来源：`include/config.h:620`
- `STQ_IDX_WIDTH` = `clog2(STQ_SIZE) = 9`，来源：`include/config.h:621`
- `LDQ_IDX_WIDTH` = `clog2(LDQ_SIZE) = 9`，来源：`include/config.h:622`
- `FTQ_IDX_WIDTH` = `clog2(FTQ_SIZE) = 8`，来源：`include/config.h:626`
- `TOTAL_FU_COUNT` = `calculate_total_fu_count()`，来源：`include/config.h:495`
- `LSU_LOAD_WB_WIDTH` = `LSU_LDU_COUNT`，来源：`include/config.h:448`

## 重要入口函数
- `FrontTop::step_bpu()`，位置：`front-end/FrontTop.cpp:36`
- `FrontTop::step_oracle()`，位置：`front-end/FrontTop.cpp:41`
- `front_top(struct front_top_in *in, struct front_top_out *out)`，位置：`front-end/front_module.h:137`
- `front_comb_calc(const struct front_top_in &inp, const FrontReadData &rd, struct front_top_out &out, FrontUpdateRequest &req)`，位置：`front-end/front_top.cpp:1002`
- `front_seq_read(const struct front_top_in &inp, FrontReadData &rd)`，位置：`front-end/front_top.cpp:1996`
- `front_seq_write(const struct front_top_in &inp, const FrontUpdateRequest &req, bool reset)`，位置：`front-end/front_top.cpp:2033`
- `front_top(struct front_top_in *in, struct front_top_out *out)`，位置：`front-end/front_top.cpp:2067`
- `step_bpu()`，位置：`include/FrontTop.h:22`
- `step_oracle()`，位置：`include/FrontTop.h:23`
- `front_cycle()`，位置：`include/SimCpu.h:39`
- `SimCpu::front_cycle()`，位置：`rv_simu_mmu_v2.cpp:639`

## 需要核对的接口结构体
- `front_top_in`，位置：`front-end/front_IO.h:11`：reset, back2front_valid[COMMIT_WIDTH], refetch, itlb_flush, fence_i, refetch_address, predict_base_pc[COMMIT_WIDTH], predict_dir[COMMIT_WIDTH], actual_dir[COMMIT_WIDTH], actual_br_type[COMMIT_WIDTH], actual_target[COMMIT_WIDTH], alt_pred[COMMIT_WIDTH], altpcpn[COMMIT_WIDTH], pcpn[COMMIT_WIDTH], tage_idx[COMMIT_WIDTH][4], tage_tag[COMMIT_WIDTH][4], sc_used[COMMIT_WIDTH], sc_pred[COMMIT_WIDTH], sc_sum[COMMIT_WIDTH], sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE], loop_used[COMMIT_WIDTH], loop_hit[COMMIT_WIDTH], loop_pred[COMMIT_WIDTH], loop_idx[COMMIT_WIDTH], loop_tag[COMMIT_WIDTH], FIFO_read_enable, csr_status
- `front_top_out`，位置：`front-end/front_IO.h:42`：FIFO_valid, pc[FETCH_WIDTH], instructions[FETCH_WIDTH], predict_dir[FETCH_WIDTH], predict_next_fetch_address, alt_pred[FETCH_WIDTH], altpcpn[FETCH_WIDTH], pcpn[FETCH_WIDTH], page_fault_inst[FETCH_WIDTH], inst_valid[FETCH_WIDTH], tage_idx[FETCH_WIDTH][4], tage_tag[FETCH_WIDTH][4], sc_used[FETCH_WIDTH], sc_pred[FETCH_WIDTH], sc_sum[FETCH_WIDTH], sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE], loop_used[FETCH_WIDTH], loop_hit[FETCH_WIDTH], loop_pred[FETCH_WIDTH], loop_idx[FETCH_WIDTH], loop_tag[FETCH_WIDTH]
- `BPU_in`，位置：`front-end/front_IO.h:67`：reset, back2front_valid[COMMIT_WIDTH], refetch, refetch_address, predict_base_pc[COMMIT_WIDTH], predict_dir[COMMIT_WIDTH], actual_dir[COMMIT_WIDTH], actual_br_type[COMMIT_WIDTH], actual_target[COMMIT_WIDTH], alt_pred[COMMIT_WIDTH], altpcpn[COMMIT_WIDTH], pcpn[COMMIT_WIDTH], tage_idx[COMMIT_WIDTH][4], tage_tag[COMMIT_WIDTH][4], sc_used[COMMIT_WIDTH], sc_pred[COMMIT_WIDTH], sc_sum[COMMIT_WIDTH], sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE], loop_used[COMMIT_WIDTH], loop_hit[COMMIT_WIDTH], loop_pred[COMMIT_WIDTH], loop_idx[COMMIT_WIDTH], loop_tag[COMMIT_WIDTH], icache_read_ready
- `BPU_out`，位置：`front-end/front_IO.h:97`：icache_read_valid, fetch_address, PTAB_write_enable, predict_dir[FETCH_WIDTH], predict_next_fetch_address, predict_base_pc[FETCH_WIDTH], alt_pred[FETCH_WIDTH], altpcpn[FETCH_WIDTH], pcpn[FETCH_WIDTH], tage_idx[FETCH_WIDTH][4], tage_tag[FETCH_WIDTH][4], sc_used[FETCH_WIDTH], sc_pred[FETCH_WIDTH], sc_sum[FETCH_WIDTH], sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE], loop_used[FETCH_WIDTH], loop_hit[FETCH_WIDTH], loop_pred[FETCH_WIDTH], loop_idx[FETCH_WIDTH], loop_tag[FETCH_WIDTH], two_ahead_valid, two_ahead_target, mini_flush_req, mini_flush_correct, mini_flush_target
- `FrontPreIO`，位置：`back-end/include/IO.h:108`：inst[FETCH_WIDTH], pc[FETCH_WIDTH], valid[FETCH_WIDTH], predict_dir[FETCH_WIDTH], alt_pred[FETCH_WIDTH], altpcpn[FETCH_WIDTH], pcpn[FETCH_WIDTH], predict_next_fetch_address[FETCH_WIDTH], tage_idx[FETCH_WIDTH][4], tage_tag[FETCH_WIDTH][4], sc_used[FETCH_WIDTH], sc_pred[FETCH_WIDTH], sc_sum[FETCH_WIDTH], sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE], loop_used[FETCH_WIDTH], loop_hit[FETCH_WIDTH], loop_pred[FETCH_WIDTH], loop_idx[FETCH_WIDTH], loop_tag[FETCH_WIDTH], page_fault_inst[FETCH_WIDTH]
- `PreFrontIO`，位置：`back-end/include/IO.h:96`：fire[FETCH_WIDTH], ready
- `CsrStatusIO`，位置：`back-end/include/IO.h:997`：sstatus, mstatus, satp, privilege
- `icache_in`，位置：`front-end/front_IO.h:129`：reset, refetch, itlb_flush, fence_i, invalidate_req, icache_read_valid, fetch_address, icache_read_valid_2, fetch_address_2, csr_status, run_comb_only
- `icache_out`，位置：`front-end/front_IO.h:145`：icache_read_ready, icache_read_complete, icache_read_ready_2, icache_read_complete_2, perf_req_fire, perf_req_blocked, perf_resp_fire, perf_miss_event, perf_miss_busy, perf_outstanding_req, perf_itlb_hit, perf_itlb_miss, perf_itlb_fault, perf_itlb_retry, perf_itlb_retry_other_walk, perf_itlb_retry_walk_req_blocked, perf_itlb_retry_wait_walk_resp, perf_itlb_retry_local_walker_busy, fetch_group[FETCH_WIDTH], page_fault_inst[FETCH_WIDTH], inst_valid[FETCH_WIDTH], fetch_group_2[FETCH_WIDTH], page_fault_inst_2[FETCH_WIDTH], inst_valid_2[FETCH_WIDTH], fetch_pc, fetch_pc_2
- `instruction_FIFO_in`，位置：`front-end/front_IO.h:177`：reset, refetch, write_enable, fetch_group[FETCH_WIDTH], pc[FETCH_WIDTH], page_fault_inst[FETCH_WIDTH], inst_valid[FETCH_WIDTH], read_enable, predecode_type[FETCH_WIDTH], predecode_target_address[FETCH_WIDTH], seq_next_pc
- `instruction_FIFO_out`，位置：`front-end/front_IO.h:194`：full, empty, FIFO_valid, instructions[FETCH_WIDTH], pc[FETCH_WIDTH], page_fault_inst[FETCH_WIDTH], inst_valid[FETCH_WIDTH], predecode_type[FETCH_WIDTH], predecode_target_address[FETCH_WIDTH], seq_next_pc
- `PTAB_in`，位置：`front-end/front_IO.h:208`：reset, refetch, write_enable, predict_dir[FETCH_WIDTH], predict_next_fetch_address, predict_base_pc[FETCH_WIDTH], alt_pred[FETCH_WIDTH], altpcpn[FETCH_WIDTH], pcpn[FETCH_WIDTH], tage_idx[FETCH_WIDTH][4], tage_tag[FETCH_WIDTH][4], sc_used[FETCH_WIDTH], sc_pred[FETCH_WIDTH], sc_sum[FETCH_WIDTH], sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE], loop_used[FETCH_WIDTH], loop_hit[FETCH_WIDTH], loop_pred[FETCH_WIDTH], loop_idx[FETCH_WIDTH], loop_tag[FETCH_WIDTH], read_enable, need_mini_flush
- `PTAB_out`，位置：`front-end/front_IO.h:237`：dummy_entry, full, empty, predict_dir[FETCH_WIDTH], predict_next_fetch_address, predict_base_pc[FETCH_WIDTH], alt_pred[FETCH_WIDTH], altpcpn[FETCH_WIDTH], pcpn[FETCH_WIDTH], tage_idx[FETCH_WIDTH][4], tage_tag[FETCH_WIDTH][4], sc_used[FETCH_WIDTH], sc_pred[FETCH_WIDTH], sc_sum[FETCH_WIDTH], sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE], loop_used[FETCH_WIDTH], loop_hit[FETCH_WIDTH], loop_pred[FETCH_WIDTH], loop_idx[FETCH_WIDTH], loop_tag[FETCH_WIDTH]
- `front2back_FIFO_in`，位置：`front-end/front_IO.h:263`：reset, refetch, write_enable, read_enable, fetch_group[FETCH_WIDTH], page_fault_inst[FETCH_WIDTH], inst_valid[FETCH_WIDTH], predict_dir_corrected[FETCH_WIDTH], predict_next_fetch_address_corrected, predict_base_pc[FETCH_WIDTH], alt_pred[FETCH_WIDTH], altpcpn[FETCH_WIDTH], pcpn[FETCH_WIDTH], tage_idx[FETCH_WIDTH][4], tage_tag[FETCH_WIDTH][4], sc_used[FETCH_WIDTH], sc_pred[FETCH_WIDTH], sc_sum[FETCH_WIDTH], sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE], loop_used[FETCH_WIDTH], loop_hit[FETCH_WIDTH], loop_pred[FETCH_WIDTH], loop_idx[FETCH_WIDTH], loop_tag[FETCH_WIDTH]
- `front2back_FIFO_out`，位置：`front-end/front_IO.h:292`：full, empty, front2back_FIFO_valid, fetch_group[FETCH_WIDTH], page_fault_inst[FETCH_WIDTH], inst_valid[FETCH_WIDTH], predict_dir_corrected[FETCH_WIDTH], predict_next_fetch_address_corrected, predict_base_pc[FETCH_WIDTH], alt_pred[FETCH_WIDTH], altpcpn[FETCH_WIDTH], pcpn[FETCH_WIDTH], tage_idx[FETCH_WIDTH][4], tage_tag[FETCH_WIDTH][4], sc_used[FETCH_WIDTH], sc_pred[FETCH_WIDTH], sc_sum[FETCH_WIDTH], sc_idx[FETCH_WIDTH][BPU_SCL_META_NTABLE], loop_used[FETCH_WIDTH], loop_hit[FETCH_WIDTH], loop_pred[FETCH_WIDTH], loop_idx[FETCH_WIDTH], loop_tag[FETCH_WIDTH]
- `fetch_address_FIFO_in`，位置：`front-end/front_IO.h:319`：reset, refetch, read_enable, write_enable, fetch_address
- `fetch_address_FIFO_out`，位置：`front-end/front_IO.h:327`：full, empty, read_valid, fetch_address
- `FetchAddrCombIn`，位置：`front-end/train_IO.h:12`：inp, rd
- `FetchAddrCombOut`，位置：`front-end/train_IO.h:17`：out_regs, clear_fifo, push_en, push_data, pop_en
- `InstructionCombIn`，位置：`front-end/train_IO.h:25`：inp, rd
- `InstructionCombOut`，位置：`front-end/train_IO.h:30`：out_regs, clear_fifo, push_en, push_entry, pop_en
- `PtabCombIn`，位置：`front-end/train_IO.h:38`：inp, rd
- `PtabCombOut`，位置：`front-end/train_IO.h:43`：out_regs, clear_ptab, push_write_en, push_write_entry, push_dummy_en, push_dummy_entry, pop_en
- `Front2BackCombIn`，位置：`front-end/train_IO.h:53`：inp, rd
- `Front2BackCombOut`，位置：`front-end/train_IO.h:58`：out_regs, clear_fifo, push_en, push_entry, pop_en
- `FrontUpdateRequest`，位置：`front-end/train_IO.h:246`：out_regs, bpu_seq_txn, front_state
- `FrontBpuInputCombIn`，位置：`front-end/train_IO.h:256`：bpu_seed, do_refetch, refetch_addr, icache_ready
- `FrontBpuInputCombOut`，位置：`front-end/train_IO.h:263`：bpu_in
- `FrontGlobalControlCombIn`，位置：`front-end/train_IO.h:267`：reset, backend_refetch, backend_refetch_address, predecode_refetch_snapshot, predecode_refetch_address_snapshot
- `FrontGlobalControlCombOut`，位置：`front-end/train_IO.h:275`：global_reset, global_refetch, refetch_address

## 当前 RTL 模块
- `bpu_hist_comb_top`，位置：`front_end/bpu/bpu_hist_comb/bpu_hist_comb_top.v:78`：1 个输入，1 个输出
- `bpu_post_read_req_comb_top`，位置：`front_end/bpu/bpu_post_read_req_comb/bpu_post_read_req_comb_top.v:71`：1 个输入，1 个输出
- `bpu_pre_read_req_comb_top`，位置：`front_end/bpu/bpu_pre_read_req_comb/bpu_pre_read_req_comb_top.v:68`：1 个输入，1 个输出
- `bpu_predict_main_comb_top`，位置：`front_end/bpu/bpu_predict_main_comb/bpu_predict_main_comb_top.v:79`：1 个输入，1 个输出
- `bpu_queue_comb_top`，位置：`front_end/bpu/bpu_queue_comb/bpu_queue_comb_top.v:79`：1 个输入，1 个输出
- `bpu_submodule_bind_comb_top`，位置：`front_end/bpu/bpu_submodule_bind_comb/bpu_submodule_bind_comb_top.v:52`：1 个输入，1 个输出
- `tage_comb_top`，位置：`front_end/bpu/dir_predictor/tage_comb/tage_comb_top.v:52`：1 个输入，1 个输出
- `tage_pre_read_comb_top`，位置：`front_end/bpu/dir_predictor/tage_pre_read_comb/tage_pre_read_comb_top.v:56`：1 个输入，1 个输出
- `btb_comb_top`，位置：`front_end/bpu/target_predictor/btb_comb/btb_comb_top.v:52`：1 个输入，1 个输出
- `btb_post_read_req_comb_top`，位置：`front_end/bpu/target_predictor/btb_post_read_req_comb/btb_post_read_req_comb_top.v:54`：1 个输入，1 个输出
- `btb_pre_read_comb_top`，位置：`front_end/bpu/target_predictor/btb_pre_read_comb/btb_pre_read_comb_top.v:50`：1 个输入，1 个输出
- `type_pred_comb_top`，位置：`front_end/bpu/type_predictor/type_pred_comb/type_pred_comb_top.v:54`：1 个输入，1 个输出
- `type_predictor_pre_read_comb_top`，位置：`front_end/bpu/type_predictor/type_predictor_pre_read_comb/type_predictor_pre_read_comb_top.v:53`：1 个输入，1 个输出
- `PTAB_comb_top`，位置：`front_end/fifo/PTAB_comb/PTAB_comb_top.v:32`：2 个输入，1 个输出
- `fetch_address_FIFO_comb_top`，位置：`front_end/fifo/fetch_address_FIFO_comb/fetch_address_FIFO_comb_top.v:30`：2 个输入，1 个输出
- `front2back_FIFO_comb_top`，位置：`front_end/fifo/front2back_FIFO_comb/front2back_FIFO_comb_top.v:30`：2 个输入，1 个输出
- `instruction_FIFO_comb_top`，位置：`front_end/fifo/instruction_FIFO_comb/instruction_FIFO_comb_top.v:30`：2 个输入，1 个输出
- `front_top`，位置：`front_end/front_top.v:7`：44 个输入，35 个输出
- `front_bpu_control_comb_top`，位置：`front_end/front_top_glue/front_bpu_control_comb/front_bpu_control_comb_top.v:58`：1 个输入，1 个输出
- `front_checker_input_comb_top`，位置：`front_end/front_top_glue/front_checker_input_comb/front_checker_input_comb_top.v:50`：1 个输入，1 个输出
- `front_front2back_write_comb_top`，位置：`front_end/front_top_glue/front_front2back_write_comb/front_front2back_write_comb_top.v:55`：1 个输入，1 个输出
- `front_global_control_comb_top`，位置：`front_end/front_top_glue/front_global_control_comb/front_global_control_comb_top.v:50`：1 个输入，1 个输出
- `front_output_comb_top`，位置：`front_end/front_top_glue/front_output_comb/front_output_comb_top.v:51`：1 个输入，1 个输出
- `front_ptab_write_comb_top`，位置：`front_end/front_top_glue/front_ptab_write_comb/front_ptab_write_comb_top.v:51`：1 个输入，1 个输出
- `front_read_enable_comb_top`，位置：`front_end/front_top_glue/front_read_enable_comb/front_read_enable_comb_top.v:57`：1 个输入，1 个输出
- `front_read_stage_input_comb_top`，位置：`front_end/front_top_glue/front_read_stage_input_comb/front_read_stage_input_comb_top.v:61`：1 个输入，1 个输出
- `predecode_comb_top`，位置：`front_end/predecode/predecode_comb/predecode_comb_top.v:46`：1 个输入，1 个输出
- `predecode_checker_comb_top`，位置：`front_end/predecode_checker/predecode_checker_comb/predecode_checker_comb_top.v:49`：1 个输入，1 个输出

## 更新流程
1. 先核对配置宽度是否和 RTL 参数一致。
2. 再核对 C++ 接口结构体是否和 `front_top.v`、`back_top.v`、comb wrapper 端口一致。
3. 上层 `front_top.v`、`bpu_top.v` 使用具名变量端口连接；`*_comb_top` 内部把变量拼成 `pi/po`，最后的 `*_bsd_top` 只保留 `.pi(pi)`、`.po(po)`。
4. 每次模拟器更新后都重新生成本上下文。
