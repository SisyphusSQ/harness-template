#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_root="$repo_root/template"

fail() {
  echo "harness source verify: $*" >&2
  exit 1
}

assert_patterns() {
  local path="$1"
  shift
  local pattern

  [[ -f "$path" ]] || fail "missing source contract file: ${path#$repo_root/}"
  for pattern in "$@"; do
    rg -Fq -- "$pattern" "$path" \
      || fail "${path#$repo_root/} missing source contract: $pattern"
  done
}

assert_patterns_any() {
  local label="$1"
  local paths="$2"
  shift 2
  local pattern

  for pattern in "$@"; do
    if ! rg -Fq -- "$pattern" $paths; then
      fail "$label missing source contract: $pattern"
    fi
  done
}

assert_plan_rejected() {
  local plan="$1"
  local label="$2"

  if bash "$template_root/scripts/harness/review_gate.sh" --plan "$plan" >/dev/null 2>&1; then
    fail "review gate accepted invalid plan: $label"
  fi
}

required_source_files=(
  "README.md"
  "agent-init-project.md"
  "init-harness-project-sop.md"
  "scripts/init_harness_project.sh"
  "scripts/init_harness_project.ps1"
  "scripts/verify_harness_source.sh"
  "scripts/verify_harness_source.ps1"
  "template/scripts/harness/check.sh"
  "template/scripts/harness/check.ps1"
  "template/scripts/harness/common.sh"
  "template/scripts/harness/common.ps1"
  "template/scripts/harness/review_gate.sh"
  "template/scripts/harness/review_gate.ps1"
  "template/scripts/harness/evidence.sh"
  "template/scripts/harness/evidence.ps1"
)

for path in "${required_source_files[@]}"; do
  [[ -f "$repo_root/$path" ]] || fail "missing source file: $path"
done

assert_patterns "$repo_root/README.md" \
  "make verify" \
  "源仓完整回归" \
  '目标仓执行 `make harness-verify`' \
  "scripts/verify_harness_source.sh" \
  "scripts/verify_harness_source.ps1"

assert_patterns "$repo_root/scripts/init_harness_project.sh" \
  '"scripts/harness/evidence.sh"' \
  '"scripts/harness/evidence.ps1"'
assert_patterns "$repo_root/scripts/init_harness_project.ps1" \
  '"scripts/harness/evidence.sh"' \
  '"scripts/harness/evidence.ps1"'

assert_patterns "$template_root/AGENTS.md" \
  "scripts/harness/evidence.sh snapshot" \
  "review_policy"

if rg -ni 'harness|control-plane|\.agents/' "$template_root/README.md" >/dev/null; then
  fail "template/README.md must stay business-only and contain no harness guidance"
fi

(
  cd "$template_root"
  bash scripts/harness/check.sh
)

rg -Fq "EXAMPLE-implementation.md" "$template_root/AGENTS.md" \
  || fail "template/AGENTS.md should point readers to EXAMPLE-implementation.md"
if rg -n '^docs/test' "$template_root/.gitignore" >/dev/null; then
  fail "template/.gitignore should not ignore docs/test runbook documents"
fi

assert_patterns "$template_root/docs/harness/control-plane.md" \
  "collect + gate -> freeze + slice -> implement -> verify -> review -> closeout" \
  '`dispatch` 只在需要多 thread / worktree / subagent fan-out 时进入' \
  '`integrate -> post-integration verify` 只在存在可写 lease、branch / worktree 集成或其他 integration event 时进入' \
  '`pr_prep -> merge` 只在当前交付目标包含 PR / MR 且用户或仓库规则已授权时进入' \
  "Issue Tracker 是主协作真相" \
  "repo 是主执行真相" \
  "goal-orchestration" \
  "write_lease" \
  "Current State" \
  "Thread Status" \
  "post-integration verify" \
  "【完成】" \
  "Issue Store Profiles" \
  "Linear 字段映射" \
  "provider 仓" \
  "consumer 仓" \
  ".agents/PLANS.md" \
  "Review Policy Contract" \
  '`review_policy`: `standard` / `strict`' \
  '`standard` 允许主 agent 执行对抗式自审' \
  '`strict` 必须由 subagent 独立评审' \
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
  "任何无法确认的情况默认重跑"

