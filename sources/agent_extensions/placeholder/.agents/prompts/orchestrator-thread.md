Mode: placeholder

# Orchestrator Thread Prompt（占位）

## 用途

这份文件用于主 thread / 子 thread 编排的入口，包括：

- root goal 下发到多个 thread 的 `goal-orchestration`
- 单张 Execution Issue 的 `single-issue` 编排
- Master Issue inventory 的串行推进
- 子 thread handoff、`write_lease`、`Current State`、`Thread Status`

当前是占位文件，不代表仓库已经冻结完整多 thread 编排语义。

## 当前仍缺的 repo-local 决策

- 是否启用 Codex thread tools，或只使用人工 handoff
- 子 thread worktree / branch 命名约定
- `write_lease` 是否需要项目级可执行检查
- live E2E 的真实命令、环境和 fallback 规则
- `waiting_on_child` 的定时检查方式

## 临时占位模板骨架

```text
你是本项目的主调度 thread。

Root Goal:
Root Issue:
Orchestration Mode: goal-orchestration | single-issue | master-inventory
Mode:

Write Lease Table:
- lease_id:
- owner_thread:
- role:
- state:
- write_scope:
- next_action:

When child thread is done:
- require fixed Thread Status comment
- do not archive by default
- add 【完成】 to thread title if thread tools are available
- if not available, record title_marker_pending=true in Current State
```

## 使用约束

- 本文件只服务编排 prompt，占位期间不得替代 `docs/harness/control-plane.md` 或 `docs/harness/issue-workflow.md`
- 可写 thread 必须有 `write_lease`
- 子 thread 不自行 merge，不自行扩大范围
- post-integration verify 仍由主 thread 基于最终 repo truth 执行

## 基础 Review / Evidence 编排字段

- gate / freeze 记录 `review_policy` 与 `subagent_review_required`。
- 多仓、多个可写 lease、branch / worktree 集成自动使用 strict，并重新执行验证。
- 验证摘要记录 `evidence_id`、有序命令、session 与验证类型。
- 仅单仓单写入者、同 session、无 integration event 的 deterministic-local 证据可在 post-integration verify 标记 `post_integration_verify_summary.status = reused`；strict、live、环境依赖或不确定时重跑。
