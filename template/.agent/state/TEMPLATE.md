# State Snapshot Template

本文件是本地辅助运行面模板，用于记录当前工作点，服务中断恢复与续做。

固定规则：

- `Linear` 仍是主协作真相
- `.agent/state/` 只记录本地恢复细节，不替代 Linear 状态
- 协作状态冲突时以 `Linear` 为准；本地恢复细节冲突时以最新 `state` 文件为准

- `state_id`:
- `updated_at`:
- `mode`:
- `master_issue`:
- `execution_issue`:
- `batch_id`:
- `phase`:
- `status`:
- `stop_scope`:
- `current_linear_state`:
- `branch`:
- `plan_ref`:
- `recovery_point`:
- `next_action`:
- `verification_matrix`:
- `blockers`:
