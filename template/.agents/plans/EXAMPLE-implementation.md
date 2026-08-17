# ExecPlan: 增加配置文件热加载

```yaml
name: 增加配置文件热加载
overview: 在不重启服务的情况下重新加载允许热更新的配置项
todos:
  - id: config-loader
    content: 增加配置读取和校验入口
    status: pending
  - id: reload-trigger
    content: 增加受控的 reload 触发方式
    status: pending
  - id: validation
    content: 补充单元和集成验证
    status: pending
isProject: false
```

## Goal

- 用户修改允许热更新的配置后，服务可以安全地重新加载。
- 非法配置不能覆盖当前有效配置。

## Scope and Non-Goals

### Included

- 配置解析、校验和替换；
- reload 入口及错误返回；
- 相关测试和 runbook。

### Excluded

- 不改配置文件格式；
- 不增加自动重试或后台轮询；
- 不处理需要重启才能生效的配置。

## Context and Decisions

- 入口代码位置：`internal/config/loader.go`、`internal/http/reload.go`；
- 装配结果：经过校验的不可变配置对象；
- 采用显式 reload 触发，避免后台轮询引入额外状态。

## Implementation Steps

1. 在配置 loader 中增加候选配置解析和边界校验。
2. 在 reload handler 中调用 loader，成功后原子替换当前配置。
3. 对非法配置保留旧配置并返回可定位的错误。
4. 补充成功、非法配置、并发 reload 和恢复验证。

## Validation and Acceptance

| 类别 | 命令或检查 | 预期结果 | 实际结果 |
| --- | --- | --- | --- |
| 单元 | `go test ./internal/config/...` | 通过 | 未执行 |
| 集成 | `go test ./internal/http/...` | reload 成功和失败路径通过 | 未执行 |
| 静态 | `git diff --check` | 无空白错误 | 未执行 |

## Idempotence and Recovery

- 重复 reload 同一配置不会改变结果。
- 校验失败时不替换当前配置。
- 服务重启后仍从原有配置入口启动。

## Outcomes and Follow-up

- 已完成：未开始。
- 未完成：实现、测试、runbook。
- 残余风险：需要确认生产环境是否允许 reload 入口。
- 下一步：先确认 reload API 的授权边界。
