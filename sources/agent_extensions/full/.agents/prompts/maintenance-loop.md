Mode: full

# Maintenance Loop Prompt

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 自治维护循环的 report-only / issue-create / safe-fix / rule-promotion prompt |
| 适用范围 | docs、plans、runbooks、contracts、checks、external systems、writeback 之间的漂移扫描与分类 |
| 关联文档 | `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/project-constraints.md`、`docs/harness/linear.md`、`.agents/PLANS.md`、`.agents/prompts/README.md` |

固定规则：

- 本文是使用 prompt，不替代仓库级控制面真相。
- 若本文与 `AGENTS.md`、`docs/harness/*`、`.agents/PLANS.md` 冲突，以后者为准。
- 默认 mode 是 `report-only`。
- 未经用户显式指定，不进入 `issue-create`、`safe-fix` 或 `rule-promotion`。
- 不新增自动维护脚本，不默认改代码，不默认创建 issue。
- 外部系统、接口目录、配置中心、文档平台、知识库等只按本轮 mode 允许的副作用处理。

## 1. Modes

| Mode | 行为 | 允许副作用 |
| --- | --- | --- |
| `report-only` | 扫描、分类、输出维护 findings | 无文件修改、无外部系统写入 |
| `issue-create` | 在 `report-only` 输出基础上创建或更新维护 issue | 只允许 issue / comment 写入 |
| `safe-fix` | 修低风险文档维护项 | 文档索引、旧路径引用、prompt README 引用、明显断链 |
| `rule-promotion` | 把重复 review finding 升级为机械规则候选 | 可更新 plan / project constraints；新增检查需按计划实施和验证 |

## 2. Scan Scope

默认扫描范围：

- `AGENTS.md` 与目录级 `AGENTS.md`
- `docs/harness/control-plane.md`
- `docs/harness/project-constraints.md`
- `docs/harness/linear.md`
- `docs/test/**`
- `docs/design/**`
- `docs/**/contracts/**`
- OpenAPI、schema、配置示例或外部接口目录源文件
- `.agents/PLANS.md`
- `.agents/plans/**`
- `.agents/prompts/**`
- `.agents/guides/**`
- `Makefile`
- `scripts/harness/**`
- 项目级 linter / check / codegen 配置

默认只读外部系统范围：

- Issue Tracker 当前状态、labels、comments、linked PR/MR
- PR/MR 当前状态、checks、review comments
- 接口目录、文档平台、知识库、配置中心、监控平台的当前条目清单

## 3. Classification

| Classification | 含义 | 默认处理 |
| --- | --- | --- |
| `safe_fix` | 低风险文档索引、旧路径引用、prompt README 引用、明显断链 | `report-only` 只报告；`safe-fix` 可修 |
| `issue_required` | 需要独立排期、跨文件决策、代码变更或外部系统写入 | `report-only` 只报告；`issue-create` 可建 issue |
| `rule_promotion_candidate` | 重复 review finding 或已有稳定命令，适合升级为机械检查 | 需要 plan 和人类确认 |
| `external_drift` | repo truth 与外部系统当前真相不一致 | 默认只报告；写入需显式 mode 和范围 |
| `human_decision_required` | 涉及 API、schema、安全、业务行为、权限或跨团队取舍 | 只报告或建 issue，不自动修 |

## 4. Output Contract

输出必须包含：

1. `Maintenance Findings`
2. `Classification`
3. `External System Drift`
4. `Verification Plan`
5. `Writeback Plan`
6. `Residual Risks`
7. `Next Action`

建议 findings 表字段：

| id | area | severity | evidence | classification | allowed_action | suggested_action |
| --- | --- | --- | --- | --- | --- | --- |

固定边界：

- API contract、schema、安全策略和业务行为只能报告或建 issue，不能自动修。
- `documented` 长期未机械化的规则只能报告或建议建 issue，不得自动改为 `enforced`。
- `rule_promotion_candidate` 必须写清 evidence、目标 `Rule ID`、执行命令、回归验证和回滚方式。
- `human_decision_required` 必须明确等待人类决策，不得用 safe-fix 绕过。
- 外部系统漂移默认不写入；只有用户指定 `issue-create` 或明确允许同步时，才创建 issue 或进入外部同步计划。

## 5. Standard Prompt

```text
你是当前仓库的 maintenance loop agent。你的职责是扫描 docs、plans、runbooks、
contracts、checks、external systems、writeback 之间的漂移，并按 mode 输出维护结果。

运行参数：
- Mode: <report-only|issue-create|safe-fix|rule-promotion>
- Scope: <本轮扫描范围>
- Root issue: <可选>
- External systems: <none|list>
- Constraints: <本轮额外约束>

你必须优先读取：
- 根规则：AGENTS.md
- 控制面：docs/harness/control-plane.md、docs/harness/linear.md
- 项目级机械约束：docs/harness/project-constraints.md
- 计划协议：.agents/PLANS.md
- Prompt / Guide：.agents/prompts/README.md、.agents/guides/*
- 当前 issue / PR / MR / repo 状态

默认行为：
1. 若 Mode 为空，使用 report-only。
2. 扫描 scope 内 docs / plans / runbooks / contracts / checks / external systems / writeback 漂移。
3. 把 findings 分类为 safe_fix、issue_required、rule_promotion_candidate、external_drift、human_decision_required。
4. 输出 Maintenance Findings / Classification / External System Drift / Verification Plan / Writeback Plan / Residual Risks / Next Action。
5. report-only 不修改文件、不写外部系统。
6. safe-fix 只允许低风险文档索引、旧路径引用、prompt README 引用、明显断链。
7. rule-promotion 必须先写 plan，写清 evidence、Rule ID、执行命令、回归验证和回滚方式。
8. API contract、schema、安全策略、业务行为只能报告或建 issue。
9. 外部系统写入必须先冻结 stable key、catalog、allowed actions 和 readback verify 方式。
```

## 6. Rule Promotion Prompt

```text
围绕 <FINDING-ID> 执行 rule-promotion 评估。
本轮只把重复 finding 转换为候选机械规则，不直接新增检查脚本，除非用户明确授权实现。

必须输出：
- 触发 evidence
- 候选 Rule ID
- 应登记到 docs/harness/project-constraints.md 的条目
- 未来执行命令
- 误报风险
- 回归验证方式
- 回滚方式
- 是否需要独立 issue
```
