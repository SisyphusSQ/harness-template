---
name: test-runbook
description: 当生成、执行或回写 `docs/test/*` runbook 时使用；尤其适用于需要声明执行副作用、记录业务 request/response、区分 `.agents/runs` 原始痕迹与提交版测试文档边界的场景。
---

# Test Runbook

用于项目内 `docs/test/*` 测试文档的生成、执行结果回写和提交版证据边界判断。

核心规则：提交版测试文档可以记录业务 request body 和 response body；认证、凭据、环境和机器本地痕迹不得写入提交版。

## 启动前检查

1. 先读取根级 `AGENTS.md`。
2. 读取 `docs/test/RUNBOOK_TEMPLATE.md` 和目标测试文档。
3. 读取相关 plan、runbook、OpenAPI / schema / controller / service / `.agents/runs/<RUN_ID>/summary`。
4. 判断本轮类型：
   - 只生成文档。
   - 只执行已有文档。
   - 生成 + 执行 + 回写。
5. 若涉及 live run，先确认环境、账号、数据范围和清理方式；疑似生产或影响面不清楚时必须停下。

## 执行前声明副作用

执行 runbook 前必须先说明影响面：

- DB：库名、表 bootstrap、seed、cleanup、保留的测试证据。
- 服务：是否启动临时 server、是否关闭 cron、端口是否只写在本地记录。
- 文件：`.agents/runs/<RUN_ID>/`、临时配置、raw transcript / headers、server log、命令输出位置。
- 外部系统：是否触达 API、第三方服务、生产环境或其他 live 系统。
- 缓存：语言运行时 test/build cache、工具缓存等可接受副作用。

## Runbook 必备结构

测试文档默认是可执行 runbook，不是泛化 QA 说明。至少包含：

- 目标。
- 执行副作用。
- 前置条件。
- 测试变量 / 初始化。
- 步骤。
- 预期结果。
- 清理。
- 结果记录模板。

若已经执行，文档前部必须写当前 / 本次验证结果；未执行只能写 `未执行` 或 `blocker`，不得伪装成通过。

## Request / Response 回写规则

每个 live HTTP 或 capability execute 步骤都要在提交版文档记录：

- HTTP method 和 path。
- 业务 query params。
- 业务 request body。
- 业务 response body。
- HTTP/body code。
- route、capability、stable business key、run id、时间戳和结果计数。

GET 无 body 时记录 method/path/query；POST/PUT/PATCH 要记录 JSON request body；response 要记录 envelope 和 data。

不要把此规则误用到 server log、analytics metadata 或 raw transcript。日志仍只能记录仓库规则允许的脱敏字段。

## 提交版证据边界

可以提交且不脱敏：

- HTTP method/path、业务 query params。
- 业务 request body、业务 response body。
- HTTP/body code、message、业务 data。
- route、capability id、稳定 contract 名。
- run id、测试生成的业务 key、业务名称、时间戳。
- result count、cleanup 状态。
- 未执行项、blocker、修正方向、Suggested Next Step。

不得提交：

- `Authorization` header、Bearer token、token hash。
- cookie、session、AK/SK、raw access key、Identity 签名。
- DB host、DB user、DB password、完整 DSN。
- 完整 URL、localhost 临时端口、presigned URL。
- 行主键、internal row id、task row id。
- server log、完整命令长输出、完整 curl transcript。
- 机器本地绝对路径、临时目录。
- 临时配置、token seed SQL、cleanup SQL 中包含凭据或环境细节的原始内容。

语义边界：

- API path 可提交；完整 `http://127.0.0.1:<port>/...` 不提交。
- 测试库名可按项目规则提交；真实 DB host/user/password/DSN 不提交。
- 外部可见业务 key 可提交；数据库内部自增 id 或行主键不提交。
- 业务 response body 可提交；带 header、token、timing、server log 的 raw transcript 不提交。
- request/response body 中若混入禁止字段，不原样提交；写 `<omitted: reason>`，并在 `提交版信息边界` 说明。

## 结果回写规则

执行后回写到目标 `docs/test/*`：

1. 在文档前部写 `本次执行结果` 或更新 `当前验证结果`。
2. 写 step-by-step 结果，已执行步骤使用真实结果。
3. 写 live request / response，按上面的提交版边界处理。
4. 写 gate 结果，包括 focused tests、contract / static catalog 检查、`git diff --check`、`make harness-verify` 等实际执行项。
5. 写未执行项，并明确 `未执行` 或 `不在本轮范围`。
6. 写清理结果：token revoke、server stopped、测试数据删除或保留策略。
7. 保留历史脱敏摘要；新结果替换或追加，不要删成空模板。

若任一步失败：

- 只写失败步骤、失败结论、修正方向和未执行步骤。
- 不把后续未执行的 live HTTP、gate 或 cleanup 写成通过。
- 原始输出保留在 `.agents/runs/<RUN_ID>/`，提交版只写必要失败摘要。

## 收口检查

回写后至少检查：

```bash
sed -n '1,220p' docs/test/<domain>/<issue>-agent-self-test.md
rg -n 'Authorization:|Bearer [A-Za-z0-9+/=_-]{12,}|token_hash|"token"|http://127\.0\.0\.1:[0-9]+|/Users/|[A-Fa-f0-9]{64}' docs/test/<domain>/<issue>-agent-self-test.md
rg -n '[[:blank:]]$' docs/test/<domain>/<issue>-agent-self-test.md
git diff --check
```

敏感扫描有命中时先判断是否只是规则说明文字；若是真实 token、hash、URL、路径或凭据，必须移出提交版文档。
