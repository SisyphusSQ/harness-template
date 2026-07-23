#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "policy contract test: $*" >&2
  exit 1
}

assert_patterns() {
  local path="$1"
  shift
  local pattern

  [[ -f "$path" ]] || fail "missing policy source: ${path#$repo_root/}"
  for pattern in "$@"; do
    rg -Fq -- "$pattern" "$path" \
      || fail "${path#$repo_root/} missing policy contract: $pattern"
  done
}

control_plane="$repo_root/template/docs/harness/control-plane.md"
assert_patterns "$control_plane" \
  'collect + gate -> freeze + slice -> implement -> verify -> review -> closeout' \
  '`dispatch` 只在需要多 thread / worktree / subagent fan-out 时进入' \
  '`integrate -> post-integration verify` 只在存在可写 lease、branch / worktree 集成或其他 integration event 时进入' \
  '`pr_prep -> merge` 只在当前交付目标包含 PR / MR 且用户或仓库规则已授权时进入' \
  "Issue Tracker 是主协作真相" \
  "Issue Store Profiles" \
  "Linear 字段映射" \
  "Current State" \
  "Thread Status" \
  "Write Lease" \
  "Done Gate" \
  "goal-orchestration" \
  "Review Policy Contract" \
  '`review_policy`: `standard` / `strict`' \
  '`standard` 允许主 agent 执行对抗式自审' \
  '`strict` 必须由 subagent 独立评审' \
  '`blocked: subagent_review_unavailable`' \
  '调用方未提供 `review_policy` 时按 `strict` 处理' \
  "Verification Evidence Reuse Contract" \
  "deterministic-local" \
  "environment-dependent" \
  '`verification_summary.evidence_status: retained`' \
  '`post_integration_verify_summary.status: executed`' \
  "任何无法确认的情况默认重跑"

assert_patterns "$repo_root/template/AGENTS.md" \
  '项目 `README.md` 只负责业务说明' \
  "项目约束" \
  "渐进式读取" \
  "不要预加载整个" \
  "issue-standard-workflow.md" \
  "orchestrator-thread.md" \
  "scripts/harness/evidence.sh snapshot" \
  "review_policy"

assert_patterns "$repo_root/sources/agent_adapters/cursor/.cursor/rules/harness.mdc" \
  "alwaysApply: true" \
  "渐进式读取" \
  "每个任务只默认读取" \
  "不要预加载全部 Harness 文件" \
  "计划质量需要校准"

if rg -ni 'harness|control-plane|\.agents/' "$repo_root/template/README.md" >/dev/null; then
  fail "template README must not contain harness guidance"
fi

harness_doc_count="$(find "$repo_root/template/docs/harness" -maxdepth 1 -type f | wc -l | tr -d ' ')"
[[ "$harness_doc_count" == "1" ]] || fail "template/docs/harness must contain exactly one file"
[[ -f "$control_plane" ]] || fail "control-plane.md must be the only harness document"

for obsolete in issue-workflow.md linear.md project-constraints.md; do
  [[ ! -e "$repo_root/template/docs/harness/$obsolete" ]] \
    || fail "obsolete harness document still exists: $obsolete"
done

assert_patterns "$repo_root/sources/agent_extensions/shared/.agents/prompts/README.md" \
  "issue-standard-workflow.md" \
  "orchestrator-thread.md" \
  "日常自然语言协作不需要额外的 loop prompt"

for mode in full placeholder; do
  mode_root="$repo_root/sources/agent_extensions/$mode/.agents"
  expected_mode="Mode: $mode"

  for path in \
    "$mode_root/prompts/issue-standard-workflow.md" \
    "$mode_root/prompts/orchestrator-thread.md" \
    "$mode_root/guides/code-review.md" \
    "$mode_root/guides/linter.md"; do
    [[ "$(sed -n '1p' "$path")" == "$expected_mode" ]] \
      || fail "invalid mode marker: ${path#$repo_root/}"
  done

  for obsolete in loop-codex.md loop-automation.md maintenance-loop.md; do
    [[ ! -e "$mode_root/prompts/$obsolete" ]] \
      || fail "obsolete prompt still exists: $mode/prompts/$obsolete"
  done

  assert_patterns "$mode_root/prompts/issue-standard-workflow.md" \
    "review_policy" \
    "subagent_review_required" \
    "evidence_id" \
    "deterministic-local" \
    "发生 integration event"
  assert_patterns "$mode_root/prompts/orchestrator-thread.md" \
    "write_lease" \
    "Review policy" \
    "post_integration_verify_summary.status"
  assert_patterns "$mode_root/guides/code-review.md" \
    "Review Policy" \
    "blocking_findings" \
    "对抗式自审"
  assert_patterns "$mode_root/guides/linter.md" \
    "AGENTS.md" \
    "机械"
done

assert_patterns "$repo_root/sources/agent_extensions/full/.agents/prompts/issue-standard-workflow.md" \
  "真实入口与触发" \
  "输入装配与边界校验" \
  "组件职责与代码落点" \
  "关键执行时序" \
  "停止 / 错误 / 恢复" \
  "不要用 harness 控制流图替代业务实现图"

assert_patterns "$repo_root/sources/agent_extensions/full/.agents/prompts/orchestrator-thread.md" \
  "Handoff 模板" \
  "当前事实与来源" \
  "实施范围" \
  "允许的副作用" \
  "停止条件" \
  "最终回传"

for result_template in \
  "$repo_root/template/.agents/runs/TEMPLATE.md" \
  "$repo_root/template/docs/issues/TEMPLATE.md"; do
  assert_patterns "$result_template" \
    '条件字段' \
    '`integration_summary`' \
    '`post_integration_verify_summary`' \
    '`optional_delivery`'
done

assert_patterns "$repo_root/template/.agents/PLANS.md" \
  '不要在 plan 复制整套控制面' \
  'Review Summary'

for plan_contract in \
  "$repo_root/template/.agents/plans/TEMPLATE.md" \
  "$repo_root/template/.agents/plans/EXAMPLE-implementation.md"; do
  assert_patterns "$plan_contract" \
    '## Review Summary' \
    '`blocking_findings`'
done

if rg -n '^## (Harness Control Plane|Issue Actions|Verify Summary|Closeout Summary)$' \
  "$repo_root/template/.agents/plans/TEMPLATE.md" \
  "$repo_root/template/.agents/plans/EXAMPLE-implementation.md" >/dev/null; then
  fail "plan files must not mirror control-plane or result surfaces"
fi

if rg -n 'review_policy|evidence_id|post_integration_verify_summary.status' \
  "$repo_root/template/.agents/PLANS.md" \
  "$repo_root/template/.agents/plans/TEMPLATE.md" \
  "$repo_root/template/.agents/plans/EXAMPLE-implementation.md" >/dev/null; then
  fail "review/evidence optimization must not change the human-readable plan contract"
fi

echo "policy contract tests passed"
