# Frontend 交付说明（simulator-front 版本）

本文档说明前端包的代码依据、模块拆分、执行顺序、接口约束和后续 RTL 实现范围。

当前前端包位于：

```text
top/front_end
```

本次训练版本统一依据 **simulator-front** 模拟器：

```text
simulator-front
```

端口宽度不再按旧版 `simulator_new` 或 `include/config.h.large` 判断。本次以 `simulator-front/include/config.h` 的实际生效配置为准。

## 0. 本次推送说明

本次推送的目标是将前端训练包的源码依据统一切换到 `simulator-front`，并同步更新前端 RTL 包、HTML 说明页、接口扫描脚本和说明文档中的版本口径。

本次已完成内容如下：

| 项目 | 状态 | 说明 |
|---|---|---|
| 模拟器基准 | 已切换 | 前端包统一以 `simulator-front` 为源码依据。 |
| 配置核对 | 已完成 | `simulator-front/include/config.h` 与旧 `simulator-ff/include/config.h` 无差异。 |
| FIFO/PTAB 口径 | 已更新 | 按 `simulator-front` 的 `push/pop/clear req` 周期末写回模型描述和实现。 |
| BPU 接口口径 | 已更新 | BPU comb 输入按显式字段/语义 bundle 组织，上层变量端口连接，最后一层保留 `pi/po`。 |
| HTML 说明 | 已更新 | 路径图和执行流说明中的源码依据已改为 `simulator-front`。 |
| 扫描脚本 | 已更新 | `top/tools/scan_simulator_interfaces.py` 默认优先识别 `simulator-front`。 |
| 扫描结果 | 已生成 | 新结果位于 `top/docs/generated_front/`。 |

本次对比结论：

- 全局配置未变化，因此 `FETCH_WIDTH`、`COMMIT_WIDTH`、`CONFIG_BPU`、FIFO/PTAB 深度等参数不需要重算。
- 主要差异集中在 `front-end/front_top.cpp`、`front-end/front_module.h`、`front-end/train_IO.h`、`front-end/BPU/BPU.h` 和四个 FIFO/PTAB cpp。
- `simulator-front` 中 FIFO/PTAB 不再采用整份 `next_rd` 覆盖写回，而是组合阶段产生请求，周期末统一执行请求。
- `simulator-front` 中 BPU comb 的输入拆得更细，当前前端 wrapper 的变量级端口连接方式与这个口径一致。

已执行的检查：

- 已重新运行 `python top/tools/scan_simulator_interfaces.py simulator-front --out-dir top/docs/generated_front`。
- 已执行 `git diff --check -- top/front_end top/tools`，未发现空白格式问题。
- 已确认旧模拟器 hash 无残留；`simulator-ff` 仅在本文档的版本差异对比处保留。

## 1. 当前交付内容

前端包当前交付的是一套可继续补 RTL 逻辑的前端训练框架：

| 文件/目录 | 作用 |
|---|---|
| `front_top.v` | 前端总入口，负责连接 ICache 边界、后端反馈、BPU、FIFO、PTAB、predecode、checker 和 front2back 输出。 |
| `bpu/bpu_top.v` | BPU 子系统总入口，负责连接 BPU 内部正式 comb 训练单元。 |
| `front_top_glue/` | `front_top.cpp` 中前端胶水组合逻辑对应的 comb 单元。 |
| `bpu/` | BPU、TypePredictor、TAGE、BTB 相关 comb 单元。 |
| `fifo/` | fetch address FIFO、instruction FIFO、PTAB、front2back FIFO 的 comb 单元。 |
| `predecode/` | predecode comb 单元。 |
| `predecode_checker/` | predecode checker comb 单元。 |
| `filelist.f` | 前端编译/交付文件清单。 |
| `front_top_interactive.html` | 27 个 comb 单元路径交互图。点击路径可查看相关模块和源码依据。 |
| `front_top_execution_flow.html` | 前端执行顺序说明图。 |
| `front_oracle_execution_flow.html` | Oracle 理想预测路径说明。当前 simulator-front 主线启用 BPU，该页只用于解释模拟器里的理想 BPU/Oracle 参考路径。 |
| `state_register_audit.md` | 前端寄存器、FIFO/PTAB 状态和 BPU 状态缺口自查。 |

