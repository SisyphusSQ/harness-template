# Prompt 目录说明

`.agents/prompts/` 存放 harness 的标准 prompt 文档与 loop contract。

固定规则：

- `.agents/prompts/issue-standard-workflow.md` 是标准 issue workflow 手册，负责高频 issue Prompt 模板。
- `.agents/prompts/orchestrator-thread.md` 是主 thread / 子 thread 编排的 Goal Prompt 与 Handoff Prompt 模板。
- `.agents/prompts/loop-codex.md` 是交互式主对话 loop contract。
- `.agents/prompts/loop-automation.md` 是无人值守 / 自动化 loop contract。
- `.agents/prompts/maintenance-loop.md` 是自治维护循环 prompt，默认 `report-only`，只在用户显式指定时进入 `issue-create / safe-fix / rule-promotion`。
- `Issue Tracker 是主协作真相`
- `repo 是主执行真相`
- 各文档共享同一套术语，不重复冻结第二套控制面真相。
- 若 prompt 与 `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agents/PLANS.md` 冲突，以后者为准。
- 若 `.agents/guides/code-review.md` 存在，review 口径先读它；若 `.agents/guides/linter.md` 存在，lint 决策与落地先读它。

## 文件分工

| 文件 | 负责什么 |
| --- | --- |
| `.agents/prompts/issue-standard-workflow.md` | 标准 issue workflow、常用 Prompt 模板、verify/review/mr_prep/收口模板 |
| `.agents/prompts/orchestrator-thread.md` | root goal / issue 下的主 thread、child thread、worktree thread、subagent 编排模板 |
| `.agents/prompts/loop-codex.md` | 交互式主对话里的短 loop contract |
| `.agents/prompts/loop-automation.md` | 自动化运行使用的规范页与 Prompt 模板 |
| `.agents/prompts/maintenance-loop.md` | docs / plans / runbooks / contracts / checks / writeback 漂移扫描、分类与维护输出 |

## Optional Superpowers Skill Hooks

如果当前 agent 环境提供 Superpowers skills，可把它们作为阶段辅助工具使用。固定边界：

- Superpowers 只辅助执行，不替代 `AGENTS.md`、`docs/harness/*`、`.agents/PLANS.md` 或 Issue Tracker truth。
- Superpowers 的 plan / spec 默认路径不作为本仓库真相；计划仍写入 `.agents/plans/`。
- skill 输出必须折回 `Verify Summary`、`Review Summary`、`Writeback Summary`、`Issue Tracker Actions` 或本仓库约定的结果面。
- 多 thread 编排时，subagent 只是短生命周期执行资源；主 thread / child thread / `write_lease` / `Current State` 语义以 `orchestrator-thread.md` 和 `docs/harness/issue-workflow.md` 为准。
- 若 Superpowers 不可用，按本仓库 harness prompt 与 guide 正常执行，不降级为失败。

| Harness 阶段 | 可考虑的 Superpowers skill | 适用条件 |
| --- | --- | --- |
| `collect / gate` | `superpowers:brainstorming` | 需求未冻结、需要先澄清设计或方案取舍 |
| `freeze / slice` | `superpowers:writing-plans` | 需要把已冻结范围写成实施计划；输出仍落 `.agents/plans/` |
| `implement` | `superpowers:test-driven-development` | 行为变更、bugfix 或重构，且能写自动化测试 |
| `implement` | `superpowers:subagent-driven-development` / `superpowers:executing-plans` | 任务独立且 subagent 可用时用前者；否则保持当前 inline loop |
| `verify` | `superpowers:verification-before-completion` | 声明完成、通过、可收口前需要新鲜验证证据 |
| `verify` 失败 / 异常排查 | `superpowers:systematic-debugging` | 测试、构建、联调或行为结果异常，先查根因再修 |
| `review` | `superpowers:requesting-code-review` | 重大改动、subagent 执行后或 merge 前需要独立 review |
| `pr_prep / merge` | `superpowers:finishing-a-development-branch` | 只辅助分支 / PR 收尾；merge 优先级仍服从本仓库规则 |

## 建议阅读顺序

1. `AGENTS.md`
2. `docs/harness/control-plane.md`
3. `docs/harness/linear.md`
4. `.agents/PLANS.md`
5. 本目录 `README.md`
6. 多 thread / worktree / subagent 编排先读 `orchestrator-thread.md`
7. 按需进入 `issue-standard-workflow.md`、`loop-codex.md`、`loop-automation.md` 或 `maintenance-loop.md`
