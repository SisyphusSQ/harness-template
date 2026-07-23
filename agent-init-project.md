# Agent 初始化项目

本文件是 agent 使用的执行入口。它负责调用 base initializer，并补充特定 agent adapter 与 prompts / guides。

## 输入

开始前确认：

- Harness 根目录与目标仓库的绝对路径
- 项目名称
- 技术栈：`go`、`python`、`java`、`c` 及仓库支持的组合栈
- merge provider：`neutral`、`github`、`gitlab`
- issue provider：`linear`、`github`、`gitlab`、`repo`、`other`
- issue prefix
- agent 类型：`codex`、`cursor`、`other`
- 扩展模式：默认 `full`；只有用户明确要求轻量占位时使用 `placeholder`

能从仓库和用户指令确认的输入先自行读取；会改变项目语义且无法可靠判断的输入再询问。

## 执行顺序

### 1. 读取目标仓规则和工作区

- 读取适用的 `AGENTS.md`。
- 检查 Git 状态和已有文件。
- 保留用户改动，不 reset、restore 或覆盖。
- 初始化脚本会写入目标仓；执行前说明目标路径和覆盖边界。

### 2. 执行 base initializer

macOS、Linux、Git Bash：

```bash
bash <HARNESS_ROOT>/scripts/init_harness_project.sh \
  --target /abs/path/to/repo \
  --project-name NAME \
  --stack STACK \
  --provider PROVIDER \
  --issue-provider ISSUE_PROVIDER \
  --issue-prefix PREFIX
```

Windows PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <HARNESS_ROOT>\scripts\init_harness_project.ps1 `
  -Target C:\path\to\repo `
  -ProjectName NAME `
  -Stack STACK `
  -Provider PROVIDER `
  -IssueProvider ISSUE_PROVIDER `
  -IssuePrefix PREFIX
```

Bash 使用 POSIX 路径；PowerShell 使用 Windows 或 UNC 路径，不互相转换。

脚本完成后至少确认：

- `AGENTS.md`、业务占位 `README.md`
- `docs/harness/control-plane.md`
- `docs/issues/`、`docs/test/RUNBOOK_TEMPLATE.md`
- `.agents/PLANS.md`、plans、skills、state 和 runs 模板
- `scripts/harness/` 的 Bash 与 PowerShell gate

初始化后把项目真实 build、test、lint、live E2E、禁止范围和发布入口写入 `AGENTS.md` 的“项目约束”，不要新建 constraints 登记文件。

### 3. 按 agent 类型补 adapter

- `cursor`：复制 `sources/agent_adapters/cursor/.`，确认 `.cursor/rules/harness.mdc` 存在且 `alwaysApply: true`。
- `codex` / `other`：不生成 Cursor adapter。

### 4. 补 prompts 与 guides

复制：

```text
sources/agent_extensions/shared/.
sources/agent_extensions/{full|placeholder}/.
```

目标文件固定为：

```text
.agents/prompts/README.md
.agents/prompts/issue-standard-workflow.md
.agents/prompts/orchestrator-thread.md
.agents/guides/code-review.md
.agents/guides/linter.md
```

四个 mode-sensitive 文件必须使用同一个 `Mode: full|placeholder`；Prompt README 不带 Mode。

### 5. 验证

在目标仓运行：

```bash
make harness-verify
```

PowerShell 可直接运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1
```

随后执行项目自身 build、test、lint 和任务要求的 live / integration 验证。

## 停止条件

遇到以下情况停止并报告：

- 目标路径不是对应平台的绝对路径
- 技术栈或 provider 无法可靠判断
- 工作区现有改动会被覆盖
- base initializer 失败
- extension 只复制了一部分或混用了 Mode
- 目标仓 Harness gate 失败

报告当前步骤、准确错误、已产生的副作用和安全恢复入口。

## 可复制 Prompt

```text
把 <HARNESS_ROOT> 的 Harness 初始化到目标仓库。

先读取目标仓 AGENTS.md 和 Git 状态，保留已有改动；说明脚本将写入的目标路径。
确认项目名称、技术栈、merge provider、issue provider、issue prefix 和 agent 类型。

1. 调用对应平台的 init_harness_project 脚本完成 base 初始化。
2. 把真实项目约束写入目标仓 AGENTS.md；项目 README 只保留业务说明。
3. Cursor 项目按需复制 cursor adapter。
4. 默认复制 shared + full agent extensions；只有明确要求轻量时使用 placeholder。
5. prompts 只应包含 README.md、issue-standard-workflow.md、orchestrator-thread.md。
6. 运行 make harness-verify 或 PowerShell check.ps1，再运行项目自身验证。

不要 reset/restore 用户改动，不创建额外 constraints 文档，不恢复已删除的通用 loop prompt。
最终报告初始化目录、Mode、验证证据与未执行项。
```
