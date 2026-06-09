#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Static back_top equivalence evaluator.

This script checks the connection-level contract between:
  1. simulator-ffc BackTop.cpp / BackTop.h / IO.h
  2. top/back_end/back_top.v and backend *_top.v wrappers

It is intentionally static.  It does not prove the internal behavior of any
*_bsd_top implementation; it verifies that the Verilog shell exposes and wires
the same first-level backend graph expected by the C++ simulator.
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
from dataclasses import dataclass
from pathlib import Path

from scan_backend_ports import (
    BUS_WIDTH_PARAMS,
    MODULE_ORDER,
    Port,
    bus_width,
    data_inputs,
    data_outputs,
    find_matching,
    load_modules,
    port_dict,
    resolve_repo_path,
    split_top_level,
    strip_comments,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]


CPP_TO_RTL = {
    "pre": ("preiduqueue_top", "pre"),
    "idu": ("idu_top", "idu"),
    "rename": ("ren_top", "rename"),
    "dis": ("dispatch_top", "dispatch"),
    "isu": ("isu_top", "isu"),
    "prf": ("prf_top", "prf"),
    "exu": ("exu_top", "exu"),
    "rob": ("rob_top", "rob"),
    "csr": ("csr_top", "csr"),
    "lsu": ("lsu_top", "lsu"),
}


SIGNAL_ALIASES = {
    "in": "front2pre",
    "idu->br_latch": "idu_br_latch",
}

CPP_FIELD_PORT_OVERRIDES = {
    ("lsu", "peripheral_resp"): "peripheral_resp",
    ("lsu", "dcache2lsu"): "dcache2lsu",
    ("lsu", "peripheral_req"): "peripheral_req",
    ("lsu", "lsu2dcache"): "lsu2dcache",
}


EXPLAINED_EXTRA_PORTS = {
    "pre": {
        "pre2front_fire": "pre2front.fire 字段展开给 back_top.fire",
        "pre2front_ready": "pre2front.ready 字段展开给 back_top.stall",
    },
    "idu": {
        "idu_br_latch": "Idu::br_latch 是 C++ 对象状态，不在 IduOut 结构体内；RTL 需要展开为 idu_top 输出再接给 preiduqueue_top",
        "dec_bcast_mispred": "dec_bcast 字段展开给 back_top.mispred",
        "dec_bcast_br_mask": "dec_bcast 字段调试展开，顶层当前未使用",
        "dec_bcast_br_id": "dec_bcast 字段调试展开，顶层当前未使用",
        "dec_bcast_redirect_rob_idx": "dec_bcast 字段调试展开，顶层当前未使用",
        "dec_bcast_clear_mask": "dec_bcast 字段调试展开，顶层当前未使用",
        "idu_br_latch_mispred": "idu.br_latch 字段调试展开，顶层当前未使用",
        "idu_br_latch_redirect_pc": "idu.br_latch.redirect_pc 展开给 back_top.redirect_pc",
        "idu_br_latch_redirect_rob_idx": "idu.br_latch 字段调试展开，顶层当前未使用",
        "idu_br_latch_br_id": "idu.br_latch 字段调试展开，顶层当前未使用",
        "idu_br_latch_ftq_idx": "idu.br_latch 字段调试展开，顶层当前未使用",
        "idu_br_latch_clear_mask": "idu.br_latch 字段调试展开，顶层当前未使用",
    },
    "rob": {
        "rob_bcast_flush": "rob_bcast.flush 展开给 back_top.flush/mispred/redirect",
        "rob_bcast_mret": "rob_bcast.mret 展开给 flush redirect 选择",
        "rob_bcast_sret": "rob_bcast.sret 展开给 flush redirect 选择",
        "rob_bcast_ecall": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_exception": "rob_bcast.exception 展开给 flush redirect 选择",
        "rob_bcast_fence": "rob_bcast.fence 展开给 back_top.itlb_flush",
        "rob_bcast_fence_i": "rob_bcast.fence_i 展开给 back_top.fence_i",
        "rob_bcast_page_fault_inst": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_page_fault_load": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_page_fault_store": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_illegal_inst": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_interrupt": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_trap_val": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_pc": "rob_bcast.pc 展开给 flush redirect pc+4",
        "rob_bcast_head_rob_idx": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_head_valid": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_head_incomplete_rob_idx": "rob_bcast 字段调试展开，顶层当前未使用",
        "rob_bcast_head_incomplete_valid": "rob_bcast 字段调试展开，顶层当前未使用",
    },
    "csr": {
        "csr2front_epc": "csr2front.epc 展开给 flush redirect 选择",
        "csr2front_trap_pc": "csr2front.trap_pc 展开给 flush redirect 选择",
        "csr_status_sstatus": "csr_status.sstatus 展开给 back_top.sstatus",
        "csr_status_mstatus": "csr_status.mstatus 展开给 back_top.mstatus",
        "csr_status_satp": "csr_status.satp 展开给 back_top.satp",
        "csr_status_privilege": "csr_status.privilege 展开给 back_top.privilege",
    },
    "exu": {
        "csr_status": "ExuIn 声明了 csr_status；ffc BackTop::init 当前未绑定，RTL 额外接入",
    },
    "lsu": {
        "mmu2lsu_io": "RTL 将 LSU/MMU 交互外置；ffc RealLsu 内部持有 mmu 对象",
        "lsu2mmu_io": "RTL 将 LSU/MMU 交互外置；ffc RealLsu 内部持有 mmu 对象",
    },
}


FRONTPRE_FIELDS = {
    "inst",
    "pc",
    "valid",
    "predict_dir",
    "alt_pred",
    "altpcpn",
    "pcpn",
    "predict_next_fetch_address",
    "tage_idx",
    "tage_tag",
    "sc_used",
    "sc_pred",
    "sc_sum",
    "sc_idx",
    "loop_used",
    "loop_hit",
    "loop_pred",
    "loop_idx",
    "loop_tag",
    "page_fault_inst",
}


@dataclass(frozen=True)
class CppConnection:
    cpp_object: str
    rtl_module: str
    rtl_instance: str
    direction: str
    cpp_field: str
    cpp_target: str
    expected_port: str
    expected_net: str


@dataclass
class RtlInstance:
    module_name: str
    instance_name: str
    connections: dict[str, str]


@dataclass
class CheckResult:
    level: str
    item: str
    detail: str


@dataclass(frozen=True)
class ScheduleInfo:
    cycle_calls: list[str]
    back_comb_calls: list[str]
    back_seq_calls: list[str]
    back_comb_output_stage_seen: bool
    cycle_tail_state_seen: bool


def normalize_space(text: str) -> str:
    return " ".join(text.strip().split())


def normalize_signal(target: str) -> str:
    target = target.strip()
    return SIGNAL_ALIASES.get(target, target.replace("->", "_"))


def markdown_table(rows: list[list[str]]) -> str:
    if not rows:
        return ""
    widths = [max(len(row[idx]) for row in rows) for idx in range(len(rows[0]))]
    lines = [
        "| " + " | ".join(rows[0][idx].ljust(widths[idx]) for idx in range(len(widths))) + " |",
        "| " + " | ".join("-" * widths[idx] for idx in range(len(widths))) + " |",
    ]
    for row in rows[1:]:
        lines.append("| " + " | ".join(row[idx].ljust(widths[idx]) for idx in range(len(widths))) + " |")
    return "\n".join(lines)


def extract_function_body(text: str, pattern: str) -> str:
    match = re.search(pattern, text)
    if not match:
        raise ValueError(f"找不到函数: {pattern}")
    open_index = text.find("{", match.end() - 1)
    if open_index < 0:
        raise ValueError(f"找不到函数体开始: {pattern}")
    close_index = find_matching(text, open_index, "{", "}")
    return text[open_index + 1 : close_index]


