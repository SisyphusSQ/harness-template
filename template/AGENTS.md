# __PROJECT_NAME__ Agent Guide

## 定位

本文件是仓库内 Agent 的根级入口。开始工作前先读取本文件，再按任务需要进入下游文档。

项目 `README.md` 只负责业务说明；本文件只记录稳定的协作入口、项目约束和本地辅助材料。

## 快速导航

| 内容 | 入口 |
| --- | --- |
| 项目业务说明 | `README.md` |
| 可选复杂任务计划 | `.agents/PLANS.md`、`.agents/plans/` |
| 本地恢复与长提示词 | `.agents/state/` |
| 本地运行摘要 | `.agents/runs/` |
| Issue Goal Prompt | `.agents/skills/issue-goal-prompt/SKILL.md` |
| 计划归档 | `.agents/skills/project-plan-archive/SKILL.md` |
| 版本与发布 | `.agents/skills/project-version-release/SKILL.md` |
| 测试 runbook | `.agents/skills/test-runbook/SKILL.md`、`docs/test/` |
| 仓库内 Issue（仅 `repo` provider） | `docs/issues/` |

## Issue 元信息

- 当前 issue provider：`__ISSUE_PROVIDER__`
- issue prefix：`__ISSUE_PREFIX__`

Linear、GitHub、GitLab 或其它外部 Issue 系统是协作记录入口；代码、配置和可复现验证以当前仓库为准。

## 默认协作方式

- 简单任务直接分析和实施，不要求先创建计划。
- 跨模块、影响公开接口、配置、数据或发布边界的任务，建议先使用 `.agents/plans/` 写一份短计划。
- 计划只描述目标、范围、实现步骤、验证和恢复方式，不复制整套协作规则。
- `.agents/state/` 只保存本地恢复点或较长提示词，不替代 Issue 状态。
- `.agents/runs/` 只保存本地运行摘要和原始记录，不作为强制门禁。
- 不存在对应模板时，按本文件、项目代码和用户明确约束直接工作，不另造全局流程。

## 项目约束

初始化后必须用本项目的真实信息补齐本节。

- 项目结构与分层：`TODO`
- 默认 build：`TODO`
- 默认 test：`TODO`
- 默认 lint / format：`TODO`
- 必需的 live / integration 验证：`TODO` 或 `not_required`
- 禁止修改或需要额外授权的范围：`TODO`
- 发布入口：`TODO` 或 `not_applicable`

只有存在可执行命令的规则才能宣称为机械强制；其余规则按文档约束准确表述。

## 提交与本地产物

- 默认提交：`AGENTS.md`、项目文档、按需计划、skills、测试 runbook 和脱敏结果摘要。
- 默认不提交：`.agents/state/` 和 `.agents/runs/` 的真实运行文件、本地日志、数据库、缓存、IDE 私有文件和凭据。
- `.agents/state/TEMPLATE.md` 与 `.agents/runs/TEMPLATE.md` 保持提交。
- repo-local skill 默认只做 dry-run；产生写入或外部副作用时必须显式授权。

## 多仓与目录级规则

- 多仓任务由实际负责该能力的仓库维护 contract、schema、接口示例和验收口径；消费仓只维护消费规则、快照、mock 或消费侧验证。
- 大仓可以在子目录增加更具体的 `AGENTS.md`；修改文件前读取就近规则，更深层规则优先。
- 目录级 `AGENTS.md` 只写稳定实现约束，不承载临时 Issue 计划。