## 2. 当前结论

前端按 **27 个正式 comb 训练单元** 组织。每个 comb 目录下都有一个 `*_comb_top.v`，其中再实例化对应的 `*_bsd_top`。

后续 RTL 实现范围为：

```text
27 个 *_bsd_top 内部的真实组合逻辑
```

该范围不等同于仅提供 27 个 `_bsd_top` 即可单独运行完整前端。完整运行仍然需要：

- `front_top.v`
- `bpu/bpu_top.v`
- 27 个 `*_comb_top.v` wrapper
- 27 个对应 `*_bsd_top` 真实逻辑
- `filelist.f`
- 上层 testbench 或 `top_top.v` 提供 `clk/reset`、ICache 输入、后端反馈输入

当前 `*_bsd_top` 分为两类：

- `fifo/` 下的 `fetch_address_FIFO_comb`、`instruction_FIFO_comb`、`PTAB_comb`、`front2back_FIFO_comb` 不再等待外部 BSD 代码，已在前端包内直接用 Verilog RTL 实现内部状态，包含 `mem/head/tail/count`，支持 reset/refetch 清空、write/read、空队列写读旁路、empty/full/valid 状态更新。
- `bpu/bpu_top.v` 已按模拟器 `BPU_TOP` 补顶层状态寄存器壳和周期写回位置；13 个 BPU comb 的真实 next-state 输出仍需后续接入。
- 其余 `*_bsd_top` 多数仍是零输出占位，需要继续补真实组合逻辑。

这四个 FIFO/PTAB 模块属于前端包自带 RTL，不是临时占位，也不是后续组员再提供 BSD 的空壳。需要注意的是，BPU 顶层寄存器壳已经补上，但 TAGE、BTB、TypePredictor 等预测器表项 RAM 以及各 BPU comb 的真实 next-state 逻辑仍需继续补。

## 3. 生效配置

本次前端和后端接口宽度按 simulator-front 生效配置整理：

| 配置项 | 生效值 | 依据 |
|---|---:|---|
| `FETCH_WIDTH` | 16 | `simulator-front/include/config.h` |
| `DECODE_WIDTH` | 8 | `simulator-front/include/config.h` |
| `COMMIT_WIDTH` | 8 | `simulator-front/include/config.h` |
| `CONFIG_BPU` | 打开 | `simulator-front/include/config.h` |
| `CONFIG_ORACLE_STEADY_FETCH_WIDTH` | 打开 | `simulator-front/include/config.h` |
| `PRF_NUM` | 2048 | `simulator-front/include/config.h` |
| `PRF_IDX_WIDTH` | 11 | `clog2(PRF_NUM)` |
| `ROB_NUM` | 2048 | `simulator-front/include/config.h` |
| `ROB_IDX_WIDTH` | 11 | `clog2(ROB_NUM)` |
| `STQ_SIZE` | 512 | `simulator-front/include/config.h` |
| `STQ_IDX_WIDTH` | 9 | `clog2(STQ_SIZE)` |
| `LDQ_SIZE` | 512 | `simulator-front/include/config.h` |
| `LDQ_IDX_WIDTH` | 9 | `clog2(LDQ_SIZE)` |
| `FTQ_SIZE` | 256 | `simulator-front/include/config.h` |
| `FTQ_IDX_WIDTH` | 8 | `clog2(FTQ_SIZE)` |

说明：

- `config.h.large` 不是本次训练包的直接依据。
- simulator-front 版本中 `front_top_out` 没有 `commit_stall`。
- simulator-front 版本中后端 `FrontPreIO` 没有 `front_stall`。
- 因此前后端接口里不再保留旧版 `commit_stall/front_stall` 字段。

### 3.1 与旧 simulator-ff 版本的差异

本次已经用 `top/tools/scan_simulator_interfaces.py` 对 `simulator-front` 重新扫描，并与旧 `simulator-ff` 口径对比：

