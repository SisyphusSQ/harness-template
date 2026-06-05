[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $scriptDir "common.ps1")

Set-Location -LiteralPath $Script:RepoRoot

function Fail {
    param([Parameter(Mandatory=$true)][string]$Message)

    [Console]::Error.WriteLine($Message)
    exit 1
}

function Get-FileText {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail "Missing required harness file: $Path"
    }

    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8)
}

function Assert-FileContains {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Pattern,
        [string]$Message
    )

    $text = Get-FileText -Path $Path
    if ($text.IndexOf($Pattern, [System.StringComparison]::Ordinal) -lt 0) {
        if ([string]::IsNullOrEmpty($Message)) {
            $Message = "$Path missing required pattern: $Pattern"
        }
        Fail $Message
    }
}

function Assert-AnyFileContains {
    param(
        [Parameter(Mandatory=$true)][string[]]$Paths,
        [Parameter(Mandatory=$true)][string]$Pattern,
        [Parameter(Mandatory=$true)][string]$Message
    )

    foreach ($path in $Paths) {
        if ((Get-FileText -Path $path).IndexOf($Pattern, [System.StringComparison]::Ordinal) -ge 0) {
            return
        }
    }

    Fail $Message
}

function Assert-FileMatches {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Regex,
        [Parameter(Mandatory=$true)][string]$Message
    )

    $text = Get-FileText -Path $Path
    if ($text -notmatch $Regex) {
        Fail $Message
    }
}

function Test-ReviewGate {
    param(
        [Parameter(Mandatory=$true)][string]$Plan,
        [Parameter(Mandatory=$true)][bool]$ShouldPass,
        [Parameter(Mandatory=$true)][string]$FailureMessage
    )

    $reviewGate = Join-Path $Script:RepoRoot "scripts\harness\review_gate.ps1"
    $psCommand = if ($PSVersionTable.PSEdition -eq "Core") {
        Get-Command pwsh -ErrorAction SilentlyContinue
    } else {
        Get-Command powershell -ErrorAction SilentlyContinue
    }

    if ($null -eq $psCommand) {
        $process = Get-Process -Id $PID
        if ($process -and $process.Path) {
            $exe = $process.Path
        } else {
            Fail "Unable to locate current PowerShell executable for review_gate.ps1 smoke test"
        }
    } else {
        $exe = $psCommand.Source
    }

    $invokeArgs = @("-NoProfile")
    if ((Split-Path -Leaf $exe) -ieq "powershell.exe") {
        $invokeArgs += @("-ExecutionPolicy", "Bypass")
    }
    $invokeArgs += @("-File", $reviewGate, "-Plan", $Plan)

    & $exe @invokeArgs *> $null
    $passed = ($LASTEXITCODE -eq 0)

    if ($ShouldPass -and -not $passed) {
        Fail $FailureMessage
    }
    if (-not $ShouldPass -and $passed) {
        Fail $FailureMessage
    }
}

$requiredFiles = @(
    ".gitignore",
    "AGENTS.md",
    "README.md",
    "docs/harness/control-plane.md",
    "docs/harness/issue-workflow.md",
    "docs/harness/linear.md",
    "docs/harness/project-constraints.md",
    "docs/issues/README.md",
    "docs/issues/TEMPLATE.md",
    "docs/test/RUNBOOK_TEMPLATE.md",
    ".agents/PLANS.md",
    ".agents/plans/TEMPLATE.md",
    ".agents/plans/EXAMPLE-implementation.md",
    ".agents/skills/project-plan-archive/SKILL.md",
    ".agents/skills/project-plan-archive/agents/openai.yaml",
    ".agents/skills/project-plan-archive/scripts/project_plan_archive.py",
    ".agents/skills/project-plan-archive/tests/test_project_plan_archive.py",
    ".agents/skills/project-version-release/SKILL.md",
    ".agents/skills/project-version-release/agents/openai.yaml",
    ".agents/skills/project-version-release/references/project-version-policy.md",
    ".agents/skills/project-version-release/scripts/project_version_release.py",
    ".agents/skills/test-runbook/SKILL.md",
    ".agents/skills/test-runbook/agents/openai.yaml",
    ".agents/state/TEMPLATE.md",
    ".agents/runs/TEMPLATE.md",
    "scripts/harness/check.sh",
    "scripts/harness/common.sh",
    "scripts/harness/review_gate.sh",
    "scripts/harness/check.ps1",
    "scripts/harness/common.ps1",
    "scripts/harness/review_gate.ps1"
)

foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "Missing required harness file: $path"
    }
}

foreach ($item in @(
    @(".agents/skills/project-plan-archive/SKILL.md", "name: project-plan-archive"),
    @(".agents/skills/project-version-release/SKILL.md", "name: project-version-release"),
    @(".agents/skills/test-runbook/SKILL.md", "name: test-runbook")
)) {
    Assert-FileContains -Path $item[0] -Pattern "---" -Message "Skill frontmatter is incomplete: $($item[0])"
    Assert-FileContains -Path $item[0] -Pattern $item[1] -Message "Skill frontmatter is incomplete: $($item[0])"
    Assert-FileContains -Path $item[0] -Pattern "description:" -Message "Skill frontmatter is incomplete: $($item[0])"
}

foreach ($item in @(
    @(".agents/skills/project-plan-archive/SKILL.md", "先查 Issue Tracker，再归档"),
    @(".agents/skills/project-plan-archive/SKILL.md", "--done-issue"),
    @(".agents/skills/project-plan-archive/SKILL.md", "no_issue_default_archive"),
    @(".agents/skills/project-plan-archive/scripts/project_plan_archive.py", "Project plan archive helper"),
    @(".agents/skills/project-plan-archive/scripts/project_plan_archive.py", "--write"),
    @(".agents/skills/project-version-release/SKILL.md", "issue 是执行粒度，release 是发布粒度"),
    @(".agents/skills/project-version-release/SKILL.md", "CHANGELOG.md -> Unreleased"),
    @(".agents/skills/project-version-release/scripts/project_version_release.py", "Project version/release helper"),
    @(".agents/skills/project-version-release/references/project-version-policy.md", "Project Version Policy"),
    @(".agents/skills/test-runbook/SKILL.md", "执行副作用"),
    @(".agents/skills/test-runbook/SKILL.md", "Request / Response 回写规则"),
    @(".agents/skills/test-runbook/SKILL.md", "提交版证据边界"),
    @(".agents/skills/test-runbook/SKILL.md", "结果回写规则")
)) {
    Assert-FileContains -Path $item[0] -Pattern $item[1] -Message "$($item[0]) missing required skill pattern: $($item[1])"
}

$skillText = Get-ChildItem -Path ".agents/skills" -Recurse -File | ForEach-Object {
    Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
}
if (($skillText -join "`n") -match 'DBBridge|db_bridge_test|/Users/suqing|TEA-') {
    Fail "Default harness skills must not contain DBBridge-specific constants"
}

$python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -ne $python) {
    & $python.Source ".agents/skills/project-plan-archive/scripts/project_plan_archive.py" "--help" *> $null
    if ($LASTEXITCODE -ne 0) {
        Fail "project_plan_archive.py --help failed"
    }
    & $python.Source ".agents/skills/project-version-release/scripts/project_version_release.py" "--help" *> $null
    if ($LASTEXITCODE -ne 0) {
        Fail "project_version_release.py --help failed"
    }
}

if (Test-Path -LiteralPath "docs/harness/prompt-templates.md" -PathType Leaf) {
    Fail "Obsolete harness file should not exist anymore: docs/harness/prompt-templates.md"
}

foreach ($target in @("harness-check", "harness-verify", "harness-review-gate")) {
    Assert-FileMatches -Path "Makefile" -Regex "(?m)^$([regex]::Escape($target)):" -Message "Makefile missing target: $target"
}

foreach ($pattern in @(
    ".DS_Store",
    ".idea/",
    ".vscode/",
    "*.log",
    "logs/",
    "tmp/",
    "temp/",
    ".agents/state/*",
    "!.agents/state/TEMPLATE.md",
    ".agents/runs/*",
    "!.agents/runs/TEMPLATE.md",
    ".cursor/*",
    "!.cursor/rules/",
    "!.cursor/rules/*.mdc"
)) {
    Assert-FileContains -Path ".gitignore" -Pattern $pattern -Message ".gitignore missing required pattern: $pattern"
}

