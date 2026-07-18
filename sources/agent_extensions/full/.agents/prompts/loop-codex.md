Mode: full

# 交互式 Loop Prompt Contract

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 主对话 / 交互式 harness loop 的可执行 prompt contract |
| 适用范围 | 围绕 execution issue 或 master issue 做 collect / gate / freeze / implement / closeout |
| 关联文档 | `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agents/PLANS.md`、`.agents/prompts/orchestrator-thread.md`、`.agents/prompts/issue-standard-workflow.md`、`.agents/prompts/loop-automation.md`、`.agents/guides/code-review.md` |

固定规则：

- 本文负责交互式主对话入口，不替代 automation contract。
- 需要无人值守、定时运行或 serial drain 时，应改读 `loop-automation.md`。
- 需要完整 issue 级模板时，优先跳到 `issue-standard-workflow.md`。
- 当前状态、`recovery_point`、`next_action` 默认落 Issue Tracker；本地 `.agents/state` / `.agents/runs` 只补充恢复细节。
- 外部工具、目录、知识库、接口平台和配置中心统一称为 `External System`；每轮必须先读外部当前真相，再写入或验收。
- 多 thread / worktree / subagent 编排先读 `.agents/prompts/orchestrator-thread.md`；Codex thread tools 不可用时降级为人工 handoff。
- 子 thread 不默认归档；完成后标题加 `【完成】`，该标识不替代 Issue Tracker 状态。

## 1. 术语

| 术语 | 定义 |
| --- | --- |
| `execution issue` | 单张最小可验证 slice，必须能独立 verify / review / closeout |
| `master issue` | 承载总体目标、Exit Criteria、inventory 和最终验收矩阵的上层容器 |
| `solo-loop` | 围绕单张 execution issue 推进一轮 |
| `plan-only loop` | 只做现状探索、范围冻结、拆卡建议和计划，不进入实现 |
| `master-loop` | 围绕 master 先冻结 inventory，再逐张推进 execution issue |
| `goal-orchestration` | root goal 由主 thread 拆解、下发、回收和集成多个 child threads / Master / Execution units |
| `write_lease` | 主 thread 授权可写 thread 的写入范围、分支、worktree、阶段和集成 owner |
| `serial-drain` | 当前 slice 收口后，回到 master 检查下一张 slice，直到 Exit Criteria 满足 |
| `waiting_on_child` | 长任务中主 thread 停在可恢复等待点，而不是空等或重复做子 thread 的 scope |
| `stop_scope` | 当前停止点：`needs-plan`、`blocked`、`waiting-on-child`、`ready-for-implement`、`ready-for-review`、`ready-for-integration`、`ready-for-merge`、`done` |

## 2. 固定主流程

交互式 loop 默认遵循：

```text
collect -> gate -> freeze -> slice -> dispatch -> implement -> verify -> review -> integrate -> verify -> writeback -> mr_prep -> merge -> closeout
```

阶段要求：

| 阶段 | 必须完成 | 不允许 |
| --- | --- | --- |
| `collect` | 读取 issue、repo docs、计划、代码和外部系统当前真相 | 只看标题就实现 |
| `gate` | 判断是否过大、依赖是否清楚、权限和环境是否可用 | 遇到缺口仍硬做 |
| `freeze` | 冻结 Included / Excluded / Acceptance Matrix / Write Scope Limit | 边做边扩大范围 |
| `slice` | 选定当前单张 execution issue 或当前实现切片 | 同时打开互相影响的多张卡 |
| `dispatch` | 派发 subagent / child thread / worktree thread，并登记 `write_lease` | 无 lease 派发可写任务 |
| `implement` | 按冻结范围修改代码、文档、计划和配置 | 重构无关区域 |
| `verify` | 执行者或 test thread 跑局部验证并记录结果 | 未验证就进入 review |
| `review` | findings-first 输出 review 结论 | verify 失败仍进入 review |
| `integrate` | 主 thread 检查 lease、diff、review、verify 后集成子 thread 输出 | 子 thread 自行 merge 或 closeout |
| `verify` | 主 thread 在集成后的 repo truth 上执行最终验证矩阵 | 只引用子 thread 验证就 Done |
| `writeback` | 回写 Issue Tracker、PR/MR 或 repo 文档摘要 | 只在聊天里说完成 |
| `mr_prep / merge` | 准备或执行 provider 原生命令收口 | 用网页替代可安全执行的 git/provider 命令 |
| `closeout` | 确认主分支、issue 状态、残余风险和下一步 | 合并后不回读状态 |

## 3. 交互式入口模板

### 3.1 直启单张 execution issue

```text
执行 <ISSUE-ID>。
先读取当前仓库规则、相关 docs/harness 文档、.agents/PLANS.md、已有计划和 issue 当前状态。
判断这张卡适合直接进入 solo-loop，还是必须先降级为 plan-only loop。

输出：
- 当前阶段
- 已确认事实
- 缺口 / blocker
- 建议 loop 类型
- next_action
```

### 3.2 只做 plan-only loop

```text
围绕 <ISSUE-ID> 执行 plan-only loop，本轮不修改代码、不写外部系统。

必须输出：
1. repo truth 摘要
2. issue truth 摘要
3. Included / Excluded
4. Acceptance Matrix
5. Write Scope Limit
6. 需要新增或更新的 .agents/plans 路径
7. 若范围过大，给出拆卡建议和第一张可执行 slice
8. stop_scope 与 next_action
```

