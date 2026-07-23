---
name: <任务名>
overview: <一句话交付结果>
todos:
  - id: <todo-id>
    content: <todo 内容>
    status: pending
isProject: false
---

# ExecPlan: <任务名>

## Goal

- 目标：
- 成功标准：

## Scope and Non-Goals

- Included：
- Excluded：

## Scope Freeze

| 类型 | 内容 |
| --- | --- |
| 代码 / 文档 / 配置范围 |  |
| Write scope |  |
| Acceptance Matrix |  |
| Stop When |  |

## Context and Orientation

- 当前现状与来源：
- 关键入口：
- 可复用能力：
- 风险、依赖与未决项：

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发

- `调用者 / 入口`：<请替换为真实入口>
- `入口代码位置`：<请替换为真实路径、函数或 command>
- `触发条件 / 上游依赖`：<请替换>

### 输入装配与边界校验

- `输入来源与装配位置`：<请替换>
- `装配结果 / 核心对象`：<请替换>
- `边界校验 / 拒绝条件`：<请替换>

### 组件职责与代码落点

| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `<路径 / 类型>` | `<新增/复用>` |  |  |  |

### 关键执行时序

```mermaid
flowchart LR
    Entry["真实入口"] --> Assemble["装配与校验"]
    Assemble --> Core["核心实现"]
    Core --> Output["结果或外部系统"]
```

- `步骤化时序`：
  1. <入口如何获取输入>
  2. <核心对象如何进入实现链路>
  3. <关键分支如何选择>
  4. <结果如何落盘或返回>

### 停止 / 错误 / 恢复

- `正常停止条件`：<请替换>
- `主要错误出口`：<请替换>
- `关键分支 / 降级路径`：<请替换>
- `恢复 / 重试 / 回滚`：<请替换>

### 按需补充

- File Map：跨目录或多文件联动时补。
- 伪代码 / 主循环：pipeline、batch、runner 或 orchestration 时补。
- 竞态 / 状态机：并发、HA、重试或恢复链路时补。

## 1. <改动面> -- <本次变更>

- 目标与边界：
- 代码落点与目标形状：
- 实现要点和兼容策略：
- 验证关注点：

按需继续增加改动面，不复制空章节。

## Reference Snippets

至少放一个与关键调用链直接相关的真实接口、结构、命令、配置、SQL 或 CLI 片段。

```text
<请替换为真实最小片段>
```

- 片段作用：

## Concrete Steps

### 实现步骤

1. <真实文件或行为改动>
2. <关键分支、错误处理或兼容逻辑>
3. <必要文档或配置同步>

### 验证与收口步骤

1. <focused 验证命令>
2. <完整验证与 review gate>
3. <结果回写位置>

## Progress

| 日期 | 状态 | 说明 |
| --- | --- | --- |
|  |  |  |

## Decision Log

| 日期 | 决策 | 原因 |
| --- | --- | --- |
|  |  |  |

## Surprises & Discoveries

-

## Validation and Acceptance

- 验证命令：
- 未验证项与原因：

## Idempotence and Recovery

- 重跑安全性：
- 恢复 / 回滚：
- `recovery_point` / `next_action`：

## Review Summary

- `blocking_findings`: <none 或阻塞摘要>
- 说明：

## Outcomes & Retrospective

- 最终结果：
- 遗留项：
- 后续建议：