if ((Get-FileText -Path "AGENTS.md").IndexOf("真实环境配置不提交", [System.StringComparison]::Ordinal) -ge 0) {
    $combined = @(
        Get-FileText -Path ".gitignore",
        Get-FileText -Path "README.md",
        Get-FileText -Path "AGENTS.md",
        Get-FileText -Path "docs/harness/control-plane.md"
    ) -join "`n"
    if ($combined -notmatch '\.env|settings\.yaml|example|template|模板|示例') {
        Fail "Repository declares real config must not be committed, but ignore/template guidance is missing"
    }
}

foreach ($path in @("README.md", "AGENTS.md")) {
    Assert-FileContains -Path $path -Pattern "EXAMPLE-implementation.md" -Message "Base harness output should point readers to EXAMPLE-implementation.md"
}

if ((Get-FileText -Path ".gitignore") -match '(?m)^docs/test') {
    Fail ".gitignore should not ignore docs/test runbook documents"
}

if (Test-Path -LiteralPath ".cursor/rules/harness.mdc" -PathType Leaf) {
    foreach ($pattern in @(
        "description: 始终使用本仓库的 harness 控制面、计划模板、测试 runbook 和验证 gate",
        "alwaysApply: true",
        "AGENTS.md",
        "目录级 `AGENTS.md`",
        "docs/harness/control-plane.md",
        "docs/harness/issue-workflow.md",
        "docs/harness/linear.md",
        "docs/harness/project-constraints.md",
        "docs/issues/README.md",
        ".agents/PLANS.md",
        ".agents/plans/TEMPLATE.md",
        ".agents/plans/EXAMPLE-implementation.md",
        "docs/test/RUNBOOK_TEMPLATE.md",
        "make harness-verify",
        "check.ps1"
    )) {
        Assert-FileContains -Path ".cursor/rules/harness.mdc" -Pattern $pattern -Message ".cursor/rules/harness.mdc missing required pattern: $pattern"
    }
}

foreach ($pattern in @(
    "collect -> gate -> freeze -> slice -> dispatch -> implement -> verify -> review -> integrate -> verify -> writeback -> pr_prep -> merge -> notify",
    "Issue Tracker 是主协作真相",
    "repo 是主执行真相",
    "goal-orchestration",
    "write_lease",
    "Current State",
    "Thread Status",
    "post-integration verify",
    "waiting_on_child",
    "【完成】",
    "Issue Store Profiles",
    "docs/issues/",
    "provider 仓",
    "consumer 仓",
    "project-constraints.md",
    "项目级机械约束",
    "Maintenance Loop",
    "report-only",
    "rule-promotion",
    "目录级 AGENTS",
    ".agents/skills",
    "运行反馈默认写回 Issue Tracker",
    "结果回写默认写回 Issue Tracker",
    "review_gate",
    "check.ps1",
    "merge",
    "escalation",
    ".agents/PLANS.md",
    ".agents/plans/TEMPLATE.md"
)) {
    Assert-FileContains -Path "docs/harness/control-plane.md" -Pattern $pattern -Message "docs/harness/control-plane.md missing required pattern: $pattern"
}

foreach ($pattern in @(
    "Issue Workflow",
    "Issue Tracker 是主协作真相",
    "Issue Store Profiles",
    "Orchestration Contract",
    "Current State Comment Contract",
    "Thread Status Comment Contract",
    "Write Lease Contract",
    "Post-Integration Verify Contract",
    "goal-orchestration",
    "write_lease",
    "【完成】",
    "Requirement Clarification",
    "Master Issue",
    "Execution Issue",
    "Codex Handoff",
    "运行反馈 Comment Contract",
    "结果回写 Contract",
    "recovery_point",
    "next_action",
    "current_issue_state",
    "Master 是否可置 Done"
)) {
    Assert-FileContains -Path "docs/harness/issue-workflow.md" -Pattern $pattern -Message "docs/harness/issue-workflow.md missing required pattern: $pattern"
}

foreach ($pattern in @(
    "Repo Issues",
    "issue-provider=repo",
    "issue_id",
    "status",
    "kind",
    "goal",
    "included",
    "excluded",
    "acceptance_matrix",
    "stop_when",
    "write_scope_limit",
    "verification_commands",
    "recovery_point",
    "next_action",
    "Orchestration",
    "Current State",
    "Thread Status Log",
    "active_write_leases",
    "post_integration_verify_summary",
    "writeback_log"
)) {
    Assert-AnyFileContains -Paths @("docs/issues/README.md", "docs/issues/TEMPLATE.md") -Pattern $pattern -Message "docs/issues templates missing required pattern: $pattern"
}

