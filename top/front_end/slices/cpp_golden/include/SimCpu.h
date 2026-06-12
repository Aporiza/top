#pragma once

// C++ golden slice 仿真专用 stub。
// simulator-front 的 BPU.h 会 include <SimCpu.h>，但 27 个 comb 的 DPI
// 验证只需要 BPU_TOP/Type/TAGE/BTB 的组合逻辑，不需要整机 SimCpu、AXI、
// DDR、MMIO 等依赖。把这个目录放在 C++ include path 最前面，可以避免
// golden slice smoke test 被整机模拟器依赖拖住。
class SimCpu;
