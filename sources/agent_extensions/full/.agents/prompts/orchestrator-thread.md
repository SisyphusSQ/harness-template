Mode: full

# Thread 编排与 Handoff

只在需要创建独立任务、主子任务分工、并行写入或跨 branch / worktree 集成时使用。普通单任务直接按 `AGENTS.md` 与 control plane 执行。

## 1. 主任务职责

主任务负责：

- 冻结 root goal、当前 Issue 和 Acceptance Matrix
- 判断是否真的需要 fan-out
- 分配互不重叠的 read / write scope
- 维护 `Current State`、`Thread Status` 和 Issue writeback
- 回收子任务证据、检查差异、执行集成和最终验证

执行任务只完成 handoff 范围，不自行扩展目标、创建额外交付动作或覆盖其他工作区改动。

## 2. 是否需要拆任务

适合拆分：

- 两个以上相互独立、可以分别验证的执行单元
- 长时间运行的构建、测试、数据采集或外部等待
- 需要独立 reviewer 的 `strict` review
- 跨仓任务需要明确 provider / consumer truth

不适合拆分：

- 单文件或强顺序的小改动
- 多个任务会写同一批文件
- 拆分成本高于执行成本
- 只是为了重复同一份检查

## 3. Handoff 模板

```text
任务标题：<动作或阶段 + 主题>

目标：
<一个可验收结果>

当前事实与来源：
- Issue / Goal: <id or none>
- Repo / branch / worktree: <absolute context>
- Source of truth: <docs, code, contract, runbook>
- Existing changes: <must preserve>

实施范围：
- Included: <items>
- Excluded: <items>
- Read scope: <paths or systems>
- Write scope: <paths or none>
- Write lease: <lease id or none>

允许的副作用：
<files, Git, database, external systems, or read-only>

验证要求：
- Commands: <ordered commands>
- Evidence level: <deterministic-local|environment-dependent|live>
- Review policy: <standard|strict>

停止条件：
- <scope conflict, dirty-worktree conflict, missing authority, unsafe state>

最终回传：
- Changed scope
- Verification result
- blocking_findings
- Residual risks
- Recovery point / next action
```

## 4. Write Lease 与集成

- 只读任务使用 `write_lease: none`。
- 可写任务必须写明仓库、branch / worktree、允许路径和禁止路径。
- 多个可写 lease 不得重叠；发现重叠或用户改动时立即停止并报告。
- 子任务 `ready` 只代表可以交回主任务，不代表 Goal 已完成。
- 主任务集成前核对 write scope、最终 diff 和验证摘要。
- 发生 merge、cherry-pick、patch apply、跨 branch/worktree 汇入或其他 integration event 后，必须执行 post-integration verify，并记录 `post_integration_verify_summary.status: executed`。
- 没有 integration event 时不制造第二次验证。

## 5. Thread Status

```yaml
thread_role: implementer|test|review|integration|explorer
status: dispatched|working|blocked|ready|integrated|done
read_scope: <scope>
write_scope: <scope|none>
write_lease: <id|none>
verification: <commands and result>
blocking_findings: <none|summary>
waiting_on: <dependency|none>
recovery_point: <safe resume point>
next_action: <one concrete action>
```

长任务使用有界等待，不高频轮询。工具不可用时保留同一 Handoff 和状态字段，改用 Issue comment 或人工交接，不另造状态机。
