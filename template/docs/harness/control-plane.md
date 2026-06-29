# Control Plane

## 主流程

固定主流程：

`collect -> gate -> freeze -> slice -> dispatch -> implement -> verify -> review -> integrate -> verify -> writeback -> pr_prep -> merge -> notify`

## 阶段职责

| 阶段 | 目标 | 主要产物 |
| --- | --- | --- |
| `collect` | 汇总目标、约束、现有计划和上下文 | batch 候选 |
| `gate` | 判断是否允许进入当前批次 | 准入 / 降级结论 |
| `freeze` | 冻结当前轮范围和验收口径 | Batch Plan |
| `slice` | 收敛最小可验证 slice | 当前轮实施边界 |
| `dispatch` | 判断是否派发 subagent、child thread 或 worktree thread | Handoff Prompt / write_lease |
| `implement` | 实施当前 slice | 代码 / 文档 / 计划更新 |
| `verify` | 执行者或测试 thread 的局部验证 | Pre-review Verify Summary |
| `review` | findings-first review | Review Summary |
| `integrate` | 主 thread 收回子 thread 结果并检查 lease、diff、冲突和边界 | Integration Summary |
| `verify` | 主 thread 在集成后的 repo truth 上执行最终验证矩阵 | Post-integration Verify Summary |
| `writeback` | 回写 Issue Tracker、必要 repo 文档与代码叙事面 | Writeback Summary |
| `pr_prep` | 准备 PR / MR 叙事 | PR Prep Summary |
| `merge` | 自动或手动 merge 收口 | merge 结论 |
| `notify` | 输出当前轮结果 | Notify Summary |

## 固定原则

- execution issue 的 `Stop When` 只负责停当前 slice
- 若当前对象是 Master issue，只有 Master Exit Criteria 满足时，整个 Master 才算完成
- provider 未锁定或自动化不可用时，`merge` 允许降级为 `manual`
- 新发现的范围外内容统一进入 follow-up，不顺手纳入当前卡
- 子 thread 完成只代表其工作单元完成，不代表 Execution Issue、Master Issue 或 root goal 已完成
- 子 thread 不默认归档；完成后标题加 `【完成】` 标识，最终完成态仍以 Issue Tracker 和 `Current State` 为准

## 真相分层

固定规则：

- `Issue Tracker 是主协作真相`
- `repo 是主执行真相`
- `PR / MR 是次级代码叙事面`

### 共享真相源

| 面 | 默认负责内容 |
| --- | --- |
| `Issue Tracker` | 任务范围、当前状态、blockers、follow-up、当前 slice、运行反馈、结果回写、`recovery_point`、`next_action` |
| `repo` | 执行命令、代码路径、设计文档入口、Prompt / Guide、repo-local 边界与约束、本地辅助运行面 |
| `PR / MR` | diff narrative、review thread、merge state |

### Issue Store Profiles

| Provider | 默认 Issue Store |
| --- | --- |
| `linear` | Linear issue body / project / state / comment |
| `github` | GitHub Issue body / label / milestone / comment |
| `gitlab` | GitLab Issue description / label / milestone / note |
| `repo` | `docs/issues/*.md` |
| `other` | 项目约定的外部 issue 系统 |

固定解释：

- `共享真相源` 默认按上述分层工作，不要求单一载体承载全部真相。
- `执行护栏` 也是双层：Issue Tracker 负责流程，repo 负责执行。
- 当两层发生冲突时，协作状态以 Issue Tracker 为准，执行约束以 repo 为准。
- `.agents/state` / `.agents/runs` 属于本地辅助运行面；它们补充恢复和审计细节，但不替代 Issue Tracker。
- Linear 只是一个 Issue Tracker profile，兼容说明在 `docs/harness/linear.md`。

## Thread Orchestration

固定解释：

- 多 thread 编排不是新的真相源；它只是把原本单 thread 连续完成的 goal，改成由主 thread 拆解、下发、回收和集成的 fan-out / fan-in 执行方式。
- Issue Tracker 仍承载协作状态，repo 仍承载执行事实，主 thread 负责调度、集成、最终验证和回写。
- Codex thread 工具可用时，主 thread 可以用 `create_thread`、`read_thread`、`send_message_to_thread`、`set_thread_title` 驱动子 thread；工具不可用时降级为人工 handoff。
- `set_thread_archived` 不作为默认动作；归档必须由用户显式要求。