assert_patterns_any "docs/issues templates" \
  "$template_root/docs/issues/README.md $template_root/docs/issues/TEMPLATE.md" \
  "Repo Issues" \
  "issue-provider=repo" \
  "issue_id" \
  "status" \
  "kind" \
  "goal" \
  "included" \
  "excluded" \
  "acceptance_matrix" \
  "stop_when" \
  "write_scope_limit" \
  "verification_commands" \
  "recovery_point" \
  "next_action" \
  "Orchestration" \
  "Current State" \
  "Thread Status Log" \
  "active_write_leases" \
  "post_integration_verify_summary" \
  "writeback_log"


for obsolete in \
  "$template_root/docs/harness/issue-workflow.md" \
  "$template_root/docs/harness/linear.md" \
  "$template_root/docs/harness/project-constraints.md"; do
  [[ ! -e "$obsolete" ]] || fail "obsolete template document still exists: ${obsolete#$repo_root/}"
done

assert_patterns "$template_root/docs/test/RUNBOOK_TEMPLATE.md" \
  "Test Runbook Template" \
  "当前验证结果" \
  "本次执行结果" \
  "执行副作用" \
  "前置条件" \
  "测试变量 / 初始化" \
  "主路径" \
  "清理结果" \
  "结果回写" \
  "runbook"

assert_patterns "$template_root/.agents/PLANS.md" \
  "何时必须写 plan" \
  "最小结构" \
  "EXAMPLE-implementation.md" \
  "真实入口与触发" \
  "输入装配与边界校验" \
  "组件职责与代码落点" \
  "关键执行时序" \
  "停止 / 错误 / 恢复" \
  "入口代码位置" \
  "装配结果 / 核心对象" \
  "步骤化时序" \
  "关键分支 / 降级路径" \
  "Reference Snippets" \
  "File Map" \
  "伪代码 / 主循环" \
  "关键分支与实现策略" \
  "竞态 / 状态机分析" \
  "不要在 plan 复制整套控制面"

assert_patterns "$template_root/.agents/plans/TEMPLATE.md" \
  "name: <任务名>" \
  "overview:" \
  "todos:" \
  "isProject: false" \
  "## Goal" \
  "## Scope Freeze" \
  "## Context and Orientation" \
  "## 0. 现有架构回顾与核心设计决策" \
  "### 真实入口与触发" \
  "入口代码位置" \
  "### 输入装配与边界校验" \
  "装配结果 / 核心对象" \
  "### 组件职责与代码落点" \
  "关键产物" \
  "### 关键执行时序" \
  "步骤化时序" \
  "### 停止 / 错误 / 恢复" \
  "关键分支 / 降级路径" \
  "### 按需补充" \
  "## Reference Snippets" \
  "## Concrete Steps" \
  "### 实现步骤" \
  "### 验证与收口步骤" \
  "## Progress" \
  "## Decision Log" \
  "## Surprises & Discoveries" \
  "## Validation and Acceptance" \
  "## Idempotence and Recovery" \
  "## Review Summary" \
  "## Outcomes & Retrospective"

assert_patterns "$template_root/.agents/plans/EXAMPLE-implementation.md" \
  "## Goal" \
  "## 0. 现有架构回顾与核心设计决策" \
  "## 1. HTTP 与 service -- 稳定幂等入口" \
  "## Reference Snippets" \
  "## Review Summary"

assert_patterns "$template_root/.agents/state/TEMPLATE.md" \
  "State Snapshot Template" \
  "Issue Tracker" \
  "orchestration_mode" \
  "root_goal" \
  "goal_state" \
  "goal_unit_roster" \
  "active_write_leases" \
  "waiting_on" \
  "next_check" \
  "post_integration_verify" \
  "recovery_point"

