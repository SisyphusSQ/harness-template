# PLANS 协议

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 复杂任务的计划协议 |
| 适用范围 | 跨模块、带风险、需多轮验证、需中断恢复的任务 |
| 计划实例位置 | `.agents/plans/` |
| 关联文档 | `docs/harness/control-plane.md`、`docs/harness/issue-workflow.md`、`docs/harness/linear.md`、`.agents/prompts/README.md`（如存在） |

本文件只定义“什么时候要写 plan、plan 怎么写、执行中怎么维护”。
具体计划实例统一写入 `.agents/plans/`，不再新增第二套计划目录。

## 1. 何时必须写 plan

满足任一条件时，默认先写或更新 plan，再进入实施：

| 场景 | 说明 |
| --- | --- |
| 跨目录或跨模块边界 | 例如同时改代码、文档、配置、 Prompt 或 Issue Workflow 约束 |
| 涉及配置、接口、兼容性 | 会影响外部输入输出或运行边界 |
| 涉及 schema / migration / 数据变更 | 需要提前写清恢复路径与验收口径 |
| 涉及鉴权、权限、风控、命令消费 | 这类任务天然有较高回归风险 |
| 涉及发布、兼容性、回滚策略 | 需要提前写清失败恢复方式 |
| 预计改动文件较多 | 需要明确分步实施和验证顺序 |
| 预计需要多轮验证 | 例如联调、构建、回归、CI 修复 |
| 属于迁移、升级、重构类任务 | 需要持续记录发现与决策 |
| 存在中断、交接、续做可能 | 需要显式记录 `recovery_point` 与 `next_action` |
| 涉及外部副作用 | 需要提前冻结边界和回写方式 |
| 涉及 maintenance loop 跨文件修复或外部系统回写 | 需要写清 findings、修复边界、验证和 writeback |
| 涉及 `rule-promotion` 或项目级约束升级 | 需要写清 evidence、`Rule ID`、命令、回归验证和回滚方式 |

默认可不写 plan 的任务：

- 单文件小修复
- 明确的拼写或文档错字修正
- 无架构影响的微小样式或占位文案调整

若判断错误，执行中一旦发现复杂度上升，应立即补 plan。

## 2. 计划文件位置与命名

| 项目 | 规则 |
| --- | --- |
| 存放位置 | `.agents/plans/` |
| 命名格式 | `YYYY-MM-DD-<slug>.md` |
| 标题格式 | `# ExecPlan: <任务名>` |
| 真相来源 | 协议真相看本文件，计划实例真相看 `.agents/plans/` |

固定规则：

- 计划协议写在 `.agents/PLANS.md`
- 计划实例写在 `.agents/plans/`
- 不新增第二套计划目录
- 历史计划不做平行迁移

## 3. 计划文档最小结构

每份复杂任务计划至少应包含以下结构块：

- `Goal`
- `Scope and Non-Goals`
- `Scope Freeze`
- `Context and Orientation`
- `Architecture / Data Flow`
  说明：可继续使用兼容标题 `## Architecture / Data Flow`，也可使用推荐标题 `## 0. 现有架构回顾与核心设计决策` 承载同一实现骨架 contract
- `Concrete Steps`
- `Progress`
- `Decision Log`
- `Surprises & Discoveries`
- `Reference Snippets`
- `Validation and Acceptance`
- `Idempotence and Recovery`
- `Harness Control Plane`
- `Issue Actions`
- `Verify Summary`
- `Review Summary`
- `Writeback Summary`
- `PR Prep Summary`
- `Outcomes & Notify Summary`
- `Outcomes & Retrospective`

固定规则：

- 若任务进入完整控制面 loop，不得省略 `Harness Control Plane / Issue Actions / Summary` 系列结构块
- 若任务仍在 plan-only 阶段，可先写最小可执行版本，但不能省略范围冻结和验证方式
- `Architecture / Data Flow` 默认至少拆成以下 5 个实现子块：
  - `### 真实入口与触发`
  - `### 输入装配与边界校验`
  - `### 组件职责与代码落点`
  - `### 关键执行时序`
  - `### 停止 / 错误 / 恢复`