### Codex-Specific Capability Boundary

- thread 的创建、读取、继续、消息发送、handoff 和 `【完成】` 标题标记属于 Codex 专用能力。
- 控制面本身仍保持 provider-neutral：Issue Tracker、repo、`Current State`、`Thread Status`、`write_lease` 和 verify gate 不依赖 Codex thread tools。
- 非 Codex agent 或人工流程只能按同一状态机执行手动 handoff；无法完成的 thread 工具动作必须显式记录为 fallback 或 pending action。

### Orchestration Mode

| `orchestration_mode` | 含义 |
| --- | --- |
| `goal-orchestration` | 围绕一个 root goal，由主 thread 拆解、下发、回收和集成多个 child threads / Master / Execution units |
| `single-issue` | 围绕一张 Execution Issue 编排主 thread、子 thread 和 `write_lease` |
| `master-inventory` | 围绕 Master Issue 冻结并推进多张 Execution Issues |
| `review-fix` | 围绕 review findings 派发修正 lease |
| `verify-only` | 只做验证 / 审查；默认不创建可写 lease |
| `maintenance` | 维护循环、漂移扫描、rule-promotion 等 |

`mode` 仍表达执行强度或副作用级别，例如 `propose-only`、`plan-only`、`create-issues`、`implement-no-merge`、`full-auto`。`mode` 不承载编排形态。

### Goal-Level Orchestration

固定规则：

- `goal-orchestration` 的 root truth 来自 Issue Tracker、repo、active plan 和主 thread Goal Prompt。
- 主 thread 维护全局 `goal_state` 与 `goal_unit_roster`；每个 Master / Execution Issue 仍维护自己的 `Current State`。
- 多个 Master Issue 串行推进时，默认只有一个 `active_master_issue`。
- 当前 Master 未达到 Exit Criteria，不进入下一个 Master；除非该 Master 被显式标记为 `blocked`、`deferred`、`skipped`，或用户要求切换。
- 若没有 Master Issue，也可以直接围绕多个 Execution Issue、child thread 或 subagent 做 goal-level fan-out / fan-in。
- root goal 只有在所有 required units 已集成、post-integration verify 已通过、writeback 和 closeout 完成后才算完成。

### Thread Roles

| 角色 | 定义 | 默认权限 |
| --- | --- | --- |
| `main_thread` | 主调度 thread，维护 root goal、状态机、dispatch、integrate、writeback 和 closeout | 可创建/暂停/释放 lease，可集成，可更新 `Current State` |
| `child_thread` | 独立 Codex thread，可长期可见和继续 | 默认只按 handoff 执行 |
| `worktree_thread` | 有独立 worktree / branch 的可写 child thread | 必须持有 `write_lease` |
| `subagent` | 当前主 thread 内部短生命周期委派者 | 适合短期探索、验证、局部 review |
| `test_thread` | 测试 / 验证 thread，可只读，也可持 lease 补测试、fixture 或 runbook | 是否可写取决于 `write_lease` |
| `review_thread` | findings-first review thread，可只读，也可持 lease 修 review finding | 修代码必须持有 `write_lease` |
| `integration_owner` | 集成 owner，默认是主 thread | 负责最终 diff、冲突、验证和状态回写 |

主 thread 的特殊权力不是无边界写入；主 thread 如果直接修改代码、文档或配置，也必须登记自己的 `write_lease`。

### Thread Naming

默认 thread 标题格式：

```text
<issue-id> <role> [short-scope]
```

完成后标题格式：

```text
【完成】<issue-id> <role> [short-scope]
```

固定规则：

- `【完成】` 只表示该 thread 自身分配的工作完成，不等于 issue 或 root goal 已 Done。
- 可写 thread 只有在 lease 达到 `ready_for_integration`、`integrated` 或 `released` 后，才能打完成标识。
- 只读 verify / review thread 只有在追加固定 `Thread Status` comment 后，才能打完成标识。
- 标题标识不替代 Issue Tracker 的 `current_state`、`write_lease.state` 或 `Current State` comment。

### Dispatch Rules

