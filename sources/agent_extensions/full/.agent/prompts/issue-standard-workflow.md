Mode: full

# Issue 标准执行工作流

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 标准 issue workflow 手册与高频 Prompt 模板 |
| 适用范围 | 当前仓库的单卡推进、开发前准备、verify / review / mr_prep / 收口场景 |
| 主要载体 | `.agent/prompts/` + `docs/harness/` + `.agent/PLANS.md` + 仓库代码 |
| 关联文档 | `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/linear.md`、`.agent/prompts/loop-codex.md`、`.agent/prompts/loop-automation.md`、`.agent/guides/code-review.md`、`.agent/PLANS.md` |

固定规则：

- 本文是 `.agent/prompts/` 的使用手册，不是新的控制面真相源。
- 若本文与 `AGENTS.md`、`docs/harness/*`、`.agent/PLANS.md` 冲突，以后者为准。
- `loop-codex.md` 负责交互式 loop 的短 contract；`loop-automation.md` 负责无人值守 loop 的自动化语义。
- 能从仓库与 issue 真相自行定位的输入，先自行探索，不要反问用户。
- 阶段反馈、收口结果、`recovery_point`、`next_action` 默认写回 Linear。

## 0. 占位符约定

| 占位符 | 含义 |
| --- | --- |
| `<ISSUE-ID>` | 当前 issue 标识 |
| `<MASTER-ISSUE>` | 当前 Master issue |
| `<PLAN-PATH>` | 当前计划路径 |
| `<CONSTRAINTS>` | 额外范围约束；没有则写 `无` |
| `<TEST-DOC-PATH>` | 当前测试文档路径；默认 `docs/test/<domain>/...` |
| `<TEST-SCOPE>` | 当前测试范围，如 `只生成` / `只执行` / `生成 + 执行 + 回写` |
| `<EXTERNAL-SYSTEM>` | 当前外部系统或接口目录名称 |
| `<EXTERNAL-CATALOG>` | 当前外部接口目录、项目、空间或文档载体 |
| `<SYNC-SCOPE>` | 当前同步范围 |
| `<FOLDER-STRATEGY>` | 当前目录策略；默认沿用现有目录，不删除旧条目 |

## 1. 固定执行约束

1. 复杂任务默认先建或更新 `.agent/plans/*`，再进入实现。
2. 任何实现都必须先冻结 Included / Excluded / Acceptance Matrix / Write Scope Limit。
3. `verify / review / mr_prep` 是独立 checkpoint，不属于 `implement` 的隐含附属动作。
4. 发现当前卡过大、依赖未清或 write scope 失控时，先回到 plan-only，不继续硬做。
5. 若存在 `.agent/guides/code-review.md`，review 口径先按其中要求执行。
6. 若仓库启用了 PR / MR，它是次级代码叙事面，不替代 Linear 的协作真相。
7. 生成或更新 plan 时，`Architecture / Data Flow` 必须补齐以下 5 个实现子块：
   - `真实入口与触发`
   - `输入装配与边界校验`
   - `组件职责与代码落点`
   - `关键执行时序`
   - `停止 / 错误 / 恢复`
8. `Concrete Steps` 必须先写 `### 实现步骤`，再写 `### 验证与收口步骤`，不要把整个步骤段落退化成纯 verify / review / writeback / merge 清单。
9. 计划里必须显式写出：
   - `入口代码位置`
   - `装配结果 / 核心对象`
   - `步骤化时序`
   - `关键分支 / 降级路径`
10. 当任务涉及 pipeline / batch / runner / task orchestration / 多路径策略 / 状态机 / 恢复链路时，主动补：
   - `File Map`
   - `伪代码 / 主循环`
   - `关键分支与实现策略`
   - `竞态 / 状态机分析`
11. 测试文档类任务默认区分 `生成 runbook`、`执行 runbook`、`结果回写` 三个阶段：
    - 执行前先说明副作用、数据库 / 服务 / 临时文件影响范围
    - 未执行时只能写“当前验证结果”或模板，不能伪装成“已通过”
    - 执行后若回写文档，默认把 `本次执行结果` 放在文档前部
    - 已脱敏的结果摘要是 `docs/test/*` 的提交版测试真相，后续同步不得删成空模板
12. 外部系统或接口目录同步类任务默认按 `repo truth -> external catalog truth -> diff -> update/create -> readback verify` 推进：
    - 更新现有条目前先读取外部系统当前详情
    - 更新后立刻回读验收，不只依赖写入命令成功
    - 默认只改本轮指定载体，不顺带改其他 repo docs/spec；除非用户明确要求双向同步