- `Concrete Steps` 默认拆成 `### 实现步骤` 与 `### 验证与收口步骤`，且实现步骤必须先于验证与收口步骤出现

## 3.1 技术实现型任务推荐写法

当任务的重点是设计实现方案、拆清改动面、让另一个工程师或 agent 可直接实施时，推荐按以下顺序写：

1. 可选 frontmatter
2. `Goal / Scope / Scope Freeze / Context and Orientation`
3. `## 0. 现有架构回顾与核心设计决策`
4. 一个或多个 `## 1. <改动面> -- <本次变更>`、`## 2. ...`
5. `## 数据流可视化`
6. `## 关键设计决策摘要`
7. `## 与现有代码的关系`
8. `Reference Snippets / Concrete Steps / Validation and Acceptance`
9. `Progress / Verify Summary / Review Summary / Writeback Summary / Outcomes`

frontmatter 推荐但不强制，固定字段如下：

```yaml
name: <任务名>
overview: <一句话概述本次交付物>
todos:
  - id: <todo-id>
    content: <todo 内容>
    status: pending
isProject: false
```

固定规则：

- frontmatter 只是推荐增强，不作为 lint 阻塞项
- 主体优先写“实现如何落地”，控制面摘要统一留在尾部
- 推荐用“按改动面展开”的结构讲清每个模块、接口、数据流和风险
- `Architecture / Data Flow` 的业务实现 contract 不变，只是推荐用更贴近实施方案的章节顺序承载
- `.agents/plans/EXAMPLE-implementation.md` 是官方示范文件，用来对齐质量和叙事密度，不替代模板

## 4. 写法约束

- 全文统一使用简体中文
- 优先表格、清单、约束式表达，少写大段散文
- 验证项必须写成可执行命令，不写“补测试”这种空描述
- 风险、未决项、依赖前提必须显式写出
- 代码示例只展示目标形状，不粘贴大段实现
- 若当前信息不足，可先写最小可执行计划，但不能省略关键栏位
- `Architecture / Data Flow` 不能只剩一张 Mermaid 图或只写 harness 阶段名，必须把真实入口、输入装配、组件职责、关键时序、停止 / 错误 / 恢复补成文字
- `Reference Snippets` 不能是空块，也不能只保留占位说明
- `组件职责与代码落点` 不能只剩表头或空话，至少要有一条真实模块 / 路径 / 类型记录
- 可以保留少量占位词作为模板提示，但不要整篇 plan 都写成 `<请替换为真实...>` 形式的空表单

## 4.1 内容标准

`L1 强约束`：默认所有复杂任务都必须写清

- `真实入口与触发` 必须回答：
  - 谁调用
  - 入口代码位置
  - 前置条件
- `输入装配与边界校验` 必须回答：
  - 输入来源
  - 装配位置
  - 装配结果 / 核心对象
  - 直接拒绝条件
- `组件职责与代码落点` 必须回答：
  - 改哪些包 / 文件 / 类型
  - 各自产出什么
  - 明确不负责什么
- `关键执行时序` 必须包含 Mermaid 之外的 `步骤化时序` 文字链路
- `停止 / 错误 / 恢复` 必须包含：
  - 正常停止条件
  - 主要错误出口
  - 至少一个关键分支 / 降级路径
  - 恢复 / 重试语义
- `Reference Snippets` 至少锁定一个关键对象形状；复杂任务默认推荐 2 段，其中一段是接口 / 结构，另一段是规则 / 配置 / SQL / CLI 片段

`L2 条件推荐`：仅在任务复杂度匹配时补充

- `File Map`
- `关键分支与实现策略`
- `伪代码 / 主循环`
- `竞态 / 状态机分析`

当任务满足以下任一条件时，`L2` 对应项升级为必写：

- 涉及 pipeline / batch / runner / task orchestration：
  - 必写 `伪代码 / 主循环`
- 涉及多路径策略（快速路径 / 通用路径、provider 分支等）：
  - 必写 `关键分支与实现策略`
