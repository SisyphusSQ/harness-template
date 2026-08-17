#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
template_root="$repo_root/template"
bash_initializer="$repo_root/scripts/init_harness_project.sh"
powershell_initializer="$repo_root/scripts/init_harness_project.ps1"

fail() {
  printf 'initializer source verify: %s\n' "$*" >&2
  exit 1
}

relative_path() {
  printf '%s\n' "$1" | sed "s#^$repo_root/##"
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing source file: $(relative_path "$path")"
}

assert_contains() {
  local path="$1"
  local expected="$2"
  assert_file "$path"
  rg -Fq -- "$expected" "$path" \
    || fail "$(relative_path "$path") missing source contract: $expected"
}

assert_not_contains() {
  local path="$1"
  local forbidden="$2"
  assert_file "$path"
  if rg -Fq -- "$forbidden" "$path"; then
    fail "$(relative_path "$path") contains forbidden source contract: $forbidden"
  fi
}

assert_absent() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "obsolete source path still exists: $(relative_path "$path")"
}

assert_tree_has_no_forbidden_terms() {
  local root="$1"
  local matches
  if matches="$(rg -n -i \
    'harness|control-plane|write_lease|review_policy|evidence_id|post[._]integration|make harness|scripts/harness|docs/harness' \
    "$root" 2>/dev/null)"; then
    printf '%s\n' "$matches" >&2
    fail "default template contains Harness-specific flow terms"
  fi
}

required_root_files=(
  "README.md"
  "agent-init-project.md"
  "init-harness-project-sop.md"
  "Makefile"
  "scripts/init_harness_project.sh"
  "scripts/init_harness_project.ps1"
  "scripts/verify_harness_source.sh"
  "scripts/verify_harness_source.ps1"
  "sources/gitignore/base.gitignore"
  "tests/source_verify_contract_test.sh"
  "tests/target_check_contract_test.sh"
  "tests/policy_contract_test.sh"
)

required_template_files=(
  "AGENTS.md"
  "README.md"
  ".gitignore"
  ".agents/PLANS.md"
  ".agents/plans/TEMPLATE.md"
  ".agents/plans/EXAMPLE-implementation.md"
  ".agents/state/TEMPLATE.md"
  ".agents/runs/TEMPLATE.md"
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
  "docs/test/RUNBOOK_TEMPLATE.md"
  "docs/issues/README.md"
  "docs/issues/TEMPLATE.md"
)

for rel in "${required_root_files[@]}"; do
  assert_file "$repo_root/$rel"
done
for rel in "${required_template_files[@]}"; do
  assert_file "$template_root/$rel"
done

for obsolete in \
  "$template_root/Makefile" \
  "$template_root/docs/harness" \
  "$template_root/scripts/harness"; do
  assert_absent "$obsolete"
done

assert_contains "$template_root/AGENTS.md" '.agents/PLANS.md'
assert_contains "$template_root/AGENTS.md" '.agents/state/'
assert_contains "$template_root/AGENTS.md" '.agents/runs/'
assert_contains "$template_root/AGENTS.md" '__ISSUE_PROVIDER__'
assert_contains "$template_root/.gitignore" '.agents/state/*'
assert_contains "$template_root/.gitignore" '.agents/runs/*'
assert_not_contains "$template_root/.gitignore" 'Harness local auxiliary run surfaces'

assert_contains "$bash_initializer" 'issue_provider="linear"'
assert_contains "$powershell_initializer" 'IssueProvider = "linear"'
assert_not_contains "$bash_initializer" '--provider'
assert_not_contains "$powershell_initializer" '-Provider'
assert_contains "$bash_initializer" 'docs/issues/README.md'
assert_contains "$powershell_initializer" 'docs/issues/README.md'
assert_contains "$bash_initializer" '".agents/skills/issue-goal-prompt/SKILL.md"'
assert_contains "$powershell_initializer" '".agents/skills/issue-goal-prompt/SKILL.md"'

for rel in \
  ".agents/skills/issue-goal-prompt/SKILL.md" \
  ".agents/skills/issue-goal-prompt/agents/openai.yaml" \
  ".agents/skills/issue-goal-prompt/references/goal-prompt-template.md" \
  ".agents/skills/project-plan-archive/SKILL.md" \
  ".agents/skills/project-plan-archive/agents/openai.yaml" \
  ".agents/skills/project-plan-archive/scripts/project_plan_archive.py" \
  ".agents/skills/project-plan-archive/tests/test_project_plan_archive.py" \
  ".agents/skills/project-version-release/SKILL.md" \
  ".agents/skills/project-version-release/agents/openai.yaml" \
  ".agents/skills/project-version-release/references/project-version-policy.md" \
  ".agents/skills/project-version-release/scripts/project_version_release.py" \
  ".agents/skills/test-runbook/SKILL.md" \
  ".agents/skills/test-runbook/agents/openai.yaml"; do
  assert_contains "$bash_initializer" "\"$rel\""
  assert_contains "$powershell_initializer" "\"$rel\""
