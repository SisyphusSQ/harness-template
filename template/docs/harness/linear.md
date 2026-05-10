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
- 如果 Linear API 或权限不可用，先把临时恢复点写入 `.agents/state/`，恢复后再回写 Linear。

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