def parse_cpp_backtop_connections(backtop_cpp: Path) -> list[CppConnection]:
    body = extract_function_body(
        backtop_cpp.read_text(encoding="utf-8", errors="ignore"),
        r"\bvoid\s+BackTop::init\s*\(\s*\)",
    )
    pattern = re.compile(
        r"\b(?P<object>[A-Za-z_]\w*)->(?P<direction>in|out)\."
        r"(?P<field>[A-Za-z_]\w*)\s*=\s*&(?P<target>(?:[A-Za-z_]\w*->)?[A-Za-z_]\w*)\s*;"
    )

    connections: list[CppConnection] = []
    seen: set[tuple[str, str, str]] = set()
    for match in pattern.finditer(body):
        cpp_object = match.group("object")
        if cpp_object not in CPP_TO_RTL:
            continue
        rtl_module, rtl_instance = CPP_TO_RTL[cpp_object]
        target = match.group("target")
        expected_net = normalize_signal(target)
        cpp_field = match.group("field")
        expected_port = CPP_FIELD_PORT_OVERRIDES.get((cpp_object, cpp_field), expected_net)
        key = (rtl_instance, match.group("direction"), expected_net)
        if key in seen:
            continue
        seen.add(key)
        connections.append(
            CppConnection(
                cpp_object=cpp_object,
                rtl_module=rtl_module,
                rtl_instance=rtl_instance,
                direction=match.group("direction"),
                cpp_field=cpp_field,
                cpp_target=target,
                expected_port=expected_port,
                expected_net=expected_net,
            )
        )
    return connections


def parse_cycle_body(rv_simu_cpp: Path) -> str:
    return extract_function_body(
        rv_simu_cpp.read_text(encoding="utf-8", errors="ignore"),
        r"\bvoid\s+SimCpu::cycle\s*\(\s*\)",
    )


def parse_cycle_calls(cycle_body: str) -> list[str]:
    call_re = re.compile(
        r"\b("
        r"back\.comb_csr_status|clear_axi_master_inputs|front_cycle|back\.comb|"
        r"mem_subsystem\.llc_comb_outputs|axi_interconnect\.set_llc_lookup_in|"
        r"axi_ddr\.comb_outputs|axi_mmio\.comb_outputs|axi_router\.comb_outputs|"
        r"axi_interconnect\.comb_outputs|bridge_axi_to_mem_subsystem|"
        r"mem_subsystem\.comb|bridge_mem_subsystem_to_axi|"
        r"axi_interconnect\.comb_inputs|axi_router\.comb_inputs|"
        r"axi_ddr\.comb_inputs|axi_mmio\.comb_inputs|back2front_comb|"
        r"back\.seq|mem_subsystem\.seq|mem_subsystem\.llc_seq|"
        r"axi_interconnect\.seq|axi_router\.seq|axi_ddr\.seq|axi_mmio\.seq"
        r")\s*\("
    )
    return [match.group(1) for match in call_re.finditer(cycle_body)]


