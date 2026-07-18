# Harness 项目初始化 SOP

## 1. 目标

这份 SOP 的目标不是把新仓库铺成一个大模板仓，而是把真正需要长期稳定存在、而且初始化后马上能跑起来的 **base harness** 一次性初始化进去，同时把后续可选的 agent adapter 与 prompts / guides 独立成脚本外补充层。

初始化分成三层：

- **base harness**：由脚本直接生成
- **agent adapter**：按初始化 agent 类型补充，例如 Cursor project rules
- **agent 扩展层**：仅在 agent 驱动初始化时补充

truth split 默认采用：

- `Issue Tracker = 主协作真相`
- `repo = 主执行真相`
- `PR / MR = 次级代码叙事面`

base harness 需要完整具备：

- 仓库控制面规则
- 工具中立 Issue Workflow 与 issue / comment 模板
- `issue-provider=repo` 时的仓库内 issue 存储模板
- 项目级机械约束登记与接入协议
- `.gitignore` 基线
- `.agents` 最小计划模板与本地辅助运行面模板
- `.agents/skills` 默认 repo-local workflow 层
- `docs/test` 通用 runbook 模板
- 计划里“怎么实现”的固定骨架，而不只是 harness 流程骨架
- repo-local 最小 gate 脚本和共享 helper

## 2. Base Harness 目标结构

初始化到目标项目时，脚本固定只输出：

```text
target-repo/
├── .gitignore
├── AGENTS.md
├── README.md
├── Makefile
├── docs/
│   ├── harness/
│   │   ├── control-plane.md
│   │   ├── issue-workflow.md
│   │   ├── linear.md
│   │   └── project-constraints.md
│   ├── issues/
│   │   ├── README.md
│   │   └── TEMPLATE.md
│   └── test/
│       └── RUNBOOK_TEMPLATE.md
├── .agents/
│   ├── PLANS.md
│   ├── plans/TEMPLATE.md
│   ├── plans/EXAMPLE-implementation.md
│   ├── skills/
│   │   ├── issue-goal-prompt/
│   │   ├── project-plan-archive/
│   │   ├── project-version-release/
│   │   └── test-runbook/
│   ├── state/TEMPLATE.md
│   └── runs/TEMPLATE.md
└── scripts/harness/
    ├── check.sh
    ├── common.sh
    ├── review_gate.sh
    ├── evidence.sh
    ├── check.ps1
    ├── common.ps1
    ├── review_gate.ps1
    └── evidence.ps1
```

固定规则：

- 不再在目标项目里生成 `docs/linear/`
- 不再在目标项目里生成 `docs/linear/prompts/`
- 不再在目标项目里生成 `docs/harness/prompt-templates.md`
- `docs/harness/` 只承载控制面真相文档、Issue Workflow、Issue Tracker profile 和项目级机械约束登记
- `docs/issues/` 是 `issue-provider=repo` 时的仓库内 issue 存储
- `docs/test/RUNBOOK_TEMPLATE.md` 属于 base harness，承载通用测试 runbook 与结果摘要模板
- 不再默认生成没有消费链路的 `.agents/mappings/`
- 默认生成 `.agents/skills/`，承载通用 repo-local workflow：issue goal prompt、计划归档、版本发布边界、测试 runbook 执行与回写
- 不默认生成 `.cursor/`；Cursor rules 只在初始化 agent 是 Cursor 时作为 adapter 补充

## 3. Agent 扩展层

如果是 agent 驱动初始化，在 base harness 完成后，再补充：

- `.agents/prompts/README.md`
- `.agents/prompts/orchestrator-thread.md`
- `.agents/prompts/issue-standard-workflow.md`
- `.agents/prompts/loop-codex.md`
- `.agents/prompts/loop-automation.md`
- `.agents/prompts/maintenance-loop.md`
- `.agents/guides/code-review.md`
- `.agents/guides/linter.md`

固定规则：

- prompts / guides 不由脚本默认生成
- agent 驱动初始化默认生成完整模板（`full`）
- 只有用户明确要求轻量、占位或暂不铺开 prompt 模板时，才生成占位文件（`placeholder`）
- `.agents/prompts/README.md` 是稳定目录说明，不区分模式
- `.agents/prompts/orchestrator-thread.md` 是主 thread / 子 thread / worktree thread / subagent 编排入口
- 其他 7 个文件需要带 `Mode: placeholder|full`
- 更推荐的入口是先读根目录 `agent-init-project.md`

### 3.1 Cursor Agent Adapter（按需）

如果初始化执行 agent 是 Cursor，在 base harness 完成后、`.agents/prompts/` 与 `.agents/guides/` 扩展层之前，额外补充：

