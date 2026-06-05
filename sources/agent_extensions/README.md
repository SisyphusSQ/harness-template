# Agent 扩展层维护源

这里存放的是 **仅供 agent 驱动初始化时补充** 的维护源，不属于
`init_harness_project.sh` 的 base harness managed files。

主要入口不是本文件，而是根目录的：

- [agent-init-project.md](../../agent-init-project.md)

## 目录说明

```text
sources/agent_extensions/
├── shared/
├── placeholder/
└── full/
```

- `shared/`：不区分模式的稳定文件
- `full/`：默认完整可执行模板版本
- `placeholder/`：显式轻量 / 占位文件版本

## 使用规则

1. 先执行 base harness 初始化脚本
2. agent 默认选择 `full`
3. 只有用户明确要求轻量、占位或临时项目时，才选择 `placeholder`
4. 复制 `shared/` + 选中模式目录下的文件到目标仓库

固定规则：

- 这些文件不由脚本默认生成
- mode-sensitive 文件必须带 `Mode: placeholder|full`
- `.agents/prompts/README.md` 是共享稳定文件，不带 `Mode`
- `.agents/prompts/orchestrator-thread.md` 是主 thread / 子 thread / worktree thread / subagent 编排入口；full 版给出可复制 Goal Prompt 与 Handoff Prompt，placeholder 版只保留入口和边界
- thread 工具链是 Codex 专用能力；非 Codex agent 可读取该 prompt 作为 handoff 模板和状态机约束，但不要求具备创建、读取、发送消息或改标题的 thread tools
- `.agents/prompts/maintenance-loop.md` 默认 `report-only`，只在用户显式指定时进入 `issue-create / safe-fix / rule-promotion`
