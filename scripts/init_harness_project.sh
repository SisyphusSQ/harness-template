#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
initializer_root="$(cd "$script_dir/.." && pwd)"
template_dir="$initializer_root/template"
shared_gitignore_dir="$initializer_root/sources/gitignore"

target=""
project_name=""
stack=""
issue_provider="linear"
issue_prefix=""
force=0
dry_run=0

usage() {
  cat <<'EOF'
Usage: bash scripts/init_harness_project.sh \
  --target /abs/path/to/repo \
  --project-name NAME \
  --stack go|python|java|c|go-node|python-node|java-node|c-node|java-c|java-c-node \
  [--issue-provider linear|github|gitlab|repo|other] \
  [--issue-prefix PREFIX] \
  [--force] \
  [--dry-run]
EOF
}

require_arg() {
  local flag="$1"
  local value="${2:-}"
  [[ -n "$value" ]] || { echo "missing value for $flag" >&2; exit 2; }
}

validate_stack() {
  case "$stack" in
    go|python|java|c|go-node|python-node|java-node|c-node|java-c|java-c-node) ;;
    *) echo "unsupported stack: $stack" >&2; exit 2 ;;
  esac
}

validate_issue_provider() {
  case "$issue_provider" in
    linear|github|gitlab|repo|other) ;;
    *) echo "unsupported issue provider: $issue_provider" >&2; exit 2 ;;
  esac
}

