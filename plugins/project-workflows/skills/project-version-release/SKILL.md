---
name: project-version-release
description: 项目明确采用 Unreleased CHANGELOG 和纯 VERSION 文件约定时维护发布记录；不接管项目原有发版工具，不因依赖清单变化自动升版。
---

# 版本与发布记录

先读取工作项目 AGENTS.md 和发布约定。当前用户指令、指定版本与已有授权优先；项目采用其它发布格式或工具时使用项目入口，不强制迁移到本技能。

SKILL_ROOT 是本次读取的 SKILL.md 所在绝对目录。脚本从实际安装目录调用，--repo 指向工作项目。

```bash
python3 "$SKILL_ROOT/scripts/project_version_release.py" check --repo "$PWD" --json
python3 "$SKILL_ROOT/scripts/project_version_release.py" classify --repo "$PWD" --changed-files <路径...> --json
```

classify 只给出变化提示：go.mod 不代表 release version；package.json 等清单需要查看实际版本字段，结果列在 version_review_files。不能仅凭文件名决定升版。

## 变更规则

- Issue 完成可追加 Unreleased；只有真实发布意图才归档 release。
- 版本号来自用户明确指定或项目已经授权的版本策略，来源不清时询问。
- changelog-add、release-archive、version-bump 支持预览，添加 --write 才写入；已有明确授权时自行完成预览和执行，不重复确认。
- version-bump 只接受仓库内内容为 SemVer 的 VERSION/version.txt。package.json、pyproject.toml 等使用项目原生工具编辑。
- 不执行 git push、不发布产物、不连接外部系统；任务另有交付授权时使用对应发布入口。
- 验证范围服从项目与用户要求。开发阶段按影响验证，提交/发版收尾复用结果，不自动重新跑测试。

CHANGELOG 格式见 references/project-version-policy.md。
