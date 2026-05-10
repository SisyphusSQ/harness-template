# Run Summary Template

本文件是本地辅助运行面模板，用于记录一次批次执行的结果面，服务审计、回放和最终收口。

固定规则：

- `Issue Tracker` 仍是主协作真相
- `.agents/runs/` 只记录本地批次结果摘要，不替代 Issue Tracker 回写
- 本地结果与协作状态冲突时，以 `Issue Tracker` 为准；本地文件用于补充执行细节

- `run_id`:
- `batch_id`:
- `mode`:
- `master_issue`:
- `execution_issue`:
- `issue_provider`: __ISSUE_PROVIDER__
- `result`:
- `master_status`:
- `stop_scope`:
- `verification_summary`:
- `review_summary`:
- `writeback_summary`:
- `residual_risks`:
- `followups`:
- `owner_agents`:
- `delegation_summary`:
- `merge_closeout`:
- `issue_writeback`:
- `sanitized_artifacts`:

## PR / MR Draft（按需）

- `title`:
- `body_sections`:
- `verification`:
- `residual_risks`:

## Local Closeout（按需）

- `merge_commit`:
- `local_branch_status`:
- `remote_status`:
- `cleanup_summary`:
