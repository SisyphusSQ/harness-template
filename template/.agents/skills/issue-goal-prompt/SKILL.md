---
name: issue-goal-prompt
description: 从任务系统条目生成可执行目标提示词，适用于 harness 管理的仓库。当用户要求把任务编号、任务链接、仓库内任务文件、设计文档或测试手册转换成具体实施交接提示词，或需要生成 .agents/state/GOAL-* 长提示词恢复文件时使用；尤其适用于实施前必须编码计划优先、分支门禁、独立评审、live E2E 策略和任务系统回写要求的场景。
---

# 任务目标提示词

为任务生成具体目标提示词。除非用户明确要求继续实施，否则只生成提示词，不执行任务实现。

## 必要输入

- `issue_id`、任务链接或仓库内任务文件路径。
- 可选约束：执行模式、范围限制、来源文档、live E2E 策略、分支 / 提交 / 推送边界、多仓范围。

如果没有任务标识或来源文档，先询问用户。否则从当前仓库和已配置的任务系统中自行发现细节。

## 真相来源

生成提示词前先读取或检查：

1. `AGENTS.md`
2. `docs/harness/control-plane.md`
3. `docs/harness/issue-workflow.md`
4. 当前启用的任务系统配置说明，例如 `issue-provider=linear` 时读取 `docs/harness/linear.md`
5. `.agents/PLANS.md`
6. `.agents/plans/TEMPLATE.md`
7. `.agents/prompts/issue-standard-workflow.md`（如存在）
8. `.agents/prompts/orchestrator-thread.md`（需要多线程、worktree 或 subagent 编排且文件存在时）
9. `.agents/guides/code-review.md`（如存在）
10. 任务正文、评论、标签 / 状态和链接的来源文档
11. 任务或用户点名的来源文档

如果真相来源冲突，协作状态以任务系统为准，执行约束以仓库文档和代码为准。未能自行消解的冲突必须写进生成的提示词。

## 生成流程

基于当前真相生成目标提示词，不只依赖记忆：

1. 提取目标、包含范围、排除范围、验收矩阵、来源文档、验证命令、停止条件、依赖 / 阻塞。
2. 要求实施前先冻结范围。
3. 要求复杂任务创建或更新 `.agents/plans/YYYY-MM-DD-<issue>-<slug>.md`，并遵循 `.agents/plans/TEMPLATE.md`。
4. 要求每个会写入的仓库先通过分支门禁：
   - 执行 `git status --short --branch`。
   - 除非用户明确允许默认分支工作，否则创建或切换到专用功能分支。
   - 分支名只允许 ASCII 字母、数字、`-`、`_` 和 `/`。
   - 保护已有脏工作区；不得丢弃或覆盖无关改动。
   - 在计划、恢复点和最终回写中记录实际分支名。
5. 要求验证后执行独立评审：
   - 可用时优先使用 subagent 评审。
   - 对实现任务，主 agent 自审不能单独满足默认评审门禁。
   - 如果必需的 subagent 评审不可用，停止在 `blocked: subagent_review_unavailable`。
6. 编码 live E2E 策略：
   - 默认目标是 `pre-commit ready`。
   - 除非用户明确要求，不要 commit、push、merge 或 mark Done。
   - 如果 live E2E 必需但当前不可用，在本地验证后停止在 `manual_gate_live_e2e`。
   - 如果 live E2E 不适用，设置 `live_e2e_status: not_required`。
7. 加入任务系统回写要求：验证、评审、集成、集成后验证、live E2E 状态、残余风险、恢复点和下一步。

完整提示词、状态文件和短启动提示词模板见 `references/goal-prompt-template.md`。

## 状态文件规则

组装提示词后统计字符数。

- 如果提示词 `<= 4000` 字符，直接返回完整提示词。
- 如果提示词 `> 4000` 字符，把完整提示词写入 `.agents/state/GOAL-<ISSUE-ID>.md`，返回时把路径解析成绝对路径。
- 如果状态文件已经存在，先读取旧文件，保留仍然有效的恢复字段，替换或更新 `## 目标提示词`，并更新 `updated_at`、`prompt_length`、`recovery_point` 和 `next_action`。

默认 harness 的 `.gitignore` 会把真实 `.agents/state/*` 文件当成本地辅助状态。如果用户要求提交生成的 `GOAL` 文件，必须先确认项目有意跟踪该状态文件，或带明确理由更新项目级忽略规则。

短启动提示词必须说明：先完整读取状态文件，只执行其中 `## 目标提示词`，不要只根据短启动提示词开始实现；如果状态文件、任务系统和仓库真相冲突，先基于任务系统和仓库真相重新消解。

## 输出规则

- 只输出生成的完整目标提示词或短启动提示词；如果写入了状态文件，可以额外输出一行说明。
- 在短启动提示词中使用绝对路径。
- 不包含隐藏推理。
- 只生成提示词时，不实施、不提交、不推送、不合并，也不修改任务系统状态；除非用户明确要求这些副作用。
