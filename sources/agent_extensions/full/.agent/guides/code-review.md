Mode: full

# Code Review Guide

## 1. 目标

这份文档用于统一仓库内的 findings-first review 口径，确保 `review` 是独立 checkpoint，而不是 `implement` 的附属动作。

## 2. 固定顺序

review 输出优先顺序固定为：

1. 正确性
2. 回归风险
3. 范围越界
4. 测试缺口
5. 可维护性

固定规则：

- 结果采用 findings-first 输出
- 非阻塞风格问题不应压过功能问题
- `blocking_findings` 是 review gate 的唯一阻塞字段

## 3. blocking finding 定义

以下情况默认可判为 blocking finding：

- 当前实现与冻结范围或预期行为不一致
- 会引入明显回归风险，但当前没有被验证覆盖
- 关键路径没有验证证据支撑
- write scope 超出当前卡已冻结边界
- 当前结果无法安全进入 mr_prep / merge

以下情况默认不构成 blocking finding：

- 命名、格式或轻微措辞优化
- 不影响当前功能正确性的风格建议
- 明确标记为 follow-up 的范围外改进项

## 4. Review 输出结构

建议固定输出：

- `Findings`
- `blocking_findings`
- `Residual Risks`
- `Scope Guard`
- `Next Action`

其中 `Review Summary` 至少应包含：

- `blocking_findings`
- `status`
- `scope_guard`

最小 Linear writeback 结构建议包含：

- `review_summary`
- `blocking_findings`
- `residual_risks`
- `next_action`

## 5. 何时执行 review

固定规则：

- review 只能发生在 verify 之后
- verify 未通过前，不进入 review
- review 未通过前，不进入 mr_prep / merge
- 修复 blocking findings 后，必须重新执行 `verify -> review`

## 6. Optional Superpowers Review Hook

- 若 Superpowers 可用，重大改动、subagent 执行后或 merge 前可考虑 `superpowers:requesting-code-review`。
- 外部 review 结论必须折回 `Findings`、`blocking_findings`、`Residual Risks`、`Scope Guard`、`Next Action`。
- reviewer 发现的 Critical / Important 问题不得绕过；若判断为误报，需要在 review summary 里写明反证。

## 7. 推荐 Prompt

```text
针对 <ISSUE-ID> 当前分支，执行独立 review gate。
先读取最新 Verify Summary，再按 findings-first 输出 Findings、blocking_findings、
Residual Risks 与下一步建议；
若存在 blocking findings，不进入 mr_prep。
```
