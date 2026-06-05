#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

required_files=(
  ".gitignore"
  "AGENTS.md"
  "README.md"
  "docs/harness/control-plane.md"
  "docs/harness/issue-workflow.md"
  "docs/harness/linear.md"
  "docs/harness/project-constraints.md"
  "docs/issues/README.md"
  "docs/issues/TEMPLATE.md"
  "docs/test/RUNBOOK_TEMPLATE.md"
  ".agents/PLANS.md"
  ".agents/plans/TEMPLATE.md"
  ".agents/plans/EXAMPLE-implementation.md"
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
  "scripts/harness/check.ps1"
  "scripts/harness/common.ps1"
  "scripts/harness/review_gate.ps1"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required harness file: $path" >&2
    exit 1
  fi
done

required_skill_frontmatter=(
  ".agents/skills/project-plan-archive/SKILL.md|name: project-plan-archive"
  ".agents/skills/project-version-release/SKILL.md|name: project-version-release"
  ".agents/skills/test-runbook/SKILL.md|name: test-runbook"
)

for item in "${required_skill_frontmatter[@]}"; do
  path="${item%%|*}"
  pattern="${item#*|}"
  if ! rg -Fq -- "---" "$path" || ! rg -Fq "$pattern" "$path" || ! rg -Fq "description:" "$path"; then
    echo "Skill frontmatter is incomplete: $path" >&2
    exit 1
  fi
done

required_skill_patterns=(
  ".agents/skills/project-plan-archive/SKILL.md|先查 Issue Tracker，再归档"
  ".agents/skills/project-plan-archive/SKILL.md|--done-issue"
  ".agents/skills/project-plan-archive/SKILL.md|no_issue_default_archive"
  ".agents/skills/project-plan-archive/scripts/project_plan_archive.py|Project plan archive helper"
  ".agents/skills/project-plan-archive/scripts/project_plan_archive.py|--write"
  ".agents/skills/project-version-release/SKILL.md|issue 是执行粒度，release 是发布粒度"
  ".agents/skills/project-version-release/SKILL.md|CHANGELOG.md -> Unreleased"
  ".agents/skills/project-version-release/scripts/project_version_release.py|Project version/release helper"
  ".agents/skills/project-version-release/references/project-version-policy.md|Project Version Policy"
  ".agents/skills/test-runbook/SKILL.md|执行副作用"
  ".agents/skills/test-runbook/SKILL.md|Request / Response 回写规则"
  ".agents/skills/test-runbook/SKILL.md|提交版证据边界"
  ".agents/skills/test-runbook/SKILL.md|结果回写规则"
)

for item in "${required_skill_patterns[@]}"; do
  path="${item%%|*}"
  pattern="${item#*|}"
  if ! rg -Fq -- "$pattern" "$path"; then
    echo "$path missing required skill pattern: $pattern" >&2
    exit 1
  fi
done

if rg -n "DBBridge|db_bridge_test|/Users/suqing|TEA-" .agents/skills >/dev/null; then
  echo "Default harness skills must not contain DBBridge-specific constants" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  python3 .agents/skills/project-plan-archive/scripts/project_plan_archive.py --help >/dev/null
  python3 .agents/skills/project-version-release/scripts/project_version_release.py --help >/dev/null
fi

if [[ -f "docs/harness/prompt-templates.md" ]]; then
  echo "Obsolete harness file should not exist anymore: docs/harness/prompt-templates.md" >&2
  exit 1
fi

required_make_targets=(
  "harness-check"
  "harness-verify"
  "harness-review-gate"
)

for target in "${required_make_targets[@]}"; do
  if ! rg -q "^${target}:" Makefile; then
    echo "Makefile missing target: $target" >&2
    exit 1
  fi
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
  if ! rg -Fq "$pattern" .gitignore; then
    echo ".gitignore missing required pattern: $pattern" >&2
    exit 1
  fi
done

if rg -Fq "真实环境配置不提交" AGENTS.md; then
  if ! rg -n "\.env|settings\.yaml|example|template|模板|示例" .gitignore README.md AGENTS.md docs/harness/control-plane.md >/dev/null; then
    echo "Repository declares real config must not be committed, but ignore/template guidance is missing" >&2
    exit 1
  fi
fi

if ! rg -Fq "EXAMPLE-implementation.md" README.md AGENTS.md; then
  echo "Base harness output should point readers to EXAMPLE-implementation.md" >&2
  exit 1
fi

if rg -n "^docs/test" .gitignore >/dev/null; then
  echo ".gitignore should not ignore docs/test runbook documents" >&2
  exit 1
fi

if [[ -f ".cursor/rules/harness.mdc" ]]; then
  required_cursor_rule_patterns=(
    "description: 始终使用本仓库的 harness 控制面、计划模板、测试 runbook 和验证 gate"
    "alwaysApply: true"
    "AGENTS.md"
    '目录级 `AGENTS.md`'
    "docs/harness/control-plane.md"
    "docs/harness/issue-workflow.md"
    "docs/harness/linear.md"
    "docs/harness/project-constraints.md"
    "docs/issues/README.md"
    ".agents/PLANS.md"
    ".agents/plans/TEMPLATE.md"
    ".agents/plans/EXAMPLE-implementation.md"
    "docs/test/RUNBOOK_TEMPLATE.md"
    "make harness-verify"
    "check.ps1"
  )

  for pattern in "${required_cursor_rule_patterns[@]}"; do
    if ! rg -Fq "$pattern" ".cursor/rules/harness.mdc"; then
      echo ".cursor/rules/harness.mdc missing required pattern: $pattern" >&2
      exit 1
    fi
  done
fi

required_control_plane_patterns=(
  "collect -> gate -> freeze -> slice -> dispatch -> implement -> verify -> review -> integrate -> verify -> writeback -> pr_prep -> merge -> notify"
  "Issue Tracker 是主协作真相"
  "repo 是主执行真相"
  "goal-orchestration"
  "write_lease"
  "Current State"
  "Thread Status"
  "post-integration verify"
  "waiting_on_child"
  "【完成】"
  "Issue Store Profiles"
  "docs/issues/"
  "provider 仓"
  "consumer 仓"
  "project-constraints.md"
  "项目级机械约束"
  "Maintenance Loop"
  "report-only"
  "rule-promotion"
  "目录级 AGENTS"
  ".agents/skills"
  "运行反馈默认写回 Issue Tracker"
  "结果回写默认写回 Issue Tracker"
  "review_gate"
  "check.ps1"
  "merge"
  "escalation"
  ".agents/PLANS.md"
  ".agents/plans/TEMPLATE.md"
)

for pattern in "${required_control_plane_patterns[@]}"; do
  if ! rg -Fq "$pattern" docs/harness/control-plane.md; then
    echo "docs/harness/control-plane.md missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_issue_workflow_patterns=(
  "Issue Workflow"
  "Issue Tracker 是主协作真相"
  "Issue Store Profiles"
  "Orchestration Contract"
  "Current State Comment Contract"
  "Thread Status Comment Contract"
  "Write Lease Contract"
  "Post-Integration Verify Contract"
  "goal-orchestration"
  "write_lease"
  "【完成】"
  "Requirement Clarification"
  "Master Issue"
  "Execution Issue"
  "Codex Handoff"
  "运行反馈 Comment Contract"
  "结果回写 Contract"
  "recovery_point"
  "next_action"
  "current_issue_state"
  "Master 是否可置 Done"
)

