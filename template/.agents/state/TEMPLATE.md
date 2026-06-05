# State Snapshot Template

本文件是本地辅助运行面模板，用于记录当前工作点，服务中断恢复与续做。

固定规则：

- `Issue Tracker` 仍是主协作真相
- `.agents/state/` 只记录本地恢复细节，不替代 Issue Tracker 状态
- 协作状态冲突时以 `Issue Tracker` 为准；本地恢复细节冲突时以最新 `state` 文件为准

- `state_id`:
- `updated_at`:
- `mode`:
- `orchestration_mode`:
- `root_goal`:
- `root_issue`:
- `goal_state`:
- `goal_unit_roster`:
- `master_issue`:
- `execution_issue`:
- `issue_provider`: __ISSUE_PROVIDER__
- `batch_id`:
- `phase`:
- `status`:
- `stop_scope`:
- `current_issue_state`:
- `branch`:
- `plan_ref`:
- `main_thread`:
- `threads`:
- `active_write_leases`:
- `recent_write_leases`:
- `branch_refs`:
- `worktree_refs`:
- `verification_policy`:
- `waiting_on`:
- `next_check`:
- `recovery_point`:
- `next_action`:
- `verification_matrix`:
- `blockers`:

## Orchestration Snapshot（按需）

- `active_master_issue`:
- `active_execution_issue`:
- `queued_master_issues`:
- `queued_execution_issues`:
- `direct_child_threads`:
- `completed_units`:
- `deferred_units`:
- `blocked_units`:

## Current State Mirror（按需）

本区块可镜像 Issue Tracker 的 `Current State` comment，便于服务中断恢复；冲突时仍以 Issue Tracker 为准。

- `title_marker_pending`:
- `last_issue_tracker_sync`:
- `last_thread_readback`:
- `last_branch_readback`:
- `post_integration_verify_required`:
- `live_e2e_required`:
