#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$repo_root/template/scripts/harness/evidence.sh"
powershell_helper="$repo_root/template/scripts/harness/evidence.ps1"

fail() {
  echo "evidence helper test: $*" >&2
  exit 1
}

field() {
  local output="$1"
  local name="$2"

  printf '%s\n' "$output" | sed -n "s/^${name}=//p" | head -n 1
}

new_repo() {
  local path="$1"

  git init -q "$path"
  git -C "$path" config user.name "Harness Test"
  git -C "$path" config user.email "harness-test@example.invalid"
}

snapshot() {
  local path="$1"
  (cd "$path" && bash "$helper" snapshot)
}

if [[ ! -f "$helper" ]]; then
  fail "missing helper: $helper"
fi

set +e
unsupported_output="$(bash "$helper" unsupported 2>/dev/null)"
unsupported_status=$?
set -e
[[ "$unsupported_status" -eq 2 ]] || fail "unsupported action should exit 2"
[[ "$(field "$unsupported_output" reusable)" == "false" ]] \
  || fail "unsupported action must not return reusable evidence"
[[ "$(field "$unsupported_output" reason)" == "unsupported_action" ]] \
  || fail "unsupported action should report unsupported_action"

tmp_root="$(mktemp -d -t harness-evidence-test)"
trap 'rm -rf "$tmp_root"' EXIT

repo="$tmp_root/repo"
new_repo "$repo"
printf 'base\n' >"$repo/tracked.txt"
git -C "$repo" add tracked.txt
git -C "$repo" commit -qm "test: base"

clean_first="$(snapshot "$repo")"
clean_second="$(snapshot "$repo")"

[[ "$(field "$clean_first" result)" == "ok" ]] || fail "clean snapshot should succeed"
[[ "$(field "$clean_first" reusable)" == "true" ]] || fail "clean snapshot should be reusable"
[[ -n "$(field "$clean_first" head)" ]] || fail "clean snapshot should include head"
[[ -n "$(field "$clean_first" worktree_digest)" ]] || fail "clean snapshot should include worktree_digest"
[[ "$(field "$clean_first" evidence_id)" == "$(field "$clean_second" evidence_id)" ]] \
  || fail "same repository state should produce the same evidence_id"

visibility_repo="$tmp_root/index-visibility"
new_repo "$visibility_repo"
printf 'base\n' >"$visibility_repo/tracked.txt"
git -C "$visibility_repo" add tracked.txt
git -C "$visibility_repo" commit -qm "test: visibility base"

git -C "$visibility_repo" update-index --assume-unchanged tracked.txt
printf 'hidden change\n' >>"$visibility_repo/tracked.txt"
assume_unchanged_snapshot="$(snapshot "$visibility_repo")"
[[ "$(field "$assume_unchanged_snapshot" reusable)" == "false" ]] \
  || fail "assume-unchanged paths must disable evidence reuse"
[[ "$(field "$assume_unchanged_snapshot" reason)" == "index_visibility_flags" ]] \
  || fail "assume-unchanged paths should report index_visibility_flags"
git -C "$visibility_repo" update-index --no-assume-unchanged tracked.txt
git -C "$visibility_repo" reset -q --hard HEAD

git -C "$visibility_repo" update-index --skip-worktree tracked.txt
printf 'hidden change\n' >>"$visibility_repo/tracked.txt"
skip_worktree_snapshot="$(snapshot "$visibility_repo")"
[[ "$(field "$skip_worktree_snapshot" reusable)" == "false" ]] \
  || fail "skip-worktree paths must disable evidence reuse"
[[ "$(field "$skip_worktree_snapshot" reason)" == "index_visibility_flags" ]] \
  || fail "skip-worktree paths should report index_visibility_flags"
git -C "$visibility_repo" update-index --no-skip-worktree tracked.txt

