# 初始化器维护入口

- template/ 是默认项目模板；plugins/project-workflows/ 是按需使用的技能包。
- scripts/init_harness_project.py 是 Bash、PowerShell 共用的唯一初始化实现。
- 修改后运行 make verify；它只使用临时目录和本地 Git fixture，不调用外部系统。
- Windows 也可运行 python scripts/verify_harness_source.py；没有 PowerShell runtime 时必须报告该包装入口未实跑。
- 覆盖、迁移、符号链接、归档和发版文件改写需要行为测试；不要用固定文件数或禁词检查替代行为验证。
- 保留已有业务文件；普通初始化不得清理历史文件。迁移见 docs/migration-v0.7.md。
- 用户指令和本次已有授权优先于技能中的通用指南，不重复请求已获得的授权。
- 提交与发版收尾复用开发阶段验证结果，不重复运行测试。
- 交付平台遵循用户指定；本仓 github 远端与 origin 远端可能指向不同平台，操作前确认目标。
