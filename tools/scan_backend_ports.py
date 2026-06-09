#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
扫描后端 RTL 端口，生成中文自查表，并可把自查注释写回每个 *_top.v。

默认使用 ffc 模拟器 large 配置：
    python top/tools/scan_backend_ports.py

生成汇总并回写 RTL 注释：
    python top/tools/scan_backend_ports.py --annotate-rtl
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

CONTROL_PORTS = {"clk", "rst_n"}

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

BUS_WIDTH_PARAMS = {
    "preiduqueue_top": ("W_PreIduQueueIn", "W_PreIduQueueOut"),
    "idu_top": ("W_IduIn", "W_IduOut"),
    "ren_top": ("W_RenIn", "W_RenOut"),
    "dispatch_top": ("W_DisIn", "W_DisOut"),
    "rob_top": ("W_RobIn", "W_RobOut"),
    "isu_top": ("W_IsuIn", "W_IsuOut"),
    "prf_top": ("W_PrfIn", "W_PrfOut"),
    "exu_top": ("W_ExuIn", "W_ExuOut"),
    "lsu_top": ("W_LsuIn", "W_LsuOut"),
    "csr_top": ("W_CsrIn", "W_CsrOut"),
}

SOURCE_HINTS = {
    "back_top": "simulator-ffc/back-end/include/BackTop.h, simulator-ffc/back-end/BackTop.cpp",
    "preiduqueue_top": "simulator-ffc/back-end/include/PreIduQueue.h, simulator-ffc/back-end/PreIduQueue.cpp, simulator-ffc/back-end/include/IO.h",
    "idu_top": "simulator-ffc/back-end/include/Idu.h, simulator-ffc/back-end/Idu.cpp, simulator-ffc/back-end/include/IO.h",
    "ren_top": "simulator-ffc/back-end/include/Ren.h, simulator-ffc/back-end/Ren.cpp, simulator-ffc/back-end/include/IO.h",
    "dispatch_top": "simulator-ffc/back-end/include/Dispatch.h, simulator-ffc/back-end/Dispatch.cpp, simulator-ffc/back-end/include/IO.h",
    "rob_top": "simulator-ffc/back-end/include/Rob.h, simulator-ffc/back-end/Rob.cpp, simulator-ffc/back-end/include/IO.h",
    "isu_top": "simulator-ffc/back-end/include/Isu.h, simulator-ffc/back-end/Isu.cpp, simulator-ffc/back-end/include/IO.h",
    "prf_top": "simulator-ffc/back-end/include/Prf.h, simulator-ffc/back-end/Prf.cpp, simulator-ffc/back-end/include/IO.h",
    "exu_top": "simulator-ffc/back-end/Exu/include/Exu.h, simulator-ffc/back-end/Exu/Exu.cpp, simulator-ffc/back-end/include/IO.h",
    "lsu_top": "simulator-ffc/back-end/Lsu/include/RealLsu.h, simulator-ffc/back-end/Lsu/RealLsu.cpp, simulator-ffc/back-end/include/IO.h",
    "csr_top": "simulator-ffc/back-end/Exu/include/Csr.h, simulator-ffc/back-end/Exu/Csr.cpp, simulator-ffc/back-end/include/IO.h",
}

FFC_LARGE_EXPECTED = {
    "FETCH_WIDTH": 16,
    "DECODE_WIDTH": 8,
    "COMMIT_WIDTH": 8,
    "AREG_IDX_WIDTH": 6,
    "PRF_IDX_WIDTH": 9,
    "ROB_IDX_WIDTH": 9,
    "STQ_IDX_WIDTH": 6,
    "LDQ_IDX_WIDTH": 6,
    "BR_TAG_WIDTH": 6,
    "BR_MASK_WIDTH": 64,
    "CSR_IDX_WIDTH": 12,
    "FTQ_IDX_WIDTH": 7,
    "FTQ_OFFSET_WIDTH": 4,
    "IQ_READY_NUM_WIDTH": 8,
    "MAX_WAKEUP_PORTS": 11,
    "ISSUE_WIDTH": 15,
    "TOTAL_FU_COUNT": 19,
    "FTQ_EXU_PC_PORT_NUM": 8,
    "FTQ_ROB_PC_PORT_NUM": 1,
    "ROB_NUM": 512,
    "LSU_LDU_COUNT": 3,
    "LSU_STA_COUNT": 2,
    "LSU_AGU_COUNT": 5,
    "LSU_SDU_COUNT": 2,
    "LSU_LOAD_WB_WIDTH": 3,
    "LSU_LDU_WIDTH": 2,
    "W_STQ_COUNT": 7,
    "W_LDQ_COUNT": 7,
}

