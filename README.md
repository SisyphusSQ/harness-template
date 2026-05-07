# Harness 初始化基线

这个目录当前包含 5 类维护源：

- [template/](template/)：初始化到目标项目时的 base harness 输出源
- [scripts/init_harness_project.sh](scripts/init_harness_project.sh)：只负责 base harness 落盘的初始化脚本
- [sources/gitignore/](sources/gitignore/)：`.gitignore` 拼装片段
- `sources/agent_adapters/`：按 agent 类型补充的适配层，例如 Cursor project rules
- `sources/agent_extensions/`：仅供 agent 驱动初始化时补充 `.agent/prompts/` 与 `.agent/guides/` 的维护源

根目录另外保留一个 agent 使用入口：

- [agent-init-project.md](agent-init-project.md)：给 agent 初始化整个项目用的执行手册 + 可直接复制 Prompt

## 目标项目默认输出

纯脚本初始化后，默认只落一套 base harness：

```text
repo/
├── .gitignore
├── AGENTS.md
├── README.md
├── Makefile
├── docs/
│   ├── harness/
│   │   ├── control-plane.md
│   │   ├── issue-workflow.md
│   │   ├── linear.md
│   │   └── project-constraints.md
│   ├── issues/
│   │   ├── README.md
│   │   └── TEMPLATE.md
│   └── test/
│       └── RUNBOOK_TEMPLATE.md
├── .agent/
│   ├── PLANS.md
│   ├── plans/TEMPLATE.md
│   ├── plans/EXAMPLE-implementation.md
│   ├── state/TEMPLATE.md
│   └── runs/TEMPLATE.md
└── scripts/harness/
```

其中 plan 相关的三层关系固定为：

- `.agent/PLANS.md`：协议，定义什么时候要写 plan、最小 contract 和写法约束
- `.agent/plans/TEMPLATE.md`：主模板，可直接填写，默认按“实现优先”结构组织
- `.agent/plans/EXAMPLE-implementation.md`：质量标杆，展示一份更像真实实施方案的 plan 应该写成什么样

## Agent 驱动补充层

如果是 Cursor 驱动初始化，在 base harness 完成后，先补充：

- `.cursor/rules/harness.mdc`

这个文件来自 `sources/agent_adapters/cursor/`，是 Cursor 专属适配层，不属于 base harness，也不由初始化脚本默认生成。

如果是 agent 驱动初始化，再由 agent 追问用户：

- 生成占位文件
- 或生成完整模板

随后补充：

- `.agent/prompts/README.md`
- `.agent/prompts/issue-standard-workflow.md`
- `.agent/prompts/loop-codex.md`
- `.agent/prompts/loop-automation.md`
- `.agent/prompts/maintenance-loop.md`
- `.agent/guides/code-review.md`
- `.agent/guides/linter.md`

## 当前原则

- `docs/harness/` 只承载控制面真相、Issue Workflow、Issue Tracker profile 与项目级机械约束登记，不再承载 prompt 模板
- `docs/issues/` 是 `issue-provider=repo` 时的仓库内 issue 存储
- `docs/harness/project-constraints.md` 是项目级机械约束登记入口，初始化后需要按真实项目补齐
- prompt 模板统一放在 `.agent/prompts/`
- `maintenance-loop.md` 属于 agent 扩展 prompt，默认 `report-only`，不新增自动修复脚本；只有用户显式指定才进入 `issue-create / safe-fix / rule-promotion`
- code-review 与 linter 说明统一放在 `.agent/guides/`
- `Issue Tracker = 主协作真相`
- `repo = 主执行真相`
- `.agent/` 的 base 输出默认初始化计划协议、计划模板、实现型 exemplar，以及本地辅助运行面模板
- `.agent/state` / `.agent/runs` 是本地辅助运行面，不替代 Issue Tracker
- `.cursor/rules/harness.mdc` 只作为 Cursor adapter，负责把 Cursor 导向仓库内 harness 真相文件
- `.gitignore` 必须在第一次提交前就完成初始化
- `scripts/harness/` 中的 gate 脚本初始化后必须能真实执行，不能只靠关键字检查过关
- `sources/agent_adapters/` 只给特定 agent 使用，不进入 `init_harness_project.sh` 的 managed files
- `sources/agent_extensions/` 只给 agent 使用，不进入 `init_harness_project.sh` 的 managed files

## 推荐用法

1. 先读 [init-harness-project-sop.md](init-harness-project-sop.md)
2. 跑 `scripts/init_harness_project.sh`
3. 若初始化 agent 是 Cursor，再从 `sources/agent_adapters/cursor/` 补 `.cursor/rules/harness.mdc`
4. 若是 agent 驱动初始化，再从 `sources/agent_extensions/shared/` 与 `sources/agent_extensions/{placeholder|full}/` 补 `.agent/prompts/` 和 `.agent/guides/`
5. 阅读 `docs/harness/issue-workflow.md`；若无外部 issue 工具，使用 `docs/issues/TEMPLATE.md`
6. 阅读并补齐 `docs/harness/project-constraints.md` 中的项目级机械约束登记表
7. 若存在 `.agent/prompts/maintenance-loop.md`，确认默认 mode 仍是 `report-only`
8. 优先阅读 `.agent/PLANS.md`、`.agent/plans/TEMPLATE.md`、`.agent/plans/EXAMPLE-implementation.md`
9. 最后执行 `make harness-verify`

更推荐的 agent 用法是：

1. 先读 [agent-init-project.md](agent-init-project.md)
2. 再按其中步骤执行 base init + agent adapter + 扩展层补齐
