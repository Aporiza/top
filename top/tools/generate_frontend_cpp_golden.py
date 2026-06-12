#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate the frontend C++ golden-slice DPI bridge.

The generated bridge is simulation-only. It lets *_bsd_top wrappers call the
simulator-front C++ comb model through DPI when USE_CPP_GOLDEN_BSD is defined.
Normal RTL delivery is unchanged when the macro is not defined.
"""

from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCAN_SCRIPT = ROOT / "top" / "tools" / "scan_frontend_comb_ports.py"
FRONT_DIR = ROOT / "top" / "front_end"
OUT_DIR = FRONT_DIR / "slices" / "cpp_golden"

FIFO_MODULES = {
    "fetch_address_FIFO_comb",
    "instruction_FIFO_comb",
    "PTAB_comb",
    "front2back_FIFO_comb",
}


def load_scan_module():
    spec = importlib.util.spec_from_file_location("scan_frontend_comb_ports", SCAN_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {SCAN_SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def sanitize(type_name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", type_name)


def clean_dim(dim: str) -> str:
    return dim.strip()


class CodeGen:
    def __init__(self, model) -> None:
        self.model = model
        self.unpack_done: set[str] = set()
        self.pack_done: set[str] = set()
        self.helper_code: list[str] = []

    def resolved(self, type_name: str, context: str = "") -> str:
        resolved = self.model.resolve_name(type_name, context)
        if resolved in self.model.aliases:
            return self.model.resolve_name(self.model.aliases[resolved], context)
        return resolved

    def is_struct(self, type_name: str, context: str = "") -> bool:
        return self.resolved(type_name, context) in self.model.structs

    def width_of(self, type_name: str, context: str = "") -> int:
        return self.model.width_of(type_name, context)

    def gen_unpack(self, type_name: str, context: str = "") -> str:
        resolved = self.resolved(type_name, context)
        fn = f"unpack_{sanitize(resolved)}"
        if fn in self.unpack_done:
            return fn
        if resolved not in self.model.structs:
            return fn
        self.unpack_done.add(fn)
        struct = self.model.structs[resolved]

        body: list[str] = []
        body.append(f"static void {fn}(BitReader &reader, {resolved} &value) {{")
        body.append("  std::memset(&value, 0, sizeof(value));")
        for field in struct.fields:
            body.extend(self.emit_unpack_value(f"value.{field.name}", field.type_name, field.context, field.dims, 1))
        body.append("}")
        body.append("")
        self.helper_code.extend(body)

        for field in struct.fields:
            if self.is_struct(field.type_name, field.context):
                self.gen_unpack(field.type_name, field.context)
        return fn

    def gen_pack(self, type_name: str, context: str = "") -> str:
        resolved = self.resolved(type_name, context)
        fn = f"pack_{sanitize(resolved)}"
        if fn in self.pack_done:
            return fn
        if resolved not in self.model.structs:
            return fn
        self.pack_done.add(fn)
        struct = self.model.structs[resolved]

        body: list[str] = []
        body.append(f"static void {fn}(BitWriter &writer, const {resolved} &value) {{")
        for field in struct.fields:
            body.extend(self.emit_pack_value(f"value.{field.name}", field.type_name, field.context, field.dims, 1))
        body.append("}")
        body.append("")
        self.helper_code.extend(body)

        for field in struct.fields:
            if self.is_struct(field.type_name, field.context):
                self.gen_pack(field.type_name, field.context)
        return fn

    def emit_unpack_value(
        self,
        expr: str,
        type_name: str,
        context: str,
        dims: list[str],
        indent: int,
    ) -> list[str]:
        pad = "  " * indent
        if dims:
            dim = clean_dim(dims[0])
            var = f"idx_{sanitize(expr)}_{len(dims)}".replace(".", "_").replace("[", "_").replace("]", "_")
            lines = [f"{pad}for (int {var} = static_cast<int>({dim}) - 1; {var} >= 0; --{var}) {{"]
            lines.extend(self.emit_unpack_value(f"{expr}[{var}]", type_name, context, dims[1:], indent + 1))
            lines.append(f"{pad}}}")
            return lines

        if self.is_struct(type_name, context):
            fn = self.gen_unpack(type_name, context)
            return [f"{pad}{fn}(reader, {expr});"]

        width = self.width_of(type_name, context)
        return [
            f"{pad}{expr} = "
            f"static_cast<std::remove_reference_t<decltype({expr})>>(reader.read_u64({width}));"
        ]

    def emit_pack_value(
        self,
        expr: str,
        type_name: str,
        context: str,
        dims: list[str],
        indent: int,
    ) -> list[str]:
        pad = "  " * indent
        if dims:
            dim = clean_dim(dims[0])
            var = f"idx_{sanitize(expr)}_{len(dims)}".replace(".", "_").replace("[", "_").replace("]", "_")
            lines = [f"{pad}for (int {var} = static_cast<int>({dim}) - 1; {var} >= 0; --{var}) {{"]
            lines.extend(self.emit_pack_value(f"{expr}[{var}]", type_name, context, dims[1:], indent + 1))
            lines.append(f"{pad}}}")
            return lines

        if self.is_struct(type_name, context):
            fn = self.gen_pack(type_name, context)
            return [f"{pad}{fn}(writer, {expr});"]

        width = self.width_of(type_name, context)
        return [f"{pad}writer.write_u64({width}, static_cast<uint64_t>({expr}));"]


FRONT_GLUE_IMPL = r'''
static void golden_front_bpu_input_comb(const FrontBpuInputCombIn &input,
                                        FrontBpuInputCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  output.bpu_in = input.bpu_seed;
  output.bpu_in.refetch = input.do_refetch;
  output.bpu_in.refetch_address = input.refetch_addr;
  output.bpu_in.icache_read_ready = input.icache_ready;
}

static void golden_front_global_control_comb(const FrontGlobalControlCombIn &input,
                                             FrontGlobalControlCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  output.global_reset = input.reset;
  output.global_refetch = input.backend_refetch || input.predecode_refetch_snapshot;
  output.refetch_address =
      input.backend_refetch ? input.backend_refetch_address
                            : input.predecode_refetch_address_snapshot;
}

static void golden_front_read_enable_comb(const FrontReadEnableCombIn &input,
                                          FrontReadEnableCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  output.fetch_addr_fifo_read_enable_slot0 =
      input.icache_ready && !input.fetch_addr_fifo_empty_latch_snapshot &&
      !input.global_reset && !input.global_refetch;
#if FRONTEND_IDEAL_ICACHE_DUAL_REQ_ACTIVE
  output.fetch_addr_fifo_read_enable_slot1_candidate =
      output.fetch_addr_fifo_read_enable_slot0 && input.icache_ready_2;
#endif
  output.predecode_can_run_old =
      !input.fifo_empty_latch_snapshot && !input.ptab_empty_latch_snapshot &&
      !input.front2back_fifo_full_latch_snapshot && !input.global_reset &&
      !input.global_refetch;
  output.inst_fifo_read_enable = output.predecode_can_run_old;
  output.ptab_read_enable = output.predecode_can_run_old;
  output.front2back_read_enable = input.backend_fifo_read_enable;
}

static void golden_front_read_stage_input_comb(
    const FrontReadStageInputCombIn &input,
    FrontReadStageInputCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  output.fetch_addr_fifo_reset = input.global_reset;
  output.fetch_addr_fifo_refetch = input.global_refetch;
  output.fetch_addr_fifo_read_enable = input.fetch_addr_fifo_read_enable_slot0;
  output.fifo_reset = input.global_reset;
  output.fifo_refetch = input.global_refetch;
  output.fifo_read_enable = input.inst_fifo_read_enable;
  output.ptab_reset = input.global_reset;
  output.ptab_refetch = input.global_refetch;
  output.ptab_read_enable = input.ptab_read_enable;
  output.front2back_fifo_reset = input.global_reset;
  output.front2back_fifo_refetch = input.backend_refetch;
  output.front2back_fifo_read_enable = input.front2back_read_enable;
}

static void golden_front_bpu_control_comb(const FrontBpuControlCombIn &input,
                                          FrontBpuControlCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  output.bpu_stall =
      input.fetch_addr_fifo_full_latch_snapshot || input.ptab_full_latch_snapshot;
  output.bpu_can_run = !output.bpu_stall || input.global_reset || input.global_refetch;
  output.bpu_icache_ready = !input.fetch_addr_fifo_full_latch_snapshot;

  FrontBpuInputCombOut bpu_input_out{};
  golden_front_bpu_input_comb(
      FrontBpuInputCombIn{input.bpu_in_seed, input.global_refetch,
                          input.refetch_address, output.bpu_icache_ready},
      bpu_input_out);
  output.bpu_in = bpu_input_out.bpu_in;
  if (!output.bpu_can_run) {
    output.bpu_in.icache_read_ready = false;
  }

  output.bpu_input.refetch = output.bpu_in.refetch;
  output.bpu_input.refetch_address = output.bpu_in.refetch_address;
  output.bpu_input.icache_read_ready = output.bpu_in.icache_read_ready;
  for (int i = 0; i < COMMIT_WIDTH; i++) {
    output.bpu_input.in_update_base_pc[i] = output.bpu_in.predict_base_pc[i];
    output.bpu_input.in_upd_valid[i] = output.bpu_in.back2front_valid[i];
    output.bpu_input.in_actual_dir[i] = output.bpu_in.actual_dir[i];
    output.bpu_input.in_actual_br_type[i] = output.bpu_in.actual_br_type[i];
    output.bpu_input.in_actual_targets[i] = output.bpu_in.actual_target[i];
    output.bpu_input.in_pred_dir[i] = output.bpu_in.predict_dir[i];
    output.bpu_input.in_alt_pred[i] = output.bpu_in.alt_pred[i];
    output.bpu_input.in_pcpn[i] = output.bpu_in.pcpn[i];
    output.bpu_input.in_altpcpn[i] = output.bpu_in.altpcpn[i];
    for (int j = 0; j < 4; j++) {
      output.bpu_input.in_tage_tags[i][j] = output.bpu_in.tage_tag[i][j];
      output.bpu_input.in_tage_idxs[i][j] = output.bpu_in.tage_idx[i][j];
    }
    output.bpu_input.in_sc_used[i] = output.bpu_in.sc_used[i];
    output.bpu_input.in_sc_pred[i] = output.bpu_in.sc_pred[i];
    output.bpu_input.in_sc_sum[i] = output.bpu_in.sc_sum[i];
    for (int t = 0; t < BPU_SCL_META_NTABLE; ++t) {
      output.bpu_input.in_sc_idx[i][t] = output.bpu_in.sc_idx[i][t];
    }
    output.bpu_input.in_loop_used[i] = output.bpu_in.loop_used[i];
    output.bpu_input.in_loop_hit[i] = output.bpu_in.loop_hit[i];
    output.bpu_input.in_loop_pred[i] = output.bpu_in.loop_pred[i];
    output.bpu_input.in_loop_idx[i] = output.bpu_in.loop_idx[i];
    output.bpu_input.in_loop_tag[i] = output.bpu_in.loop_tag[i];
  }
}

static void golden_front_ptab_write_comb(const FrontPtabWriteCombIn &input,
                                         FrontPtabWriteCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  output.ptab_in.reset = input.global_reset;
  output.ptab_in.refetch = input.global_refetch;
  output.ptab_in.read_enable = false;
  output.ptab_in.write_enable = input.ptab_can_write;
  if (!input.ptab_can_write) {
    return;
  }

  const BPU_TOP::OutputPayload &bpu_output = input.bpu_output;
  for (int i = 0; i < FETCH_WIDTH; i++) {
    output.ptab_in.predict_dir[i] = bpu_output.out_pred_dir[i];
    output.ptab_in.predict_base_pc[i] = bpu_output.out_pred_base_pc + (i * 4);
    output.ptab_in.alt_pred[i] = bpu_output.out_alt_pred[i];
    output.ptab_in.altpcpn[i] = bpu_output.out_altpcpn[i];
    output.ptab_in.pcpn[i] = bpu_output.out_pcpn[i];
    for (int j = 0; j < 4; j++) {
      output.ptab_in.tage_idx[i][j] = bpu_output.out_tage_idxs[i][j];
      output.ptab_in.tage_tag[i][j] = bpu_output.out_tage_tags[i][j];
    }
    output.ptab_in.sc_used[i] = bpu_output.out_sc_used[i];
    output.ptab_in.sc_pred[i] = bpu_output.out_sc_pred[i];
    output.ptab_in.sc_sum[i] = bpu_output.out_sc_sum[i];
    for (int t = 0; t < BPU_SCL_META_NTABLE; ++t) {
      output.ptab_in.sc_idx[i][t] = bpu_output.out_sc_idx[i][t];
    }
    output.ptab_in.loop_used[i] = bpu_output.out_loop_used[i];
    output.ptab_in.loop_hit[i] = bpu_output.out_loop_hit[i];
    output.ptab_in.loop_pred[i] = bpu_output.out_loop_pred[i];
    output.ptab_in.loop_idx[i] = bpu_output.out_loop_idx[i];
    output.ptab_in.loop_tag[i] = bpu_output.out_loop_tag[i];
  }
  output.ptab_in.predict_next_fetch_address = bpu_output.predict_next_fetch_address;
  output.ptab_in.need_mini_flush = bpu_output.mini_flush_req;
}

static void golden_front_checker_input_comb(const FrontCheckerInputCombIn &input,
                                            FrontCheckerInputCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  for (int i = 0; i < FETCH_WIDTH; i++) {
    output.checker_in.predict_dir[i] = input.ptab_out.predict_dir[i];
    output.checker_in.predecode_type[i] = input.fifo_out.predecode_type[i];
    output.checker_in.predecode_target_address[i] =
        input.fifo_out.predecode_target_address[i];
  }
  output.checker_in.seq_next_pc = input.fifo_out.seq_next_pc;
  output.checker_in.predict_next_fetch_address =
      input.ptab_out.predict_next_fetch_address;
}

static void golden_front_front2back_write_comb(
    const FrontFront2backWriteCombIn &input,
    FrontFront2backWriteCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  constexpr uint32_t kPcpnMask = (1u << pcpn_t_BITS) - 1u;
  constexpr uint32_t kTageIdxMask = (1u << tage_idx_t_BITS) - 1u;
  constexpr uint32_t kTageTagMask = (1u << tage_tag_t_BITS) - 1u;
  for (int i = 0; i < FETCH_WIDTH; i++) {
    output.front2back_fifo_in.fetch_group[i] = input.fifo_out.instructions[i];
    output.front2back_fifo_in.page_fault_inst[i] = input.fifo_out.page_fault_inst[i];
    output.front2back_fifo_in.inst_valid[i] = input.fifo_out.inst_valid[i];
    output.front2back_fifo_in.predict_dir_corrected[i] =
        input.checker_out.predict_dir_corrected[i];
    output.front2back_fifo_in.predict_base_pc[i] = input.ptab_out.predict_base_pc[i];
    output.front2back_fifo_in.alt_pred[i] = input.ptab_out.alt_pred[i];
    output.front2back_fifo_in.altpcpn[i] =
        static_cast<uint8_t>(input.ptab_out.altpcpn[i] & kPcpnMask);
    output.front2back_fifo_in.pcpn[i] =
        static_cast<uint8_t>(input.ptab_out.pcpn[i] & kPcpnMask);
    for (int j = 0; j < 4; j++) {
      output.front2back_fifo_in.tage_idx[i][j] =
          input.ptab_out.tage_idx[i][j] & kTageIdxMask;
      output.front2back_fifo_in.tage_tag[i][j] =
          input.ptab_out.tage_tag[i][j] & kTageTagMask;
    }
    output.front2back_fifo_in.sc_used[i] = input.ptab_out.sc_used[i];
    output.front2back_fifo_in.sc_pred[i] = input.ptab_out.sc_pred[i];
    output.front2back_fifo_in.sc_sum[i] = input.ptab_out.sc_sum[i];
    for (int t = 0; t < BPU_SCL_META_NTABLE; ++t) {
      output.front2back_fifo_in.sc_idx[i][t] = input.ptab_out.sc_idx[i][t];
    }
    output.front2back_fifo_in.loop_used[i] = input.ptab_out.loop_used[i];
    output.front2back_fifo_in.loop_hit[i] = input.ptab_out.loop_hit[i];
    output.front2back_fifo_in.loop_pred[i] = input.ptab_out.loop_pred[i];
    output.front2back_fifo_in.loop_idx[i] = input.ptab_out.loop_idx[i];
    output.front2back_fifo_in.loop_tag[i] = input.ptab_out.loop_tag[i];

    if (input.use_front2back_output_bypass) {
      output.bypass_front2back_fifo_out.fetch_group[i] = input.fifo_out.instructions[i];
      output.bypass_front2back_fifo_out.page_fault_inst[i] =
          input.fifo_out.page_fault_inst[i];
      output.bypass_front2back_fifo_out.inst_valid[i] = input.fifo_out.inst_valid[i];
      output.bypass_front2back_fifo_out.predict_dir_corrected[i] =
          input.checker_out.predict_dir_corrected[i];
      output.bypass_front2back_fifo_out.predict_base_pc[i] =
          input.ptab_out.predict_base_pc[i];
      output.bypass_front2back_fifo_out.alt_pred[i] = input.ptab_out.alt_pred[i];
      output.bypass_front2back_fifo_out.altpcpn[i] = input.ptab_out.altpcpn[i];
      output.bypass_front2back_fifo_out.pcpn[i] = input.ptab_out.pcpn[i];
      for (int j = 0; j < 4; j++) {
        output.bypass_front2back_fifo_out.tage_idx[i][j] = input.ptab_out.tage_idx[i][j];
        output.bypass_front2back_fifo_out.tage_tag[i][j] = input.ptab_out.tage_tag[i][j];
      }
      output.bypass_front2back_fifo_out.sc_used[i] = input.ptab_out.sc_used[i];
      output.bypass_front2back_fifo_out.sc_pred[i] = input.ptab_out.sc_pred[i];
      output.bypass_front2back_fifo_out.sc_sum[i] = input.ptab_out.sc_sum[i];
      for (int t = 0; t < BPU_SCL_META_NTABLE; ++t) {
        output.bypass_front2back_fifo_out.sc_idx[i][t] = input.ptab_out.sc_idx[i][t];
      }
      output.bypass_front2back_fifo_out.loop_used[i] = input.ptab_out.loop_used[i];
      output.bypass_front2back_fifo_out.loop_hit[i] = input.ptab_out.loop_hit[i];
      output.bypass_front2back_fifo_out.loop_pred[i] = input.ptab_out.loop_pred[i];
      output.bypass_front2back_fifo_out.loop_idx[i] = input.ptab_out.loop_idx[i];
      output.bypass_front2back_fifo_out.loop_tag[i] = input.ptab_out.loop_tag[i];
    }
  }
  output.front2back_fifo_in.predict_next_fetch_address_corrected =
      input.checker_out.predict_next_fetch_address_corrected;
  if (input.use_front2back_output_bypass) {
    output.bypass_front2back_fifo_out.front2back_FIFO_valid = true;
    output.bypass_front2back_fifo_out.predict_next_fetch_address_corrected =
        input.checker_out.predict_next_fetch_address_corrected;
  }
}

static void golden_front_output_comb(const FrontOutputCombIn &input,
                                     FrontOutputCombOut &output) {
  std::memset(&output, 0, sizeof(output));
  const front2back_FIFO_out *out_src = &input.saved_front2back_fifo_out;
  if (!input.saved_front2back_fifo_out.front2back_FIFO_valid &&
      input.use_front2back_output_bypass) {
    out_src = &input.bypass_front2back_fifo_out;
  }
  output.out.FIFO_valid = out_src->front2back_FIFO_valid;
  for (int i = 0; i < FETCH_WIDTH; i++) {
    output.out.instructions[i] = out_src->fetch_group[i];
    output.out.page_fault_inst[i] = out_src->page_fault_inst[i];
    output.out.predict_dir[i] = out_src->predict_dir_corrected[i];
    output.out.pc[i] = out_src->predict_base_pc[i];
    output.out.alt_pred[i] = out_src->alt_pred[i];
    output.out.altpcpn[i] = out_src->altpcpn[i];
    output.out.pcpn[i] = out_src->pcpn[i];
    for (int j = 0; j < 4; j++) {
      output.out.tage_idx[i][j] = out_src->tage_idx[i][j];
      output.out.tage_tag[i][j] = out_src->tage_tag[i][j];
    }
    output.out.sc_used[i] = out_src->sc_used[i];
    output.out.sc_pred[i] = out_src->sc_pred[i];
    output.out.sc_sum[i] = out_src->sc_sum[i];
    for (int t = 0; t < BPU_SCL_META_NTABLE; ++t) {
      output.out.sc_idx[i][t] = out_src->sc_idx[i][t];
    }
    output.out.loop_used[i] = out_src->loop_used[i];
    output.out.loop_hit[i] = out_src->loop_hit[i];
    output.out.loop_pred[i] = out_src->loop_pred[i];
    output.out.loop_idx[i] = out_src->loop_idx[i];
    output.out.loop_tag[i] = out_src->loop_tag[i];
    output.out.inst_valid[i] = out_src->inst_valid[i];
  }
  output.out.predict_next_fetch_address =
      out_src->predict_next_fetch_address_corrected;
}
'''


CALLS = {
    "predecode_comb": "predecode_comb(in, out);",
    "predecode_checker_comb": "predecode_checker_comb(in, out);",
    "type_predictor_pre_read_comb": "g_type_predictor.pre_read_comb(in, out);",
    "type_pred_comb": "g_type_predictor.type_pred_comb(in, out);",
    "tage_pre_read_comb": "g_tage.tage_pre_read_comb(in, out);",
    "tage_comb": "g_tage.tage_comb(in, out);",
    "btb_pre_read_comb": "g_btb.btb_pre_read_comb(in, out);",
    "btb_post_read_req_comb": "g_btb.btb_post_read_req_comb(in, out);",
    "btb_comb": "g_btb.btb_comb(in, out);",
    "bpu_pre_read_req_comb": "golden_bpu().bpu_pre_read_req_comb(in, out);",
    "bpu_post_read_req_comb": "golden_bpu().bpu_post_read_req_comb(in, out);",
    "bpu_submodule_bind_comb": "golden_bpu().bpu_submodule_bind_comb(in, out);",
    "bpu_predict_main_comb": "golden_bpu().bpu_predict_main_comb(in, out);",
    "bpu_hist_comb": "golden_bpu().bpu_hist_comb(in, out);",
    "bpu_queue_comb": "golden_bpu().bpu_queue_comb(in, out);",
    "front_global_control_comb": "golden_front_global_control_comb(in, out);",
    "front_read_enable_comb": "golden_front_read_enable_comb(in, out);",
    "front_read_stage_input_comb": "golden_front_read_stage_input_comb(in, out);",
    "front_bpu_control_comb": "golden_front_bpu_control_comb(in, out);",
    "front_ptab_write_comb": "golden_front_ptab_write_comb(in, out);",
    "front_checker_input_comb": "golden_front_checker_input_comb(in, out);",
    "front_front2back_write_comb": "golden_front_front2back_write_comb(in, out);",
    "front_output_comb": "golden_front_output_comb(in, out);",
}


def generate_cpp(model, scan) -> str:
    gen = CodeGen(model)
    modules = [m for m in scan.MODULES if m.name not in FIFO_MODULES]
    for spec in modules:
        gen.gen_unpack(spec.in_type)
        gen.gen_pack(spec.out_type)

    lines: list[str] = []
    lines.append("// Generated by top/tools/generate_frontend_cpp_golden.py.")
    lines.append("// Simulation-only C++ golden slice bridge for frontend BSD wrappers.")
    lines.append("#include \"svdpi.h\"")
    lines.append("#include <cassert>")
    lines.append("#include <cstdint>")
    lines.append("#include <cstdlib>")
    lines.append("#include <cstring>")
    lines.append("#include <iostream>")
    lines.append("#include <type_traits>")
    lines.append("#include <vector>")
    lines.append("")
    lines.append("#define private public")
    lines.append("#include \"train_IO.h\"")
    lines.append("#undef private")
    lines.append("")
    lines.append("#ifdef CPP_GOLDEN_USE_EXTERNAL_BPU_TOP")
    lines.append("extern BPU_TOP *g_bpu_top;")
    lines.append("static BPU_TOP &golden_bpu() {")
    lines.append("  assert(g_bpu_top != nullptr);")
    lines.append("  return *g_bpu_top;")
    lines.append("}")
    lines.append("#else")
    lines.append("BPU_TOP g_bpu;")
    lines.append("BPU_TOP *g_bpu_top = &g_bpu;")
    lines.append("static BPU_TOP &golden_bpu() { return g_bpu; }")
    lines.append("#endif")
    lines.append("static TypePredictor g_type_predictor;")
    lines.append("static TAGE_TOP g_tage;")
    lines.append("static BTB_TOP g_btb;")
    lines.append("")
    lines.append("class BitReader {")
    lines.append(" public:")
    lines.append("  BitReader(const svBitVecVal *data, int total_bits) : data_(data), bit_(total_bits) {}")
    lines.append("  uint64_t read_u64(int width) {")
    lines.append("    bit_ -= width;")
    lines.append("    uint64_t value = 0;")
    lines.append("    for (int i = 0; i < width; ++i) {")
    lines.append("      const int src_bit = bit_ + i;")
    lines.append("      const uint32_t word = data_[src_bit >> 5];")
    lines.append("      if ((word >> (src_bit & 31)) & 1u) {")
    lines.append("        value |= (uint64_t{1} << i);")
    lines.append("      }")
    lines.append("    }")
    lines.append("    return value;")
    lines.append("  }")
    lines.append(" private:")
    lines.append("  const svBitVecVal *data_;")
    lines.append("  int bit_;")
    lines.append("};")
    lines.append("")
    lines.append("class BitWriter {")
    lines.append(" public:")
    lines.append("  BitWriter(svBitVecVal *data, int total_bits) : data_(data), bit_(total_bits) {")
    lines.append("    const int words = (total_bits + 31) / 32;")
    lines.append("    for (int i = 0; i < words; ++i) data_[i] = 0;")
    lines.append("  }")
    lines.append("  void write_u64(int width, uint64_t value) {")
    lines.append("    bit_ -= width;")
    lines.append("    for (int i = 0; i < width; ++i) {")
    lines.append("      if ((value >> i) & 1u) {")
    lines.append("        const int dst_bit = bit_ + i;")
    lines.append("        data_[dst_bit >> 5] |= (svBitVecVal{1} << (dst_bit & 31));")
    lines.append("      }")
    lines.append("    }")
    lines.append("  }")
    lines.append(" private:")
    lines.append("  svBitVecVal *data_;")
    lines.append("  int bit_;")
    lines.append("};")
    lines.append("")
    lines.extend(gen.helper_code)
    lines.append(FRONT_GLUE_IMPL)
    lines.append("")
    for spec in modules:
        in_width = model.width_of(spec.in_type)
        out_width = model.width_of(spec.out_type)
        unpack_fn = gen.gen_unpack(spec.in_type)
        pack_fn = gen.gen_pack(spec.out_type)
        lines.append(f"extern \"C\" void cpp_golden_{spec.name}(const svBitVecVal *pi, svBitVecVal *po) {{")
        lines.append(f"  {spec.in_type} in{{}};")
        lines.append(f"  {spec.out_type} out{{}};")
        lines.append(f"  BitReader reader(pi, {in_width});")
        lines.append(f"  {unpack_fn}(reader, in);")
        lines.append(f"  {CALLS[spec.name]}")
        lines.append(f"  BitWriter writer(po, {out_width});")
        lines.append(f"  {pack_fn}(writer, out);")
        lines.append("}")
        lines.append("")
    return "\n".join(lines)


def generate_macro() -> str:
    return """// Simulation-only helper for C++ golden BSD mode.