## 1.1 Optional Superpowers Skill Hooks

固定规则：

- Superpowers 只作为阶段辅助，不替代本文、`.agent/PLANS.md`、`docs/harness/*` 或 Linear truth。
- 实施计划统一写入 `.agent/plans/`；不采用 Superpowers 默认计划目录作为仓库计划真相。
- skill 输出必须折回当前计划或 issue 的 `Verify Summary`、`Review Summary`、`Writeback Summary`、`Linear Actions`。
- 若 Superpowers 不可用，继续按本仓库 harness loop 执行。

阶段提示：

- `collect / gate`：需求未冻结、需要澄清设计或方案取舍时，可考虑 `superpowers:brainstorming`。
- `freeze / slice`：写实施计划时，可考虑 `superpowers:writing-plans`，但路径与结构服从 `.agent/PLANS.md`。
- `implement`：行为变更、bugfix 或重构可考虑 `superpowers:test-driven-development`。
- `implement`：任务独立且 subagent 可用时可考虑 `superpowers:subagent-driven-development`；否则使用普通 inline loop。
- `verify`：声明完成、通过或可收口前，可考虑 `superpowers:verification-before-completion`。
- `verify` 失败或异常排查：可考虑 `superpowers:systematic-debugging`，先定位根因再修。
- `review`：重大改动或 merge 前可考虑 `superpowers:requesting-code-review`，并把结论归并到 `blocking_findings`。
- `pr_prep / merge`：分支收口可参考 `superpowers:finishing-a-development-branch`，但 merge 优先级仍服从本仓库规则。

## 2. 常用 Prompt 模板

### 2.1 启动一张卡

```text
执行 <ISSUE-ID>。
先基于当前仓库、相关文档和 issue 上下文判断这张卡目前处于什么阶段，
再给出下一步最合适的动作。
如果当前信息不足以直接进入开发，优先先做范围分析和计划准备，不要直接扩大范围。
```

### 2.2 开发前准备 / plan-only（范围冻结 + 执行计划）

```text
执行 <ISSUE-ID>，本轮只做开发前准备 / plan-only，不开始开发实现。
Additional constraints: <CONSTRAINTS>
按以下连续流程输出：

1. 先做只读分析，确认当前 issue、仓库、相关文档和现状。
2. 冻结范围，明确：
   - Included
   - Excluded
   - Acceptance Matrix
   - Write Scope Limit
3. 基于已冻结范围生成正式执行计划（写到 `.agent/plans/` 下），计划中至少写清：
   - Goal
   - Scope and Non-Goals
   - Architecture / Data Flow 下的 5 个实现子块：
     - 真实入口与触发
     - 输入装配与边界校验
     - 组件职责与代码落点
     - 关键执行时序
     - 停止 / 错误 / 恢复
   - 其中必须写出：
     - 入口代码位置
     - 装配结果 / 核心对象
     - 步骤化时序
     - 关键分支 / 降级路径
   - Concrete Steps（先写 `### 实现步骤`，再写 `### 验证与收口步骤`）
   - Reference Snippets
   - Validation
4. 补充当前风险和待确认项。
5. 给出明确的下一步动作，不伪装成已经可以直接闭环。

额外要求：
- 若范围仍过大，先给出收窄或拆卡建议，不要假装可以直接一轮做完。
- 若任务以测试文档或外部系统同步为主，冻结范围时必须写清外部系统、目标载体、写回位置和副作用边界。
- 若任务涉及 pipeline / batch / runner / task orchestration / 多路径策略 / 状态机，主动补：
  - File Map
  - 伪代码 / 主循环
  - 关键分支与实现策略
  - 竞态 / 状态机分析

反模式：
- 不要用 harness 控制流图替代业务实现图
- 不要只画图，不写步骤化时序
- 不要只写职责，不写代码落点
- 不要只写 happy path，不写关键分支 / 降级路径
- 不要把 Concrete Steps 写成纯控制面收口步骤
```

### 2.3 开始开发实现

```text
按已冻结范围执行 <ISSUE-ID>，计划在 <PLAN-PATH>，基于当前 issue 分支开始开发实现。
Additional constraints: <CONSTRAINTS>

