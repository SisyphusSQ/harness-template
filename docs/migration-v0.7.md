# v0.7.0 迁移说明

普通初始化只补充入口，不承担历史文件清理。v0.7.0 需要 Python 3.10+，--force / -Force 会报错；逐文件覆盖使用 --overwrite / -Overwrite。

## 更新协作入口

1. 检查目标仓 AGENTS.md、README、.gitignore、计划和技能的实际内容与 Git 差异。
2. 使用 --dry-run 查看更新；默认保留已有内容，只补缺失文件和 .gitignore 标记块。
3. 对需要更新的文档先合并项目事实。明确要恢复为当前模板的文件才使用 --overwrite；该选项不会替换清单外文件。
4. 根规则明确已有授权持续有效；移除泛化的“所有写入都再次确认”“任何写入后重新跑全套验证”要求，保留真实权限、数据、安全和验收边界。
5. 使用当前计划模板的可选 issue_id；旧 execution_issue/master_issue 仍可被归档器读取。无 Issue 计划默认跳过，核实已完成后用 --done-plan 指定具体相对路径。

## 历史文件归属核对

旧版 docs/harness/、scripts/harness/、prompts、guides、adapter 以及 Makefile 都不会自动删除。相同路径不足以证明文件属于初始化器。

在已授权的迁移范围内，先取得目标仓当时采用的可信模板版本（例如 Git tag 或历史提交），逐文件比较原模板、项目定制内容和当前引用：

- 文件内容匹配旧模板且不再被引用时，才把该具体路径纳入清理清单。
- 内容已修改、含业务命令或无法确认来源时，保留并人工合并，不推断其可删除。
- Makefile 必须检查业务目标、CI 和开发文档的引用，不能因名称在历史清单里就删除。
- state/runs、日志与真实执行证据保持原有本地保存边界，不随模板升级清空。
- 删除前确保有可恢复的 Git 历史或本地备份；历史文件清理与初始化分开执行、分别报告结果。

旧源可在 [v0.6.0](https://github.com/SisyphusSQ/harness-template/tree/v0.6.0) 及更早 tag 中查询。若不能确认文件归属，就完成安全的入口补充并保留该文件，不自动扩大清理范围。

## 技能分发

通用技能已移到 plugins/project-workflows/skills/。可复用共享插件；需要项目独立副本时使用 --skill 选择。

初始化器保留目标仓已有技能。转为共享插件前，比较并迁移 repo-local 定制，确认任务不再引用旧副本后再按已授权的清理范围移除。不要同时维护同名共享技能与仓库副本。

project-version-release 不再把 go.mod 变化视为 release version 变化。package.json 等清单只提供“检查版本字段”的提示；version-bump 只支持内容为 SemVer 的 VERSION/version.txt，多文件先统一检查再写入。