foreach ($pattern in @(
    "Project Mechanical Constraints",
    "状态枚举",
    "分类枚举",
    "enforced",
    "partial",
    "documented",
    "planned",
    "not_applicable",
    "architecture",
    "contract",
    "runtime",
    "verification",
    "docs",
    "security",
    "cross-repo",
    "维护循环关联",
    "maintenance_candidate",
    "rule_promotion_candidate",
    "human_decision_required",
    "Maintenance Tag",
    "Rule ID | Category | Rule | Source | Enforcement | Command | Status | Maintenance Tag | Notes",
    "project-check",
    "没有可执行命令或 gate 时，不得假装 `enforced`",
    "repeated review finding"
)) {
    Assert-FileContains -Path "docs/harness/project-constraints.md" -Pattern $pattern -Message "docs/harness/project-constraints.md missing required pattern: $pattern"
}

foreach ($pattern in @(
    "Test Runbook Template",
    "当前验证结果",
    "本次执行结果",
    "执行副作用",
    "前置条件",
    "测试变量 / 初始化",
    "主路径",
    "清理结果",
    "敏感信息处理",
    "结果回写",
    "脱敏",
    "runbook"
)) {
    Assert-FileContains -Path "docs/test/RUNBOOK_TEMPLATE.md" -Pattern $pattern -Message "docs/test/RUNBOOK_TEMPLATE.md missing required pattern: $pattern"
}

foreach ($pattern in @(
    "Linear Profile",
    "issue-workflow.md",
    "Linear 字段映射",
    "current_issue_state",
    "Current State",
    "Thread Status",
    "write_lease",
    "post-integration verify",
    "【完成】",
    "recovery_point",
    "next_action",
    "Issue Tracker 是主协作真相"
)) {
    Assert-FileContains -Path "docs/harness/linear.md" -Pattern $pattern -Message "docs/harness/linear.md missing required pattern: $pattern"
}

if ((Get-FileText -Path ".agents/PLANS.md").IndexOf("docs/harness/prompt-templates.md", [System.StringComparison]::Ordinal) -ge 0) {
    Fail ".agents/PLANS.md should not reference docs/harness/prompt-templates.md anymore"
}

foreach ($pattern in @(
    "文档定位",
    "计划实例位置",
    "何时必须写 plan",
    "计划文件位置与命名",
    "计划文档最小结构",
    "技术实现型任务推荐写法",
    "frontmatter 推荐但不强制",
    "EXAMPLE-implementation.md",
    "内容标准",
    "禁止写法",
    "真实入口与触发",
    "输入装配与边界校验",
    "组件职责与代码落点",
    "关键执行时序",
    "停止 / 错误 / 恢复",
    "实现步骤",
    "验证与收口步骤",
    "入口代码位置",
    "装配结果 / 核心对象",
    "步骤化时序",
    "关键分支 / 降级路径",
    "Reference Snippets",
    "File Map",
    "伪代码 / 主循环",
    "关键分支与实现策略",
    "竞态 / 状态机分析",
    "Mermaid 使用规则",
    "代码示例使用规则",
    "维护规则",
    "Maintenance Loop 计划要求",
    "rule-promotion",
    "Maintenance Findings",
    "Issue Tracker 默认约定"
)) {
    Assert-FileContains -Path ".agents/PLANS.md" -Pattern $pattern -Message ".agents/PLANS.md missing required section or keyword: $pattern"
}

foreach ($required in @("issue_provider", "issue_project", "current_issue_state", "recovery_point", "next_action", "state_ref", "latest_run_ref", "master_run_ref")) {
    Assert-FileContains -Path ".agents/plans/TEMPLATE.md" -Pattern $required -Message ".agents/plans/TEMPLATE.md missing required field: $required"
}

