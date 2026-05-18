# Frontend 交付说明

本文档说明前端包的代码依据、模块拆分、执行顺序、接口约束和后续 RTL 实现范围。

当前前端包位于：

```text
top/front_end
```

本次训练版本统一依据 **simulator-ff** 模拟器：

```text
simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0
```

端口宽度不再按旧版 `simulator_new` 或 `include/config.h.large` 判断。本次以 `simulator-ff/include/config.h` 的实际生效配置为准。

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
| `front_oracle_execution_flow.html` | Oracle 备用路径说明。当前 ff 主线启用 BPU，该页只用于解释灰色/备用代码。 |

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

当前 `*_bsd_top` 多数仍是占位逻辑：

```verilog
assign po = {W_xxxOut{1'b0}};
```

占位逻辑只表示结构连接，不代表功能正确。需要在对应 `*_bsd_top` 中替换为真实 RTL。

## 3. 生效配置

本次前端和后端接口宽度按 simulator-ff 生效配置整理：

| 配置项 | 生效值 | 依据 |
|---|---:|---|
| `FETCH_WIDTH` | 16 | `simulator-ff/include/config.h` |
| `DECODE_WIDTH` | 8 | `simulator-ff/include/config.h` |
| `COMMIT_WIDTH` | 8 | `simulator-ff/include/config.h` |
| `CONFIG_BPU` | 打开 | `simulator-ff/include/config.h` |
| `CONFIG_ORACLE_STEADY_FETCH_WIDTH` | 打开 | `simulator-ff/include/config.h` |
| `PRF_NUM` | 2048 | `simulator-ff/include/config.h` |
| `PRF_IDX_WIDTH` | 11 | `clog2(PRF_NUM)` |
| `ROB_NUM` | 2048 | `simulator-ff/include/config.h` |
| `ROB_IDX_WIDTH` | 11 | `clog2(ROB_NUM)` |
| `STQ_SIZE` | 512 | `simulator-ff/include/config.h` |
| `STQ_IDX_WIDTH` | 9 | `clog2(STQ_SIZE)` |
| `LDQ_SIZE` | 512 | `simulator-ff/include/config.h` |
| `LDQ_IDX_WIDTH` | 9 | `clog2(LDQ_SIZE)` |
| `FTQ_SIZE` | 256 | `simulator-ff/include/config.h` |
| `FTQ_IDX_WIDTH` | 8 | `clog2(FTQ_SIZE)` |

说明：

- `config.h.large` 不是本次训练包的直接依据。
- ff 版本中 `front_top_out` 没有 `commit_stall`。
- ff 版本中后端 `FrontPreIO` 没有 `front_stall`。
- 因此前后端接口里不再保留旧版 `commit_stall/front_stall` 字段。

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

每个 comb 文件当前结构类似：

```verilog
module xxx_comb_top #(
    parameter integer W_XxxCombIn = 64,
    parameter integer W_XxxCombOut = 64
) (
    input  wire [W_XxxCombIn-1:0]  xxx_comb_in,
    output wire [W_XxxCombOut-1:0] xxx_comb_out
);
    wire [W_XxxCombIn-1:0]  xxx_comb_pi;
    wire [W_XxxCombOut-1:0] xxx_comb_po;

    assign xxx_comb_pi = xxx_comb_in;
    assign xxx_comb_out = xxx_comb_po;

    xxx_comb_bsd_top u_xxx_comb_bsd_top (
        .pi(xxx_comb_pi),
        .po(xxx_comb_po)
    );
endmodule
```

实现要求：

1. 保留 `xxx_comb_top` 作为连接壳。
2. 在 `xxx_comb_bsd_top` 中实现真实组合逻辑。
3. 保持 `front_top.v` 和 `bpu_top.v` 的大框架连线稳定。
4. 如果一个 comb 内部需要继续拆小函数，可在本 comb 目录下新建子模块或使用 `slices/` 预留目录；helper 不计入新的正式顶层 comb。
5. 补完后确认 `filelist.f` 中包含新增子模块文件。
6. 所有接口宽度按 simulator-ff 当前配置，不按旧版 large 截图或 simulator_new。

## 7. ICache 和 Oracle 说明

### ICache

ff 源码中前端不是纯 ideal 取指，而是通过 ICache/PTW 运行时边界取指。当前 RTL 包没有私自实现完整 ICache，而是在 `front_top.v` 暴露 `front_icache_*` 输入输出，由上层或 testbench 驱动。

因此：

- 前端包负责产生 ICache 请求和接收 ICache 返回。
- ICache 具体行为需要由上层环境、testbench 或后续模块提供。

### Oracle

当前 ff 生效配置打开了 `CONFIG_BPU`，正常训练主线走：

```text
front.step_bpu()
```

`step_oracle()` 是 `CONFIG_BPU` 关闭时的备用路径，不参与当前 27 个 BPU comb 主线交付。保留 `front_oracle_execution_flow.html` 是为了说明灰色 `#else` 代码是什么。

## 8. 当前已检查内容

已做的静态检查：

- `filelist.f` 中列出的前端文件路径存在。
- 27 个正式 comb wrapper 均存在。
- 每个 wrapper 均有对应 `*_bsd_top` 占位模块。
- `front_top_interactive.html` 和 `front_top_execution_flow.html` 已按 27 个 comb 路径整理。
- 前后端接口按 simulator-ff 配置去掉旧版 `commit_stall/front_stall` 残留。

尚未完成的功能性验证：

- 当前环境未安装 `iverilog/verilator/yosys`，所以还没有做完整 Verilog 编译。
- `*_bsd_top` 多数仍是零输出占位，补真实逻辑前不能认为功能正确。

## 9. 文件查看顺序

查看顺序如下：

1. 先打开 `front_top_execution_flow.html`，看一遍整体执行顺序。
2. 再打开 `front_top_interactive.html`，点击路径查看每条路径涉及哪些 comb 和源码依据。
3. 回到 `front_top.v`，确认总连线如何把 27 个 comb 串起来。
4. 如果负责 BPU，再看 `bpu/bpu_top.v`。
5. 最后进入自己负责的 `*_comb_top.v`，补对应 `*_bsd_top`。
