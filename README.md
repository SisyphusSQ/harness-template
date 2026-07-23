# Harness 初始化基线

本仓库维护一套可初始化到业务项目的 Harness。目标是提供稳定的计划、状态、验证和交接入口，不把业务仓库铺成规则文档仓。

## 维护源

- `template/`：脚本初始化的 base harness
- `scripts/init_harness_project.sh` / `.ps1`：Bash 与 PowerShell 初始化入口
- `sources/gitignore/`：按技术栈拼装的 `.gitignore` 片段
- `sources/agent_adapters/`：Cursor 等特定 agent 的适配层
- `sources/agent_extensions/`：agent 驱动初始化时补充的 prompts 与 guides
- `agent-init-project.md`：agent 执行入口
- `init-harness-project-sop.md`：维护者与人工操作 SOP

## 初始化后的默认目录

脚本先生成 base harness；agent 驱动初始化再补 prompts、guides 和按需 adapter。

```text
repo/
├── AGENTS.md
├── README.md                       # 只保留业务说明
├── Makefile
├── .gitignore
├── .agents/
│   ├── PLANS.md
│   ├── plans/
│   │   ├── TEMPLATE.md
│   │   └── EXAMPLE-implementation.md
│   ├── prompts/
│   │   ├── README.md
│   │   ├── issue-standard-workflow.md
│   │   └── orchestrator-thread.md
│   ├── guides/
│   │   ├── code-review.md
│   │   └── linter.md
│   ├── runs/TEMPLATE.md
│   ├── state/TEMPLATE.md
│   └── skills/
│       ├── issue-goal-prompt/
│       ├── project-plan-archive/
│       ├── project-version-release/
│       └── test-runbook/
├── docs/
│   ├── harness/control-plane.md
│   ├── issues/
│   │   ├── README.md
│   │   └── TEMPLATE.md
│   └── test/RUNBOOK_TEMPLATE.md
└── scripts/harness/
    ├── check.sh
    ├── common.sh
    ├── evidence.sh
    ├── review_gate.sh
    ├── check.ps1
    ├── common.ps1
    ├── evidence.ps1
    └── review_gate.ps1
```

## 规则归属

- `AGENTS.md`：Agent 入口、项目真实约束和验证命令
- `docs/harness/control-plane.md`：唯一 Harness 控制面、Issue 状态机与 provider 映射
- `.agents/PLANS.md`：计划协议
- `.agents/prompts/issue-standard-workflow.md`：手动逐阶段执行
- `.agents/prompts/orchestrator-thread.md`：独立任务与主子任务交接
- `.agents/guides/`：review 和 lint 专项说明
- `docs/issues/`：`issue-provider=repo` 时的共享 Issue 载体
- `docs/test/`：测试 runbook 与脱敏结果摘要

项目 README 不承载 Harness 说明。通用交互 loop、automation loop 和 maintenance loop 不进入默认产物；自动化与维护规则跟随具体 automation、skill 或项目 runbook。

## 使用方式

macOS、Linux 或 Git Bash：

```bash
bash scripts/init_harness_project.sh \
  --target /abs/path/to/repo \
  --project-name NAME \
  --stack go \
  --provider neutral \
  --issue-provider linear \
  --issue-prefix ISSUE
```

Windows PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\init_harness_project.ps1 `
  -Target C:\path\to\repo `
  -ProjectName NAME `
  -Stack go `
  -Provider neutral `
  -IssueProvider linear `
  -IssuePrefix ISSUE
```

Agent 驱动初始化继续按 [agent-init-project.md](agent-init-project.md) 补充 adapter 和 extensions。

## 验证边界

- 源仓执行 `make verify` 或 `bash scripts/verify_harness_source.sh`；Windows 可运行 `scripts/verify_harness_source.ps1`。这些入口验证模板、初始化器、Bash/PowerShell 对齐、扩展源和 fresh init。
- 目标仓执行 `make harness-verify`，只验证 Harness 运行时关键不变量；仍需运行项目自身 build、test、lint 和 required live E2E。
- 没有 PowerShell runtime 时只能报告 Bash 实跑与 PowerShell 静态一致性，不能宣称 PowerShell 已运行通过。

修改 `template/`、初始化器或 `sources/agent_extensions/` 后必须运行源仓完整回归。