foreach ($pattern in @(
    "name: <任务名>",
    "overview:",
    "todos:",
    "isProject: false",
    "## Goal",
    "## Scope Freeze",
    "## Context and Orientation",
    "## 0. 现有架构回顾与核心设计决策",
    "### 真实入口与触发",
    "入口代码位置",
    "### 输入装配与边界校验",
    "装配结果 / 核心对象",
    "### 组件职责与代码落点",
    "关键产物",
    "### 关键执行时序",
    "步骤化时序",
    "### 停止 / 错误 / 恢复",
    "关键分支 / 降级路径",
    "## 1. <改动面> -- <本次变更>",
    "## 数据流可视化",
    "## 关键设计决策摘要",
    "## 与现有代码的关系",
    "## File Map（按需）",
    "## 关键分支与实现策略（按需）",
    "## 伪代码 / 主循环（按需）",
    "## 竞态 / 状态机分析（按需）",
    "## Reference Snippets",
    "## Concrete Steps",
    "### 实现步骤",
    "### 验证与收口步骤",
    "## Progress",
    "## Decision Log",
    "## Surprises & Discoveries",
    "## Validation and Acceptance",
    "## Idempotence and Recovery",
    "## Outcomes & Retrospective"
)) {
    Assert-FileContains -Path ".agents/plans/TEMPLATE.md" -Pattern $pattern -Message ".agents/plans/TEMPLATE.md missing required pattern: $pattern"
}

foreach ($pattern in @(
    "name:",
    "overview:",
    "todos:",
    "isProject:",
    "## Goal",
    "## 0. 现有架构回顾与核心设计决策",
    "## 1. HTTP 入口层 -- 收口请求与幂等键",
    "## 数据流可视化",
    "## 关键设计决策摘要",
    "## 与现有代码的关系",
    "## Reference Snippets",
    "## Review Summary"
)) {
    Assert-FileContains -Path ".agents/plans/EXAMPLE-implementation.md" -Pattern $pattern -Message ".agents/plans/EXAMPLE-implementation.md missing required pattern: $pattern"
}

foreach ($pattern in @(
    "State Snapshot Template",
    "Run Summary Template",
    "Issue Tracker",
    "orchestration_mode",
    "root_goal",
    "goal_state",
    "goal_unit_roster",
    "active_write_leases",
    "waiting_on",
    "next_check",
    "post_integration_verify",
    "recovery_point"
)) {
    Assert-AnyFileContains -Paths @(".agents/state/TEMPLATE.md", ".agents/runs/TEMPLATE.md") -Pattern $pattern -Message "state/run templates missing required pattern: $pattern"
}

foreach ($pattern in @(
    "Get-PlanImplementationSkeletonErrors",
    "Resolve-PlanImplementationSection",
    "Reference Snippets",
    "组件职责与代码落点"
)) {
    Assert-FileContains -Path "scripts/harness/common.ps1" -Pattern $pattern -Message "scripts/harness/common.ps1 missing required pattern: $pattern"
}

foreach ($pattern in @(
    "Get-PlanImplementationSkeletonErrors",
    "blocking_findings",
    "result=pass",
    "result=fail"
)) {
    Assert-FileContains -Path "scripts/harness/review_gate.ps1" -Pattern $pattern -Message "scripts/harness/review_gate.ps1 missing required pattern: $pattern"
}

Assert-FileContains -Path "scripts/harness/check.ps1" -Pattern "harness check passed" -Message "scripts/harness/check.ps1 missing smoke completion marker"

$optionalModeFiles = @(
    ".agents/prompts/orchestrator-thread.md",
    ".agents/prompts/issue-standard-workflow.md",
    ".agents/prompts/loop-codex.md",
    ".agents/prompts/loop-automation.md",
    ".agents/prompts/maintenance-loop.md",
    ".agents/guides/code-review.md",
    ".agents/guides/linter.md"
)

$optionalBundleFiles = @(
    ".agents/prompts/README.md",
    ".agents/prompts/orchestrator-thread.md",
    ".agents/prompts/issue-standard-workflow.md",
    ".agents/prompts/loop-codex.md",
    ".agents/prompts/loop-automation.md",
    ".agents/prompts/maintenance-loop.md",
    ".agents/guides/code-review.md",
    ".agents/guides/linter.md"
)

$hasOptionalBundle = $false
foreach ($path in $optionalBundleFiles) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $hasOptionalBundle = $true
        break
    }
}

