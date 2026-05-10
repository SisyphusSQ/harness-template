Mode: full

# Linter Guide

## 1. 目标

这份文档用于帮助仓库按技术栈补齐 lint 能力，但它本身不是“已经接通 lint”的证明。lint 是项目级机械约束的一种载体，具体规则必须回登记到 `docs/harness/project-constraints.md`。

固定规则：

- 没有冻结 repo-local 命令与配置前，不要假装仓库已有可执行 lint contract
- 是否把 lint 接进 Makefile / CI / verify，由仓库自己决定
- 若 lint 结果被采用为 gate，应把 lint 摘要写进 Linear 反馈
- 若 lint 承接项目级机械约束，应同步更新 `docs/harness/project-constraints.md` 的 `Enforcement`、`Command` 和 `Status`

## 2. 按栈候选方案

| 栈 | 候选命令 | 典型配置 |
| --- | --- | --- |
| `go` | `golangci-lint run ./...` | `.golangci.yml` |
| `python` | `ruff check .` / `pyright` | `pyproject.toml` |
| `go-node` | Go lint + `eslint .` / 前端 lint 命令 | `.golangci.yml` + `eslint.config.*` |
| `python-node` | Python lint + Node/前端 lint | `pyproject.toml` + `eslint.config.*` |

说明：

- 上表只是候选起点，不是强制命令
- 只有在仓库确认采用后，才应写进 Makefile、CI 或 verify contract

## 3. 接入顺序

建议按以下顺序补齐：

1. 冻结当前仓库真实使用的 lint 工具
2. 冻结配置文件路径
3. 冻结本地执行入口
4. 冻结是否接入 CI
5. 冻结 lint 失败是否阻塞 verify / review
6. 回写 `docs/harness/project-constraints.md`，把对应规则状态从 `documented` / `planned` 调整为真实状态

## 4. 最小决策表

| 项目 | 必须回答的问题 |
| --- | --- |
| 工具 | 用什么 lint 工具 |
| 命令 | 最终执行命令是什么 |
| 配置 | 配置文件在哪里 |
| 入口 | 手动执行 / Make / CI / pre-commit 哪些需要 |
| 阻塞性 | 是否阻塞 verify / review |

## 5. 推荐做法

- 在仓库还没稳定前，可以先只写本文件，不急着把 lint 接进 base harness
- 若 lint 规则很重，先作为手动命令验证，再决定是否升级为默认 gate
- 若未来确实稳定，再把 lint 入口提升为 repo-local verify contract 的一部分