### 3.3 按已冻结计划实现

```text
按已冻结范围执行 <ISSUE-ID>。
Plan: <PLAN-PATH>
Additional constraints: <CONSTRAINTS>

执行要求：
1. 先确认计划仍匹配当前代码、文档和 issue 状态。
2. 严格按计划实施，不新增范围。
3. 若发现 blocker、依赖未满足或计划与现实冲突，立即停止并回写 plan/update。
4. 实现后按计划验证，再进入 review。
5. 输出实现摘要、验证结果、review 状态、writeback 状态和 residual_risks。
```

### 3.4 启动 master-loop

```text
围绕 <MASTER-ISSUE> 启动 master-loop。
先读取 master 的 Goal、Exit Criteria、当前 inventory、已有 execution issue 和相关 docs。

必须先完成：
1. collect：master / repo / external truth
2. gate：依赖、权限、环境和范围风险
3. freeze：完整初始 execution issue inventory
4. slice：当前第一张 execution issue

本轮默认只推进当前 slice，不并行打开第二张卡。
输出 master_status、inventory_status、current_slice、stop_scope、next_action。
```

### 3.5 Master 继续下一张 slice

```text
围绕 <MASTER-ISSUE> 继续 master-loop。
先判断 Master Exit Criteria 是否已满足。

若未满足：
- 找出下一张未完成 execution issue
- 若没有可执行卡，先补拆卡建议，不直接创造实现范围
- 进入下一张卡的 collect / gate / freeze

输出：
- 当前 Master 状态
- 已完成 / 未完成 inventory
- 下一张 execution issue
- 是否存在 blocker
- next_action
```

### 3.6 Master 最终 closeout

```text
围绕 <MASTER-ISSUE> 做最终 closeout。
只在所有 execution issue Done、验证摘要齐全、文档同步完成、主分支回读确认后，才建议 Master Done。

输出：
- Exit Criteria 对照表
- execution issue 完成矩阵
- 验证摘要
- 文档 / 外部系统同步摘要
- residual_risks
- Done / Not Done 结论
```

### 3.7 启动 goal orchestration

```text
围绕 <ROOT-GOAL 或 ROOT-ISSUE> 启动 goal-orchestration。
先读取 Issue Tracker、repo docs、active plan、已有 thread / branch / run 状态。
如果需要多 thread / worktree / subagent 编排，先读 `.agents/prompts/orchestrator-thread.md` 并生成主 thread Goal Prompt。

必须输出：
- root_goal
- orchestration_mode
- goal_state
- goal_unit_roster
- active_master_issue / active_execution_issue
- child thread / subagent dispatch 建议
- write_lease 表
- waiting_on / next_check / recovery_point / next_action
```

### 3.8 子 thread ready 后集成

```text
围绕 <ISSUE-ID> 集成子 thread 输出。
先读取子 thread 的 Thread Status comment、branch/worktree、write_lease 和验证摘要。
检查 diff 是否落在 write_scope 且未触碰 excluded_scope。
review 通过后进入 integrate；集成后必须重新执行 post-integration verify。
若 required live E2E 未执行，停止在 blocked / manual-gate，不得标记 verified / done。
```

## 4. 外部系统交互约束

适用于接口平台、文档平台、知识库、配置中心、监控平台、工单平台、CI/CD、Issue Tracker 以外的 provider。

固定顺序：

```text
repo truth -> external current truth -> diff -> update/create -> readback verify -> writeback summary
```

固定边界：

- 默认不删除外部条目、不重构目录、不做整包导入。
- 写入前必须读取目标载体当前详情。
- 写入后必须回读验收关键字段。
- 外部系统不可用时，降级为 plan-only 或 manual gate，不伪装已同步。
- 外部工具名称、空间、目录、稳定键和副作用范围必须写入计划或结果摘要。

## 5. 使用建议

- issue 级高频 prompt 直接读 `issue-standard-workflow.md`。
- 多 thread / worktree / subagent 编排读 `orchestrator-thread.md`。
- 自动推进、run id、drain 策略等语义读 `loop-automation.md`。
- review 前默认读 `.agents/guides/code-review.md`。
- lint 或机械规则接入前默认读 `.agents/guides/linter.md` 和 `docs/harness/project-constraints.md`。

## 6. 自适应 Review / Evidence Loop

- gate / freeze 先写入 `review_policy` 与 `subagent_review_required`。普通单仓低风险任务可显式使用 standard 对抗式自审；strict 必须由 subagent 独立评审，旧调用未提供 policy 时按 strict。
- strict 覆盖多仓 / 多 lease / 集成、安全与公开 contract、schema / 数据、并发 / 幂等 / 重试 / 业务状态机、release / 生产 / 不可逆副作用、required live E2E、full-auto、自动 merge和未知风险。
- verify 成功后记录 `evidence_id`、有序命令、`execution_session_id` 和验证类型。
- post-integration verify 仍必须进入；只允许同一执行 session、同一快照、同一命令顺序、单仓单写入者的 deterministic-local 结果复用。
- strict、环境依赖、live、多仓、多 lease、发生 integration event 或尚有 required live E2E 时必须重跑。