`ifndef CPP_GOLDEN_BSD_MACROS_VH
`define CPP_GOLDEN_BSD_MACROS_VH

`define CPP_GOLDEN_BSD(MOD_NAME, IN_WIDTH, OUT_WIDTH) \\
    import "DPI-C" context function void cpp_golden_``MOD_NAME( \\
        input  bit [IN_WIDTH-1:0]  dpi_pi, \\
        output bit [OUT_WIDTH-1:0] dpi_po \\
    ); \\
    reg [OUT_WIDTH-1:0] po_cpp_golden; \\
    always @* begin \\
        cpp_golden_``MOD_NAME(pi, po_cpp_golden); \\
    end \\
    assign po = po_cpp_golden;

`endif
"""


def patch_rtl(scan) -> list[Path]:
    patched: list[Path] = []
    for spec in scan.MODULES:
        if spec.name in FIFO_MODULES:
            continue
        path = FRONT_DIR / scan.RTL_FILES[spec.name]
        text = path.read_text(encoding="utf-8")
        if "USE_CPP_GOLDEN_BSD" in text:
            continue
        module_name = f"{spec.name}_bsd_top"
        # Match the inside of the bsd module after the port list. This replaces
        # only the placeholder assign/localparam area, keeping module ports intact.
        pattern = re.compile(
            rf"(module\s+{re.escape(module_name)}\s*#\s*\(.*?\)\s*\(.*?\);\s*)(.*?)(\s*endmodule)",
            re.S,
        )
        match = pattern.search(text)
        if not match:
            raise RuntimeError(f"cannot find {module_name} in {path}")
        body = match.group(2)
        if "assign po" not in body:
            raise RuntimeError(f"cannot locate placeholder assign in {path}")
        params = re.findall(r"parameter\s+(?:integer\s+)?([A-Za-z_]\w*)\s*=", match.group(1))
        if len(params) < 2:
            raise RuntimeError(f"cannot find pi/po width parameters in {path}")
        in_param, out_param = params[0], params[1]
        replacement_body = f"""