assert_patterns "$template_root/.agents/runs/TEMPLATE.md" \
  "Run Summary Template" \
  "Issue Tracker" \
  "orchestration_mode" \
  "root_goal" \
  "goal_state" \
  "active_write_leases" \
  "post_integration_verify"

assert_patterns "$template_root/.agents/skills/issue-goal-prompt/SKILL.md" \
  "任务系统" \
  "状态文件规则" \
  "pre-commit ready" \
  "subagent_review_unavailable" \
  "manual_gate_live_e2e" \
  '派生 `review_policy`' \
  '兼容性默认值是 `strict`' \
  "对抗式自审" \
  "验证证据复用"

assert_patterns "$template_root/.agents/skills/issue-goal-prompt/references/goal-prompt-template.md" \
  "完整目标提示词" \
  "状态文件模板" \
  "短启动提示词" \
  '- review_policy: <standard|strict>' \
  '- subagent_review_required: <true|false>' \
  "review_owner: main-agent-self-review" \
  "review_owner: subagent" \
  '`evidence_id`' \
  '`execution_session_id`' \
  '`post_integration_verify_summary.status`: `executed`'

assert_patterns "$template_root/.agents/skills/project-plan-archive/SKILL.md" \
  "先查 Issue Tracker，再归档" \
  "--done-issue" \
  "no_issue_default_archive"

assert_patterns "$template_root/.agents/skills/project-version-release/SKILL.md" \
  "issue 是执行粒度，release 是发布粒度" \
  "CHANGELOG.md -> Unreleased"

assert_patterns "$template_root/.agents/skills/test-runbook/SKILL.md" \
  "执行副作用" \
  "Request / Response 回写规则" \
  "提交版证据边界" \
  "结果回写规则"

if rg -n "DBBridge|db_bridge_test|/Users/suqing|TEA-" "$template_root/.agents/skills" >/dev/null; then
  fail "default harness skills contain project-specific constants"
fi

assert_patterns "$template_root/scripts/harness/common.ps1" \
  "Get-PlanImplementationSkeletonErrors" \
  "Resolve-PlanImplementationSection" \
  "Reference Snippets" \
  "组件职责与代码落点"
assert_patterns "$template_root/scripts/harness/review_gate.ps1" \
  "blocking_findings" \
  "result=pass" \
  "result=fail"
assert_patterns "$template_root/scripts/harness/evidence.ps1" \
  "result=" \
  "head=" \
  "worktree_digest=" \
  "evidence_id=" \
  "reusable=" \
  "reason="

assert_patterns "$repo_root/scripts/verify_harness_source.ps1" \
  "template/README.md must stay business-only" \
  "Reference Snippets" \
  "Get-PlanImplementationSkeletonErrors" \
  "full and placeholder extension bundles have different file sets" \
  "init_harness_project.ps1" \
  "harness source verify passed"

full_root="$repo_root/sources/agent_extensions/full"
placeholder_root="$repo_root/sources/agent_extensions/placeholder"
shared_root="$repo_root/sources/agent_extensions/shared"

full_files="$(cd "$full_root" && find . -type f -print | sort)"
placeholder_files="$(cd "$placeholder_root" && find . -type f -print | sort)"
[[ "$full_files" == "$placeholder_files" ]] \
  || fail "full and placeholder extension bundles have different file sets"
[[ -f "$shared_root/.agents/prompts/README.md" ]] \
  || fail "shared extension bundle is missing prompt README"

assert_patterns "$shared_root/.agents/prompts/README.md" \
  "orchestrator-thread.md" \
  "issue-standard-workflow.md" \
  "日常自然语言协作不需要额外的 loop prompt"

