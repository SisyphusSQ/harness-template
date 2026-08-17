# Agent 初始化项目

本文件是 Agent 使用的执行入口。它调用极简项目初始化器，把模板中的通用协作能力同步到目标仓库，不安装 Harness 控制面或强制流程。

## 输入

开始前确认：

- 初始化器根目录与目标仓库的绝对路径
- 项目名称
- 技术栈：`go`、`python`、`java`、`c` 及脚本支持的组合栈
- issue provider：默认 `linear`；也可指定 `github`、`gitlab`、`repo` 或 `other`
- 可选 issue prefix

能从仓库和用户指令确认的输入先自行读取；会改变项目语义且无法可靠判断的输入再询问。

## 执行顺序

### 1. 读取目标仓规则和工作区

- 读取适用的 `AGENTS.md`。
- 检查 Git 状态和已有文件。
- 保留用户改动，不 reset、restore 或静默覆盖。
- 执行前说明目标路径、写入范围和是否使用 force。

### 2. 执行初始化器

macOS、Linux、Git Bash：

```bash
bash <INIT_ROOT>/scripts/init_harness_project.sh \
  --target /abs/path/to/repo \
  --project-name NAME \
  --stack STACK \
  --issue-provider linear \
  --issue-prefix PREFIX
```

Windows PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <INIT_ROOT>\scripts\init_harness_project.ps1 `
  -Target C:\path\to\repo `
  -ProjectName NAME `
  -Stack STACK `
  -IssueProvider linear `
  -IssuePrefix PREFIX
```

默认初始化内容是：

- `AGENTS.md` 与业务 `README.md` 占位
- `.agents/PLANS.md`、`plans/`、`state/`、`runs/`
- `template/.agents/skills/` 下的全部 skills 及其辅助文件
- `docs/test/RUNBOOK_TEMPLATE.md`
- `issue_provider=repo` 时的 `docs/issues/`
- 按技术栈生成的 `.gitignore`

默认不生成 `docs/harness/`、`scripts/harness/`、Harness prompts/guides、Makefile、agent adapter 或强制 gate。初始化器也不会连接外部 Issue 系统、提交、推送或运行目标项目验证。

### 3. 初始化后补项目事实

在目标 `AGENTS.md` 中补充真实的：

- 项目结构和开发入口
- build、test、lint、integration / live E2E 命令
- 必须遵守的安全、权限、数据和发布边界
- 失败恢复与清理方式

复杂任务按需在 `.agents/plans/` 创建计划；需要本地状态或运行摘要时使用 `.agents/state/` 与 `.agents/runs/`。这三类文件是辅助面，不会自动组成强制状态机。

### 4. 验证

源仓维护时运行：

```bash
make verify
```

目标仓不再有统一 Harness check；按目标项目 `AGENTS.md` 中的真实命令验证，并分别报告未执行项和外部依赖。

## 停止条件

遇到以下情况停止并报告：

- 目标路径不是对应平台的绝对路径
- 技术栈或 issue provider 无法可靠判断
- 工作区现有文件会被覆盖且没有显式 force
- 初始化器失败
- 目标仓存在旧版声明的 managed Harness 文件，但未获准使用 force 清理

报告当前步骤、准确错误、已产生的副作用和安全恢复入口。

## 可复制 Prompt

```text
把 <INIT_ROOT> 的项目初始化模板同步到目标仓库。

先读取目标仓 AGENTS.md 和 Git 状态，保留已有改动；说明脚本将写入的目标路径和覆盖边界。
确认项目名称、技术栈、issue provider（默认 linear）和 issue prefix。

1. 调用对应平台的 init_harness_project 脚本。
2. 确认模板中的全部 skills、.agents/PLANS.md、plans、state、runs 和 docs/test 已同步。
3. 把真实项目约束补入目标 AGENTS.md；项目 README 只保留业务说明。
4. 仅当 issue provider 为 repo 时使用 docs/issues/ 模板。
5. 不生成 Harness 控制面、scripts/harness、prompts/guides、Makefile 或强制 gate。
6. 按目标项目真实命令执行需要的验证；不要把初始化完成写成项目测试通过。

不要 reset/restore 用户改动，不连接外部 Issue 系统，不创建额外 constraints 文档。
最终报告初始化目录、实际生成的文件、验证证据与未执行项。
```
