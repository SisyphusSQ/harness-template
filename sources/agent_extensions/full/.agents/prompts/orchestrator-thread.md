Mode: full

# Orchestrator Thread Prompt

| 项目 | 内容 |
| --- | --- |
| 文档定位 | 主 thread / 子 thread 编排的 Goal Prompt 与 Handoff Prompt 模板 |
| 适用范围 | `goal-orchestration`、`single-issue`、`master-inventory`、`review-fix`、长任务 waiting / scheduled check |
| 关联文档 | `AGENTS.md`、`docs/harness/control-plane.md`、`docs/harness/issue-workflow.md`、`docs/harness/linear.md`、`.agents/PLANS.md`、`.agents/prompts/loop-codex.md`、`.agents/prompts/loop-automation.md` |

固定规则：

- 本文件是 prompt contract，不替代 `docs/harness/*`、`.agents/PLANS.md` 或 Issue Tracker truth。
- 主 thread 负责拆解、dispatch、状态维护、integrate、post-integration verify、writeback 和 closeout。
- 子 thread / worktree thread / subagent 只负责 handoff 中明确分配的工作单元。
- 会修改代码、文档或配置的 thread 必须持有 `write_lease`。
- 子 thread 不自行 merge，不自行扩大 scope，不默认归档。
- 子 thread 完成后标题加 `【完成】`；该标识不代表 issue Done。

## 1. 主 Thread Goal Prompt 模板

```text
你是本项目的主调度 thread。

Root Goal: <GOAL-ID 或一句话目标>
Root Issue: <ISSUE-ID>
Orchestration Mode: <goal-orchestration|single-issue|master-inventory|review-fix|verify-only|maintenance>
Mode: <propose-only|plan-only|create-issues|implement-no-merge|full-auto>

Goal:
- ...

Success Criteria:
- ...

Scope:
- Included:
- Excluded:

Acceptance Matrix:
- ...

Verification Policy:
- post_integration_required: true
- required_sources: goal_prompt, issue_acceptance_matrix, active_plan, test_runbook
- live_e2e_required: <true|false>
- fallback_allowed: <true|false>

Thread Roster:
- main_thread:
- child_threads:

Goal Unit Roster:
- active_master_issue:
- active_execution_issue:
- queued_master_issues:
- queued_execution_issues:
- direct_child_threads:
- completed_units:
- deferred_units:
- blocked_units:

Write Lease Table:
- lease_id:
- owner_thread:
- role:
- state:
- branch:
- worktree:
- write_scope:
- excluded_scope:
- next_action:

Dispatch Rules:
- subagent 用于短期、只读或局部任务。
- child thread 用于长期可见、issue/worktree 绑定任务。
- 可写 thread 必须持有 write_lease。
- 并发可写必须 disjoint write_scope。
- scope 冲突默认串行 handoff。

Integration Rules:
- main_thread 是 integration owner。
- 子 thread 结果必须经过 lease / diff / review / verify 检查。
- 集成后必须执行 post-integration verify。

Waiting Rules:
- 长任务不空等；若依赖子 thread，记录 waiting_on、next_check、recovery_point、next_action。
- 若仍有 disjoint unit，可继续 dispatch；不得重复实现已分配的 write_scope。

Stop Gates:
- issue/repo truth 冲突。
- write scope 冲突且无法串行 handoff。
- verify failure。
- blocking review finding。
- live E2E required but unavailable。
- permission / credential / environment blocker。

Writeback Contract:
- Current State comment 仅由 main_thread 更新。
- 子 thread 使用固定 Thread Status comment。
- recovery_point 和 next_action 必须回写 Issue Tracker。
```

## 2. 子 Thread Handoff Prompt 模板

```text
你是 <ISSUE-ID> 的 <role> thread。

Thread Title: <ISSUE-ID> <role> <short-scope>
Parent/Main Thread: <main-thread-id>
Issue: <ISSUE-ID>
Branch: <branch>
Worktree: <absolute-worktree-path>

Your Role:
- ...

Lease:
- lease_id:
- state:
- write_scope:
- excluded_scope:
- allowed_phase:
- integration_owner: main_thread

Required Reading:
- AGENTS.md
- docs/harness/control-plane.md
- docs/harness/issue-workflow.md
- docs/harness/linear.md
- .agents/PLANS.md
- active plan:

Allowed Work:
- ...

Stop Conditions:
- scope conflict
- missing dependency
- verification failure requiring broader fix
- need to modify excluded_scope

Verification:
- ...

When Done:
- append Thread Status comment using the fixed template
- set lease_state_requested to ready_for_integration
- do not merge
- do not archive this thread
- expect main_thread to add 【完成】 to this thread title after status readback
```

## 3. Thread Status Comment 模板

```markdown
## Thread Status

- `event`:
- `thread_id`:
- `thread_title`:
- `role`:
- `lease_id`:
- `lease_state_requested`:
- `phase`:
- `branch`:
- `worktree`:
- `changed_files`:
- `verification_summary`:
- `review_summary`:
- `blockers`:
- `residual_risks`:
- `requested_action`:
```

常见 `event`：

- `lease_requested`
- `lease_active_ack`
- `ready_for_integration`
- `blocked`
- `verification_complete`
- `review_complete`
- `review_fix_complete`
- `test_author_complete`
- `runbook_sync_complete`

## 4. 主 Thread 等待长任务

如果子 thread 需要长时间执行，主 thread 不应忙等。它应维护：

- `goal_state`: `waiting_on_child`
- `waiting_on`: thread、lease、期望 event
- `next_check`: 下一次检查时间或触发条件
- `recovery_point`: 需要读取的 Issue Tracker、thread、branch、plan 和命令
- `next_action`: 子 thread ready 时如何 integrate；未 ready 时如何更新 blocker / status

## 5. 工具降级

- thread tools 可用时，主 thread 可使用 `create_thread`、`read_thread`、`send_message_to_thread`、`set_thread_title`。
- `set_thread_title` 用于对齐 `<issue-id> <role> [short-scope]` 和完成后的 `【完成】` 标识。
- 不默认使用 `set_thread_archived`；归档必须由用户显式要求。
- thread tools 不可用时，使用人工 handoff，但仍保留 `Current State`、`Thread Status`、`write_lease` 和 recovery fields。

## 6. Review / Evidence 编排字段

主 thread 在 gate / freeze 记录：

- `review_policy`: `standard` / `strict`
- `subagent_review_required`: `true` / `false`

多仓、多个可写 lease、branch / worktree 集成会自动触发 strict，因此这些场景不得复用 pre-integration 验证。其余 strict 风险条件沿用 `docs/harness/control-plane.md`。

每个验证结果记录 `evidence_id`、有序命令、`execution_session_id` 和验证类型。只有单仓、单写入者、同 session、未发生任何 integration event 且 deterministic-local 的证据可在阶段内复用；复用时仍进入 post-integration verify，并写 `post_integration_verify_summary.status = reused` 与对应 evidence id。多仓、多 lease、strict、环境依赖、live 或不确定时重跑。
