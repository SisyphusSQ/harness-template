Mode: full

# Automation Loop Prompt

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 无人值守 / 自动化 harness loop 的规范页与可复制 Prompt 模板 |
| 适用范围 | 围绕 root issue 自动推进一轮受控 collect / freeze / implement / closeout |
| 关联文档 | `.agents/prompts/orchestrator-thread.md`、`.agents/prompts/issue-standard-workflow.md`、`.agents/prompts/loop-codex.md`、`AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agents/guides/code-review.md`、`.agents/PLANS.md` |

固定规则：

- 本文用于 automation，不替代仓库级控制面真相。
- 若本文与 `AGENTS.md`、`docs/harness/*`、`.agents/PLANS.md` 冲突，以后者为准。
- automation 的结果面优先回写 Issue Tracker；PR/MR 和 repo 文档是次级叙事面。
- 外部工具、目录、配置中心、文档平台、接口平台、监控平台统一称为 `External System`，必须按 readback verify 闭环。
- 多 thread automation 使用 `orchestrator-thread.md` 的 Goal Prompt、Handoff Prompt、`write_lease` 和 `Current State` contract。
- 自动化不默认归档子 thread；完成后只加 `【完成】` 标题标识，工具不可用时记录 `title_marker_pending=true`。

## 1. Root Issue 双入口

| `root_issue_type` | 作用 | 默认 loop |
| --- | --- | --- |
| `goal` | root goal 由主 thread 拆解、下发、回收和集成多个 child threads / Master / Execution units | `goal-orchestration` |
| `master` | 承载总体目标、Exit Criteria、inventory 与统一验收矩阵 | `master-loop` |
| `execution` | 承载单个最小可验证 slice | `solo-loop` |

固定规则：

1. `goal` 启动时，先冻结 `goal_unit_roster`，再选择当前 active Master / Execution / direct child thread。
2. `execution` 直启时，只围绕该 execution issue 推进。
3. `master` 启动时，必须先完成 `collect -> gate -> freeze`，并冻结初始 inventory。
4. `master + full-auto` 默认采用 `serial-drain`，一次只推进一张 execution issue。
5. execution issue 的 `Stop When` 只负责停当前 slice，不负责结束 Master 或 root goal。

## 2. 执行模式

| 模式 | 行为 | 允许副作用 |
| --- | --- | --- |
| `propose-only` | 只做分析、冻结与下一步建议 | 无文件修改、无外部写入 |
| `create-issues` | 冻结并创建 execution issue inventory | Issue Tracker 写入 |
| `implement-no-merge` | 推进到 verify / review / writeback / MR ready | 代码和文档修改，禁止 merge |
| `full-auto` | 按 loop 自动推进到可安全完成的位置 | 允许 merge，但必须满足仓库 merge gate |

## 3. Checkpoint 与停止规则

固定主流程：

```text
collect -> gate -> freeze -> slice -> implement -> verify -> review -> writeback -> mr_prep -> merge -> notify
```

停止条件：

| stop_scope | 触发条件 | next_action |
| --- | --- | --- |
| `needs-plan` | 范围、依赖或验收未冻结 | 写或更新 `.agents/plans/*` |
| `blocked` | 缺凭证、权限、环境、上游决策或外部系统不可用 | 回写 blocker 和人工动作 |
| `waiting-on-child` | 长任务依赖子 thread 输出 | 记录 waiting_on、next_check、recovery_point |
| `ready-for-implement` | plan-only 完成但未实现 | 等待实现授权或进入 implement |
| `ready-for-review` | verify 完成，需要独立 review | 执行 review gate |
| `ready-for-integration` | 子 thread 输出 ready，等待主 thread 集成 | 检查 lease、diff、review、verify |
| `ready-for-merge` | verify / review / writeback 通过 | 执行 provider 原生命令收口 |
| `done` | 主分支、issue 状态和结果面已回读确认 | 输出 final summary |

固定规则：

- `verify / review / mr_prep / merge / escalation` 都是独立 checkpoint。
- `dispatch / integrate / post-integration verify` 是多 thread automation 的独立 checkpoint。
- verify 失败时不进入 review；review 有 blocking finding 时不进入 mr_prep。
- 子 thread 验证只是输入证据；主 thread 集成后必须重新执行 post-integration verify。
- required live E2E 未执行时，不进入 `verified / ready-for-merge / done`。
- 自动 merge 条件不满足时，降级为 manual gate，不伪装已合并。
- 遇到未冻结的外部系统写入范围，降级为 plan-only。

## 4. 结果面

automation 至少同步以下字段：

