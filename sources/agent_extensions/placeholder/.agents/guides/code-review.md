Mode: placeholder

# Code Review Guide（占位）

## 用途

这份文件用于承载仓库级 findings-first review 口径。

当前是占位文件，不代表仓库已经冻结完整 review 规则。

## 当前仍缺的 repo-local 决策

- blocking finding 的定义
- findings 输出顺序
- Review Summary 需要回写哪些字段
- review 与 verify / mr_prep 的前后关系
- Linear writeback 的最小 review 字段集合

## 最小占位结构

- Findings
- blocking_findings
- Residual Risks
- Scope Guard
- Next Action

## 临时占位说明

- 在补齐前，默认优先关注：正确性、回归风险、范围越界、测试缺口、可维护性
- 若仓库已有 `Review Summary` 字段契约，应以后者为准
- 若 Superpowers skills 可用，只能参考 `.agents/prompts/README.md` 的 Optional Superpowers Skill Hooks；当前占位文件不冻结完整 review skill hook contract
- 补齐前不要把当前文件当作完整 review gate contract

## 基础 Review Policy

- standard 使用 `review_owner=main-agent-self-review`，要求主 agent 做 findings-first 对抗式自审。
- strict 使用 `review_owner=subagent`，必须由 subagent 独立评审；不可用时阻塞。
- 两种 policy 都必须输出 `blocking_findings`，只有 `blocking_findings=none` 才通过。
- 未提供 `review_policy` 时按 strict；repo-local 规则只能增加 strict 条件，不能降低 `docs/harness/control-plane.md` 的基础风险条件。