PARAM_NOTES = {
    "FTQ_EXU_PC_PORT_NUM": "ffc large 中由 ALU_NUM + BRU_NUM 得到。",
    "TOTAL_FU_COUNT": "由 ffc large 的 GLOBAL_ISSUE_PORT_CONFIG 按 major FU mask 展开得到。",
    "IQ_READY_NUM_WIDTH": "来自 bit_width_for_count(MAX_IQ_SIZE + 1)，large 下 MAX_IQ_SIZE=128。",
}


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
    pi_fields: list[str]
    po_fields: list[str]


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


def find_matching(text: str, open_index: int, left: str = "(", right: str = ")") -> int:
    depth = 0
    for index in range(open_index, len(text)):
        char = text[index]
        if char == left:
            depth += 1
        elif char == right:
            depth -= 1
            if depth == 0:
                return index
    raise ValueError(f"找不到匹配的 {right}")


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
    expr = re.sub(r"([0-9]+)\s*'[bBoOdDhH][0-9a-fA-F_xXzZ]+", r"\1", expr)
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
    current_width = "1"
    current_width_value: int | None = 1
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
            name = name.strip().rstrip(",")
            if not name or name in {"wire", "reg", "logic"}:
                continue
            if re.match(r"^[A-Za-z_]\w*$", name):
                ports.append(
                    Port(
                        direction=current_direction,
                        width_expr=current_width,
                        width_value=current_width_value,
                        name=name,
                    )
                )
    return ports


def parse_concat_names(text: str) -> list[str]:
    names: list[str] = []
    for item in split_top_level(text):
        item = item.strip()
        if re.match(r"^[A-Za-z_]\w*$", item):
            names.append(item)
    return names


def parse_pi_po_fields(raw_text: str) -> tuple[list[str], list[str]]:
    clean = strip_comments(raw_text)
    pi_fields: list[str] = []
    po_fields: list[str] = []

    # 逐条 assign 语句识别，避免从前面的拆包语句一直跨到后面的 = po。
    for statement in clean.split(";"):
        statement = statement.strip()
        pi_match = re.match(r"assign\s+pi\s*=\s*\{(.*)\}\s*$", statement, flags=re.S)
        if pi_match:
            pi_fields = parse_concat_names(pi_match.group(1))
            continue

        po_match = re.match(r"assign\s*\{(.*)\}\s*=\s*po\s*$", statement, flags=re.S)
        if po_match:
            po_fields = parse_concat_names(po_match.group(1))

    return pi_fields, po_fields


def parse_modules(path: Path, root: Path) -> list[ModuleInfo]:
    raw = path.read_text(encoding="utf-8", errors="ignore")
    clean = strip_comments(raw)
    pi_fields, po_fields = parse_pi_po_fields(raw)
    modules: list[ModuleInfo] = []
    for match in re.finditer(r"\bmodule\s+([A-Za-z_]\w*)", clean):
        name = match.group(1)
        index = match.end()
        while index < len(clean) and clean[index].isspace():
            index += 1
        param_block = ""
        if index < len(clean) and clean[index] == "#":
            open_index = clean.find("(", index)
            close_index = find_matching(clean, open_index)
            param_block = clean[open_index + 1 : close_index]
            index = close_index + 1
        while index < len(clean) and clean[index].isspace():
            index += 1
        if index >= len(clean) or clean[index] != "(":
            continue
        port_close = find_matching(clean, index)
        port_block = clean[index + 1 : port_close]
        params, values = parse_parameters(param_block)
        ports = parse_ports(port_block, values)
        modules.append(
            ModuleInfo(
                name=name,
                path=path.resolve().relative_to(root.resolve()),
                line=line_number(clean, match.start()),
                parameters=params,
                ports=ports,
                pi_fields=pi_fields,
                po_fields=po_fields,
            )
        )
    return modules


def load_modules(back_dir: Path) -> dict[str, ModuleInfo]:
    modules: dict[str, ModuleInfo] = {}
    for path in sorted(back_dir.rglob("*.v")):
        for module in parse_modules(path, back_dir):
            modules[module.name] = module
    return modules