| 项目 | 结论 | 对前端包的影响 |
|---|---|---|
| `include/config.h` | 与旧版本无差异 | `FETCH_WIDTH=16`、`COMMIT_WIDTH=8`、`CONFIG_BPU` 打开等宽度配置保持不变。 |
| `front-end/config/frontend_feature_config.h` | 与旧版本无差异 | FIFO/PTAB 深度参数保持不变。 |
| `front-end/front_top.cpp` | FIFO/PTAB 写回从 `next_rd` 改为 `*_req` 命令式写回 | 前端 FIFO/PTAB RTL 应按 `push/pop/clear` 请求更新状态，而不是整份 next_rd 覆盖。 |
| `front-end/front_module.h` | FIFO/PTAB read snapshot 只暴露 `size/head_valid/head_entry` | RTL 需要保存完整队列状态，组合读取只向外提供队首快照。 |
| `front-end/train_IO.h` | `FrontReadStageInputCombOut` 拆成 reset/refetch/read_enable 字段 | `front_read_stage_input_comb` 不再直接输出四个完整 FIFO 输入结构体。 |
| `front-end/BPU/BPU.h` | BPU comb 输入从 `InputPayload + ReadData` 拆成显式字段 | BPU wrapper 的变量级端口应保持显式信号/语义 bundle，最后一层再拼 `pi/po`。 |
| FIFO/PTAB cpp | 新增模型类并改为 `seq_write(req)` | `fetch_address_FIFO`、`instruction_FIFO`、`PTAB`、`front2back_FIFO` 四个模块需要直接实现 Verilog FIFO/PTAB 状态。 |

因此，本次切换到 `simulator-front` 不要求重算全局位宽，但要求文档、源码依据、FIFO/PTAB 行为说明都按新的请求式写回模型描述。

## 4. 前端执行主线

前端从 CPU 模拟器进入，顺序如下：

| 顺序 | 函数 | 源码依据 | 作用 |
|---:|---|---|---|
| 1 | `SimCpu::front_cycle()` | `rv_simu_mmu_v2.cpp` | 每拍设置 `front.in`，再调用前端执行函数。 |
| 2 | `FrontTop::step_bpu()` | `front-end/FrontTop.cpp` | BPU 主线入口，调用 `front_top(&in, &out)`。 |
| 3 | `front_top()` | `front-end/front_top.cpp` | 固定执行 `front_seq_read -> front_comb_calc -> front_seq_write`。 |
| 4 | `front_seq_read()` | `front-end/front_top.cpp` | 读取上一拍寄存器、FIFO、PTAB、BPU 表项和 ICache 相关快照。 |
| 5 | `front_comb_calc()` | `front-end/front_top.cpp` | 执行本拍全部组合逻辑，生成输出和 next-state 请求。 |
| 6 | `front_seq_write()` | `front-end/front_top.cpp` | 周期末统一写回寄存器、FIFO、PTAB、BPU 表项等状态。 |

执行原则：

```text
先读旧状态，再跑完整组合链，最后在周期末统一写新状态。
```

该顺序用于保证时序状态读取、组合逻辑计算和周期末状态更新分离。

## 5. 27 个正式 comb 训练单元

当前按源码调用关系整理为 27 个正式 comb 单元。`bpu_hist_*` 一类 helper 不再作为独立顶层模块展开，它们归入 `bpu_hist_comb` 内部说明。

### front_top glue

| 模块 | 当前文件 | 源码函数依据 |
|---|---|---|
| `front_global_control_comb` | `front_top_glue/front_global_control_comb/front_global_control_comb_top.v` | `front_top.cpp` |
| `front_read_enable_comb` | `front_top_glue/front_read_enable_comb/front_read_enable_comb_top.v` | `front_top.cpp` |
| `front_read_stage_input_comb` | `front_top_glue/front_read_stage_input_comb/front_read_stage_input_comb_top.v` | `front_top.cpp` |
| `front_bpu_control_comb` | `front_top_glue/front_bpu_control_comb/front_bpu_control_comb_top.v` | `front_top.cpp` |
| `front_ptab_write_comb` | `front_top_glue/front_ptab_write_comb/front_ptab_write_comb_top.v` | `front_top.cpp` |
| `front_checker_input_comb` | `front_top_glue/front_checker_input_comb/front_checker_input_comb_top.v` | `front_top.cpp` |
| `front_front2back_write_comb` | `front_top_glue/front_front2back_write_comb/front_front2back_write_comb_top.v` | `front_top.cpp` |
| `front_output_comb` | `front_top_glue/front_output_comb/front_output_comb_top.v` | `front_top.cpp` |

