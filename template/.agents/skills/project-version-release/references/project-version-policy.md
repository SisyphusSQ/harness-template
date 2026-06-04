# Project Version Policy

## 真相边界

项目默认把以下版本面分开维护：

| 版本面 | 变化时机 |
| --- | --- |
| Issue log | 每个完成的 issue 都可以追加记录。 |
| Changelog Unreleased | 已完成但尚未进入真实 release 的变更。 |
| Release version | 只有发布 artifact 或正式归档 release notes 时变化。 |
| Compatibility policy | 只有项目明确维护兼容性策略时变化。 |

不要把这些版本面当成同一个字段的别名。

## CHANGELOG 策略

`CHANGELOG.md` 顶部应有 `## Unreleased` 段。

issue 收口时，把简洁条目追加到 `Unreleased`：

```markdown
## Unreleased
#### feature:
1. [APP-123] 增加 capability discovery。
```

只有真实 release 收口时，才把 `Unreleased` 归档成 release 段：

```markdown
### v0.2.0(20260424)
#### feature:
1. [APP-123] 增加 capability discovery。
```

已归档 release 段默认不可追加新 issue。

## 版本格式

release version 建议使用 SemVer：

| Channel | 示例 |
| --- | --- |
| stable | `v0.2.0` |
| beta | `v0.2.0-beta.1` |
| dev | `v0.2.0-dev.20260424.1` |

不要把裸 `dev`、git hash 或 dirty build 字符串作为正式兼容性版本。

## 自动化护栏

- `check` 和 `classify` 始终是安全 dry-run 命令。
- `changelog-add`、`release-archive`、`version-bump` 只有带 `--write` 时才改文件。
- `policy-plan` 只打印 operator intent，不连接外部系统。
- 任何写入后，都要按触及文件运行对应仓库验证。
