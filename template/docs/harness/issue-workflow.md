# Issue Workflow

本文件是工具中立的 issue 协作协议。Linear、GitHub Issues、GitLab Issues、仓库内 `docs/issues/` 或其它工具都只是 Issue Tracker profile，不改变 base harness 的核心模型。

当前默认 issue provider：

- `__ISSUE_PROVIDER__`

当前默认 issue 前缀示例：

- `__ISSUE_PREFIX__`

## Issue 标准执行工作流

推荐顺序：

1. 需求不清楚时先写 Requirement Clarification
2. 需要项目级容器时写 Project
3. 需要总体方案时写 Master Issue
4. 需要单张可执行卡时写 Execution Issue
5. 进入仓库实施前补 Codex Handoff
6. 关键阶段用 comment / writeback log 回写进展
7. 收口前按 Master 是否可置 Done 清单检查

## 真相 Contract

固定规则：

- `Issue Tracker 是主协作真相`
- `repo 是主执行真相`
- `PR / MR 是次级代码叙事面`

默认解释：

- 当前任务范围、状态、blockers、follow-up、运行反馈、`recovery_point`、`next_action` 默认以 Issue Tracker 为准。
- 当前执行命令、代码路径、设计文档入口、Prompt / Guide、write scope 默认以 repo 为准。
- PR / MR 只在仓库启用时承接代码叙事，不作为唯一任务真相面。
- 当仓库使用 `issue-provider=repo` 时，`docs/issues/` 就是 Issue Tracker 的提交版存储。

## Issue Store Profiles

| Provider | Issue Store | Writeback Target |
| --- | --- | --- |
| `linear` | Linear issue body / project / state / comment | Linear comment 或 issue body |
| `github` | GitHub Issue body / label / milestone / comment | GitHub Issue comment |
| `gitlab` | GitLab Issue description / label / milestone / note | GitLab Issue note |
| `repo` | `docs/issues/*.md` | `writeback_log` |
| `other` | 项目约定的外部 issue 系统 | 对应系统的 comment / history |

固定规则：

- 每个 profile 必须能承载同一组任务真相字段。
- 没有外部工具时，用 `docs/issues/TEMPLATE.md` 创建仓库内 issue。
- 外部 issue 工具不可用时，允许临时把恢复点写入 `.agents/state/`，但最终协作状态仍要回写到 Issue Tracker。

## Master / Execution 模型

| 层级 | 作用 |
| --- | --- |
| `Master Issue` | 承载总体目标、Exit Criteria、统一验收矩阵、当前执行卡列表 |
| `Execution Issue` | 承载单个最小可验证 slice |

固定规则：

- `Master Issue` 标题必须显式带 `【Master】`
- `Execution Issue` 必须有 `Included`、`Excluded`、`Stop When`
- execution issue 达到当前轮验收后立即停止，不顺手补范围外内容

## 必填任务真相字段

Master / Execution issue 至少要清楚这些字段：

- `Goal`
- `Included`
- `Excluded`
- `Acceptance Matrix`
- `Stop When`
- `Write Scope Limit`
- `Verification Commands`
- `Rollback Unit`
- `Dependencies / Blockers`
- `Follow-up Candidates`
- `recovery_point`
- `next_action`
- `current_issue_state`

## Orchestration Contract

本节定义 provider-neutral 的多 thread 编排字段。Linear、GitHub、GitLab、repo issue 或其它工具都应能承载同一组状态。

### Orchestration 字段

当一张 issue 或一个 root goal 使用多 thread 编排时，至少记录：

- `root_goal`
- `orchestration_mode`: `goal-orchestration` / `single-issue` / `master-inventory` / `review-fix` / `verify-only` / `maintenance`
- `mode`: `propose-only` / `plan-only` / `create-issues` / `implement-no-merge` / `full-auto`
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
- `recovery_point`
- `next_action`

固定解释：

- `goal-orchestration` 表示一个原本可由单 thread 完成的 root goal，由主 thread 拆解、下发、回收并集成多个 child threads / Master / Execution units。
- `goal_state` 是 root goal 层状态；每个 Master / Execution Issue 仍维护自己的 `current_issue_state`。
- 多个 Master Issue 串行推进时，默认只有一个 `active_master_issue`；当前 Master 未 Done / blocked / deferred / skipped 前，不进入下一个 Master。

### Current State Comment Contract

`Current State` 是当前 issue / root goal 的固定状态快照。默认只由主 thread 更新；子 thread 不直接改这条 comment。