def parse_backtop_schedule(backtop_cpp: Path, rv_simu_cpp: Path) -> ScheduleInfo:
    text = backtop_cpp.read_text(encoding="utf-8", errors="ignore")
    cycle_body = parse_cycle_body(rv_simu_cpp)
    comb_body = extract_function_body(text, r"\bvoid\s+BackTop::comb\s*\(\s*\)")
    seq_body = extract_function_body(text, r"\bvoid\s+BackTop::seq\s*\(\s*\)")

    comb_calls = [
        f"{match.group(1)}->{match.group(2)}"
        for match in re.finditer(r"\b(pre|idu|rename|dis|isu|prf|exu|rob|csr|lsu)->([A-Za-z_]\w*)\s*\(", comb_body)
    ]
    seq_calls = [
        f"{match.group(1)}->seq"
        for match in re.finditer(r"\b(pre|idu|rename|dis|isu|prf|exu|rob|csr|lsu)->seq\s*\(", seq_body)
    ]
    return ScheduleInfo(
        cycle_calls=parse_cycle_calls(cycle_body),
        back_comb_calls=comb_calls,
        back_seq_calls=seq_calls,
        back_comb_output_stage_seen=all(
            needle in comb_body
            for needle in (
                "out.flush = rob->out.rob_bcast->flush",
                "out.stall = !pre2front.ready",
                "out.redirect_pc = idu->br_latch.redirect_pc",
                "out.commit_entry[i]",
            )
        ),
        cycle_tail_state_seen=all(
            needle in cycle_body
            for needle in (
                "back.number_PC = back.out.redirect_pc",
                "back.in.valid[j] = false",
            )
        ),
    )


def check_schedule_surface(back_dir: Path, schedule: ScheduleInfo) -> list[CheckResult]:
    results: list[CheckResult] = []
    backtop_text = (back_dir / "back_top.v").read_text(encoding="utf-8", errors="ignore")
    clean = strip_comments(backtop_text)

    if not schedule.cycle_calls:
        results.append(CheckResult("ERROR", "SimCpu::cycle", "未能抽取每拍顶层调用顺序"))
    else:
        expected_prefix = ["back.comb_csr_status", "clear_axi_master_inputs", "front_cycle", "back.comb"]
        if schedule.cycle_calls[:4] != expected_prefix:
            results.append(
                CheckResult(
                    "ERROR",
                    "SimCpu::cycle",
                    f"每拍前四步不是期望顺序 {expected_prefix}，实际 {schedule.cycle_calls[:4]}",
                )
            )

    if not schedule.back_comb_calls:
        results.append(CheckResult("ERROR", "BackTop::comb", "未能抽取后端组合调用顺序"))
    else:
        first_calls = schedule.back_comb_calls[:10]
        expected_begin = [
            "pre->comb_begin",
            "idu->comb_begin",
            "rename->comb_begin",
            "dis->comb_begin",
            "isu->comb_begin",
            "prf->comb_begin",
            "exu->comb_begin",
            "rob->comb_begin",
            "csr->comb_begin",
            "pre->comb_accept_front",
        ]
        if first_calls != expected_begin:
            results.append(
                CheckResult(
                    "ERROR",
                    "BackTop::comb order",
                    f"组合入口前缀不一致，期望 {expected_begin}，实际 {first_calls}",
                )
            )

    expected_seq = [
        "pre->seq",
        "rename->seq",
        "dis->seq",
        "idu->seq",
        "isu->seq",
        "exu->seq",
        "prf->seq",
        "rob->seq",
        "csr->seq",
        "lsu->seq",
    ]
    if schedule.back_seq_calls != expected_seq:
        results.append(
            CheckResult(
                "ERROR",
                "BackTop::seq order",
                f"seq 顺序不一致，期望 {expected_seq}，实际 {schedule.back_seq_calls}",
            )
        )

    if schedule.back_comb_output_stage_seen:
        results.append(CheckResult("OK", "BackTop::comb outputs", "识别到 flush/stall/redirect_pc/commit_entry 的 C++ 输出组装阶段"))
    else:
        results.append(CheckResult("ERROR", "BackTop::comb outputs", "未完整识别 C++ Back_out 输出组装阶段"))

    if schedule.cycle_tail_state_seen:
        results.append(
            CheckResult(
                "WARN",
                "SimCpu::cycle tail state",
                "识别到 back.seq() 之后仍会按 back.out 更新 back.number_PC，stall 时还会清 back.in.valid[j]；这属于外层 CPU 周期语义，不在 back_top.v 单体连线内",
            )
        )
    else:
        results.append(CheckResult("ERROR", "SimCpu::cycle tail state", "未识别 cycle 尾部 back.number_PC/back.in.valid 更新"))

    if re.search(r"\balways\b", clean):
        results.append(CheckResult("INFO", "RTL timing", "back_top.v 含 always 块，需要人工确认是否对应 BackTop::seq 顺序"))
    else:
        results.append(
            CheckResult(
                "WARN",
                "RTL timing",
                "back_top.v 是结构连线壳，只有实例和连续赋值；它本身不表达 BackTop::comb() 的串行调用顺序，也不表达 BackTop::seq() 的模块更新顺序",
            )
        )

    return results