`ifdef USE_CPP_GOLDEN_BSD
    `include "slices/cpp_golden/cpp_golden_bsd_macros.vh"
    `CPP_GOLDEN_BSD({spec.name}, {in_param}, {out_param})
`else
{body.rstrip()}
`endif
"""
        replacement_body = "\n".join(line.rstrip() for line in replacement_body.splitlines()) + "\n"
        new_text = text[: match.start()] + match.group(1) + replacement_body + match.group(3) + text[match.end() :]
        path.write_text(new_text, encoding="utf-8")
        patched.append(path)
    return patched


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("simulator_front", type=Path)
    parser.add_argument("--patch-rtl", action="store_true")
    args = parser.parse_args()

    scan = load_scan_module()
    model = scan.Model(args.simulator_front)
    model.load()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "cpp_golden_bsd.cpp").write_text(generate_cpp(model, scan), encoding="utf-8")
    (OUT_DIR / "cpp_golden_bsd_macros.vh").write_text(generate_macro(), encoding="utf-8")
    if args.patch_rtl:
        patched = patch_rtl(scan)
        print(f"patched_rtl_files={len(patched)}")
    print(f"generated {OUT_DIR / 'cpp_golden_bsd.cpp'}")
    print(f"generated {OUT_DIR / 'cpp_golden_bsd_macros.vh'}")


if __name__ == "__main__":
    main()
