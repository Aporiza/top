#!/usr/bin/env bash
set -euo pipefail

# 前端顶层烟测入口。
# 先手动进入 top/front_end 或直接从任意目录运行本脚本均可。
# 该脚本只验证当前 RTL 骨架能被 Verilator 编译并跑若干拍。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${FRONT_DIR}/build/verilator_smoke"

cd "${FRONT_DIR}"
mkdir -p "${BUILD_DIR}"

verilator \
    --binary \
    --timing \
    -Wno-TIMESCALEMOD \
    -sv \
    -f filelist.f \
    sim/front_top_smoke_tb.sv \
    --top-module front_top_smoke_tb \
    -Mdir "${BUILD_DIR}/obj_dir" \
    -o front_top_smoke

"${BUILD_DIR}/obj_dir/front_top_smoke"