def parse_named_connections(block: str) -> dict[str, str]:
    connections: dict[str, str] = {}
    for match in re.finditer(r"\.([A-Za-z_]\w*)\s*\(", block):
        port = match.group(1)
        open_index = block.find("(", match.end() - 1)
        close_index = find_matching(block, open_index)
        connections[port] = normalize_space(block[open_index + 1 : close_index])
    return connections


def parse_rtl_instances(backtop_v: Path) -> dict[str, RtlInstance]:
    raw = backtop_v.read_text(encoding="utf-8", errors="ignore")
    clean = strip_comments(raw)
    instances: dict[str, RtlInstance] = {}
    wanted_modules = {module for module, _ in CPP_TO_RTL.values()}

    for module_name in wanted_modules:
        for match in re.finditer(rf"\b{re.escape(module_name)}\b", clean):
            index = match.end()
            while index < len(clean) and clean[index].isspace():
                index += 1
            if index < len(clean) and clean[index] == "#":
                param_open = clean.find("(", index)
                param_close = find_matching(clean, param_open)
                index = param_close + 1
            while index < len(clean) and clean[index].isspace():
                index += 1
            inst_match = re.match(r"([A-Za-z_]\w*)", clean[index:])
            if not inst_match:
                continue
            instance_name = inst_match.group(1)
            index += inst_match.end()
            while index < len(clean) and clean[index].isspace():
                index += 1
            if index >= len(clean) or clean[index] != "(":
                continue
            conn_close = find_matching(clean, index)
            conn_block = clean[index + 1 : conn_close]
            instances[instance_name] = RtlInstance(
                module_name=module_name,
                instance_name=instance_name,
                connections=parse_named_connections(conn_block),
            )
    return instances


def parse_concat_assignment(raw_text: str, lhs: str) -> list[str]:
    clean = strip_comments(raw_text)
    escaped_lhs = re.escape(lhs)
    for statement in clean.split(";"):
        statement = statement.strip()
        match = re.match(rf"assign\s+{escaped_lhs}\s*=\s*\{{(.*)\}}\s*$", statement, flags=re.S)
        if match:
            names: list[str] = []
            for item in split_top_level(match.group(1)):
                item = item.strip()
                if re.match(r"^[A-Za-z_]\w*$", item):
                    names.append(item)
            return names
    return []


def parse_struct_field_order(header: Path, struct_name: str) -> list[str]:
    text = strip_comments(header.read_text(encoding="utf-8", errors="ignore"))
    match = re.search(rf"\bstruct\s+{re.escape(struct_name)}\b", text)
    if not match:
        raise ValueError(f"找不到 struct {struct_name}: {header}")
    open_index = text.find("{", match.end())
    close_index = find_matching(text, open_index, "{", "}")
    body = text[open_index + 1 : close_index]
    fields: list[str] = []
    for statement in body.split(";"):
        statement = normalize_space(statement)
        if not statement or "(" in statement:
            continue
        name_match = re.search(r"\b([A-Za-z_]\w*)\s*(?:\[[^\]]+\])*(?:\s*=\s*nullptr)?$", statement)
        if not name_match:
            continue
        name = name_match.group(1)
        if name in FRONTPRE_FIELDS:
            fields.append(name)
    return fields


def sum_field_widths(module_ports: dict[str, Port], fields: list[str]) -> int | None:
    total = 0
    for field in fields:
        port = module_ports.get(field)
        if not port or port.width_value is None:
            return None
        total += port.width_value
    return total


