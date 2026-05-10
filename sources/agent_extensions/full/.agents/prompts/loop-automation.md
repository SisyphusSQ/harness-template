Mode: full

# Automation Loop Prompt

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 无人值守 / 自动化 loop 的规范页与 Prompt 模板 |
| 适用范围 | 需要围绕 root issue 自动推进一轮受控 harness loop 的场景 |
| 关联文档 | `.agents/prompts/issue-standard-workflow.md`、`.agents/prompts/loop-codex.md`、`AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agents/guides/code-review.md`、`.agents/PLANS.md` |

固定规则：

- 本文用于 automation，不替代仓库级控制面真相。
- 若本文与 `AGENTS.md`、`docs/harness/*`、`.agents/PLANS.md` 冲突，以后者为准。
- 当前 automation 语义优先围绕 `root_issue_type=master|execution` 设计。
- automation run 的结果面优先是 Linear，而不是本地 `state / runs`。

## 0.1 Optional Superpowers Skill Hooks

- automation 仍按本文的 `root_issue_type`、`mode`、drain 策略与结果面执行。
- `superpowers:subagent-driven-development` 只在任务相互独立、subagent 可用且 write scope 不冲突时考虑；否则使用当前 inline loop。
- `superpowers:executing-plans` 可用于按已冻结 plan 串行执行。
- `superpowers:verification-before-completion` 可用于任何完成、通过或可收口声明前。
- verify 失败或异常排查时，可考虑 `superpowers:systematic-debugging`，先定位根因再修。
- skill 输出必须回填到 `verification_summary`、`review_summary`、`writeback_summary`、`residual_risks`、`recovery_point`。

## 1. Root Issue 双入口

| `root_issue_type` | 作用 | 默认 loop |
| --- | --- | --- |
| `master` | 承载总体目标、Exit Criteria、inventory 与统一验收矩阵 | `master-loop` |
| `execution` | 承载单个最小可验证 slice | `solo-loop` |

固定规则：

1. `execution` 直启时，当前 loop 只围绕该 execution issue 推进。
2. `master` 启动时，必须先完成 `collect -> gate -> freeze`，再开始第一张 execution issue 的实现。
3. `master` 若采用自动 drain，必须先冻结完整初始 inventory。

## 2. 执行模式

| 模式 | 行为 |
| --- | --- |
| `propose-only` | 只做分析、冻结与下一步建议，不建卡、不实现 |
| `create-issues` | 冻结并创建 execution issue inventory，但不开始实现 |
| `implement-no-merge` | 推进到 verify / review / writeback / MR ready，但不进入 merge |
| `full-auto` | `master` 入口按 `serial-drain` 串行推进；`execution` 入口只围绕当前 slice 自动执行一轮 |

## 3. Drain 策略

| 策略 | 含义 | 默认适用场景 |
| --- | --- | --- |
| `single-batch` | 只推进当前一轮，不自动继续下一张 execution issue | `execution` 入口，或 `propose-only / create-issues / implement-no-merge` |
| `serial-drain` | 当前 slice 收口后，若 Master Exit Criteria 未满足，则自动回到 `collect` 继续下一张 | `master + full-auto` |

固定规则：

1. `full-auto` 处理 `master` 时，默认采用 `serial-drain`。
2. execution issue 的 `Stop When` 只负责停当前 slice，不负责结束整个 Master。
3. 只有 Master 自身的 Exit Criteria 满足，才允许把整个 Master 判定为完成。

## 4. Checkpoint 与停止规则

固定主流程：

`collect -> gate -> freeze -> slice -> implement -> verify -> review -> writeback -> mr_prep -> merge -> notify`

固定规则：

1. `verify / review / mr_prep / merge / escalation` 都是独立 checkpoint。
2. 当前 execution issue 若仍过大，必须先回 `freeze` 收窄或拆卡；拆卡完成前不继续编码。
3. review 出现 blocking finding 时，先修正，再重新执行 `verify -> review`。
4. 若自动 merge 条件不满足，应明确降级到 manual gate，而不是假装已自动收口。

## 5. 结果面

automation 至少要同步以下结果面：

- 当前执行结果 `result`
- 当前 stop_scope
- 当前 verification / review 摘要
- 当前 writeback 摘要
- 当前 residual_risks
- followups / next_action
- 当前 `recovery_point`

若是 `master` 场景，还必须说明：

- 当前 Master 状态
- 当前 inventory 是否已冻结
- 当前 slice 与下一张 execution issue

默认回写面：

- 优先写回 Linear
- 若仓库启用了 PR / MR，再同步代码叙事面
- 必要时再同步 repo 文档

## 6. 标准 Automation Prompt 模板

```text
你是当前仓库的无人值守 loop agent。你的职责是围绕 root issue，
用仓库内 harness 真相推进一轮受控 automation loop，并在不能安全自动化时明确降级。

运行参数：
- Root issue type: <ROOT_ISSUE_TYPE>
- Root issue: <ROOT_ISSUE>
- Run ID: <RUN_ID>
- Mode: <MODE>

你必须优先读取以下真相源：
- 根规则：AGENTS.md
- 工程控制面：docs/harness/control-plane.md、docs/harness/linear.md
- 计划协议：.agents/PLANS.md、.agents/plans/*
- Prompt 合同：.agents/prompts/*
- Review / Lint 说明：.agents/guides/*

固定主流程：
collect -> gate -> freeze -> slice -> implement -> verify -> review -> writeback -> mr_prep -> merge -> notify

执行硬约束：
1. root_issue_type=execution 时，默认进入 solo-loop，不要求先有 Master issue。
2. root_issue_type=master 时，必须先完成 collect -> gate -> freeze，并冻结完整初始 inventory。
3. full-auto 下的 master-loop 默认采用 serial-drain，一次只推进一张 execution issue。
4. verify / review / mr_prep / merge / escalation 都是独立 checkpoint。
5. 若当前 execution issue 仍过大，必须先回 freeze 收窄或拆卡。
6. 结果面至少同步当前 result、stop_scope、verification_summary、review_summary、writeback_summary、residual_risks、followups、recovery_point。
7. `merge` / `escalation` 结论默认由 agent 给出；无法安全自动化时，明确降级为 manual gate 或 plan-only，不要伪装成已闭环。
```

## 7. 使用建议

- 初次验证 automation prompt 时，先用 `propose-only` 或 `create-issues`
- 需要验证实现主流程但不想自动收尾时，用 `implement-no-merge`
- 只有在需要无人值守串行 drain 时，再对 `master` 使用 `full-auto`
