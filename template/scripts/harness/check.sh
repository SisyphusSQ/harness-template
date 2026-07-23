#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "$repo_root"

fail() {
  echo "$*" >&2
  exit 1
}

required_files=(
  ".gitignore"
  "AGENTS.md"
  "README.md"
  "docs/harness/control-plane.md"
  "docs/issues/README.md"
  "docs/issues/TEMPLATE.md"
  "docs/test/RUNBOOK_TEMPLATE.md"
  ".agents/PLANS.md"
  ".agents/plans/TEMPLATE.md"
  ".agents/plans/EXAMPLE-implementation.md"
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
  ".agents/state/TEMPLATE.md"
  ".agents/runs/TEMPLATE.md"
  "scripts/harness/check.sh"
  "scripts/harness/common.sh"
  "scripts/harness/review_gate.sh"
  "scripts/harness/evidence.sh"
  "scripts/harness/check.ps1"
  "scripts/harness/common.ps1"
  "scripts/harness/review_gate.ps1"
  "scripts/harness/evidence.ps1"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing required harness file: $path"
done

obsolete_files=(
  "docs/harness/README.md"
  "docs/harness/prompt-templates.md"
  "docs/harness/issue-workflow.md"
  "docs/harness/linear.md"
  "docs/harness/project-constraints.md"
  ".agents/prompts/loop-codex.md"
  ".agents/prompts/loop-automation.md"
  ".agents/prompts/maintenance-loop.md"
)

for path in "${obsolete_files[@]}"; do
  [[ ! -e "$path" ]] || fail "Obsolete harness file should not exist anymore: $path"
done

required_skill_frontmatter=(
  ".agents/skills/issue-goal-prompt/SKILL.md|name: issue-goal-prompt"
  ".agents/skills/project-plan-archive/SKILL.md|name: project-plan-archive"
  ".agents/skills/project-version-release/SKILL.md|name: project-version-release"
  ".agents/skills/test-runbook/SKILL.md|name: test-runbook"
)

for item in "${required_skill_frontmatter[@]}"; do
  path="${item%%|*}"
  pattern="${item#*|}"
  rg -Fq -- "---" "$path" || fail "Skill frontmatter is incomplete: $path"
  rg -Fq "$pattern" "$path" || fail "Skill frontmatter is incomplete: $path"
  rg -Fq "description:" "$path" || fail "Skill frontmatter is incomplete: $path"
done

if rg -n "DBBridge|db_bridge_test|/Users/suqing|TEA-" .agents/skills >/dev/null; then
  fail "Default harness skills must not contain project-specific constants"
fi

if command -v python3 >/dev/null 2>&1; then
  python3 .agents/skills/project-plan-archive/scripts/project_plan_archive.py --help >/dev/null
  python3 .agents/skills/project-version-release/scripts/project_version_release.py --help >/dev/null
fi

for target in "harness-check" "harness-verify" "harness-review-gate"; do
  rg -q "^${target}:" Makefile || fail "Makefile missing target: $target"
done

required_gitignore_patterns=(
  ".DS_Store"
  ".idea/"
  ".vscode/"
  "*.log"
  "logs/"
  "tmp/"
  "temp/"
  ".agents/state/*"
  "!.agents/state/TEMPLATE.md"
  ".agents/runs/*"
  "!.agents/runs/TEMPLATE.md"
  ".cursor/*"
  "!.cursor/rules/"
  "!.cursor/rules/*.mdc"
)

for pattern in "${required_gitignore_patterns[@]}"; do
  rg -Fq -- "$pattern" .gitignore || fail ".gitignore missing required pattern: $pattern"
done

project_placeholder='__PROJECT''_NAME__'
provider_placeholder='__PROVIDER''__'
issue_provider_placeholder='__ISSUE''_PROVIDER__'
issue_prefix_placeholder='__ISSUE''_PREFIX__'
placeholder_regex="${project_placeholder}|${provider_placeholder}|${issue_provider_placeholder}|${issue_prefix_placeholder}"

template_source=0
source_harness_root="$(cd "$repo_root/.." && pwd -P)"
canonical_source_template=""
if [[ -d "$source_harness_root/template" ]]; then
  canonical_source_template="$(cd "$source_harness_root/template" && pwd -P)"
fi
if rg -Fq "# $project_placeholder" README.md \
  && rg -Fq "$provider_placeholder" docs/harness/control-plane.md \
  && rg -Fq "$issue_provider_placeholder" docs/harness/control-plane.md \
  && [[ -f "$source_harness_root/scripts/verify_harness_source.sh" ]] \
  && [[ -f "$source_harness_root/scripts/verify_harness_source.ps1" ]] \
  && [[ -d "$source_harness_root/sources/agent_extensions" ]] \
  && [[ -n "$canonical_source_template" ]] \
  && [[ "$repo_root" == "$canonical_source_template" ]]; then
  template_source=1
fi

if [[ "$template_source" -eq 0 ]]; then
  if rg -n --hidden -g '!scripts/harness/check.sh' \
    "$placeholder_regex" \
    AGENTS.md README.md docs .agents Makefile >/dev/null; then
    fail "Unresolved harness initializer placeholder detected"
  fi

  merge_provider="$(awk '
    /当前 merge provider：/ { found=1; next }
    found && /^- `/ { value=$0; sub(/^- `/, "", value); sub(/`.*$/, "", value); print value; exit }
  ' docs/harness/control-plane.md)"
  issue_provider="$(awk '
    /当前 issue provider：/ { found=1; next }
    found && /^- `/ { value=$0; sub(/^- `/, "", value); sub(/`.*$/, "", value); print value; exit }
  ' docs/harness/control-plane.md)"

  [[ "$merge_provider" =~ ^(neutral|github|gitlab)$ ]] \
    || fail "Invalid merge provider: ${merge_provider:-missing}"
  [[ "$issue_provider" =~ ^(linear|github|gitlab|repo|other)$ ]] \
    || fail "Invalid issue provider: ${issue_provider:-missing}"

fi

if [[ -f ".cursor/rules/harness.mdc" ]]; then
  rg -Fq "alwaysApply: true" .cursor/rules/harness.mdc \
    || fail ".cursor/rules/harness.mdc missing alwaysApply: true"
  rg -Fq "make harness-verify" .cursor/rules/harness.mdc \
    || fail ".cursor/rules/harness.mdc missing harness verification entry"
fi

optional_mode_files=(
  ".agents/prompts/orchestrator-thread.md"
  ".agents/prompts/issue-standard-workflow.md"
  ".agents/guides/code-review.md"
  ".agents/guides/linter.md"
)

optional_bundle_files=(
  ".agents/prompts/README.md"
  "${optional_mode_files[@]}"
)

has_optional_bundle=0
for path in "${optional_bundle_files[@]}"; do
  if [[ -f "$path" ]]; then
    has_optional_bundle=1
    break
  fi
done

if [[ "$has_optional_bundle" -eq 1 ]]; then
  for path in "${optional_bundle_files[@]}"; do
    [[ -f "$path" ]] || fail "Optional agent extension bundle is incomplete: missing $path"
  done

  detected_mode=""
  for path in "${optional_mode_files[@]}"; do
    rg -qx "Mode: (placeholder|full)" "$path" \
      || fail "Optional harness file missing valid mode marker: $path"
    current_mode="$(sed -n '1s/^Mode: //p' "$path")"
    if [[ -z "$detected_mode" ]]; then
      detected_mode="$current_mode"
    elif [[ "$detected_mode" != "$current_mode" ]]; then
      fail "Optional agent extension bundle has mixed modes: expected $detected_mode, got $current_mode in $path"
    fi
  done
fi

bash -n scripts/harness/common.sh scripts/harness/review_gate.sh scripts/harness/evidence.sh

tmp_plan="$(mktemp -t harness-plan-pass)"
tmp_blocking_plan="$(mktemp -t harness-plan-blocking)"
tmp_evidence_repo="$(mktemp -d -t harness-evidence-smoke)"
trap 'rm -f "$tmp_plan" "$tmp_blocking_plan"; rm -rf "$tmp_evidence_repo"' EXIT

cp .agents/plans/EXAMPLE-implementation.md "$tmp_plan"
cp "$tmp_plan" "$tmp_blocking_plan"
perl -0pi -e 's/`blocking_findings`: none/`blocking_findings`: correctness regression/' "$tmp_blocking_plan"

if ! bash scripts/harness/review_gate.sh --plan "$tmp_plan" >/dev/null; then
  fail "review gate should pass for the implementation example"
fi
if bash scripts/harness/review_gate.sh --plan "$tmp_blocking_plan" >/dev/null 2>&1; then
  fail "review gate should fail when blocking findings are present"
fi

git init -q "$tmp_evidence_repo"
git -C "$tmp_evidence_repo" config user.name "Harness Check"
git -C "$tmp_evidence_repo" config user.email "harness-check@example.invalid"
printf 'base\n' >"$tmp_evidence_repo/value.txt"
git -C "$tmp_evidence_repo" add value.txt
git -C "$tmp_evidence_repo" commit -qm "test: evidence base"

evidence_first="$(cd "$tmp_evidence_repo" && bash "$repo_root/scripts/harness/evidence.sh" snapshot)"
evidence_second="$(cd "$tmp_evidence_repo" && bash "$repo_root/scripts/harness/evidence.sh" snapshot)"
first_id="$(printf '%s\n' "$evidence_first" | sed -n 's/^evidence_id=//p')"
second_id="$(printf '%s\n' "$evidence_second" | sed -n 's/^evidence_id=//p')"
[[ -n "$first_id" && "$first_id" == "$second_id" ]] \
  || fail "evidence helper should be stable for an unchanged repository"

printf 'changed\n' >>"$tmp_evidence_repo/value.txt"
evidence_changed="$(cd "$tmp_evidence_repo" && bash "$repo_root/scripts/harness/evidence.sh" snapshot)"
changed_id="$(printf '%s\n' "$evidence_changed" | sed -n 's/^evidence_id=//p')"
[[ -n "$changed_id" && "$changed_id" != "$first_id" ]] \
  || fail "evidence helper should change after repository content changes"

echo "harness check passed"
