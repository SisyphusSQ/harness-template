# Repo Issue: <title>

- `issue_id`:
- `status`: Todo
- `kind`: Requirement Clarification / Project / Master Issue / Execution Issue
- `issue_provider`: repo
- `created_at`:
- `updated_at`:

## Goal

- `goal`:
- `success_criteria`:

## Scope

- `included`:
- `excluded`:

## Acceptance Matrix

- `acceptance_matrix`:

| 类别 | 口径 |
| --- | --- |
| 构建 |  |
| 测试 |  |
| review |  |
| writeback |  |

## Execution Contract

- `stop_when`:
- `write_scope_limit`:
- `verification_commands`:
- `rollback_unit`:
- `dependencies_blockers`:
- `follow_up_candidates`:

## Recovery

- `current_issue_state`:
- `recovery_point`:
- `next_action`:

## Orchestration

- `orchestration_mode`:
- `mode`:
- `root_goal`:
- `root_issue`:
- `goal_state`:
- `goal_unit_roster`:
- `main_thread`:
- `threads`:
- `active_write_leases`:
- `recent_write_leases`:
- `branch_refs`:
- `worktree_refs`:
- `verification_policy`:
- `waiting_on`:
- `next_check`:

## Current State

由主 thread 维护当前快照；冲突时以本 issue 的最新 `Current State` 和 repo 当前执行事实为准。

- `current_phase`:
- `current_state`:
- `title_marker_pending`:
- `blockers`:
- `residual_risks`:
- `post_integration_verify_summary`:
- `goal_level_verification_summary`:

## Thread Status Log

追加子 thread milestone/status 记录。子 thread 完成后标题应加 `【完成】`，但该标识不替代 issue 状态。

### <YYYY-MM-DD HH:MM> - Thread Status

- `event`:
- `thread_id`:
- `thread_title`:
- `role`:
- `lease_id`:
- `lease_state_requested`:
- `phase`:
- `branch`:
- `worktree`:
- `changed_files`:
- `verification_summary`:
- `review_summary`:
- `blockers`:
- `residual_risks`:
- `requested_action`:

## Writeback Log

- `writeback_log`:

追加最新记录到最上方或按时间顺序维护，但每条记录必须可用于恢复当前 issue 状态。

### <YYYY-MM-DD HH:MM> - <phase>

- `result`:
- `verification_summary`:
- `review_summary`:
- `integration_summary`:
- `post_integration_verify_summary`:
- `writeback_summary`:
- `residual_risks`:
- `next_action`:
