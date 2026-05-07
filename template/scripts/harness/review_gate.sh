#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/common.sh"

cd "$repo_root"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/harness/review_gate.sh --plan path/to/plan.md
  bash scripts/harness/review_gate.sh path/to/plan.md
EOF
}

plan_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)
      if [[ -z "${2:-}" ]]; then
        echo "review gate: missing value for --plan" >&2
        exit 2
      fi
      plan_path="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$plan_path" ]]; then
        echo "review gate: unexpected argument: $1" >&2
        exit 2
      fi
      plan_path="$1"
      shift
      ;;
  esac
done

if [[ -z "$plan_path" ]]; then
  echo "review gate: pass a plan path via --plan or the first argument" >&2
  exit 2
fi

if [[ ! -f "$plan_path" ]]; then
  echo "review gate: missing plan file: $plan_path" >&2
  exit 2
fi

plan_structure_errors="$(collect_plan_implementation_skeleton_errors "$plan_path" || true)"

if [[ -n "$plan_structure_errors" ]]; then
  printf 'result=fail\n' >&2
  printf 'reason=plan implementation skeleton is incomplete\n' >&2
  printf '%s\n' "$plan_structure_errors" >&2
  printf 'plan=%s\n' "$plan_path" >&2
  exit 1
fi

blocking_findings="$(extract_section_field "$plan_path" "## Review Summary" "blocking_findings" || true)"

if [[ -z "$blocking_findings" ]]; then
  echo "review gate: missing blocking_findings in $plan_path" >&2
  exit 2
fi

normalized="$(
  printf '%s' "$blocking_findings" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/`//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
)"

if [[ "$normalized" == "none" ]]; then
  printf 'result=pass\n'
  printf 'blocking_findings=none\n'
  printf 'plan=%s\n' "$plan_path"
  exit 0
fi

printf 'result=fail\n' >&2
printf 'blocking_findings=%s\n' "$blocking_findings" >&2
printf 'plan=%s\n' "$plan_path" >&2
exit 1