for pattern in "${required_issue_workflow_patterns[@]}"; do
  if ! rg -Fq "$pattern" docs/harness/issue-workflow.md; then
    echo "docs/harness/issue-workflow.md missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_repo_issue_patterns=(
  "Repo Issues"
  "issue-provider=repo"
  "issue_id"
  "status"
  "kind"
  "goal"
  "included"
  "excluded"
  "acceptance_matrix"
  "stop_when"
  "write_scope_limit"
  "verification_commands"
  "recovery_point"
  "next_action"
  "Orchestration"
  "Current State"
  "Thread Status Log"
  "active_write_leases"
  "post_integration_verify_summary"
  "writeback_log"
)

for pattern in "${required_repo_issue_patterns[@]}"; do
  if ! rg -Fq "$pattern" docs/issues/README.md docs/issues/TEMPLATE.md; then
    echo "docs/issues templates missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_project_constraints_patterns=(
  "Project Mechanical Constraints"
  "状态枚举"
  "分类枚举"
  "enforced"
  "partial"
  "documented"
  "planned"
  "not_applicable"
  "architecture"
  "contract"
  "runtime"
  "verification"
  "docs"
  "security"
  "cross-repo"
  "维护循环关联"
  "maintenance_candidate"
  "rule_promotion_candidate"
  "human_decision_required"
  "Maintenance Tag"
  "Rule ID | Category | Rule | Source | Enforcement | Command | Status | Maintenance Tag | Notes"
  "project-check"
  '没有可执行命令或 gate 时，不得假装 `enforced`'
  "repeated review finding"
)