- 涉及 HA / 选主 / 重试 / 状态机 / 恢复链路：
  - 必写 `竞态 / 状态机分析`
- 涉及跨多个目录或脚本 / 服务 / 配置联动实现：
  - 推荐补 `File Map`

## 4.2 禁止写法

- 只有 Mermaid，没有 `步骤化时序`
- 只有职责描述，没有代码落点或关键产物
- 只有 happy path，没有关键分支 / 降级路径
- `Concrete Steps` 只剩 `补测试 / 回写 / merge` 一类控制面步骤
- 只写抽象章节名，不写输入、对象、分支、边界
- 把 `Architecture / Data Flow` 写成对全系统的百科式介绍，而不是本次决策相关的实现链路
- 把整份 plan 写成纯表单问答，不输出真正的方案判断与改动面拆解

## 5. Mermaid 使用规则

- 每份复杂任务计划至少包含 1 张 Mermaid 图
- Mermaid 图应放在 `Architecture / Data Flow`、`设计与分层`、`数据流` 或 `执行流` 附近
- 若图放在实现骨架相关 section，默认必须画本次业务实现架构、模块调用链或数据流，不得用 harness 控制流程替代业务图
- harness 控制面流程只能放在 `Harness Control Plane` 邻近说明里，不能替代业务实现图
- 图下必须再写真实文字说明，至少覆盖真实入口、关键组件职责、数据或控制最终流向
- 默认优先使用：
  - `flowchart TD/LR`
  - `sequenceDiagram`
  - `stateDiagram-v2`
- 图只画本次决策相关的关键路径，不画全系统百科图

## 6. 代码示例使用规则

- 每份复杂任务计划至少包含 1 段代码示例，通常控制在 1-3 段
- 代码示例应紧贴具体改动点，用来锁定 DTO、接口签名、Repo 方法、SQL / DDL、配置片段的目标形状
- 示例优先级：
  - DTO / 请求响应结构
  - 服务或仓储接口签名
  - SQL / DDL / 配置样例
  - HTTP 请求示例
- `Reference Snippets` 至少锁定一个与当前关键调用链直接相关的真实接口 / 结构 / 命令 / 配置片段
- 示例只展示和本次决策直接相关的最小片段，不替代正式代码阅读

## 7. 维护规则

- plan 是活文档，不是一次性草稿
- 范围变化时，先更新范围冻结，再继续实施
- 新决策进入 `Decision Log`
- 新发现进入 `Surprises & Discoveries`
- 每完成一段工作后更新 `Progress`
- 任务结束后补 `Outcomes & Retrospective`

## 7.1 Maintenance Loop 计划要求

固定规则：

- `report-only` maintenance loop 若不修改文件、不写外部系统，可以只输出 findings，不强制写 plan。
- 进入 `issue-create`、`safe-fix`、`rule-promotion`、跨文件维护修复或外部系统回写时，必须先写或更新 plan。
- `rule-promotion` 必须写清：
  - 原始 evidence：哪些 review finding、runbook 漂移或重复问题触发升级
  - 拟升级的 `Rule ID`：对应 `docs/harness/project-constraints.md` 中哪条规则
  - 执行命令：升级后由哪个 linter、script、test、contract diff、E2E 或 harness check 承担
  - 回归验证：如何证明新增规则能拦截目标问题且不误伤现有合法用法
  - 回滚方式：误伤时如何临时关闭、降级为 `partial` 或回退检查
- maintenance plan 的结果面必须保留：`Maintenance Findings / Classification / Verification Plan / Writeback Plan / Residual Risks / Next Action`。

## 8. Issue Tracker 默认约定

固定规则：

- 若仓库不启用本地 `state / runs`，则 `recovery_point` 与 `next_action` 默认写回 Issue Tracker
- 计划里出现的 `Verify Summary / Review Summary / Writeback Summary` 默认都应可直接整理成 Issue Tracker 反馈结构
- repo 负责执行真相，Issue Tracker 负责协作真相
- Linear、GitHub、GitLab、repo issue 或其它工具只是 Issue Tracker profile
