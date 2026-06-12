#pragma once

// 仿真 C-RTL 对拍专用最小头文件。
// simulator-front/front-end/icache/ICacheTop.cpp 在当前版本中 include "Csr.h"，
// 但实际使用的 CsrStatusIO 已由 back-end/include/IO.h 提供。
// 本文件只用于补齐该 include，避免把完整后端 CSR 模块拉入前端对拍。
