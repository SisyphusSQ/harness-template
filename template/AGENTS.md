# __PROJECT_NAME__ AGENTS

## 项目定位

本文件是 `__PROJECT_NAME__` 的根级协作入口，只负责：

1. 说明仓库当前阶段
2. 给出控制面文档导航
3. 定义 `docs/harness/` 与 `.agent/` 的边界
4. 明确哪些内容默认不提交

## 快速导航

| 主题 | 入口 |
| --- | --- |
| 仓库说明 | `README.md` |
| 主流程、gate、计划 contract | `docs/harness/control-plane.md` |
| Linear 工作流与模板 | `docs/harness/linear.md` |
| 项目级机械约束登记 | `docs/harness/project-constraints.md` |
| 计划协议 | `.agent/PLANS.md` |
| 计划主模板 | `.agent/plans/TEMPLATE.md` |
| 实现型示例 | `.agent/plans/EXAMPLE-implementation.md` |
| 本地恢复面 | `.agent/state/TEMPLATE.md` |
| 本地结果面 | `.agent/runs/TEMPLATE.md` |
| 可选 Prompt 层 | `.agent/prompts/README.md`（如存在） |
| 可选维护循环 Prompt | `.agent/prompts/maintenance-loop.md`（如存在，默认 `report-only`） |
| 可选 Guide 层 | `.agent/guides/`（如存在） |

## 真相边界

| 路径 | 负责内容 |
| --- | --- |
| `docs/harness/` | 控制面规则、Linear 模板与项目级机械约束登记 |
| `.agent/PLANS.md` + `.agent/plans/` | 计划协议、计划主模板和实现型示例 |
| `.agent/state/` + `.agent/runs/` | repo-local 恢复点与结果摘要面 |
| `.agent/prompts/` | 可选 Prompt 模板，仅 agent 驱动初始化时补充 |
| `.agent/guides/` | 可选 review / linter 说明，仅 agent 驱动初始化时补充 |
| `.agent/skills/` | 可选 repo-local skill，仅在项目需要稳定复用的专门流程时补充 |
| `scripts/harness/` | base harness 的最小 gate 脚本与共享 helper |

固定解释：

- `Linear 是主协作真相`
- `repo 是主执行真相`
- `PR / MR 是次级代码叙事面`
- `.agent/state/` 与 `.agent/runs/` 只补充本地恢复和结果细节，不替代 Linear

## 协作约束

- 复杂任务默认先写 plan，再进入实现
- `docs/harness/*.md` 默认应提交
- 初始化后应在 `docs/harness/project-constraints.md` 中登记项目级机械约束；没有可执行命令或 gate 的规则不得标记为 `enforced`
- `.agent/plans/TEMPLATE.md` 默认应提交
- `.agent/plans/EXAMPLE-implementation.md` 默认应提交
- `.agent/state/TEMPLATE.md` 默认应提交
- `.agent/runs/TEMPLATE.md` 默认应提交
- 若后续补齐 `.agent/prompts/` 和 `.agent/guides/`，这些文档默认也应提交
- 若存在 `.agent/prompts/maintenance-loop.md`，默认只做 `report-only` 维护扫描；`issue-create / safe-fix / rule-promotion` 必须由用户显式指定
- 模板配置可提交，真实环境配置不提交
- 若需要环境配置，优先提交 `.env.example`、`settings.example.yaml` 这类示例文件
- `docs/test/*` 默认提交可复用 runbook 与脱敏后的当前 / 本次验证结果摘要
- 原始命令输出、真实凭据、数据库主机、临时目录、完整下载 URL、token、行主键、本机路径等敏感或机器本地痕迹不提交
- 已写入 `docs/test/*` 的脱敏验证结果摘要是提交版测试真相，后续同步或 closeout 不得因为避免敏感信息而删成空模板
- `.agent/state/*` 与 `.agent/runs/*` 的真实运行文件默认不提交
- 本地日志、数据库文件、缓存、IDE 私有文件默认不提交
- `merge` / `escalation` 仍然是流程阶段，但默认不由 initializer 自带 shell gate 承担

## 多仓协作约定（按需）

- 多仓协作时，默认由 provider 仓维护 contract truth、schema truth、接口示例和服务端验收口径。
- consumer 仓只维护 consumer rule、快照、缓存、mock、golden 或消费侧验证，不反定义 provider truth。
- 若 consumer 仓需要新增或调整 contract 快照，默认同步检查 provider 仓的 contract 文档是否需要更新。

## 目录级 AGENTS（按需）

- 大仓或分层约束较重的目录，可以在子目录放置更细的 `AGENTS.md`。
- 修改某个目录下的代码前，先读取该目录就近的 `AGENTS.md`；更细目录规则优先于根级通用规则。
- 目录级 `AGENTS.md` 只写稳定实现习惯、分层边界、测试约定和代码风格，不承接临时 issue 计划。

## Provider 默认值

- 当前 provider：`__PROVIDER__`
- 若后续锁定 GitHub 或 GitLab，只调整 merge 说明，不改变目录结构
