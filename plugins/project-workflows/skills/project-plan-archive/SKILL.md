---
name: project-plan-archive
description: 用户明确要求整理已完成计划时使用；核对完成证据，预览归档路径并精确修复引用，不自动归档无 Issue 计划。
---

# 计划归档

读取工作项目的 AGENTS.md、.agents/PLANS.md 和候选计划。用户当前请求与已有授权优先，不重复请求已获得的归档授权。

把 SKILL_ROOT 设置为本次读取的 SKILL.md 所在绝对目录；共享插件与仓库副本都从这个位置调用脚本，--repo 指向工作项目。

```bash
python3 "$SKILL_ROOT/scripts/project_plan_archive.py" inspect --repo "$PWD" --json
python3 "$SKILL_ROOT/scripts/project_plan_archive.py" archive --repo "$PWD" --done-issue APP-123 --json
python3 "$SKILL_ROOT/scripts/project_plan_archive.py" archive --repo "$PWD" --done-issue APP-123 --write --json
```

先核对 Issue provider 的完成证据，再传 --done-issue。当前字段是 issue_id；已有 execution_issue/master_issue 仍可读取，优先顺序为 issue_id、execution_issue、master_issue。

没有 Issue 的计划默认进入 skipped_missing_issue。只有已经从用户指令或计划结果核实完成时，使用具体相对路径：

```bash
python3 "$SKILL_ROOT/scripts/project_plan_archive.py" archive --repo "$PWD" \
  --done-plan .agents/plans/2026-09-12-example.md --json
```

预览后在已有授权范围内添加 --write 执行，不因 dry-run 再增加审批。--done-plan 不能绕过已有 Issue 的完成要求。

## 边界

- 只处理 .agents/plans/ 根级带日期的 Markdown；模板、示例、未完成和无法核实的计划保留。
- 目标为 .agents/plans/completed/<ISO周>/<原文件名>，目标已存在时跳过。
- 精确修复 Git 跟踪文本及本地 state/runs Markdown 中的旧路径；不改二进制或越界符号链接。
- 脚本不连接或修改 Issue 系统；Git 引用清单无法读取时停止，不能宣称引用已全部修复。
- 写入后核对实际移动和引用结果；仅运行改动需要的检查，交付收尾复用已有验证。