if ($hasOptionalBundle) {
    foreach ($path in $optionalBundleFiles) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Fail "Optional agent extension bundle is incomplete: missing $path"
        }
    }

    $detectedMode = ""
    foreach ($path in $optionalModeFiles) {
        $firstLine = (Get-Content -LiteralPath $path -TotalCount 1 -Encoding UTF8)
        if ($firstLine -notmatch '^Mode: (placeholder|full)$') {
            Fail "Optional harness file missing valid mode marker: $path"
        }
        $currentMode = $Matches[1]
        if ([string]::IsNullOrEmpty($detectedMode)) {
            $detectedMode = $currentMode
        } elseif ($detectedMode -ne $currentMode) {
            Fail "Optional agent extension bundle has mixed modes: expected $detectedMode, got $currentMode in $path"
        }
    }

    foreach ($pattern in @("orchestrator-thread.md", "issue-standard-workflow.md", "loop-codex.md", "loop-automation.md", "maintenance-loop.md")) {
        Assert-FileContains -Path ".agents/prompts/README.md" -Pattern $pattern -Message ".agents/prompts/README.md missing prompt reference: $pattern"
    }

    Assert-FileContains -Path ".agents/guides/linter.md" -Pattern "docs/harness/project-constraints.md" -Message ".agents/guides/linter.md should point project-level mechanical constraints back to docs/harness/project-constraints.md"

    if ($detectedMode -eq "full") {
        foreach ($pattern in @(
            "goal-orchestration",
            "write_lease",
            "Current State",
            "Thread Status",
            "post-integration verify",
            "waiting_on_child",
            "【完成】",
            "set_thread_title"
        )) {
            Assert-FileContains -Path ".agents/prompts/orchestrator-thread.md" -Pattern $pattern -Message ".agents/prompts/orchestrator-thread.md missing required pattern: $pattern"
        }

        foreach ($pattern in @(
            "真实入口与触发",
            "输入装配与边界校验",
            "组件职责与代码落点",
            "关键执行时序",
            "停止 / 错误 / 恢复",
            "入口代码位置",
            "装配结果 / 核心对象",
            "步骤化时序",
            "关键分支 / 降级路径",
            "File Map",
            "伪代码 / 主循环",
            "关键分支与实现策略",
            "竞态 / 状态机分析",
            "不要用 harness 控制流替代业务实现图",
            "不要只画图，不写步骤化时序",
            "不要只写职责，不写代码落点",
            "不要只写 happy path，不写关键分支 / 降级路径",
            "不要把 Concrete Steps 写成纯控制面收口步骤",
            "orchestrator-thread.md",
            "write_lease",
            "post-integration verify",
            "【完成】"
        )) {
            Assert-FileContains -Path ".agents/prompts/issue-standard-workflow.md" -Pattern $pattern -Message ".agents/prompts/issue-standard-workflow.md missing required pattern: $pattern"
        }

        foreach ($pattern in @(
            "report-only",
            "issue-create",
            "safe-fix",
            "rule-promotion",
            "Maintenance Findings",
            "Classification",
            "Verification Plan",
            "Writeback Plan",
            "Residual Risks",
            "Next Action",
            "rule_promotion_candidate",
            "human_decision_required"
        )) {
            Assert-FileContains -Path ".agents/prompts/maintenance-loop.md" -Pattern $pattern -Message ".agents/prompts/maintenance-loop.md missing required pattern: $pattern"
        }
    }
}

$tempPlans = New-Object System.Collections.Generic.List[string]

