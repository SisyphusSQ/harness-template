# 可选版本策略

此策略仅用于已经选择本技能的项目，不替代项目现有发布约定。

Issue 是工作粒度，release 是发布粒度。已完成但未发布的条目保存在 CHANGELOG.md 的 ## Unreleased 段；发布时归档为 ### v0.7.0(20260912) 一类版本段。

分类使用 feature、optimization、bugFix、note、script。已归档内容不随普通 Issue 修改。正式版本使用 SemVer，预发布可使用 beta/dev 标识。

共享脚本只做确定的文本操作：
- check：检查 CHANGELOG 与可发现的版本文件。
- classify：区分发布记录、纯版本文件与需要检查字段的 manifest，不判断业务是否应升版。
- changelog-add / release-archive：维护已选定格式的发布记录。
- version-bump：只修改 VERSION/version.txt，先统一检查全部目标，再执行写入。
- policy-plan：只打印发布意图。

脚本不替代版本决策、项目测试或发布平台。是否写入根据当前请求与已有授权决定；预览不新增审批流程，交付收尾不重复测试。
