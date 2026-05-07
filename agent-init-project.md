# Agent 初始化整个项目入口

本文件是给 agent 使用的总入口，用于把当前 harness 维护源完整初始化到一个目标仓库中。

它承担两件事：

1. 执行手册
2. 可直接复制给 agent 的完整 Prompt 模板

固定规则：

- 本文件位于当前 harness 维护源根目录，不属于目标项目模板，不会被初始化脚本复制到目标仓库
- `init_harness_project.sh` 与 `init_harness_project.ps1` 只负责 base harness
- `sources/agent_adapters/` 是按 agent 类型补充的适配层，不属于 base harness
- `.agent/prompts/` 与 `.agent/guides/` 由 agent 在 base harness 完成后补齐
- `.agent/skills/` 不是 base harness 输出，只在项目需要稳定复用的 repo-local 专门流程时另行补充

## 1. 执行手册

### 1.1 初始化前需要收集的输入

在开始前，agent 需要确认：

- 当前 harness 维护源绝对路径（下文记作 `<HARNESS_ROOT>`）
- 目标仓库绝对路径
- 项目名称
- 技术栈：`go` / `python` / `java` / `c` / `go-node` / `python-node` / `java-node` / `c-node` / `java-c` / `java-c-node`
- provider：`neutral` / `github` / `gitlab`
- issue provider：`linear` / `github` / `gitlab` / `repo` / `other`，默认 `linear`
- issue prefix
- 初始化 agent 类型：`codex` / `cursor` / `other`
- agent 扩展层模式：
  - `placeholder`
  - `full`

若上述信息有缺口：

- 能从仓库路径、现有文件、用户指令里推断的，先自行探索
- 只有扩展层模式这种偏好型问题需要明确问用户；若用户未明确选择，默认 `placeholder`

### 1.2 固定执行顺序

1. 先执行 base harness 初始化脚本  
   macOS / Linux / Git Bash 命令形如：

   ```bash
   bash <HARNESS_ROOT>/scripts/init_harness_project.sh \
     --target /abs/path/to/repo \
     --project-name NAME \
     --stack go|python|java|c|go-node|python-node|java-node|c-node|java-c|java-c-node \
     --provider neutral|github|gitlab \
     --issue-provider linear|github|gitlab|repo|other \
     --issue-prefix PREFIX
   ```

   Windows PowerShell 命令形如：

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File <HARNESS_ROOT>\scripts\init_harness_project.ps1 `
     -Target C:\path\to\repo `
     -ProjectName NAME `
     -Stack go|python|java|c|go-node|python-node|java-node|c-node|java-c|java-c-node `
     -Provider neutral|github|gitlab `
     -IssueProvider linear|github|gitlab|repo|other `
     -IssuePrefix PREFIX
   ```

   路径规则固定：Bash / Git Bash 使用 `/abs/path` 或 `/c/path`；PowerShell 使用 `C:\path\to\repo` 或 `\\server\share\repo`；两个入口不互相转换路径。

2. 确认 base harness 初始化成功，至少包含：

   - `docs/harness/control-plane.md`
   - `docs/harness/issue-workflow.md`
   - `docs/harness/linear.md`
   - `docs/harness/project-constraints.md`
   - `docs/issues/README.md`
   - `docs/issues/TEMPLATE.md`
   - `docs/test/RUNBOOK_TEMPLATE.md`
   - `.agent/PLANS.md`
   - `.agent/plans/TEMPLATE.md`
   - `.agent/plans/EXAMPLE-implementation.md`
   - `.agent/state/TEMPLATE.md`
   - `.agent/runs/TEMPLATE.md`
   - `scripts/harness/check.sh`
   - `scripts/harness/common.sh`
   - `scripts/harness/review_gate.sh`
   - `scripts/harness/check.ps1`
   - `scripts/harness/common.ps1`
   - `scripts/harness/review_gate.ps1`

   同时确认当前 base harness 的计划 contract 已经可读出：

   - `.agent/PLANS.md` 明确 plan 可以继续使用 `## Architecture / Data Flow`，也可以使用推荐标题 `## 0. 现有架构回顾与核心设计决策`
   - `TEMPLATE.md` 已切到“实现优先”骨架，正文默认按
     `0. 现有架构回顾与核心设计决策 -> 1..N 改动面 -> 数据流可视化 -> 关键设计决策摘要 -> 与现有代码的关系`
   - `EXAMPLE-implementation.md` 是官方质量标杆，可直接对照风格和密度
   - 实现骨架需要补齐
     `真实入口与触发 / 输入装配与边界校验 / 组件职责与代码落点 / 关键执行时序 / 停止 / 错误 / 恢复`
   - `Concrete Steps` 需要拆成 `### 实现步骤` 与 `### 验证与收口步骤`
   - `review_gate.sh` / `review_gate.ps1` 会对 plan 做结构型轻量 lint，而不只检查 `blocking_findings`
   - `Reference Snippets` 不能是空块或纯占位内容
   - `组件职责与代码落点` 至少要有一条真实模块 / 路径 / 类型记录
   - `docs/harness/project-constraints.md` 是项目级机械约束登记入口，不能把只有文档约束的规则写成 `enforced`
   - `docs/test/RUNBOOK_TEMPLATE.md` 能作为测试 runbook、执行副作用、清理结果和脱敏结果回写模板

