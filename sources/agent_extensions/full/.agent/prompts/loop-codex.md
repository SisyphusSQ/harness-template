Mode: full

# 交互式 Loop Prompt Contract

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 主对话 / 交互式 harness loop 的短 contract |
| 适用范围 | 当前会话里围绕 issue 或 master 做 collect / gate / freeze / implement / closeout |
| 关联文档 | `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agent/prompts/issue-standard-workflow.md`、`.agent/prompts/loop-automation.md`、`.agent/PLANS.md` |

固定规则：

- 本文只负责交互式主对话，不替代 automation contract。
- 需要无人值守 / 定时运行时，应改读 `loop-automation.md`。
- 若当前 loop 需要详细 issue 级模板，优先跳到 `issue-standard-workflow.md`。
- 当前状态、`recovery_point`、`next_action` 默认落 Linear，而不是本地 `state / runs`。

## 1. 术语

| 术语 | 定义 |
| --- | --- |
| `execution` | 单张最小可验证 slice |
| `master` | 承载总体目标、Exit Criteria 和 inventory 的上层容器 |
| `solo-loop` | 围绕单张 execution issue 推进一轮 |
| `plan-only loop` | 只做分析、冻结和计划，不进入实现 |
| `master-loop` | 围绕 Master 先冻结 inventory，再逐张推进 |

## 2. 固定约束

1. 交互式 loop 先探索、再冻结、后实现。
2. 当前对象若仍过大，先回到 plan-only，不继续编码。
3. `verify / review / mr_prep` 仍然是独立 checkpoint。
4. 交互式 loop 的结果面最少要说明：当前范围、当前 stop_scope、下一步动作。
5. 交互式 loop 的运行反馈默认回写到 Linear。

## 3. 常用 Prompt 模板

### 3.1 直启单张 execution issue

```text
执行 <ISSUE-ID>。
先判断当前卡是适合直接进入 solo-loop，还是应先降级为 plan-only loop。
若信息不足，优先先做范围分析和计划准备，不直接扩大范围。
```

### 3.2 围绕 execution issue 做 plan-only loop

```text
围绕 <ISSUE-ID> 执行 plan-only loop。
本轮目标不是开发，而是输出：
1. 当前范围分析
2. 已确认事实
3. 待确认项
4. 拆卡建议
5. 推荐的下一步执行顺序
```

### 3.3 启动 master-loop

```text
围绕 <MASTER-ISSUE> 启动 master-loop。
先完成 collect -> gate -> freeze，
冻结本轮 execution issue inventory，并明确当前第一张 slice；
本轮默认只推进当前 slice，不直接并行打开第二张卡。
```

### 3.4 Master 未完成，继续下一张 slice

```text
围绕 <MASTER-ISSUE> 继续 master-loop。
先判断当前 Master 是否已满足 Exit Criteria；
若未满足，则进入下一张 execution issue 的 collect / gate / freeze。
输出：
- 当前 Master 状态
- 当前 stop_scope
- 下一张 execution issue
- 若没有下一张，是否需要先补拆卡
```

### 3.5 Master 完成收口

```text
围绕 <MASTER-ISSUE> 做最终收口检查。
先核对 Exit Criteria、当前 execution issue 完成情况、验证摘要与文档同步状态；
若已满足闭环条件，再给出 Done 建议；
若未满足，明确剩余 issue 与下一步动作。
```

## 4. 使用建议

- issue 级高频 Prompt 直接去 `issue-standard-workflow.md`
- 自动推进、无人值守、run id、drain 策略等语义去 `loop-automation.md`
- 当前文件适合主对话里快速进入 loop，而不是承载完整 issue 模板全集
