#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成后端 RTL 端口自查 Markdown。

默认可在仓库任意目录运行：
    python top/tools/scan_backend_ports.py

本脚本直接扫描 top/back_end 下的 Verilog 文件，汇总每个 *_top
和对应 *_bsd_top 的参数、端口和 top -> bsd_top 关系。
"""

from __future__ import annotations

import argparse
import datetime as dt
import math
import re
from dataclasses import dataclass
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]

MODULE_ORDER = [
    "back_top",
    "preiduqueue_top",
    "idu_top",
    "ren_top",
    "dispatch_top",
    "rob_top",
    "isu_top",
    "prf_top",
    "exu_top",
    "lsu_top",
    "csr_top",
]


@dataclass
class Parameter:
    name: str
    expr: str
    value: int | None


@dataclass
class Port:
    direction: str
    width_expr: str
    width_value: int | None
    name: str


@dataclass
class ModuleInfo:
    name: str
    path: Path
    line: int
    parameters: list[Parameter]
    ports: list[Port]


@dataclass
class BsdLink:
    module_name: str
    instance_name: str
    defined: bool


def resolve_repo_path(path_text: str | None, default_path: Path) -> Path:
    if not path_text:
        return default_path.resolve()
    path = Path(path_text)
    if path.is_absolute():
        return path.resolve()
    cwd_path = (Path.cwd() / path).resolve()
    if cwd_path.exists():
        return cwd_path
    return (REPO_ROOT / path).resolve()


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*?$", "", text, flags=re.M)


def line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def find_matching(text: str, open_index: int) -> int:
    depth = 0
    for index in range(open_index, len(text)):
        if text[index] == "(":
            depth += 1
        elif text[index] == ")":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("找不到匹配的右括号")


def split_top_level(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    paren = 0
    bracket = 0
    brace = 0
    for index, char in enumerate(text):
        if char == "(":
            paren += 1
        elif char == ")":
            paren -= 1
        elif char == "[":
            bracket += 1
        elif char == "]":
            bracket -= 1
        elif char == "{":
            brace += 1
        elif char == "}":
            brace -= 1
        elif char == "," and paren == 0 and bracket == 0 and brace == 0:
            part = text[start:index].strip()
            if part:
                parts.append(part)
            start = index + 1
    tail = text[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def eval_expr(expr: str, values: dict[str, int]) -> int | None:
    expr = expr.strip()
    expr = re.sub(r"\bparameter\b", "", expr)
    expr = re.sub(r"\binteger\b", "", expr)
    expr = re.sub(r"([0-9]+)\s*'[bdhBDH][0-9a-fA-F_xXzZ]+", r"\1", expr)
    expr = re.sub(r"([0-9]+)\s*[uUlL]+", r"\1", expr)

    def clog2(value: int) -> int:
        if value <= 1:
            return 0
        return int(math.ceil(math.log2(value)))

    names = dict(values)
    names.update({"clog2": clog2})
    try:
        return int(eval(expr, {"__builtins__": {}}, names))
    except Exception:
        return None


def parse_parameters(block: str) -> tuple[list[Parameter], dict[str, int]]:
    params: list[Parameter] = []
    values: dict[str, int] = {}
    for item in split_top_level(block):
        item = " ".join(item.split())
        match = re.match(r"parameter\s+(?:integer\s+)?([A-Za-z_]\w*)\s*=\s*(.+)$", item)
        if not match:
            continue
        name = match.group(1)
        expr = match.group(2).strip()
        value = eval_expr(expr, values)
        if value is not None:
            values[name] = value
        params.append(Parameter(name=name, expr=expr, value=value))
    return params, values


def parse_width(width_text: str, values: dict[str, int]) -> tuple[str, int | None]:
    width_text = width_text.strip()
    if not width_text:
        return "1", 1
    match = re.match(r"\[(.+):(.+)\]", width_text)
    if not match:
        return width_text, None
    left = match.group(1).strip()
    right = match.group(2).strip()
    left_value = eval_expr(left, values)
    right_value = eval_expr(right, values)
    if left_value is None or right_value is None:
        return width_text, None
    return width_text, abs(left_value - right_value) + 1


def parse_ports(block: str, values: dict[str, int]) -> list[Port]:
    ports: list[Port] = []
    current_direction = ""
    current_width = ""
    current_width_value: int | None = None
    for raw in split_top_level(block):
        item = " ".join(raw.split())
        if not item:
            continue
        match = re.match(r"(input|output|inout)\s+(?:wire|reg|logic)?\s*(\[[^\]]+\])?\s*(.+)$", item)
        if match:
            current_direction = match.group(1)
            current_width, current_width_value = parse_width(match.group(2) or "", values)
            names = match.group(3)
        else:
            names = item
        for name in re.split(r"\s+", names.strip()):
            name = name.strip()
            if not name or name in {"wire", "reg", "logic"}:
                continue
            name = name.rstrip(",")
            if re.match(r"^[A-Za-z_]\w*$", name):
                ports.append(Port(
                    direction=current_direction,
                    width_expr=current_width,
                    width_value=current_width_value,
                    name=name,
                ))
    return ports


def parse_modules(path: Path, root: Path) -> list[ModuleInfo]:
    raw = path.read_text(encoding="utf-8", errors="ignore")
    text = strip_comments(raw)
    modules: list[ModuleInfo] = []
    for match in re.finditer(r"\bmodule\s+([A-Za-z_]\w*)", text):
        name = match.group(1)
        index = match.end()
        while index < len(text) and text[index].isspace():
            index += 1
        param_block = ""
        if index < len(text) and text[index] == "#":
            open_index = text.find("(", index)
            close_index = find_matching(text, open_index)
            param_block = text[open_index + 1:close_index]
            index = close_index + 1
        while index < len(text) and text[index].isspace():
            index += 1
        if index >= len(text) or text[index] != "(":
            continue
        port_close = find_matching(text, index)
        port_block = text[index + 1:port_close]
        params, values = parse_parameters(param_block)
        ports = parse_ports(port_block, values)
        modules.append(ModuleInfo(
            name=name,
            path=path.resolve().relative_to(root.resolve()),
            line=line_number(text, match.start()),
            parameters=params,
            ports=ports,
        ))
    return modules


def find_bsd_link(module: ModuleInfo, modules: dict[str, ModuleInfo], back_dir: Path) -> BsdLink | None:
    if module.name == "back_top":
        return None
    expected = module.name.replace("_top", "_bsd_top")
    source = (back_dir / module.path).read_text(encoding="utf-8", errors="ignore")
    instance_match = re.search(rf"\b({re.escape(expected)})\s*#?\s*\(", source)
    if instance_match:
        inst_match = re.search(rf"\b{re.escape(expected)}\s*(?:#\s*\([^;]*?\)\s*)?([A-Za-z_]\w*)\s*\(", source, flags=re.S)
        instance_name = inst_match.group(1) if inst_match else ""
        return BsdLink(module_name=expected, instance_name=instance_name, defined=expected in modules)
    return None


def width_text(port: Port) -> str:
    if port.width_value is not None:
        return f"{port.width_value} bit"
    return port.width_expr


def total_width(ports: list[Port]) -> str:
    if any(port.width_value is None for port in ports):
        return "存在表达式未求值"
    return f"{sum(port.width_value or 0 for port in ports)} bit"


def port_rows(ports: list[Port]) -> list[str]:
    if not ports:
        return ["//   无"]
    name_width = max(len(port.name) for port in ports)
    width_expr_width = max(len(port.width_expr) for port in ports)
    out: list[str] = []
    for port in ports:
        out.append(f"//   {port.name:<{name_width}}  {port.width_expr:<{width_expr_width}}  {width_text(port)}")
    return out


def param_rows(parameters: list[Parameter]) -> list[str]:
    if not parameters:
        return ["//   无"]
    name_width = max(len(param.name) for param in parameters)
    out: list[str] = []
    for param in parameters:
        value_text = str(param.value) if param.value is not None else "未求值"
        out.append(f"//   {param.name:<{name_width}} = {param.expr}  // {value_text}")
    return out


def generate_backend_markdown(back_dir: Path, out_path: Path) -> None:
    modules: dict[str, ModuleInfo] = {}
    for path in sorted(back_dir.rglob("*.v")):
        for module in parse_modules(path, back_dir):
            modules[module.name] = module

    top_names = [name for name in MODULE_ORDER if name in modules]
    top_names.extend(sorted(
        name for name in modules
        if name.endswith("_top") and not name.endswith("_bsd_top") and name not in top_names
    ))

    lines: list[str] = []
    lines.append("# 后端端口自查汇总\n")
    lines.append(f"- 生成时间：{dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"- RTL 目录：`{back_dir.as_posix()}`")
    lines.append("- 范围：`back_top` 与后端一级 `*_top`，并列出对应 `*_bsd_top` 的 `pi/po` 端口。")
    lines.append("- 说明：本文件由 RTL module 声明直接生成，用于人工核对端口和 top -> bsd_top 关系。\n")

    summary = [["序号", "模块", "输入端口", "输出端口", "对应 BSD", "文件"]]
    for index, name in enumerate(top_names, 1):
        module = modules[name]
        bsd_link = find_bsd_link(module, modules, back_dir)
        if bsd_link:
            state = "已定义" if bsd_link.defined else "未提供定义"
            bsd_text = f"`{bsd_link.module_name}` / {state}"
        else:
            bsd_text = "-"
        summary.append([
            str(index),
            f"`{name}`",
            str(sum(1 for port in module.ports if port.direction == "input")),
            str(sum(1 for port in module.ports if port.direction == "output")),
            bsd_text,
            f"`{module.path}:{module.line}`",
        ])
    lines.append("## 总览\n")
    lines.append(markdown_table(summary))
    lines.append("\n## 逐模块自查\n")

    for index, name in enumerate(top_names, 1):
        module = modules[name]
        bsd_link = find_bsd_link(module, modules, back_dir)
        bsd = modules.get(bsd_link.module_name) if bsd_link and bsd_link.defined else None
        inputs = [port for port in module.ports if port.direction == "input"]
        outputs = [port for port in module.ports if port.direction == "output"]

        lines.append(f"### {index:02d}. `{name}`\n")
        lines.append("```verilog")
        lines.append("// -----------------------------------------------------------------------------")
        lines.append("// 后端端口自查")
        lines.append(f"// 模块：{name}")
        lines.append(f"// 文件：{module.path}:{module.line}")
        if bsd_link:
            defined_text = "仓库内已有定义" if bsd_link.defined else "当前仓库未提供定义"
            inst_text = f"，实例名 {bsd_link.instance_name}" if bsd_link.instance_name else ""
            lines.append(f"// BSD 层：{bsd_link.module_name}{inst_text}，{defined_text}")
        else:
            lines.append("// BSD 层：无直接 bsd_top")
        lines.append("// 来源：当前 back_end RTL module 声明")
        lines.append("//")
        lines.append(f"// 输入端口：{len(inputs)} 个，合计 {total_width(inputs)}")
        lines.append(f"// 输出端口：{len(outputs)} 个，合计 {total_width(outputs)}")
        lines.append("//")
        lines.append("// 参数：")
        lines.extend(param_rows(module.parameters))
        lines.append("//")
        lines.append("// 输入端口：")
        lines.extend(port_rows(inputs))
        lines.append("//")
        lines.append("// 输出端口：")
        lines.extend(port_rows(outputs))
        if bsd:
            bsd_inputs = [port for port in bsd.ports if port.direction == "input"]
            bsd_outputs = [port for port in bsd.ports if port.direction == "output"]
            lines.append("//")
            lines.append(f"// BSD 层端口：{bsd.name}")
            lines.append(f"//   输入合计 {total_width(bsd_inputs)}，输出合计 {total_width(bsd_outputs)}")
            lines.append("//   BSD 输入：")
            lines.extend(port_rows(bsd_inputs))
            lines.append("//   BSD 输出：")
            lines.extend(port_rows(bsd_outputs))
        elif bsd_link:
            lines.append("//")
            lines.append("// BSD 层端口：当前仓库只实例化该 bsd_top，未提供 module 定义。")
            lines.append("//   后续组员补 bsd_top 时，应保持实例名和 pi/po 连接一致。")
        lines.append("// -----------------------------------------------------------------------------")
        lines.append("```\n")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def markdown_table(rows: list[list[str]]) -> str:
    widths = [max(len(row[index]) for row in rows) for index in range(len(rows[0]))]
    out = []
    out.append("| " + " | ".join(rows[0][index].ljust(widths[index]) for index in range(len(widths))) + " |")
    out.append("| " + " | ".join("-" * widths[index] for index in range(len(widths))) + " |")
    for row in rows[1:]:
        out.append("| " + " | ".join(row[index].ljust(widths[index]) for index in range(len(widths))) + " |")
    return "\n".join(out)


def main() -> None:
    parser = argparse.ArgumentParser(description="生成后端 RTL 端口自查 Markdown")
    parser.add_argument("--back-dir", default=None, help="back_end 目录，默认 top/back_end")
    parser.add_argument("--out", default=None, help="输出 Markdown，默认 top/back_end/后端端口自查汇总.md")
    args = parser.parse_args()

    back_dir = resolve_repo_path(args.back_dir, REPO_ROOT / "top" / "back_end")
    out_path = resolve_repo_path(args.out, back_dir / "后端端口自查汇总.md")
    generate_backend_markdown(back_dir, out_path)
    print(f"已生成后端端口自查汇总：{out_path}")


if __name__ == "__main__":
    main()