symlink_repo="$tmp_root/symlink"
new_repo "$symlink_repo"
printf 'target-*\n' >"$symlink_repo/.gitignore"
printf 'same content\n' >"$symlink_repo/target-one"
printf 'same content\n' >"$symlink_repo/target-two"
ln -s target-one "$symlink_repo/link"
symlink_first="$(snapshot "$symlink_repo")"
unlink "$symlink_repo/link"
ln -s target-two "$symlink_repo/link"
symlink_second="$(snapshot "$symlink_repo")"
[[ "$(field "$symlink_first" evidence_id)" != "$(field "$symlink_second" evidence_id)" ]] \
  || fail "untracked symlink retargeting must invalidate evidence_id"

printf 'changed\n' >>"$repo/tracked.txt"
tracked_change="$(snapshot "$repo")"

[[ "$(field "$tracked_change" evidence_id)" != "$(field "$clean_first" evidence_id)" ]] \
  || fail "tracked content changes should invalidate evidence_id"

git -C "$repo" add tracked.txt
staged_change="$(snapshot "$repo")"
[[ "$(field "$staged_change" evidence_id)" != "$(field "$clean_first" evidence_id)" ]] \
  || fail "staged content changes should invalidate evidence_id"

printf 'base\n' >"$repo/tracked.txt"
staged_then_reverted_worktree="$(snapshot "$repo")"
[[ "$(field "$staged_then_reverted_worktree" evidence_id)" != "$(field "$clean_first" evidence_id)" ]] \
  || fail "staged changes must remain visible when an unstaged edit restores the HEAD content"

git -C "$repo" reset -q --hard HEAD
printf 'new\n' >"$repo/new file.txt"
untracked_change="$(snapshot "$repo")"
[[ "$(field "$untracked_change" evidence_id)" != "$(field "$clean_first" evidence_id)" ]] \
  || fail "untracked content should invalidate evidence_id"

printf 'newer\n' >>"$repo/new file.txt"
untracked_content_change="$(snapshot "$repo")"
[[ "$(field "$untracked_content_change" evidence_id)" != "$(field "$untracked_change" evidence_id)" ]] \
  || fail "untracked content changes should invalidate evidence_id"

printf 'unreadable\n' >"$repo/unreadable.txt"
chmod 000 "$repo/unreadable.txt"
set +e
unreadable_snapshot="$(snapshot "$repo" 2>/dev/null)"
unreadable_status=$?
set -e
chmod 600 "$repo/unreadable.txt"
rm -f "$repo/unreadable.txt"
[[ "$unreadable_status" -ne 0 ]] || fail "unreadable files should fail snapshot calculation"
[[ "$(field "$unreadable_snapshot" reusable)" == "false" ]] \
  || fail "unreadable files must not produce reusable evidence"
[[ "$(field "$unreadable_snapshot" reason)" == "snapshot_failed" ]] \
  || fail "unreadable files should report snapshot_failed"

rm -f "$repo/new file.txt"
rm -f "$repo/tracked.txt"
deleted_change="$(snapshot "$repo")"
[[ "$(field "$deleted_change" evidence_id)" != "$(field "$clean_first" evidence_id)" ]] \
  || fail "deleted tracked files should invalidate evidence_id"

git -C "$repo" reset -q --hard HEAD
git -C "$repo" mv tracked.txt renamed.txt
renamed_change="$(snapshot "$repo")"
[[ "$(field "$renamed_change" evidence_id)" != "$(field "$clean_first" evidence_id)" ]] \
  || fail "renamed tracked files should invalidate evidence_id"

unborn_repo="$tmp_root/unborn"
new_repo "$unborn_repo"
printf 'first\n' >"$unborn_repo/untracked.txt"
unborn_first="$(snapshot "$unborn_repo")"
printf 'second\n' >>"$unborn_repo/untracked.txt"
unborn_second="$(snapshot "$unborn_repo")"

