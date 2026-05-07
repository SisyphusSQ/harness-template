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
- `placeholder/`：占位文件版本
- `full/`：完整 starter 模板版本

## 使用规则

1. 先执行 base harness 初始化脚本
2. 再由 agent 询问用户：补占位文件还是完整模板
3. 复制 `shared/` + 选中模式目录下的文件到目标仓库

固定规则：

- 这些文件不由脚本默认生成
- mode-sensitive 文件必须带 `Mode: placeholder|full`
- `.agent/prompts/README.md` 是共享稳定文件，不带 `Mode`
- `.agent/prompts/maintenance-loop.md` 默认 `report-only`，只在用户显式指定时进入 `issue-create / safe-fix / rule-promotion`
