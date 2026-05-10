Mode: placeholder

# 交互式 Loop Prompt（占位）

## 用途

这份文件用于主对话里的 loop contract，包括：

- solo-loop 入口
- plan-only loop 入口
- master-loop 的交互式启动与续做入口

当前是占位文件，不代表仓库已经冻结完整交互式 loop 语义。

## 当前仍缺的 repo-local 决策

- `root_issue_type` 是否固定采用 `master|execution`
- loop 的最小状态机与 stop 条件
- 当前仓库的结果面字段与 writeback 约束
- 交互式 loop 与自动化 loop 的边界
- `recovery_point` / `next_action` 是否默认落 Linear

## 临时占位模板骨架

### 直启单张 issue

```text
执行 <ISSUE-ID>。
先判断当前卡适合 solo-loop 还是 plan-only loop。
Repo-local TODO: issue 边界判定、当前 loop 输出结构。
```

### plan-only loop

```text
围绕 <ISSUE-ID> 执行 plan-only loop。
本轮只做范围分析、冻结和计划，不开始开发。
Repo-local TODO: plan 结构、Issue writeback 要求。
```

### 启动 master-loop

```text
围绕 <MASTER-ISSUE> 启动 master-loop。
先完成 collect -> gate -> freeze，再决定当前 slice。
Repo-local TODO: inventory 结构、下一张 execution issue 选择规则。
```

## 使用约束

- 当前文件只服务交互式主对话
- 若是无人值守 / 自动化场景，应优先补齐 `.agents/prompts/loop-automation.md`
- 补齐后默认应把当前状态、`recovery_point`、`next_action` 写回 Linear
- 补齐前不要把这里的占位语义当作完整 loop contract
