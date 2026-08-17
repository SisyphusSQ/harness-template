#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
initializer="$repo_root/scripts/init_harness_project.sh"

fail() {
  printf 'target initializer contract test: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  local target="$1"
  local rel="$2"
  [[ -f "$target/$rel" ]] || fail "missing generated file: $rel"
}

assert_absent() {
  local target="$1"
  local rel="$2"
  [[ ! -e "$target/$rel" ]] || fail "forbidden generated path exists: $rel"
}

assert_no_forbidden_terms() {
  local target="$1"
  local matches
  if matches="$(rg -n -i \
    'harness|control-plane|write_lease|review_policy|evidence_id|post[._]integration|make harness|scripts/harness|docs/harness' \
    "$target" 2>/dev/null)"; then
    printf '%s\n' "$matches" >&2
    fail "generated target contains Harness-specific flow terms"
  fi
}

run_init() {
  local target="$1"
  shift
  bash "$initializer" --target "$target" --project-name "Initializer Contract" --stack go "$@" \
    >"$target.init.out" 2>&1
}

expect_init_fail() {
  local target="$1"
  shift
  if run_init "$target" "$@"; then
    fail "initialization should fail for target: $target"
  fi
}

skill_files=(
  ".agents/skills/issue-goal-prompt/SKILL.md"
  ".agents/skills/issue-goal-prompt/agents/openai.yaml"
  ".agents/skills/issue-goal-prompt/references/goal-prompt-template.md"
  ".agents/skills/project-plan-archive/SKILL.md"
  ".agents/skills/project-plan-archive/agents/openai.yaml"
  ".agents/skills/project-plan-archive/scripts/project_plan_archive.py"
  ".agents/skills/project-plan-archive/tests/test_project_plan_archive.py"
  ".agents/skills/project-version-release/SKILL.md"
  ".agents/skills/project-version-release/agents/openai.yaml"
  ".agents/skills/project-version-release/references/project-version-policy.md"
  ".agents/skills/project-version-release/scripts/project_version_release.py"
  ".agents/skills/test-runbook/SKILL.md"
  ".agents/skills/test-runbook/agents/openai.yaml"
)

tmp_root="$(mktemp -d -t initializer-target-contract)"
trap 'rm -rf "$tmp_root"' EXIT

linear="$tmp_root/linear"
mkdir -p "$linear"
run_init "$linear"
for rel in \
  "AGENTS.md" \
  "README.md" \
  ".gitignore" \
  ".agents/PLANS.md" \
  ".agents/plans/TEMPLATE.md" \
  ".agents/plans/EXAMPLE-implementation.md" \
  ".agents/state/TEMPLATE.md" \
  ".agents/runs/TEMPLATE.md" \
  "docs/test/RUNBOOK_TEMPLATE.md"; do
  assert_file "$linear" "$rel"
done
for rel in "${skill_files[@]}"; do
  assert_file "$linear" "$rel"
done
for rel in \
  "Makefile" \
  "docs/harness" \
  "scripts/harness" \
  ".agents/prompts" \
  ".agents/guides" \
  "docs/issues"; do
  assert_absent "$linear" "$rel"
done
rg -Fq -- '当前 issue provider：`linear`' "$linear/AGENTS.md" \
  || fail "default target did not retain linear issue provider"
rg -Fq -- 'Project-local runtime summaries and execution records' "$linear/.gitignore" \
  || fail "generated .gitignore did not use generic runtime wording"
if matches="$(rg -n -- '__PROJECT_NAME__|__ISSUE_PROVIDER__|__ISSUE_PREFIX__' "$linear" 2>/dev/null)"; then
  printf '%s\n' "$matches" >&2
  fail "default target contains unresolved placeholders"
fi
assert_no_forbidden_terms "$linear"

repo_provider="$tmp_root/repo-provider"
mkdir -p "$repo_provider"
run_init "$repo_provider" --issue-provider repo --issue-prefix REP
assert_file "$repo_provider" "docs/issues/README.md"
assert_file "$repo_provider" "docs/issues/TEMPLATE.md"
rg -Fq -- '当前 issue provider：`repo`' "$repo_provider/AGENTS.md" \
  || fail "repo provider was not written to AGENTS.md"
assert_absent "$repo_provider" "Makefile"
assert_absent "$repo_provider" "docs/harness"
assert_absent "$repo_provider" "scripts/harness"
assert_no_forbidden_terms "$repo_provider"

existing="$tmp_root/existing"
mkdir -p "$existing"
printf 'keep me\n' >"$existing/README.md"
expect_init_fail "$existing"
rg -Fq -- 'keep me' "$existing/README.md" \
  || fail "failed initialization changed an existing file"

legacy="$tmp_root/legacy"
mkdir -p "$legacy/docs/harness" "$legacy/scripts/harness" "$legacy/.agents/prompts"
printf 'old control file\n' >"$legacy/docs/harness/control-plane.md"
printf 'old check\n' >"$legacy/scripts/harness/check.sh"
printf 'old prompt\n' >"$legacy/.agents/prompts/README.md"
expect_init_fail "$legacy"
run_init "$legacy" --force
for rel in \
  "docs/harness/control-plane.md" \
  "scripts/harness/check.sh" \
  ".agents/prompts/README.md" \
  "docs/harness" \
  "scripts/harness" \
  ".agents/prompts"; do
  assert_absent "$legacy" "$rel"
done
assert_file "$legacy" "AGENTS.md"
assert_no_forbidden_terms "$legacy"

dry_run="$tmp_root/dry-run"
bash "$initializer" \
  --target "$dry_run" \
  --project-name "Dry Run" \
  --stack python \
  --dry-run >"$tmp_root/dry-run.out" 2>&1
[[ ! -e "$dry_run" ]] || fail "dry-run created target files"

if command -v python3 >/dev/null 2>&1; then
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$linear/.agents/skills/project-plan-archive/tests/test_project_plan_archive.py" \
    >"$tmp_root/plan-skill.out" 2>&1 \
    || { sed -n '1,160p' "$tmp_root/plan-skill.out" >&2; fail "synced plan archive skill tests failed"; }
fi

printf 'target initializer contract tests passed\n'