done

for rel in \
  "AGENTS.md" \
  "README.md" \
  ".agents/PLANS.md" \
  ".agents/plans/TEMPLATE.md" \
  ".agents/plans/EXAMPLE-implementation.md" \
  ".agents/state/TEMPLATE.md" \
  ".agents/runs/TEMPLATE.md" \
  "docs/test/RUNBOOK_TEMPLATE.md"; do
  assert_contains "$bash_initializer" "\"$rel\""
  assert_contains "$powershell_initializer" "\"$rel\""
done

assert_not_contains "$repo_root/README.md" '--provider'
assert_not_contains "$repo_root/agent-init-project.md" '--provider'
assert_not_contains "$repo_root/init-harness-project-sop.md" '--provider'
assert_tree_has_no_forbidden_terms "$template_root"

tmp_root="$(mktemp -d -t initializer-source-verify)"
trap 'rm -rf "$tmp_root"' EXIT

linear_target="$tmp_root/linear"
bash "$bash_initializer" \
  --target "$linear_target" \
  --project-name "Source Verify" \
  --stack go \
  --issue-prefix TST >"$tmp_root/linear.out"

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
  [[ -f "$linear_target/$rel" ]] || fail "fresh linear target missing: $rel"
done
for rel in \
  ".agents/skills/issue-goal-prompt/SKILL.md" \
  ".agents/skills/issue-goal-prompt/agents/openai.yaml" \
  ".agents/skills/issue-goal-prompt/references/goal-prompt-template.md" \
  ".agents/skills/project-plan-archive/SKILL.md" \
  ".agents/skills/project-plan-archive/agents/openai.yaml" \
  ".agents/skills/project-plan-archive/scripts/project_plan_archive.py" \
  ".agents/skills/project-plan-archive/tests/test_project_plan_archive.py" \
  ".agents/skills/project-version-release/SKILL.md" \
  ".agents/skills/project-version-release/agents/openai.yaml" \
  ".agents/skills/project-version-release/references/project-version-policy.md" \
  ".agents/skills/project-version-release/scripts/project_version_release.py" \
  ".agents/skills/test-runbook/SKILL.md" \
  ".agents/skills/test-runbook/agents/openai.yaml"; do
  [[ -f "$linear_target/$rel" ]] || fail "fresh linear target missing skill file: $rel"
done
for obsolete in \
  "$linear_target/Makefile" \
  "$linear_target/docs/harness" \
  "$linear_target/scripts/harness" \
  "$linear_target/.agents/prompts" \
  "$linear_target/.agents/guides"; do
  [[ ! -e "$obsolete" ]] || fail "fresh linear target contains forbidden path: $obsolete"
done
[[ ! -e "$linear_target/docs/issues" ]] \
  || fail "fresh linear target must not contain docs/issues for the default provider"
assert_contains "$linear_target/AGENTS.md" '当前 issue provider：`linear`'
assert_contains "$linear_target/.gitignore" 'Project-local runtime summaries and execution records'
if matches="$(rg -n -- '__PROJECT_NAME__|__ISSUE_PROVIDER__|__ISSUE_PREFIX__' "$linear_target" 2>/dev/null)"; then
  printf '%s\n' "$matches" >&2
  fail "fresh linear target contains unresolved placeholders"
fi
assert_tree_has_no_forbidden_terms "$linear_target"

repo_target="$tmp_root/repo-provider"
bash "$bash_initializer" \
  --target "$repo_target" \
  --project-name "Repo Provider" \
  --stack python \
  --issue-provider repo \
  --issue-prefix REP >"$tmp_root/repo.out"
[[ -f "$repo_target/docs/issues/README.md" ]] \
  || fail "repo provider target missing docs/issues/README.md"
[[ -f "$repo_target/docs/issues/TEMPLATE.md" ]] \
  || fail "repo provider target missing docs/issues/TEMPLATE.md"
assert_contains "$repo_target/AGENTS.md" '当前 issue provider：`repo`'
for obsolete in \
  "$repo_target/Makefile" \
  "$repo_target/docs/harness" \
  "$repo_target/scripts/harness"; do
  [[ ! -e "$obsolete" ]] || fail "repo provider target contains forbidden path: $obsolete"
done

printf 'initializer source verify passed\n'
