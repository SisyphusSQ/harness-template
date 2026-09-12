# 更新记录

## v0.7.0（2026-09-12）

- 默认初始化从 22 个文件收敛到 9 个，四个通用技能独立为 project-workflows 可选插件包；支持 --skill 选择仓库副本。
- Bash、PowerShell 共用 Python 标准库实现，环境要求 Python 3.10+。
- 默认保留现有业务文件，.gitignore 只维护标记块；覆盖改为逐文件 --overwrite，取消 --force 自动覆盖与旧文件清理。
- 合并重复授权与验证规则，按任务使用计划、恢复记录和 runbook。
- 归档支持 issue_id 与无 Issue 计划的显式完成路径；缺少完成证据默认跳过，并修复移动计划内的引用更新。
- 发版辅助工具不再把 go.mod 或普通 manifest 变化直接判为版本变更；纯版本写入拒绝清单文件及越界路径。
- 用行为契约覆盖真实输出、保留/覆盖、符号链接、归档及版本变更；移除固定文件数与禁词门禁。
- 旧控制面源改由历史 tag 提供；迁移按文件归属核对，普通初始化不删除 Makefile 或历史证据。

历史版本见 [GitHub Releases](https://github.com/SisyphusSQ/harness-template/releases)。