try {
    function New-PlanFixture {
        param([Parameter(Mandatory=$true)][string]$Content)

        $path = [System.IO.Path]::GetTempFileName()
        Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
        [void]$tempPlans.Add($path)
        return $path
    }

    $tmpPlanNew = New-PlanFixture @'
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
- 成功标准：review gate 返回 pass。

## Scope Freeze

| 类别 | 本次纳入 |
| --- | --- |
| gate smoke | `review_gate` 正反例 |

## Context and Orientation

- 当前仓库现状：只需要验证新模板 contract。
- 关键入口文件 / 文档：`scripts/harness/review_gate.ps1`
- 可复用组件 / 已有能力：`common.ps1`

## 0. 现有架构回顾与核心设计决策

### 真实入口与触发
- `入口命令 / 调用源`：`powershell -File scripts/harness/review_gate.ps1`
- `入口代码位置`：`scripts/harness/review_gate.ps1`
- `触发条件 / 上游依赖`：传入合法 plan 路径即可

### 输入装配与边界校验
- `输入来源`：CLI 参数 `-Plan`
- `装配位置`：`review_gate.ps1`
- `装配结果 / 核心对象`：待校验的 plan 文件路径
- `边界校验`：plan 文件不存在时直接失败

### 组件职责与代码落点
| 模块/类型 | 新增/复用 | 关键产物 | 职责 | 不负责 |
| --- | --- | --- | --- | --- |
| `scripts/harness/review_gate.ps1` | 复用 | `review gate` | 读取 plan 并输出 pass / fail | 不负责实现业务逻辑 |

### 关键执行时序
```mermaid
flowchart TD
    Entry["PowerShell gate"] --> Gate["review_gate.ps1"]
    Gate --> Result["pass/fail"]
```
- `图示说明`：PowerShell 入口读取 plan 后给出结论。
- `步骤化时序`：
  1. check script 传入 `-Plan` 参数。
  2. review gate 读取 plan 并检查实现骨架。
  3. blocking findings 为 none 时输出 pass。
- `关键状态推进 / 数据流`：输入路径被解析为一个待校验 plan，最后输出 gate 结果。

### 停止 / 错误 / 恢复
- `正常停止条件`：plan 通过校验并输出 pass。
- `主要错误出口`：plan 缺字段或缺结构时输出 fail。
- `关键分支 / 降级路径`：缺少实现骨架时立即失败，不继续读取 review 结果。
- `恢复 / 重试 / 回滚`：补全 plan 后可安全重跑。

## Reference Snippets

```text
result=pass
blocking_findings=none
```

- `片段说明`：锁定 gate 成功时的最小输出形状。

## Concrete Steps

### 实现步骤
1. 读取 plan。
2. 校验实现骨架。

## Review Summary
- `blocking_findings`: none
'@

    $tmpPlanLegacy = New-PlanFixture @'
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
'@

    $tmpBadPlanNoSteps = New-PlanFixture @'
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

### 停止 / 错误 / 恢复
- `正常停止条件`：runner 返回结果。
- `主要错误出口`：参数缺失时直接返回错误。
- `关键分支 / 降级路径`：无 pipeline 时降级为失败返回，不启动 runner。
- `恢复 / 重试 / 回滚`：修正参数后可安全重跑。

## Reference Snippets

```text
SmokeRunnerConfig{Pipeline: "smoke"}
```

## Concrete Steps

### 实现步骤
1. verify

## Review Summary
- `blocking_findings`: none
'@

    $tmpBadPlanNoCore = New-PlanFixture @'
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

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
'@

    $tmpBadPlanNoBranch = New-PlanFixture @'
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

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
'@

    $tmpBadPlanNoSnippets = New-PlanFixture @'
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
'@

    $tmpBadPlanNoComponentRow = New-PlanFixture @'
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

## Concrete Steps

### 实现步骤
1. 编写 smoke runner。

## Review Summary
- `blocking_findings`: none
'@

    $tmpBadPlanHarnessFlow = New-PlanFixture @'
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
'@

    Test-ReviewGate -Plan $tmpPlanNew -ShouldPass $true -FailureMessage "review_gate.ps1 should pass for a new implementation-first plan"
    Test-ReviewGate -Plan $tmpPlanLegacy -ShouldPass $true -FailureMessage "review_gate.ps1 should still pass for a legacy plan without frontmatter"
    Test-ReviewGate -Plan $tmpBadPlanNoSteps -ShouldPass $false -FailureMessage "review_gate.ps1 should fail for a plan without step-by-step flow"
    Test-ReviewGate -Plan $tmpBadPlanNoCore -ShouldPass $false -FailureMessage "review_gate.ps1 should fail for a plan without core object/result"
    Test-ReviewGate -Plan $tmpBadPlanNoBranch -ShouldPass $false -FailureMessage "review_gate.ps1 should fail for a plan without key branch/degrade path"
    Test-ReviewGate -Plan $tmpBadPlanNoSnippets -ShouldPass $false -FailureMessage "review_gate.ps1 should fail for a plan without reference snippets"
    Test-ReviewGate -Plan $tmpBadPlanNoComponentRow -ShouldPass $false -FailureMessage "review_gate.ps1 should fail for a plan without a real component responsibility entry"
    Test-ReviewGate -Plan $tmpBadPlanHarnessFlow -ShouldPass $false -FailureMessage "review_gate.ps1 should fail for a plan that only contains harness flow"
}
finally {
    foreach ($path in $tempPlans) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

Write-Output "harness check passed"
