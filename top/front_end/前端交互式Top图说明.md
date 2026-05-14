# 前端交互式 Top 图说明

## 1. 文件位置

交互式示意图文件：

```text
top/front_end/front_top_interactive.html
```

该文件可以直接用浏览器打开，不依赖 Verdi、nWave、网络或额外 JS 库。

## 2. 图中模块口径

本图采用老板/学长截图中更细的 **comb 训练单元口径**，不是之前的 8 个一级 wrapper 口径。

当前正式依据来自新版模拟器仓库：

```text
simulator-new/front-end/TRAINING_FUNCTION_LIST.md
```

其中原正式列出的前端待训练 comb 单元为 27 个；按最新全分支训练口径，`bpu_nlp_comb`、Oracle、ICache slot1 和两个 bypass 也需要在图中展开说明。

当前 HTML 以 `SimCpu::front_cycle()` 为函数运行顺序标准：`CONFIG_BPU` 主路径、Oracle `step_oracle()`、`ENABLE_2AHEAD` / NLP、ICache slot1、fetch-to-ICache bypass、ICache-to-predecode bypass 和 front2back-output bypass 都保留路径高亮和源码依据。

## 3. 与 8 个一级 wrapper 的关系

之前的 8 个模块是 RTL wrapper 顶层结构：

```text
bpu_top
fetch_address_fifo_top
icache_top
predecode_top
instruction_fifo_top
ptab_top
predecode_checker_top
front2back_fifo_top
```

当前 HTML 图进一步展开到 comb 训练单元，例如：

```text
bpu_pre_read_req_comb
bpu_post_read_req_comb
bpu_submodule_bind_comb
bpu_predict_main_comb
bpu_hist_comb
bpu_queue_comb
front_global_control_comb
front_read_enable_comb
front_output_comb
...
```

所以两种说法并不冲突：

- 8 个是前端一级 wrapper 视角。
- 27 个是原训练 IO / comb 单元视角；全分支图在此基础上增加宏控制分支和 Oracle 参考路径。

## 4. bpu_hist 的展开说明

新版 `TRAINING_FUNCTION_LIST.md` 正式清单里保留的是：

```text
bpu_hist_comb
```

学长截图中的：

```text
bpu_hist_commit_ctrl_comb
bpu_hist_pred_ctrl_comb
bpu_hist_ras_step_comb
bpu_hist_step_comb
```

属于 `bpu_hist_comb` 的生成细分子块。HTML 图中将这些子块挂在 `bpu_hist_comb` 后面，用于表达截图中的层级展开关系。

## 5. 使用方式

打开 `front_top_interactive.html` 后可以：

- 鼠标滚轮缩放。
- 鼠标拖拽平移。
- 点击模块查看来源文件、IO 位宽、说明和源码依据。
- 点击连线查看源模块、目标模块、语义和对应源码依据。
- 点击左侧路径按钮高亮对应传输路径，并查看该路径的源码依据。
- 使用“复位视图”回到默认视图。

## 6. 当前高亮路径

HTML 中提供以下路径高亮：

- 取指主路径
- BPU 预测内部路径
- 预测信息 PTAB 路径
- checker 修正路径
- 前端输出路径
- bpu_hist 展开路径

## 7. 结论

该 HTML 图用于替代 Verdi/nWave 的静态 top 截图，重点表达前端 top 在新版模拟器中的模块层级和主要数据流。

右侧详情面板已经给模块、连线和路径补充 `simulator-new/...:line` 形式的源码依据，方便汇报时直接定位到 `front_top.cpp`、`rv_simu_mmu_v2.cpp`、BPU 子模块、FIFO、PTAB、predecode/checker 等原始实现。

它不是仿真波形，也不表达时序波形变化；它表达的是模块之间的结构关系、训练 comb 单元分组和关键传输路径。
