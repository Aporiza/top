# front_top 三段式与 comb_calc/seq_read 自查

本文用于回答“前端三段式里 `comb_calc` 是否藏了额外逻辑、有没有没有从输入进来却影响输出的状态”这个问题。

## 1. 顶层调用主线

`simulator-front/front-end/front_top.cpp` 的主入口固定是：

```text
front_seq_read -> front_comb_calc -> front_seq_write
```

- `front_seq_read`：读上一拍寄存器、FIFO、PTAB、BPU、ICache 的状态快照。
- `front_comb_calc`：本拍组合逻辑总调度，串起各个正式 comb 和必要的 FIFO/PTAB/BPU 读写请求。
- `front_seq_write`：周期末统一写回寄存器、FIFO、PTAB、BPU 等状态。

所以不能只看 27 个正式 comb，还必须看 `comb_calc` 中间有没有 `seq_read` 或表项读取。27 个 comb 是训练边界，`comb_calc` 是把这些训练边界按时序顺序接起来的胶水层。

## 2. FIFO/PTAB 的情况

涉及文件：

- `simulator-front/front-end/fifo/fetch_address_FIFO.cpp`
- `simulator-front/front-end/fifo/instruction_FIFO.cpp`
- `simulator-front/front-end/fifo/PTAB.cpp`
- `simulator-front/front-end/fifo/front2bank_FIFO.cpp`

这四类模块都有自己的：

```text
seq_read -> comb_calc -> seq_write
```

当前 RTL 中没有等待外部 BSD 提供 FIFO/PTAB 逻辑，而是在对应 `*_comb_top.v` / `*_comb_bsd_top.v` 中直接用 Verilog 实现队列行为。它们的隐式状态来源是 FIFO/PTAB 内部 `mem/head/tail/count`，当前 RTL 已经显式放在模块内部寄存器里，不属于“从外部看不到却影响输出”的隐藏 C++ 函数。

自查结论：

- FIFO/PTAB 的旧状态通过 `*_rd_snapshot_reg` 或模块内部寄存器参与组合计算。
- `reset` 和 `refetch` 是同步清空条件，`rst_n` 是硬复位。
- push/pop/full/empty/read_valid 逻辑已在 Verilog 内部实现。

## 3. predecode 与 checker 的情况

涉及文件：

- `simulator-front/front-end/predecode.cpp`
- `simulator-front/front-end/predecode_checker.cpp`

`predecode_seq_read` 只把 `inst` 和 `pc` 拷贝到 read data。

`predecode_checker_seq_read` 只把 checker 输入结构拷贝到 read data。

这两个 `seq_read` 不读持久寄存器、不读 RAM、不读 FIFO，所以不会引入额外隐藏状态。RTL 中 `predecode_comb_top` 和 `predecode_checker_comb_top` 直接按输入 bundle 运行是合理的。

需要注意的有效门控已经补上：

```text
predecode_can_run_gate = inst_fifo_read_enable && !ptab_dummy_entry
checker_out_validated  = predecode_can_run_gate ? checker_out : 0
```

原因是 C++ 里 checker 只有在 `predecode_can_run` 为真时才运行；如果不加这个门，checker 可能在 FIFO/PTAB 没有有效对齐输出时误触发 `predecode_refetch`。

## 4. BPU 的情况

涉及文件：

- `simulator-front/front-end/BPU/BPU.h`
- `simulator-front/front-end/BPU/type_predictor/TypePredictor.h`
- `simulator-front/front-end/BPU/dir_predictor/TAGE_top.h`
- `simulator-front/front-end/BPU/target_predictor/BTB_top.h`

BPU 是本次自查里最需要重点说明的地方。`BPU_TOP::bpu_comb_calc` 的源码顺序是：

```text
bpu_pre_read_req_comb
-> bpu_data_seq_read
-> bpu_post_read_req_comb
-> bpu_submodule_seq_read
-> bpu_core_comb_calc
```

其中 `bpu_core_comb_calc` 内部继续调用：