def ordered_top_names(modules: dict[str, ModuleInfo]) -> list[str]:
    top_names = [name for name in MODULE_ORDER if name in modules]
    top_names.extend(
        sorted(
            name
            for name in modules
            if name.endswith("_top")
            and not name.endswith("_bsd_top")
            and name not in top_names
        )
    )
    return top_names


def param_dict(module: ModuleInfo) -> dict[str, Parameter]:
    return {param.name: param for param in module.parameters}


def port_dict(module: ModuleInfo) -> dict[str, Port]:
    return {port.name: port for port in module.ports}


def width_text(value: int | None, expr: str | None = None) -> str:
    if value is not None:
        return f"{value} bit"
    return expr or "未求值"


def total_width_value(ports: list[Port]) -> int | None:
    if any(port.width_value is None for port in ports):
        return None
    return sum(port.width_value or 0 for port in ports)


def port_rows(ports: list[Port]) -> list[str]:
    if not ports:
        return ["//   无"]
    name_width = max(len(port.name) for port in ports)
    expr_width = max(len(port.width_expr) for port in ports)
    return [
        f"//   {port.name:<{name_width}}  {port.width_expr:<{expr_width}}  {width_text(port.width_value)}"
        for port in ports
    ]


def field_rows(module: ModuleInfo, fields: list[str]) -> list[str]:
    if not fields:
        return ["//   未在当前文件中识别到 pi/po 拼接字段"]
    ports = port_dict(module)
    rows: list[str] = []
    field_width = max(len(name) for name in fields)
    for name in fields:
        port = ports.get(name)
        if port:
            rows.append(f"//   {name:<{field_width}}  {width_text(port.width_value, port.width_expr)}")
        else:
            rows.append(f"//   {name:<{field_width}}  内部信号，见本文件拆包/拼接")
    return rows


def find_bsd_link(module: ModuleInfo, back_dir: Path) -> tuple[str, str] | None:
    if module.name == "back_top":
        return None
    expected = module.name.replace("_top", "_bsd_top")
    source = (back_dir / module.path).read_text(encoding="utf-8", errors="ignore")
    inst_match = re.search(
        rf"\b{re.escape(expected)}\s*(?:#\s*\(.*?\)\s*)?([A-Za-z_]\w*)\s*\(",
        source,
        flags=re.S,
    )
    if not inst_match:
        return None
    return expected, inst_match.group(1)


def control_ports(module: ModuleInfo) -> list[Port]:
    return [port for port in module.ports if port.name in CONTROL_PORTS]


def data_inputs(module: ModuleInfo) -> list[Port]:
    return [port for port in module.ports if port.direction == "input" and port.name not in CONTROL_PORTS]


def data_outputs(module: ModuleInfo) -> list[Port]:
    return [port for port in module.ports if port.direction == "output"]


def bus_width(module: ModuleInfo, param_name: str | None) -> int | None:
    if not param_name:
        return None
    param = param_dict(module).get(param_name)
    return param.value if param else None


def param_check_rows(module: ModuleInfo) -> list[str]:
    params = param_dict(module)
    rows: list[str] = []
    for name, expected in FFC_LARGE_EXPECTED.items():
        if name not in params:
            continue
        actual = params[name].value
        state = "OK" if actual == expected else "不一致"
        note = PARAM_NOTES.get(name, "")
        rows.append(f"//   {name:<24} 实际 {actual!s:<6} 期望 {expected:<6} {state} {note}".rstrip())
    if not rows:
        return ["//   无直接 large 配置参数"]
    return rows