[[ "$(field "$unborn_first" head)" == "UNBORN" ]] || fail "unborn repository should use UNBORN head"
[[ "$(field "$unborn_first" evidence_id)" != "$(field "$unborn_second" evidence_id)" ]] \
  || fail "unborn untracked content changes should invalidate evidence_id"

conflict_repo="$tmp_root/conflict"
new_repo "$conflict_repo"
printf 'base\n' >"$conflict_repo/conflict.txt"
git -C "$conflict_repo" add conflict.txt
git -C "$conflict_repo" commit -qm "test: conflict base"
git -C "$conflict_repo" switch -qc other
printf 'other\n' >"$conflict_repo/conflict.txt"
git -C "$conflict_repo" commit -qam "test: other change"
git -C "$conflict_repo" switch -q master
printf 'main\n' >"$conflict_repo/conflict.txt"
git -C "$conflict_repo" commit -qam "test: main change"
if git -C "$conflict_repo" merge other >/dev/null 2>&1; then
  fail "conflict fixture should not merge cleanly"
fi

conflict_snapshot="$(snapshot "$conflict_repo")"
[[ "$(field "$conflict_snapshot" result)" == "ok" ]] || fail "conflict snapshot should still be readable"
[[ "$(field "$conflict_snapshot" reusable)" == "false" ]] || fail "unmerged entries must not be reusable"
[[ "$(field "$conflict_snapshot" reason)" == "unmerged_entries" ]] \
  || fail "unmerged entries should report a stable reason"

submodule_origin="$tmp_root/submodule-origin"
new_repo "$submodule_origin"
printf 'submodule\n' >"$submodule_origin/value.txt"
git -C "$submodule_origin" add value.txt
git -C "$submodule_origin" commit -qm "test: submodule base"

submodule_repo="$tmp_root/submodule-repo"
new_repo "$submodule_repo"
printf 'root\n' >"$submodule_repo/root.txt"
git -C "$submodule_repo" add root.txt
git -C "$submodule_repo" commit -qm "test: root base"
git -C "$submodule_repo" -c protocol.file.allow=always submodule add -q "$submodule_origin" deps/sub
git -C "$submodule_repo" commit -qam "test: add submodule"
printf 'dirty\n' >>"$submodule_repo/deps/sub/value.txt"

submodule_snapshot="$(snapshot "$submodule_repo")"
[[ "$(field "$submodule_snapshot" result)" == "ok" ]] || fail "dirty submodule snapshot should be readable"
[[ "$(field "$submodule_snapshot" reusable)" == "false" ]] || fail "dirty submodules must not be reusable"
[[ "$(field "$submodule_snapshot" reason)" == "dirty_or_unavailable_submodule" ]] \
  || fail "dirty submodules should report a stable reason"

[[ -f "$powershell_helper" ]] || fail "missing PowerShell helper: $powershell_helper"
for pattern in \
  'Action = "Snapshot"' \
  'result=' \
  'head=' \
  'worktree_digest=' \
  'evidence_id=' \
  'reusable=' \
  'reason=' \
  'unsupported_action' \
  'git diff --binary --no-ext-diff' \
  '"--cached"' \
  '"worktree`0"' \
  'git ls-files --others --exclude-standard -z' \
  'git ls-files -u' \
  'git submodule' \
  '"submodules`0"'; do
  rg -Fq -- "$pattern" "$powershell_helper" \
    || fail "PowerShell helper missing contract pattern: $pattern"
done
for pattern in \
  'index_visibility_flags' \
  'git ls-files -v' \
  'LinkTarget'; do
  rg -Fq -- "$pattern" "$powershell_helper" \
    || fail "PowerShell helper missing conservative visibility/symlink contract: $pattern"
done
if rg -Fq 'Get-Item -LiteralPath $null' "$powershell_helper"; then
  fail "PowerShell unborn branch setup must not pass a null path to git hash-object"
fi

echo "evidence helper tests passed"