```markdown
## Current State

- `orchestration_mode`:
- `mode`:
- `current_phase`:
- `current_state`:
- `root_goal`:
- `root_issue`:
- `parent_issue`:
- `execution_issue`:
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
- `blockers`:
- `residual_risks`:
- `recovery_point`:
- `next_action`:
- `last_updated_by`: main_thread
```

如果 thread 工具不可用，无法给完成的子 thread 标题加 `【完成】` 时，在 `Current State` 中记录 `title_marker_pending=true`。

### Thread Status Comment Contract

子 thread 使用固定 milestone/status comment 汇报状态。主 thread 读取这些 comment 后，统一更新 `Current State` 和本地 orchestration snapshot。

```markdown
## Thread Status

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
```

常见 `event`：

- `lease_requested`
- `lease_active_ack`
- `ready_for_integration`
- `blocked`
- `verification_complete`
- `review_complete`
- `review_fix_complete`
- `test_author_complete`
- `runbook_sync_complete`

### Write Lease Contract

`write_lease` 是写入许可、写入边界和集成约定。任何会修改代码、文档或配置的 thread，包括主 thread 自己，都必须先登记 `write_lease`。

最小字段：

- `lease_id`
- `state`: `requested` / `active` / `paused` / `ready_for_integration` / `integrated` / `released` / `blocked`
- `role`
- `owner_thread`
- `issue`
- `branch`
- `worktree`
- `write_scope`
- `excluded_scope`
- `scope_note`
- `allowed_phase`
- `handoff_from`
- `integration_owner`
- `verification_commands`

固定规则：

- `write_scope` 以路径模式为主，语义说明只作补充。
- 路径重叠默认冲突；并发可写必须由主 thread 判断为 disjoint。
- 冲突默认串行 handoff，不能并发写同一范围。
- 子 thread 不自行 merge，不自行扩大范围，不绕过主 thread closeout。

### Thread Title Contract

默认 thread 标题：

```text
<issue-id> <role> [short-scope]
```

完成后标题：

```text
【完成】<issue-id> <role> [short-scope]
```

`【完成】` 只表示该 thread 自身工作完成，不等于 issue Done。issue 是否完成仍看 `Current State`、`current_issue_state`、验证和 writeback。

### Post-Integration Verify Contract

子 thread 的验证结果只是输入证据。主 thread 集成任何可写 lease 后，必须执行 post-integration verify。

post-integration verify 必须覆盖 required sources：

- 主 thread Goal Prompt
- Issue Acceptance Matrix / Verification Commands
- active plan 的 Validation and Acceptance
- 相关 test runbook

如果任何 required item 是 live E2E，必须执行 live E2E，或停止为 `blocked` / `manual-gate`。未执行 required live E2E 时，不得进入 `verified`、`ready_for_merge`、`done`。

## Requirement Clarification 模板

### 背景

- 当前问题：
- 当前上下文：
- 相关系统 / 仓库：

### 目标

- 业务目标：
- 成功标准：

### 非目标

- 本次明确不做：

### 约束

- 技术约束：
- 时间约束：
- 协作约束：

### 风险

- 已知风险：
- 依赖项：

### 待确认

- [待确认]

## Project 模板

### 项目目标

- 该项目要解决什么问题：
- 当前阶段：

### 范围

- In Scope：
- Out of Scope：

### 成功标准

- 里程碑 1：
- 里程碑 2：

### 风险与依赖

- 关键风险：
- 外部依赖：

### 协作方式

- 文档真相：
- 仓库真相：
- Issue Tracker 归口：

## Master Issue 模板

### 标题

`【Master】<主题名>`

### Goal

- 目标：
- 成功标准：

### In Scope

-

### Out of Scope

-

### Exit Criteria

-

### Acceptance Matrix

| 类别 | 口径 |
| --- | --- |
| 构建 |  |
| 测试 |  |
| review |  |
| writeback |  |

### Batch Strategy

- `single-batch` / `serial-drain`：
- 当前建议：

### Execution Issues

- 当前纳入：
- 当前排除：

### Dependencies

-

### Risks

-

### Writeback

- 仓库：
- 文档：
- 结果面：

### Done Gate

- 是否满足 Exit Criteria：
- 若不满足，下一张 execution issue：

## Execution Issue 模板

### 标题

`<slice-topic>`

### Goal

- 一句话说明本卡交付什么：

### Included

- 仅写当前最小可验证 slice：

### Excluded

- 显式排除顺手扩展内容：

### Acceptance Matrix

| 类别 | 口径 |
| --- | --- |
| 构建 |  |
| 测试 |  |
| review |  |
| writeback |  |

### Stop When