3. 在 base harness 完成后，按初始化 agent 类型补充 adapter：

   - 若 agent 类型是 `cursor`，复制：
     - `sources/agent_adapters/cursor/.`
   - 复制后确认目标仓库存在 `.cursor/rules/harness.mdc`
   - 确认 Cursor rule 使用中文 `description`、中文正文和 `alwaysApply: true`
   - 若 agent 类型是 `codex` 或 `other`，不生成 `.cursor/`
   - Cursor adapter 不依赖 `.agent/prompts/` 的 `placeholder` / `full` 模式

4. 确定 agent 扩展层模式：

   - 询问用户使用 `placeholder` 还是 `full`
   - 若用户未明确选择，默认 `placeholder`
   - 复制：
     - `sources/agent_extensions/shared/.`
     - `sources/agent_extensions/{placeholder|full}/.`

5. 扩展层补齐后，确认目标仓库存在：

   - `.agent/prompts/README.md`
   - `.agent/prompts/issue-standard-workflow.md`
   - `.agent/prompts/loop-codex.md`
   - `.agent/prompts/loop-automation.md`
   - `.agent/prompts/maintenance-loop.md`
   - `.agent/guides/code-review.md`
   - `.agent/guides/linter.md`

6. 对 6 个 mode-sensitive 文件检查：

   - 都带 `Mode: placeholder` 或 `Mode: full`
   - mode 必须一致

7. 额外确认控制面文档里已经能看出 truth split：

   - `docs/harness/control-plane.md` 能读出：
     - `Issue Tracker 是主协作真相`
     - `repo 是主执行真相`
   - `docs/harness/issue-workflow.md` 能读出：
     - 运行反馈默认写回 Issue Tracker
     - `recovery_point` / `next_action` 默认落 Issue Tracker
   - `docs/harness/linear.md` 能读出它只是 Linear profile / migration note
   - `docs/issues/TEMPLATE.md` 能读出 repo issue 固定字段和 `writeback_log`
   - `docs/harness/project-constraints.md` 能读出：
     - 状态枚举和分类枚举
     - `maintenance_candidate`、`rule_promotion_candidate`、`human_decision_required`
     - `project-check` 挂载协议
     - 没有可执行命令或 gate 时不得假装 `enforced`
   - `.agent/prompts/maintenance-loop.md` 能读出：
     - 默认 mode 是 `report-only`
     - 只有用户显式指定才进入 `issue-create / safe-fix / rule-promotion`
     - API contract、schema、安全策略和业务行为不能自动修
   - `.agent/state/TEMPLATE.md` 与 `.agent/runs/TEMPLATE.md` 能读出：
     - 它们是本地辅助运行面
     - 不替代 Issue Tracker
   - `docs/test/RUNBOOK_TEMPLATE.md` 能读出：
     - 测试文档默认是可执行 runbook
     - 提交版文档只保留脱敏结果摘要
     - 未执行步骤不得写成已通过
   - `.agent/PLANS.md` 与 `.agent/plans/TEMPLATE.md` 能读出：
     - 计划必须显式写实现逻辑骨架
     - 不能用 harness 控制流替代 `Architecture / Data Flow`
   - `.agent/plans/EXAMPLE-implementation.md` 能作为实现型 plan 的参考范式

8. 最后进入目标仓库执行：

   ```bash
   make harness-verify
   ```

   Windows PowerShell 环境不要求安装 `make`，可执行：

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1
   ```

### 1.3 何时应停止并报告

遇到以下情况应先停下，不要继续硬做：

- 目标路径不是绝对路径
- 无法判断技术栈
- 用户对扩展层模式没有明确选择且你不能合理默认
- base harness 初始化失败
- Cursor adapter 补齐后 `.cursor/rules/harness.mdc` 缺少 `alwaysApply: true` 或关键导航入口
- 扩展层补齐后出现半套文件或 mode 混用

此时应向用户明确报告：

- 当前停在哪一步
- 缺了什么输入或哪一步失败
- 下一步需要用户补什么信息

## 2. 可直接复制的完整 Prompt 模板

```text
使用前先把 `<HARNESS_ROOT>` 替换为当前 harness 维护源的绝对路径。

你要把 `<HARNESS_ROOT>` 这套维护源完整初始化到目标仓库。

执行要求：
1. 先只做 base harness 初始化，不要直接补 prompts / guides。
2. 使用：
   - `<HARNESS_ROOT>/scripts/init_harness_project.sh`
   - Windows PowerShell 可改用 `<HARNESS_ROOT>\scripts\init_harness_project.ps1`
