---
name: project-plan-archive
description: 当需要归档 `.agents/plans/` 根目录下已完成的日期计划文件时使用；先由 agent 按当前 issue provider 查证完成态，再用本 skill 做 dry-run 归档、ISO 周目录移动和旧 plan 路径精确改写。
---

# Project Plan Archive

用于项目内 `.agents/plans/` 计划文件的归档与旧路径修复。

核心规则：先查 Issue Tracker，再归档；默认只做 dry-run，只有显式 `--write` 才允许移动文件和改写引用。

## 第一步

1. 先读取根级 `AGENTS.md` 和 `.agents/PLANS.md`。
2. 确认当前 `issue-provider` 和需要查证的 issue key。
3. 先做只读检查：

```bash
python3 .agents/skills/project-plan-archive/scripts/project_plan_archive.py inspect \
  --repo "$PWD" --json
```

## 固定执行链

1. 先运行 `inspect`，只看 `.agents/plans/*.md` 根级日期计划文件。
2. 从每个候选计划按顺序提取 `execution_issue`、`master_issue`，不使用 `issue_targets` 做归档判定。
3. agent 按当前 `issue-provider` 查证 issue 完成态；脚本不直接连接 Linear、GitHub、GitLab 或其他外部系统。
4. 把已完成 issue 列表传给 `archive` 做 dry-run；只有确认后才加 `--write`。
5. 写入后运行 `git diff --check` 和项目要求的 harness / test gate。

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
| 周目录格式 | `YYYY-Www`，例如 `2026-W18` |
| issue 字段 | 优先 `execution_issue`，缺失时再看 `master_issue` |
| 引用修复 | 只做旧 plan 路径到新路径的精确字符串替换 |
| 扫描面 | 所有 git-tracked 文本文件，外加 `.agents/runs/**/*.md`、`.agents/state/**/*.md` |
| 禁止行为 | 不做标题模糊修复，不碰二进制、日志、构建产物，不直接查询或修改 Issue Tracker |

## 结果分类

`archive` 输出必须显式区分：

- `eligible`：有 issue 且 issue 已查证完成，可归档。
- `skipped_not_done`：有 issue，但未传入 `--done-issue`。
- `skipped_malformed`：文件名、日期或目标路径异常，或目标文件已存在。
- `no_issue_default_archive`：没有可用 issue，按默认规则可归档。
- `rewritten_refs`：命中的旧路径引用及其改写结果。

## 红线

- Issue Tracker 不可用且存在带 issue 的候选计划时，不允许直接执行 `--write`。
- 不允许把未完成 issue 对应的计划移动到 `completed/`。
- 不允许顺手归档模板、示例、日志、二进制或其他非计划文件。