for mode_root in "$full_root" "$placeholder_root"; do
  assert_patterns "$mode_root/.agents/guides/linter.md" \
    "AGENTS.md"
  assert_patterns "$mode_root/.agents/prompts/issue-standard-workflow.md" \
    "review_policy" \
    "subagent_review_required" \
    "evidence_id" \
    "deterministic-local" \
    "environment-dependent" \
    "发生 integration event"
  assert_patterns "$mode_root/.agents/prompts/orchestrator-thread.md" \
    "Review policy" \
    "write_lease" \
    "post_integration_verify_summary.status" \
    "executed"
  assert_patterns "$mode_root/.agents/guides/code-review.md" \
    "Review Policy" \
    "main-agent-self-review" \
    "subagent" \
    "blocking_findings" \
    "对抗式自审"
done

while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  rg -qx "Mode: full" "$full_root/$rel" \
    || fail "full extension missing mode marker: $rel"
  rg -qx "Mode: placeholder" "$placeholder_root/$rel" \
    || fail "placeholder extension missing mode marker: $rel"
done <<<"$full_files"

assert_patterns "$full_root/.agents/prompts/orchestrator-thread.md" \
  "Handoff 模板" \
  "write_lease" \
  "Current State" \
  "Thread Status" \
  "post-integration verify"

assert_patterns "$full_root/.agents/prompts/issue-standard-workflow.md" \
  "真实入口与触发" \
  "输入装配与边界校验" \
  "组件职责与代码落点" \
  "关键执行时序" \
  "停止 / 错误 / 恢复" \
  "不要用 harness 控制流图替代业务实现图" \
  "不要只画图，不写步骤化时序" \
  "不要只写职责，不写代码落点" \
  "不要只写 happy path，不写关键分支 / 降级路径" \
  "不要把 Concrete Steps 写成纯控制面收口步骤" \
  "write_lease" \
  "post-integration verify"

for mode_root in "$full_root" "$placeholder_root"; do
  for obsolete in loop-codex.md loop-automation.md maintenance-loop.md; do
    [[ ! -e "$mode_root/.agents/prompts/$obsolete" ]] \
      || fail "obsolete prompt still exists: ${mode_root#$repo_root/}/.agents/prompts/$obsolete"
  done
done

tmp_root="$(mktemp -d -t harness-source-verify)"
trap 'rm -rf "$tmp_root"' EXIT

valid_plan="$template_root/.agents/plans/EXAMPLE-implementation.md"
bash "$template_root/scripts/harness/review_gate.sh" --plan "$valid_plan" >/dev/null \
  || fail "review gate rejected the source exemplar"
(
  cd "$template_root"
  make harness-review-gate PLAN="$valid_plan" >/dev/null
) || fail "Makefile review gate rejected the source exemplar"

legacy_plan="$tmp_root/legacy-plan.md"
bad_blocking="$tmp_root/bad-blocking.md"
bad_steps="$tmp_root/bad-steps.md"
bad_core="$tmp_root/bad-core.md"
bad_branch="$tmp_root/bad-branch.md"
bad_snippets="$tmp_root/bad-snippets.md"
bad_component="$tmp_root/bad-component.md"
bad_harness_flow="$tmp_root/bad-harness-flow.md"

cp "$valid_plan" "$bad_blocking"
cp "$valid_plan" "$bad_steps"
cp "$valid_plan" "$bad_core"
cp "$valid_plan" "$bad_branch"
cp "$valid_plan" "$bad_snippets"
cp "$valid_plan" "$bad_component"
cp "$valid_plan" "$legacy_plan"

perl -0pi -e 's/## 0\. 现有架构回顾与核心设计决策/## Architecture \/ Data Flow/' "$legacy_plan"
bash "$template_root/scripts/harness/review_gate.sh" --plan "$legacy_plan" >/dev/null \
  || fail "review gate rejected the legacy implementation section"