```text
type_pred_comb_calc
bpu_submodule_bind_comb
tage_comb_calc
btb_comb_calc
bpu_predict_main_comb
bpu_hist_comb
bpu_queue_comb
```

这里不是单纯的 13 个 BPU comb 直连。中间有这些显式读状态步骤：

- `bpu_seq_read`：读取 BPU 顶层状态快照，例如 `pc_reg`、`pc_can_send_to_icache`、`do_pred_latch`、update queue 指针/count、GHR/FH/path/RAS、TAGE/BTB latch、2-ahead/mini-flush 状态等。
- `bpu_data_seq_read`：根据 `bpu_pre_read_req_comb` 生成的 read slot/index，读取 update queue、NLP 表项、RAS 栈顶等。
- `bpu_submodule_seq_read`：读取 TypePredictor、TAGE、BTB 的表项快照。
- `type_pred_comb_calc` / `tage_comb_calc` / `btb_comb_calc` 内部也有各自的 pre-read、data seq-read 和 core comb 组织关系。

因此学长担心的点是成立的：如果 RTL 只是把 13 个 BPU comb wrapper 串起来，但没有把这些 seq_read 读出的寄存器/RAM/table 数据明确接入对应 comb 输入，就只能说明“端口形状能连上”，不能说明 BPU 功能已经等价。

当前 `front_end/bpu/bpu_top.v` 的状态：

- 已经有 BPU_TOP 级别寄存器骨架。
- 已经例化 13 个 BPU 相关 comb wrapper。
- 当前 `bpu_top` 的部分 route bundle 仍是占位式拼接，真实 TypePredictor/TAGE/BTB/NLP/RAS/update queue 读数据还需要继续细化到对应输入字段。

自查结论：

```text
前端 glue / FIFO / PTAB / predecode / checker 的门控目前没有看到新的明显漏门。
BPU 不是“漏一个门”的问题，而是 seq_read/table read 还需要进一步显式建模。
当前 VCS/Verilator 通过代表端口和语法可编译，不代表 BPU C-RTL 功能等价。
```

## 5. 给学长的汇报口径

可以这样说：

```text
我重新按 simulator-front 的三段式主线查了一遍。
front_top 的执行顺序是 front_seq_read -> front_comb_calc -> front_seq_write。
27 个 comb 是正式训练边界，但 comb_calc 里还负责把 FIFO/PTAB/BPU 的 seq_read 和 comb 串起来。

FIFO/PTAB 这四个不会给 BSD 的模块已经在 Verilog 里直接实现，reset/refetch/push/pop/full/empty/read_valid 都是显式状态。
predecode 和 checker 的 seq_read 只是输入拷贝，没有隐藏寄存器；checker 已经加了 predecode_can_run 的门控，避免无效 FIFO/PTAB 输出误触发 predecode_refetch。

BPU 部分需要单独标注：源码的 bpu_comb_calc 中间有 bpu_data_seq_read 和 bpu_submodule_seq_read，会读取 update queue、NLP、TypePredictor、TAGE、BTB 等状态。
所以当前 bpu_top 不能只理解成 13 个 comb 直接相连，后续需要把这些读出的表项和寄存器快照按源码字段显式接到各个 comb 输入。
目前 VCS/Verilator 通过只能证明端口与语法可编译，不能证明 BPU 功能等价。
```

## 6. 后续动作

1. 继续把 `bpu_top.v` 中占位式 route bundle 拆成源码字段级拼接。
2. 明确列出 BPU 中每个 `seq_read` 对应的 RTL 存储体：寄存器、update queue、NLP table、TypePredictor table、TAGE table、BTB table、RAS。
3. 对 TypePredictor/TAGE/BTB 的 `*_comb_calc` 再做一层同样审计，确认每个表读数据都来自显式输入或显式 RAM 输出。
4. 后续 C-RTL 验证时，不只检查端口编译，还要用同一组输入比较 C++ `comb_calc` 输出和 RTL 输出。