def make_audit_comment(module: ModuleInfo, back_dir: Path, source_root: Path) -> str:
    params = param_dict(module)
    input_param, output_param = BUS_WIDTH_PARAMS.get(module.name, (None, None))
    in_width = bus_width(module, input_param)
    out_width = bus_width(module, output_param)
    bsd_link = find_bsd_link(module, back_dir)
    extra_outputs = [
        port
        for port in data_outputs(module)
        if module.po_fields and port.name not in set(module.po_fields)
    ]

    lines: list[str] = []
    lines.append("// -----------------------------------------------------------------------------")
    lines.append("// 后端端口自查")
    lines.append(f"// 模块: {module.name}")
    lines.append(f"// RTL 文件: {module.path.as_posix()}:{module.line}")
    lines.append(f"// 模拟器版本: {source_root.name}")
    lines.append("// 配置: ffc large")
    lines.append(f"// 源码依据: {SOURCE_HINTS.get(module.name, 'simulator-ffc/back-end/include/IO.h')}")
    if bsd_link:
        lines.append(f"// BSD 层: {bsd_link[0]}，实例名 {bsd_link[1]}")
    else:
        lines.append("// BSD 层: 无直接 bsd_top")
    lines.append("//")
    lines.append("// large 配置关键参数核对:")
    lines.extend(param_check_rows(module))
    lines.append("//")
    if input_param and output_param:
        lines.append(
            f"// BSD 业务接口: {input_param}({width_text(in_width)}) -> "
            f"{output_param}({width_text(out_width)})"
        )
        lines.append("// 控制端口 clk/rst_n 单独连接，不计入业务 pi/po 位宽。")
    else:
        lines.append(
            f"// 顶层数据端口: 输入 {width_text(total_width_value(data_inputs(module)))}，"
            f"输出 {width_text(total_width_value(data_outputs(module)))}"
        )
    lines.append("//")
    lines.append("// 控制端口:")
    lines.extend(port_rows(control_ports(module)))
    lines.append("//")
    lines.append("// 输入端口:")
    lines.extend(port_rows(data_inputs(module)))
    lines.append("//")
    lines.append("// 输出端口:")
    lines.extend(port_rows(data_outputs(module)))
    if module.pi_fields:
        lines.append("//")
        lines.append("// pi 拼接顺序:")
        lines.extend(field_rows(module, module.pi_fields))
    if module.po_fields:
        lines.append("//")
        lines.append("// po 拆分顺序:")
        lines.extend(field_rows(module, module.po_fields))
    if extra_outputs:
        lines.append("//")
        lines.append("// 额外展开输出: 这些信号由 po 中字段再拆出来，方便 back_top 连线，不计入 bsd_po。")
        lines.extend(port_rows(extra_outputs))
    lines.append("// -----------------------------------------------------------------------------")
    return "\n".join(lines)


def markdown_table(rows: list[list[str]]) -> str:
    widths = [max(len(row[index]) for row in rows) for index in range(len(rows[0]))]
    lines: list[str] = []
    lines.append("| " + " | ".join(rows[0][index].ljust(widths[index]) for index in range(len(widths))) + " |")
    lines.append("| " + " | ".join("-" * widths[index] for index in range(len(widths))) + " |")
    for row in rows[1:]:
        lines.append("| " + " | ".join(row[index].ljust(widths[index]) for index in range(len(widths))) + " |")
    return "\n".join(lines)


def config_check_markdown(modules: dict[str, ModuleInfo]) -> str:
    rows = [["模块", "参数", "实际", "期望", "结论"]]
    for name in ordered_top_names(modules):
        module = modules[name]
        params = param_dict(module)
        for pname, expected in FFC_LARGE_EXPECTED.items():
            if pname not in params:
                continue
            actual = params[pname].value
            rows.append([
                f"`{name}`",
                f"`{pname}`",
                str(actual),
                str(expected),
                "OK" if actual == expected else "不一致",
            ])
    return markdown_table(rows)