| 字段 | 含义 |
| --- | --- |
| `result` | 当前 run 结果 |
| `stop_scope` | 当前停止点 |
| `verification_summary` | 验证命令、结果和失败摘要 |
| `review_summary` | findings-first review 结论 |
| `integration_summary` | 主 thread 集成子 thread / lease / branch 的结果 |
| `post_integration_verify_summary` | 集成后的最终验证结果 |
| `writeback_summary` | Issue Tracker / PR / repo 文档回写摘要 |
| `external_system_summary` | 外部系统读写、diff、readback 结果 |
| `residual_risks` | 剩余风险 |
| `followups` | 不属于当前冻结范围但需要排期的事项 |
| `recovery_point` | 下一轮恢复所需的分支、计划、issue 状态和命令 |
| `next_action` | 推荐下一步 |

若是 `master` 场景，还必须同步：

- `master_status`
- `inventory_status`
- `current_slice`
- `next_slice`
- `exit_criteria_status`

若是 `goal` 场景，还必须同步：

- `goal_state`
- `goal_unit_roster`
- `active_master_issue`
- `active_execution_issue`
- `completed_units`
- `deferred_units`
- `blocked_units`
- `waiting_on`
- `next_check`
- `goal_next_action`

## 5. External System Automation Contract

所有外部系统同步统一按下列占位抽象：

| 占位符 | 含义 |
| --- | --- |
| `<EXTERNAL_SYSTEM>` | 外部系统名称，如接口平台、文档平台、知识库、配置中心、监控平台 |
| `<PROVIDER>` | 工具或 API provider，如 CLI、MCP、REST API、SDK |
| `<CATALOG>` | 项目、空间、目录、分组或 collection |
| `<STABLE_KEY>` | 稳定键，如 `method + path`、配置 key、schema 名、标题 + 父目录 |
| `<ALLOWED_ACTIONS>` | `read-only`、`create`、`update`、`delete` 中本轮允许的动作 |

固定流程：

```text
read repo truth -> read external current truth -> diff by stable key -> apply allowed actions -> readback verify -> writeback summary
```

默认边界：

- 默认 `delete` 不允许。
- 默认不做整包导入。
- 默认只改 `<CATALOG>` 内的本轮 `<SYNC_SCOPE>`。
- 外部系统写入必须有 readback proof。
- provider 失败、权限不足或稳定键冲突时，停止在 `blocked`。

## 6. 标准 Automation Prompt 模板

```text
你是当前仓库的无人值守 loop agent。你的职责是围绕 root issue，
用仓库内 harness 真相推进一轮受控 automation loop，并在不能安全自动化时明确降级。

运行参数：
- Root issue type: <master|execution>
- Root goal: <ROOT_GOAL_OR_NONE>
- Root issue: <ROOT_ISSUE>
- Run ID: <RUN_ID>
- Mode: <propose-only|create-issues|implement-no-merge|full-auto>
- External systems: <none|list>
- Constraints: <CONSTRAINTS>

你必须优先读取：
- 根规则：AGENTS.md
- 工程控制面：docs/harness/control-plane.md、docs/harness/linear.md
- 项目级机械约束：docs/harness/project-constraints.md
- 计划协议：.agents/PLANS.md、.agents/plans/*
- Prompt / Guide：.agents/prompts/*、.agents/guides/*
- 多 thread 编排：.agents/prompts/orchestrator-thread.md
- 当前 issue / PR / MR / repo 状态

固定主流程：
collect -> gate -> freeze -> slice -> dispatch -> implement -> verify -> review -> integrate -> verify -> writeback -> mr_prep -> merge -> notify

执行硬约束：
1. root_issue_type=goal 时，默认进入 goal-orchestration。
2. root_issue_type=execution 时，默认进入 solo-loop。
3. root_issue_type=master 时，必须先冻结完整初始 inventory。
4. full-auto 下的 master-loop 默认 serial-drain，一次只推进一张 execution issue。
5. 可写 child thread 必须有 write_lease；并发可写必须 disjoint write_scope。
6. verify / review / integrate / post-integration verify / mr_prep / merge / escalation 都是独立 checkpoint。
7. 若当前 execution issue 仍过大，回到 freeze 收窄或拆卡。
8. 所有外部系统写入都必须先读当前详情，写后回读验证。
9. 结果面至少同步 result、stop_scope、verification_summary、review_summary、integration_summary、post_integration_verify_summary、writeback_summary、external_system_summary、residual_risks、followups、recovery_point、next_action。
10. 无法安全自动化时，明确降级为 manual gate 或 plan-only。
```

## 7. 使用建议

- 首次接入 automation 先用 `propose-only`。
- 只想冻结 inventory 时用 `create-issues`。
- 不想自动收尾时用 `implement-no-merge`。
- 只有确认 merge gate、权限、验证和 writeback 都稳定后，才使用 `full-auto`。
