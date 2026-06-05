# Linear Profile

本文件是 `docs/harness/issue-workflow.md` 的 Linear 兼容 profile。通用 issue 协议、模板和 Done Gate 以 `issue-workflow.md` 为准；本文件只说明 Linear 如何映射通用字段。

## 迁移说明

- 新项目应优先阅读 `docs/harness/issue-workflow.md`
- 旧项目中指向 `docs/harness/linear.md` 的链接可继续保留一个兼容周期
- `Linear 是主协作真相` 已迁移为 `Issue Tracker 是主协作真相`
- `运行反馈默认回写到 Linear` 已迁移为 `运行反馈默认写回 Issue Tracker`
- `结果回写默认写回 Linear` 已迁移为 `结果回写默认写回 Issue Tracker`

## Linear 字段映射

| 通用字段 | Linear 承载方式 |
| --- | --- |
| `Issue Tracker` | Linear workspace / team / project |
| `Issue Store` | Linear issue body、project、state、comment |
| `current_issue_state` | Linear issue state |
| `orchestration_mode` | Linear issue comment 中的 `Current State` 字段 |
| `goal_state` | Linear issue comment 中的 root goal 状态字段 |
| `goal_unit_roster` | Linear issue comment 中的 unit 列表字段 |
| `main_thread` | Linear issue comment 中的主 thread 标识 |
| `threads` | Linear issue comment 中的 thread 列表 |
| `active_write_leases` | Linear issue comment 中的当前写入许可列表 |
| `recent_write_leases` | Linear issue comment 中的最近完成 / 集成 / 释放的 lease 列表 |
| `waiting_on` | Linear issue comment 中的等待对象 |
| `next_check` | Linear issue comment 中的下一次检查时间或触发条件 |
| `Master Issue` | 标题带 `【Master】` 的 Linear issue |
| `Execution Issue` | 单张可执行 Linear issue |
| `Comment Contract` | Linear issue comment |
| `Writeback Contract` | Linear issue body 或 comment |
| `recovery_point` | Linear comment 中的恢复点字段 |
| `next_action` | Linear comment 中的下一步字段 |

## Linear Profile 规则

- Linear project 可以承接项目级容器，但不能替代 repo 执行真相。
- Linear issue body 应保留 `Goal / Included / Excluded / Acceptance Matrix / Stop When / Verification Commands`。
- Linear comment 应保留 `verification_summary / review_summary / writeback_summary / residual_risks / recovery_point / next_action`。
- Linear `Current State` comment 是多 thread 编排的当前状态快照，默认只由主 thread 更新。
- 子 thread 不直接更新 `Current State` comment；子 thread 只追加固定 `Thread Status` comment。
- Linear issue body 不作为高频状态写入面，避免多个 thread 覆盖稳定范围字段。
- `write_lease`、`Thread Status`、post-integration verify 和 live E2E gate 的通用 contract 以 `docs/harness/issue-workflow.md` 为准。
- 子 thread 完成后不默认归档；标题应加 `【完成】` 标识。该标识只代表 thread 自身完成，不代表 Linear issue Done。
- 如果 Linear API 或权限不可用，先把临时恢复点写入 `.agents/state/`，恢复后再回写 Linear。

## Linear Current State

主 thread 维护一条固定 `Current State` comment，最小字段包括：

- `orchestration_mode`
- `mode`
- `current_phase`
- `current_state`
- `root_goal`
- `root_issue`
- `goal_state`
- `goal_unit_roster`
- `main_thread`
- `threads`
- `active_write_leases`
- `recent_write_leases`
- `branch_refs`
- `worktree_refs`
- `verification_policy`
- `waiting_on`
- `next_check`
- `blockers`
- `residual_risks`
- `recovery_point`
- `next_action`

如果无法通过 thread tool 给完成的子 thread 标题加 `【完成】`，在 `Current State` 中记录 `title_marker_pending=true`。

## Linear Thread Status Comment

子 thread 只追加固定 `Thread Status` comment，常见 event 包括：

- `lease_requested`
- `lease_active_ack`
- `ready_for_integration`
- `blocked`
- `verification_complete`
- `review_complete`
- `review_fix_complete`
- `test_author_complete`
- `runbook_sync_complete`

主 thread 读取这些 comment 后统一更新 `Current State`、`.agents/state/orchestration-*.md` 和必要 writeback。

## Linear Done Boundary

- 子 thread `【完成】` 不等于 Execution Issue Done。
- Execution Issue Done 需要 lease 集成、post-integration verify、必要 review、writeback 和 residual risk 说明完成。
- Master Issue Done 仍以 `docs/harness/issue-workflow.md` 中的 Master Done Gate 为准。
- required live E2E 未执行时，不得把 Linear issue 移到 Done；应停在 `blocked` / `manual-gate` 并写明所需环境、权限或人工动作。

## 通用模板入口

以下模板不在本文件重复维护：

- Requirement Clarification
- Project
- Master Issue
- Execution Issue
- Codex Handoff
- 运行反馈 Comment Contract
- 结果回写 Contract
- Master 是否可置 Done

统一从 `docs/harness/issue-workflow.md` 读取。
