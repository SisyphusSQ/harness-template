# Gitignore 维护源

这里存放的是初始化脚本内部使用的 `.gitignore` 片段。

## 作用

- `base.gitignore`：公共规则
- `go.gitignore`：Go 规则
- `python.gitignore`：Python 规则
- `node-frontend.gitignore`：Node / 前端规则

这些文件不是给目标项目直接保留的目录结构，而是初始化脚本拼装最终根 `.gitignore` 的内部来源。
