# 模拟器接口识别脚本

本目录用于放置和模拟器接口识别、RTL 包装更新相关的辅助脚本。

## 脚本

```text
scan_simulator_interfaces.py
```

作用：

- 扫描模拟器 `include/config.h`，提取当前生效配置和 `CONFIG_*` 宏。
- 扫描模拟器 C++ 头文件/源码，提取“像接口一样使用”的 `struct/class` 字段。
- 扫描入口和 comb 相关函数，例如 `front_cycle`、`step_bpu`、`front_top`、`front_comb_calc`、`*_comb`。
- 扫描当前 RTL `.v` 文件，提取 Verilog module 的输入/输出端口。
- 生成完整中文 Markdown、JSON，以及可直接喂给 Codex 的中文短上下文。

## 使用方式

在工作区根目录执行：

```powershell
python top/tools/scan_simulator_interfaces.py simulator-front
```

如果后续模拟器目录名发生变化，只需要替换命令里的 `source` 参数：

```powershell
python top/tools/scan_simulator_interfaces.py simulator-new
```

不传 source 时，脚本会在工作区根目录下自动寻找 `simulator*` 目录，并优先选择名字中带 `front` 的目录。

仍然保留完整参数形式，方便需要指定 RTL 根目录或输出目录时使用：

```powershell
python top/tools/scan_simulator_interfaces.py simulator-front --rtl-root top --out-dir top/docs/generated_front
```

## 输出文件

默认输出到：

```text
top/docs/generated
```

生成文件：

| 文件 | 用途 |
|---|---|
| `simulator_interface_scan.md` | 完整扫描报告，适合人工核对。 |
| `simulator_interface_scan.json` | 结构化扫描结果，适合后续脚本处理。为方便脚本读取，JSON 键名保留英文。 |
| `codex_quick_context.md` | 精简上下文，适合在模拟器更新后直接喂给 Codex。 |

## 后续更新流程

1. 模拟器更新后，先运行 `scan_simulator_interfaces.py`。
2. 打开 `top/docs/generated/codex_quick_context.md`，把内容作为上下文交给 Codex。
3. 要求 Codex 对比新扫描结果和当前 `top/front_end`、`top/back_end`、`top_top.v`。
4. 重点检查：
   - `FETCH_WIDTH`、`DECODE_WIDTH`、`COMMIT_WIDTH` 等配置是否变化。
   - `front_top_in/front_top_out`、`FrontPreIO`、BPU 训练反馈字段是否变化。
   - `CONFIG_BPU`、`CONFIG_ORACLE_STEADY_FETCH_WIDTH` 等宏是否变化。
   - RTL 顶层端口和 wrapper 端口是否仍然对齐。
   - `front_top.v`、`bpu_top.v` 是否用具名变量端口连接各 comb wrapper。
   - `*_comb_top` 是否在内部把变量拼成 `pi/po`，并且只有 `*_bsd_top` 这一层保留 `.pi(pi)`、`.po(po)`。

## 注意

该脚本是静态扫描工具，不替代 Verilog 编译或仿真。它的作用是快速暴露“模拟器接口发生了什么变化”，减少人工翻文件的时间。

## 前后端端口自查脚本

当前推荐把前端和后端端口自查分开跑，输出文件直接放回对应目录：

```powershell
python top/tools/scan_frontend_ports.py
python top/tools/scan_backend_ports.py
python top/tools/scan_backend_ports.py --annotate-rtl
```

输出：

| 脚本 | 输出文件 | 说明 |
|---|---|---|
| `scan_frontend_ports.py` | `top/front_end/前端端口自查汇总.md` | 从 `simulator-front` 解析 27 个正式 comb 的输入/输出位宽、字段来源和关键结构展开。 |
| `scan_backend_ports.py` | `top/back_end/后端端口自查汇总.md` | 从 `top/back_end` RTL module 声明解析后端 top 端口、参数和 top 到 bsd_top 的实例关系。 |

这两个脚本只生成 Markdown 汇总，不会修改 RTL。已经写入各 `*_comb_top.v` 的分散端口注释继续保留。