- `.cursor/rules/harness.mdc`

维护源固定放在：

```text
sources/agent_adapters/cursor/.cursor/rules/harness.mdc
```

固定规则：

- Cursor adapter 不属于 base harness
- `init_harness_project.sh` 与 `init_harness_project.ps1` 不负责生成 Cursor adapter，也不增加 `--agent` 参数
- `.cursor/rules/harness.mdc` 必须使用 Cursor project rule 格式
- frontmatter 字段名保持英文，必须包含 `alwaysApply: true`
- `description` 与正文使用中文
- 正文只负责引导 Cursor 读取 `AGENTS.md`、就近目录级 `AGENTS.md`、`docs/harness/*`、`.agents/*` 和 `docs/test/RUNBOOK_TEMPLATE.md`
- 不复制完整模板正文，避免和 harness 维护源漂移
- Cursor adapter 不和 `.agents/prompts/` 的 `placeholder` / `full` 模式绑定

## 4. 初始化输入

初始化脚本固定接收：

| Bash 参数 | PowerShell 参数 | 说明 |
| --- | --- |
| `--target` | `-Target` | 目标仓库绝对路径 |
| `--project-name` | `-ProjectName` | 目标项目名称 |
| `--stack` | `-Stack` | `go` / `python` / `java` / `c` / `go-node` / `python-node` / `java-node` / `c-node` / `java-c` / `java-c-node` |
| `--provider` | `-Provider` | `neutral` / `github` / `gitlab` |
| `--issue-provider` | `-IssueProvider` | `linear` / `github` / `gitlab` / `repo` / `other`，默认 `linear` |
| `--issue-prefix` | `-IssuePrefix` | Issue 前缀，例如 `APP` |
| `--force` | `-Force` | 允许覆盖模板管理的目标文件 |
| `--dry-run` | `-DryRun` | 只打印动作，不落盘 |

路径规则固定：

- Bash / Git Bash 入口只使用 POSIX 路径，例如 `/abs/path/to/repo` 或 `/c/path/to/repo`
- PowerShell 入口只使用 Windows 原生路径，例如 `C:\path\to\repo` 或 `\\server\share\repo`
- 两个入口不做自动路径转换；路径格式由调用方按入口类型传入

## 5. 初始化第 0 步：先定 `.gitignore`

顺序固定为：

1. 先叠加公共规则
2. 再叠加技术栈规则
3. 再补项目专属本地文件
4. 最后才做第一次提交

内部维护源位于：

- `sources/gitignore/base.gitignore`
- `sources/gitignore/go.gitignore`
- `sources/gitignore/python.gitignore`
- `sources/gitignore/java.gitignore`
- `sources/gitignore/c.gitignore`
- `sources/gitignore/node-frontend.gitignore`

### 5.1 公共规则

目标项目根 `.gitignore` 必须至少包含：

- `.DS_Store`
- `.idea/`
- `.vscode/`
- `*.log`
- `logs/`
- `tmp/`
- `temp/`

### 5.2 技术栈叠加

| `--stack` | 叠加规则 |
| --- | --- |
| `go` | Base + Go |
| `python` | Base + Python |
| `java` | Base + Java |
| `c` | Base + C / C++ |
| `go-node` | Base + Go + Node |
| `python-node` | Base + Python + Node |
| `java-node` | Base + Java + Node |
| `c-node` | Base + C / C++ + Node |
| `java-c` | Base + Java + C / C++ |
| `java-c-node` | Base + Java + C / C++ + Node |

### 5.3 默认不提交

初始化后，至少把这些内容视为默认不提交：

| 类别 | 示例 |
| --- | --- |
| 本地辅助运行面 | `.agents/state/*`、`.agents/runs/*` 的真实运行文件 |
| Cursor 私有配置 | `.cursor/*` 中除 `.cursor/rules/*.mdc` 外的本地文件 |
| 日志和缓存 | `*.log`、`logs/`、缓存目录 |
| 本地数据库 | `*.db`、`*.sqlite` |
| 本地导出物 | 调试截图、临时报表、调查附件 |
| IDE 私有文件 | `.idea/`、`.vscode/` |

### 5.4 防误伤规则

| 类型 | 不推荐 | 推荐 |
| --- | --- | --- |
| 日志目录 | `logs` | `logs/` 或 `*/logs/` |
| 文档目录 | `docs/harness/*` | 不忽略 |
| 技术栈目录 | 宽泛忽略整个 `src/`、`app/` | 只忽略明确的构建 / 缓存目录 |

固定规则：

