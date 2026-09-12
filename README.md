# Agent 项目初始化基线

v0.7.0 提供按需协作的项目入口。默认生成 9 个文件：项目规则、业务 README 占位、计划/恢复/运行记录模板、测试 runbook 和 .gitignore。四个通用技能单独维护、按需使用。

## 使用

需要 Python 3.10+，不需要安装第三方 Python 包。Bash 和 PowerShell 共用同一份初始化实现。

```bash
bash scripts/init_harness_project.sh \
  --target /abs/path/to/repo --project-name NAME --stack go
```

```powershell
.\scripts\init_harness_project.ps1 -Target C:\path\to\repo -ProjectName NAME -Stack go
```

也可直接运行 `python3 scripts/init_harness_project.py`，参数与 Bash 相同。

- 默认只创建缺失文件，保留已有 README、AGENTS、计划和技能。相同输入可重复执行。
- .gitignore 只更新标记块，原有规则保留；首次生成的标记块放在原有规则之前，保留用户规则的优先级。
- `--dry-run` / `-DryRun` 显示实际 create、update、keep-existing、unchanged 操作，不创建目录或文件。
- 需要替换文件时显式指定 `--overwrite .agents/plans/TEMPLATE.md` / `-Overwrite .agents/plans/TEMPLATE.md`；先审阅该文件，不能用此参数覆盖输出范围之外的文件。
- `--force` / `-Force` 已取消并会报错。初始化不会删除任何旧版文件，包括 Makefile。迁移见 [v0.7 迁移说明](docs/migration-v0.7.md)。

## 默认目录

```text
repo/
├── AGENTS.md
├── README.md
├── .gitignore
├── .agents/
│   ├── PLANS.md
│   ├── plans/TEMPLATE.md
│   ├── plans/EXAMPLE-implementation.md
│   ├── state/TEMPLATE.md
│   └── runs/TEMPLATE.md
└── docs/test/RUNBOOK_TEMPLATE.md
```

计划只用于复杂任务；state/runs 只在恢复或追溯需要时写入，不要求每个任务重复维护。初始化后由 Agent 结合仓库补齐真实入口、命令和约束，未知项保持明确，不能把模板生成当成业务验证。

默认 issue provider 是 `linear`，仅写元数据，不访问外部系统。`--issue-provider repo` 额外生成 docs/issues/。已有文件被保留时，其原有 provider、项目名和约束也保留；切换 provider 要审阅并更新相应文档。

## 可选技能

[project-workflows](plugins/project-workflows/README.md) 包含目标提示词、计划归档、版本发布、测试 runbook 四个技能，可作为共享插件使用。初始化器不会安装插件或修改本机设置。

只在目标仓确实需要独立副本时选择技能：

```bash
bash scripts/init_harness_project.sh \
  --target /abs/path/to/repo --project-name NAME --stack go \
  --skill test-runbook --skill project-plan-archive
```

PowerShell 对应 `-Skill test-runbook,project-plan-archive`。技能脚本可以从插件目录或 repo-local 副本执行，目标仓库通过 `--repo` 指定；源仓测试不会复制到业务项目。

## 维护与验证

- `template/`：默认项目模板，目录自动发现，不重复维护文件清单。
- `sources/gitignore/`：按技术栈拼装的规则片段。
- `scripts/init_harness_project.py`：唯一初始化实现；.sh/.ps1 只传递参数。
- `plugins/project-workflows/`：可选技能包。
- [Agent 执行入口](agent-init-project.md)、[维护 SOP](init-harness-project-sop.md)。

开发阶段运行 `make verify`；Windows 可运行 `python scripts/verify_harness_source.py`。验证使用临时目录、本地 Git 仓库和 Python 标准库，覆盖初始化、保留/覆盖边界、技能副本、归档和版本文件操作。发现 PowerShell runtime 时实跑其包装入口；否则明确报告 NOT_RUN。不访问业务服务、数据库或 Issue Tracker。

旧控制面与 adapter 源不再参与维护；需要历史参考时查看 [v0.6.0](https://github.com/SisyphusSQ/harness-template/tree/v0.6.0)。发布记录见 [CHANGELOG](CHANGELOG.md)。
