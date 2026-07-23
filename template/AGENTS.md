# __PROJECT_NAME__ AGENTS

## 定位

本文件是仓库内 Agent 的根级入口。开始工作前先读取本文件，再按任务进入对应文档。

项目 `README.md` 只负责业务说明，不承载 Harness 规则。

## 快速导航

| 任务 | 入口 |
| --- | --- |
| Harness 主流程、Issue 状态机、review 与验证 | `docs/harness/control-plane.md` |
| 复杂任务计划协议 | `.agents/PLANS.md` |
| 计划模板与示例 | `.agents/plans/TEMPLATE.md`、`.agents/plans/EXAMPLE-implementation.md` |
| 手动逐阶段执行 | `.agents/prompts/issue-standard-workflow.md`（如存在） |
| 多任务或子任务交接 | `.agents/prompts/orchestrator-thread.md`（如存在） |
| Review / lint 说明 | `.agents/guides/`（如存在） |
| 仓库内 Issue 载体 | `docs/issues/` |
| 测试 runbook | `docs/test/`、`.agents/skills/test-runbook/SKILL.md` |
| 计划归档与版本发布 | `.agents/skills/project-plan-archive/`、`.agents/skills/project-version-release/` |
| 本地恢复点与结果摘要 | `.agents/state/`、`.agents/runs/` |

## 渐进式读取

- 默认只读取本文件；根据任务需要再进入下游文档，不要预加载整个 `.agents/` 或 `docs/`。
- 涉及 Harness 状态、Issue、review、验证或交付边界时读取 `docs/harness/control-plane.md`。
- 复杂任务先读 `.agents/PLANS.md`；真正写计划时再读 `.agents/plans/TEMPLATE.md`。
- `.agents/plans/EXAMPLE-implementation.md` 只在需要校准计划质量或叙事密度时读取。
- 手动逐阶段执行、多任务交接、review、lint、测试分别读取对应 prompt、guide 或 runbook。
- `docs/issues/` 只在 `issue-provider=repo` 时读取；skills 只在任务匹配或被显式调用时读取。

## 真相边界

- `Issue Tracker 是主协作真相`：目标、范围、状态、阻塞和结果回写以 Issue Tracker 为准。
- `repo 是主执行真相`：代码、配置、计划、测试和可复现验证以当前仓库为准。
- PR / MR 是次级代码叙事面，不替代 Issue Tracker。
- `.agents/state/` 与 `.agents/runs/` 只保存本地恢复和结果细节。
- 当前 merge provider：`__PROVIDER__`。
- 当前 issue provider：`__ISSUE_PROVIDER__`；为 `repo` 时使用 `docs/issues/`。

## 默认工作方式

- 日常主线：`collect + gate -> freeze + slice -> implement -> verify -> review -> closeout`。
- 只有发生 fan-out、可写 lease 或其他 integration event 时，才进入 `dispatch / integrate / post-integration verify`。
- 只有交付目标包含 PR / MR 且已获用户或仓库规则授权时，才进入 `pr_prep / merge`。
- 复杂任务先按 `.agents/PLANS.md` 创建或更新计划，再实施。
- 手动一步步推进时使用 `.agents/prompts/issue-standard-workflow.md`。
- 创建独立任务、子任务或跨工作区交接时使用 `.agents/prompts/orchestrator-thread.md`。
- 不存在对应 prompt 时，直接遵循本文件与 `docs/harness/control-plane.md`，不要另造一套流程。

## 项目约束

初始化后必须用本项目的真实信息补齐本节；不要维护单独的 constraints 登记表。

- 项目结构与分层：`TODO`
- 默认 build：`TODO`
- 默认 test：`TODO`
- 默认 lint / format：`TODO`
- 必需的 live / integration 验证：`TODO` 或 `not_required`
- 禁止修改或需要额外授权的范围：`TODO`
- 发布入口：`TODO` 或 `not_applicable`

只有存在可执行命令或 gate 的规则才能宣称为机械强制；其余规则按文档约束准确表述。

## Harness 验证

- macOS、Linux、Git Bash：`make harness-verify`
- Windows PowerShell：`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1`
- Harness 验证不替代项目自身 build、test、lint 或 required live E2E。
- 成功验证后可用 `bash scripts/harness/evidence.sh snapshot` 生成证据快照；复用边界见 control plane。
- `review_policy` 与验证证据复用规则统一以 control plane 为准，不在本文件重复定义。
- Bash / Git Bash 使用 POSIX 路径；PowerShell 使用 Windows 或 UNC 路径，不自动互转。

## 提交与本地产物

- 默认提交：`AGENTS.md`、`docs/harness/`、`.agents/PLANS.md`、计划模板、skills、prompt、guides、可复用测试 runbook 与脱敏结果摘要。
- 默认不提交：`.agents/state/` 和 `.agents/runs/` 的真实运行文件、本地日志、数据库、缓存、IDE 私有文件和凭据。
- `.agents/state/TEMPLATE.md` 与 `.agents/runs/TEMPLATE.md` 保持提交。
- 已写入 `docs/test/*` 的脱敏验证摘要不得在后续同步时删回空模板。
- repo-local skill 默认只做 dry-run；产生写入或外部副作用时必须显式授权。

## 多仓与目录级规则

- 多仓任务由 provider 仓维护 contract、schema、接口示例和服务端验收口径；consumer 仓只维护消费规则、快照、mock 或消费侧验证。
- 大仓可以在子目录增加更具体的 `AGENTS.md`；修改文件前读取就近规则，更深层规则优先。
- 目录级 `AGENTS.md` 只写稳定实现约束，不承载临时 Issue 计划。
