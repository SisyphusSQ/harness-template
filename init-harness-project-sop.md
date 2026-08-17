# 项目初始化 SOP

本 SOP 面向人工操作和初始化器维护者。Agent 执行入口见 `agent-init-project.md`。

## 1. 目标

初始化后，业务项目获得一套轻量、可选的协作基础：

- 根级 `AGENTS.md` 和业务 `README.md` 占位
- `.agents/PLANS.md` 与按需计划模板
- `.agents/state/`、`.agents/runs/` 的本地记录模板
- `template/.agents/skills/` 中的全部 skills
- `docs/test/RUNBOOK_TEMPLATE.md`
- 默认保留 `issue_provider=linear` 元数据

不再默认生成：

```text
Makefile
docs/harness/
scripts/harness/
.agents/prompts/
.agents/guides/
agent adapter
强制状态机、review gate、evidence gate 或 orchestrator loop
```

## 2. 初始化参数

| 参数 | 允许值 |
| --- | --- |
| stack | `go`、`python`、`java`、`c` 及脚本列出的组合栈 |
| issue provider | `linear`（默认）、`github`、`gitlab`、`repo`、`other` |
| issue prefix | 可选字符串 |
| force | 显式允许覆盖现有 managed 文件，并清理声明过的旧初始化产物 |

目标路径必须是对应平台的绝对路径。已有目标文件默认不覆盖；不要把 `--force` 用于未检查的业务仓库。

## 3. Base 初始化

macOS、Linux、Git Bash：

```bash
bash scripts/init_harness_project.sh \
  --target /abs/path/to/repo \
  --project-name NAME \
  --stack go \
  --issue-provider linear \
  --issue-prefix ISSUE
```

Windows PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\init_harness_project.ps1 `
  -Target C:\path\to\repo `
  -ProjectName NAME `
  -Stack go `
  -IssueProvider linear `
  -IssuePrefix ISSUE
```

初始化器负责：

- 复制 `template/` 的 managed files，包括模板中的全部 skills
- 按技术栈拼装 `.gitignore`
- 替换项目名、issue provider 和 issue prefix 占位符
- 仅在 force 模式下清理已声明的旧 Harness managed 文件
- `issue_provider=repo` 时复制 `docs/issues/`

初始化器不负责：

- 推断业务 build / test / lint 命令
- 创建 PR / MR、提交或推送
- 写入外部 Issue Tracker
- 执行项目测试、live E2E 或部署
- 安装 agent adapter、prompts、guides 或目标仓 gate

## 4. 初始化后补齐

1. 保留或补充业务 README，不写初始化器教程。
2. 在 `AGENTS.md` 写入真实项目结构、build、test、lint、integration / live E2E、禁止范围和发布入口。
3. 复杂任务才创建 `.agents/plans/YYYY-MM-DD-<slug>.md`。
4. 需要本地恢复信息或命令摘要时，写入 `.agents/state/` 或 `.agents/runs/`；默认不提交真实运行记录。
5. `issue_provider=repo` 时使用 `docs/issues/TEMPLATE.md`；其他 provider 不生成仓库内 Issue 文档。

## 5. 验证

源仓维护后：

```bash
make verify
```

目标仓：按目标项目 `AGENTS.md` 中的真实命令验证。必须区分初始化器检查、项目本地验证、外部环境验证和未执行项；不要用初始化完成替代项目验证。

没有 PowerShell runtime 时，只能记录 Bash 实跑与 PowerShell 静态检查，不能声称双平台实跑通过。

## 6. 验收清单

- 默认 issue provider 是 `linear`
- 模板中的全部 skills 已复制到目标 `.agents/skills/`
- `.agents/PLANS.md`、plans、state、runs 和 `docs/test/` 已生成
- `issue_provider=repo` 才生成 `docs/issues/`
- 默认没有 `Makefile`、`docs/harness/`、`scripts/harness/`、prompts、guides 或 agent adapter
- 生成文件不含未替换的项目占位符
- 用户现有文件和未提交改动未被静默覆盖
- 目标项目的真实验证与初始化器验证分别报告

## 7. 常见错误

- 继续把默认输出当作 Harness 控制面
- 把外部 Issue provider 元数据误认为已经写入 Issue
- 删除 `.agents` 的 plans、skills、state 或 runs 辅助面
- 未检查工作区就使用 force
- 只更新 Bash，不同步 PowerShell 和契约测试
- 没有 PowerShell runtime 却声称双平台实跑通过
