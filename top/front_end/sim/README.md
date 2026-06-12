# 前端仿真与 C-RTL 对拍说明

本目录提供 `front_top` 的仿真入口，用来检查前端顶层骨架、C++ golden slice 以及周期级 C-RTL 对拍。

## 1. 纯 RTL 结构检查

只检查 `filelist.f` 中的 RTL 是否能被 Verilator 展开，不启用 C++ golden：

```bash
cd top/front_end
verilator --lint-only -sv -f filelist.f
```

当前已通过该检查。

## 2. 普通 smoke

使用当前 RTL，占位 BSD 仍保持占位，主要验证顶层端口、时钟复位、ICache 边界和主要输出没有明显 X：

```bash
cd top/front_end
bash sim/run_verilator_smoke.sh
```

成功标志：

```text
FRONT_TOP_SMOKE_PASS
```

## 3. C++ golden BSD smoke

打开 `USE_CPP_GOLDEN_BSD`，非 FIFO/PTAB 的 `*_bsd_top` 通过 DPI 调用 `simulator-front` 里的 C++ comb 函数。四个 FIFO/PTAB 仍使用本仓库 Verilog 实现：

```bash
cd top/front_end
bash sim/run_verilator_cpp_golden.sh
```

成功标志：

```text
FRONT_TOP_SMOKE_PASS
```

该入口用于确认 27 个 comb wrapper 的 `pi/po` 打包链路、C++ comb bridge 和 Verilator 编译链路能跑通。

## 4. 周期级 C-RTL 对拍

新增入口：

```bash
cd top/front_end
bash sim/run_verilator_crtl_compare.sh
```

这个脚本会：

1. 重新生成 `slices/cpp_golden/cpp_golden_bsd.cpp` 和宏文件；
2. 打开 `USE_CPP_GOLDEN_BSD`，让非 FIFO/PTAB 的 BSD 占位走 C++ comb；
3. 编译 `sim/front_top_cpp_oracle.cpp`，每拍调用一次 `simulator-front/front-end/front_top.cpp`；
4. 把 C++ 的 `front_top_out` 按 RTL 输出顺序打包；
5. 在 `front_top_smoke_tb.sv` 中逐拍比较 RTL 打包输出和 C++ 打包输出。

成功标志仍是：

```text
FRONT_TOP_SMOKE_PASS
```

若出现不一致，会打印：

```text
C_RTL_MISMATCH cycle=<n>
```

并用 `$fatal` 停止仿真。

当前这条 C-RTL 对拍入口已经在本地 WSL 下跑通。

## 5. 当前边界

这条对拍已经把 `simulator-front` 的 `front_top.cpp`、ICache、MMU、物理内存、FIFO C++ 模型和 23 个 C++ comb bridge 链进 Verilator 仿真。但它仍是 smoke 级对拍场景，不是完整程序级等价证明。

后续如果要扩大覆盖，需要继续增加输入激励，覆盖 backend commit、BPU 更新、ICache 返回、refetch、fence.i、ITLB flush、FIFO 满空和 PTAB dummy 等路径。