def generate_backend_markdown(back_dir: Path, out_path: Path, source_root: Path, modules: dict[str, ModuleInfo]) -> None:
    top_names = ordered_top_names(modules)
    lines: list[str] = []
    lines.append("# 后端端口自查汇总\n")
    lines.append(f"- 生成时间：{dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"- RTL 目录：`{back_dir.as_posix()}`")
    lines.append(f"- 模拟器依据：`{source_root.as_posix()}`")
    lines.append("- 配置：`large`，依据 `include/config.h.large`。")
    lines.append("- 统计口径：`clk/rst_n` 作为控制端口单独列出，不计入业务 `pi/po` 位宽。")
    lines.append("- 说明：`*_top` 是可读连接层，`*_bsd_top` 是待接入或外部提供的业务实现层。\n")
    lines.append("## BSD 接入契约\n")
    lines.append("- 后端 wrapper 统一例化 `*_bsd_top`，端口名约定为 `clk/rst_n/pi/po`。")
    lines.append("- `pi/po` 只承载业务打包总线；`clk/rst_n` 是控制端口，不进入位宽统计。")
    lines.append("- 如果综合网表端口名是 `din/dout`、`pi_ext/po_ext` 等，需要改成该契约或额外加一层适配壳。\n")

    summary = [["序号", "模块", "BSD 输入", "BSD 输出", "控制端口", "pi 字段", "po 字段", "RTL 文件"]]
    for index, name in enumerate(top_names, 1):
        module = modules[name]
        input_param, output_param = BUS_WIDTH_PARAMS.get(name, (None, None))
        in_width = bus_width(module, input_param)
        out_width = bus_width(module, output_param)
        summary.append(
            [
                str(index),
                f"`{name}`",
                f"`{input_param}` = {width_text(in_width)}" if input_param else width_text(total_width_value(data_inputs(module))),
                f"`{output_param}` = {width_text(out_width)}" if output_param else width_text(total_width_value(data_outputs(module))),
                ", ".join(port.name for port in control_ports(module)) or "-",
                str(len(module.pi_fields)) if module.pi_fields else "-",
                str(len(module.po_fields)) if module.po_fields else "-",
                f"`{module.path.as_posix()}:{module.line}`",
            ]
        )

    lines.append("## 总览\n")
    lines.append(markdown_table(summary))
    lines.append("\n## large 参数交叉核对\n")
    lines.append(config_check_markdown(modules))
    lines.append("\n## 逐模块端口明细\n")

    for index, name in enumerate(top_names, 1):
        module = modules[name]
        lines.append(f"### {index:02d}. `{name}`\n")
        lines.append("```verilog")
        lines.append(make_audit_comment(module, back_dir, source_root))
        lines.append("```\n")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def remove_audit_blocks(text: str) -> str:
    block_re = re.compile(
        r"// -----------------------------------------------------------------------------\n"
        r".*?"
        r"// -----------------------------------------------------------------------------\n+",
        flags=re.S,
    )

    def keep_or_drop(match: re.Match[str]) -> str:
        block = match.group(0)
        audit_markers = (
            "端口自查",
            "绔",
            "鍚",
            "业务接口",
            "BSD 层",
            "bsd_top",
        )
        if any(marker in block for marker in audit_markers):
            return ""
        return block

    return block_re.sub(keep_or_drop, text)


def annotate_backend_rtl(back_dir: Path, source_root: Path, modules: dict[str, ModuleInfo]) -> int:
    changed = 0
    for name in ordered_top_names(modules):
        module = modules[name]
        path = back_dir / module.path
        text = path.read_text(encoding="utf-8", errors="ignore")
        text = remove_audit_blocks(text)
        module_match = re.search(rf"(?m)^module\s+{re.escape(name)}\b", text)
        if not module_match:
            continue
        comment = make_audit_comment(module, back_dir, source_root) + "\n\n"
        new_text = text[: module_match.start()] + comment + text[module_match.start() :]
        if new_text != path.read_text(encoding="utf-8", errors="ignore"):
            path.write_text(new_text, encoding="utf-8", newline="\n")
            changed += 1
    return changed


def main() -> None:
    parser = argparse.ArgumentParser(description="生成后端 RTL 端口自查 Markdown")
    parser.add_argument("--back-dir", default=None, help="back_end 目录，默认 top/back_end")
    parser.add_argument(
        "--source",
        default="simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0",
        help="后端依据的 ffc 模拟器目录",
    )
    parser.add_argument("--profile", default="large", choices=["large"], help="配置档，当前固定支持 large")
    parser.add_argument("--out", default=None, help="输出 Markdown，默认 top/back_end/后端端口自查汇总.md")
    parser.add_argument("--annotate-rtl", action="store_true", help="把端口自查注释写回每个后端 *_top.v")
    args = parser.parse_args()

    back_dir = resolve_repo_path(args.back_dir, REPO_ROOT / "top" / "back_end")
    source_root = resolve_repo_path(args.source, REPO_ROOT / args.source)
    out_path = resolve_repo_path(args.out, back_dir / "后端端口自查汇总.md")

    modules = load_modules(back_dir)
    changed = 0
    if args.annotate_rtl:
        changed = annotate_backend_rtl(back_dir, source_root, modules)
        modules = load_modules(back_dir)

    generate_backend_markdown(back_dir, out_path, source_root, modules)
    print(f"已生成后端端口自查汇总：{out_path}")
    if args.annotate_rtl:
        print(f"已回写 RTL 自查注释：{changed} 个文件")


if __name__ == "__main__":
    main()
