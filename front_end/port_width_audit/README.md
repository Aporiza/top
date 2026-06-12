# 前端 27 个 comb 端口位宽目录

- 生成时间：2026-06-12 00:24:18
- 模拟器源码：`C:/Users/16854/Desktop/codex/simulator-front`
- 配置口径：`simulator-front` 当前默认 large 配置
- 说明：本目录只核对端口和字段来源，不代表 BSD 真实组合逻辑已经补齐。

## large 配置关键值

| 配置项                     | 值    |
| ----------------------- | ---- |
| `FETCH_WIDTH`           | 16   |
| `COMMIT_WIDTH`          | 8    |
| `TN_MAX`                | 4    |
| `BPU_BANK_NUM`          | 16   |
| `TAGE_IDX_WIDTH`        | 12   |
| `TAGE_TAG_WIDTH`        | 8    |
| `TAGE_SC_PATH_BITS`     | 16   |
| `TYPE_PRED_SET_NUM`     | 2048 |
| `FETCH_ADDR_FIFO_SIZE`  | 32   |
| `INSTRUCTION_FIFO_SIZE` | 32   |
| `PTAB_SIZE`             | 32   |
| `FRONT2BACK_FIFO_SIZE`  | 64   |
| `Q_DEPTH`               | 500  |
| `RAS_DEPTH`             | 64   |


## 特殊 typedef 处理

- `tage_reset_ctr_t`：源码写成 `using tage_reset_ctr_t = wire32_t`，但有效宽度按 `tage_reset_ctr_t_BITS = TAGE_IDX_WIDTH + 11`，当前为 23 bit。
- `tage_path_hist_t`：源码写成 `using tage_path_hist_t = wire32_t`，但有效宽度按 `tage_path_hist_t_BITS = TAGE_SC_PATH_BITS`，当前为 16 bit。

## 27 个 comb 汇总