for pattern in "${required_project_constraints_patterns[@]}"; do
  if ! rg -Fq "$pattern" docs/harness/project-constraints.md; then
    echo "docs/harness/project-constraints.md missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_test_runbook_patterns=(
  "Test Runbook Template"
  "当前验证结果"
  "本次执行结果"
  "执行副作用"
  "前置条件"
  "测试变量 / 初始化"
  "主路径"
  "清理结果"
  "敏感信息处理"
  "结果回写"
  "脱敏"
  "runbook"
)

for pattern in "${required_test_runbook_patterns[@]}"; do
  if ! rg -Fq "$pattern" docs/test/RUNBOOK_TEMPLATE.md; then
    echo "docs/test/RUNBOOK_TEMPLATE.md missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_linear_profile_patterns=(
  "Linear Profile"
  "issue-workflow.md"
  "Linear 字段映射"
  "current_issue_state"
  "Current State"
  "Thread Status"
  "write_lease"
  "post-integration verify"
  "【完成】"
  "recovery_point"
  "next_action"
  "Issue Tracker 是主协作真相"
)

for pattern in "${required_linear_profile_patterns[@]}"; do
  if ! rg -Fq "$pattern" docs/harness/linear.md; then
    echo "docs/harness/linear.md missing required pattern: $pattern" >&2
    exit 1
  fi
done

if rg -Fq "docs/harness/prompt-templates.md" .agents/PLANS.md; then
  echo ".agents/PLANS.md should not reference docs/harness/prompt-templates.md anymore" >&2
  exit 1
fi

required_plans_patterns=(
  "文档定位"
  "计划实例位置"
  "何时必须写 plan"
  "计划文件位置与命名"
  "计划文档最小结构"
  "技术实现型任务推荐写法"
  "frontmatter 推荐但不强制"
  "EXAMPLE-implementation.md"
  "内容标准"
  "禁止写法"
  "真实入口与触发"
  "输入装配与边界校验"
  "组件职责与代码落点"
  "关键执行时序"
  "停止 / 错误 / 恢复"
  "实现步骤"
  "验证与收口步骤"
  "入口代码位置"
  "装配结果 / 核心对象"
  "步骤化时序"
  "关键分支 / 降级路径"
  "Reference Snippets"
  "File Map"
  "伪代码 / 主循环"
  "关键分支与实现策略"
  "竞态 / 状态机分析"
  "Mermaid 使用规则"
  "代码示例使用规则"
  "维护规则"
  "Maintenance Loop 计划要求"
  "rule-promotion"
  "Maintenance Findings"
  "Issue Tracker 默认约定"
)

for pattern in "${required_plans_patterns[@]}"; do
  if ! rg -Fq "$pattern" .agents/PLANS.md; then
    echo ".agents/PLANS.md missing required section or keyword: $pattern" >&2
    exit 1
  fi
done

for required in "issue_provider" "issue_project" "current_issue_state" "recovery_point" "next_action" "state_ref" "latest_run_ref" "master_run_ref"; do
  if ! rg -Fq "$required" .agents/plans/TEMPLATE.md; then
    echo ".agents/plans/TEMPLATE.md missing required field: $required" >&2
    exit 1
  fi
done

required_plan_template_patterns=(
  "name: <任务名>"
  "overview:"
  "todos:"
  "isProject: false"
  "## Goal"
  "## Scope Freeze"
  "## Context and Orientation"
  "## 0. 现有架构回顾与核心设计决策"
  "### 真实入口与触发"
  "入口代码位置"
  "### 输入装配与边界校验"
  "装配结果 / 核心对象"
  "### 组件职责与代码落点"
  "关键产物"
  "### 关键执行时序"
  "步骤化时序"
  "### 停止 / 错误 / 恢复"
  "关键分支 / 降级路径"
  "## 1. <改动面> -- <本次变更>"
  "## 数据流可视化"
  "## 关键设计决策摘要"
  "## 与现有代码的关系"
  "## File Map（按需）"
  "## 关键分支与实现策略（按需）"
  "## 伪代码 / 主循环（按需）"
  "## 竞态 / 状态机分析（按需）"
  "## Reference Snippets"
  "## Concrete Steps"
  "### 实现步骤"
  "### 验证与收口步骤"
  "## Progress"
  "## Decision Log"
  "## Surprises & Discoveries"
  "## Validation and Acceptance"
  "## Idempotence and Recovery"
  "## Outcomes & Retrospective"
)

for pattern in "${required_plan_template_patterns[@]}"; do
  if ! rg -Fq "$pattern" .agents/plans/TEMPLATE.md; then
    echo ".agents/plans/TEMPLATE.md missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_example_patterns=(
  "name:"
  "overview:"
  "todos:"
  "isProject:"
  "## Goal"
  "## 0. 现有架构回顾与核心设计决策"
  "## 1. HTTP 入口层 -- 收口请求与幂等键"
  "## 数据流可视化"
  "## 关键设计决策摘要"
  "## 与现有代码的关系"
  "## Reference Snippets"
  "## Review Summary"
)

