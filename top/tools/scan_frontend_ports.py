#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成前端 27 个正式 comb 的端口自查 Markdown。

默认可在仓库任意目录运行：
    python top/tools/scan_frontend_ports.py

也可以显式指定：
    python top/tools/scan_frontend_ports.py --source simulator-front --front-dir top/front_end

本脚本只生成 Markdown 汇总，不改 RTL 注释。
如需重写每个 *_comb_top.v 里的端口自查注释，继续使用
scan_frontend_comb_ports.py --annotate-rtl。
"""

from __future__ import annotations

import argparse
import datetime as dt
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from scan_frontend_comb_ports import (  # noqa: E402
    MODULES,
    Model,
    key_expansion_rows,
    make_rtl_comment,
    module_group,
    top_level_rows,
    write_table,
)


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


def build_summary_table(model: Model) -> str:
    rows = [["序号", "分组", "comb", "输入", "输出", "源码依据"]]
    for index, spec in enumerate(MODULES, 1):
        rows.append([
            str(index),
            module_group(spec.name),
            f"`{spec.name}`",
            f"`{spec.in_type}` / {model.width_of(spec.in_type)} bit",
            f"`{spec.out_type}` / {model.width_of(spec.out_type)} bit",
            spec.source_note,
        ])
    return write_table(rows)


def source_lines(model: Model, type_name: str) -> list[str]:
    rows = top_level_rows(model, type_name)
    out: list[str] = []
    for row in rows:
        out.append(
            f"- `{row['field']}`: `{row['type']}`, "
            f"{row['total_bits']} bit, 来源 `{row['source']}`"
        )
    return out


def key_lines(model: Model, spec_name: str, in_type: str, out_type: str) -> list[str]:
    rows = key_expansion_rows(model, in_type) + key_expansion_rows(model, out_type)
    seen: set[tuple[str, str]] = set()
    out: list[str] = []
    for row in rows:
        key = (str(row["field"]), str(row.get("resolved_type", row["type"])))
        if key in seen:
            continue
        seen.add(key)
        out.append(
            f"- `{row['field']}`: `{row.get('resolved_type', row['type'])}`, "
            f"{row['total_bits']} bit"
        )
    if not out:
        out.append(f"- `{spec_name}` 无额外嵌套结构体需要展开。")
    return out


def generate_frontend_markdown(model: Model, out_path: Path) -> None:
    lines: list[str] = []
    lines.append("# 前端端口自查汇总\n")
    lines.append(f"- 生成时间：{dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"- 模拟器源码：`{model.sim_root.as_posix()}`")
    lines.append("- 配置口径：`simulator-front` 默认 large 配置")
    lines.append("- 范围：27 个正式 comb 训练单元")
    lines.append("- 说明：本文件用于集中人工复查端口位宽和字段来源，不参与综合，也不改 RTL 注释。\n")

    lines.append("## 总览\n")
    lines.append(build_summary_table(model))
    lines.append("\n## 逐模块自查\n")

    for index, spec in enumerate(MODULES, 1):
        in_width = model.width_of(spec.in_type)
        out_width = model.width_of(spec.out_type)
        lines.append(f"### {index:02d}. `{spec.name}`\n")
        lines.append("```verilog")
        lines.append(make_rtl_comment(model, spec))
        lines.append("```\n")

        lines.append("字段来源补充：")
        lines.append("")
        lines.append("输入顶层字段：")
        lines.extend(source_lines(model, spec.in_type))
        lines.append("")
        lines.append("输出顶层字段：")
        lines.extend(source_lines(model, spec.out_type))
        lines.append("")
        lines.append("关键结构：")
        lines.extend(key_lines(model, spec.name, spec.in_type, spec.out_type))
        lines.append("")
        lines.append(f"自查结论：`{spec.name}` 输入 {in_width} bit，输出 {out_width} bit。\n")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="生成前端 comb 端口自查 Markdown")
    parser.add_argument("--source", default=None, help="simulator-front 源码目录，默认自动使用仓库根目录下的 simulator-front")
    parser.add_argument("--front-dir", default=None, help="front_end 目录，默认 top/front_end")
    parser.add_argument("--out", default=None, help="输出 Markdown，默认 top/front_end/前端端口自查汇总.md")
    args = parser.parse_args()

    source = resolve_repo_path(args.source, REPO_ROOT / "simulator-front")
    front_dir = resolve_repo_path(args.front_dir, REPO_ROOT / "top" / "front_end")
    out_path = resolve_repo_path(args.out, front_dir / "前端端口自查汇总.md")

    model = Model(source)
    model.load()
    generate_frontend_markdown(model, out_path)
    print(f"已生成前端端口自查汇总：{out_path}")


if __name__ == "__main__":
    main()