- 达到以下状态后必须立即停止：

### Write Scope Limit

- 主写入范围：
- 辅助文件范围：

### Reference Targets

-

### Writeback Targets

-

### Verification Commands

-

### Rollback Unit

-

### Dependencies / Blockers

-

### Follow-up Candidates

-

### Expected PR Narrative

- 未来 PR / MR 应如何讲述本卡边界：

## Codex Handoff 模板

### Repo Context

- 仓库：
- 当前分支：
- 相关 issue：

### Goal

- 本轮要交付什么：

### Frozen Scope

- 纳入：
- 不纳入：

### Key Paths

- 关键文件：
- 关键目录：
- 关键文档：

### Commands

- 最小验证命令：

### Constraints

- merge provider：
- issue provider：
- 配置约束：
- 边界约束：

### Validation

- 已有验证：
- 仍需验证：

### Stop Conditions

- 遇到以下情况必须停下：

### Expected Output

- 结果摘要：
- 计划回写：
- 文档回写：

## 运行反馈 Comment Contract

默认回写面：

- 当前 issue comment / note / writeback log
- 必要时同步到 Master issue

最小字段：

- `current_phase`
- `result`
- `verification_summary`
- `review_summary`
- `integration_summary`
- `post_integration_verify_summary`
- `writeback_summary`
- `residual_risks`
- `active_write_leases`
- `recent_write_leases`
- `recovery_point`
- `next_action`
- `current_issue_state`

固定规则：

- `运行反馈` 默认写回 Issue Tracker comment / issue body / writeback log
- 不启用本地 `state / runs` 时，也必须能在 Issue Tracker 上恢复当前状态
- 若是 `master` 场景，还要显式写出 `current_slice` 与 `master_status`
- 若是 `goal-orchestration` 场景，还要显式写出 `goal_state`、`goal_unit_roster`、`waiting_on` 与 `next_check`

## 结果回写 Contract

### 当前 slice 完成时

- 回写本轮 `result`
- 回写 `verification_summary`
- 回写 `review_summary`
- 回写 `integration_summary`
- 回写 `post_integration_verify_summary`
- 回写 `writeback_summary`
- 回写 `residual_risks`
- 回写下一步 `next_action`

### Master 未完成时

- 明确 `master_status`
- 明确 `stop_scope`
- 明确下一张 execution issue
- 明确当前 `recovery_point`

### Goal 未完成时

- 明确 `goal_state`
- 明确 `active_master_issue` / `active_execution_issue`
- 明确 `goal_unit_roster`
- 明确 `completed_units` / `deferred_units` / `blocked_units`
- 明确 `waiting_on`、`next_check`、`recovery_point` 与 `goal_next_action`

### Master Done 时

- 明确最终结果
- 明确已完成 execution issues
- 明确残余风险
- 明确 follow-ups
- 明确最终建议状态

## 评论模板

### Gate / Slice Start 评论

- `Included now`:
- `Excluded now`:
- `Verification matrix`:
- `Rollback unit`:
- `Write scope`:

### Execution Issue 收口评论

- `Result`:
- `PR/MR`:
- `Merge commit`:
- `Verification Summary`:
- `Integration Summary`:
- `Post-integration Verify Summary`:
- `Master Status`:
- `stop_scope`:
- `Next execution issue`:

### Goal orchestration 评论

- `Goal State`:
- `Active master issue`:
- `Active execution issue`:
- `Goal unit roster`:
- `Completed units`:
- `Deferred units`:
- `Blocked units`:
- `Waiting on`:
- `Next check`:
- `Goal next action`:

### Master 未完成评论

- `Current master status`:
- `Why not done`:
- `Remaining issues`:
- `Next action`:
- `Suggested state`:

### Master 完成评论

- `Result`:
- `Master Status`:
- `stop_scope`:
- `Completed execution issues`:
- `Final head commit`:
- `Residual risks`:
- `Followups`:

## Master 是否可置 Done 清单

只有同时满足下面条件，才建议把 Master 置为 `Done`：

1. Master 自身的 `Exit Criteria` 已满足
2. 本轮纳入的 execution issues 已全部完成并回写结果
3. 验证结果已形成稳定摘要
4. 文档同步和必要 writeback 已完成
5. 没有仍属于 Master 范围内但被遗漏的未完成 execution issue

### 不应置 Done 的场景

- execution issue 只完成了一张，但 Master 仍未满足 Exit Criteria
- 当前只是停在 `stop-current-slice`
- 仍有关键 blocker 或待补 execution issue
- 当前卡本身是长期归口容器，不适合作为一次性 Done 对象
