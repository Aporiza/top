#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 simulator-front 源码扫描前端 27 个正式 comb 的端口位宽。

用法：
    python top/tools/scan_frontend_comb_ports.py simulator-front
    python top/tools/scan_frontend_comb_ports.py simulator-front --annotate-rtl top/front_end

输出：
    top/front_end/port_width_audit/README.md
    top/front_end/port_width_audit/details/*.md

说明：
    - 只依赖 Python 标准库。
    - 按 simulator-front 当前默认 large 配置计算。
    - 优先使用类型自己的 *_BITS 常量；例如 tage_reset_ctr_t 和
      tage_path_hist_t 虽然 using 到 wire32_t，但实际宽度分别按
      tage_reset_ctr_t_BITS、tage_path_hist_t_BITS 计算。
"""

from __future__ import annotations

import argparse
import datetime as dt
import math
import re
import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Field:
    name: str
    type_name: str
    dims: list[str]
    source: str
    line: int
    context: str


@dataclass
class StructDef:
    name: str
    fields: list[Field]
    source: str
    line: int
    context: str


@dataclass
class ModuleSpec:
    name: str
    in_type: str
    out_type: str
    source_note: str


MODULES: list[ModuleSpec] = [
    ModuleSpec("fetch_address_FIFO_comb", "FetchAddrCombIn", "FetchAddrCombOut", "train_IO.h / fifo/fetch_address_FIFO.cpp"),
    ModuleSpec("instruction_FIFO_comb", "InstructionCombIn", "InstructionCombOut", "train_IO.h / fifo/instruction_FIFO.cpp"),
    ModuleSpec("PTAB_comb", "PtabCombIn", "PtabCombOut", "train_IO.h / PTAB.cpp"),
    ModuleSpec("front2back_FIFO_comb", "Front2BackCombIn", "Front2BackCombOut", "train_IO.h / fifo/front2back_FIFO.cpp"),
    ModuleSpec("predecode_comb", "PredecodeCombIn", "PredecodeCombOut", "train_IO.h / predecode.cpp"),
    ModuleSpec("predecode_checker_comb", "PredecodeCheckerCombIn", "PredecodeCheckerCombOut", "train_IO.h / predecode_checker.cpp"),
    ModuleSpec("type_predictor_pre_read_comb", "TypePredPreReadCombIn", "TypePredPreReadCombOut", "train_IO.h / BPU/type_predictor"),
    ModuleSpec("type_pred_comb", "TypePredCombIn", "TypePredCombOut", "train_IO.h / BPU/type_predictor"),
    ModuleSpec("tage_pre_read_comb", "TagePreReadCombIn", "TagePreReadCombOut", "train_IO.h / BPU/dir_predictor/TAGE_top.h"),
    ModuleSpec("tage_comb", "TageCombIn", "TageCombOut", "train_IO.h / BPU/dir_predictor/TAGE_top.h"),
    ModuleSpec("btb_pre_read_comb", "BtbPreReadCombIn", "BtbPreReadCombOut", "train_IO.h / BPU/target_predictor/BTB_top.h"),
    ModuleSpec("btb_post_read_req_comb", "BTB_TOP::BtbPostReadReqCombIn", "BTB_TOP::BtbPostReadReqCombOut", "BPU/target_predictor/BTB_top.h"),
    ModuleSpec("btb_comb", "BtbCombIn", "BtbCombOut", "train_IO.h / BPU/target_predictor/BTB_top.h"),
    ModuleSpec("bpu_pre_read_req_comb", "BpuPreReadReqCombIn", "BpuPreReadReqCombOut", "train_IO.h / BPU/BPU.h"),
    ModuleSpec("bpu_post_read_req_comb", "BpuPostReadReqCombIn", "BpuPostReadReqCombOut", "train_IO.h / BPU/BPU.h"),
    ModuleSpec("bpu_submodule_bind_comb", "BpuSubmoduleBindCombIn", "BpuSubmoduleBindCombOut", "train_IO.h / BPU/BPU.h"),
    ModuleSpec("bpu_predict_main_comb", "BpuPredictMainCombIn", "BpuPredictMainCombOut", "train_IO.h / BPU/BPU.h"),
    ModuleSpec("bpu_hist_comb", "BpuHistCombIn", "BpuHistCombOut", "train_IO.h / BPU/BPU.h"),
    ModuleSpec("bpu_queue_comb", "BpuQueueCombIn", "BpuQueueCombOut", "train_IO.h / BPU/BPU.h"),
    ModuleSpec("front_global_control_comb", "FrontGlobalControlCombIn", "FrontGlobalControlCombOut", "train_IO.h / front_top.cpp"),
    ModuleSpec("front_read_enable_comb", "FrontReadEnableCombIn", "FrontReadEnableCombOut", "train_IO.h / front_top.cpp"),
    ModuleSpec("front_read_stage_input_comb", "FrontReadStageInputCombIn", "FrontReadStageInputCombOut", "train_IO.h / front_top.cpp"),
    ModuleSpec("front_bpu_control_comb", "FrontBpuControlCombIn", "FrontBpuControlCombOut", "train_IO.h / front_top.cpp"),
    ModuleSpec("front_ptab_write_comb", "FrontPtabWriteCombIn", "FrontPtabWriteCombOut", "train_IO.h / front_top.cpp"),
    ModuleSpec("front_checker_input_comb", "FrontCheckerInputCombIn", "FrontCheckerInputCombOut", "train_IO.h / front_top.cpp"),
    ModuleSpec("front_front2back_write_comb", "FrontFront2backWriteCombIn", "FrontFront2backWriteCombOut", "train_IO.h / front_top.cpp"),
    ModuleSpec("front_output_comb", "FrontOutputCombIn", "FrontOutputCombOut", "train_IO.h / front_top.cpp"),
]


RTL_FILES: dict[str, str] = {
    "fetch_address_FIFO_comb": "fifo/fetch_address_FIFO_comb/fetch_address_FIFO_comb_top.v",
    "instruction_FIFO_comb": "fifo/instruction_FIFO_comb/instruction_FIFO_comb_top.v",
    "PTAB_comb": "fifo/PTAB_comb/PTAB_comb_top.v",
    "front2back_FIFO_comb": "fifo/front2back_FIFO_comb/front2back_FIFO_comb_top.v",
    "predecode_comb": "predecode/predecode_comb/predecode_comb_top.v",
    "predecode_checker_comb": "predecode_checker/predecode_checker_comb/predecode_checker_comb_top.v",
    "type_predictor_pre_read_comb": "bpu/type_predictor/type_predictor_pre_read_comb/type_predictor_pre_read_comb_top.v",
    "type_pred_comb": "bpu/type_predictor/type_pred_comb/type_pred_comb_top.v",
    "tage_pre_read_comb": "bpu/dir_predictor/tage_pre_read_comb/tage_pre_read_comb_top.v",
    "tage_comb": "bpu/dir_predictor/tage_comb/tage_comb_top.v",
    "btb_pre_read_comb": "bpu/target_predictor/btb_pre_read_comb/btb_pre_read_comb_top.v",
    "btb_post_read_req_comb": "bpu/target_predictor/btb_post_read_req_comb/btb_post_read_req_comb_top.v",
    "btb_comb": "bpu/target_predictor/btb_comb/btb_comb_top.v",
    "bpu_pre_read_req_comb": "bpu/bpu_pre_read_req_comb/bpu_pre_read_req_comb_top.v",
    "bpu_post_read_req_comb": "bpu/bpu_post_read_req_comb/bpu_post_read_req_comb_top.v",
    "bpu_submodule_bind_comb": "bpu/bpu_submodule_bind_comb/bpu_submodule_bind_comb_top.v",
    "bpu_predict_main_comb": "bpu/bpu_predict_main_comb/bpu_predict_main_comb_top.v",
    "bpu_hist_comb": "bpu/bpu_hist_comb/bpu_hist_comb_top.v",
    "bpu_queue_comb": "bpu/bpu_queue_comb/bpu_queue_comb_top.v",
    "front_global_control_comb": "front_top_glue/front_global_control_comb/front_global_control_comb_top.v",
    "front_read_enable_comb": "front_top_glue/front_read_enable_comb/front_read_enable_comb_top.v",
    "front_read_stage_input_comb": "front_top_glue/front_read_stage_input_comb/front_read_stage_input_comb_top.v",
    "front_bpu_control_comb": "front_top_glue/front_bpu_control_comb/front_bpu_control_comb_top.v",
    "front_ptab_write_comb": "front_top_glue/front_ptab_write_comb/front_ptab_write_comb_top.v",
    "front_checker_input_comb": "front_top_glue/front_checker_input_comb/front_checker_input_comb_top.v",
    "front_front2back_write_comb": "front_top_glue/front_front2back_write_comb/front_front2back_write_comb_top.v",
    "front_output_comb": "front_top_glue/front_output_comb/front_output_comb_top.v",
}


class Model:
    def __init__(self, sim_root: Path) -> None:
        self.sim_root = sim_root.resolve()
        self.constants: dict[str, int] = {}
        self.aliases: dict[str, str] = {}
        self.structs: dict[str, StructDef] = {}
        self.type_bits: dict[str, int] = {}
        self._width_stack: list[str] = []

    def rel(self, path: Path) -> str:
        try:
            return path.resolve().relative_to(self.sim_root).as_posix()
        except ValueError:
            return path.resolve().as_posix()

    @staticmethod
    def strip_comments(text: str) -> str:
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
        return re.sub(r"//.*?$", "", text, flags=re.M)

    @staticmethod
    def line_number(text: str, index: int) -> int:
        return text.count("\n", 0, index) + 1

    def load(self) -> None:
        files = sorted((self.sim_root / "front-end").rglob("*.h"))
        files += sorted((self.sim_root / "include").rglob("*.h")) if (self.sim_root / "include").exists() else []
        raw_by_file = {path: path.read_text(encoding="utf-8", errors="ignore") for path in files}
        clean_by_file = {path: self.strip_comments(text) for path, text in raw_by_file.items()}
        self.collect_constants(clean_by_file)
        self.collect_aliases(clean_by_file)
        self.collect_structs(clean_by_file)
        self.build_type_bits()

    def collect_constants(self, clean_by_file: dict[Path, str]) -> None:
        exprs: dict[str, str] = {}
        for text in clean_by_file.values():
            for name, value in re.findall(r"^\s*#define\s+([A-Za-z_]\w*)\s+([^\n/]+)", text, flags=re.M):
                if "(" not in name:
                    exprs.setdefault(name, value.strip())
            for name, value in re.findall(
                r"static\s+constexpr\s+(?:int|unsigned|uint32_t|size_t|auto)\s+([A-Za-z_]\w*)\s*=\s*([^;]+);",
                text,
            ):
                exprs[name] = value.strip()

        changed = True
        while changed:
            changed = False
            for name, expr in exprs.items():
                if name in self.constants:
                    continue
                value = self.eval_expr(expr, allow_unknown=True)
                if value is not None:
                    self.constants[name] = value
                    changed = True

        # simulator-front 的 large/default 关键配置。若源码表达式解析不到，用这里兜底。
        fallback = {
            "FETCH_WIDTH": 16,
            "COMMIT_WIDTH": 8,
            "TN_MAX": 4,
            "BPU_BANK_NUM": 16,
            "TAGE_IDX_WIDTH": 12,
            "TAGE_TAG_WIDTH": 8,
            "TAGE_SC_PATH_BITS": 16,
            "TYPE_PRED_SET_NUM": 2048,
            "PC_BITS": 32,
            "INST_BITS": 32,
            "PCPN_BITS": 3,
            "BR_TYPE_BITS": 3,
            "BPU_SCL_META_NTABLE": 8,
            "BPU_SCL_META_IDX_BITS": 16,
            "BPU_SCL_META_SUM_BITS": 16,
            "BPU_LOOP_META_IDX_BITS": 16,
            "BPU_LOOP_META_TAG_BITS": 16,
            "FETCH_ADDR_FIFO_SIZE": 32,
            "INSTRUCTION_FIFO_SIZE": 32,
            "PTAB_SIZE": 32,
            "FRONT2BACK_FIFO_SIZE": 64,
            "Q_DEPTH": 500,
            "RAS_DEPTH": 64,
        }
        for name, value in fallback.items():
            self.constants.setdefault(name, value)

    def eval_expr(self, expr: str, allow_unknown: bool = False) -> int | None:
        expr = expr.strip()
        expr = re.sub(r"\bstatic_cast\s*<[^>]+>\s*\(([^()]+)\)", r"(\1)", expr)
        expr = re.sub(r"\bstd::", "", expr)
        expr = expr.replace("uint32_t", "")
        expr = re.sub(r"([0-9]+)\s*[uUlL]+", r"\1", expr)
        expr = expr.replace("&&", " and ").replace("||", " or ")
        expr = re.sub(r"\btrue\b", "1", expr)
        expr = re.sub(r"\bfalse\b", "0", expr)

        def clog2(value: int) -> int:
            if value <= 1:
                return 0
            return int(math.ceil(math.log2(value)))

        names = dict(self.constants)
        names.update({"clog2": clog2, "rv_clog2": clog2, "ceil_log2": clog2, "ceil_log2_u32": clog2})
        try:
            return int(eval(expr, {"__builtins__": {}}, names))
        except Exception:
            if allow_unknown:
                return None
            raise ValueError(f"无法计算表达式: {expr}")

    def collect_aliases(self, clean_by_file: dict[Path, str]) -> None:
        for text in clean_by_file.values():
            for name, target in re.findall(r"\busing\s+([A-Za-z_]\w*)\s*=\s*([^;]+);", text):
                self.aliases[name] = self.clean_type(target)
            for target, name in re.findall(r"\btypedef\s+([^;]+?)\s+([A-Za-z_]\w*)\s*;", text):
                self.aliases[name] = self.clean_type(target)

    def collect_structs(self, clean_by_file: dict[Path, str]) -> None:
        for path, text in clean_by_file.items():
            text = re.sub(r"^\s*#.*$", "", text, flags=re.M)
            class_spans: list[tuple[int, int]] = []
            for match in re.finditer(r"\bclass\s+([A-Za-z_]\w*)\s*\{", text):
                name = match.group(1)
                start = match.end() - 1
                end = self.find_matching_brace(text, start)
                if end == -1:
                    continue
                class_spans.append((match.start(), end + 1))
                self.parse_structs_in_block(text[start + 1:end], name, path, text, match.start())

            top_text = list(text)
            for start, end in class_spans:
                top_text[start:end] = " " * (end - start)
            self.parse_structs_in_block("".join(top_text), "", path, text, 0)

    def parse_structs_in_block(self, block: str, prefix: str, path: Path, full_text: str, base_offset: int) -> None:
        search_pos = 0
        struct_spans: list[tuple[int, int]] = []
        while True:
            match = re.search(r"\bstruct\s+([A-Za-z_]\w*)\s*\{", block[search_pos:])
            if not match:
                break
            match_start = search_pos + match.start()
            name = match.group(1)
            brace = search_pos + match.end() - 1
            end = self.find_matching_brace(block, brace)
            if end == -1:
                break
            full_name = f"{prefix}::{name}" if prefix else name
            body = block[brace + 1:end]
            line = self.line_number(full_text, base_offset + match_start)
            self.parse_structs_in_block(body, full_name, path, full_text, base_offset + brace + 1)
            fields = self.parse_fields(body, full_name, path, full_text, base_offset + brace + 1)
            self.structs[full_name] = StructDef(full_name, fields, self.rel(path), line, prefix)
            if not prefix and name not in self.structs:
                self.structs[name] = self.structs[full_name]
            struct_spans.append((match_start, end + 1))
            search_pos = end + 1

    def parse_fields(self, body: str, context: str, path: Path, full_text: str, base_offset: int) -> list[Field]:
        body_chars = list(body)
        for start, end in self.find_struct_spans(body):
            body_chars[start:end] = " " * (end - start)
        clean_body = "".join(body_chars)

        fields: list[Field] = []
        offset = 0
        for stmt in clean_body.split(";"):
            raw = stmt.strip()
            stmt_offset = clean_body.find(stmt, offset)
            offset = stmt_offset + len(stmt) + 1
            if not raw:
                continue
            raw = re.sub(r"^\s*(public|private|protected)\s*:\s*", "", raw).strip()
            if not raw or "(" in raw or "=" in raw or raw.startswith(("static ", "using ", "typedef ", "enum ")):
                continue
            match = re.match(r"(.+?)\s+([A-Za-z_]\w*)\s*((?:\[[^\]]+\])*)$", raw, flags=re.S)
            if not match:
                continue
            type_name = self.clean_type(match.group(1))
            field_name = match.group(2)
            dims = re.findall(r"\[([^\]]+)\]", match.group(3))
            line = self.line_number(full_text, base_offset + max(stmt_offset, 0))
            fields.append(Field(field_name, type_name, dims, self.rel(path), line, context))
        return fields

    @staticmethod
    def find_matching_brace(text: str, start: int) -> int:
        depth = 0
        for idx in range(start, len(text)):
            if text[idx] == "{":
                depth += 1
            elif text[idx] == "}":
                depth -= 1
                if depth == 0:
                    return idx
        return -1

    def find_struct_spans(self, text: str) -> list[tuple[int, int]]:
        spans: list[tuple[int, int]] = []
        for match in re.finditer(r"\bstruct\s+([A-Za-z_]\w*)\s*\{", text):
            end = self.find_matching_brace(text, match.end() - 1)
            if end != -1:
                spans.append((match.start(), end + 1))
        return spans

    @staticmethod
    def clean_type(type_name: str) -> str:
        type_name = type_name.strip()
        type_name = re.sub(r"\b(const|volatile|struct|class|typename)\b", "", type_name)
        type_name = type_name.replace("&", " ").replace("*", " ")
        type_name = " ".join(type_name.split())
        return type_name

    def build_type_bits(self) -> None:
        for name, value in self.constants.items():
            if name.endswith("_BITS"):
                self.type_bits[name[:-5]] = value
        for name, target in list(self.aliases.items()):
            if name in self.type_bits:
                continue
            if target in self.type_bits:
                self.type_bits[name] = self.type_bits[target]
        for name in list(self.aliases):
            match = re.match(r"wire(\d+)_t$", name)
            if match:
                self.type_bits[name] = int(match.group(1))

        self.type_bits.setdefault("bool", 1)
        self.type_bits.setdefault("uint8_t", 8)
        self.type_bits.setdefault("uint16_t", 16)
        self.type_bits.setdefault("uint32_t", 32)
        self.type_bits.setdefault("uint64_t", 64)

    def resolve_name(self, type_name: str, context: str) -> str:
        type_name = self.clean_type(type_name)
        if "::" in type_name:
            if type_name in self.structs or type_name in self.aliases or type_name in self.type_bits:
                return type_name
            parts = context.split("::") if context else []
            while parts:
                candidate = "::".join(parts + [type_name])
                if candidate in self.structs or candidate in self.aliases or candidate in self.type_bits:
                    return candidate
                parts.pop()
            return type_name
        parts = context.split("::") if context else []
        while parts:
            candidate = "::".join(parts + [type_name])
            if candidate in self.structs or candidate in self.aliases or candidate in self.type_bits:
                return candidate
            parts.pop()
        return type_name

    def width_of(self, type_name: str, context: str = "") -> int:
        resolved = self.resolve_name(type_name, context)
        if resolved in self._width_stack:
            raise ValueError("递归类型依赖: " + " -> ".join(self._width_stack + [resolved]))
        if resolved in self.type_bits:
            return self.type_bits[resolved]
        template_bits = re.match(r"wire_for_bits_t\s*<\s*(.+)\s*>$", resolved)
        if template_bits:
            return self.eval_expr(template_bits.group(1))
        template_range = re.match(r"wire_for_range_t\s*<\s*(.+)\s*>$", resolved)
        if template_range:
            max_value = self.eval_expr(template_range.group(1))
            return int(math.ceil(math.log2(max_value + 1))) if max_value > 0 else 1
        if resolved in self.aliases:
            self._width_stack.append(resolved)
            value = self.width_of(self.aliases[resolved], context)
            self._width_stack.pop()
            return value
        if resolved in self.structs:
            self._width_stack.append(resolved)
            total = 0
            for field in self.structs[resolved].fields:
                total += self.field_width(field)
            self._width_stack.pop()
            return total
        match = re.match(r"wire(\d+)_t$", resolved)
        if match:
            return int(match.group(1))
        raise KeyError(f"无法解析类型位宽: {type_name} (context={context})")

    def field_width(self, field: Field) -> int:
        count = 1
        for dim in field.dims:
            count *= self.eval_expr(dim)
        return self.width_of(field.type_name, field.context) * count

    def flatten(self, type_name: str, context: str = "", prefix: str = "") -> list[dict[str, str | int]]:
        resolved = self.resolve_name(type_name, context)
        if resolved in self.aliases:
            return self.flatten(self.aliases[resolved], context, prefix)
        if resolved not in self.structs:
            return [{
                "field": prefix or resolved,
                "type": resolved,
                "item_bits": self.width_of(resolved, context),
                "count": 1,
                "total_bits": self.width_of(resolved, context),
                "source": "内建/typedef",
            }]

        rows: list[dict[str, str | int]] = []
        struct = self.structs[resolved]
        for field in struct.fields:
            count = 1
            for dim in field.dims:
                count *= self.eval_expr(dim)
            item_bits = self.width_of(field.type_name, field.context)
            total_bits = item_bits * count
            field_path = f"{prefix}.{field.name}" if prefix else field.name
            dim_text = "".join(f"[{dim}]" for dim in field.dims)
            rows.append({
                "field": f"{field_path}{dim_text}",
                "type": field.type_name,
                "item_bits": item_bits,
                "count": count,
                "total_bits": total_bits,
                "source": f"{field.source}:{field.line}",
            })
            resolved_field = self.resolve_name(field.type_name, field.context)
            if resolved_field in self.aliases:
                resolved_field = self.resolve_name(self.aliases[resolved_field], field.context)
            if resolved_field in self.structs:
                for child in self.flatten(field.type_name, field.context, field_path):
                    child = dict(child)
                    child["source"] = f"{child['source']}"
                    rows.append(child)
        return rows

    def source_of_type(self, type_name: str, context: str = "") -> str:
        resolved = self.resolve_name(type_name, context)
        if resolved in self.aliases:
            return f"using {type_name} = {self.aliases[resolved]}"
        if resolved in self.structs:
            struct = self.structs[resolved]
            return f"{struct.source}:{struct.line}"
        return "内建/typedef"


def write_table(rows: list[list[str]]) -> str:
    if not rows:
        return ""
    widths = [max(len(row[idx]) for row in rows) for idx in range(len(rows[0]))]
    out: list[str] = []
    header = rows[0]
    out.append("| " + " | ".join(header[idx].ljust(widths[idx]) for idx in range(len(header))) + " |")
    out.append("| " + " | ".join("-" * widths[idx] for idx in range(len(header))) + " |")
    for row in rows[1:]:
        out.append("| " + " | ".join(row[idx].ljust(widths[idx]) for idx in range(len(row))) + " |")
    return "\n".join(out)


def module_group(name: str) -> str:
    if name in {
        "fetch_address_FIFO_comb",
        "instruction_FIFO_comb",
        "PTAB_comb",
        "front2back_FIFO_comb",
    }:
        return "FIFO/PTAB"
    if name in {"predecode_comb", "predecode_checker_comb"}:
        return "Predecode"
    if name.startswith("front_"):
        return "front_top glue"
    return "BPU"


def top_level_rows(model: Model, type_name: str) -> list[dict[str, str | int]]:
    resolved = model.resolve_name(type_name, "")
    if resolved in model.aliases:
        resolved = model.resolve_name(model.aliases[resolved], "")
    if resolved not in model.structs:
        width = model.width_of(type_name)
        return [{
            "field": resolved,
            "type": resolved,
            "item_bits": width,
            "count": 1,
            "total_bits": width,
            "source": "内建/typedef",
        }]

    rows: list[dict[str, str | int]] = []
    for field in model.structs[resolved].fields:
        count = 1
        for dim in field.dims:
            count *= model.eval_expr(dim)
        item_bits = model.width_of(field.type_name, field.context)
        dim_text = "".join(f"[{dim}]" for dim in field.dims)
        rows.append({
            "field": f"{field.name}{dim_text}",
            "type": field.type_name,
            "context": field.context,
            "item_bits": item_bits,
            "count": count,
            "total_bits": item_bits * count,
            "source": f"{field.source}:{field.line}",
        })
    return rows


def key_expansion_rows(model: Model, type_name: str) -> list[dict[str, str | int]]:
    rows: list[dict[str, str | int]] = []
    for row in top_level_rows(model, type_name):
        field_type = str(row["type"])
        resolved = model.resolve_name(field_type, str(row.get("context", "")))
        if resolved in model.aliases:
            resolved = model.resolve_name(model.aliases[resolved], str(row.get("context", "")))
        if resolved in model.structs:
            expanded = dict(row)
            expanded["resolved_type"] = resolved
            rows.append(expanded)
    return rows


def comment_line(text: str = "") -> str:
    return f"// {text}".rstrip()


def format_breakdown(model: Model, title: str, type_name: str) -> list[str]:
    lines: list[str] = []
    rows = top_level_rows(model, type_name)
    total = model.width_of(type_name)
    name_width = max(len(str(row["field"])) for row in rows)
    bit_width = max(len(str(total)), *(len(str(row["total_bits"])) for row in rows))
    lines.append(comment_line(f"{title} {type_name} = {total} bit"))
    for idx, row in enumerate(rows):
        sign = "=" if idx == 0 else "+"
        field = str(row["field"])
        bits = str(row["total_bits"])
        lines.append(comment_line(f"  {sign} {field:<{name_width}} {bits:>{bit_width}} bit"))
    lines.append(comment_line(f"  = {'合计':<{name_width}} {total:>{bit_width}} bit"))
    return lines


def make_rtl_comment(model: Model, spec: ModuleSpec) -> str:
    in_width = model.width_of(spec.in_type)
    out_width = model.width_of(spec.out_type)
    lines: list[str] = []
    lines.append("// -----------------------------------------------------------------------------")
    lines.append(comment_line("端口自查"))
    lines.append(comment_line(f"模块：{spec.name}"))
    lines.append(comment_line(f"来源：{spec.source_note}"))
    lines.append(comment_line("配置：simulator-front 默认 large 配置"))
    lines.append(comment_line(f"接口：{spec.in_type}({in_width} bit) -> {spec.out_type}({out_width} bit)"))
    lines.append(comment_line(""))
    lines.extend(format_breakdown(model, "输入", spec.in_type))
    lines.append(comment_line(""))
    lines.extend(format_breakdown(model, "输出", spec.out_type))

    key_rows = key_expansion_rows(model, spec.in_type) + key_expansion_rows(model, spec.out_type)
    seen: set[tuple[str, str]] = set()
    unique_key_rows: list[dict[str, str | int]] = []
    for row in key_rows:
        key = (str(row["field"]), str(row["type"]))
        if key not in seen:
            seen.add(key)
            unique_key_rows.append(row)
    if unique_key_rows:
        lines.append(comment_line(""))
        lines.append(comment_line("关键结构展开："))
        field_width = max(len(str(row["field"])) for row in unique_key_rows)
        type_width = max(len(str(row.get("resolved_type", row["type"]))) for row in unique_key_rows)
        bit_width = max(len(str(row["total_bits"])) for row in unique_key_rows)
        for row in unique_key_rows:
            type_text = row.get("resolved_type", row["type"])
            lines.append(comment_line(
                f"  {str(row['field']):<{field_width}} : "
                f"{str(type_text):<{type_width}} {str(row['total_bits']):>{bit_width}} bit"
            ))

    lines.append(comment_line(""))
    lines.append(comment_line("配置口径："))
    config_keys = [
        "FETCH_WIDTH",
        "COMMIT_WIDTH",
        "TN_MAX",
        "BPU_BANK_NUM",
        "TAGE_IDX_WIDTH",
        "TAGE_TAG_WIDTH",
        "TAGE_SC_PATH_BITS",
        "BPU_SCL_META_NTABLE",
        "BPU_SCL_META_IDX_BITS",
        "BPU_LOOP_META_IDX_BITS",
        "BPU_LOOP_META_TAG_BITS",
    ]
    key_width = max(len(key) for key in config_keys)
    for key in config_keys:
        if key in model.constants:
            lines.append(comment_line(f"  {key:<{key_width}} = {model.constants[key]}"))
    if "tage_reset_ctr_t" in model.type_bits:
        lines.append(comment_line(f"  tage_reset_ctr_t = TAGE_IDX_WIDTH + 11 = {model.type_bits['tage_reset_ctr_t']}"))
    if "tage_path_hist_t" in model.type_bits:
        lines.append(comment_line(f"  tage_path_hist_t  = TAGE_SC_PATH_BITS = {model.type_bits['tage_path_hist_t']}"))
    lines.append(comment_line(""))
    lines.append(comment_line(f"自查确认：{spec.name} Input Bits = {in_width}, Output Bits = {out_width}。"))
    lines.append(comment_line("完整字段来源见 front_end/port_width_audit/details 对应文件。"))
    lines.append("// -----------------------------------------------------------------------------")
    return "\n".join(lines)


def annotate_rtl(model: Model, front_end_dir: Path) -> None:
    begin_pattern = r"// -----------------------------------------------------------------------------\n// 端口自查(?:：.*)?\n.*?// -----------------------------------------------------------------------------\n"
    for spec in MODULES:
        rel_path = RTL_FILES[spec.name]
        path = front_end_dir / rel_path
        text = path.read_text(encoding="utf-8")
        text = re.sub(begin_pattern, "", text, flags=re.S)
        module_match = re.search(r"\bmodule\s+", text)
        if not module_match:
            raise RuntimeError(f"找不到 module 关键字：{path}")
        block = make_rtl_comment(model, spec)
        prefix = text[:module_match.start()].rstrip()
        suffix = text[module_match.start():].lstrip("\n")
        text = prefix + ("\n\n" if prefix else "") + block + "\n\n" + suffix
        path.write_text(text, encoding="utf-8", newline="\n")


def generate_comb_port_summary(model: Model, summary_path: Path) -> None:
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    lines.append("// =============================================================================")
    lines.append("// 前端 27 个正式 comb 端口位宽集中自查")
    lines.append("//")
    lines.append("// 生成方式：")
    lines.append("//   python top/tools/scan_frontend_comb_ports.py simulator-front --annotate-rtl top/front_end")
    lines.append("//")
    lines.append("// 说明：")
    lines.append("//   1. 本文件只做端口宽度和字段来源审阅，不加入 filelist.f，不参与综合。")
    lines.append("//   2. 每个 comb 的分散注释仍保留在对应 *_comb_top.v 文件中。")
    lines.append("//   3. 端口位宽来源为 simulator-front 默认 large 配置。")
    lines.append("// =============================================================================")
    lines.append("")

    for index, spec in enumerate(MODULES, 1):
        lines.append(comment_line(f"{index:02d}/27"))
        lines.append(make_rtl_comment(model, spec))
        lines.append("")

    summary_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8", newline="\n")


def generate_docs(model: Model, out_dir: Path) -> None:
    details_dir = out_dir / "details"
    if out_dir.exists():
        shutil.rmtree(out_dir)
    details_dir.mkdir(parents=True, exist_ok=True)

    summary_rows = [["序号", "分组", "comb", "输入类型", "输入bit", "输出类型", "输出bit", "源码依据"]]
    for index, spec in enumerate(MODULES, 1):
        in_width = model.width_of(spec.in_type)
        out_width = model.width_of(spec.out_type)
        detail_name = f"{index:02d}_{spec.name}.md"
        summary_rows.append([
            str(index),
            module_group(spec.name),
            f"[{spec.name}](details/{detail_name})",
            f"`{spec.in_type}`",
            str(in_width),
            f"`{spec.out_type}`",
            str(out_width),
            spec.source_note,
        ])

        detail_lines: list[str] = []
        detail_lines.append(f"# {spec.name}\n")
        detail_lines.append(f"- 分组：`{module_group(spec.name)}`")
        detail_lines.append(f"- 源码依据：`{spec.source_note}`")
        detail_lines.append("- 配置口径：`simulator-front` 当前默认 large 配置\n")
        detail_lines.append("## 端口总览\n")
        detail_lines.append(write_table([
            ["方向", "类型", "bit"],
            ["输入", f"`{spec.in_type}`", str(in_width)],
            ["输出", f"`{spec.out_type}`", str(out_width)],
        ]))
        detail_lines.append("\n\n## 输入展开\n")
        input_rows = [["字段", "类型", "单项bit", "数量", "合计bit", "来源"]]
        for row in model.flatten(spec.in_type):
            input_rows.append([
                str(row["field"]),
                f"`{row['type']}`",
                str(row["item_bits"]),
                str(row["count"]),
                str(row["total_bits"]),
                str(row["source"]),
            ])
        detail_lines.append(write_table(input_rows))
        detail_lines.append("\n\n## 输出展开\n")
        output_rows = [["字段", "类型", "单项bit", "数量", "合计bit", "来源"]]
        for row in model.flatten(spec.out_type):
            output_rows.append([
                str(row["field"]),
                f"`{row['type']}`",
                str(row["item_bits"]),
                str(row["count"]),
                str(row["total_bits"]),
                str(row["source"]),
            ])
        detail_lines.append(write_table(output_rows))
        detail_lines.append("\n")
        (details_dir / detail_name).write_text("\n".join(detail_lines), encoding="utf-8")

    config_keys = [
        "FETCH_WIDTH",
        "COMMIT_WIDTH",
        "TN_MAX",
        "BPU_BANK_NUM",
        "TAGE_IDX_WIDTH",
        "TAGE_TAG_WIDTH",
        "TAGE_SC_PATH_BITS",
        "TYPE_PRED_SET_NUM",
        "FETCH_ADDR_FIFO_SIZE",
        "INSTRUCTION_FIFO_SIZE",
        "PTAB_SIZE",
        "FRONT2BACK_FIFO_SIZE",
        "Q_DEPTH",
        "RAS_DEPTH",
    ]
    config_rows = [["配置项", "值"]]
    for key in config_keys:
        config_rows.append([f"`{key}`", str(model.constants.get(key, "未解析"))])

    readme: list[str] = []
    readme.append("# 前端 27 个 comb 端口位宽目录\n")
    readme.append(f"- 生成时间：{dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    readme.append(f"- 模拟器源码：`{model.sim_root.as_posix()}`")
    readme.append("- 配置口径：`simulator-front` 当前默认 large 配置")
    readme.append("- 说明：本目录只核对端口和字段来源，不代表 BSD 真实组合逻辑已经补齐。\n")
    readme.append("## large 配置关键值\n")
    readme.append(write_table(config_rows))
    readme.append("\n\n## 特殊 typedef 处理\n")
    readme.append("- `tage_reset_ctr_t`：源码写成 `using tage_reset_ctr_t = wire32_t`，但有效宽度按 `tage_reset_ctr_t_BITS = TAGE_IDX_WIDTH + 11`，当前为 23 bit。")
    readme.append("- `tage_path_hist_t`：源码写成 `using tage_path_hist_t = wire32_t`，但有效宽度按 `tage_path_hist_t_BITS = TAGE_SC_PATH_BITS`，当前为 16 bit。\n")
    readme.append("## 27 个 comb 汇总\n")
    readme.append(write_table(summary_rows))
    readme.append("\n")
    (out_dir / "README.md").write_text("\n".join(readme), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="扫描 simulator-front 并生成前端 comb 端口目录")
    parser.add_argument("source", help="simulator-front 源码目录，例如 simulator-front")
    parser.add_argument("--out", default="top/front_end/port_width_audit", help="输出目录")
    parser.add_argument("--summary-file", help="集中端口自查文件，默认写到 top/front_end/front_comb_port_width_summary.vh")
    parser.add_argument("--annotate-rtl", help="前端 RTL 目录，例如 top/front_end；指定后会把端口自查注释写入 27 个 comb 文件")
    args = parser.parse_args()

    model = Model(Path(args.source))
    model.load()
    out_dir = Path(args.out)
    generate_docs(model, out_dir)
    summary_path = Path(args.summary_file) if args.summary_file else out_dir.parent / "front_comb_port_width_summary.vh"
    generate_comb_port_summary(model, summary_path)
    if args.annotate_rtl:
        annotate_rtl(model, Path(args.annotate_rtl))
        print(f"已写入 27 个 comb 的端口自查注释：{Path(args.annotate_rtl).resolve()}")
    print(f"已生成集中端口自查文件：{summary_path.resolve()}")
    print(f"已生成端口目录：{out_dir.resolve()}")


if __name__ == "__main__":
    main()
