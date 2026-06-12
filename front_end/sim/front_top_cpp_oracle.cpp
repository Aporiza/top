// Cycle-level C++ oracle for front_top RTL verification.
//
// This file is simulation-only.  It calls simulator-front's front_top()
// once per RTL cycle and packs front_top_out with the same field order used
// by front_output_comb/front_top.v.

#include "svdpi.h"

#include <cassert>
#include <cstdint>
#include <cstring>

#include "IO.h"
#include "PhysMemory.h"
#include "front_IO.h"
#include "front_module.h"

long long sim_time = 0;

namespace {

constexpr int kFetchWidth = FETCH_WIDTH;
constexpr int kCommitWidth = COMMIT_WIDTH;
constexpr int kTnMax = TN_MAX;
constexpr int kPcbits = 32;
constexpr int kInstBits = 32;
constexpr int kPrivilegeBits = 2;
constexpr int kPcpnBits = 3;
constexpr int kBrTypeBits = 3;
constexpr int kTageIdxBits = TAGE_IDX_WIDTH;
constexpr int kTageTagBits = TAGE_TAG_WIDTH;
constexpr int kScMetaNtable = BPU_SCL_META_NTABLE;
constexpr int kScMetaIdxBits = BPU_SCL_META_IDX_BITS;
constexpr int kScMetaSumBits = 16;
constexpr int kLoopMetaIdxBits = BPU_LOOP_META_IDX_BITS;
constexpr int kLoopMetaTagBits = BPU_LOOP_META_TAG_BITS;
constexpr int kFrontTopOutBits = 5393;

front_top_in g_in{};
front_top_out g_out{};
CsrStatusIO g_csr{};

uint64_t read_bits(const svBitVecVal *data, int lsb, int width) {
  uint64_t value = 0;
  for (int bit = 0; bit < width; ++bit) {
    const int src = lsb + bit;
    if ((data[src >> 5] >> (src & 31)) & 1u) {
      value |= (uint64_t{1} << bit);
    }
  }
  return value;
}

void clear_bits(svBitVecVal *data, int total_bits) {
  const int words = (total_bits + 31) / 32;
  for (int i = 0; i < words; ++i) {
    data[i] = 0;
  }
}

class BitWriter {
public:
  BitWriter(svBitVecVal *data, int total_bits) : data_(data), bit_(total_bits) {
    clear_bits(data_, total_bits);
  }

