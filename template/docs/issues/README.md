# Repo Issues

本目录用于 `issue-provider=repo` 的仓库内 issue 存储。没有 Linear、GitHub Issues、GitLab Issues 或其它外部工具时，仓库 issue 就是提交版 Issue Tracker。

固定规则：

- 新 issue 从 `docs/issues/TEMPLATE.md` 复制并填写。
- 文件名建议使用 `YYYY-MM-DD-<slug>.md` 或 `<ISSUE_PREFIX>-<number>-<slug>.md`。
- 每个 issue 必须保留 `issue_id`、`status`、`kind`、`goal`、`included`、`excluded`、`acceptance_matrix`、`stop_when`、`verification_commands`、`recovery_point`、`next_action`、`writeback_log`。
- 原始命令输出、真实凭据、数据库主机、完整 URL、token、cookie、DSN、本机路径等敏感或机器本地痕迹不写入提交版 issue。
- `.agents/state/` 和 `.agents/runs/` 可以补充本地恢复与审计细节，但不替代本目录中的 issue 真相。

推荐状态：

- `Backlog`
- `Todo`
- `In Progress`
- `In Review`
- `Done`
- `Canceled`
- `Blocked`
