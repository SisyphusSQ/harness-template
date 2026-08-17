# 可选计划说明

本文件只说明什么时候值得写计划，以及计划至少要表达什么。计划不是强制状态机，也不替代 Issue、代码或项目验证。

## 何时建议写计划

满足任一条件时，建议先写或更新 `.agents/plans/` 下的计划：

- 跨目录、模块或仓库；
- 影响公开接口、contract、配置或兼容性；
- 涉及 schema、migration、数据、安全、权限、发布或回滚；
- 需要多轮验证、中断恢复或外部系统回写；
- 改动面较大，无法用一个短步骤列表可靠表达。

单文件小修、拼写修正和无行为影响的微调可以直接处理。

## 目录与生命周期

- 计划路径：`.agents/plans/YYYY-MM-DD-<slug>.md`；
- 计划模板：`.agents/plans/TEMPLATE.md`；
- 示例：`.agents/plans/EXAMPLE-implementation.md`；
- 完成后可用 `project-plan-archive` skill 归档；
- 共享状态和结果仍回写 Issue provider，不在计划中复制运行日志。

## 最小结构

1. Goal
2. Scope and Non-Goals
3. Context and Decisions
4. Implementation Steps
5. Validation and Acceptance
6. Idempotence and Recovery
7. Outcomes and Follow-up

计划应落到真实文件、入口、命令和行为；不要只写抽象目标，也不要把计划写成一份全局规则手册。