### BPU top

| 模块 | 当前文件 | 源码函数依据 |
|---|---|---|
| `bpu_pre_read_req_comb` | `bpu/bpu_pre_read_req_comb/bpu_pre_read_req_comb_top.v` | `front-end/BPU/BPU.h` |
| `bpu_post_read_req_comb` | `bpu/bpu_post_read_req_comb/bpu_post_read_req_comb_top.v` | `front-end/BPU/BPU.h` |
| `bpu_submodule_bind_comb` | `bpu/bpu_submodule_bind_comb/bpu_submodule_bind_comb_top.v` | `front-end/BPU/BPU.h` |
| `bpu_predict_main_comb` | `bpu/bpu_predict_main_comb/bpu_predict_main_comb_top.v` | `front-end/BPU/BPU.h` |
| `bpu_hist_comb` | `bpu/bpu_hist_comb/bpu_hist_comb_top.v` | `front-end/BPU/BPU.h` |
| `bpu_queue_comb` | `bpu/bpu_queue_comb/bpu_queue_comb_top.v` | `front-end/BPU/BPU.h` |

### predictor submodules

| 模块 | 当前文件 | 源码函数依据 |
|---|---|---|
| `type_predictor_pre_read_comb` | `bpu/type_predictor/type_predictor_pre_read_comb/type_predictor_pre_read_comb_top.v` | `front-end/BPU/type_predictor/TypePredictor.h` |
| `type_pred_comb` | `bpu/type_predictor/type_pred_comb/type_pred_comb_top.v` | `front-end/BPU/type_predictor/TypePredictor.h` |
| `tage_pre_read_comb` | `bpu/dir_predictor/tage_pre_read_comb/tage_pre_read_comb_top.v` | `front-end/BPU/dir_predictor/TAGE_top.h` |
| `tage_comb` | `bpu/dir_predictor/tage_comb/tage_comb_top.v` | `front-end/BPU/dir_predictor/TAGE_top.h` |
| `btb_pre_read_comb` | `bpu/target_predictor/btb_pre_read_comb/btb_pre_read_comb_top.v` | `front-end/BPU/target_predictor/BTB_top.h` |
| `btb_post_read_req_comb` | `bpu/target_predictor/btb_post_read_req_comb/btb_post_read_req_comb_top.v` | `front-end/BPU/target_predictor/BTB_top.h` |
| `btb_comb` | `bpu/target_predictor/btb_comb/btb_comb_top.v` | `front-end/BPU/target_predictor/BTB_top.h` |

### FIFO / predecode / checker

| 模块 | 当前文件 | 源码函数依据 |
|---|---|---|
| `fetch_address_FIFO_comb` | `fifo/fetch_address_FIFO_comb/fetch_address_FIFO_comb_top.v` | `front-end/fifo` 相关源码 |
| `instruction_FIFO_comb` | `fifo/instruction_FIFO_comb/instruction_FIFO_comb_top.v` | `front-end/fifo` 相关源码 |
| `PTAB_comb` | `fifo/PTAB_comb/PTAB_comb_top.v` | `front-end/fifo` 相关源码 |
| `front2back_FIFO_comb` | `fifo/front2back_FIFO_comb/front2back_FIFO_comb_top.v` | `front-end/fifo` 相关源码 |
| `predecode_comb` | `predecode/predecode_comb/predecode_comb_top.v` | `front-end/predecode` 相关源码 |
| `predecode_checker_comb` | `predecode_checker/predecode_checker_comb/predecode_checker_comb_top.v` | `front-end/predecode_checker` 相关源码 |

## 6. BSD 逻辑实现要求

前端 comb wrapper 的接口格式与后端保持一致：父级 `front_top.v` / `bpu_top.v`
连接语义变量端口，只有 `xxx_comb_bsd_top` 这一层保留 `pi/po`。

每个 comb 文件当前结构类似：

