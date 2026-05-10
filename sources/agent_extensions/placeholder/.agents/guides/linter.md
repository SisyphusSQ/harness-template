Mode: placeholder

# Linter Guide（占位）

## 用途

这份文件用于记录仓库的 lint 能力应该如何接入，但当前只提供占位说明。lint 是项目级机械约束的一种载体，具体规则需要回登记到 `docs/harness/project-constraints.md`。

## 当前仍缺的 repo-local 决策

- 按技术栈选择哪些 lint 工具
- lint 命令是什么
- 配置文件放在哪里
- 是否接到 Makefile / CI / pre-commit
- lint 失败是否阻塞 verify / review
- lint 结果是否需要进入 Linear 反馈摘要
- 哪些 lint 规则需要同步登记到 `docs/harness/project-constraints.md`

## 按栈待补项

| 栈 | 待补内容 |
| --- | --- |
| `go` | 选择 `golangci-lint` 或等价方案，补命令与配置 |
| `python` | 选择 `ruff` / `pyright` 或等价方案，补命令与配置 |
| `go-node` | 同时补 Go 与 Node/前端 lint 入口 |
| `python-node` | 同时补 Python 与 Node/前端 lint 入口 |

## 固定说明

- 当前文件不是可执行 lint contract
- 未补齐前，不要在 Makefile 里假装存在 `lint` / `verify-lint`
- 未接入可执行命令前，不要在 `docs/harness/project-constraints.md` 中把对应规则标成 `enforced`
- 若后续要接入 lint，先冻结命令、配置和阻塞策略，再决定是否进 base harness
