#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
template_root="$repo_root/template"

fail() {
  printf 'policy contract test: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing policy source: $path"
}

assert_contains() {
  local path="$1"
  local expected="$2"
  assert_file "$path"
  rg -Fq -- "$expected" "$path" \
    || fail "$path missing policy contract: $expected"
}

for rel in \
  "AGENTS.md" \
  ".agents/PLANS.md" \
  ".agents/plans/TEMPLATE.md" \
  ".agents/plans/EXAMPLE-implementation.md" \
  ".agents/state/TEMPLATE.md" \
  ".agents/runs/TEMPLATE.md" \
  "docs/test/RUNBOOK_TEMPLATE.md" \
  "docs/issues/README.md" \
  "docs/issues/TEMPLATE.md"; do
  assert_file "$template_root/$rel"
done

assert_contains "$template_root/AGENTS.md" '.agents/PLANS.md'
assert_contains "$template_root/AGENTS.md" '.agents/plans/'
assert_contains "$template_root/AGENTS.md" '.agents/state/'
assert_contains "$template_root/AGENTS.md" '.agents/runs/'
assert_contains "$template_root/AGENTS.md" '当前 issue provider：'
assert_contains "$template_root/.agents/PLANS.md" '计划不是强制状态机'
assert_contains "$template_root/.agents/plans/TEMPLATE.md" '## Scope and Non-Goals'
assert_contains "$template_root/.agents/plans/TEMPLATE.md" '## Idempotence and Recovery'
assert_contains "$template_root/.agents/state/TEMPLATE.md" 'recovery_point'
assert_contains "$template_root/.agents/runs/TEMPLATE.md" 'Artifact Boundary'
assert_contains "$template_root/docs/test/RUNBOOK_TEMPLATE.md" '执行副作用'
assert_contains "$template_root/docs/issues/TEMPLATE.md" '## Acceptance'

skill_count=0
while IFS= read -r -d '' path; do
  skill_count=$((skill_count + 1))
done < <(find "$template_root/.agents/skills" -type f -print0)
[[ "$skill_count" -eq 13 ]] \
  || fail "expected 13 synced skill files, found $skill_count"

for path in \
  "$template_root/.agents/skills/issue-goal-prompt/SKILL.md" \
  "$template_root/.agents/skills/project-plan-archive/SKILL.md" \
  "$template_root/.agents/skills/project-version-release/SKILL.md" \
  "$template_root/.agents/skills/test-runbook/SKILL.md"; do
  assert_contains "$path" '##'
done

if matches="$(rg -n -i \
  'harness|control-plane|write_lease|review_policy|evidence_id|post[._]integration|make harness|scripts/harness|docs/harness' \
  "$template_root/.agents" "$template_root/docs" "$template_root/AGENTS.md" "$template_root/.gitignore" 2>/dev/null)"; then
  printf '%s\n' "$matches" >&2
  fail "default template contains removed Harness workflow terms"
fi

for obsolete in \
  "$template_root/Makefile" \
  "$template_root/docs/harness" \
  "$template_root/scripts/harness"; do
  [[ ! -e "$obsolete" ]] || fail "obsolete default path exists: $obsolete"
done

assert_contains "$repo_root/sources/gitignore/base.gitignore" \
  'Project-local runtime summaries and execution records'
if rg -Fq -- 'Harness local auxiliary run surfaces' \
  "$repo_root/sources/gitignore/base.gitignore"; then
  fail "gitignore source still describes Harness-only runtime surfaces"
fi

printf 'policy contract tests passed\n'
