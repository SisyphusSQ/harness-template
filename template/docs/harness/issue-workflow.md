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
- `writeback_summary`
- `residual_risks`
- `recovery_point`
- `next_action`
- `current_issue_state`

固定规则：

- `运行反馈` 默认写回 Issue Tracker comment / issue body / writeback log
- 不启用本地 `state / runs` 时，也必须能在 Issue Tracker 上恢复当前状态
- 若是 `master` 场景，还要显式写出 `current_slice` 与 `master_status`

## 结果回写 Contract

### 当前 slice 完成时

- 回写本轮 `result`
- 回写 `verification_summary`
- 回写 `review_summary`
- 回写 `writeback_summary`
- 回写 `residual_risks`
- 回写下一步 `next_action`

### Master 未完成时

- 明确 `master_status`
- 明确 `stop_scope`
- 明确下一张 execution issue
- 明确当前 `recovery_point`

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
- `Master Status`:
- `stop_scope`:
- `Next execution issue`:

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
