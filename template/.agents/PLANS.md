# 按需计划

跨模块、接口或数据变更，需要多轮验证、中断恢复，或难以用短步骤说明的任务，建议使用 .agents/plans/YYYY-MM-DD-<slug>.md。简单任务直接处理。

计划记录目标、范围、关键决策、真实文件和实现步骤、验收及恢复方式。模板见 plans/TEMPLATE.md，示例见 plans/EXAMPLE-implementation.md。

- issue_id 可留空；只在已有 Issue 时填写，不为写计划强制创建 Issue。
- 计划不复制全局协作规则、原始日志或 Issue 全部内容；已有事实用链接引用。
- 验证类别按影响选择，未执行项准确标注，不因模板出现某类检查就扩大测试。
- 完成计划可以保留原路径；需要整理时再使用已安装的 project-plan-archive。
- 无 Issue 计划不会自动归档，必须核实完成后显式指定路径。