def compare_cpp_and_rtl(
    cpp_connections: list[CppConnection],
    rtl_instances: dict[str, RtlInstance],
) -> list[CheckResult]:
    results: list[CheckResult] = []
    expected_by_instance: dict[str, set[str]] = {}

    for conn in cpp_connections:
        expected_by_instance.setdefault(conn.rtl_instance, set()).add(conn.expected_port)
        inst = rtl_instances.get(conn.rtl_instance)
        if not inst:
            results.append(
                CheckResult("ERROR", f"{conn.rtl_instance}", "RTL 中找不到该 C++ 对应实例")
            )
            continue
        actual_net = inst.connections.get(conn.expected_port)
        if actual_net is None:
            results.append(
                CheckResult(
                    "ERROR",
                    f"{conn.rtl_instance}.{conn.expected_port}",
                    f"C++ {conn.cpp_object}->{conn.direction}.{conn.cpp_field}=&{conn.cpp_target}，RTL 缺少端口连接",
                )
            )
        elif actual_net != conn.expected_net:
            results.append(
                CheckResult(
                    "ERROR",
                    f"{conn.rtl_instance}.{conn.expected_port}",
                    f"C++ 期望连接 {conn.expected_net}，RTL 实际连接 {actual_net}",
                )
            )

    for instance_name, inst in sorted(rtl_instances.items()):
        expected_ports = expected_by_instance.get(instance_name, set())
        for port, net in sorted(inst.connections.items()):
            if port in {"clk", "rst_n"} or port in expected_ports:
                continue
            reason = EXPLAINED_EXTRA_PORTS.get(instance_name, {}).get(port)
            if reason:
                level = "WARN" if instance_name in {"exu", "lsu"} else "INFO"
                results.append(CheckResult(level, f"{instance_name}.{port}", reason + f"；RTL net={net}"))
            else:
                results.append(
                    CheckResult(
                        "ERROR",
                        f"{instance_name}.{port}",
                        f"该 RTL 端口不在 BackTop::init 指针图中，且没有登记为顶层字段展开；RTL net={net}",
                    )
                )

    if not any(result.level == "ERROR" for result in results):
        results.append(
            CheckResult(
                "OK",
                "C++ init graph",
                f"{len(cpp_connections)} 条 BackTop::init 指针连接均在 back_top.v 中找到同名 net 连接",
            )
        )
    return results


def check_wrapper_pi_po(back_dir: Path) -> list[CheckResult]:
    modules = load_modules(back_dir)
    results: list[CheckResult] = []

    for name in MODULE_ORDER:
        if name == "back_top" or name not in modules:
            continue
        module = modules[name]
        ports = port_dict(module)
        input_param, output_param = BUS_WIDTH_PARAMS.get(name, (None, None))

        data_input_names = [port.name for port in data_inputs(module)]
        if module.pi_fields != data_input_names:
            results.append(
                CheckResult(
                    "ERROR",
                    f"{name}.pi",
                    f"pi 拼接顺序 {module.pi_fields} 与模块输入端口顺序 {data_input_names} 不一致",
                )
            )

        pi_width = sum_field_widths(ports, module.pi_fields)
        expected_pi_width = bus_width(module, input_param)
        if pi_width != expected_pi_width:
            results.append(
                CheckResult(
                    "ERROR",
                    f"{name}.pi_width",
                    f"pi 字段合计 {pi_width} bit，参数 {input_param}={expected_pi_width} bit",
                )
            )

        for field in module.po_fields:
            if field not in ports:
                results.append(CheckResult("ERROR", f"{name}.po", f"po 字段 {field} 不是模块端口"))

        po_width = sum_field_widths(ports, module.po_fields)
        expected_po_width = bus_width(module, output_param)
        if po_width != expected_po_width:
            results.append(
                CheckResult(
                    "ERROR",
                    f"{name}.po_width",
                    f"po 字段合计 {po_width} bit，参数 {output_param}={expected_po_width} bit",
                )
            )

        raw = (back_dir / module.path).read_text(encoding="utf-8", errors="ignore")
        expected_bsd = name.replace("_top", "_bsd_top")
        if not re.search(rf"\b{re.escape(expected_bsd)}\b", strip_comments(raw)):
            results.append(CheckResult("ERROR", f"{name}.bsd", f"未找到 {expected_bsd} 实例"))

    if not any(result.level == "ERROR" for result in results):
        checked = len([name for name in MODULE_ORDER if name != "back_top" and name in modules])
        results.append(CheckResult("OK", "BSD wrappers", f"{checked} 个后端 wrapper 的 pi/po 顺序和位宽检查通过"))
    return results


