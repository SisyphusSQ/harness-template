# Agent 项目初始化基线

本仓库提供一个极简的 Agent 项目初始化器。默认只写入项目协作真正需要的入口、计划、状态/运行记录模板、repo-local skills 和测试 runbook；不会把 Harness 控制面、状态机或 gate 流程带进目标项目。

## 维护源

- `template/`：初始化器复制的唯一项目模板；其中的全部 skills 会同步到目标项目
- `scripts/init_harness_project.sh` / `.ps1`：Bash 与 PowerShell 初始化入口
- `sources/gitignore/`：按技术栈拼装 `.gitignore` 的片段
- `sources/agent_adapters/`、`sources/agent_extensions/`：保留的历史/按需源，不属于默认初始化输出
- `agent-init-project.md`：Agent 执行入口
- `init-harness-project-sop.md`：维护者与人工操作 SOP

## 初始化后的默认目录

```text
repo/
├── AGENTS.md
├── README.md                       # 业务说明占位
├── .gitignore
├── .agents/
│   ├── PLANS.md                    # 按需计划说明
│   ├── plans/
│   │   ├── TEMPLATE.md
│   │   └── EXAMPLE-implementation.md
│   ├── state/TEMPLATE.md           # 真实状态文件默认留在本地
│   ├── runs/TEMPLATE.md            # 真实运行摘要默认留在本地
│   └── skills/                     # template/ 下的全部 skills
│       ├── issue-goal-prompt/
│       ├── project-plan-archive/
│       ├── project-version-release/
│       └── test-runbook/
└── docs/
    └── test/RUNBOOK_TEMPLATE.md
```

当 `issue_provider=repo` 时，额外生成 `docs/issues/README.md` 和 `docs/issues/TEMPLATE.md`。默认 `issue_provider` 是 `linear`，但初始化器不会主动调用或写入外部 Issue 系统。

默认不会生成以下内容：

- `Makefile`
- `docs/harness/`
- `scripts/harness/`
- `.agents/prompts/`、`.agents/guides/` 和 agent adapter
- 强制性的 issue 状态机、review gate、evidence gate 或 orchestrator loop

## 使用方式

macOS、Linux 或 Git Bash：

```bash
bash scripts/init_harness_project.sh \
  --target /abs/path/to/repo \
  --project-name NAME \
  --stack go \
  --issue-prefix ISSUE
```

Windows PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\init_harness_project.ps1 `
  -Target C:\path\to\repo `
  -ProjectName NAME `
  -Stack go `
  -IssuePrefix ISSUE
```

需要仓库内 Issue 记录时显式指定：

```bash
bash scripts/init_harness_project.sh \
  --target /abs/path/to/repo \
  --project-name NAME \
  --stack go \
  --issue-provider repo
```

已有目标文件默认不会覆盖；确认要更新旧初始化产物时使用 `--force` / `-Force`。旧版本声明过的 Harness 文件只会在 force 模式下清理，未声明的业务文件不会被处理。

## 验证边界

- 源仓运行 `make verify`，检查模板、初始化器、契约和 fresh target 初始化。
- 目标仓只运行项目自身约定的 build、test、lint、integration 或 live E2E；本初始化器不再安装或执行目标仓 Harness gate。
- 没有 PowerShell runtime 时，源仓验证只能报告 Bash 实跑与 PowerShell 静态检查结果，不能宣称 PowerShell 已实跑通过。

修改 `template/`、初始化器或 `.gitignore` 源片段后运行 `make verify`。
