#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_root="$repo_root/template"

fail() {
  echo "target check contract test: $*" >&2
  exit 1
}

new_target() {
  local destination="$1"

  mkdir -p "$destination"
  cp -R "$template_root/." "$destination/"
  while IFS= read -r -d '' path; do
    perl -0pi -e \
      's/__PROJECT_NAME__/Harness Test/g; s/__PROVIDER__/neutral/g; s/__ISSUE_PROVIDER__/linear/g; s/__ISSUE_PREFIX__/TST/g' \
      "$path"
  done < <(rg -l -0 --hidden '__PROJECT_NAME__|__PROVIDER__|__ISSUE_PROVIDER__|__ISSUE_PREFIX__' "$destination" || true)
}

expect_pass() {
  local target="$1"
  local label="$2"

  if ! (cd "$target" && bash scripts/harness/check.sh) >"$target/check.out" 2>&1; then
    sed -n '1,120p' "$target/check.out" >&2
    fail "$label should pass"
  fi
}

expect_fail() {
  local target="$1"
  local label="$2"

  if (cd "$target" && bash scripts/harness/check.sh) >"$target/check.out" 2>&1; then
    fail "$label should fail"
  fi
}

tmp_root="$(mktemp -d -t harness-target-check-test)"
trap 'rm -rf "$tmp_root"' EXIT

untouched="$tmp_root/untouched-template"
mkdir -p "$untouched"
cp -R "$template_root/." "$untouched/"
expect_fail "$untouched" "untouched source template copied as a target"

fake_source_root="$tmp_root/fake-source-root"
mkdir -p \
  "$fake_source_root/scripts" \
  "$fake_source_root/sources/agent_extensions" \
  "$fake_source_root/not-template"
: >"$fake_source_root/scripts/verify_harness_source.sh"
: >"$fake_source_root/scripts/verify_harness_source.ps1"
cp -R "$template_root/." "$fake_source_root/not-template/"
expect_fail "$fake_source_root/not-template" "source sentinel outside the canonical template directory"

baseline="$tmp_root/baseline"
new_target "$baseline"
expect_pass "$baseline" "baseline target"

wording="$tmp_root/wording"
new_target "$wording"
perl -0pi -e 's/## Maintenance Loop/## Maintenance Cycle/' "$wording/docs/harness/control-plane.md"
expect_pass "$wording" "non-contract wording change"

missing="$tmp_root/missing"
new_target "$missing"
rm -f "$missing/AGENTS.md"
expect_fail "$missing" "missing core file"

placeholder="$tmp_root/placeholder"
new_target "$placeholder"
printf '\nUnresolved: __PROJECT_NAME__\n' >>"$placeholder/README.md"
expect_fail "$placeholder" "unresolved initializer placeholder"

invalid_provider="$tmp_root/invalid-provider"
new_target "$invalid_provider"
perl -0pi -e 's/(当前 merge provider：\n\n)- `neutral`/${1}- `invalid`/' \
  "$invalid_provider/docs/harness/control-plane.md"
expect_fail "$invalid_provider" "invalid merge provider"

mixed_mode="$tmp_root/mixed-mode"
new_target "$mixed_mode"
cp -R "$repo_root/sources/agent_extensions/shared/." "$mixed_mode/"
cp -R "$repo_root/sources/agent_extensions/full/." "$mixed_mode/"
perl -0pi -e 's/^Mode: full/Mode: placeholder/' \
  "$mixed_mode/.agents/prompts/loop-codex.md"
expect_fail "$mixed_mode" "mixed extension mode"

powershell_check="$template_root/scripts/harness/check.ps1"
for pattern in \
  'evidence.ps1' \
  'Unresolved harness initializer placeholder detected' \
  'Optional agent extension bundle has mixed modes' \
  'harness check passed'; do
  rg -Fq -- "$pattern" "$powershell_check" \
    || fail "PowerShell target check missing runtime contract: $pattern"
done
for source_only_pattern in \
  'requiredControlPlanePatterns' \
  'requiredPlansPatterns' \
  'tmpBadPlanNoSteps' \
  'tmpBadPlanHarnessFlow'; do
  if rg -Fq -- "$source_only_pattern" "$powershell_check"; then
    fail "PowerShell target check still contains source-only contract: $source_only_pattern"
  fi
done

echo "target check contract tests passed"
