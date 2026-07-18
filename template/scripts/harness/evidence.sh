#!/usr/bin/env bash

set -euo pipefail

action="${1:-snapshot}"

emit_snapshot() {
  local result="$1"
  local head="$2"
  local worktree_digest="$3"
  local evidence_id="$4"
  local reusable="$5"
  local reason="$6"

  printf 'result=%s\n' "$result"
  printf 'head=%s\n' "$head"
  printf 'worktree_digest=%s\n' "$worktree_digest"
  printf 'evidence_id=%s\n' "$evidence_id"
  printf 'reusable=%s\n' "$reusable"
  printf 'reason=%s\n' "$reason"
}

if [[ "$action" != "snapshot" ]]; then
  emit_snapshot "error" "UNKNOWN" "UNKNOWN" "UNKNOWN" "false" "unsupported_action"
  exit 2
fi

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  emit_snapshot "error" "UNKNOWN" "UNKNOWN" "UNKNOWN" "false" "not_git_repository"
  exit 1
fi

cd "$repo_root"

if head_commit="$(git rev-parse --verify HEAD 2>/dev/null)"; then
  diff_base="$head_commit"
else
  head_commit="UNBORN"
  diff_base="$(git hash-object -t tree /dev/null)"
fi

snapshot_file="$(mktemp -t harness-evidence-snapshot)"
untracked_file="$(mktemp -t harness-evidence-untracked)"
trap 'rm -f "$snapshot_file" "$untracked_file"' EXIT

if ! git ls-files --others --exclude-standard -z >"$untracked_file"; then
  emit_snapshot "error" "$head_commit" "UNKNOWN" "UNKNOWN" "false" "snapshot_failed"
  exit 1
fi

write_snapshot_payload() {
  local path
  local blob_hash
  local submodule_status

  printf 'head\0%s\0' "$head_commit"

  printf 'index\0'
  if ! git diff --binary --no-ext-diff --cached "$diff_base" --; then
    return 1
  fi

  printf 'worktree\0'
  if ! git diff --binary --no-ext-diff --; then
    return 1
  fi

  while IFS= read -r -d '' path; do
    if [[ -L "$path" ]]; then
      if ! blob_hash="$(readlink -n -- "$path" | git hash-object --stdin)"; then
        return 1
      fi
    elif ! blob_hash="$(git hash-object -- "$path")"; then
      return 1
    fi
    printf 'untracked\0%s\0%s\0' "$path" "$blob_hash"
  done <"$untracked_file"

  if ! submodule_status="$(git submodule status --recursive 2>/dev/null)"; then
    return 1
  fi
  printf 'submodules\0%s\0' "$submodule_status"
}

if ! write_snapshot_payload >"$snapshot_file"; then
  emit_snapshot "error" "$head_commit" "UNKNOWN" "UNKNOWN" "false" "snapshot_failed"
  exit 1
fi

worktree_digest="$(git hash-object "$snapshot_file")"
evidence_id="$(printf '%s\n%s\n' "$head_commit" "$worktree_digest" | git hash-object --stdin)"
reusable="true"
reason="snapshot_stable"
index_visibility=""

if [[ -n "$(git ls-files -u)" ]]; then
  reusable="false"
  reason="unmerged_entries"
elif ! index_visibility="$(git ls-files -v)"; then
  reusable="false"
  reason="snapshot_failed"
elif printf '%s\n' "$index_visibility" | grep -Eq '^[a-zS]'; then
  reusable="false"
  reason="index_visibility_flags"
elif git submodule status --recursive 2>/dev/null | grep -Eq '^[+-U]'; then
  reusable="false"
  reason="dirty_or_unavailable_submodule"
elif ! git submodule foreach --quiet --recursive \
  'test -z "$(git status --porcelain --untracked-files=normal)"' >/dev/null 2>&1; then
  reusable="false"
  reason="dirty_or_unavailable_submodule"
fi

emit_snapshot "ok" "$head_commit" "$worktree_digest" "$evidence_id" "$reusable" "$reason"