| 序号 | 分组             | comb                                                                       | 输入类型                            | 输入bit | 输出类型                             | 输出bit | 源码依据                                        |
| -- | -------------- | -------------------------------------------------------------------------- | ------------------------------- | ----- | -------------------------------- | ----- | ------------------------------------------- |
| 1  | FIFO/PTAB      | [fetch_address_FIFO_comb](details/01_fetch_address_FIFO_comb.md)           | `FetchAddrCombIn`               | 75    | `FetchAddrCombOut`               | 70    | train_IO.h / fifo/fetch_address_FIFO.cpp    |
| 2  | FIFO/PTAB      | [instruction_FIFO_comb](details/02_instruction_FIFO_comb.md)               | `InstructionCombIn`             | 3275  | `InstructionCombOut`             | 3270  | train_IO.h / fifo/instruction_FIFO.cpp      |
| 3  | FIFO/PTAB      | [PTAB_comb](details/03_PTAB_comb.md)                                       | `PtabCombIn`                    | 9710  | `PtabCombOut`                    | 14555 | train_IO.h / PTAB.cpp                       |
| 4  | FIFO/PTAB      | [front2back_FIFO_comb](details/04_front2back_FIFO_comb.md)                 | `Front2BackCombIn`              | 10796 | `Front2BackCombOut`              | 10790 | train_IO.h / fifo/front2back_FIFO.cpp       |
| 5  | Predecode      | [predecode_comb](details/05_predecode_comb.md)                             | `PredecodeCombIn`               | 64    | `PredecodeCombOut`               | 34    | train_IO.h / predecode.cpp                  |
| 6  | Predecode      | [predecode_checker_comb](details/06_predecode_checker_comb.md)             | `PredecodeCheckerCombIn`        | 624   | `PredecodeCheckerCombOut`        | 49    | train_IO.h / predecode_checker.cpp          |
| 7  | BPU            | [type_predictor_pre_read_comb](details/07_type_predictor_pre_read_comb.md) | `TypePredPreReadCombIn`         | 816   | `TypePredPreReadCombOut`         | 672   | train_IO.h / BPU/type_predictor             |
| 8  | BPU            | [type_pred_comb](details/08_type_pred_comb.md)                             | `TypePredCombIn`                | 2448  | `TypePredCombOut`                | 376   | train_IO.h / BPU/type_predictor             |
| 9  | BPU            | [tage_pre_read_comb](details/09_tage_pre_read_comb.md)                     | `TagePreReadCombIn`             | 2528  | `TagePreReadCombOut`             | 579   | train_IO.h / BPU/dir_predictor/TAGE_top.h   |
| 10 | BPU            | [tage_comb](details/10_tage_comb.md)                                       | `TageCombIn`                    | 3329  | `TageCombOut`                    | 1932  | train_IO.h / BPU/dir_predictor/TAGE_top.h   |
| 11 | BPU            | [btb_pre_read_comb](details/11_btb_pre_read_comb.md)                       | `BtbPreReadCombIn`              | 105   | `BtbPreReadCombOut`              | 228   | train_IO.h / BPU/target_predictor/BTB_top.h |
| 12 | BPU            | [btb_post_read_req_comb](details/12_btb_post_read_req_comb.md)             | `BTB_TOP::BtbPostReadReqCombIn` | 2264  | `BTB_TOP::BtbPostReadReqCombOut` | 45    | BPU/target_predictor/BTB_top.h              |
| 13 | BPU            | [btb_comb](details/13_btb_comb.md)                                         | `BtbCombIn`                     | 2264  | `BtbCombOut`                     | 1089  | train_IO.h / BPU/target_predictor/BTB_top.h |
| 14 | BPU            | [bpu_pre_read_req_comb](details/14_bpu_pre_read_req_comb.md)               | `BpuPreReadReqCombIn`           | 369   | `BpuPreReadReqCombOut`           | 875   | train_IO.h / BPU/BPU.h                      |
| 15 | BPU            | [bpu_post_read_req_comb](details/15_bpu_post_read_req_comb.md)             | `BpuPostReadReqCombIn`          | 7332  | `BpuPostReadReqCombOut`          | 22509 | train_IO.h / BPU/BPU.h                      |
| 16 | BPU            | [bpu_submodule_bind_comb](details/16_bpu_submodule_bind_comb.md)           | `BpuSubmoduleBindCombIn`        | 1856  | `BpuSubmoduleBindCombOut`        | 1680  | train_IO.h / BPU/BPU.h                      |
| 17 | BPU            | [bpu_predict_main_comb](details/17_bpu_predict_main_comb.md)               | `BpuPredictMainCombIn`          | 5798  | `BpuPredictMainCombOut`          | 6502  | train_IO.h / BPU/BPU.h                      |
| 18 | BPU            | [bpu_hist_comb](details/18_bpu_hist_comb.md)                               | `BpuHistCombIn`                 | 6944  | `BpuHistCombOut`                 | 5935  | train_IO.h / BPU/BPU.h                      |
| 19 | BPU            | [bpu_queue_comb](details/19_bpu_queue_comb.md)                             | `BpuQueueCombIn`                | 3152  | `BpuQueueCombOut`                | 3281  | train_IO.h / BPU/BPU.h                      |
| 20 | front_top glue | [front_global_control_comb](details/20_front_global_control_comb.md)       | `FrontGlobalControlCombIn`      | 67    | `FrontGlobalControlCombOut`      | 34    | train_IO.h / front_top.cpp                  |
| 21 | front_top glue | [front_read_enable_comb](details/21_front_read_enable_comb.md)             | `FrontReadEnableCombIn`         | 9     | `FrontReadEnableCombOut`         | 6     | train_IO.h / front_top.cpp                  |
| 22 | front_top glue | [front_read_stage_input_comb](details/22_front_read_stage_input_comb.md)   | `FrontReadStageInputCombIn`     | 7     | `FrontReadStageInputCombOut`     | 12    | train_IO.h / front_top.cpp                  |
| 23 | front_top glue | [front_bpu_control_comb](details/23_front_bpu_control_comb.md)             | `FrontBpuControlCombIn`         | 2775  | `FrontBpuControlCombOut`         | 5480  | train_IO.h / front_top.cpp                  |
| 24 | front_top glue | [front_ptab_write_comb](details/24_front_ptab_write_comb.md)               | `FrontPtabWriteCombIn`          | 4473  | `FrontPtabWriteCombOut`          | 4853  | train_IO.h / front_top.cpp                  |
| 25 | front_top glue | [front_checker_input_comb](details/25_front_checker_input_comb.md)         | `FrontCheckerInputCombIn`       | 6486  | `FrontCheckerInputCombOut`       | 624   | train_IO.h / front_top.cpp                  |
| 26 | front_top glue | [front_front2back_write_comb](details/26_front_front2back_write_comb.md)   | `FrontFront2backWriteCombIn`    | 6536  | `FrontFront2backWriteCombOut`    | 10791 | train_IO.h / front_top.cpp                  |
| 27 | front_top glue | [front_output_comb](details/27_front_output_comb.md)                       | `FrontOutputCombIn`             | 10791 | `FrontOutputCombOut`             | 5393  | train_IO.h / front_top.cpp                  |