perl -0pi -e 's/`blocking_findings`: none/`blocking_findings`: correctness regression/' "$bad_blocking"
perl -0pi -e 's/步骤化时序/执行顺序/g' "$bad_steps"
perl -0pi -e 's/装配结果 \/ 核心对象/装配产物/g' "$bad_core"
perl -0pi -e 's/关键分支 \/ 降级路径/异常分支/g' "$bad_branch"
perl -0pi -e 's/## Reference Snippets/## Reference Samples/' "$bad_snippets"
python3 - "$bad_component" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
start = text.index("### 组件职责与代码落点")
end = text.index("### 关键执行时序", start)
section = text[start:end]
lines = section.splitlines()
kept = [line for line in lines if not (line.startswith("|") and "---" not in line and "模块/类型" not in line)]
path.write_text(text[:start] + "\n".join(kept) + "\n\n" + text[end:])
PY

cat >"$bad_harness_flow" <<'EOF'
# ExecPlan: harness-only flow

## Architecture / Data Flow

```mermaid
flowchart TD
  Collect["collect"] --> Verify["verify"]
  Verify --> Review["review"]
```

## Reference Snippets

```text
result=pass
```

## Concrete Steps

### 实现步骤
1. 运行控制面。

## Review Summary
- `blocking_findings`: none
EOF

assert_plan_rejected "$bad_blocking" "blocking finding"
assert_plan_rejected "$bad_steps" "missing step-by-step sequence"
assert_plan_rejected "$bad_core" "missing assembled core object"
assert_plan_rejected "$bad_branch" "missing key branch"
assert_plan_rejected "$bad_snippets" "missing reference snippets"
assert_plan_rejected "$bad_component" "missing component responsibility row"
assert_plan_rejected "$bad_harness_flow" "harness-only flow"

if command -v python3 >/dev/null 2>&1; then
  PYTHONDONTWRITEBYTECODE=1 python3 "$template_root/.agents/skills/project-plan-archive/tests/test_project_plan_archive.py" >/dev/null
  PYTHONDONTWRITEBYTECODE=1 python3 "$template_root/.agents/skills/project-version-release/scripts/project_version_release.py" --help >/dev/null
else
  fail "python3 is required for harness source verification"
fi

bash -n \
  "$repo_root/scripts/init_harness_project.sh" \
  "$repo_root/scripts/verify_harness_source.sh" \
  "$template_root/scripts/harness/check.sh" \
  "$template_root/scripts/harness/common.sh" \
  "$template_root/scripts/harness/review_gate.sh" \
  "$template_root/scripts/harness/evidence.sh"

init_target="$tmp_root/initialized-target"
bash "$repo_root/scripts/init_harness_project.sh" \
  --target "$tmp_root/dry-run-target" \
  --project-name "Harness Source Verify" \
  --stack go \
  --provider neutral \
  --issue-provider linear \
  --issue-prefix HSV \
  --dry-run >/dev/null
bash "$repo_root/scripts/init_harness_project.sh" \
  --target "$init_target" \
  --project-name "Harness Source Verify" \
  --stack go \
  --provider neutral \
  --issue-provider linear \
  --issue-prefix HSV >/dev/null

(
  cd "$init_target"
  [[ -f scripts/harness/evidence.sh ]] \
    || fail "initialized target is missing Bash evidence helper"
  [[ -f scripts/harness/evidence.ps1 ]] \
    || fail "initialized target is missing PowerShell evidence helper"
  bash scripts/harness/check.sh >/dev/null
)

if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$repo_root/scripts/verify_harness_source.ps1" >/dev/null
  echo "PowerShell source verify: passed with pwsh"
elif command -v powershell >/dev/null 2>&1; then
  powershell -NoProfile -File "$repo_root/scripts/verify_harness_source.ps1" >/dev/null
  echo "PowerShell source verify: passed with powershell"
else
  echo "PowerShell source verify: runtime unavailable; static parity checks passed"
fi

if [[ "${HARNESS_SOURCE_SKIP_EXTERNAL_TESTS:-0}" != "1" && -d "$repo_root/tests" ]]; then
  bash "$repo_root/tests/evidence_helper_test.sh"
  bash "$repo_root/tests/target_check_contract_test.sh"
  bash "$repo_root/tests/policy_contract_test.sh"
fi

echo "harness source verify passed"
