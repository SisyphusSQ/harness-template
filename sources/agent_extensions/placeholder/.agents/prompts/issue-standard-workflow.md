Mode: placeholder

# Issue 标准执行工作流 Prompt（占位）

## 用途

这份文件用于承载：

- 单张 issue 的标准执行流程
- 高频 Prompt 模板
- verify / review / mr_prep / 收口的最小话术入口
- 多 thread 编排时跳转 `.agents/prompts/orchestrator-thread.md`

当前是占位文件，不代表仓库已经冻结完整 issue workflow contract。

即使当前仍是占位版，凡是进入 plan-only 输出或执行计划编写，仍必须遵守
`.agents/PLANS.md` 的计划骨架，尤其是：

- `Architecture / Data Flow` 下的：
  - `真实入口与触发`
  - `输入装配与边界校验`
  - `组件职责与代码落点`
  - `关键执行时序`
  - `停止 / 错误 / 恢复`
- `Concrete Steps` 先写 `### 实现步骤`，再写 `### 验证与收口步骤`

反模式：

- 不要用 harness 控制流图替代业务实现图
- 不要把 Concrete Steps 写成纯控制面收口步骤

## 当前仍缺的 repo-local 决策

- issue 平台与状态流转口径
- 默认分支策略与是否自动建分支
- verify / review / mr_prep / merge 的仓库级命令
- 结果面默认回写到 Linear 还是其他系统
- ChangeLog / 文档同步是否为必选项
- 是否启用 `goal-orchestration`、`write_lease` 和 Codex thread tools

## 后续应补齐的模板

- 启动一张卡
- 开发前准备
- 只生成执行计划
- 开始开发
- Verify Gate
- Review Gate
- Review 后修正
- 开发后准备 PR / MR
- 处理 PR Review / CI
- 合并后收尾
- Master 是否可 Done / 收口检查
- root goal / child thread / worktree thread handoff

## 临时占位模板骨架

### 启动一张卡

```text
执行 <ISSUE-ID>。
先基于当前仓库、当前 issue、相关文档与计划判断这张卡处于什么阶段，
再决定进入 plan-only、implement、verify/review，还是 closeout。
Repo-local TODO: issue 状态、默认分支、回写位置。
```

### 开发前准备

```text
执行 <ISSUE-ID>，先分析并冻结范围，生成执行计划；
本轮只做开发前准备，不开始开发。
Repo-local TODO: 是否需要自动建分支、是否需要写回 issue 状态。
输出的 plan 仍要按 `.agents/PLANS.md` 补齐 `真实入口与触发 / 输入装配与边界校验 / 组件职责与代码落点 / 关键执行时序 / 停止 / 错误 / 恢复`。
```

### 开始开发

```text
按已冻结范围执行 <ISSUE-ID>，基于当前 issue 分支开始开发实现。
Repo-local TODO: verify / review / mr_prep 的最小命令矩阵。
```

### Review Gate

```text
针对 <ISSUE-ID> 当前分支执行 findings-first review。
Repo-local TODO: blocking finding 定义与 Review Summary 字段。
```

### 合并后收尾

```text
针对 <ISSUE-ID> 做最终收口检查。
Repo-local TODO: 合并动作、Linear/Issue writeback、ChangeLog 规则。
```

## 使用约束

- 先读取 `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agents/PLANS.md`
- 若存在 `.agents/guides/code-review.md`，先按其中的 review 口径执行
- 默认把阶段反馈、收口结果、`recovery_point`、`next_action` 写回 Linear
- 多 thread / worktree / subagent 编排先读 `.agents/prompts/orchestrator-thread.md`
- 可写 child thread 必须有 `write_lease`；子 thread 不默认归档，完成后标题加 `【完成】`
- plan-only 输出即使来自占位 prompt，也不能退化成纯 harness 流程；仍要按 `.agents/PLANS.md` 写清实现逻辑骨架
- 若 Superpowers skills 可用，只能参考 `.agents/prompts/README.md` 的 Optional Superpowers Skill Hooks；当前占位文件不冻结完整 skill hook contract
- 当前文件只是占位 skeleton，补齐前不要把它当成可直接执行的完整仓库 contract
