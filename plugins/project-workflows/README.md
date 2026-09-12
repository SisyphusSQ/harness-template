# 可选项目技能

本目录是可独立分发的 Codex 插件包，manifest 位于 .codex-plugin/plugin.json。它不会随项目初始化自动安装，也不会修改本机 marketplace。

| 技能 | 使用场景 |
| --- | --- |
| issue-goal-prompt | 用户明确要求生成交接或启动提示词 |
| project-plan-archive | 已核实完成的计划需要归档及修复引用 |
| project-version-release | 项目明确采用此 CHANGELOG/纯版本文件约定 |
| test-runbook | 集成、live、恢复等需要可复现执行记录的验证 |

共享使用时把此目录作为插件包交给已有插件分发渠道。项目需要独立副本时，在初始化命令中指定 --skill <名称>，不会复制测试代码。

脚本从实际技能目录调用；SKILL_ROOT 表示本次读到的 SKILL.md 所在绝对目录，--repo 始终指向工作项目。这样插件安装位置与目标仓不会混淆。

目标提示词、计划归档仅显式调用时启用。技能尊重当前用户请求和已有授权，dry-run 是预览能力，不新增人机审批环节。不会自行提交、推送、合并或写入 Issue Tracker。

本包与初始化器共用 v0.7.0 发布；源仓行为测试位于 ../../tests/。
