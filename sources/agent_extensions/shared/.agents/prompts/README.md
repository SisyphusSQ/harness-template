# Prompt 目录说明

本目录只保留两类需要人工复制或显式调用的 Prompt。

| 文件 | 使用场景 |
| --- | --- |
| `issue-standard-workflow.md` | 希望手动按阶段推进 Issue：准备、实现、验证、review、PR / MR 与收尾 |
| `orchestrator-thread.md` | 创建独立任务、主子任务交接、并行写入和结果集成 |

使用顺序：

1. 先读根目录 `AGENTS.md`。
2. 控制面问题读 `docs/harness/control-plane.md`。
3. 复杂任务按 `.agents/PLANS.md` 写计划。
4. 只有需要可复制话术时才进入本目录。

固定边界：

- 本目录不是控制面真相源。
- 与 `AGENTS.md`、`docs/harness/control-plane.md` 或 `.agents/PLANS.md` 冲突时，以这些文件为准。
- 日常自然语言协作不需要额外的 loop prompt。
- 自动化的锁、输入、输出、数据质量和写入规则跟随具体 automation 或项目 runbook，不在这里维护通用模板。
- 项目维护任务跟随对应 skill / runbook，不在这里维护自治 maintenance loop。
- Review 与 lint 分别使用 `.agents/guides/code-review.md` 和 `.agents/guides/linter.md`（如存在）。
