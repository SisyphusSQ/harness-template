Mode: placeholder

# Automation Loop Prompt（占位）

## 用途

这份文件用于无人值守 / 自动化 loop 的说明与 Prompt 模板。

当前是占位文件，不代表仓库已经冻结完整 automation 语义。

## 当前仍缺的 repo-local 决策

- `root_issue_type` 和入口对象的唯一定位方式
- automation mode 集合
- drain 策略与 stop 条件
- 结果面字段与 writeback 目标
- 人工降级 / manual gate 条件
- 结果面是否默认优先写回 Linear
- goal-orchestration、write_lease、post-integration verify 的自动化边界

## 后续应补齐的主题

- `propose-only / create-issues / implement-no-merge / full-auto`
- `single-batch / serial-drain`
- verify / review / mr_prep / merge / escalation checkpoint
- stop-current-slice / stop-master
- automation 结果面与 follow-up 规则
- child thread handoff、waiting_on_child 与 `【完成】` 标题标识

## 临时占位模板骨架

```text
你是当前仓库的无人值守 loop agent。
围绕 <ROOT_ISSUE> 推进一轮 automation loop。

运行参数：
- Root issue type: <ROOT_ISSUE_TYPE>
- Root issue: <ROOT_ISSUE>
- Run ID: <RUN_ID>
- Mode: <MODE>

Repo-local TODO:
1. 读取哪些工程控制面真相
2. automation mode 的固定语义
3. 停止与降级规则
4. 结果面最少要写到哪些载体
```

## 使用约束

- 先读取 `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agents/PLANS.md`
- 若是交互式主对话，不要直接拿本文件替代 `.agents/prompts/loop-codex.md`
- 若涉及多 thread / worktree / subagent 编排，先读 `.agents/prompts/orchestrator-thread.md`
- 补齐后默认应把 automation 结果面优先写回 Linear
- 补齐后默认由 agent 给出 `merge / escalation` 结论
- 若 Superpowers skills 可用，只能参考 `.agents/prompts/README.md` 的 Optional Superpowers Skill Hooks；当前占位文件不冻结完整 automation skill hook contract
- 补齐前不要把这里的占位语义当作完整 automation contract
