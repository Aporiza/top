#pragma once

#include <cstdint>

// 仿真 C-RTL 对拍专用 AXI 读端口最小定义。
// ICacheTop.cpp 只需要这些字段来描述 ICache 对上游内存的读请求/响应。
namespace axi_interconnect {

constexpr uint32_t MAX_READ_TRANSACTION_BYTES = 256;

struct WideData512_t {
  uint32_t words[MAX_READ_TRANSACTION_BYTES / 4] = {0};
  uint32_t &operator[](int idx) { return words[idx]; }
  const uint32_t &operator[](int idx) const { return words[idx]; }
};

struct ReadMasterReq_t {
  bool valid = false;
  bool ready = false;
  bool accepted = false;
  uint32_t addr = 0;
  uint8_t total_size = 0;
  uint8_t id = 0;
  uint8_t accepted_id = 0;
  bool bypass = false;
};

struct ReadMasterResp_t {
  bool valid = false;
  bool ready = false;
  WideData512_t data{};
  uint8_t id = 0;
};

struct ReadMasterPort_t {
  ReadMasterReq_t req{};
  ReadMasterResp_t resp{};
};

} // namespace axi_interconnect
