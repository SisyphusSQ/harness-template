# 项目初始化 SOP

使用参数和目录见 [README](README.md)，Agent 补齐项目事实的要求见 [执行入口](agent-init-project.md)。

## 新项目与已有项目

1. 确认目标绝对路径、Git 状态、项目名、技术栈、issue provider。
2. 运行初始化器的 --dry-run，审阅 create/update/keep-existing/unchanged。
3. 使用相同参数执行。已有文件默认保留，.gitignore 只维护标记块。
4. 需要覆盖时指定每个 --overwrite 路径；不要覆盖已维护的项目事实。
5. 只在项目需要时添加 --skill；默认不复制四个通用技能。
6. 根据目标仓代码补齐 AGENTS.md，再按任务需要使用计划、恢复记录和测试 runbook。

支持的 stack：go、python、java、c、go-node、python-node、java-node、c-node、java-c、java-c-node。
支持的 issue provider：linear（默认）、github、gitlab、repo、other。只有 repo 额外生成 docs/issues/。

更新 provider 不会自动改写被保留的 AGENTS.md，也不自动删除旧 docs/issues/。请结合项目实际归属更新文档。旧版迁移见 [v0.7 迁移说明](docs/migration-v0.7.md)。

## 源仓维护

- 模板文件由目录自动发现，新增文件不需要在多个脚本内重复列名。
- 通用技能只维护 plugins/project-workflows/skills/；脚本使用显式 --repo，不依赖安装位置。
- 行为测试维护在 tests/，不分发到目标项目。
- 开发阶段运行 make verify；Windows 运行 python scripts/verify_harness_source.py。
- PowerShell 未安装时报告包装入口未实跑，不把共享 Python 核心通过写成 Windows 通过。
- 修改插件结构时验证 manifest；用户要求交付时复用开发阶段证据，不重复测试。

## 完成标准

默认入口已生成或明确保留；业务文件与旧文件未被静默改写或删除；选择的技能可在其安装位置调用；项目事实与验证入口已补齐或明确列出未知项；实际执行结果与未执行项分别说明。
