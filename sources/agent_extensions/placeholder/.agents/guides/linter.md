Mode: placeholder

# Linter 接入指南（占位）

项目真实约束写入 `AGENTS.md`；能机械验证的规则再接入项目已有 lint、test、Makefile 或 gate。

补齐时至少说明：

- 规则来源和适用范围
- 检查命令
- 一个应通过和一个应失败的 fixture
- 允许例外与误报边界
- 验证结果和回滚方式

没有可执行命令和正反例时，不要宣称规则已被机械强制。
