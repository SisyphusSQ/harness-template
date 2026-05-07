# Control Plane

## 主流程

固定主流程：

`collect -> gate -> freeze -> slice -> implement -> verify -> review -> writeback -> pr_prep -> merge -> notify`

## 阶段职责

| 阶段 | 目标 | 主要产物 |
| --- | --- | --- |
| `collect` | 汇总目标、约束、现有计划和上下文 | batch 候选 |
| `gate` | 判断是否允许进入当前批次 | 准入 / 降级结论 |
| `freeze` | 冻结当前轮范围和验收口径 | Batch Plan |
| `slice` | 收敛最小可验证 slice | 当前轮实施边界 |
| `implement` | 实施当前 slice | 代码 / 文档 / 计划更新 |
| `verify` | 执行验证矩阵 | Verify Summary |
| `review` | findings-first review | Review Summary |
| `writeback` | 回写 Issue Tracker、必要 repo 文档与代码叙事面 | Writeback Summary |
| `pr_prep` | 准备 PR / MR 叙事 | PR Prep Summary |
| `merge` | 自动或手动 merge 收口 | merge 结论 |
| `notify` | 输出当前轮结果 | Notify Summary |

## 固定原则

- execution issue 的 `Stop When` 只负责停当前 slice
- 若当前对象是 Master issue，只有 Master Exit Criteria 满足时，整个 Master 才算完成
- provider 未锁定或自动化不可用时，`merge` 允许降级为 `manual`
- 新发现的范围外内容统一进入 follow-up，不顺手纳入当前卡

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
- `.agent/state` / `.agent/runs` 属于本地辅助运行面；它们补充恢复和审计细节，但不替代 Issue Tracker。
- Linear 只是一个 Issue Tracker profile，兼容说明在 `docs/harness/linear.md`。

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
- 安全策略、鉴权、权限、脱敏规则和危险命令边界
- 业务行为、数据变更、迁移策略、运行时配置语义
- 任何需要人类选择取舍的 `human_decision_required` 项

固定解释：

- maintenance loop 不是新的自动修复脚本，也不要求新增 `maintenance_loop.sh`。
- `report-only` 可以不写 plan；一旦进入跨文件修复、`issue-create`、`safe-fix`、`rule-promotion` 或外部系统回写，应遵循 `.agent/PLANS.md`。
- prompts / guides 与 `AGENTS.md`、`docs/harness/*`、`.agent/PLANS.md` 冲突时，以后者为准。

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
| merge | 默认由 agent 根据仓库真相给出 `manual / blocked / merged` 结论 |
| escalation | 默认由 agent 根据风险和阻塞项给出 `continue / degraded / escalated` 结论 |

固定要求：

- `harness-check` 除了检查关键文件、关键字段、`.gitignore` contract，还必须做 gate smoke test
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
- 若仓库启用了 `.agent/state` / `.agent/runs`，可同步记录本地恢复点与批次结果面

默认解释：

- 不启用本地 `state / runs` 时，`recovery_point` 与 `next_action` 默认留在 Issue Tracker
- 启用本地 `state / runs` 时，协作状态仍以 Issue Tracker 为准，本地文件只补充恢复与审计细节
- `writeback` 不要求单独本地运行面才能成立

## 测试 runbook

固定规则：

- `docs/test/RUNBOOK_TEMPLATE.md` 是 base harness 的通用测试 runbook 模板。
- 具体测试文档默认放在 `docs/test/<domain>/`，同时保留可执行步骤和提交版脱敏结果摘要。
- 已脱敏的 `当前验证结果` / `本次执行结果` 是提交版测试真相，后续同步或 closeout 不得删成空模板。
- 原始命令输出、真实凭据、数据库主机、连接串、行主键、临时目录、完整下载 URL 和机器本地痕迹不写入提交版文档。

## provider-neutral 默认策略

当前 merge provider：

- `__PROVIDER__`

当前 issue provider：

- `__ISSUE_PROVIDER__`

默认解释：

- `neutral`：只要求 agent 能给出 `manual` 或 `blocked` 结论，不假装自动 merge
- `github` / `gitlab`：只调整默认说明，不改变当前控制面目录结构
- issue provider 只影响 Issue Tracker profile，不影响 PR / MR merge provider

## `.agent` 计划 contract

### 目录语义

| 路径 | 语义 |
| --- | --- |
| `.agent/PLANS.md` | 复杂任务计划协议 |
| `.agent/plans/TEMPLATE.md` | 具体计划模板 |
| `.agent/plans/EXAMPLE-implementation.md` | 实现型计划范例与质量标杆 |
| `.agent/state/TEMPLATE.md` | 本地辅助恢复面模板 |
| `.agent/runs/TEMPLATE.md` | 本地辅助结果面模板 |
| `.agent/skills/` | 可选 repo-local skill 目录 |
| `docs/issues/` | `issue-provider=repo` 时的仓库 issue 存储 |

固定要求：

- 默认初始化计划协议、计划主模板、实现型 exemplar 和本地辅助运行面模板
- `.agent/state` / `.agent/runs` 服务本地恢复与结果审计，不替代 Issue Tracker
- `.agent/skills` 只在项目有稳定复用的专门流程时补充，不属于 base harness 必备输出
- `review_gate` 的输入真相来自 plan 文件，不依赖额外状态目录

## 目录级 AGENTS（按需）

固定规则：

- 根级 `AGENTS.md` 负责全局边界、提交流程、验证入口和默认不提交规则。
- 目录级 `AGENTS.md` 负责该目录的稳定实现习惯、分层约束、测试约定和代码风格。
- 修改某个目录前，优先读取就近的目录级 `AGENTS.md`；若约束更细，以目录级规则为准。
- 不用目录级 `AGENTS.md` 保存临时 issue 计划、一次性排查记录或敏感运行结果。

## Agent 扩展层

固定规则：

- `docs/harness/` 不承载 prompt 模板
- 若仓库后续通过 agent 驱动初始化补了 `.agent/prompts/` 与 `.agent/guides/`，这些文件属于使用手册与扩展说明层
- prompts / guides 与 `docs/harness/*`、`.agent/PLANS.md` 冲突时，以后者为准
- base harness 的 `check / verify` 不依赖 prompts / guides 存在
- `merge` / `escalation` 默认由 agent 补齐，不要求扩展成 repo-local shell gate

## `.gitignore` 约束

固定要求：

- `docs/harness/*.md` 默认应提交
- `docs/issues/*.md` 默认应提交
- `.agent/plans/TEMPLATE.md` 默认应提交
- `.agent/plans/EXAMPLE-implementation.md` 默认应提交
- 若后续补了 `.agent/prompts/` 与 `.agent/guides/`，这些文档默认也应提交

同时默认不提交：

- 真实环境配置
- token / cookie / DSN / secret
- 本地日志和缓存
- 本地数据库文件
- IDE 私有文件
