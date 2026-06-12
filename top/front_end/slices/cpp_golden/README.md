# C++ Golden Slice 目录说明

本目录是前端验证辅助目录，不是最终 BSD 交付目录。

## 文件说明

```text
cpp_golden_bsd.cpp        由脚本生成的 DPI C++ bridge
cpp_golden_bsd_macros.vh  RTL 中 USE_CPP_GOLDEN_BSD 分支使用的宏
include/SimCpu.h          仿真专用轻量 stub，避免 comb 验证拉入整机 SimCpu 依赖
```

`cpp_golden_bsd.cpp` 不建议手改。需要更新时执行：

```bash
python top/tools/generate_frontend_cpp_golden.py simulator-front --patch-rtl
```

或直接运行：

```bash
cd top/front_end
bash sim/run_verilator_cpp_golden.sh
```

## 和真实 BSD 的关系

真实交付时不定义 `USE_CPP_GOLDEN_BSD`，各个 `*_bsd_top` 仍由组员补真实 Verilog/BSD 逻辑。

这个目录只用于“真实 BSD 未补齐前，先用 C++ 源码逻辑验证 top 连接是否通”的仿真模式。