- `docs/harness/*.md` 默认应提交
- `docs/issues/*.md` 默认应提交
- `docs/test/RUNBOOK_TEMPLATE.md` 默认应提交
- `.cursor/rules/*.mdc` 默认可提交，其它 `.cursor/*` 默认不提交
- `.agents/plans/TEMPLATE.md` 默认应提交
- `.agents/state/TEMPLATE.md` 与 `.agents/runs/TEMPLATE.md` 默认应提交
- 若 agent 后续补了 `.agents/prompts/` 或 `.agents/guides/`，这些文档默认也应提交
- 不允许因为懒得细化规则而用宽泛模式误伤源码或文档真相

## 6. 脚本初始化器做什么

初始化脚本固定做 8 步：

1. 校验参数
2. 校验目标路径是绝对路径且可初始化
3. 复制 `template/` 基础文件到目标项目
4. 按 `--stack` 生成最终根 `.gitignore`
5. 替换 `__PROJECT_NAME__`、`__ISSUE_PREFIX__`、`__PROVIDER__`、`__ISSUE_PROVIDER__`
6. Bash 入口赋予 `scripts/harness/*.sh` 可执行权限；PowerShell 入口不要求可执行位
7. Bash 入口执行 `scripts/harness/check.sh`；PowerShell 入口执行 `scripts/harness/check.ps1`
8. 打印下一步人工动作

固定规则：

- 脚本只负责 base harness
- scripts/init 不负责 Cursor adapter
- scripts/init 不负责 prompts / guides 的 placeholder/full 选择
- agent adapter 只在 agent 驱动初始化流程中按 agent 类型决定
- agent 扩展层只在 agent 驱动初始化时补充，默认使用 `full`
- 根目录 `agent-init-project.md` 是 agent 初始化整个项目的推荐入口
- Windows 用户不需要安装 Git Bash / WSL / make 即可完成 base harness 初始化和 PowerShell gate 验证

## 7. `docs/harness/` 与 `docs/issues/` 分工

### `control-plane.md`

必须覆盖：

- 主流程
- review / verification / merge / escalation 阶段说明
- `.agents` 计划 contract
- `.gitignore` 约束
- provider-neutral 默认策略

### `issue-workflow.md`

必须完整覆盖：

- issue 标准执行工作流
- requirement clarification 模板
- project 模板
- master issue 模板
- execution issue 模板
- codex handoff 模板
- 4 类评论模板
- master done checklist
- Issue Store Profiles
- repo issue 与外部 issue provider 的映射

### `linear.md`

必须完整覆盖：

- Linear profile 定位
- 从旧 Linear-first 入口到 `issue-workflow.md` 的迁移说明
- 通用字段到 Linear issue body / comment / state / project 的映射

### `docs/issues/`

必须完整覆盖：

- `README.md`：仓库内 issue 存储规则
- `TEMPLATE.md`：`issue_id`、`status`、`kind`、`goal`、`included`、`excluded`、`acceptance_matrix`、`stop_when`、`write_scope_limit`、`verification_commands`、`recovery_point`、`next_action`、`writeback_log`

### `project-constraints.md`

必须完整覆盖：

- 项目级机械约束的用途和边界
- 状态枚举：`enforced`、`partial`、`documented`、`planned`、`not_applicable`
- 分类枚举：`architecture`、`contract`、`runtime`、`verification`、`docs`、`security`、`cross-repo`
- 登记表字段：`Rule ID / Category / Rule / Source / Enforcement / Command / Status / Maintenance Tag / Notes`
- 维护标签：`maintenance_candidate`、`rule_promotion_candidate`、`human_decision_required`
- `project-check` 挂载协议
- 没有可执行命令或 gate 时，不得假装 `enforced`

固定规则：

- `docs/harness/` 不再承载 prompt 模板
- `project-constraints.md` 属于 base harness managed file，初始化后必须由项目按真实规则补齐
- maintenance loop 会扫描 `project-constraints.md`，但发现 `documented` 长期未机械化时只能报告或建议建 issue
- `docs/test/` 默认承载可执行测试 runbook 和提交版结果摘要
- 所有 prompt 模板统一归口 `.agents/prompts/`
- `Issue Tracker` 默认承接任务范围、状态、运行反馈、结果回写
- `repo` 默认承接执行命令、代码路径、设计入口、Prompt / Guide

### `docs/test/RUNBOOK_TEMPLATE.md`

必须覆盖：

- `当前验证结果`
- `本次执行结果`
- `执行副作用`
- `前置条件`
- `测试变量 / 初始化`
- `主路径`
- `清理结果`
- `结果回写`

固定规则：