固定规则：

- subagent 用于短生命周期、当前主 thread 内部、无需长期 UI 可见、无需独立 worktree、无需直接回写 Issue Tracker 的任务。
- child thread 用于需要独立 Codex 会话、长期可见、跨天继续、绑定 issue / branch / worktree 或持续回写状态的任务。
- 会修改代码、文档或配置的 child thread 默认必须使用独立 worktree、独立 branch 和明确 `write_lease`。
- single Execution Issue 下常规预期是 `1-2` 个 child threads；超过 `3` 个 active child threads 时，主 thread 应回到 `gate` 判断是否需要拆卡。

### Write Lease

`write_lease` 是主 thread 发给某个 thread 的写入许可、写入边界和集成约定；它不是 git lock 或文件系统锁。

最小字段：

- `lease_id`
- `state`
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

`write_lease.state` 使用：

- `requested`
- `active`
- `paused`
- `ready_for_integration`
- `integrated`
- `released`
- `blocked`

固定规则：

- `write_scope` 以路径模式为主；语义说明只能补充边界，不能覆盖路径冲突。
- 路径模式重叠默认视为冲突；只有主 thread 明确判断为 disjoint，才允许并发可写 thread。
- scope 冲突默认串行 handoff：暂停后一个 lease，等前一个 lease `ready_for_integration` / `integrated` / `released` 后再决定是否恢复。
- 第一版不把 `write_lease` 冲突判断做进 `harness-check`；重复踩坑后再通过 `rule-promotion` 升级为项目级可选 gate。

### Waiting on Long-Running Threads

长任务中主 thread 不应空等。若下一步依赖子 thread，主 thread 应停在可恢复状态：

- `goal_state`: `waiting_on_child`
- `waiting_on`: 等待的 thread、lease、期望 event
- `next_check`: 下一次检查时间或触发条件
- `recovery_point`: 需要读取的 issue、thread、branch、plan 和命令
- `next_action`: 子 thread ready 时如何 integrate；未 ready 时如何更新 blocker / status

若仍有不重叠工作，主 thread 可以继续 dispatch 或准备 review / test / final verify；不得重复实现子 thread 已分配的 scope。

### Integration and Final Verify

固定规则：

- 默认顺序是 `implement -> local/test verify -> review -> integrate -> final verify`。
- 第一个 `verify` 是执行者或 test thread 的局部验证，用来确认输出进入可 review 状态。
- review 默认前置；集成后若发生冲突处理、integration fix、diff 形态明显变化、二次 verify 失败后返修，或 write scope 边界有争议，主 thread 必须补轻量 review。
- `integrate -> verify` 是权威验证。主 thread 集成任何可写 lease 后，必须在集成后的 repo truth 上重新跑最终验证矩阵。
- 若 Goal Prompt、Issue Acceptance Matrix、active plan 或 test runbook 声明 required live E2E，则 post-integration verify 必须执行 live E2E；无法执行时停止在 `blocked` / `manual-gate`，不得进入 `verified`、`ready_for_merge` 或 `done`。

### 跨仓 truth split（按需）

| 仓库角色 | 默认负责内容 |
| --- | --- |
| provider 仓 | contract truth、schema truth、接口示例、服务端 runbook、provider 验收口径 |
| consumer 仓 | consumer rule、contract 快照、cache / mock / golden、消费侧 runbook |

固定解释：

- consumer 仓可以缓存、快照和验证 provider contract，但不反定义 provider truth。
- consumer 侧发现 contract 漂移时，先回到 provider 仓确认真实 contract，再决定同步哪一侧。
- 跨仓 closeout 要写清 provider truth、consumer truth 和结果回写分别落在哪个载体。

## 项目级机械约束

固定入口：

- `docs/harness/project-constraints.md`

固定解释：

- `project-constraints.md` 负责登记项目级机械约束、当前状态、执行载体和验证命令。
- base harness 只提供登记协议和检查入口，不内置项目专属架构规则。
- 没有可执行命令或 gate 时，项目规则不得标记为 `enforced`。
- 若项目后续接入 `project-check`，它应作为项目专属检查入口存在，不替代 `make harness-check`。
- `harness-check` 只确认 `project-constraints.md` 结构完整，不替项目臆造规则。