3. 初始化前先确认这些输入：
   - 目标仓库绝对路径
   - 项目名称
   - 技术栈：go / python / java / c / go-node / python-node / java-node / c-node / java-c / java-c-node
   - provider：neutral / github / gitlab
   - issue provider：linear / github / gitlab / repo / other
   - issue prefix
   - 初始化 agent 类型：codex / cursor / other
4. base harness 完成后，按初始化 agent 类型补充 adapter：
   - 如果是 cursor，复制 `<HARNESS_ROOT>/sources/agent_adapters/cursor/.`
   - 确认 `.cursor/rules/harness.mdc` 存在
   - 确认 `.cursor/rules/harness.mdc` 使用中文 `description`、中文正文和 `alwaysApply: true`
   - 如果是 codex 或 other，不生成 `.cursor/`
5. 再询问用户：
   - agent 扩展层用 placeholder 还是 full
   - 若用户未明确选择，默认 placeholder
6. 然后复制：
   - `<HARNESS_ROOT>/sources/agent_extensions/shared/.`
   - `<HARNESS_ROOT>/sources/agent_extensions/{placeholder|full}/.`
7. 扩展层补齐后，必须确认以下文件全部存在：
   - `.agent/prompts/README.md`
   - `.agent/prompts/issue-standard-workflow.md`
   - `.agent/prompts/loop-codex.md`
   - `.agent/prompts/loop-automation.md`
   - `.agent/prompts/maintenance-loop.md`
   - `.agent/guides/code-review.md`
   - `.agent/guides/linter.md`
8. 对以下 6 个文件检查 mode：
   - `.agent/prompts/issue-standard-workflow.md`
   - `.agent/prompts/loop-codex.md`
   - `.agent/prompts/loop-automation.md`
   - `.agent/prompts/maintenance-loop.md`
   - `.agent/guides/code-review.md`
   - `.agent/guides/linter.md`
   要求：
   - 都带 `Mode: placeholder` 或 `Mode: full`
   - mode 必须一致
9. 额外确认：
   - `docs/harness/control-plane.md` 已明确 `Issue Tracker 是主协作真相`
   - `docs/harness/control-plane.md` 已明确 `repo 是主执行真相`
   - `docs/harness/issue-workflow.md` 已明确运行反馈与结果回写默认写回 Issue Tracker
   - `docs/harness/linear.md` 已明确它是 Linear profile / migration note
   - `docs/issues/TEMPLATE.md` 已存在，可作为 repo issue 和 `writeback_log` 模板
   - `docs/harness/project-constraints.md` 已存在，且明确项目级机械约束登记、状态枚举、分类枚举、`project-check` 挂载协议和不得假装 `enforced`
   - `.agent/prompts/maintenance-loop.md` 已存在，默认 `report-only`，且只有用户显式指定时才进入 `issue-create / safe-fix / rule-promotion`
   - `.agent/PLANS.md` 与 `.agent/plans/TEMPLATE.md` 已明确
     `真实入口与触发 / 输入装配与边界校验 / 组件职责与代码落点 / 关键执行时序 / 停止 / 错误 / 恢复`
   - `.agent/plans/EXAMPLE-implementation.md` 已存在，可作为质量标杆
   - `docs/test/RUNBOOK_TEMPLATE.md` 已存在，可作为测试 runbook 和脱敏结果回写模板
   - `review_gate.sh` / `review_gate.ps1` 已明确会拒绝只有 harness 流程、没有实现骨架的 plan
   - `review_gate.sh` / `review_gate.ps1` 已明确会拒绝空的 `Reference Snippets` 和空的组件职责记录
   - `.agent/state/TEMPLATE.md` 与 `.agent/runs/TEMPLATE.md` 已明确它们只是本地辅助运行面
   - `.agent/skills` 未作为 base 必备输出；如项目需要 repo-local skill，应单独说明来源和使用边界
   - 如果生成了 `.cursor/rules/harness.mdc`，它已明确读取 harness 入口并要求 `make harness-verify`
10. 最后在目标仓库执行 `make harness-verify`；Windows PowerShell 可执行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1`

输出要求：
1. 先说明当前在做 base harness、agent adapter 还是 agent 扩展层
2. 若需要用户选择扩展层模式，先问，不要自己乱猜
3. 完成后明确列出：
   - base harness 是否完成
   - Cursor adapter 是否按 agent 类型处理
   - 扩展层是否补齐
   - 当前使用的是 placeholder 还是 full
   - `PLANS.md / TEMPLATE.md / EXAMPLE-implementation.md` 三层关系是否已经可读
   - `docs/test/RUNBOOK_TEMPLATE.md` 是否已经就位
   - `docs/harness/project-constraints.md` 是否已经就位并提醒使用者后续按项目真实规则补齐
   - truth split 是否已经在 control-plane / issue-workflow 中可读
   - 最终验证是否通过
4. 若失败，明确指出失败步骤、报错和下一步建议
```