  void write_u64(int width, uint64_t value) {
    bit_ -= width;
    for (int i = 0; i < width; ++i) {
      if ((value >> i) & 1u) {
        const int dst_bit = bit_ + i;
        data_[dst_bit >> 5] |= (svBitVecVal{1} << (dst_bit & 31));
      }
    }
  }

private:
  svBitVecVal *data_;
  int bit_;
};

void unpack_commit_inputs(
    const svBitVecVal *back2front_valid,
    const svBitVecVal *predict_base_pc,
    const svBitVecVal *predict_dir,
    const svBitVecVal *actual_dir,
    const svBitVecVal *actual_br_type,
    const svBitVecVal *actual_target,
    const svBitVecVal *alt_pred,
    const svBitVecVal *altpcpn,
    const svBitVecVal *pcpn,
    const svBitVecVal *tage_idx,
    const svBitVecVal *tage_tag,
    const svBitVecVal *sc_used,
    const svBitVecVal *sc_pred,
    const svBitVecVal *sc_sum,
    const svBitVecVal *sc_idx,
    const svBitVecVal *loop_used,
    const svBitVecVal *loop_hit,
    const svBitVecVal *loop_pred,
    const svBitVecVal *loop_idx,
    const svBitVecVal *loop_tag) {
  for (int i = 0; i < kCommitWidth; ++i) {
    g_in.back2front_valid[i] = read_bits(back2front_valid, i, 1) != 0;
    g_in.predict_base_pc[i] =
        static_cast<pc_t>(read_bits(predict_base_pc, i * kPcbits, kPcbits));
    g_in.predict_dir[i] = read_bits(predict_dir, i, 1) != 0;
    g_in.actual_dir[i] = read_bits(actual_dir, i, 1) != 0;
    g_in.actual_br_type[i] = static_cast<br_type_t>(
        read_bits(actual_br_type, i * kBrTypeBits, kBrTypeBits));
    g_in.actual_target[i] = static_cast<target_addr_t>(
        read_bits(actual_target, i * kPcbits, kPcbits));
    g_in.alt_pred[i] = read_bits(alt_pred, i, 1) != 0;
    g_in.altpcpn[i] =
        static_cast<pcpn_t>(read_bits(altpcpn, i * kPcpnBits, kPcpnBits));
    g_in.pcpn[i] =
        static_cast<pcpn_t>(read_bits(pcpn, i * kPcpnBits, kPcpnBits));
    for (int j = 0; j < kTnMax; ++j) {
      g_in.tage_idx[i][j] = static_cast<tage_idx_t>(
          read_bits(tage_idx, (i * kTnMax + j) * kTageIdxBits, kTageIdxBits));
      g_in.tage_tag[i][j] = static_cast<tage_tag_t>(
          read_bits(tage_tag, (i * kTnMax + j) * kTageTagBits, kTageTagBits));
    }
    g_in.sc_used[i] = read_bits(sc_used, i, 1) != 0;
    g_in.sc_pred[i] = read_bits(sc_pred, i, 1) != 0;
    g_in.sc_sum[i] = static_cast<tage_scl_meta_sum_t>(
        read_bits(sc_sum, i * kScMetaSumBits, kScMetaSumBits));
    for (int j = 0; j < kScMetaNtable; ++j) {
      g_in.sc_idx[i][j] = static_cast<tage_scl_meta_idx_t>(
          read_bits(sc_idx, (i * kScMetaNtable + j) * kScMetaIdxBits,
                    kScMetaIdxBits));
    }
    g_in.loop_used[i] = read_bits(loop_used, i, 1) != 0;
    g_in.loop_hit[i] = read_bits(loop_hit, i, 1) != 0;
    g_in.loop_pred[i] = read_bits(loop_pred, i, 1) != 0;
    g_in.loop_idx[i] = static_cast<tage_loop_meta_idx_t>(
        read_bits(loop_idx, i * kLoopMetaIdxBits, kLoopMetaIdxBits));
    g_in.loop_tag[i] = static_cast<tage_loop_meta_tag_t>(
        read_bits(loop_tag, i * kLoopMetaTagBits, kLoopMetaTagBits));
  }
}

void pack_front_top_out(BitWriter &writer, const front_top_out &value) {
  writer.write_u64(1, static_cast<uint64_t>(value.FIFO_valid));
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(32, static_cast<uint64_t>(value.pc[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(32, static_cast<uint64_t>(value.instructions[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.predict_dir[i]));
  }
  writer.write_u64(32, static_cast<uint64_t>(value.predict_next_fetch_address));
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.alt_pred[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(3, static_cast<uint64_t>(value.altpcpn[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(3, static_cast<uint64_t>(value.pcpn[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.page_fault_inst[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.inst_valid[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    for (int j = kTnMax - 1; j >= 0; --j) {
      writer.write_u64(12, static_cast<uint64_t>(value.tage_idx[i][j]));
    }
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    for (int j = kTnMax - 1; j >= 0; --j) {
      writer.write_u64(8, static_cast<uint64_t>(value.tage_tag[i][j]));
    }
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.sc_used[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.sc_pred[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(16, static_cast<uint64_t>(value.sc_sum[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    for (int j = kScMetaNtable - 1; j >= 0; --j) {
      writer.write_u64(16, static_cast<uint64_t>(value.sc_idx[i][j]));
    }
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.loop_used[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.loop_hit[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(1, static_cast<uint64_t>(value.loop_pred[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(16, static_cast<uint64_t>(value.loop_idx[i]));
  }
  for (int i = kFetchWidth - 1; i >= 0; --i) {
    writer.write_u64(16, static_cast<uint64_t>(value.loop_tag[i]));
  }
}

void set_csr(uint32_t sstatus, uint32_t mstatus, uint32_t satp,
             uint32_t privilege) {
  g_csr.sstatus = sstatus;
  g_csr.mstatus = mstatus;
  g_csr.satp = satp;
  g_csr.privilege = static_cast<wire2_t>(privilege & 0x3u);
  g_in.csr_status = &g_csr;
}

} // namespace

extern "C" void cpp_front_top_oracle_reset() {
  const bool memory_ready = pmem_init();
  assert(memory_ready);
  pmem_clear_all();
  std::memset(&g_in, 0, sizeof(g_in));
  std::memset(&g_out, 0, sizeof(g_out));
  g_csr = {};
  g_in.csr_status = &g_csr;
  sim_time = 0;
}

extern "C" void cpp_front_top_oracle_step(
    unsigned char reset,
    unsigned char refetch,
    unsigned char itlb_flush,
    unsigned char fence_i,
    uint32_t refetch_address,
    unsigned char FIFO_read_enable,
    const svBitVecVal *back2front_valid,
    const svBitVecVal *predict_base_pc,
    const svBitVecVal *predict_dir,
    const svBitVecVal *actual_dir,
    const svBitVecVal *actual_br_type,
    const svBitVecVal *actual_target,
    const svBitVecVal *alt_pred,
    const svBitVecVal *altpcpn,
    const svBitVecVal *pcpn,
    const svBitVecVal *tage_idx,
    const svBitVecVal *tage_tag,
    const svBitVecVal *sc_used,
    const svBitVecVal *sc_pred,
    const svBitVecVal *sc_sum,
    const svBitVecVal *sc_idx,
    const svBitVecVal *loop_used,
    const svBitVecVal *loop_hit,
    const svBitVecVal *loop_pred,
    const svBitVecVal *loop_idx,
    const svBitVecVal *loop_tag,
    uint32_t csr_status_sstatus,
    uint32_t csr_status_mstatus,
    uint32_t csr_status_satp,
    unsigned char csr_status_privilege,
    svBitVecVal *front_top_out_packed) {
  g_in.reset = reset != 0;
  g_in.refetch = refetch != 0;
  g_in.itlb_flush = itlb_flush != 0;
  g_in.fence_i = fence_i != 0;
  g_in.refetch_address = refetch_address;
  g_in.FIFO_read_enable = FIFO_read_enable != 0;
  set_csr(csr_status_sstatus, csr_status_mstatus, csr_status_satp,
          csr_status_privilege);
  unpack_commit_inputs(back2front_valid, predict_base_pc, predict_dir,
                       actual_dir, actual_br_type, actual_target, alt_pred,
                       altpcpn, pcpn, tage_idx, tage_tag, sc_used, sc_pred,
                       sc_sum, sc_idx, loop_used, loop_hit, loop_pred,
                       loop_idx, loop_tag);

  front_top(&g_in, &g_out);

  BitWriter writer(front_top_out_packed, kFrontTopOutBits);
  pack_front_top_out(writer, g_out);
  ++sim_time;
}