## Maintenance Loop

固定目标：

- 发现 `docs`、`plans`、`runbooks`、`contracts`、`checks`、`writeback` 之间的漂移。
- 把漂移分类为可直接修正文档、需要建 issue、需要升级机械规则或需要人工决策。
- 默认只输出维护 findings，不自动改代码、不自动建 issue、不自动调整业务行为。

### Modes

默认 mode：`report-only`

| Mode | 行为 | 允许副作用 |
| --- | --- | --- |
| `report-only` | 扫描、分类、输出维护 findings | 无文件修改、无外部系统写入 |
| `issue-create` | 在 `report-only` 输出基础上，按用户确认创建或更新维护 issue | 只允许 issue / comment / writeback log 写入 |
| `safe-fix` | 只修低风险文档维护项 | 低风险文档索引、旧路径引用、prompt README 引用 |
| `rule-promotion` | 把重复 review finding 升级为机械规则候选 | 可更新 plan / project constraints；真正新增检查需按计划实施和验证 |

### 输出结构

Maintenance loop 的输出必须包含：

1. `Maintenance Findings`
2. `Classification`
3. `Verification Plan`
4. `Writeback Plan`
5. `Residual Risks`
6. `Next Action`

### 自动修复边界

允许进入 `safe-fix` 的低风险项：

- 文档索引漏链、过期章节链接、旧路径引用
- prompt README 中缺少已存在 prompt / guide 的引用
- runbook 或计划文档中的明显文件重命名引用

只能报告或建 issue，不能自动修复的项：

- API contract、schema、OpenAPI 语义和兼容性策略
- 安全策略、鉴权、权限和危险命令边界
- 业务行为、数据变更、迁移策略、运行时配置语义
- 任何需要人类选择取舍的 `human_decision_required` 项

固定解释：

- maintenance loop 不是新的自动修复脚本，也不要求新增 `maintenance_loop.sh`。
- `report-only` 可以不写 plan；一旦进入跨文件修复、`issue-create`、`safe-fix`、`rule-promotion` 或外部系统回写，应遵循 `.agents/PLANS.md`。
- prompts / guides 与 `AGENTS.md`、`docs/harness/*`、`.agents/PLANS.md` 冲突时，以后者为准。

## Review 口径

### findings-first

评审结论优先看：

1. 正确性
2. 回归风险
3. 范围越界
4. 测试缺口
5. 可维护性

固定要求：

- 结果采用 findings-first 输出
- `blocking_findings` 是 review gate 唯一阻塞字段
- 非阻塞风格问题不应压过功能问题

## Verification 口径

最小验证矩阵：

| 阶段 | 默认动作 |
| --- | --- |
| 基线检查 | `make harness-check` |
| 总入口 | `make harness-verify` |
| review gate | `make harness-review-gate PLAN=path/to/plan.md` |
| Windows 基线检查 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1` |
| Windows review gate | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\review_gate.ps1 -Plan .\.agents\plans\example.md` |
| merge | 默认由 agent 根据仓库真相给出 `manual / blocked / merged` 结论 |
| escalation | 默认由 agent 根据风险和阻塞项给出 `continue / degraded / escalated` 结论 |

固定要求：

- `harness-check` 除了检查关键文件、关键字段、`.gitignore` contract，还必须做 gate smoke test
- `check.ps1` 与 `review_gate.ps1` 对齐 Bash gate 行为，但不要求 Windows 用户安装 `make`、Git Bash 或 WSL
- `review_gate` 只根据 `blocking_findings` 判定 pass / fail
- `merge` 虽然仍是控制面阶段，但 base harness 默认不内置 shell evaluator
- `escalation` 虽然仍是控制面阶段，但 base harness 默认不内置 shell evaluator
- `stop_scope=stop-current-slice` 时，结果面必须说明下一步动作

## 运行反馈与结果回写

固定规则：

- `运行反馈默认写回 Issue Tracker`
- `结果回写默认写回 Issue Tracker`

最小要求：

