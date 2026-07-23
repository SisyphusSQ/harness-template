# Control Plane

本文是 Harness 的唯一控制面规则。可复制的人工 Prompt 放在 `.agents/prompts/`，项目真实约束放在 `AGENTS.md`，计划格式放在 `.agents/PLANS.md`。

## 1. 默认主流程

日常单写入者使用：

`collect + gate -> freeze + slice -> implement -> verify -> review -> closeout`

- `collect + gate`：读取 Issue、仓库、适用规则和当前工作区，确认授权与阻塞。
- `freeze + slice`：冻结 Included、Excluded、Acceptance Matrix、Write Scope 和当前执行单元。
- `implement`：仅在冻结范围内实施；遇到必须扩大的范围先停止并回写。
- `verify`：执行项目验证与必要的 Harness gate，记录真实证据等级。
- `review`：按 findings-first 输出 review 结论，阻塞项修复后重新验证。
- `closeout`：完成结果回写、可选交付动作和最终通知。

以下均为条件分支：

- `dispatch` 只在需要多 thread / worktree / subagent fan-out 时进入。
- `integrate -> post-integration verify` 只在存在可写 lease、branch / worktree 集成或其他 integration event 时进入。
- `pr_prep -> merge` 只在当前交付目标包含 PR / MR 且用户或仓库规则已授权时进入。
- `closeout` 内按实际需要完成 `writeback -> optional delivery -> notify`；未请求的交付动作记为 `not_requested`，不伪装执行。

## 2. 真相分层与 Provider

- `Issue Tracker 是主协作真相`：Goal、Scope、状态、依赖、阻塞、验收和结果回写以 Issue Tracker 为准。
- `repo 是主执行真相`：代码、配置、计划、测试和验证证据以当前仓库为准。
- `PR / MR 是次级代码叙事面`：描述代码差异和评审状态，不替代 Issue Tracker。
- `.agents/state/` 和 `.agents/runs/` 是本地辅助面，不替代共享真相。

当前 merge provider：

- `__PROVIDER__`

允许值：`neutral`、`github`、`gitlab`。

当前 issue provider：

- `__ISSUE_PROVIDER__`

允许值：`linear`、`github`、`gitlab`、`repo`、`other`。

### Issue Store Profiles

所有 Issue provider 共享同一套字段和 Done Gate：

- `linear`：使用下方 Linear 字段映射。
- `github` / `gitlab`：正文保存稳定字段，评论保存运行状态与结果回写。
- `repo`：使用 `docs/issues/README.md` 与 `docs/issues/TEMPLATE.md`。
- `other`：显式记录稳定 ID、状态映射和回写入口。

### Linear 字段映射

| Harness 语义 | Linear 载体 |
| --- | --- |
| Goal / Scope / Acceptance Matrix | Issue description |
| 当前执行阶段 | Issue state + `Current State` comment |
| 子任务与 write lease | sub-issue + `Thread Status` comment |
| 依赖与阻塞 | relation + comment |
| 验证、review、结果回写 | comment |
| Master / Goal 完成 | 所有 Done Gate 满足后更新 state |

不要依赖未稳定开放的自定义字段；字段不可用时用结构化 comment 表达。

## 3. Issue 状态机

### 必填任务字段

每个可执行 Issue 至少包含：

- Goal
- Included / Excluded
- Acceptance Matrix
- Write Scope Limit
- Verification Commands
- Dependencies / Blockers
- Stop When
- Recovery Point / Next Action

复杂任务还应关联 `.agents/plans/<plan>.md`。从设计文档、runbook 或需求文档创建 Issue 时，必须先通读来源并保留会影响实现和验收的边界。

### Current State

每个活跃 Issue 维护一条可更新的 `Current State`：

```yaml
current_issue_state: planned|in_progress|blocked|ready_for_review|verified|done
active_phase: collect|freeze|implement|verify|review|integrate|closeout
active_plan: <path|none>
active_owner: <thread|human|automation>
waiting_on: <dependency|none>
recovery_point: <safe resume point>
next_action: <one concrete action>
```

状态必须来自实际证据，不根据 thread 的 UI `idle`、`active` 或 `notLoaded` 推断完成。

### Thread Status

发生多任务编排时，每个执行任务维护：

```yaml
thread_role: implementer|test|review|integration|explorer
status: dispatched|working|blocked|ready|integrated|done
read_scope: <paths or facts>
write_scope: <paths|none>
write_lease: <lease id|none>
verification: <commands and result>
blocking_findings: <none|summary>
recovery_point: <safe resume point>
next_action: <one concrete action>
```

### Write Lease

- 只读任务不需要 lease。
- 任何写代码、文档或配置的并行任务必须有互不重叠的 `write_lease`。
- lease 必须写明目标仓、branch / worktree、允许路径和禁止路径。
- 发现重叠、工作区漂移或 scope 外改动时停止集成，不自行覆盖。
- 单仓单写入者默认不制造 lease 或 integration 阶段。

### Done Gate

只有同时满足以下条件，Execution Issue 才能标记 Done：