validate_target() {
  [[ "$target" == /* ]] || { echo "--target must be an absolute path: $target" >&2; exit 2; }
  if [[ -e "$target" && ! -d "$target" ]]; then
    echo "target exists and is not a directory: $target" >&2
    exit 2
  fi
}

obsolete_managed_files=(
  "Makefile"
  "docs/harness/control-plane.md"
  "docs/harness/README.md"
  "docs/harness/prompt-templates.md"
  "docs/harness/issue-workflow.md"
  "docs/harness/linear.md"
  "docs/harness/project-constraints.md"
  "scripts/harness/check.sh"
  "scripts/harness/common.sh"
  "scripts/harness/evidence.sh"
  "scripts/harness/review_gate.sh"
  "scripts/harness/check.ps1"
  "scripts/harness/common.ps1"
  "scripts/harness/evidence.ps1"
  "scripts/harness/review_gate.ps1"
  ".agents/prompts/README.md"
  ".agents/prompts/issue-standard-workflow.md"
  ".agents/prompts/orchestrator-thread.md"
  ".agents/prompts/loop-codex.md"
  ".agents/prompts/loop-automation.md"
  ".agents/prompts/maintenance-loop.md"
  ".agents/guides/code-review.md"
  ".agents/guides/linter.md"
  ".agents/mappings/reference-mapping.yaml"
  ".agents/mappings/knowledge-writeback-mapping.example.yaml"
)

obsolete_managed_directories=(
  "docs/harness"
  "scripts/harness"
  ".agents/prompts"
  ".agents/guides"
  ".agents/mappings"
)

cleanup_obsolete_managed_files() {
  local found=0
  for rel in "${obsolete_managed_files[@]}"; do
    if [[ -e "$target/$rel" ]]; then
      found=1
      if [[ "$force" -eq 1 ]]; then
        if [[ "$dry_run" -eq 1 ]]; then
          printf '[dry-run] remove obsolete managed file %s\n' "$target/$rel"
        else
          rm -f "$target/$rel"
        fi
      fi
    fi
  done
  if [[ "$found" -eq 1 && "$force" -ne 1 && "$dry_run" -ne 1 ]]; then
    echo "obsolete managed files detected in target; rerun with --force to clean them before initialization" >&2
    exit 1
  fi
  if [[ "$force" -eq 1 ]]; then
    for rel in "${obsolete_managed_directories[@]}"; do
      if [[ -d "$target/$rel" ]]; then
        if [[ "$dry_run" -eq 1 ]]; then
          printf '[dry-run] remove empty obsolete managed directory %s\n' "$target/$rel"
        else
          rmdir "$target/$rel" 2>/dev/null || true
        fi
      fi
    done
  fi
}

copy_file() {
  local src="$1"
  local dest="$2"
  if [[ -e "$dest" && "$force" -ne 1 ]]; then
    echo "refusing to overwrite existing file without --force: $dest" >&2
    exit 1
  fi
  if [[ "$dry_run" -eq 1 ]]; then
    printf '[dry-run] copy %s -> %s\n' "$src" "$dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

gitignore_parts() {
  local parts=("$shared_gitignore_dir/base.gitignore")
  case "$stack" in
    go) parts+=("$shared_gitignore_dir/go.gitignore") ;;
    python) parts+=("$shared_gitignore_dir/python.gitignore") ;;
    java) parts+=("$shared_gitignore_dir/java.gitignore") ;;
    c) parts+=("$shared_gitignore_dir/c.gitignore") ;;
    go-node) parts+=("$shared_gitignore_dir/go.gitignore" "$shared_gitignore_dir/node-frontend.gitignore") ;;
    python-node) parts+=("$shared_gitignore_dir/python.gitignore" "$shared_gitignore_dir/node-frontend.gitignore") ;;
    java-node) parts+=("$shared_gitignore_dir/java.gitignore" "$shared_gitignore_dir/node-frontend.gitignore") ;;
    c-node) parts+=("$shared_gitignore_dir/c.gitignore" "$shared_gitignore_dir/node-frontend.gitignore") ;;
    java-c) parts+=("$shared_gitignore_dir/java.gitignore" "$shared_gitignore_dir/c.gitignore") ;;
    java-c-node) parts+=("$shared_gitignore_dir/java.gitignore" "$shared_gitignore_dir/c.gitignore" "$shared_gitignore_dir/node-frontend.gitignore") ;;
  esac
  printf '%s\n' "${parts[@]}"
}

build_gitignore() {
  local output="$1"
  mapfile -t parts < <(gitignore_parts)
  if [[ "$dry_run" -eq 1 ]]; then
    printf '[dry-run] build .gitignore from:\n'
    printf '  - %s\n' "${parts[@]}"
    return
  fi
  {
    printf '# Generated by the project initializer.\n\n'
    for part in "${parts[@]}"; do
      cat "$part"
      printf '\n'
    done
  } >"$output"
}

escape_replacement() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\//\\/}"
  value="${value//&/\\&}"
  printf '%s' "$value"
}

replace_placeholders() {
  local file="$1"
  local project_escaped prefix_escaped issue_provider_escaped
  project_escaped="$(escape_replacement "$project_name")"
  prefix_escaped="$(escape_replacement "$issue_prefix")"
  issue_provider_escaped="$(escape_replacement "$issue_provider")"
  perl -0pi -e "s/__PROJECT_NAME__/$project_escaped/g; s/__ISSUE_PREFIX__/$prefix_escaped/g; s/__ISSUE_PROVIDER__/$issue_provider_escaped/g" "$file"
}

postprocess_text_files() {
  local files=(
    "$target/AGENTS.md"
    "$target/README.md"
    "$target/.agents/PLANS.md"
    "$target/.agents/plans/TEMPLATE.md"
    "$target/.agents/plans/EXAMPLE-implementation.md"
    "$target/.agents/state/TEMPLATE.md"
    "$target/.agents/runs/TEMPLATE.md"
    "$target/docs/test/RUNBOOK_TEMPLATE.md"
  )
  if [[ "$issue_provider" == "repo" ]]; then
    files+=("$target/docs/issues/README.md" "$target/docs/issues/TEMPLATE.md")
  fi
  if [[ "$dry_run" -eq 1 ]]; then
    printf '[dry-run] replace placeholders in template text files\n'
    return
  fi
  for file in "${files[@]}"; do
    replace_placeholders "$file"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) require_arg "$1" "${2:-}"; target="$2"; shift 2 ;;
    --project-name) require_arg "$1" "${2:-}"; project_name="$2"; shift 2 ;;
    --stack) require_arg "$1" "${2:-}"; stack="$2"; shift 2 ;;
    --issue-provider) require_arg "$1" "${2:-}"; issue_provider="$2"; shift 2 ;;
    --issue-prefix) require_arg "$1" "${2:-}"; issue_prefix="$2"; shift 2 ;;
    --force) force=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$target" || -z "$project_name" || -z "$stack" ]]; then
  usage >&2
  exit 2
fi

validate_stack
validate_issue_provider
validate_target

[[ "$dry_run" -eq 1 ]] || mkdir -p "$target"
cleanup_obsolete_managed_files

managed_files=(
  "AGENTS.md"
  "README.md"
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
  "docs/test/RUNBOOK_TEMPLATE.md"
)
if [[ "$issue_provider" == "repo" ]]; then
  managed_files+=("docs/issues/README.md" "docs/issues/TEMPLATE.md")
fi

for rel in "${managed_files[@]}"; do
  copy_file "$template_dir/$rel" "$target/$rel"
done

if [[ -e "$target/.gitignore" && "$force" -ne 1 && "$dry_run" -ne 1 ]]; then
  echo "refusing to overwrite existing file without --force: $target/.gitignore" >&2
  exit 1
fi
if [[ "$dry_run" -eq 1 ]]; then
  printf '[dry-run] copy %s/.gitignore -> %s/.gitignore (will be rebuilt)\n' "$template_dir" "$target"
else
  mkdir -p "$(dirname "$target/.gitignore")"
  cp "$template_dir/.gitignore" "$target/.gitignore"
fi

build_gitignore "$target/.gitignore"
postprocess_text_files

printf 'initialized project baseline into: %s\n' "$target"
printf 'stack: %s\n' "$stack"
printf 'issue provider: %s\n' "$issue_provider"
printf 'next steps:\n'
printf '  1. fill AGENTS.md with repo-specific build, test, lint, live E2E, and release constraints\n'
printf '  2. read the skills or runbook that match the task\n'
printf '  3. create a plan under .agents/plans/ only when the task needs one\n'
printf '  4. keep real .agents/state/ and .agents/runs/ files local unless the project explicitly tracks them\n'
