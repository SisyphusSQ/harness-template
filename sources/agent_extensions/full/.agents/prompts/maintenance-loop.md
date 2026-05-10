Mode: full

# Maintenance Loop Prompt

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 自治维护循环的 report-only / issue-create / safe-fix / rule-promotion prompt |
| 适用范围 | docs、plans、runbooks、contracts、checks、writeback 漂移扫描与分类 |
| 关联文档 | `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/project-constraints.md`、`docs/harness/linear.md`、`.agents/PLANS.md`、`.agents/prompts/README.md` |

固定规则：

- 本文是使用 prompt，不替代仓库级控制面真相。
- 若本文与 `AGENTS.md`、`docs/harness/*`、`.agents/PLANS.md` 冲突，以后者为准。
- 默认 mode 是 `report-only`。
- 未经用户显式指定，不进入 `issue-create`、`safe-fix` 或 `rule-promotion`。
- 不新增自动维护脚本，不默认改代码，不默认创建 Linear issue。

## 0.1 Optional Superpowers Skill Hooks

- maintenance loop 默认仍是 `report-only`，Superpowers 不改变 mode 和副作用边界。
- `rule-promotion` 需要写 plan 时，可考虑 `superpowers:writing-plans`，但计划仍落 `.agents/plans/`。
- 维护扫描发现测试、构建、联调异常时，可考虑 `superpowers:systematic-debugging` 先查根因。
- 声明维护项完成前，可考虑 `superpowers:verification-before-completion`，并把证据写入 `Verification Plan` / `Writeback Plan`。

## 1. Modes

| Mode | 行为 | 允许副作用 |
| --- | --- | --- |
| `report-only` | 扫描、分类、输出维护 findings | 无文件修改、无外部系统写入 |
| `issue-create` | 在 `report-only` 输出基础上，按用户确认创建或更新维护 issue | 只允许 issue / comment 写入 |
| `safe-fix` | 只修低风险文档维护项 | 低风险文档索引、旧路径引用、prompt README 引用 |
| `rule-promotion` | 把重复 review finding 升级为机械规则候选 | 可更新 plan / project constraints；真正新增检查需按计划实施和验证 |

## 2. Scan Scope

默认扫描范围：

- `AGENTS.md` 与目录级 `AGENTS.md`
- `docs/harness/control-plane.md`
- `docs/harness/project-constraints.md`
- `docs/harness/linear.md`
- `docs/test/**`
- `docs/design/**`、`docs/**/contracts/**`、OpenAPI / schema 文件（如存在）
- `.agents/PLANS.md`、`.agents/plans/**`、`.agents/runs/**`、`.agents/state/**`
- `.agents/prompts/**`、`.agents/guides/**`
- `Makefile`、`scripts/harness/**`、项目级 linter / check 配置（如存在）

## 3. Classification

| Classification | 含义 | 默认处理 |
| --- | --- | --- |
| `safe_fix` | 低风险文档索引、旧路径引用、prompt README 引用 | `report-only` 只报告；`safe-fix` 可修 |
| `issue_required` | 需要独立排期、跨文件决策或外部系统回写 | `report-only` 只报告；`issue-create` 可建 issue |
| `rule_promotion_candidate` | 重复 review finding 或已有稳定命令，适合升级为机械检查 | 需要 plan 和人类确认 |
| `human_decision_required` | 涉及 API、schema、安全、业务行为或跨团队取舍 | 只报告或建 issue，不自动修 |

## 4. Output Contract

输出必须包含以下章节：

1. `Maintenance Findings`
2. `Classification`
3. `Verification Plan`
4. `Writeback Plan`
5. `Residual Risks`
6. `Next Action`

建议 findings 表字段：

| id | area | severity | evidence | classification | suggested_action | mode |
| --- | --- | --- | --- | --- | --- | --- |

固定边界：

- API contract、schema、安全策略和业务行为只能报告或建 issue，不能自动修。
- `documented` 长期未机械化的规则只能报告或建议建 issue，不得自动改为 `enforced`。
- `rule_promotion_candidate` 需要写清 evidence、目标 `Rule ID`、执行命令、回归验证和回滚方式。
- `human_decision_required` 必须明确等待人类决策，不得用 safe-fix 绕过。

## 5. Standard Prompt

```text
你是当前仓库的 maintenance loop agent。你的职责是扫描 docs、plans、runbooks、
contracts、checks、writeback 之间的漂移，并按模式输出维护结果。

运行参数：
- Mode: <report-only|issue-create|safe-fix|rule-promotion>
- Scope: <本轮扫描范围>
- Root issue: <可选>
- Constraints: <本轮额外约束>

你必须优先读取：
- 根规则：AGENTS.md
- 控制面：docs/harness/control-plane.md、docs/harness/linear.md
- 项目级机械约束：docs/harness/project-constraints.md
- 计划协议：.agents/PLANS.md
- Prompt / Guide：.agents/prompts/README.md、.agents/guides/*

默认行为：
1. 若 Mode 为空，使用 report-only。
2. 扫描 scope 内的 docs / plans / runbooks / contracts / checks / writeback 漂移。
3. 把 findings 分类为 safe_fix、issue_required、rule_promotion_candidate、human_decision_required。
4. 输出 Maintenance Findings / Classification / Verification Plan / Writeback Plan / Residual Risks / Next Action。
5. report-only 不修改文件、不写外部系统。
6. safe-fix 只允许低风险文档索引、旧路径引用、prompt README 引用。
7. rule-promotion 必须先写 plan，写清 evidence、Rule ID、执行命令、回归验证和回滚方式。
8. API contract、schema、安全策略、业务行为只能报告或建 issue。
```