- 每一轮至少要把 `verification_summary`、`review_summary`、`writeback_summary`、`residual_risks`、`recovery_point`、`next_action` 写回 Issue Tracker
- 若仓库启用了 PR / MR，再把代码叙事和 review thread 写到 PR / MR
- 若本轮修改了设计或运行说明，再把必要事实回写到 repo 文档
- 若仓库启用了 `.agents/state` / `.agents/runs`，可同步记录本地恢复点与批次结果面

默认解释：

- 不启用本地 `state / runs` 时，`recovery_point` 与 `next_action` 默认留在 Issue Tracker
- 启用本地 `state / runs` 时，协作状态仍以 Issue Tracker 为准，本地文件只补充恢复与审计细节
- `writeback` 不要求单独本地运行面才能成立

## 测试 runbook

固定规则：

- `docs/test/RUNBOOK_TEMPLATE.md` 是 base harness 的通用测试 runbook 模板。
- 具体测试文档默认放在 `docs/test/<domain>/`，同时保留可执行步骤和提交版结果摘要。
- `当前验证结果` / `本次执行结果` 是提交版测试真相，后续同步或 closeout 不得删成空模板。

## provider-neutral 默认策略

当前 merge provider：

- `__PROVIDER__`

当前 issue provider：

- `__ISSUE_PROVIDER__`

默认解释：

- `neutral`：只要求 agent 能给出 `manual` 或 `blocked` 结论，不假装自动 merge
- `github` / `gitlab`：只调整默认说明，不改变当前控制面目录结构
- issue provider 只影响 Issue Tracker profile，不影响 PR / MR merge provider

## `.agents` 计划 contract

### 目录语义

| 路径 | 语义 |
| --- | --- |
| `.agents/PLANS.md` | 复杂任务计划协议 |
| `.agents/plans/TEMPLATE.md` | 具体计划模板 |
| `.agents/plans/EXAMPLE-implementation.md` | 实现型计划范例与质量标杆 |
| `.agents/skills/` | base 默认 repo-local workflow skill 层 |
| `.agents/state/TEMPLATE.md` | 本地辅助恢复面模板 |
| `.agents/runs/TEMPLATE.md` | 本地辅助结果面模板 |
| `docs/issues/` | `issue-provider=repo` 时的仓库 issue 存储 |

固定要求：

- 默认初始化计划协议、计划主模板、实现型 exemplar、repo-local workflow skill 和本地辅助运行面模板
- `.agents/skills` 默认包含 `project-plan-archive`、`project-version-release`、`test-runbook`
- 默认 skill 不直接连接外部 Issue Tracker、数据库或发布系统；外部完成态、发布动作和 live 环境由 agent 按项目规则另行查证或执行
- `.agents/state` / `.agents/runs` 服务本地恢复与结果审计，不替代 Issue Tracker
- `review_gate` 的输入真相来自 plan 文件，不依赖额外状态目录

## 目录级 AGENTS（按需）

固定规则：

- 根级 `AGENTS.md` 负责全局边界、提交流程、验证入口和默认不提交规则。
- 目录级 `AGENTS.md` 负责该目录的稳定实现习惯、分层约束、测试约定和代码风格。
- 修改某个目录前，优先读取就近的目录级 `AGENTS.md`；若约束更细，以目录级规则为准。
- 不用目录级 `AGENTS.md` 保存临时 issue 计划、一次性排查记录或临时运行结果。

## Agent 扩展层

固定规则：

- `docs/harness/` 不承载 prompt 模板
- 若仓库后续通过 agent 驱动初始化补了 `.agents/prompts/` 与 `.agents/guides/`，这些文件属于使用手册与扩展说明层
- prompts / guides 与 `docs/harness/*`、`.agents/PLANS.md` 冲突时，以后者为准
- base harness 的 `check / verify` 不依赖 prompts / guides 存在
- `merge` / `escalation` 默认由 agent 补齐，不要求扩展成 repo-local shell gate

## `.gitignore` 约束

固定要求：

- `docs/harness/*.md` 默认应提交
- `docs/issues/*.md` 默认应提交
- `.agents/plans/TEMPLATE.md` 默认应提交
- `.agents/plans/EXAMPLE-implementation.md` 默认应提交
- 若后续补了 `.agents/prompts/` 与 `.agents/guides/`，这些文档默认也应提交

同时默认不提交：

- 本地日志和缓存
- 本地数据库文件
- IDE 私有文件
