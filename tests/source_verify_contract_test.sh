#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
  printf 'source verify contract test: %s\n' "$*" >&2
  exit 1
}

expect_pass() {
  local root="$1"
  local label="$2"
  local output="$3"

  if ! bash "$root/scripts/verify_harness_source.sh" >"$output" 2>&1; then
    sed -n '1,160p' "$output" >&2
    fail "$label should pass source verification"
  fi
}

expect_fail() {
  local root="$1"
  local label="$2"
  local output="$3"

  if bash "$root/scripts/verify_harness_source.sh" >"$output" 2>&1; then
    sed -n '1,160p' "$output" >&2
    fail "$label should fail source verification"
  fi
}

new_source_fixture() {
  local destination="$1"

  mkdir -p "$destination"
  cp -R "$repo_root/template" "$destination/template"
  cp -R "$repo_root/sources" "$destination/sources"
  mkdir -p "$destination/scripts" "$destination/tests"
  cp "$repo_root/scripts/init_harness_project.sh" "$destination/scripts/"
  cp "$repo_root/scripts/init_harness_project.ps1" "$destination/scripts/"
  cp "$repo_root/scripts/verify_harness_source.sh" "$destination/scripts/"
  cp "$repo_root/scripts/verify_harness_source.ps1" "$destination/scripts/"
  cp "$repo_root/README.md" "$destination/"
  cp "$repo_root/agent-init-project.md" "$destination/"
  cp "$repo_root/init-harness-project-sop.md" "$destination/"
  cp "$repo_root/Makefile" "$destination/"
  cp "$repo_root/tests/source_verify_contract_test.sh" "$destination/tests/"
  cp "$repo_root/tests/target_check_contract_test.sh" "$destination/tests/"
  cp "$repo_root/tests/policy_contract_test.sh" "$destination/tests/"
}

for path in \
  "$repo_root/Makefile" \
  "$repo_root/scripts/verify_harness_source.sh" \
  "$repo_root/scripts/verify_harness_source.ps1"; do
  [[ -f "$path" ]] || fail "missing source verification entry: $path"
done

tmp_root="$(mktemp -d -t initializer-source-contract)"
trap 'rm -rf "$tmp_root"' EXIT

baseline="$tmp_root/baseline"
new_source_fixture "$baseline"
expect_pass "$baseline" "repository baseline" "$tmp_root/baseline.out"

missing_skill="$tmp_root/missing-skill"
new_source_fixture "$missing_skill"
rm -f "$missing_skill/template/.agents/skills/test-runbook/SKILL.md"
expect_fail "$missing_skill" "missing template skill" "$tmp_root/missing-skill.out"

legacy_path="$tmp_root/legacy-path"
new_source_fixture "$legacy_path"
mkdir -p "$legacy_path/template/scripts/harness"
: >"$legacy_path/template/scripts/harness/check.sh"
expect_fail "$legacy_path" "legacy target flow source" "$tmp_root/legacy-path.out"

wrong_default="$tmp_root/wrong-default"
new_source_fixture "$wrong_default"
perl -0pi -e 's/issue_provider="linear"/issue_provider="other"/' \
  "$wrong_default/scripts/init_harness_project.sh"
expect_fail "$wrong_default" "non-linear default" "$tmp_root/wrong-default.out"

printf 'source verify contract tests passed\n'
