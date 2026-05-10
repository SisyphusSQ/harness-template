Mode: placeholder

# Maintenance Loop Prompt（占位）

## 用途

这份文件用于自治维护循环的说明与 Prompt 模板。

当前是占位文件，不代表仓库已经冻结完整 repo-local maintenance 语义。

## 默认模式

- 默认 mode：`report-only`
- 默认只扫描、分类、输出维护 findings
- 未经用户显式指定，不进入 `issue-create`、`safe-fix` 或 `rule-promotion`
- 不新增自动维护脚本，不默认改代码，不默认创建 Linear issue

## 当前仍缺的 repo-local 决策

- 固定扫描范围
- 哪些文档索引、旧路径引用和 prompt README 引用可以进入 `safe-fix`
- 哪些 repeated review finding 可作为 `rule_promotion_candidate`
- 维护 findings 默认写回 Linear、repo 文档还是本地 run surface
- 哪些情况必须标记为 `human_decision_required`

## 后续应补齐的主题

- `report-only / issue-create / safe-fix / rule-promotion`
- `Maintenance Findings / Classification / Verification Plan / Writeback Plan / Residual Risks / Next Action`
- `docs/harness/project-constraints.md` 中 `maintenance_candidate` 与 `rule_promotion_candidate` 的使用规则
- API contract、schema、安全策略、业务行为的自动修复禁区

## 临时占位模板骨架

```text
你是当前仓库的 maintenance loop agent。
围绕 <SCOPE> 扫描 docs、plans、runbooks、contracts、checks、writeback 漂移。

运行参数：
- Mode: <report-only|issue-create|safe-fix|rule-promotion>
- Scope: <SCOPE>
- Constraints: <CONSTRAINTS>

输出结构：
1. Maintenance Findings
2. Classification
3. Verification Plan
4. Writeback Plan
5. Residual Risks
6. Next Action
```

## 使用约束

- 先读取 `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/project-constraints.md`、`docs/harness/linear.md`、`.agents/PLANS.md`
- `report-only` 不修改文件、不写外部系统
- `safe-fix` 只允许低风险文档维护项
- `rule-promotion` 必须写 plan，并写清 evidence、`Rule ID`、执行命令、回归验证和回滚方式
- 若 Superpowers skills 可用，只能参考 `.agents/prompts/README.md` 的 Optional Superpowers Skill Hooks；当前占位文件不冻结完整 maintenance skill hook contract
- API contract、schema、安全策略和业务行为默认 `human_decision_required`
