# 目标提示词模板

最终提示词必须足够具体，让另一个 agent 不依赖原始聊天也能执行。

## 完整目标提示词

```text
执行 <ISSUE-ID>：<ISSUE-TITLE>。

工作仓库：
- 主仓库：<绝对路径>
- 相关仓库：<绝对路径或无>

当前信息：
- issue_provider: <linear|github|gitlab|repo|other>
- mode: <propose-only|plan-only|implement-no-merge|full-auto>
- 当前分支：<branch>
- 现有工作区改动：<摘要>

目标：
<目标>

成功标准：
- <标准 1>
- <标准 2>

必须先读取：
- <绝对路径>/AGENTS.md
- <绝对路径>/.agents/PLANS.md（如任务复杂）
- <相关计划、Issue 和来源文档>

范围：
包含：
- <包含项>

排除：
- <排除项>

实现要求：
1. <真实文件、入口或行为>
2. <输入、边界和错误处理>
3. <恢复或回滚方式>

验证要求：
1. <命令>：<预期结果>
2. <命令>：<预期结果>

停止条件：
- <冲突、缺授权、依赖缺失或不安全状态>

最终回传：
- 改动文件
- 验证命令和真实结果
- 未执行项
- 残余风险
- recovery_point
- next_action
```

## 状态文件模板

```text
# GOAL-<ISSUE-ID>

- issue_provider: <linear|github|gitlab|repo|other>
- issue_id: <ISSUE-ID>
- updated_at: <ISO-8601>
- recovery_point: <安全恢复点>
- next_action: <一个具体动作>

## 目标提示词

<完整目标提示词>
```

## 短启动提示词

```text
先完整读取 <绝对路径>/.agents/state/GOAL-<ISSUE-ID>.md，只执行其中“目标提示词”部分。
如果状态文件、Issue 和仓库真相冲突，先基于当前真相重新消解，再开始工作。
```