- Acceptance Matrix 已逐项满足或明确记录未满足项。
- 必需验证已真实执行并通过。
- `blocking_findings` 为空。
- required live E2E 已执行；若缺失，只能停在 manual gate。
- 结果、残余风险和下一步已回写 Issue Tracker。
- 若发生 integration event，post-integration verify 已在最终 repo truth 上执行。

Master / Goal 只有在所有必需执行单元满足 Done Gate、依赖与阻塞清空后才能完成。

## 4. Thread Orchestration

编排模式：

- `single-issue`：单卡单写入者，默认模式。
- `goal-orchestration`：一个 root goal 下有多个相对独立的执行单元。
- `master-inventory`：先盘点和切片，再逐张执行。
- `review-fix`：review 与修复职责需要隔离。
- `verify-only`：只执行验证，不修改实现。

固定规则：

- 主任务负责冻结目标、分配 scope、维护 Issue 状态、集成和最终验证。
- 执行任务只处理 handoff 中的范围，不自行扩展 Goal。
- Handoff 模板与工具用法见 `.agents/prompts/orchestrator-thread.md`。
- 长任务使用有界等待；不要高频轮询，也不要把无状态变化报告成进展。
- 子任务完成后先回传证据，主任务核对 scope 和差异后再集成。
- 标题中的 `【完成】` 只是可选可见标识，不代替 Done Gate。

## 5. Review Policy Contract

`review_policy`: `standard` / `strict`。

- `standard` 允许主 agent 执行对抗式自审，仍必须输出 findings-first 结果。
- `strict` 必须由 subagent 独立评审；不可用时状态为 `blocked: subagent_review_unavailable`，不得伪装独立评审。
- 调用方未提供 `review_policy` 时按 `strict` 处理，保证旧任务兼容。

以下情况必须使用 `strict`：

- 多仓代码改动、多个可写 lease 或 branch / worktree 集成
- 鉴权、安全、权限、公开 API 或 contract 兼容性
- schema、migration 或数据修改
- 并发、幂等、重试或业务状态机
- release、部署、生产环境或不可逆外部副作用
- required live E2E、full-auto 或自动 merge
- 风险无法可靠判断

Review 输出至少包含：

```yaml
review_policy: standard|strict
review_owner: main-agent-self-review|subagent
blocking_findings: none|summary
findings: []
residual_risks: []
```

`blocking_findings` 是 review gate 的内容阻塞字段。Review 默认只出结论；修复必须由用户授权或任务范围明确包含。

## 6. Verification Evidence Reuse Contract

验证摘要至少记录：

- `evidence_id`
- `execution_session_id`
- worktree / commit snapshot
- 有序命令与结果
- 验证类型：`deterministic-local` / `environment-dependent` / `live`

只有同时满足以下条件，证据才可在 closeout 中保留复用：

- 同一执行 session
- 同一仓库、同一 author、同一 snapshot
- 命令和顺序不变
- 全部为 deterministic-local
- 未发生 integration event

复用时记录 `verification_summary.evidence_status: retained`，不要伪装成第二次执行。

以下情况必须重跑：

- 发生 merge、cherry-pick、rebase、patch apply、跨 branch/worktree 汇入等 integration event
- 多仓、多 lease 或 strict 任务
- environment-dependent、live 或 required E2E
- 文件、依赖、配置、环境或命令顺序发生变化
- 任何无法确认的情况默认重跑

发生 integration event 后，必须在最终 repo truth 上执行验证，并记录 `post_integration_verify_summary.status: executed`。没有 integration event 时不制造 post-integration verify 阶段。

Harness 自检只覆盖控制面关键不变量，不替代项目 build、test、lint、security scan 或 live E2E。没有 PowerShell runtime 时只能报告 Bash 实跑和 PowerShell 静态一致性，不能宣称 PowerShell 已通过。

## 7. Plan、Runbook 与 Closeout

- 复杂任务计划写入 `.agents/plans/`，格式以 `.agents/PLANS.md` 为准。
- `.agents/state/` 保存恢复点，`.agents/runs/` 保存本地运行摘要；真实运行文件默认不提交。
- 测试 runbook 放在 `docs/test/`，执行前说明副作用，执行后区分真实结果、未执行项和脱敏摘要。
- `docs/issues/` 只在 `issue-provider=repo` 时承担共享 Issue 载体。
- provider 仓维护 contract / schema truth，consumer 仓不反向定义 provider 语义。

Closeout 至少完成：

1. 核对最终 scope 和工作区。
2. 汇总验证与 review 证据，区分实跑、静态检查和未观察项。
3. 回写 Issue Tracker 的状态、结果、残余风险、`recovery_point` 和 `next_action`。
4. 仅在授权范围内执行 commit、push、PR / MR、merge、release 或外部写入。
5. 给出最终通知；没有执行的动作明确写 `not_requested`、`not_run` 或 blocker。

如果规则需要项目化，写入 `AGENTS.md`；如果规则可以机械执行，落实到项目 Makefile、lint 或 gate。不要再创建第二份项目约束登记文档。