- 测试文档默认写成可执行 runbook，不写成泛化 QA 说明
- 未执行步骤必须写 `未执行` 或 `blocker`，不得伪装成 `通过`
- 提交版文档应保留真实执行状态、结果摘要和必要恢复信息

## 8. `.agents` Base 输出

目标项目默认初始化这 4 类文件：

- `PLANS.md`
- `plans/TEMPLATE.md`
- `plans/EXAMPLE-implementation.md`
- `state/TEMPLATE.md`
- `runs/TEMPLATE.md`

固定要求：

- `state` / `runs` 默认作为本地辅助运行面保留
- 它们服务中断恢复、批次结果与本地审计，不替代 Issue Tracker
- `.agents/PLANS.md` 与 `.agents/plans/TEMPLATE.md` 必须明确：
  - `PLANS.md` 是协议，`TEMPLATE.md` 是主模板，`EXAMPLE-implementation.md` 是质量标杆
  - frontmatter 推荐但不强制，固定字段为 `name`、`overview`、`todos`、`isProject`
  - `Architecture / Data Flow` 要写业务实现骨架
  - `真实入口与触发 / 输入装配与边界校验 / 组件职责与代码落点 / 关键执行时序 / 停止 / 错误 / 恢复` 是默认必填子块
  - `Concrete Steps` 需要拆成 `### 实现步骤` 与 `### 验证与收口步骤`
  - `TEMPLATE.md` 默认采用“实现优先”结构：`0. 现有架构回顾与核心设计决策 -> 1..N 改动面 -> 数据流可视化 -> 关键设计决策摘要 -> 与现有代码的关系`
- `scripts/harness/review_gate.sh` 与 `scripts/harness/review_gate.ps1` 除了读取 `blocking_findings`，还要对 plan 做结构型轻量 lint，拒绝缺少实现骨架或仍保留明显占位内容的计划
- `scripts/harness/evidence.sh` 与 `scripts/harness/evidence.ps1` 只读生成 `head`、`worktree_digest`、`evidence_id`、`reusable` 和 `reason`
- `Reference Snippets` 不能是空块或纯占位内容
- `组件职责与代码落点` 至少要有一条真实模块 / 路径 / 类型记录
- `.agents/prompts/` 与 `.agents/guides/` 由 agent 驱动初始化时补充
- `.agents/skills/` 属于 base harness 默认输出；默认包含 `issue-goal-prompt`、`project-plan-archive`、`project-version-release`、`test-runbook`
- 若仓库同时使用 Issue Tracker 和本地运行面，则协作状态以 Issue Tracker 为准，本地恢复细节以 `.agents/state` / `.agents/runs` 为准

## 9. Agent 扩展维护源

agent adapter 维护源固定放在：

```text
sources/agent_adapters/
└── cursor/
    └── .cursor/
        └── rules/
            └── harness.mdc
```

固定规则：

- `sources/agent_adapters/` 按 agent 类型分目录
- Cursor adapter 只在初始化 agent 是 Cursor 时复制
- `.cursor/rules/harness.mdc` 必须是中文说明 + `alwaysApply: true`
- adapter 只负责 IDE / agent 入口路由，不承载完整 harness 模板正文

agent 扩展层维护源固定放在：

```text
sources/agent_extensions/
├── shared/
│   └── .agents/prompts/README.md
├── placeholder/
│   └── .agents/
│       ├── prompts/
│       │   ├── issue-standard-workflow.md
│       │   ├── loop-codex.md
│       │   ├── loop-automation.md
│       │   └── maintenance-loop.md
│       └── guides/
│           ├── code-review.md
│           └── linter.md
└── full/
    └── .agents/
        ├── prompts/
        │   ├── issue-standard-workflow.md
        │   ├── loop-codex.md
        │   ├── loop-automation.md
        │   └── maintenance-loop.md
        └── guides/
            ├── code-review.md
            └── linter.md
```

固定规则：

- `shared/` 只放不分模式的稳定文件
- `full/` 是 agent 驱动初始化默认扩展层，必须保持可直接执行的 prompt 密度
- `placeholder/` 是显式轻量模式，只用于用户要求占位或临时项目
- `placeholder/` 和 `full/` 的路径结构必须完全一致
- mode-sensitive 文件必须带 `Mode: placeholder|full`
- `full/` 与 `placeholder/` 生成执行计划时，都必须与 `.agents/PLANS.md` 的实现骨架 contract 保持一致
- `maintenance-loop.md` 默认 `report-only`，不新增自动修复脚本；只有用户显式指定时才进入 `issue-create / safe-fix / rule-promotion`

## 10. gate 脚本

目标项目固定保留两套 gate 入口：