执行要求：
1. 严格按已冻结范围实施，不新增范围。
2. 若发现 blocker 或必须拆卡，先停下并回写计划，不继续硬做。
3. 代码、文档、计划同步更新。
4. 非代码型交付也要按“真相探索 -> 实施 -> 验证 -> 结果回写”闭环，不因没有代码改动就跳过验证。
5. 本轮结束时给出实现结果、验证状态和剩余风险。
```

### 2.4 Verify + Review Gate（只出结论与 findings，不修改）

```text
针对 <ISSUE-ID> 当前分支，执行独立 Verify + Review Gate。
按以下顺序执行，本轮不修改代码：

1. 先按当前冻结范围运行验证矩阵，产出独立 Verify Summary。
2. 若 verify 失败，只给出失败结论、修正方向与 Suggested Next Step，停止，不进入 review。
3. 若 verify 通过，基于最新 Verify Summary 再按 findings-first 输出：
   - Findings
   - blocking_findings
   - Residual Risks
   - Suggested Next Step
4. 若存在 blocking findings，不进入 mr_prep / merge。
```

固定要求：

- `Verify Summary` 必须先于 review findings 产出。
- docs-only 默认至少执行 `make harness-check` 与 `git diff --check`。
- Review 阶段默认只出结论与 findings，不直接改代码。

### 2.5 Findings 后直接修正

```text
针对 <ISSUE-ID> 当前 verify + review findings，直接进入修正。
优先修正 blocking findings，再按约定范围处理其他 findings；
修正后重新执行 verify -> review；
保持冻结范围不变；
未重新通过 review 前，不进入 mr_prep / merge。
```

### 2.6 Findings 先给我 review，再决定修改

```text
针对 <ISSUE-ID> 当前 verify + review 结果，本轮先只整理 findings，不修改代码。
输出：
- Findings
- blocking_findings
- Residual Risks
- 建议处理顺序
- Suggested Next Step

先等我 review / 确认处理范围，再决定是否进入修正；
若后续进入修正，仍保持冻结范围不变，并重新执行 verify -> review。
```

### 2.7 测试文档生成 / 执行 / 结果回写

```text
围绕 <ISSUE-ID> 处理测试文档任务。
目标文档：<TEST-DOC-PATH>
本轮范围：<TEST-SCOPE>
Additional constraints: <CONSTRAINTS>

按以下连续流程执行：

1. 先探索 repo truth：
   - 当前 issue、相关 contract / controller / schema / runbook
   - 是否已有 `docs/test/*` 文档可复用
   - 当前任务到底是 `只生成文档`、`只执行已有文档`，还是 `生成 + 执行 + 回写`
2. 若需要生成或更新测试文档：
   - 先把 runbook 写成可执行文档，不写成泛化 QA 说明
   - 至少写清：
     - 目标
     - 执行副作用
     - 前置条件
     - 测试变量 / 初始化
     - 步骤
     - 预期结果
     - 清理
     - 结果记录模板
   - 默认优先落到 `docs/test/<domain>/...`
3. 若需要执行 runbook：
   - 执行前先明确说明副作用、数据库 / 服务 / 临时文件影响范围
   - 再按 runbook 真实跑命令、联调或探查，不要只做纸面推演
   - 真实 HTTP、DB 或第三方系统联调只允许触达仓库已明确允许的测试环境
4. 执行后输出：
   - step-by-step 结果
   - 关键验证结论
   - 剩余 blocker / 风险
   - 清理结果
   - 区分 `可提交的脱敏摘要` 与 `不提交的原始输出 / 敏感痕迹`
5. 若用户要求回写文档：
   - 把 `本次执行结果` 放在文档前部，或更新现有 `当前验证结果`
   - 已执行的步骤写真实结果
   - 未执行的步骤显式写 `未执行` 或 `blocker`
   - 脱敏凭据、token、数据库主机、临时目录、完整下载 URL、本机路径等敏感或机器本地痕迹
   - 保留已脱敏的历史摘要；若有新结果，用新的脱敏摘要替换或追加，不要删成空模板
   - 原始命令输出和敏感痕迹只写 issue comment、`.agent/runs` 或本地记录，不写入提交版文档

固定要求：
- 测试文档默认是 runbook，不是泛化 QA 说明
- 未执行时只能写“当前验证结果”或模板，不得伪装成“已通过”
- 已脱敏的结果摘要是提交版测试真相，不得因为避免敏感信息而整体删除
```

### 2.8 外部接口目录 / 外部系统同步验收 (external-sync)

```text
围绕 <ISSUE-ID> 执行外部系统同步或接口目录验收。
External system: <EXTERNAL-SYSTEM>
External catalog: <EXTERNAL-CATALOG>
Sync scope: <SYNC-SCOPE>
Folder strategy: <FOLDER-STRATEGY>
Additional constraints: <CONSTRAINTS>

