# Agent 扩展层维护源

这些文件只在 agent 驱动初始化时复制，不属于 base initializer 的 managed files。

```text
sources/agent_extensions/
├── shared/        # 不区分 Mode 的 Prompt README
├── full/          # 默认完整 Prompt 与 guides
└── placeholder/   # 用户明确要求时使用的轻量占位版
```

复制顺序：

1. `shared/.`
2. `full/.`，或用户明确要求轻量时使用 `placeholder/.`

目标文件固定为：

```text
.agents/prompts/README.md
.agents/prompts/issue-standard-workflow.md
.agents/prompts/orchestrator-thread.md
.agents/guides/code-review.md
.agents/guides/linter.md
```

规则：

- Prompt README 不带 Mode。
- 其余四个文件必须带一致的 `Mode: full|placeholder`。
- 普通交互、automation 和 maintenance 不再各维护一份通用 loop prompt。
- thread tools 是 Codex 专用能力；其他 agent 仍可复用 Handoff 字段和共享状态契约。
- 扩展内容与 `AGENTS.md`、`docs/harness/control-plane.md` 或 `.agents/PLANS.md` 冲突时，以后三者为准。
