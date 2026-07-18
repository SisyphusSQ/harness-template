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
  "Review Policy Contract" \
  '`review_policy`: `standard` / `strict`' \
  '`standard` 允许主 agent 执行对抗式自审' \
  '`strict` 必须由 subagent 独立评审' \
  '`blocked: subagent_review_unavailable`' \
  '调用方未提供 `review_policy` 时按 `strict` 处理' \
  "多仓代码改动、多个可写 lease 或 branch / worktree 集成" \
  "鉴权、安全、权限、公开 API 或 contract 兼容性" \
  "schema、migration 或数据修改" \
  "并发、幂等、重试或业务状态机" \
  "release、部署、生产环境或不可逆外部副作用" \
  "required live E2E、full-auto 或自动 merge" \
  "风险无法可靠判断" \
  "Verification Evidence Reuse Contract" \
  "deterministic-local" \
  "environment-dependent" \
  '`post_integration_verify_summary.status`: `reused`' \
  "任何无法确认的情况默认重跑"

goal_skill="$repo_root/template/.agents/skills/issue-goal-prompt/SKILL.md"
goal_reference="$repo_root/template/.agents/skills/issue-goal-prompt/references/goal-prompt-template.md"
assert_patterns "$goal_skill" \
  '派生 `review_policy`' \
  '兼容性默认值是 `strict`' \
  '`subagent_review_required` 等于 `review_policy == strict`' \
  "对抗式自审" \
  "验证证据复用"
assert_patterns "$goal_reference" \
  '- review_policy: <standard|strict>' \
  '- subagent_review_required: <true|false>' \
  "review_owner: main-agent-self-review" \
  "review_owner: subagent" \
  '`evidence_id`' \
  '`execution_session_id`' \
  '`deterministic-local` / `environment-dependent` / `live`' \
  '`post_integration_verify_summary.status`: `reused`' \
  '- `review_policy`: <standard|strict>' \
  '- `subagent_review_required`: <true|false>'

for mode in full placeholder; do
  mode_root="$repo_root/sources/agent_extensions/$mode/.agents"
  assert_patterns "$mode_root/prompts/issue-standard-workflow.md" \
    "review_policy" \
    "subagent_review_required" \
    "standard" \
    "strict" \
    "evidence_id" \
    "deterministic-local" \
    "environment-dependent" \
    "reused"
  assert_patterns "$mode_root/prompts/loop-codex.md" \
    "review_policy" \
    "subagent_review_required" \
    "evidence_id" \
    "同一执行 session" \
    "required live E2E"
  assert_patterns "$mode_root/prompts/loop-automation.md" \
    "review_policy" \
    '兼容性默认 `strict`' \
    "strict" \
    "evidence_id" \
    "任何无法确认的情况默认重跑"
  assert_patterns "$mode_root/prompts/orchestrator-thread.md" \
    "review_policy" \
    "subagent_review_required" \
    "多仓" \
    "多个可写 lease" \
    "post_integration_verify_summary.status" \
    "reused"
  assert_patterns "$mode_root/guides/code-review.md" \
    "Review Policy" \
    "main-agent-self-review" \
    "subagent" \
    "blocking_findings" \
    "对抗式自审"
done

if rg -n 'review_policy|evidence_id|post_integration_verify_summary.status' \
  "$repo_root/template/.agents/PLANS.md" \
  "$repo_root/template/.agents/plans/TEMPLATE.md" \
  "$repo_root/template/.agents/plans/EXAMPLE-implementation.md" >/dev/null; then
  fail "review/evidence optimization must not change the human-readable plan contract"
fi

echo "policy contract tests passed"