按以下连续流程执行：

1. 先确认外部系统当前真相：
   - 当前项目、空间、目录或分组结构
   - 当前已存在的条目列表
   - 本轮允许新增、更新、删除或只读验收的边界
2. 再确认 repo truth：
   - 从当前仓库的 contract、schema、controller、配置或文档枚举本轮公开面
   - 明确哪些是新增、哪些是现有条目刷新、哪些保持不动
3. 以稳定键做 diff：
   - HTTP 接口优先用 `method + path`
   - 配置或 schema 优先用稳定名称、版本或文件路径
   - 文档目录优先用标题 + 父目录
4. 对现有条目：
   - 先读当前详情
   - 再按 repo 当前真相完整重写或按外部系统推荐方式更新
   - 立刻回读验收
5. 对缺失条目：
   - 创建到指定目录或分组
   - 回读确认字段、示例、状态码、目录归类或其他关键元数据
6. 输出验收结果：
   - 外部系统和目标载体
   - 同步范围
   - 本轮新增 / 更新 / 跳过摘要
   - 是否存在重复稳定键
   - 代表性条目抽查结果
   - 剩余风险和下一步

固定要求：
- 默认只改本轮指定外部载体，不顺带改 repo docs/spec；除非用户明确要求双向同步
- 默认不删除条目、不重构目录、不做整包导入；除非用户明确要求
- 更新后必须回读验证，不能只以写入命令成功作为完成依据
```

### 2.9 开发后准备 PR / MR

```text
针对 <ISSUE-ID> 当前分支，完成本地验证、code review、文档同步，并准备 PR / MR。

执行要求：
1. 先执行本地验证并记录结果。
2. 按 findings-first 做 code review。
3. 若 review 有阻塞项，先修复再继续。
4. 同步更新相关计划、文档和结果摘要。
5. 准备 PR / MR，描述至少包含：
   - 本次范围
   - 本次不纳入
   - 验证结果
   - 文档同步点
   - 遗留风险
```

### 2.10 处理 PR Review / CI

```text
针对 <ISSUE-ID> 当前 PR / MR，处理 review 意见和 CI 问题，保持范围不变。

执行要求：
1. 优先处理阻塞性 review finding 和失败检查。
2. 不扩大原已冻结范围。
3. 修复后重新验证关键命令。
4. 更新 PR / MR 描述或评论中的验证摘要和残余风险。
```

### 2.11 合并后收尾

```text
<ISSUE-ID> 的 PR / MR 已满足合并条件，则完成合并并执行收尾。

执行要求：
1. 合并前再次确认当前卡的验证结果和阻塞项状态。
2. 合并后优先回写结果摘要到 Linear，再按需同步到 PR / MR 和 repo 文档。
3. 若当前卡已满足闭环条件，则将状态切到 Done。
4. 本地切回主分支并更新。
```

### 2.12 Master 是否可 Done

```text
对 <MASTER-ISSUE> 做一次“是否可置为 Done”的收口验收。
先读取 Master issue、相关计划文档、验证记录与当前 harness 文档；
只做检查、结论和 writeback 建议，不修改代码；
按 findings-first 输出 PASS / FAIL、阻塞项、残余风险与 Suggested Action。
```

## 3. 使用建议

- 先用“开发前准备 / plan-only（范围冻结 + 执行计划）”模板把范围、计划和 write scope 锁死，再进入开发。
- 需要先只看 findings、不自动修改时，先用“Verify + Review Gate（只出结论与 findings，不修改）”，再按需要选择两个 findings follow-up 模板之一。
- 需要生成或执行 `docs/test/*` runbook，优先用 `2.7 测试文档生成 / 执行 / 结果回写`。
- 需要同步外部接口目录或外部系统条目，优先用 `2.8 外部接口目录 / 外部系统同步验收 (external-sync)`。
- 需要交互式 loop 入口时，优先改用 `.agent/prompts/loop-codex.md`。
- 需要无人值守 / 自动推进时，优先改用 `.agent/prompts/loop-automation.md`。
- 做本地 review 前，默认先读取 `.agent/guides/code-review.md`（若存在）。