for pattern in "${required_example_patterns[@]}"; do
  if ! rg -Fq "$pattern" .agents/plans/EXAMPLE-implementation.md; then
    echo ".agents/plans/EXAMPLE-implementation.md missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_state_run_patterns=(
  "State Snapshot Template"
  "Run Summary Template"
  "Issue Tracker"
  "orchestration_mode"
  "root_goal"
  "goal_state"
  "goal_unit_roster"
  "active_write_leases"
  "waiting_on"
  "next_check"
  "post_integration_verify"
  "recovery_point"
)

for pattern in "${required_state_run_patterns[@]}"; do
  if ! rg -Fq "$pattern" .agents/state/TEMPLATE.md .agents/runs/TEMPLATE.md; then
    echo "state/run templates missing required pattern: $pattern" >&2
    exit 1
  fi
done

required_powershell_gate_patterns=(
  "Get-PlanImplementationSkeletonErrors"
  "Resolve-PlanImplementationSection"
  "Reference Snippets"
  "组件职责与代码落点"
  "blocking_findings"
  "result=pass"
  "result=fail"
  "harness check passed"
)

for pattern in "${required_powershell_gate_patterns[@]}"; do
  if ! rg -Fq "$pattern" scripts/harness/common.ps1 scripts/harness/review_gate.ps1 scripts/harness/check.ps1; then
    echo "PowerShell harness gates missing required pattern: $pattern" >&2
    exit 1
  fi
done

optional_mode_files=(
  ".agents/prompts/orchestrator-thread.md"
  ".agents/prompts/issue-standard-workflow.md"
  ".agents/prompts/loop-codex.md"
  ".agents/prompts/loop-automation.md"
  ".agents/prompts/maintenance-loop.md"
  ".agents/guides/code-review.md"
  ".agents/guides/linter.md"
)

