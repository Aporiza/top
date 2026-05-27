#!/usr/bin/env python3
"""
扫描模拟器仓库，并生成 RTL 训练包需要的接口摘要。

脚本只依赖 Python 标准库，模拟器更新后可以直接重新运行。
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
from pathlib import Path
from typing import Any


INTERESTING_CONFIG = [
    "FETCH_WIDTH",
    "DECODE_WIDTH",
    "COMMIT_WIDTH",
    "PRF_NUM",
    "ROB_NUM",
    "STQ_SIZE",
    "LDQ_SIZE",
    "FTQ_SIZE",
    "PRF_IDX_WIDTH",
    "ROB_IDX_WIDTH",
    "STQ_IDX_WIDTH",
    "LDQ_IDX_WIDTH",
    "FTQ_IDX_WIDTH",
    "ISSUE_WIDTH",
    "MAX_WAKEUP_PORTS",
    "TOTAL_FU_COUNT",
    "LSU_LOAD_WB_WIDTH",
]

ENTRY_FUNCTION_HINTS = [
    "front_cycle",
    "back2front_comb",
    "step_bpu",
    "step_oracle",
    "front_top",
    "front_seq_read",
    "front_comb_calc",
    "front_seq_write",
    "bpu_comb_calc",
    "comb_calc",
]

KEY_STRUCT_HINTS = [
    "front_top",
    "BPU",
    "bpu",
    "FIFO",
    "fifo",
    "PTAB",
    "ptab",
    "icache",
    "IO",
    "Io",
    "In",
    "Out",
    "Input",
    "Output",
    "Payload",
    "Req",
    "Resp",
    "Meta",
]

STRUCT_PRIORITY_NAMES = {
    "front_top_in": 0,
    "front_top_out": 1,
    "BPU_in": 2,
    "BPU_out": 3,
    "FrontPreIO": 4,
    "PreFrontIO": 5,
    "CsrStatusIO": 6,
}


class ChineseArgumentParser(argparse.ArgumentParser):
    def format_usage(self) -> str:
        return super().format_usage().replace("usage:", "用法:", 1)

    def format_help(self) -> str:
        return super().format_help().replace("usage:", "用法:", 1)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def rel(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*?$", "", text, flags=re.M)
    return text


def auto_find_sim_root(workspace_root: Path) -> Path:
    candidates = [p for p in workspace_root.iterdir() if p.is_dir() and p.name.startswith("simulator")]
    if not candidates:
        return workspace_root

    def score(path: Path) -> tuple[int, str]:
        name = path.name.lower()
        if "front" in name:
            return (0, name)
        if "ff" in name:
            return (1, name)
        if "new" in name:
            return (2, name)
        return (3, name)

    return sorted(candidates, key=score)[0]


def scan_config(sim_root: Path) -> dict[str, Any]:
    config_path = sim_root / "include" / "config.h"
    result: dict[str, Any] = {
        "path": rel(config_path, sim_root) if config_path.exists() else "",
        "defines": [],
        "constexpr": [],
        "interesting": [],
        "enabled_config_macros": [],
    }
    if not config_path.exists():
        return result

    text = read_text(config_path)
    lines = text.splitlines()
    constexpr_by_name: dict[str, dict[str, Any]] = {}
    define_by_name: dict[str, dict[str, Any]] = {}

    for lineno, raw in enumerate(lines, 1):
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        define_match = re.match(r"#\s*define\s+([A-Za-z_]\w*)(?:\s+(.*))?$", line)
        if define_match:
            name = define_match.group(1)
            value = (define_match.group(2) or "1").strip()
            item = {"name": name, "value": value, "line": lineno}
            define_by_name[name] = item
            result["defines"].append(item)
            if name.startswith("CONFIG_"):
                result["enabled_config_macros"].append(item)
            continue

        const_match = re.match(
            r"constexpr\s+(?:int|unsigned|uint\d+_t|size_t|auto|uint64_t|uint32_t)\s+"
            r"([A-Za-z_]\w*)\s*=\s*(.*?);",
            line,
        )
        if const_match:
            name = const_match.group(1)
            value = const_match.group(2).strip()
            item = {"name": name, "value": value, "line": lineno}
            constexpr_by_name[name] = item
            result["constexpr"].append(item)

    for name in INTERESTING_CONFIG:
        item = constexpr_by_name.get(name) or define_by_name.get(name)
        if item:
            result["interesting"].append(item)

    evaluated = evaluate_config_values(result["constexpr"], result["defines"])
    for group_name in ("defines", "constexpr", "interesting", "enabled_config_macros"):
        for item in result[group_name]:
            if item["name"] in evaluated:
                item["evaluated"] = evaluated[item["name"]]
    return result


def clean_cpp_int_expr(expr: str) -> str:
    expr = re.sub(r"\b(\d+)(?:ull|ULL|ul|UL|u|U|ll|LL)\b", r"\1", expr)
    return expr


def try_eval_config_expr(expr: str, values: dict[str, int]) -> int | None:
    expr = clean_cpp_int_expr(expr)
    for _ in range(4):
        changed = False
        for name, value in values.items():
            new_expr = re.sub(rf"\b{re.escape(name)}\b", str(value), expr)
            if new_expr != expr:
                changed = True
                expr = new_expr
        if not changed:
            break
    if re.search(r"[A-Za-z_]\w*(?!\s*\()", expr.replace("clog2", "")):
        return None
    if not re.fullmatch(r"[0-9\s+\-*/%<>()|&~^,]+|clog2\s*\([0-9\s+\-*/%<>()|&~^,]+\)", expr):
        if not re.fullmatch(r"[0-9\s+\-*/%<>()|&~^,clog2]+", expr):
            return None
    try:
        value = eval(expr, {"__builtins__": {}}, {"clog2": lambda n: (int(n) - 1).bit_length()})
    except Exception:
        return None
    if isinstance(value, int):
        return value
    return None


def evaluate_config_values(constexpr_items: list[dict[str, Any]], define_items: list[dict[str, Any]]) -> dict[str, int]:
    raw: dict[str, str] = {}
    for item in define_items + constexpr_items:
        raw[item["name"]] = item["value"]
    values: dict[str, int] = {}
    for _ in range(8):
        changed = False
        for name, expr in raw.items():
            if name in values:
                continue
            value = try_eval_config_expr(expr, values)
            if value is not None:
                values[name] = value
                changed = True
        if not changed:
            break
    return values


def find_matching_brace(text: str, open_index: int) -> int:
    depth = 0
    for idx in range(open_index, len(text)):
        char = text[idx]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return idx
    return -1


def split_field_names(names: str) -> list[str]:
    cleaned = names.split("=")[0].strip()
    parts = [part.strip() for part in cleaned.split(",")]
    found = []
    for part in parts:
        part = part.replace("*", " ").replace("&", " ")
        match = re.search(r"\b([A-Za-z_]\w*)\b\s*((?:\[[^\]]+\]\s*)*)$", part)
        if match:
            suffix = match.group(2).replace(" ", "")
            found.append(match.group(1) + suffix)
    return found


def parse_struct_fields(body: str) -> list[dict[str, str]]:
    fields = []
    for raw in body.splitlines():
        line = raw.strip()
        if not line or line in {"public:", "private:", "protected:"}:
            continue
        if line.startswith(("//", "#", "using ", "typedef ", "static_assert", "template")):
            continue
        if "(" in line or ")" in line:
            continue
        if not line.endswith(";"):
            continue
        line = line.rstrip(";").strip()
        if line.startswith(("struct ", "class ", "enum ")):
            continue
        match = re.match(r"(.+?)\s+([^;]+)$", line)
        if not match:
            continue
        typ = " ".join(match.group(1).split())
        names = split_field_names(match.group(2))
        for name in names:
            fields.append({"type": typ, "name": name})
    return fields


def scan_cpp_structs(sim_root: Path) -> list[dict[str, Any]]:
    structs: list[dict[str, Any]] = []
    for path in sim_root.rglob("*"):
        if path.suffix.lower() not in {".h", ".hpp", ".cpp", ".cc"}:
            continue
        if any(part in {"build", ".git", "obj_dir"} for part in path.parts):
            continue
        text = read_text(path)
        scan_text = strip_comments(text)
        for match in re.finditer(r"\b(struct|class)\s+([A-Za-z_]\w*)(?:\s*:[^{]+)?\s*\{", scan_text):
            open_index = scan_text.find("{", match.end() - 1)
            close_index = find_matching_brace(scan_text, open_index)
            if close_index < 0:
                continue
            body = scan_text[open_index + 1 : close_index]
            fields = parse_struct_fields(body)
            if not fields:
                continue
            name = match.group(2)
            structs.append(
                {
                    "name": name,
                    "kind": match.group(1),
                    "file": rel(path, sim_root),
                    "line": line_number(scan_text, match.start()),
                    "field_count": len(fields),
                    "fields": fields,
                    "is_interface_like": any(hint in name for hint in KEY_STRUCT_HINTS),
                }
            )
    structs.sort(key=lambda item: (item["file"], item["line"], item["name"]))
    return structs


def scan_functions(sim_root: Path) -> list[dict[str, Any]]:
    functions = []
    pattern = re.compile(
        r"(?:(?:static|inline|constexpr|virtual)\s+)*"
        r"(?:void|bool|int|auto|uint\d+_t|[A-Za-z_]\w*(?:::[A-Za-z_]\w*)?(?:<[^;{}()]*>)?)"
        r"[\s*&]+([A-Za-z_]\w*(?:::[A-Za-z_]\w*)?)\s*\(([^;{}]*)\)\s*(?:const\s*)?(?:\{|;)",
        re.S,
    )
    for path in sim_root.rglob("*"):
        if path.suffix.lower() not in {".h", ".hpp", ".cpp", ".cc"}:
            continue
        if any(part in {"build", ".git", "obj_dir"} for part in path.parts):
            continue
        text = strip_comments(read_text(path))
        for match in pattern.finditer(text):
            name = match.group(1)
            bare = name.split("::")[-1]
            if not any(hint in bare for hint in ENTRY_FUNCTION_HINTS) and "comb" not in bare:
                continue
            args = " ".join(match.group(2).split())
            functions.append(
                {
                    "name": name,
                    "bare_name": bare,
                    "file": rel(path, sim_root),
                    "line": line_number(text, match.start()),
                    "args": args,
                }
            )
    functions.sort(key=lambda item: (item["file"], item["line"], item["name"]))
    return functions


def scan_verilog_modules(rtl_root: Path) -> list[dict[str, Any]]:
    modules = []
    if not rtl_root.exists():
        return modules
    for path in rtl_root.rglob("*.v"):
        text = strip_comments(read_text(path))
        for match in re.finditer(
            r"\bmodule\s+([A-Za-z_]\w*)\s*(?:#\s*\(.*?\)\s*)?\((.*?)\);",
            text,
            flags=re.S,
        ):
            name = match.group(1)
            body = match.group(2)
            ports = []
            for chunk in body.split(","):
                line = " ".join(chunk.strip().split())
                port_match = re.match(
                    r"(input|output|inout)\s+(?:wire|reg|logic)?\s*(\[[^\]]+\])?\s*([A-Za-z_]\w*)$",
                    line,
                )
                if port_match:
                    ports.append(
                        {
                            "direction": port_match.group(1),
                            "width": port_match.group(2) or "1",
                            "name": port_match.group(3),
                        }
                    )
            modules.append(
                {
                    "name": name,
                    "file": rel(path, rtl_root),
                    "line": line_number(text, match.start()),
                    "port_count": len(ports),
                    "inputs": sum(1 for p in ports if p["direction"] == "input"),
                    "outputs": sum(1 for p in ports if p["direction"] == "output"),
                    "ports": ports,
                }
            )
    modules.sort(key=lambda item: (item["file"], item["line"], item["name"]))
    return modules


def md_table(headers: list[str], rows: list[list[Any]]) -> str:
    out = ["| " + " | ".join(headers) + " |", "| " + " | ".join(["---"] * len(headers)) + " |"]
    for row in rows:
        out.append("| " + " | ".join(str(cell).replace("\n", " ") for cell in row) + " |")
    return "\n".join(out)


def display_config_value(item: dict[str, Any]) -> str:
    value = str(item["value"])
    if "evaluated" in item and value != str(item["evaluated"]):
        return f"{value} = {item['evaluated']}"
    return value


def display_direction(direction: str) -> str:
    return {
        "input": "输入",
        "output": "输出",
        "inout": "双向",
    }.get(direction, direction)


def select_key_structs(structs: list[dict[str, Any]]) -> list[dict[str, Any]]:
    preferred_files = ("front_IO.h", "train_IO.h", "include/IO.h", "icache_module.h")
    selected = [
        item
        for item in structs
        if item["is_interface_like"] and any(item["file"].endswith(name) for name in preferred_files)
    ]
    if not selected:
        selected = [item for item in structs if item["is_interface_like"]]
    selected.sort(
        key=lambda item: (
            STRUCT_PRIORITY_NAMES.get(item["name"], 100),
            0 if item["file"].endswith("front_IO.h") else 1 if item["file"].endswith("train_IO.h") else 2,
            item["file"],
            item["line"],
        )
    )
    return selected[:80]


def render_markdown(data: dict[str, Any]) -> str:
    config = data["config"]
    structs = data["cpp_structs"]
    functions = data["functions"]
    verilog_modules = data["verilog_modules"]
    key_structs = select_key_structs(structs)

    lines = [
        "# 模拟器接口扫描报告",
        "",
        f"- 生成时间：`{data['generated_at']}`",
        f"- 模拟器目录：`{data['sim_root']}`",
        f"- RTL/训练包目录：`{data['rtl_root']}`",
        "",
        "## 关键配置",
        "",
    ]
    if config["interesting"]:
        rows = [[item["name"], display_config_value(item), f"{config['path']}:{item['line']}"] for item in config["interesting"]]
        lines.append(md_table(["名称", "取值", "源码位置"], rows))
    else:
        lines.append("未在 `include/config.h` 中找到关键配置。")

    lines += ["", "## 已启用 CONFIG 宏", ""]
    macros = config["enabled_config_macros"][:80]
    if macros:
        lines.append(md_table(["宏", "取值", "源码位置"], [[m["name"], display_config_value(m), f"{config['path']}:{m['line']}"] for m in macros]))
    else:
        lines.append("未找到已启用的 `CONFIG_*` 宏。")

    lines += ["", "## 入口函数与 comb 函数", ""]
    entry_rows = [
        [fn["name"], fn["args"][:140], f"{fn['file']}:{fn['line']}"]
        for fn in functions
        if any(hint in fn["bare_name"] for hint in ENTRY_FUNCTION_HINTS)
    ][:120]
    if entry_rows:
        lines.append(md_table(["函数", "参数", "源码位置"], entry_rows))
    else:
        lines.append("未找到匹配的入口函数或 comb 函数。")

    lines += ["", "## C++ 接口结构体", ""]
    if key_structs:
        lines.append(md_table(["结构体/类", "字段数", "源码位置"], [[s["name"], s["field_count"], f"{s['file']}:{s['line']}"] for s in key_structs]))
        lines.append("")
        lines.append("### 字段明细")
        for struct in key_structs:
            lines += [
                "",
                f"#### `{struct['name']}`",
                "",
                f"源码位置：`{struct['file']}:{struct['line']}`",
                "",
                md_table(["类型", "字段名"], [[field["type"], field["name"]] for field in struct["fields"]]),
            ]
    else:
        lines.append("未找到接口结构体。")

    lines += ["", "## Verilog 模块与端口", ""]
    if verilog_modules:
        lines.append(md_table(["模块", "输入端口数", "输出端口数", "源码位置"], [[m["name"], m["inputs"], m["outputs"], f"{m['file']}:{m['line']}"] for m in verilog_modules]))
        for module in [m for m in verilog_modules if m["name"] in {"front_top", "bpu_top"} or m["name"].endswith("_comb_top")][:80]:
            lines += [
                "",
                f"### `{module['name']}`",
                "",
                f"源码位置：`{module['file']}:{module['line']}`",
                "",
                md_table(["方向", "位宽", "端口名"], [[display_direction(p["direction"]), p["width"], p["name"]] for p in module["ports"]]),
            ]
    else:
        lines.append("未找到 Verilog 模块。")

    lines += [
        "",
        "## 如何喂给 Codex",
        "",
        "当模拟器更新后，先重新运行本脚本，再把 `codex_quick_context.md` 的内容交给 Codex。这样 Codex 能先知道新的配置、接口结构体、入口函数和当前 RTL 端口，再继续更新前端/后端训练包。",
        "",
        "```powershell",
        "python top/tools/scan_simulator_interfaces.py simulator-front",
        "```",
        "",
    ]
    return "\n".join(lines)


def render_codex_context(data: dict[str, Any]) -> str:
    config = data["config"]
    functions = data["functions"]
    key_structs = select_key_structs(data["cpp_structs"])[:30]
    verilog_modules = data["verilog_modules"]
    front_modules = [m for m in verilog_modules if m["name"] == "front_top" or m["name"].endswith("_comb_top")]

    lines = [
        "# Codex 快速上下文：模拟器接口",
        "",
        f"模拟器目录：`{data['sim_root']}`",
        f"RTL/训练包目录：`{data['rtl_root']}`",
        "",
        "## 生效配置",
    ]
    for item in config["interesting"]:
        lines.append(f"- `{item['name']}` = `{display_config_value(item)}`，来源：`{config['path']}:{item['line']}`")

    lines += ["", "## 重要入口函数"]
    for fn in [
        f
        for f in functions
        if f["bare_name"] in {"front_cycle", "step_bpu", "step_oracle", "front_top", "front_seq_read", "front_comb_calc", "front_seq_write"}
    ][:40]:
        lines.append(f"- `{fn['name']}({fn['args']})`，位置：`{fn['file']}:{fn['line']}`")

    lines += ["", "## 需要核对的接口结构体"]
    for struct in key_structs:
        field_names = ", ".join(field["name"] for field in struct["fields"][:30])
        suffix = " ..." if len(struct["fields"]) > 30 else ""
        lines.append(f"- `{struct['name']}`，位置：`{struct['file']}:{struct['line']}`：{field_names}{suffix}")

    lines += ["", "## 当前 RTL 模块"]
    for module in front_modules[:60]:
        lines.append(f"- `{module['name']}`，位置：`{module['file']}:{module['line']}`：{module['inputs']} 个输入，{module['outputs']} 个输出")

    lines += [
        "",
        "## 更新流程",
        "1. 先核对配置宽度是否和 RTL 参数一致。",
        "2. 再核对 C++ 接口结构体是否和 `front_top.v`、`back_top.v`、comb wrapper 端口一致。",
        "3. 上层 `front_top.v`、`bpu_top.v` 使用具名变量端口连接；`*_comb_top` 内部把变量拼成 `pi/po`，最后的 `*_bsd_top` 只保留 `.pi(pi)`、`.po(po)`。",
        "4. 每次模拟器更新后都重新生成本上下文。",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    script_path = Path(__file__).resolve()
    top_root = script_path.parents[1]
    workspace_root = top_root.parent

    parser = ChineseArgumentParser(
        description="扫描模拟器 C++/RTL 接口，并生成中文 Markdown 摘要和 JSON 结果。",
        add_help=False,
    )
    parser._positionals.title = "位置参数"
    parser._optionals.title = "可选参数"
    parser.add_argument("-h", "--help", action="help", help="显示帮助信息并退出。")
    parser.add_argument(
        "source",
        nargs="?",
        type=Path,
        metavar="模拟器目录",
        help="模拟器仓库根目录。例如：python scan_simulator_interfaces.py simulator-front...",
    )
    parser.add_argument(
        "--sim-root",
        type=Path,
        default=None,
        metavar="路径",
        help="模拟器仓库根目录。为兼容旧命令保留；优先使用位置参数“模拟器目录”。",
    )
    parser.add_argument(
        "--rtl-root",
        type=Path,
        default=top_root,
        metavar="路径",
        help="要扫描的 RTL/训练包根目录，默认是 top/。",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=top_root / "docs" / "generated",
        metavar="路径",
        help="输出目录。",
    )
    parser.add_argument(
        "--json-name",
        default="simulator_interface_scan.json",
        metavar="文件名",
        help="JSON 输出文件名。",
    )
    parser.add_argument(
        "--md-name",
        default="simulator_interface_scan.md",
        metavar="文件名",
        help="完整 Markdown 扫描报告文件名。",
    )
    parser.add_argument(
        "--context-name",
        default="codex_quick_context.md",
        metavar="文件名",
        help="给 Codex 使用的精简上下文文件名。",
    )
    args = parser.parse_args()

    sim_root = (args.sim_root or args.source or auto_find_sim_root(workspace_root)).resolve()
    rtl_root = args.rtl_root.resolve()
    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    data = {
        "generated_at": _dt.datetime.now().isoformat(timespec="seconds"),
        "sim_root": rel(sim_root, workspace_root),
        "rtl_root": rel(rtl_root, workspace_root),
        "config": scan_config(sim_root),
        "cpp_structs": scan_cpp_structs(sim_root),
        "functions": scan_functions(sim_root),
        "verilog_modules": scan_verilog_modules(rtl_root),
    }

    json_path = out_dir / args.json_name
    md_path = out_dir / args.md_name
    context_path = out_dir / args.context_name

    json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(data), encoding="utf-8")
    context_path.write_text(render_codex_context(data), encoding="utf-8")

    print(f"已写入 {json_path}")
    print(f"已写入 {md_path}")
    print(f"已写入 {context_path}")
    print(
        "扫描摘要："
        f"{len(data['config']['interesting'])} 个关键配置，"
        f"{len(data['cpp_structs'])} 个 C++ struct/class，"
        f"{len(data['functions'])} 个函数，"
        f"{len(data['verilog_modules'])} 个 Verilog module。"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
