# Frontend C++ Golden Slice 验证说明

本文档说明 `top/front_end` 里的 C++ golden slice 验证模式。

## 1. 目标

当前 `front_top.v` 已经把前端总框架包好，`slices` 目录用于后续放置或辅助生成 BSD 切片。真实 BSD 逻辑尚未全部交付前，可以先用 `simulator-front` 里的 C++ comb 函数临时代替对应 BSD 切片，用来验证：

- `front_top.v` 的总体连接是否能展开；
- 27 个 comb wrapper 的 `pi/po` 打包链路是否能跑通；
- 4 个 FIFO/PTAB 的本地 Verilog 实现能否和其余 comb 链路协同；
- Verilator 能否编译并运行一个基础 smoke。

这个模式只用于仿真验证，不改变默认交付形态。

## 2. 当前实现方式

默认不定义 `USE_CPP_GOLDEN_BSD` 时：

- FIFO/PTAB 使用本仓库 Verilog 实现；
- 其他 `*_bsd_top` 仍保持占位，等待组员替换真实 BSD 逻辑。

定义 `USE_CPP_GOLDEN_BSD` 时：

- 23 个非 FIFO/PTAB 的 `*_bsd_top` 会通过 DPI 调用 C++ golden 函数；
- 4 个 FIFO/PTAB 仍使用本仓库 Verilog 实现；
- C++ golden 函数由脚本从 `simulator-front` 的 struct 和 comb 类型生成。

相关文件：

```text
top/tools/generate_frontend_cpp_golden.py
top/front_end/slices/cpp_golden/cpp_golden_bsd.cpp
top/front_end/slices/cpp_golden/cpp_golden_bsd_macros.vh
top/front_end/slices/cpp_golden/include/SimCpu.h
top/front_end/sim/run_verilator_cpp_golden.sh
```

## 3. 运行命令

在 WSL 或服务器上执行：

```bash
cd top/front_end
bash sim/run_verilator_cpp_golden.sh
```

成功时会看到：

```text
FRONT_TOP_SMOKE_PASS
```

脚本会自动执行：

1. 重新生成 `slices/cpp_golden/cpp_golden_bsd.cpp`；
2. 确认非 FIFO/PTAB 的 `*_bsd_top` 具备 `USE_CPP_GOLDEN_BSD` 分支；
3. 用 Verilator 打开 `USE_CPP_GOLDEN_BSD`；
4. 编译 `front_top`、FIFO/PTAB Verilog、C++ golden bridge；
5. 运行 `front_top_smoke_tb.sv`。

## 4. 通过结果说明

当前已经通过：

```bash
verilator --lint-only -sv -f filelist.f
bash sim/run_verilator_cpp_golden.sh
```

结论：

- 默认 RTL 交付模式可以通过 Verilator lint；
- C++ golden slice 模式可以编译并跑完 smoke；
- `front_top` 到 27 个 comb wrapper 的连接链路具备可验证入口；
- C++ golden bridge 能和当前 `simulator-front` 头文件、类型、位宽一起编译。

## 5. 不能夸大的范围

`FRONT_TOP_SMOKE_PASS` 不是完整功能等价结论。

它只能说明“基础连接、编译、少量 smoke 场景”通过。完整等价还需要后续做 C-RTL 对拍：

- 给 simulator-front 和 RTL 喂同一组输入；
- 按周期比较 `front_top` 输出；
- 覆盖 refetch、flush、BPU 更新、ICache 返回、FIFO 满空、PTAB dummy、front2back bypass 等路径。

因此当前汇报口径应为：

```text
front_top 已支持 C++ golden slice 验证模式。当前默认 RTL lint 通过，C++ golden slice smoke 通过，可以用于验证 wrapper 连接和 pi/po 打包链路。后续仍需要补充完整 C-RTL 对拍，才能证明功能完全等价 simulator-front。
```