def check_frontpre_pack(backtop_v: Path, io_h: Path) -> list[CheckResult]:
    rtl_fields = parse_concat_assignment(backtop_v.read_text(encoding="utf-8", errors="ignore"), "front2pre")
    cpp_fields = parse_struct_field_order(io_h, "FrontPreIO")
    expected = [f"front2pre_{name}" for name in cpp_fields]
    if rtl_fields == expected:
        return [CheckResult("OK", "FrontPreIO pack", "back_top.v 的 front2pre 拼接顺序与 IO.h::FrontPreIO 字段顺序一致")]
    return [
        CheckResult(
            "ERROR",
            "FrontPreIO pack",
            f"RTL 拼接顺序 {rtl_fields}，C++ 字段期望 {expected}",
        )
    ]


def make_report(
    out_path: Path,
    back_dir: Path,
    source_root: Path,
    cpp_connections: list[CppConnection],
    schedule: ScheduleInfo,
    results: list[CheckResult],
) -> None:
    counts = {
        "ERROR": sum(1 for result in results if result.level == "ERROR"),
        "WARN": sum(1 for result in results if result.level == "WARN"),
        "INFO": sum(1 for result in results if result.level == "INFO"),
        "OK": sum(1 for result in results if result.level == "OK"),
    }
    status = "静态结构通过，动态等价未证明" if counts["ERROR"] == 0 else "不通过"

    lines: list[str] = []
    lines.append("# back_top .v / C++ 静态等价评测\n")
    lines.append(f"- 生成时间：{dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"- RTL 目录：`{back_dir.as_posix()}`")
    lines.append(f"- C++ 依据：`{source_root.as_posix()}`")
    lines.append("- 范围：一级 back_top 连线、FrontPreIO 顶层打包、各后端 `*_top -> *_bsd_top` 的 `pi/po` 顺序与位宽、C++ 每拍调度顺序抽取。")
    lines.append("- 边界：这是静态评测，不执行 `*_bsd_top` 内部功能，不替代后续 C++/Verilog 动态 cosim。")
    lines.append("- 正确口径：`BackTop::init()` 只看连线；`SimCpu::cycle()`、`BackTop::comb()`、`BackTop::seq()` 才决定每拍行为和输出时机。\n")

    lines.append("## 结论\n")
    lines.append(markdown_table([
        ["项目", "结果"],
        ["总状态", status],
        ["ERROR", str(counts["ERROR"])],
        ["WARN", str(counts["WARN"])],
        ["INFO", str(counts["INFO"])],
        ["BackTop::init 连接数", str(len(cpp_connections))],
        ["BackTop::comb 调用数", str(len(schedule.back_comb_calls))],
        ["BackTop::seq 调用数", str(len(schedule.back_seq_calls))],
    ]))

    lines.append("\n## 每拍调度依据\n")
    lines.append("### SimCpu::cycle\n")
    rows = [["序号", "调用"]]
    for index, call in enumerate(schedule.cycle_calls, 1):
        rows.append([str(index), f"`{call}()`"])
    lines.append(markdown_table(rows))

    lines.append("\n### BackTop::comb\n")
    rows = [["序号", "调用"]]
    for index, call in enumerate(schedule.back_comb_calls, 1):
        rows.append([str(index), f"`{call}()`"])
    lines.append(markdown_table(rows))

    lines.append("\n### BackTop::seq\n")
    rows = [["序号", "调用"]]
    for index, call in enumerate(schedule.back_seq_calls, 1):
        rows.append([str(index), f"`{call}()`"])
    lines.append(markdown_table(rows))

    lines.append("\n## C++ init 指针图\n")
    rows = [["C++ 对象", "方向", "字段", "C++ 目标", "RTL 实例端口"]]
    for conn in cpp_connections:
        rows.append([
            conn.cpp_object,
            conn.direction,
            conn.cpp_field,
            conn.cpp_target,
            f"{conn.rtl_instance}.{conn.expected_port}({conn.expected_net})",
        ])
    lines.append(markdown_table(rows))

    lines.append("\n## 检查明细\n")
    rows = [["等级", "项目", "说明"]]
    for result in results:
        rows.append([result.level, f"`{result.item}`", result.detail])
    lines.append(markdown_table(rows))

    lines.append("\n## 使用口径\n")
    lines.append("- `OK`：本检查项未发现静态连线问题。")
    lines.append("- `INFO`：额外展开端口，用于 back_top 输出或调试，不改变传给 BSD 的 `pi/po` 业务总线。")
    lines.append("- `WARN`：RTL 相对 `BackTop::init` 有额外外置接口或额外输入，评测脚本不直接判错，但需要在后续功能 cosim 中覆盖。")
    lines.append("- `ERROR`：静态连线或打包顺序不一致，应优先修正。")
    lines.append("- 只有当动态 harness 按 `SimCpu::cycle()` 相同相位比较 `Back_out`、LSU/DCache/MMU/peripheral 端口和跨拍状态时，才能宣称功能等价。")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="评测 back_top.v 与 simulator-ffc BackTop C++ 的静态连线等价性")
    parser.add_argument("--back-dir", default=None, help="默认 top/back_end")
    parser.add_argument("--source", default="simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0", help="simulator-ffc 目录")
    parser.add_argument("--out", default=None, help="默认 top/back_end/back_top_static_equivalence_report.md")
    args = parser.parse_args()

    back_dir = resolve_repo_path(args.back_dir, REPO_ROOT / "top" / "back_end")
    source_root = resolve_repo_path(args.source, REPO_ROOT / args.source)
    out_path = resolve_repo_path(args.out, back_dir / "back_top_static_equivalence_report.md")

    backtop_cpp = source_root / "back-end" / "BackTop.cpp"
    rv_simu_cpp = source_root / "rv_simu_mmu_v2.cpp"
    io_h = source_root / "back-end" / "include" / "IO.h"
    backtop_v = back_dir / "back_top.v"

    cpp_connections = parse_cpp_backtop_connections(backtop_cpp)
    schedule = parse_backtop_schedule(backtop_cpp, rv_simu_cpp)
    rtl_instances = parse_rtl_instances(backtop_v)

    results: list[CheckResult] = []
    results.extend(check_schedule_surface(back_dir, schedule))
    results.extend(compare_cpp_and_rtl(cpp_connections, rtl_instances))
    results.extend(check_wrapper_pi_po(back_dir))
    results.extend(check_frontpre_pack(backtop_v, io_h))

    make_report(out_path, back_dir, source_root, cpp_connections, schedule, results)

    error_count = sum(1 for result in results if result.level == "ERROR")
    warn_count = sum(1 for result in results if result.level == "WARN")
    print(f"已生成 back_top 静态等价评测报告：{out_path}")
    print(f"ERROR={error_count}, WARN={warn_count}")
    return 1 if error_count else 0


if __name__ == "__main__":
    raise SystemExit(main())
