Mode: placeholder

# Thread 编排与 Handoff（占位）

仅在独立任务、主子任务或并行写入时使用。普通单任务不需要额外编排。

## Handoff 最小字段

```text
目标：<一个可验收结果>
当前事实与来源：<Issue、repo、branch、文档或 contract>
Included：<范围>
Excluded：<范围>
Read scope：<路径或系统>
Write scope：<路径或 none>
Write lease：<id 或 none>
允许的副作用：<read-only / 文件 / Git / 外部系统>
验证命令：<有序命令>
Review policy：<standard|strict>
停止条件：<冲突、缺授权或不安全状态>
最终回传：<改动、验证、blocking_findings、风险、next action>
```

固定边界：

- 只读任务不需要 lease；可写任务必须有互不重叠的 `write_lease`。
- 执行任务不扩大 Goal，不覆盖既有用户改动。
- `ready` 只代表可交回主任务，不代表完成。
- 发生 integration event 后，主任务必须执行 post-integration verify，并记录 `post_integration_verify_summary.status: executed`。
- 没有 integration event 时不制造第二次验证。
- 共享状态使用 control plane 的 `Current State` 与 `Thread Status`。
