// =============================================================================
// 前端 27 个正式 comb 端口位宽集中自查
//
// 生成方式：
//   python top/tools/scan_frontend_comb_ports.py simulator-front --annotate-rtl top/front_end
//
// 说明：
//   1. 本文件只做端口宽度和字段来源审阅，不加入 filelist.f，不参与综合。
//   2. 每个 comb 的分散注释仍保留在对应 *_comb_top.v 文件中。
//   3. 端口位宽来源为 simulator-front 默认 large 配置。
// =============================================================================

// 01/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：fetch_address_FIFO_comb
// 来源：train_IO.h / fifo/fetch_address_FIFO.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FetchAddrCombIn(75 bit) -> FetchAddrCombOut(70 bit)
//
// 输入 FetchAddrCombIn = 75 bit
//   = inp 36 bit
//   + rd  39 bit
//   = 合计  75 bit
//
// 输出 FetchAddrCombOut = 70 bit
//   = out_regs   35 bit
//   + clear_fifo  1 bit
//   + push_en     1 bit
//   + push_data  32 bit
//   + pop_en      1 bit
//   = 合计         70 bit
//
// 关键结构展开：
//   inp      : fetch_address_FIFO_in        36 bit
//   rd       : fetch_address_FIFO_read_data 39 bit
//   out_regs : fetch_address_FIFO_out       35 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：fetch_address_FIFO_comb Input Bits = 75, Output Bits = 70。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 02/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：instruction_FIFO_comb
// 来源：train_IO.h / fifo/instruction_FIFO.cpp
// 配置：simulator-front 默认 large 配置
// 接口：InstructionCombIn(3275 bit) -> InstructionCombOut(3270 bit)
//
// 输入 InstructionCombIn = 3275 bit
//   = inp 1636 bit
//   + rd  1639 bit
//   = 合计  3275 bit
//
// 输出 InstructionCombOut = 3270 bit
//   = out_regs   1635 bit
//   + clear_fifo    1 bit
//   + push_en       1 bit
//   + push_entry 1632 bit
//   + pop_en        1 bit
//   = 合计         3270 bit
//
// 关键结构展开：
//   inp        : instruction_FIFO_in        1636 bit
//   rd         : instruction_FIFO_read_data 1639 bit
//   out_regs   : instruction_FIFO_out       1635 bit
//   push_entry : instruction_FIFO_entry     1632 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：instruction_FIFO_comb Input Bits = 3275, Output Bits = 3270。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 03/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：PTAB_comb
// 来源：train_IO.h / PTAB.cpp
// 配置：simulator-front 默认 large 配置
// 接口：PtabCombIn(9710 bit) -> PtabCombOut(14555 bit)
//
// 输入 PtabCombIn = 9710 bit
//   = inp 4853 bit
//   + rd  4857 bit
//   = 合计  9710 bit
//
// 输出 PtabCombOut = 14555 bit
//   = out_regs          4851 bit
//   + clear_ptab           1 bit
//   + push_write_en        1 bit
//   + push_write_entry  4850 bit
//   + push_dummy_en        1 bit
//   + push_dummy_entry  4850 bit
//   + pop_en               1 bit
//   = 合计               14555 bit
//
// 关键结构展开：
//   inp              : PTAB_in        4853 bit
//   rd               : PTAB_read_data 4857 bit
//   out_regs         : PTAB_out       4851 bit
//   push_write_entry : PTAB_entry     4850 bit
//   push_dummy_entry : PTAB_entry     4850 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：PTAB_comb Input Bits = 9710, Output Bits = 14555。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 04/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front2back_FIFO_comb
// 来源：train_IO.h / fifo/front2back_FIFO.cpp
// 配置：simulator-front 默认 large 配置
// 接口：Front2BackCombIn(10796 bit) -> Front2BackCombOut(10790 bit)
//
// 输入 Front2BackCombIn = 10796 bit
//   = inp  5396 bit
//   + rd   5400 bit
//   = 合计  10796 bit
//
// 输出 Front2BackCombOut = 10790 bit
//   = out_regs    5395 bit
//   + clear_fifo     1 bit
//   + push_en        1 bit
//   + push_entry  5392 bit
//   + pop_en         1 bit
//   = 合计         10790 bit
//
// 关键结构展开：
//   inp        : front2back_FIFO_in        5396 bit
//   rd         : front2back_FIFO_read_data 5400 bit
//   out_regs   : front2back_FIFO_out       5395 bit
//   push_entry : front2back_FIFO_entry     5392 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front2back_FIFO_comb Input Bits = 10796, Output Bits = 10790。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 05/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：predecode_comb
// 来源：train_IO.h / predecode.cpp
// 配置：simulator-front 默认 large 配置
// 接口：PredecodeCombIn(64 bit) -> PredecodeCombOut(34 bit)
//
// 输入 PredecodeCombIn = 64 bit
//   = inst 32 bit
//   + pc   32 bit
//   = 合计   64 bit
//
// 输出 PredecodeCombOut = 34 bit
//   = type            2 bit
//   + target_address 32 bit
//   = 合计             34 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：predecode_comb Input Bits = 64, Output Bits = 34。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 06/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：predecode_checker_comb
// 来源：train_IO.h / predecode_checker.cpp
// 配置：simulator-front 默认 large 配置
// 接口：PredecodeCheckerCombIn(624 bit) -> PredecodeCheckerCombOut(49 bit)
//
// 输入 PredecodeCheckerCombIn = 624 bit
//   = inp_regs 624 bit
//   = 合计       624 bit
//
// 输出 PredecodeCheckerCombOut = 49 bit
//   = predict_dir_corrected[FETCH_WIDTH]   16 bit
//   + predict_next_fetch_address_corrected 32 bit
//   + predecode_flush_enable                1 bit
//   = 合计                                   49 bit
//
// 关键结构展开：
//   inp_regs : predecode_checker_in 624 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：predecode_checker_comb Input Bits = 624, Output Bits = 49。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 07/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：type_predictor_pre_read_comb
// 来源：train_IO.h / BPU/type_predictor
// 配置：simulator-front 默认 large 配置
// 接口：TypePredPreReadCombIn(816 bit) -> TypePredPreReadCombOut(672 bit)
//
// 输入 TypePredPreReadCombIn = 816 bit
//   = pred_valid[FETCH_WIDTH]    16 bit
//   + pred_pc[FETCH_WIDTH]      512 bit
//   + upd_valid[COMMIT_WIDTH]     8 bit
//   + upd_pc[COMMIT_WIDTH]      256 bit
//   + upd_br_type[COMMIT_WIDTH]  24 bit
//   = 合计                        816 bit
//
// 输出 TypePredPreReadCombOut = 672 bit
//   = pred_req 448 bit
//   + upd_req  224 bit
//   = 合计       672 bit
//
// 关键结构展开：
//   pred_req : TypePredictor::PredReadReqCombOut 448 bit
//   upd_req  : TypePredictor::UpdReadReqCombOut  224 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：type_predictor_pre_read_comb Input Bits = 816, Output Bits = 672。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 08/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：type_pred_comb
// 来源：train_IO.h / BPU/type_predictor
// 配置：simulator-front 默认 large 配置
// 接口：TypePredCombIn(2448 bit) -> TypePredCombOut(376 bit)
//
// 输入 TypePredCombIn = 2448 bit
//   = inp       816 bit
//   + pre_read  672 bit
//   + rd        960 bit
//   = 合计       2448 bit
//
// 输出 TypePredCombOut = 376 bit
//   = out_regs  80 bit
//   + req      296 bit
//   = 合计       376 bit
//
// 关键结构展开：
//   inp      : TypePredictor::InputPayload   816 bit
//   pre_read : TypePredictor::PreReadCombOut 672 bit
//   rd       : TypePredictor::ReadData       960 bit
//   out_regs : TypePredictor::OutputPayload   80 bit
//   req      : TypePredictor::CombResult     296 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：type_pred_comb Input Bits = 2448, Output Bits = 376。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 09/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：tage_pre_read_comb
// 来源：train_IO.h / BPU/dir_predictor/TAGE_top.h
// 配置：simulator-front 默认 large 配置
// 接口：TagePreReadCombIn(2528 bit) -> TagePreReadCombOut(579 bit)
//
// 输入 TagePreReadCombIn = 2528 bit
//   = inp      1248 bit
//   + state_in 1280 bit
//   = 合计       2528 bit
//
// 输出 TagePreReadCombOut = 579 bit
//   = pred_req         262 bit
//   + upd_req          244 bit
//   + useful_reset_req  13 bit
//   + idx               60 bit
//   = 合计               579 bit
//
// 关键结构展开：
//   inp              : TAGE_TOP::InputPayload                  1248 bit
//   state_in         : TAGE_TOP::StateInput                    1280 bit
//   pred_req         : TAGE_TOP::TagePredReadReqCombOut         262 bit
//   upd_req          : TAGE_TOP::TageUpdReadReqCombOut          244 bit
//   useful_reset_req : TAGE_TOP::TageUsefulResetReadReqCombOut   13 bit
//   idx              : TAGE_TOP::IndexResult                     60 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：tage_pre_read_comb Input Bits = 2528, Output Bits = 579。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 10/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：tage_comb
// 来源：train_IO.h / BPU/dir_predictor/TAGE_top.h
// 配置：simulator-front 默认 large 配置
// 接口：TageCombIn(3329 bit) -> TageCombOut(1932 bit)
//
// 输入 TageCombIn = 3329 bit
//   = inp 1248 bit
//   + rd  2081 bit
//   = 合计  3329 bit
//
// 输出 TageCombOut = 1932 bit
//   = out_regs  272 bit
//   + req      1660 bit
//   = 合计       1932 bit
//
// 关键结构展开：
//   inp      : TAGE_TOP::InputPayload  1248 bit
//   rd       : TAGE_TOP::ReadData      2081 bit
//   out_regs : TAGE_TOP::OutputPayload  272 bit
//   req      : TAGE_TOP::CombResult    1660 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：tage_comb Input Bits = 3329, Output Bits = 1932。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 11/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：btb_pre_read_comb
// 来源：train_IO.h / BPU/target_predictor/BTB_top.h
// 配置：simulator-front 默认 large 配置
// 接口：BtbPreReadCombIn(105 bit) -> BtbPreReadCombOut(228 bit)
//
// 输入 BtbPreReadCombIn = 105 bit
//   = inp 105 bit
//   = 合计  105 bit
//
// 输出 BtbPreReadCombOut = 228 bit
//   = pred_req  85 bit
//   + upd_req  143 bit
//   = 合计       228 bit
//
// 关键结构展开：
//   inp      : BTB_TOP::InputPayload          105 bit
//   pred_req : BTB_TOP::BtbPredReadReqCombOut  85 bit
//   upd_req  : BTB_TOP::BtbUpdReadReqCombOut  143 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：btb_pre_read_comb Input Bits = 105, Output Bits = 228。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 12/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：btb_post_read_req_comb
// 来源：BPU/target_predictor/BTB_top.h
// 配置：simulator-front 默认 large 配置
// 接口：BTB_TOP::BtbPostReadReqCombIn(2264 bit) -> BTB_TOP::BtbPostReadReqCombOut(45 bit)
//
// 输入 BTB_TOP::BtbPostReadReqCombIn = 2264 bit
//   = inp  105 bit
//   + rd  2159 bit
//   = 合计  2264 bit
//
// 输出 BTB_TOP::BtbPostReadReqCombOut = 45 bit
//   = pred_tc_read_valid  1 bit
//   + pred_tc_idx        11 bit
//   + upd_next_bht_data  11 bit
//   + upd_tc_read_valid   1 bit
//   + upd_tc_write_idx   11 bit
//   + upd_tc_write_tag   10 bit
//   = 合计                 45 bit
//
// 关键结构展开：
//   inp : BTB_TOP::InputPayload  105 bit
//   rd  : BTB_TOP::ReadData     2159 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：btb_post_read_req_comb Input Bits = 2264, Output Bits = 45。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 13/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：btb_comb
// 来源：train_IO.h / BPU/target_predictor/BTB_top.h
// 配置：simulator-front 默认 large 配置
// 接口：BtbCombIn(2264 bit) -> BtbCombOut(1089 bit)
//
// 输入 BtbCombIn = 2264 bit
//   = inp  105 bit
//   + rd  2159 bit
//   = 合计  2264 bit
//
// 输出 BtbCombOut = 1089 bit
//   = out_regs   35 bit
//   + req      1054 bit
//   = 合计       1089 bit
//
// 关键结构展开：
//   inp      : BTB_TOP::InputPayload   105 bit
//   rd       : BTB_TOP::ReadData      2159 bit
//   out_regs : BTB_TOP::OutputPayload   35 bit
//   req      : BTB_TOP::CombResult    1054 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：btb_comb Input Bits = 2264, Output Bits = 1089。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 14/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_pre_read_req_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuPreReadReqCombIn(369 bit) -> BpuPreReadReqCombOut(875 bit)
//
// 输入 BpuPreReadReqCombIn = 369 bit
//   = refetch                           1 bit
//   + refetch_address                  32 bit
//   + icache_read_ready                 1 bit
//   + pc_reg_snapshot                  32 bit
//   + pc_can_send_to_icache_snapshot    1 bit
//   + q_count_snapshot[BPU_BANK_NUM]  144 bit
//   + q_rd_ptr_snapshot[BPU_BANK_NUM] 144 bit
//   + Arch_ras_count_snapshot           7 bit
//   + Spec_ras_count_snapshot           7 bit
//   = 合计                              369 bit
//
// 输出 BpuPreReadReqCombOut = 875 bit
//   = use_arch_ras_snapshot              1 bit
//   + ras_count_snapshot                 7 bit
//   + ras_has_entry_snapshot             1 bit
//   + ras_top_index                      6 bit
//   + pred_base_pc                      32 bit
//   + boundary_addr                     32 bit
//   + do_pred_on_this_pc[FETCH_WIDTH]   16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]     80 bit
//   + do_pred_for_this_pc[FETCH_WIDTH] 512 bit
//   + q_read_slot[BPU_BANK_NUM]        144 bit
//   + going_to_do_pred                   1 bit
//   + going_to_do_upd[BPU_BANK_NUM]     16 bit
//   + set_submodule_input                1 bit
//   + nlp_pred_base_re                   1 bit
//   + nlp_pred_base_idx                 12 bit
//   + nlp_train_re                       1 bit
//   + nlp_train_idx                     12 bit
//   = 合计                               875 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：bpu_pre_read_req_comb Input Bits = 369, Output Bits = 875。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 15/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_post_read_req_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuPostReadReqCombIn(7332 bit) -> BpuPostReadReqCombOut(22509 bit)
//
// 输入 BpuPostReadReqCombIn = 7332 bit
//   = refetch                             1 bit
//   + in_update_base_pc[COMMIT_WIDTH]   256 bit
//   + in_upd_valid[COMMIT_WIDTH]          8 bit
//   + in_actual_br_type[COMMIT_WIDTH]    24 bit
//   + ghr_snapshot[GHR_LENGTH]          512 bit
//   + fh_snapshot[FH_N_MAX][TN_MAX]     384 bit
//   + path_snapshot                      16 bit
//   + pred_base_pc                       32 bit
//   + going_to_do_pred                    1 bit
//   + set_submodule_input                 1 bit
//   + do_pred_on_this_pc[FETCH_WIDTH]    16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]      80 bit
//   + do_pred_for_this_pc[FETCH_WIDTH]  512 bit
//   + going_to_do_upd[BPU_BANK_NUM]      16 bit
//   + q_data[BPU_BANK_NUM]             5408 bit
//   + nlp_pred_base_entry_snapshot       65 bit
//   = 合计                               7332 bit
//
// 输出 BpuPostReadReqCombOut = 22509 bit
//   = nlp_s1_re                 1 bit
//   + nlp_s1_idx               12 bit
//   + nlp_s1_req_pc            32 bit
//   + type_in                 816 bit
//   + tage_in[BPU_BANK_NUM] 19968 bit
//   + btb_in[BPU_BANK_NUM]   1680 bit
//   = 合计                    22509 bit
//
// 关键结构展开：
//   q_data[BPU_BANK_NUM]         : BPU_TOP::ReadData::QueueEntrySnapshot  5408 bit
//   nlp_pred_base_entry_snapshot : BPU_TOP::ReadData::NlpEntrySnapshot      65 bit
//   type_in                      : TypePredictor::InputPayload             816 bit
//   tage_in[BPU_BANK_NUM]        : TAGE_TOP::InputPayload                19968 bit
//   btb_in[BPU_BANK_NUM]         : BTB_TOP::InputPayload                  1680 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：bpu_post_read_req_comb Input Bits = 7332, Output Bits = 22509。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 16/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_submodule_bind_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuSubmoduleBindCombIn(1856 bit) -> BpuSubmoduleBindCombOut(1680 bit)
//
// 输入 BpuSubmoduleBindCombIn = 1856 bit
//   = do_pred_on_this_pc[FETCH_WIDTH]   16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]     80 bit
//   + btb_in[BPU_BANK_NUM]            1680 bit
//   + type_out                          80 bit
//   = 合计                              1856 bit
//
// 输出 BpuSubmoduleBindCombOut = 1680 bit
//   = btb_in_with_type[BPU_BANK_NUM] 1680 bit
//   = 合计                             1680 bit
//
// 关键结构展开：
//   btb_in[BPU_BANK_NUM]           : BTB_TOP::InputPayload        1680 bit
//   type_out                       : TypePredictor::OutputPayload   80 bit
//   btb_in_with_type[BPU_BANK_NUM] : BTB_TOP::InputPayload        1680 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：bpu_submodule_bind_comb Input Bits = 1856, Output Bits = 1680。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 17/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_predict_main_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuPredictMainCombIn(5798 bit) -> BpuPredictMainCombOut(6502 bit)
//
// 输入 BpuPredictMainCombIn = 5798 bit
//   = refetch                              1 bit
//   + refetch_address                     32 bit
//   + pred_base_pc                        32 bit
//   + boundary_addr                       32 bit
//   + pc_can_send_to_icache_snapshot       1 bit
//   + going_to_do_pred                     1 bit
//   + do_pred_on_this_pc[FETCH_WIDTH]     16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]       80 bit
//   + do_pred_for_this_pc[FETCH_WIDTH]   512 bit
//   + ras_has_entry_snapshot               1 bit
//   + ras_top_snapshot                    32 bit
//   + saved_2ahead_prediction_snapshot    32 bit
//   + saved_2ahead_pred_valid_snapshot     1 bit
//   + saved_mini_flush_correct_snapshot    1 bit
//   + saved_mini_flush_target_snapshot    32 bit
//   + type_out                            80 bit
//   + tage_out[BPU_BANK_NUM]            4352 bit
//   + btb_out[BPU_BANK_NUM]              560 bit
//   = 合计                                5798 bit
//
// 输出 BpuPredictMainCombOut = 6502 bit
//   = out                                                 4470 bit
//   + final_pred_dir[FETCH_WIDTH]                           16 bit
//   + next_fetch_addr_calc                                  32 bit
//   + final_2_ahead_address                                 32 bit
//   + tage_calc_pred_dir_latch_next[FETCH_WIDTH]            16 bit
//   + tage_calc_altpred_latch_next[FETCH_WIDTH]             16 bit
//   + tage_calc_pcpn_latch_next[FETCH_WIDTH]                48 bit
//   + tage_calc_altpcpn_latch_next[FETCH_WIDTH]             48 bit
//   + tage_pred_calc_tags_latch_next[FETCH_WIDTH][TN_MAX]  512 bit
//   + tage_pred_calc_idxs_latch_next[FETCH_WIDTH][TN_MAX]  768 bit
//   + tage_result_valid_latch_next[FETCH_WIDTH]             16 bit
//   + btb_pred_target_latch_next[FETCH_WIDTH]              512 bit
//   + btb_result_valid_latch_next[FETCH_WIDTH]              16 bit
//   = 合计                                                  6502 bit
//
// 关键结构展开：
//   type_out               : TypePredictor::OutputPayload   80 bit
//   tage_out[BPU_BANK_NUM] : TAGE_TOP::OutputPayload      4352 bit
//   btb_out[BPU_BANK_NUM]  : BTB_TOP::OutputPayload        560 bit
//   out                    : BPU_TOP::OutputPayload       4470 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：bpu_predict_main_comb Input Bits = 5798, Output Bits = 6502。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 18/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_hist_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuHistCombIn(6944 bit) -> BpuHistCombOut(5935 bit)
//
// 输入 BpuHistCombIn = 6944 bit
//   = refetch                               1 bit
//   + in_update_base_pc[COMMIT_WIDTH]     256 bit
//   + in_upd_valid[COMMIT_WIDTH]            8 bit
//   + in_actual_dir[COMMIT_WIDTH]           8 bit
//   + in_actual_br_type[COMMIT_WIDTH]      24 bit
//   + in_pred_dir[COMMIT_WIDTH]             8 bit
//   + going_to_do_pred                      1 bit
//   + do_pred_on_this_pc[FETCH_WIDTH]      16 bit
//   + this_pc_bank_sel[FETCH_WIDTH]        80 bit
//   + do_pred_for_this_pc[FETCH_WIDTH]    512 bit
//   + Spec_GHR_snapshot[GHR_LENGTH]       512 bit
//   + Spec_FH_snapshot[FH_N_MAX][TN_MAX]  384 bit
//   + Arch_GHR_snapshot[GHR_LENGTH]       512 bit
//   + Arch_FH_snapshot[FH_N_MAX][TN_MAX]  384 bit
//   + Spec_PATH_snapshot                   16 bit
//   + Arch_PATH_snapshot                   16 bit
//   + Arch_ras_stack_snapshot[RAS_DEPTH] 2048 bit
//   + Arch_ras_count_snapshot               7 bit
//   + Spec_ras_stack_snapshot[RAS_DEPTH] 2048 bit
//   + Spec_ras_count_snapshot               7 bit
//   + type_out                             80 bit
//   + final_pred_dir[FETCH_WIDTH]          16 bit
//   = 合计                                 6944 bit
//
// 输出 BpuHistCombOut = 5935 bit
//   = should_update_spec_hist           1 bit
//   + Spec_GHR_next[GHR_LENGTH]       512 bit
//   + Spec_FH_next[FH_N_MAX][TN_MAX]  384 bit
//   + Arch_GHR_next[GHR_LENGTH]       512 bit
//   + Arch_FH_next[FH_N_MAX][TN_MAX]  384 bit
//   + Spec_PATH_next                   16 bit
//   + Arch_PATH_next                   16 bit
//   + Arch_ras_stack_next[RAS_DEPTH] 2048 bit
//   + Arch_ras_count_next               7 bit
//   + Spec_ras_stack_next[RAS_DEPTH] 2048 bit
//   + Spec_ras_count_next               7 bit
//   = 合计                             5935 bit
//
// 关键结构展开：
//   type_out : TypePredictor::OutputPayload 80 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：bpu_hist_comb Input Bits = 6944, Output Bits = 5935。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 19/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：bpu_queue_comb
// 来源：train_IO.h / BPU/BPU.h
// 配置：simulator-front 默认 large 配置
// 接口：BpuQueueCombIn(3152 bit) -> BpuQueueCombOut(3281 bit)
//
// 输入 BpuQueueCombIn = 3152 bit
//   = in_update_base_pc[COMMIT_WIDTH]               256 bit
//   + in_upd_valid[COMMIT_WIDTH]                      8 bit
//   + in_actual_dir[COMMIT_WIDTH]                     8 bit
//   + in_actual_br_type[COMMIT_WIDTH]                24 bit
//   + in_actual_targets[COMMIT_WIDTH]               256 bit
//   + in_pred_dir[COMMIT_WIDTH]                       8 bit
//   + in_alt_pred[COMMIT_WIDTH]                       8 bit
//   + in_pcpn[COMMIT_WIDTH]                          24 bit
//   + in_altpcpn[COMMIT_WIDTH]                       24 bit
//   + in_tage_tags[COMMIT_WIDTH][TN_MAX]            256 bit
//   + in_tage_idxs[COMMIT_WIDTH][TN_MAX]            384 bit
//   + in_sc_used[COMMIT_WIDTH]                        8 bit
//   + in_sc_pred[COMMIT_WIDTH]                        8 bit
//   + in_sc_sum[COMMIT_WIDTH]                       128 bit
//   + in_sc_idx[COMMIT_WIDTH][BPU_SCL_META_NTABLE] 1024 bit
//   + in_loop_used[COMMIT_WIDTH]                      8 bit
//   + in_loop_hit[COMMIT_WIDTH]                       8 bit
//   + in_loop_pred[COMMIT_WIDTH]                      8 bit
//   + in_loop_idx[COMMIT_WIDTH]                     128 bit
//   + in_loop_tag[COMMIT_WIDTH]                     128 bit
//   + q_wr_ptr_snapshot[BPU_BANK_NUM]               144 bit
//   + q_rd_ptr_snapshot[BPU_BANK_NUM]               144 bit
//   + q_count_snapshot[BPU_BANK_NUM]                144 bit
//   + going_to_do_upd[BPU_BANK_NUM]                  16 bit
//   = 合计                                           3152 bit
//
// 输出 BpuQueueCombOut = 3281 bit
//   = q_push_en[BPU_BANK_NUM]       16 bit
//   + q_pop_en[BPU_BANK_NUM]        16 bit
//   + q_wr_ptr_next[BPU_BANK_NUM]  144 bit
//   + q_rd_ptr_next[BPU_BANK_NUM]  144 bit
//   + q_count_next[BPU_BANK_NUM]   144 bit
//   + q_entry_we[COMMIT_WIDTH]       8 bit
//   + q_entry_bank[COMMIT_WIDTH]    32 bit
//   + q_entry_slot[COMMIT_WIDTH]    72 bit
//   + q_entry_data[COMMIT_WIDTH]  2704 bit
//   + update_queue_full              1 bit
//   = 合计                          3281 bit
//
// 关键结构展开：
//   q_entry_data[COMMIT_WIDTH] : BPU_TOP::ReadData::QueueEntrySnapshot 2704 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：bpu_queue_comb Input Bits = 3152, Output Bits = 3281。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 20/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_global_control_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontGlobalControlCombIn(67 bit) -> FrontGlobalControlCombOut(34 bit)
//
// 输入 FrontGlobalControlCombIn = 67 bit
//   = reset                               1 bit
//   + backend_refetch                     1 bit
//   + backend_refetch_address            32 bit
//   + predecode_refetch_snapshot          1 bit
//   + predecode_refetch_address_snapshot 32 bit
//   = 合计                                 67 bit
//
// 输出 FrontGlobalControlCombOut = 34 bit
//   = global_reset     1 bit
//   + global_refetch   1 bit
//   + refetch_address 32 bit
//   = 合计              34 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_global_control_comb Input Bits = 67, Output Bits = 34。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 21/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_read_enable_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontReadEnableCombIn(9 bit) -> FrontReadEnableCombOut(6 bit)
//
// 输入 FrontReadEnableCombIn = 9 bit
//   = backend_fifo_read_enable             1 bit
//   + fetch_addr_fifo_empty_latch_snapshot 1 bit
//   + fifo_empty_latch_snapshot            1 bit
//   + ptab_empty_latch_snapshot            1 bit
//   + front2back_fifo_full_latch_snapshot  1 bit
//   + global_reset                         1 bit
//   + global_refetch                       1 bit
//   + icache_ready                         1 bit
//   + icache_ready_2                       1 bit
//   = 合计                                   9 bit
//
// 输出 FrontReadEnableCombOut = 6 bit
//   = fetch_addr_fifo_read_enable_slot0           1 bit
//   + fetch_addr_fifo_read_enable_slot1_candidate 1 bit
//   + predecode_can_run_old                       1 bit
//   + inst_fifo_read_enable                       1 bit
//   + ptab_read_enable                            1 bit
//   + front2back_read_enable                      1 bit
//   = 合计                                          6 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_read_enable_comb Input Bits = 9, Output Bits = 6。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 22/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_read_stage_input_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontReadStageInputCombIn(7 bit) -> FrontReadStageInputCombOut(12 bit)
//
// 输入 FrontReadStageInputCombIn = 7 bit
//   = backend_refetch                   1 bit
//   + global_reset                      1 bit
//   + global_refetch                    1 bit
//   + fetch_addr_fifo_read_enable_slot0 1 bit
//   + inst_fifo_read_enable             1 bit
//   + ptab_read_enable                  1 bit
//   + front2back_read_enable            1 bit
//   = 合计                                7 bit
//
// 输出 FrontReadStageInputCombOut = 12 bit
//   = fetch_addr_fifo_reset        1 bit
//   + fetch_addr_fifo_refetch      1 bit
//   + fetch_addr_fifo_read_enable  1 bit
//   + fifo_reset                   1 bit
//   + fifo_refetch                 1 bit
//   + fifo_read_enable             1 bit
//   + ptab_reset                   1 bit
//   + ptab_refetch                 1 bit
//   + ptab_read_enable             1 bit
//   + front2back_fifo_reset        1 bit
//   + front2back_fifo_refetch      1 bit
//   + front2back_fifo_read_enable  1 bit
//   = 合计                          12 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_read_stage_input_comb Input Bits = 7, Output Bits = 12。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 23/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_bpu_control_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontBpuControlCombIn(2775 bit) -> FrontBpuControlCombOut(5480 bit)
//
// 输入 FrontBpuControlCombIn = 2775 bit
//   = bpu_in_seed                         2739 bit
//   + fetch_addr_fifo_full_latch_snapshot    1 bit
//   + ptab_full_latch_snapshot               1 bit
//   + global_reset                           1 bit
//   + global_refetch                         1 bit
//   + refetch_address                       32 bit
//   = 合计                                  2775 bit
//
// 输出 FrontBpuControlCombOut = 5480 bit
//   = bpu_stall           1 bit
//   + bpu_can_run         1 bit
//   + bpu_icache_ready    1 bit
//   + bpu_in           2739 bit
//   + bpu_input        2738 bit
//   = 合计               5480 bit
//
// 关键结构展开：
//   bpu_in_seed : BPU_in                2739 bit
//   bpu_in      : BPU_in                2739 bit
//   bpu_input   : BPU_TOP::InputPayload 2738 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_bpu_control_comb Input Bits = 2775, Output Bits = 5480。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 24/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_ptab_write_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontPtabWriteCombIn(4473 bit) -> FrontPtabWriteCombOut(4853 bit)
//
// 输入 FrontPtabWriteCombIn = 4473 bit
//   = bpu_output     4470 bit
//   + global_reset      1 bit
//   + global_refetch    1 bit
//   + ptab_can_write    1 bit
//   = 合计             4473 bit
//
// 输出 FrontPtabWriteCombOut = 4853 bit
//   = ptab_in 4853 bit
//   = 合计      4853 bit
//
// 关键结构展开：
//   bpu_output : BPU_TOP::OutputPayload 4470 bit
//   ptab_in    : PTAB_in                4853 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_ptab_write_comb Input Bits = 4473, Output Bits = 4853。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 25/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_checker_input_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontCheckerInputCombIn(6486 bit) -> FrontCheckerInputCombOut(624 bit)
//
// 输入 FrontCheckerInputCombIn = 6486 bit
//   = fifo_out 1635 bit
//   + ptab_out 4851 bit
//   = 合计       6486 bit
//
// 输出 FrontCheckerInputCombOut = 624 bit
//   = checker_in 624 bit
//   = 合计         624 bit
//
// 关键结构展开：
//   fifo_out   : instruction_FIFO_out 1635 bit
//   ptab_out   : PTAB_out             4851 bit
//   checker_in : predecode_checker_in  624 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_checker_input_comb Input Bits = 6486, Output Bits = 624。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 26/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_front2back_write_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontFront2backWriteCombIn(6536 bit) -> FrontFront2backWriteCombOut(10791 bit)
//
// 输入 FrontFront2backWriteCombIn = 6536 bit
//   = fifo_out                     1635 bit
//   + ptab_out                     4851 bit
//   + checker_out                    49 bit
//   + use_front2back_output_bypass    1 bit
//   = 合计                           6536 bit
//
// 输出 FrontFront2backWriteCombOut = 10791 bit
//   = front2back_fifo_in          5396 bit
//   + bypass_front2back_fifo_out  5395 bit
//   = 合计                         10791 bit
//
// 关键结构展开：
//   fifo_out                   : instruction_FIFO_out  1635 bit
//   ptab_out                   : PTAB_out              4851 bit
//   checker_out                : predecode_checker_out   49 bit
//   front2back_fifo_in         : front2back_FIFO_in    5396 bit
//   bypass_front2back_fifo_out : front2back_FIFO_out   5395 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_front2back_write_comb Input Bits = 6536, Output Bits = 10791。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------

