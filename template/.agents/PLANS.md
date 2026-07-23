# PLANS 协议

本文件只定义复杂任务何时写计划、最低质量和维护方式。计划实例放在 `.agents/plans/`；写计划时使用 `TEMPLATE.md`，需要质量参考时再读 `EXAMPLE-implementation.md`。

## 1. 何时必须写 plan

满足任一条件时先写或更新计划：

- 跨目录、模块或仓库
- 影响公开接口、contract、配置或兼容性
- 涉及 schema、migration、数据、安全、权限或不可逆副作用
- 涉及并发、幂等、重试、状态机、发布或回滚
- 需要多轮验证、中断恢复、并行交接或外部系统回写
- 改动面较多，无法用一个短步骤列表可靠表达

单文件小修、拼写修正和无行为影响的微调默认不要求计划；执行中复杂度上升时立即补计划。

## 2. 文件与生命周期

- 路径：`.agents/plans/YYYY-MM-DD-<slug>.md`
- 标题：`# ExecPlan: <任务名>`
- plan 是活文档：范围变化先更新 Scope，进度写入 Progress，决策写入 Decision Log，新发现写入 Surprises & Discoveries。
- 任务结束后补 Outcomes & Retrospective；共享状态和结果仍回写 Issue Tracker 或 `.agents/runs/`，不要在 plan 复制整套控制面。

## 3. 最小结构

计划至少包含：

1. `Goal`
2. `Scope and Non-Goals` / `Scope Freeze`
3. `Context and Orientation`
4. `Architecture / Data Flow`，或推荐标题 `0. 现有架构回顾与核心设计决策`
5. `Reference Snippets`
6. `Concrete Steps`
7. `Progress` / `Decision Log` / `Surprises & Discoveries`
8. `Validation and Acceptance`
9. `Idempotence and Recovery`
10. `Review Summary`
11. `Outcomes & Retrospective`

Review Summary 只保留 gate 需要的 `blocking_findings` 和必要说明；验证、writeback、optional delivery 与通知结果进入 Issue Tracker 或 run summary。

## 4. 实现骨架 contract

Architecture / Data Flow 必须写真实业务实现，不得只画 Harness 流程。至少包含：

### 真实入口与触发

写清调用者、`入口代码位置`、触发条件和上游依赖。

### 输入装配与边界校验

写清输入来源、装配位置、`装配结果 / 核心对象`、默认值和拒绝条件。

### 组件职责与代码落点

至少列出一条真实模块、文件或类型，说明关键产物、职责和明确不负责的内容。

### 关键执行时序

除 Mermaid 外必须给出`步骤化时序`，说明输入如何经过关键组件形成最终状态或产物。

### 停止 / 错误 / 恢复

写清正常停止、主要错误出口、至少一个`关键分支 / 降级路径`以及恢复、重试或回滚语义。

## 5. 条件内容

按任务复杂度补充，不作为所有计划的固定章节：

- 跨目录、多文件联动：File Map
- pipeline、batch、runner、orchestration：伪代码 / 主循环
- provider、多路径策略：关键分支与实现策略
- HA、并发、重试、状态机：竞态 / 状态机分析

## 6. Reference Snippets 与 Concrete Steps

- Reference Snippets 至少包含一个真实接口、结构、命令、配置、SQL 或 CLI 片段；只展示本次决策相关的最小形状。
- Concrete Steps 先写`实现步骤`，再写`验证与收口步骤`。
- 实现步骤必须能落到真实文件、类型或行为，不能只剩补测试、回写、review、merge。
- 验证项写可执行命令，并区分 deterministic-local、environment-dependent 与 live。

## 7. 写法约束

- 默认使用简体中文，优先清单、表格和约束式表达。
- Mermaid 只在重要关系明显更清楚时使用；图不能替代文字时序。
- 风险、依赖、未决项和范围外事项必须显式记录。
- 不写全系统百科，不堆大段源码，不把模板保留成空表单。
- 项目实现和验证事实优先，控制面状态只做链接或简短引用。
