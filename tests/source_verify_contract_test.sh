#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "source verify contract test: $*" >&2
  exit 1
}

expect_source_pass() {
  local root="$1"
  local label="$2"
  local output

  output="$(mktemp -t harness-source-pass)"

  if ! HARNESS_SOURCE_SKIP_EXTERNAL_TESTS=1 \
    bash "$root/scripts/verify_harness_source.sh" >"$output" 2>&1; then
    sed -n '1,160p' "$output" >&2
    rm -f "$output"
    fail "$label should pass source verification"
  fi
  rm -f "$output"
}

expect_source_fail() {
  local root="$1"
  local label="$2"
  local output

  output="$(mktemp -t harness-source-fail)"
  if HARNESS_SOURCE_SKIP_EXTERNAL_TESTS=1 \
    bash "$root/scripts/verify_harness_source.sh" >"$output" 2>&1; then
    rm -f "$output"
    fail "$label should fail source verification"
  fi
  rm -f "$output"
}

new_source_fixture() {
  local destination="$1"

  mkdir -p "$destination/scripts"
  cp -R "$repo_root/template" "$destination/template"
  cp -R "$repo_root/sources" "$destination/sources"
  cp "$repo_root/scripts/init_harness_project.sh" "$destination/scripts/"
  cp "$repo_root/scripts/init_harness_project.ps1" "$destination/scripts/"
  cp "$repo_root/scripts/verify_harness_source.sh" "$destination/scripts/"
  cp "$repo_root/scripts/verify_harness_source.ps1" "$destination/scripts/"
  cp "$repo_root/README.md" "$destination/"
  cp "$repo_root/agent-init-project.md" "$destination/"
  cp "$repo_root/init-harness-project-sop.md" "$destination/"
  cp "$repo_root/Makefile" "$destination/"
}

for path in \
  "$repo_root/Makefile" \
  "$repo_root/scripts/verify_harness_source.sh" \
  "$repo_root/scripts/verify_harness_source.ps1"; do
  [[ -f "$path" ]] || fail "missing source verification entry: $path"
done

for test_entry in \
  'tests/evidence_helper_test.sh' \
  'tests/target_check_contract_test.sh' \
  'tests/policy_contract_test.sh'; do
  rg -Fq -- "$test_entry" "$repo_root/scripts/verify_harness_source.sh" \
    || fail "source verification entry must execute $test_entry"
done

expect_source_pass "$repo_root" "repository baseline"

tmp_root="$(mktemp -d -t harness-source-verify-test)"
trap 'rm -rf "$tmp_root"' EXIT

wording="$tmp_root/wording"
new_source_fixture "$wording"
perl -0pi -e 's/## Maintenance Loop/## Maintenance Cycle/' \
  "$wording/template/docs/harness/control-plane.md"
expect_source_fail "$wording" "control-plane contract drift"

plan_contract="$tmp_root/plan-contract"
new_source_fixture "$plan_contract"
perl -0pi -e 's/## Reference Snippets/## Reference Samples/' \
  "$plan_contract/template/.agents/plans/TEMPLATE.md"
expect_source_fail "$plan_contract" "plan template contract drift"

powershell_contract="$tmp_root/powershell-contract"
new_source_fixture "$powershell_contract"
perl -0pi -e 's/Get-PlanImplementationSkeletonErrors/Get-PlanSkeletonErrors/g' \
  "$powershell_contract/template/scripts/harness/common.ps1"
expect_source_fail "$powershell_contract" "PowerShell gate contract drift"

policy_contract="$tmp_root/policy-contract"
new_source_fixture "$policy_contract"
while IFS= read -r -d '' path; do
  perl -0pi -e 's/review_policy/review_strategy/g; s/evidence_id/snapshot_id/g' "$path"
done < <(find \
  "$policy_contract/sources/agent_extensions/full" \
  "$policy_contract/sources/agent_extensions/placeholder" \
  -type f -print0)
expect_source_fail "$policy_contract" "extension review/evidence contract drift"

echo "source verify contract tests passed"
