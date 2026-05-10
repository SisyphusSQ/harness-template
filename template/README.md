# __PROJECT_NAME__

这是 `__PROJECT_NAME__` 的仓库级 README 模板。

## 当前阶段

- 当前仓库已完成 harness 控制面初始化
- 控制面文档统一收口到 `docs/harness/`
- 初始化后应先确认 `.gitignore`、`.agents/`、`docs/harness/project-constraints.md`、`docs/test/RUNBOOK_TEMPLATE.md`、`scripts/harness/` 是否就位并可执行
- 若通过 agent 驱动初始化，默认再补齐 `.agents/prompts/` 与 `.agents/guides/`
- base harness 默认只带 Bash 与 PowerShell 两套 `check + review_gate`
- `.agents/state/` 与 `.agents/runs/` 默认作为本地辅助运行面存在

## 推荐阅读顺序

1. `AGENTS.md`
2. `docs/harness/control-plane.md`
3. `docs/harness/issue-workflow.md`
4. `docs/harness/linear.md`（仅 Linear 兼容 profile）
5. `docs/issues/README.md`
6. `docs/harness/project-constraints.md`
7. `docs/test/RUNBOOK_TEMPLATE.md`
8. `.agents/PLANS.md`
9. `.agents/plans/TEMPLATE.md`
10. `.agents/plans/EXAMPLE-implementation.md`
11. 若存在，再读 `.agents/prompts/README.md`
12. 若存在，再读 `.agents/prompts/maintenance-loop.md`

## 目录职责

| 路径 | 说明 |
| --- | --- |
| `docs/harness/` | 控制面规则、Issue Workflow、Issue Tracker profile 与项目级机械约束登记 |
| `docs/issues/` | `issue-provider=repo` 时的仓库 issue 存储 |
| `docs/test/` | 通用测试 runbook 模板与后续脱敏结果摘要 |
| `.agents/` | 计划协议、计划模板、实现型 exemplar、本地辅助运行面，以及后续 prompts / guides |
| `scripts/harness/` | base harness 的最小 gate 脚本与共享 helper |

## 默认 truth split

- `Issue Tracker = 主协作真相`
- `repo = 主执行真相`
- `PR / MR = 次级代码叙事面`
- `.agents/state / .agents/runs = 本地辅助运行面`

## 初始化后先做什么

1. 检查 `.gitignore`
2. 确认真实配置、日志、数据库文件不会进入暂存区
3. 若仓库需要环境配置，优先补 `.env.example`、`settings.example.yaml`
4. 阅读 `docs/harness/` 与 `docs/issues/README.md`
5. 若没有外部 issue 工具，使用 `docs/issues/TEMPLATE.md` 维护仓库内 issue
6. 填写 `docs/harness/project-constraints.md` 中的项目级机械约束登记表
7. 阅读 `docs/test/RUNBOOK_TEMPLATE.md`
8. 阅读 `.agents/PLANS.md`、`.agents/plans/TEMPLATE.md`、`.agents/plans/EXAMPLE-implementation.md`
9. 若是 agent 驱动初始化，再补齐 `.agents/prompts/` 与 `.agents/guides/`，并选择 `placeholder / full` 模式
10. 若存在 `.agents/prompts/maintenance-loop.md`，确认默认 mode 是 `report-only`
11. macOS / Linux / Git Bash 执行 `make harness-verify`
12. Windows PowerShell 执行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1`
