Mode: full

# Linter 接入指南

本文帮助项目把稳定约束落实为可执行检查。它不是“已经接通 lint”的证明。

## 原则

- 项目真实约束先写入根 `AGENTS.md`。
- 可以机械验证的规则再落实到 linter、test、contract diff、Makefile 或 Harness gate。
- 没有可执行命令、正反例和稳定失败语义时，只能称为文档约束。
- 不把临时 Issue 需求、一次性 review finding 或特定实现偏好直接升级成全仓规则。

## 接入步骤

1. 从重复缺陷、稳定架构边界或外部 contract 中提取候选规则。
2. 明确检查对象、适用目录、允许例外和误报边界。
3. 选择项目已有 lint/test 入口，避免另建平行工具链。
4. 先写至少一个应通过和一个应失败的 fixture。
5. 实现检查并给出稳定、可定位的错误信息。
6. 把命令接入项目 Makefile 或既有验证入口。
7. 更新 `AGENTS.md` 的项目约束与验证命令。
8. 运行 focused tests、项目完整验证、`make harness-verify` 和 `git diff --check`。

## 交付结果

至少报告：

- Rule / source
- Enforcement command
- Positive / negative fixture
- Scope and exceptions
- Verification result
- Residual risks
- Rollback or disable path