- `check.sh`
- `common.sh`
- `review_gate.sh`
- `evidence.sh`
- `check.ps1`
- `common.ps1`
- `review_gate.ps1`
- `evidence.ps1`

固定要求：

- 保持 gate 入口脚本独立，公共解析逻辑收口到 `common.sh` / `common.ps1`
- `check.sh` 与 `check.ps1` 不只看关键字，还要做 gate smoke test
- `review_gate.sh` 与 `review_gate.ps1` 默认同时校验 `blocking_findings` 和 plan 的实现骨架
- `check.sh` 与 `check.ps1` 必须检查默认 `.agents/skills/` 文件、frontmatter 和关键安全边界
- `check.sh` 与 `check.ps1` 不要求 `.agents/prompts/` 与 `.agents/guides/` 存在
- 若这些可选文件存在，只允许检查其 `Mode:` 标记是否合法
- optional bundle 一旦存在，`.agents/prompts/maintenance-loop.md` 也必须存在并带合法 `Mode: placeholder|full`
- `check.sh` 与 `check.ps1` 不要求 `.cursor/rules/harness.mdc` 存在
- 若 Cursor rule 存在，必须检查中文描述、`alwaysApply: true`、关键 harness 导航入口和 `make harness-verify`
- `merge` / `escalation` 仍然是控制面阶段，但默认由 agent 根据仓库真相判断，不再作为 base harness 自带 shell gate

## 11. 初始化后人工检查

初始化完成后，立刻检查：

| 检查项 | 预期 |
| --- | --- |
| `git status` 是否出现真实配置 | 不应出现 |
| `docs/harness/control-plane.md` 是否存在 | 应存在 |
| `docs/harness/issue-workflow.md` 是否存在 | 应存在 |
| `docs/harness/linear.md` 是否存在兼容 profile | 应存在 |
| `docs/issues/README.md` 是否存在 | 应存在 |
| `docs/issues/TEMPLATE.md` 是否存在 | 应存在 |
| `docs/harness/project-constraints.md` 是否存在 | 应存在 |
| `docs/harness/prompt-templates.md` 是否不存在 | 应不存在 |
| `.agents/plans/EXAMPLE-implementation.md` 是否存在 | 应存在 |
| `.agents/skills/issue-goal-prompt/SKILL.md` 是否存在 | 应存在 |
| `.agents/skills/project-plan-archive/SKILL.md` 是否存在 | 应存在 |
| `.agents/skills/project-version-release/SKILL.md` 是否存在 | 应存在 |
| `.agents/skills/test-runbook/SKILL.md` 是否存在 | 应存在 |
| `.agents/state/TEMPLATE.md` 是否存在 | 应存在 |
| `.agents/runs/TEMPLATE.md` 是否存在 | 应存在 |
| `docs/test/RUNBOOK_TEMPLATE.md` 是否存在 | 应存在 |
| `scripts/harness/common.sh` 是否存在 | 应存在 |
| `scripts/harness/review_gate.sh` 是否存在 | 应存在 |
| `scripts/harness/common.ps1` 是否存在 | 应存在 |
| `scripts/harness/review_gate.ps1` 是否存在 | 应存在 |
| `scripts/harness/merge_gate.sh` 是否不存在 | 应不存在 |
| `scripts/harness/escalation_gate.sh` 是否不存在 | 应不存在 |
| `bash scripts/harness/check.sh` 是否通过 | 应通过 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1` 是否通过 | Windows / PowerShell 环境应通过 |
| 若初始化 agent 是 Cursor，`.cursor/rules/harness.mdc` 是否存在且 `alwaysApply: true` | 应正确 |
| 若是 agent 驱动初始化，`.agents/prompts/*.md` 是否带正确 `Mode:` 标记 | 应正确 |

## 12. 常见误区

1. 继续把 issue 模板散放到 `docs/linear/`
2. 继续把 prompt 模板塞回 `docs/harness/`
3. `.gitignore` 只做了 Base，没叠加技术栈规则
4. 预先初始化一堆没有消费链路的 `.agents` 空壳目录
5. 让 `check.sh` / `check.ps1` 依赖 prompts / guides 才能通过
6. 把 agent 扩展层做成脚本参数，而不是在 agent 初始化流程里决定
7. 把 `merge` / `escalation` 继续实现成 initializer 自带 shell gate
8. 把 Cursor rules 放进 base template，导致所有项目默认生成 `.cursor/`
9. 把项目级机械约束只写在聊天或 README 里，不登记到 `docs/harness/project-constraints.md`
10. 把 maintenance loop 理解成默认自动修复脚本，而不是默认 `report-only` 的维护 prompt
