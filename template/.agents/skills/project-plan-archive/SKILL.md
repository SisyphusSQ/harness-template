---
name: project-plan-archive
description: 当需要归档 `.agents/plans/` 根目录下已完成的日期计划文件时使用；先按当前 issue provider 查证完成态，再做 dry-run 归档和旧路径修复。
---

# Project Plan Archive

用于项目内 `.agents/plans/` 计划文件的归档与旧路径修复。

核心规则：先查 Issue provider，再归档；默认只做 dry-run，只有显式 `--write` 才允许移动文件和改写引用。

## 第一步

1. 先读取根级 `AGENTS.md` 和 `.agents/PLANS.md`；
2. 确认当前 `issue_provider` 和需要查证的 issue key；
3. 先做只读检查：

```bash
python3 .agents/skills/project-plan-archive/scripts/project_plan_archive.py inspect \
  --repo "$PWD" --json
```

## 固定执行链

1. 先运行 `inspect`，只看 `.agents/plans/*.md` 根级日期计划文件；
2. 从每个候选计划按顺序提取 `execution_issue`、`master_issue`；
3. agent 按当前 issue provider 查证 issue 完成态；脚本不直接连接外部系统；
4. 把已完成 issue 列表传给 `archive` 做 dry-run；只有确认后才加 `--write`；
5. 写入后运行项目要求的文档或测试检查。

## 快速命令

```bash
python3 .agents/skills/project-plan-archive/scripts/project_plan_archive.py inspect \
  --repo "$PWD" --json

python3 .agents/skills/project-plan-archive/scripts/project_plan_archive.py archive \
  --repo "$PWD" \
  --done-issue ISSUE-123 \
  --json

python3 .agents/skills/project-plan-archive/scripts/project_plan_archive.py archive \
  --repo "$PWD" \
  --done-issue ISSUE-123 \
  --write --json
```

## 归档规则

| 项目 | 固定规则 |
| --- | --- |
| 候选范围 | 只看 `.agents/plans/` 根目录下带 `YYYY-MM-DD-` 前缀的 `.md` 文件 |
| 永不移动 | `TEMPLATE.md`、`EXAMPLE-implementation.md`、已经在 `completed/` 下的文件 |
| 目标路径 | `.agents/plans/completed/<ISO周>/<原文件名>` |
| 引用修复 | 只做旧计划路径到新路径的精确字符串替换 |
| 扫描面 | 所有 git-tracked 文本文件，以及存在时的 `.agents/runs/**/*.md`、`.agents/state/**/*.md` |
| 禁止行为 | 不做标题模糊修复，不碰二进制、日志、构建产物，不直接查询或修改 Issue provider |

## 红线

- Issue provider 不可用且存在带 issue 的候选计划时，不允许直接执行 `--write`；
- 不允许把未完成 issue 对应的计划移动到 `completed/`；
- 不允许顺手归档模板、示例、日志、二进制或其它非计划文件。
