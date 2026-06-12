#!/usr/bin/env bash
set -euo pipefail

# 周期级 C-RTL 对拍入口。
# - RTL: top/front_end/front_top.v
# - C++ golden: simulator-front/front-end/front_top.cpp
# - 非 FIFO/PTAB 的 BSD 占位在仿真时通过 USE_CPP_GOLDEN_BSD 调用 C++ comb
# - FIFO/PTAB 仍使用本仓库 Verilog 实现

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${FRONT_DIR}/../.." && pwd)"
SIM_FRONT="${REPO_ROOT}/simulator-front"
BUILD_DIR="${FRONT_DIR}/build/verilator_crtl_compare"

if [[ ! -d "${SIM_FRONT}" ]]; then
    echo "找不到 simulator-front: ${SIM_FRONT}" >&2
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

COMMON_INCLUDES=(
    -I.
    -I"${FRONT_DIR}/slices/cpp_golden/include"
    -I"${SIM_FRONT}/front-end"
    -I"${SIM_FRONT}/front-end/config"
    -I"${SIM_FRONT}/front-end/icache"
    -I"${SIM_FRONT}/front-end/icache/include"
    -I"${SIM_FRONT}/front-end/BPU"
    -I"${SIM_FRONT}/front-end/BPU/type_predictor"
    -I"${SIM_FRONT}/front-end/BPU/dir_predictor"
    -I"${SIM_FRONT}/front-end/BPU/target_predictor"
    -I"${SIM_FRONT}/include"
    -I"${SIM_FRONT}/back-end/include"
    -I"${SIM_FRONT}/back-end/Lsu/include"
    -I"${SIM_FRONT}/MemSubSystem/include"
    -I"${SIM_FRONT}/diff/include"
    -I"${SIM_FRONT}"
)

CPP_CFLAGS="-DCPP_GOLDEN_USE_EXTERNAL_BPU_TOP"
for inc in "${COMMON_INCLUDES[@]}"; do
    CPP_CFLAGS+=" ${inc}"
done

verilator \
    --binary \
    --timing \
    -Wno-TIMESCALEMOD \
    -Wno-WIDTH \
    -Wno-BLKLOOPINIT \
    -sv \
    +define+USE_CPP_GOLDEN_BSD \
    +define+FRONT_TOP_CRTL_COMPARE \
    "${COMMON_INCLUDES[@]}" \
    -CFLAGS "${CPP_CFLAGS}" \
    -f filelist.f \
    sim/front_top_smoke_tb.sv \
    "${FRONT_DIR}/sim/front_top_cpp_oracle.cpp" \
    "${FRONT_DIR}/slices/cpp_golden/cpp_golden_bsd.cpp" \
    "${SIM_FRONT}/front-end/front_top.cpp" \
    "${SIM_FRONT}/front-end/predecode.cpp" \
    "${SIM_FRONT}/front-end/predecode_checker.cpp" \
    "${SIM_FRONT}/front-end/fifo/fetch_address_FIFO.cpp" \
    "${SIM_FRONT}/front-end/fifo/instruction_FIFO.cpp" \
    "${SIM_FRONT}/front-end/fifo/PTAB.cpp" \
    "${SIM_FRONT}/front-end/fifo/front2bank_FIFO.cpp" \
    "${SIM_FRONT}/front-end/icache/icache.cpp" \
    "${SIM_FRONT}/front-end/icache/ICacheTop.cpp" \
    "${SIM_FRONT}/front-end/icache/icache_module.cpp" \
    "${SIM_FRONT}/back-end/PhysMemory.cpp" \
    "${SIM_FRONT}/back-end/Lsu/SimpleMmu.cpp" \
    "${SIM_FRONT}/back-end/Lsu/TlbMmu.cpp" \
    "${SIM_FRONT}/MemSubSystem/PtwWalker.cpp" \
    "${SIM_FRONT}/front-end/host_profile.cpp" \
    "${SIM_FRONT}/front-end/frontend_stats.cpp" \
    --top-module front_top_smoke_tb \
    -Mdir "${BUILD_DIR}/obj_dir" \
    -o front_top_crtl_compare

"${BUILD_DIR}/obj_dir/front_top_crtl_compare"