```verilog
module xxx_comb_top #(
    parameter integer W_XxxCombIn  = 1234,  // actual: 1234, from front_top/bpu_top ...
    parameter integer W_XxxCombOut = 5678   // actual: 5678, from front_top/bpu_top ...
) (
    input  wire                    named_control,
    input  wire [W_XxxPayload-1:0] named_input_bundle,
    output wire [W_XxxResult-1:0]  named_output_bundle
);
    wire [W_XxxCombIn-1:0]  pi;
    wire [W_XxxCombOut-1:0] po;

    assign pi = {
        named_control,
        named_input_bundle
    };

    assign {
        named_output_bundle
    } = po;

    xxx_comb_bsd_top u_xxx_comb_bsd_top (
        .pi(pi),
        .po(po)
    );
endmodule
```

实现要求：

1. 保留 `xxx_comb_top` 作为连接壳。
2. `front_top.v`、`bpu_top.v` 调用 comb 时使用变量端口，例如 `.named_input_bundle(named_input_bundle)`。
3. `xxx_comb_top` 内部只负责把变量端口拼成 `pi`，并把 `po` 拆回变量输出。
4. `xxx_comb_bsd_top` 对外统一使用 `pi/po`，组员后续在这一层补真实组合逻辑。
5. 顶层参数不要写统一占位 `64`，应写当前 simulator-front 配置下的实际默认值，并在注释里标出来源。
6. 保持 `front_top.v` 和 `bpu_top.v` 的大框架连线稳定。
7. 如果一个 comb 内部需要继续拆小函数，可在本 comb 目录下新建子模块或使用 `slices/` 预留目录；helper 不计入新的正式顶层 comb。
8. 补完后确认 `filelist.f` 中包含新增子模块文件。
9. 所有接口宽度按 simulator-front 当前配置，不按旧版 large 截图或 simulator_new。

## 7. ICache 和 Oracle 说明

### ICache

simulator-front 源码中前端不是纯 ideal 取指，而是通过 ICache/PTW 运行时边界取指。当前 RTL 包没有私自实现完整 ICache，而是在 `front_top.v` 暴露 `front_icache_*` 输入输出，由上层或 testbench 驱动。

因此：

- 前端包负责产生 ICache 请求和接收 ICache 返回。
- ICache 具体行为需要由上层环境、testbench 或后续模块提供。

### Oracle

当前 simulator-front 生效配置打开了 `CONFIG_BPU`，正常训练主线走：

```text
front.step_bpu()
```

本次 RTL 包按“BPU 一定在”的口径连接：`front_top.v` 中实例化 `bpu_top`，再由 `bpu_top` 展开 13 个 BPU comb wrapper。Oracle 不作为另一套硬件分支接入 `front_top.v`。

模拟器里的 `step_oracle()` 可以理解为理想 BPU/参考预测路径：它用于说明源码里的理想预测逻辑，不参与当前 27 个正式 comb 主线交付，也不作为可综合 RTL 数据源接入。

## 8. 当前已检查内容

已做的静态检查：

- `filelist.f` 中列出的前端文件路径存在。
- 27 个正式 comb wrapper 均存在。
- 每个 wrapper 均有对应 `*_bsd_top` 模块。
- `fifo/` 下 4 个 FIFO/PTAB comb 已改为前端包直接 Verilog RTL 实现。
- `bpu/bpu_top.v` 已补 BPU 顶层状态寄存器壳，复位初值参考 `BPU_TOP::reset_internal_all()`。
- `front_top_interactive.html` 和 `front_top_execution_flow.html` 已按 27 个 comb 路径整理。
- 前后端接口按 simulator-front 配置去掉旧版 `commit_stall/front_stall` 残留。

尚未完成的功能性验证：

- 当前环境未安装 `iverilog/verilator/yosys`，所以还没有做完整 Verilog 编译。
- 非 FIFO/PTAB 的 `*_bsd_top` 多数仍是零输出占位，BPU 顶层状态壳已有，但真实 next-state、TAGE/BTB/TypePredictor 表项更新还未接入，补真实逻辑前不能认为功能正确。

## 9. 文件查看顺序

查看顺序如下：

1. 先打开 `front_top_execution_flow.html`，看一遍整体执行顺序。
2. 再打开 `front_top_interactive.html`，点击路径查看每条路径涉及哪些 comb 和源码依据。
3. 回到 `front_top.v`，确认总连线如何把 27 个 comb 串起来。
4. 如果负责 BPU，再看 `bpu/bpu_top.v`。
5. 最后进入自己负责的 `*_comb_top.v`，补对应 `*_bsd_top`。
