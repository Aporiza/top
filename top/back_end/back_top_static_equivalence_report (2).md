# back_top 静态检查说明

本文件原先记录旧版后端静态等价检查结果。旧结果基于非 `large` 参数和旧接口命名，已经不再作为当前交付依据。

当前后端端口与连接自查统一查看：

```text
top/back_end/后端端口自查汇总.md
```

当前口径：

- 模拟器依据：`simulator-ffc9fad707a7acb0be5c7d4fe7c06d48987c73e0`
- 配置：`large`
- 控制端口：`clk/rst_n`
- BSD 接入端口：`pi/po`
- 统计范围：`back_top` 与 10 个后端一级 `*_top` wrapper 的参数、业务位宽、`pi/po` 拼接顺序、`*_top -> *_bsd_top` 控制端口连接。

当前结论以 `后端端口自查汇总.md` 中的 large 参数交叉核对为准。
