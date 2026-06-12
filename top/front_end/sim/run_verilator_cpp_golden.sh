#!/usr/bin/env bash
set -euo pipefail

# C++ golden slice 验证入口。
# 这个脚本只用于仿真连接检查：非 FIFO/PTAB 的 *_bsd_top 通过 DPI 调用
# simulator-front 里的 C++ comb 逻辑，FIFO/PTAB 仍使用本仓库 Verilog 实现。
# 真实交付模式不定义 USE_CPP_GOLDEN_BSD，仍由组员替换 *_bsd_top 内部逻辑。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${FRONT_DIR}/../.." && pwd)"
SIM_FRONT="${REPO_ROOT}/simulator-front"
BUILD_DIR="${FRONT_DIR}/build/verilator_cpp_golden"

if [[ ! -d "${SIM_FRONT}" ]]; then
    echo "找不到 simulator-front：${SIM_FRONT}" >&2
    exit 1
fi

cd "${FRONT_DIR}"
mkdir -p "${BUILD_DIR}"

if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN=python3
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN=python
elif command -v py >/dev/null 2>&1; then
    PYTHON_BIN=py
else
    echo "找不到 Python，请先安装 python3 或把 python 加入 PATH。" >&2
    exit 1
fi

"${PYTHON_BIN}" "${REPO_ROOT}/top/tools/generate_frontend_cpp_golden.py" \
    "${SIM_FRONT}" \
    --patch-rtl

verilator \
    --binary \
    --timing \
    -Wno-TIMESCALEMOD \
    -Wno-WIDTH \
    -Wno-BLKLOOPINIT \
    -sv \
    +define+USE_CPP_GOLDEN_BSD \
    -I. \
    -I"${FRONT_DIR}/slices/cpp_golden/include" \
    -I"${SIM_FRONT}/front-end" \
    -I"${SIM_FRONT}/front-end/config" \
    -I"${SIM_FRONT}/include" \
    -I"${SIM_FRONT}/back-end/include" \
    -I"${SIM_FRONT}" \
    -CFLAGS "-I${FRONT_DIR}/slices/cpp_golden/include -I${SIM_FRONT}/front-end -I${SIM_FRONT}/front-end/config -I${SIM_FRONT}/include -I${SIM_FRONT}/back-end/include -I${SIM_FRONT}" \
    -f filelist.f \
    sim/front_top_smoke_tb.sv \
    "${FRONT_DIR}/slices/cpp_golden/cpp_golden_bsd.cpp" \
    "${SIM_FRONT}/front-end/predecode.cpp" \
    "${SIM_FRONT}/front-end/predecode_checker.cpp" \
    --top-module front_top_smoke_tb \
    -Mdir "${BUILD_DIR}/obj_dir" \
    -o front_top_cpp_golden_smoke

"${BUILD_DIR}/obj_dir/front_top_cpp_golden_smoke"