// 27/27
// -----------------------------------------------------------------------------
// 端口自查
// 模块：front_output_comb
// 来源：train_IO.h / front_top.cpp
// 配置：simulator-front 默认 large 配置
// 接口：FrontOutputCombIn(10791 bit) -> FrontOutputCombOut(5393 bit)
//
// 输入 FrontOutputCombIn = 10791 bit
//   = saved_front2back_fifo_out     5395 bit
//   + bypass_front2back_fifo_out    5395 bit
//   + use_front2back_output_bypass     1 bit
//   = 合计                           10791 bit
//
// 输出 FrontOutputCombOut = 5393 bit
//   = out 5393 bit
//   = 合计  5393 bit
//
// 关键结构展开：
//   saved_front2back_fifo_out  : front2back_FIFO_out 5395 bit
//   bypass_front2back_fifo_out : front2back_FIFO_out 5395 bit
//   out                        : front_top_out       5393 bit
//
// 配置口径：
//   FETCH_WIDTH            = 16
//   COMMIT_WIDTH           = 8
//   TN_MAX                 = 4
//   BPU_BANK_NUM           = 16
//   TAGE_IDX_WIDTH         = 12
//   TAGE_TAG_WIDTH         = 8
//   TAGE_SC_PATH_BITS      = 16
//   BPU_SCL_META_NTABLE    = 8
//   BPU_SCL_META_IDX_BITS  = 16
//   BPU_LOOP_META_IDX_BITS = 16
//   BPU_LOOP_META_TAG_BITS = 16
//   tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = 23
//   tage_path_hist_t  = TAGE_SC_PATH_BITS = 16
//
// 自查确认：front_output_comb Input Bits = 10791, Output Bits = 5393。
// 完整字段来源见 front_end/port_width_audit/details 对应文件。
// -----------------------------------------------------------------------------
