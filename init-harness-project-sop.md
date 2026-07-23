# Harness 初始化 SOP

本 SOP 面向人工操作和 Harness 维护者。Agent 执行入口见 `agent-init-project.md`。

## 1. 目标

初始化后，业务项目获得：

- 根级 `AGENTS.md` 和不含 Harness 信息的业务 `README.md`
- 单一 `docs/harness/control-plane.md`
- 计划、状态、运行摘要和四个 repo-local skills
- 本地 Issue 与测试 runbook 模板
- Bash / PowerShell Harness gate
- agent 驱动场景下的两个 Prompt 与两份 guide

不再生成：

```text
docs/harness/issue-workflow.md
docs/harness/linear.md
docs/harness/project-constraints.md
.agents/prompts/loop-codex.md
.agents/prompts/loop-automation.md
.agents/prompts/maintenance-loop.md
```

## 2. 初始化参数

| 参数 | 允许值 |
| --- | --- |
| stack | `go`、`python`、`java`、`c` 及脚本列出的组合栈 |
| provider | `neutral`、`github`、`gitlab` |
| issue provider | `linear`、`github`、`gitlab`、`repo`、`other` |
| extension mode | `full`，或用户明确要求时使用 `placeholder` |

目标路径必须是对应平台的绝对路径。已有目标文件默认不覆盖；确认覆盖时显式使用 `--force` / `-Force`。

## 3. Base 初始化

macOS、Linux、Git Bash：

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

初始化器负责：

- 复制 `template/` 的 managed files
- 按技术栈拼装 `.gitignore`
- 替换 project、provider、issue provider 和 issue prefix 占位符
- 清理已声明废弃的 managed files（仅 force 模式）
- 设置 shell 脚本可执行位
- 运行目标仓 Harness check

初始化器不负责：

- 推断业务 build / test / lint 命令
- 创建 PR / MR、提交或推送
- 写入外部 Issue Tracker
- 执行项目 live E2E
- 复制特定 agent adapter 与 extensions

## 4. Agent 扩展层

Cursor adapter 按需复制：

```text
sources/agent_adapters/cursor/.
```

Prompt 与 guide 复制：

```text
sources/agent_extensions/shared/.
sources/agent_extensions/full/.
```

只有用户明确要求轻量占位时，把 `full` 换成 `placeholder`。

扩展层最终文件：

```text
.agents/prompts/README.md
.agents/prompts/issue-standard-workflow.md
.agents/prompts/orchestrator-thread.md
.agents/guides/code-review.md
.agents/guides/linter.md
```

## 5. 初始化后补齐

1. 保留或补充业务 README，不写 Harness 教程。
2. 在 `AGENTS.md` 填写真实项目结构、build、test、lint、live E2E、禁止范围和发布入口。
3. 确认 `docs/harness/control-plane.md` 中 provider 已替换。
4. 若 issue provider 为 `repo`，使用 `docs/issues/TEMPLATE.md`。
5. 保留 `.agents/PLANS.md`、plans 示例、skills、state/runs 模板。
6. 使用手动逐阶段流程时读 `issue-standard-workflow.md`；发生独立任务或并行交接时读 `orchestrator-thread.md`。

## 6. 验证

目标仓：

```bash
make harness-verify
git diff --check
```

PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1
```

源仓维护后：

```bash
make verify
```

源仓完整回归必须覆盖：

- source contract
- Bash / PowerShell 初始化器静态一致性
- full / placeholder 文件集合与 Mode
- fresh target 初始化和目标仓 check
- review gate 与 evidence helper 正反例
- 已删除文件不再生成或被引用

没有 PowerShell runtime 时，只能记录 Bash 实跑与 PowerShell 静态一致性。

## 7. 验收清单

- `README.md` 没有 Harness 说明
- `AGENTS.md` 包含 Harness 入口和项目真实约束
- `docs/harness/` 只有 `control-plane.md`
- `.agents/prompts/` 只有 README 和两个 Prompt
- `.agents/` 的 plans、skills、state、runs、guides 均保留
- 旧 Harness 文档与通用 loop prompt 不存在
- extension Mode 一致
- 目标仓 Harness gate 与项目自身验证分别报告
- 用户现有文件和未提交改动未被静默覆盖

## 8. 常见错误

- 把 Harness 介绍写回项目 README
- 删除状态机、Done Gate 或 required live E2E 边界
- 删除 `.agents` 的 plans、skills、state、runs 或 guides
- 在多个文档重复定义同一状态字段
- 用通用 automation / maintenance prompt 替代具体 runbook
- 只更新 Bash，不同步 PowerShell 和契约测试
- 没有 PowerShell runtime却声称双平台实跑通过