optional_bundle_files=(
  ".agents/prompts/README.md"
  ".agents/prompts/orchestrator-thread.md"
  ".agents/prompts/issue-standard-workflow.md"
  ".agents/prompts/loop-codex.md"
  ".agents/prompts/loop-automation.md"
  ".agents/prompts/maintenance-loop.md"
  ".agents/guides/code-review.md"
  ".agents/guides/linter.md"
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
    if [[ ! -f "$path" ]]; then
      echo "Optional agent extension bundle is incomplete: missing $path" >&2
      exit 1
    fi
  done

  detected_mode=""
  for path in "${optional_mode_files[@]}"; do
    if ! rg -qx "Mode: (placeholder|full)" "$path"; then
      echo "Optional harness file missing valid mode marker: $path" >&2
      exit 1
    fi

    current_mode="$(sed -n '1s/^Mode: //p' "$path")"
    if [[ -z "$detected_mode" ]]; then
      detected_mode="$current_mode"
    elif [[ "$detected_mode" != "$current_mode" ]]; then
      echo "Optional agent extension bundle has mixed modes: expected $detected_mode, got $current_mode in $path" >&2
      exit 1
    fi
  done

  for pattern in "orchestrator-thread.md" "issue-standard-workflow.md" "loop-codex.md" "loop-automation.md" "maintenance-loop.md"; do
    if ! rg -Fq "$pattern" ".agents/prompts/README.md"; then
      echo ".agents/prompts/README.md missing prompt reference: $pattern" >&2
      exit 1
    fi
  done

  if ! rg -Fq "docs/harness/project-constraints.md" ".agents/guides/linter.md"; then
    echo ".agents/guides/linter.md should point project-level mechanical constraints back to docs/harness/project-constraints.md" >&2
    exit 1
  fi

  if [[ "$detected_mode" == "full" ]]; then
    required_orchestrator_patterns=(
      "goal-orchestration"
      "write_lease"
      "Current State"
      "Thread Status"
      "post-integration verify"
      "waiting_on_child"
      "【完成】"
      "set_thread_title"
    )

    for pattern in "${required_orchestrator_patterns[@]}"; do
      if ! rg -Fq "$pattern" ".agents/prompts/orchestrator-thread.md"; then
        echo ".agents/prompts/orchestrator-thread.md missing required pattern: $pattern" >&2
        exit 1
      fi
    done

    required_issue_workflow_patterns=(
      "真实入口与触发"
      "输入装配与边界校验"
      "组件职责与代码落点"
      "关键执行时序"
      "停止 / 错误 / 恢复"
      "入口代码位置"
      "装配结果 / 核心对象"
      "步骤化时序"
      "关键分支 / 降级路径"
      "File Map"
      "伪代码 / 主循环"
      "关键分支与实现策略"
      "竞态 / 状态机分析"
      "不要用 harness 控制流图替代业务实现图"
      "不要只画图，不写步骤化时序"
      "不要只写职责，不写代码落点"
      "不要只写 happy path，不写关键分支 / 降级路径"
      "不要把 Concrete Steps 写成纯控制面收口步骤"
      "orchestrator-thread.md"
      "write_lease"
      "post-integration verify"
      "【完成】"
    )

    for pattern in "${required_issue_workflow_patterns[@]}"; do
      if ! rg -Fq "$pattern" ".agents/prompts/issue-standard-workflow.md"; then
        echo ".agents/prompts/issue-standard-workflow.md missing required pattern: $pattern" >&2
        exit 1
      fi
    done

    required_maintenance_patterns=(
      "report-only"
      "issue-create"
      "safe-fix"
      "rule-promotion"
      "Maintenance Findings"
      "Classification"
      "Verification Plan"
      "Writeback Plan"
      "Residual Risks"
      "Next Action"
      "rule_promotion_candidate"
      "human_decision_required"
    )

    for pattern in "${required_maintenance_patterns[@]}"; do
      if ! rg -Fq "$pattern" ".agents/prompts/maintenance-loop.md"; then
        echo ".agents/prompts/maintenance-loop.md missing required pattern: $pattern" >&2
        exit 1
      fi
    done
  fi
fi

tmp_plan_new="$(mktemp -t harness-plan-new)"
tmp_plan_legacy="$(mktemp -t harness-plan-legacy)"
tmp_bad_plan_no_steps="$(mktemp -t harness-plan-bad-steps)"
tmp_bad_plan_no_core="$(mktemp -t harness-plan-bad-core)"
tmp_bad_plan_no_branch="$(mktemp -t harness-plan-bad-branch)"
tmp_bad_plan_no_snippets="$(mktemp -t harness-plan-bad-snippets)"
tmp_bad_plan_no_component_row="$(mktemp -t harness-plan-bad-component-row)"
tmp_bad_plan_harness_flow="$(mktemp -t harness-plan-bad-harness-flow)"
trap 'rm -f "$tmp_plan_new" "$tmp_plan_legacy" "$tmp_bad_plan_no_steps" "$tmp_bad_plan_no_core" "$tmp_bad_plan_no_branch" "$tmp_bad_plan_no_snippets" "$tmp_bad_plan_no_component_row" "$tmp_bad_plan_harness_flow"' EXIT

cat >"$tmp_plan_new" <<'EOF'
---
name: harness smoke new
overview: verify implementation-first plan shape
todos:
  - id: smoke
    content: validate new review gate path
    status: pending
isProject: false
---

# ExecPlan: harness smoke new

## Goal
- 目标：验证新模板风格的 plan 可以通过 review gate。
- 成功标准：review gate 和 Makefile 入口都返回 pass。

## Scope and Non-Goals
- 本次范围：只验证结构与 gate。
- 明确不做：不实现真实业务逻辑。

## Scope Freeze

| 类别 | 本次纳入 |
| --- | --- |
| gate smoke | `review_gate` 正反例 |

| 类别 | 本次不纳入 |
| --- | --- |
| 代码实现 | 不写真实代码 |

| 类别 | 验收口径 |
| --- | --- |
| gate | 新风格 plan 能通过 |

## Context and Orientation

- 当前仓库现状：只需要验证新模板 contract。
- 关键入口文件 / 文档：`scripts/harness/review_gate.sh`
- 可复用组件 / 已有能力：`common.sh`
- 风险、依赖与未决项：无

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发
- `入口命令 / 调用源`：`make harness-review-gate`
- `入口代码位置`：`scripts/harness/review_gate.sh`
- `触发条件 / 上游依赖`：传入合法 plan 路径即可

### 输入装配与边界校验
- `输入来源`：CLI 参数 `--plan`
- `装配位置`：`review_gate.sh`
- `装配结果 / 核心对象`：待校验的 plan 文件路径
- `边界校验`：plan 文件不存在时直接失败

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `scripts/harness/review_gate.sh` | 复用 | `review gate` | 读取 plan 并输出 pass / fail | 不负责实现业务逻辑 |

### 关键执行时序
```mermaid
flowchart TD
    Entry["make harness-review-gate"] --> Gate["review_gate.sh"]
    Gate --> Result["pass/fail"]
```
- `图示说明`：Makefile 入口转到 review gate，读取 plan 后给出结论。
- `步骤化时序`：
  1. Makefile 接收 `PLAN` 参数。
  2. review gate 读取 plan 并检查实现骨架。
  3. blocking findings 为 none 时输出 pass。
- `关键状态推进 / 数据流`：输入路径被解析为一个待校验 plan，最后输出 gate 结果。

### 停止 / 错误 / 恢复
- `正常停止条件`：plan 通过校验并输出 pass。
- `主要错误出口`：plan 缺字段或缺结构时输出 fail。
- `关键分支 / 降级路径`：缺少实现骨架时立即失败，不继续读取 review 结果。
- `恢复 / 重试 / 回滚`：补全 plan 后可安全重跑。

## 1. Gate 合约 -- smoke 校验

### 目标与边界
- 目标：验证新风格 plan 可以过 gate。
- 这一块明确不做什么：不引入新的 shell 接口。

### 接口 / 结构目标形状

```text
make harness-review-gate PLAN=/tmp/example-plan.md
```

### 实现要点
- 继续复用 `blocking_findings`
- 兼容旧 `## Architecture / Data Flow`
- 支持新 `## 0. 现有架构回顾与核心设计决策`

### 验证关注点
- 新风格通过
- 旧风格仍通过

## 数据流可视化

```mermaid
sequenceDiagram
    participant Make as Make
    participant Gate as review_gate
    participant Plan as Plan

    Make->>Gate: PLAN=/tmp/example-plan.md
    Gate->>Plan: 读取内容
    Gate-->>Make: result=pass
```

- `主路径说明`：参数被读取后转成 gate 判断。
- `关键分支说明`：结构缺失则立即失败。

## 关键设计决策摘要

- `决策 1`：保留 `blocking_findings` 作为 review gate 输入。
- `决策 2`：新旧 plan 标题都兼容。

## 与现有代码的关系

- `复用的现有能力`：Makefile 与 review gate 入口
- `需要新增或改造的模块`：无
- `明确不改的现有模块`：其余 harness 文件
- `对外行为 / 接口 / 配置变化`：无

## Reference Snippets

```text
result=pass
blocking_findings=none
plan=/tmp/example-plan.md
```

- `片段说明`：锁定 gate 成功时的最小输出形状。

## Concrete Steps

### 实现步骤
1. 读取 plan。
2. 校验实现骨架。

## Review Summary
- `blocking_findings`: none
EOF

cat >"$tmp_plan_legacy" <<'EOF'
# ExecPlan: harness smoke legacy

## Architecture / Data Flow

### 真实入口与触发
- `入口命令 / 调用源`：`cmd/demo`
- `入口代码位置`：`cmd/demo/root.go`
- `触发条件 / 上游依赖`：CLI 完成解析后进入 smoke runner。

### 输入装配与边界校验
- `输入来源`：CLI flags
- `装配位置`：`cmd/demo/root.go`
- `装配结果 / 核心对象`：`SmokeRunnerConfig`
- `边界校验`：缺少 pipeline 时直接失败。

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `internal/demo/runner.go` | 新增 | `SmokeRunner` | 串接 smoke runner 并返回结果 | 不负责网络重试 |

### 关键执行时序
```mermaid
flowchart TD
    Entry["CLI"] --> Runner["SmokeRunner"]
```
- `图示说明`：CLI 触发 smoke runner。
- `步骤化时序`：
  1. root command 解析参数并构造 config。
  2. runner 消费 config 并返回结果摘要。
- `关键状态推进 / 数据流`：输入参数归一化后进入 runner。

### 停止 / 错误 / 恢复
- `正常停止条件`：runner 返回结果。
- `主要错误出口`：参数缺失时直接返回错误。
- `关键分支 / 降级路径`：无 pipeline 时降级为失败返回，不启动 runner。
- `恢复 / 重试 / 回滚`：修正参数后可安全重跑。

## Reference Snippets

```text
SmokeRunnerConfig{Pipeline: "smoke"}
```

- `片段说明`：锁定 smoke runner 的最小输入对象。

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
EOF

cat >"$tmp_bad_plan_no_steps" <<'EOF'
# ExecPlan: harness smoke bad no steps

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发
- `入口命令 / 调用源`：`cmd/demo`
- `入口代码位置`：`cmd/demo/root.go`
- `触发条件 / 上游依赖`：CLI 完成解析后进入 smoke runner。

### 输入装配与边界校验
- `输入来源`：CLI flags
- `装配位置`：`cmd/demo/root.go`
- `装配结果 / 核心对象`：`SmokeRunnerConfig`
- `边界校验`：缺少 pipeline 时直接失败。

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `internal/demo/runner.go` | 新增 | `SmokeRunner` | 串接 smoke runner 并返回结果 | 不负责网络重试 |

```mermaid
flowchart TD
    Entry["CLI"] --> Runner["SmokeRunner"]
```

### 停止 / 错误 / 恢复
- `正常停止条件`：runner 返回结果。
- `主要错误出口`：参数缺失时直接返回错误。
- `关键分支 / 降级路径`：无 pipeline 时降级为失败返回，不启动 runner。
- `恢复 / 重试 / 回滚`：修正参数后可安全重跑。

## Reference Snippets

```text
SmokeRunnerConfig{Pipeline: "smoke"}
```

- `片段说明`：锁定 smoke runner 的最小输入对象。

## Concrete Steps

### 实现步骤
1. verify

## Review Summary
- `blocking_findings`: none
EOF

cat >"$tmp_bad_plan_no_core" <<'EOF'
# ExecPlan: harness smoke bad no core object

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发
- `入口命令 / 调用源`：`cmd/demo`
- `入口代码位置`：`cmd/demo/root.go`
- `触发条件 / 上游依赖`：CLI 完成解析后进入 smoke runner。

### 输入装配与边界校验
- `输入来源`：CLI flags
- `装配位置`：`cmd/demo/root.go`
- `装配结果 / 核心对象`：
- `边界校验`：缺少 pipeline 时直接失败。

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `internal/demo/runner.go` | 新增 | `SmokeRunner` | 串接 smoke runner 并返回结果 | 不负责网络重试 |

### 关键执行时序
```mermaid
flowchart TD
    Entry["CLI"] --> Runner["SmokeRunner"]
```
- `图示说明`：CLI 触发 smoke runner。
- `步骤化时序`：
  1. root command 解析参数并构造 config。
  2. runner 消费 config 并返回结果摘要。
- `关键状态推进 / 数据流`：输入参数归一化后进入 runner。

### 停止 / 错误 / 恢复
- `正常停止条件`：runner 返回结果。
- `主要错误出口`：参数缺失时直接返回错误。
- `关键分支 / 降级路径`：无 pipeline 时降级为失败返回，不启动 runner。
- `恢复 / 重试 / 回滚`：修正参数后可安全重跑。

## Reference Snippets

```text
SmokeRunnerConfig{Pipeline: "smoke"}
```

- `片段说明`：锁定 smoke runner 的最小输入对象。

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
EOF

cat >"$tmp_bad_plan_no_branch" <<'EOF'
# ExecPlan: harness smoke bad no branch

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发
- `入口命令 / 调用源`：`cmd/demo`
- `入口代码位置`：`cmd/demo/root.go`
- `触发条件 / 上游依赖`：CLI 完成解析后进入 smoke runner。

### 输入装配与边界校验
- `输入来源`：CLI flags
- `装配位置`：`cmd/demo/root.go`
- `装配结果 / 核心对象`：`SmokeRunnerConfig`
- `边界校验`：缺少 pipeline 时直接失败。

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `internal/demo/runner.go` | 新增 | `SmokeRunner` | 串接 smoke runner 并返回结果 | 不负责网络重试 |

### 关键执行时序
```mermaid
flowchart TD
    Entry["CLI"] --> Runner["SmokeRunner"]
```
- `图示说明`：CLI 触发 smoke runner。
- `步骤化时序`：
  1. root command 解析参数并构造 config。
  2. runner 消费 config 并返回结果摘要。
- `关键状态推进 / 数据流`：输入参数归一化后进入 runner。

### 停止 / 错误 / 恢复
- `正常停止条件`：runner 返回结果。
- `主要错误出口`：参数缺失时直接返回错误。
- `关键分支 / 降级路径`：
- `恢复 / 重试 / 回滚`：修正参数后可安全重跑。

## Reference Snippets

```text
SmokeRunnerConfig{Pipeline: "smoke"}
```

- `片段说明`：锁定 smoke runner 的最小输入对象。

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
EOF

cat >"$tmp_bad_plan_no_snippets" <<'EOF'
# ExecPlan: harness smoke bad no snippets

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发
- `入口命令 / 调用源`：`cmd/demo`
- `入口代码位置`：`cmd/demo/root.go`
- `触发条件 / 上游依赖`：CLI 完成解析后进入 smoke runner。

### 输入装配与边界校验
- `输入来源`：CLI flags
- `装配位置`：`cmd/demo/root.go`
- `装配结果 / 核心对象`：`SmokeRunnerConfig`
- `边界校验`：缺少 pipeline 时直接失败。

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `internal/demo/runner.go` | 新增 | `SmokeRunner` | 串接 smoke runner 并返回结果 | 不负责网络重试 |

### 关键执行时序
```mermaid
flowchart TD
    Entry["CLI"] --> Runner["SmokeRunner"]
```
- `图示说明`：CLI 触发 smoke runner。
- `步骤化时序`：
  1. root command 解析参数并构造 config。
  2. runner 消费 config 并返回结果摘要。
- `关键状态推进 / 数据流`：输入参数归一化后进入 runner。

### 停止 / 错误 / 恢复
- `正常停止条件`：runner 返回结果。
- `主要错误出口`：参数缺失时直接返回错误。
- `关键分支 / 降级路径`：无 pipeline 时降级为失败返回，不启动 runner。
- `恢复 / 重试 / 回滚`：修正参数后可安全重跑。

## Reference Snippets

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
EOF

cat >"$tmp_bad_plan_no_component_row" <<'EOF'
# ExecPlan: harness smoke bad no component row

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发
- `入口命令 / 调用源`：`cmd/demo`
- `入口代码位置`：`cmd/demo/root.go`
- `触发条件 / 上游依赖`：CLI 完成解析后进入 smoke runner。

### 输入装配与边界校验
- `输入来源`：CLI flags
- `装配位置`：`cmd/demo/root.go`
- `装配结果 / 核心对象`：`SmokeRunnerConfig`
- `边界校验`：缺少 pipeline 时直接失败。

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |

### 关键执行时序
```mermaid
flowchart TD
    Entry["CLI"] --> Runner["SmokeRunner"]
```
- `图示说明`：CLI 触发 smoke runner。
- `步骤化时序`：
  1. root command 解析参数并构造 config。
  2. runner 消费 config 并返回结果摘要。
- `关键状态推进 / 数据流`：输入参数归一化后进入 runner。

### 停止 / 错误 / 恢复
- `正常停止条件`：runner 返回结果。
- `主要错误出口`：参数缺失时直接返回错误。
- `关键分支 / 降级路径`：无 pipeline 时降级为失败返回，不启动 runner。
- `恢复 / 重试 / 回滚`：修正参数后可安全重跑。

## Reference Snippets

```text
SmokeRunnerConfig{Pipeline: "smoke"}
```

- `片段说明`：锁定 smoke runner 的最小输入对象。

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
EOF

cat >"$tmp_bad_plan_harness_flow" <<'EOF'
# ExecPlan: harness smoke bad harness flow

## Architecture / Data Flow

```mermaid
flowchart TD
    Collect["collect"] --> Verify["verify"]
    Verify --> Review["review"]
    Review --> Notify["notify"]
```

## Reference Snippets

```text
result=pass
```

## Concrete Steps

### 实现步骤
1. 运行控制面。

## Review Summary
- `blocking_findings`: none
EOF

if ! bash scripts/harness/review_gate.sh --plan "$tmp_plan_new" >/dev/null; then
  echo "review_gate should pass for a new implementation-first plan" >&2
  exit 1
fi

if ! make harness-review-gate PLAN="$tmp_plan_new" >/dev/null; then
  echo "Makefile harness-review-gate smoke test failed for the new plan shape" >&2
  exit 1
fi

if ! bash scripts/harness/review_gate.sh --plan "$tmp_plan_legacy" >/dev/null; then
  echo "review_gate should still pass for a legacy plan without frontmatter" >&2
  exit 1
fi

if bash scripts/harness/review_gate.sh --plan "$tmp_bad_plan_no_steps" >/dev/null 2>&1; then
  echo "review_gate should fail for a plan without step-by-step flow" >&2
  exit 1
fi

if bash scripts/harness/review_gate.sh --plan "$tmp_bad_plan_no_core" >/dev/null 2>&1; then
  echo "review_gate should fail for a plan without core object/result" >&2
  exit 1
fi

if bash scripts/harness/review_gate.sh --plan "$tmp_bad_plan_no_branch" >/dev/null 2>&1; then
  echo "review_gate should fail for a plan without key branch/degrade path" >&2
  exit 1
fi

if bash scripts/harness/review_gate.sh --plan "$tmp_bad_plan_no_snippets" >/dev/null 2>&1; then
  echo "review_gate should fail for a plan without reference snippets" >&2
  exit 1
fi

if bash scripts/harness/review_gate.sh --plan "$tmp_bad_plan_no_component_row" >/dev/null 2>&1; then
  echo "review_gate should fail for a plan without a real component responsibility entry" >&2
  exit 1
fi

if bash scripts/harness/review_gate.sh --plan "$tmp_bad_plan_harness_flow" >/dev/null 2>&1; then
  echo "review_gate should fail for a plan that only contains harness flow" >&2
  exit 1
fi

echo "harness check passed"
