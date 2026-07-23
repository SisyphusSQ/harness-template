param()

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TemplateRoot = Join-Path $RepoRoot "template"

function Assert-SourcePatterns {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Patterns
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "harness source verify: missing source contract file: $Path"
    }

    $Content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    foreach ($Pattern in $Patterns) {
        if (-not $Content.Contains($Pattern)) {
            throw "harness source verify: $Path missing source contract: $Pattern"
        }
    }
}

function Get-CurrentPowerShellExecutable {
    $Process = Get-Process -Id $PID
    if ($null -eq $Process -or [string]::IsNullOrWhiteSpace($Process.Path)) {
        throw "harness source verify: unable to locate current PowerShell executable"
    }
    return $Process.Path
}

function Invoke-PowerShellScriptProcess {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [object[]]$ScriptArguments = @(),
        [bool]$ShouldPass = $true,
        [Parameter(Mandatory = $true)][string]$FailureMessage,
        [switch]$Quiet
    )

    $Executable = Get-CurrentPowerShellExecutable
    $Arguments = @("-NoProfile")
    if ((Split-Path -Leaf $Executable) -ieq "powershell.exe") {
        $Arguments += @("-ExecutionPolicy", "Bypass")
    }
    $Arguments += @("-File", $ScriptPath)
    $Arguments += $ScriptArguments

    if ($Quiet) {
        & $Executable @Arguments *> $null
    }
    else {
        & $Executable @Arguments
    }
    $Passed = ($LASTEXITCODE -eq 0)
    if ($Passed -ne $ShouldPass) {
        throw "harness source verify: $FailureMessage"
    }
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

Invoke-PowerShellScriptProcess `
    -ScriptPath (Join-Path $TemplateRoot "scripts/harness/check.ps1") `
    -FailureMessage "target runtime check failed"

$TemplateReadme = [System.IO.File]::ReadAllText((Join-Path $TemplateRoot "README.md"), [System.Text.Encoding]::UTF8)
if ($TemplateReadme -match '(?i)harness|control-plane|\.agents/') {
    throw "harness source verify: template/README.md must stay business-only and contain no harness guidance"
}

Assert-SourcePatterns -Path (Join-Path $TemplateRoot "docs/harness/control-plane.md") -Patterns @(
    "collect + gate -> freeze + slice -> implement -> verify -> review -> closeout",
    '`dispatch` 只在需要多 thread / worktree / subagent fan-out 时进入',
    '`integrate -> post-integration verify` 只在存在可写 lease、branch / worktree 集成或其他 integration event 时进入',
    '`pr_prep -> merge` 只在当前交付目标包含 PR / MR 且用户或仓库规则已授权时进入',
    "Issue Tracker 是主协作真相",
    "write_lease",
    "Current State",
    "Thread Status",
    "post-integration verify",
    "Linear 字段映射",
    ".agents/PLANS.md",
    "Review Policy Contract",
    '`review_policy`: `standard` / `strict`',
    '`standard` 允许主 agent 执行对抗式自审',
    '`strict` 必须由 subagent 独立评审',
    "多仓代码改动、多个可写 lease 或 branch / worktree 集成",
    "鉴权、安全、权限、公开 API 或 contract 兼容性",
    "schema、migration 或数据修改",
    "并发、幂等、重试或业务状态机",
    "release、部署、生产环境或不可逆外部副作用",
    "required live E2E、full-auto 或自动 merge",
    "风险无法可靠判断",
    "Verification Evidence Reuse Contract",
    "deterministic-local",
    "environment-dependent",
    "任何无法确认的情况默认重跑"
)

$ObsoleteTemplateDocs = @(
    "docs/harness/issue-workflow.md",
    "docs/harness/linear.md",
    "docs/harness/project-constraints.md"
)
foreach ($RelativePath in $ObsoleteTemplateDocs) {
    if (Test-Path -LiteralPath (Join-Path $TemplateRoot $RelativePath)) {
        throw "harness source verify: obsolete template document still exists: $RelativePath"
    }
}

Assert-SourcePatterns -Path (Join-Path $TemplateRoot "docs/test/RUNBOOK_TEMPLATE.md") -Patterns @(
    "Test Runbook Template",
    "当前验证结果",
    "本次执行结果",
    "执行副作用",
    "前置条件",
    "测试变量 / 初始化",
    "主路径",
    "清理结果",
    "结果回写"
)

Assert-SourcePatterns -Path (Join-Path $TemplateRoot ".agents/PLANS.md") -Patterns @(
    "最小结构",
    "真实入口与触发",
    "输入装配与边界校验",
    "组件职责与代码落点",
    "关键执行时序",
    "停止 / 错误 / 恢复",
    "Reference Snippets",
    "不要在 plan 复制整套控制面"
)

Assert-SourcePatterns -Path (Join-Path $TemplateRoot ".agents/plans/TEMPLATE.md") -Patterns @(
    "## 0. 现有架构回顾与核心设计决策",
    "### 真实入口与触发",
    "### 输入装配与边界校验",
    "### 组件职责与代码落点",
    "### 关键执行时序",
    "### 停止 / 错误 / 恢复",
    "## Reference Snippets",
    "### 实现步骤",
    "### 验证与收口步骤",
    "## Review Summary",
    "## Outcomes & Retrospective"
)

Assert-SourcePatterns -Path (Join-Path $TemplateRoot ".agents/skills/issue-goal-prompt/SKILL.md") -Patterns @(
    '派生 `review_policy`',
    '兼容性默认值是 `strict`',
    "对抗式自审",
    "验证证据复用",
    "subagent_review_unavailable",
    "manual_gate_live_e2e"
)

Assert-SourcePatterns -Path (Join-Path $TemplateRoot ".agents/skills/issue-goal-prompt/references/goal-prompt-template.md") -Patterns @(
    "- review_policy: <standard|strict>",
    "- subagent_review_required: <true|false>",
    "review_owner: main-agent-self-review",
    "review_owner: subagent",
    '`evidence_id`',
    '`execution_session_id`',
    '`post_integration_verify_summary.status`: `executed`'
)

Assert-SourcePatterns -Path (Join-Path $TemplateRoot "scripts/harness/common.ps1") -Patterns @(
    "Get-PlanImplementationSkeletonErrors",
    "Resolve-PlanImplementationSection",
    "Reference Snippets",
    "组件职责与代码落点"
)
Assert-SourcePatterns -Path (Join-Path $TemplateRoot "scripts/harness/review_gate.ps1") -Patterns @(
    "blocking_findings",
    "result=pass",
    "result=fail"
)
Assert-SourcePatterns -Path (Join-Path $TemplateRoot "scripts/harness/evidence.ps1") -Patterns @(
    "result=",
    "head=",
    "worktree_digest=",
    "evidence_id=",
    "reusable=",
    "reason="
)

$FullRoot = Join-Path $RepoRoot "sources/agent_extensions/full"
$PlaceholderRoot = Join-Path $RepoRoot "sources/agent_extensions/placeholder"
$SharedRoot = Join-Path $RepoRoot "sources/agent_extensions/shared"
$FullFiles = Get-ChildItem -LiteralPath $FullRoot -File -Recurse | ForEach-Object {
    $_.FullName.Substring($FullRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar).Replace("\", "/")
} | Sort-Object
$PlaceholderFiles = Get-ChildItem -LiteralPath $PlaceholderRoot -File -Recurse | ForEach-Object {
    $_.FullName.Substring($PlaceholderRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar).Replace("\", "/")
} | Sort-Object

if (Compare-Object -ReferenceObject $FullFiles -DifferenceObject $PlaceholderFiles) {
    throw "harness source verify: full and placeholder extension bundles have different file sets"
}

Assert-SourcePatterns -Path (Join-Path $SharedRoot ".agents/prompts/README.md") -Patterns @(
    "issue-standard-workflow.md",
    "orchestrator-thread.md",
    "日常自然语言协作不需要额外的 loop prompt"
)

foreach ($RelativePath in $FullFiles) {
    Assert-SourcePatterns -Path (Join-Path $FullRoot $RelativePath) -Patterns @("Mode: full")
    Assert-SourcePatterns -Path (Join-Path $PlaceholderRoot $RelativePath) -Patterns @("Mode: placeholder")
}

foreach ($ModeRoot in @($FullRoot, $PlaceholderRoot)) {
    Assert-SourcePatterns -Path (Join-Path $ModeRoot ".agents/prompts/issue-standard-workflow.md") -Patterns @(
        "review_policy",
        "subagent_review_required",
        "evidence_id",
        "deterministic-local",
        "environment-dependent",
        "发生 integration event"
    )
    Assert-SourcePatterns -Path (Join-Path $ModeRoot ".agents/prompts/orchestrator-thread.md") -Patterns @(
        "Review policy",
        "write_lease",
        "post_integration_verify_summary.status",
        "executed"
    )
    Assert-SourcePatterns -Path (Join-Path $ModeRoot ".agents/guides/code-review.md") -Patterns @(
        "Review Policy",
        "main-agent-self-review",
        "subagent",
        "blocking_findings",
        "对抗式自审"
    )
}

Assert-SourcePatterns -Path (Join-Path $FullRoot ".agents/prompts/orchestrator-thread.md") -Patterns @(
    "Handoff 模板",
    "write_lease",
    "Current State",
    "Thread Status",
    "post-integration verify"
)

foreach ($ModeRoot in @($FullRoot, $PlaceholderRoot)) {
    foreach ($ObsoletePrompt in @("loop-codex.md", "loop-automation.md", "maintenance-loop.md")) {
        $Path = Join-Path $ModeRoot ".agents/prompts/$ObsoletePrompt"
        if (Test-Path -LiteralPath $Path) {
            throw "harness source verify: obsolete prompt still exists: $Path"
        }
    }
}

$ValidPlan = Join-Path $TemplateRoot ".agents/plans/EXAMPLE-implementation.md"
$ReviewGate = Join-Path $TemplateRoot "scripts/harness/review_gate.ps1"
Invoke-PowerShellScriptProcess -ScriptPath $ReviewGate -ScriptArguments @("-Plan", $ValidPlan) `
    -FailureMessage "PowerShell review gate rejected the exemplar" -Quiet

$PlanTempRoot = Join-Path ([IO.Path]::GetTempPath()) ("harness-plan-matrix-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $PlanTempRoot -Force | Out-Null
try {
    $ValidPlanText = [System.IO.File]::ReadAllText($ValidPlan)
    $PlanCases = @(
        @{
            Name = "bad-blocking.md"
            Content = $ValidPlanText.Replace('`blocking_findings`: none', '`blocking_findings`: correctness regression')
            Label = "blocking finding"
        },
        @{
            Name = "bad-steps.md"
            Content = $ValidPlanText.Replace("步骤化时序", "执行顺序")
            Label = "missing step-by-step sequence"
        },
        @{
            Name = "bad-core.md"
            Content = $ValidPlanText.Replace("装配结果 / 核心对象", "装配产物")
            Label = "missing assembled core object"
        },
        @{
            Name = "bad-branch.md"
            Content = $ValidPlanText.Replace("关键分支 / 降级路径", "异常分支")
            Label = "missing key branch"
        },
        @{
            Name = "bad-snippets.md"
            Content = $ValidPlanText.Replace("## Reference Snippets", "## Reference Samples")
            Label = "missing reference snippets"
        }
    )

    foreach ($Case in $PlanCases) {
        $CasePath = Join-Path $PlanTempRoot $Case.Name
        Write-Utf8NoBom -Path $CasePath -Content $Case.Content
        Invoke-PowerShellScriptProcess -ScriptPath $ReviewGate -ScriptArguments @("-Plan", $CasePath) `
            -ShouldPass $false -FailureMessage "PowerShell review gate accepted invalid plan: $($Case.Label)" -Quiet
    }

    $LegacyPlan = Join-Path $PlanTempRoot "legacy-plan.md"
    Write-Utf8NoBom -Path $LegacyPlan -Content $ValidPlanText.Replace(
        "## 0. 现有架构回顾与核心设计决策",
        "## Architecture / Data Flow"
    )
    Invoke-PowerShellScriptProcess -ScriptPath $ReviewGate -ScriptArguments @("-Plan", $LegacyPlan) `
        -FailureMessage "PowerShell review gate rejected the legacy implementation section" -Quiet

    $ComponentStart = $ValidPlanText.IndexOf("### 组件职责与代码落点", [StringComparison]::Ordinal)
    $ComponentEnd = $ValidPlanText.IndexOf("### 关键执行时序", $ComponentStart, [StringComparison]::Ordinal)
    if ($ComponentStart -lt 0 -or $ComponentEnd -lt 0) {
        throw "harness source verify: unable to construct missing-component-row plan fixture"
    }
    $ComponentSection = $ValidPlanText.Substring($ComponentStart, $ComponentEnd - $ComponentStart)
    $ComponentLines = $ComponentSection -split '\r?\n'
    $KeptComponentLines = $ComponentLines | Where-Object {
        -not ($_.StartsWith("|") -and -not $_.Contains("---") -and -not $_.Contains("模块/类型"))
    }
    $BadComponentText = $ValidPlanText.Substring(0, $ComponentStart) +
        ($KeptComponentLines -join [Environment]::NewLine) + [Environment]::NewLine +
        $ValidPlanText.Substring($ComponentEnd)
    $BadComponent = Join-Path $PlanTempRoot "bad-component.md"
    Write-Utf8NoBom -Path $BadComponent -Content $BadComponentText
    Invoke-PowerShellScriptProcess -ScriptPath $ReviewGate -ScriptArguments @("-Plan", $BadComponent) `
        -ShouldPass $false -FailureMessage "PowerShell review gate accepted invalid plan: missing component row" -Quiet

    $BadHarnessFlow = Join-Path $PlanTempRoot "bad-harness-flow.md"
    Write-Utf8NoBom -Path $BadHarnessFlow -Content @'
# ExecPlan: harness-only flow

## Architecture / Data Flow

```mermaid
flowchart TD
  Collect["collect"] --> Verify["verify"]
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
    Invoke-PowerShellScriptProcess -ScriptPath $ReviewGate -ScriptArguments @("-Plan", $BadHarnessFlow) `
        -ShouldPass $false -FailureMessage "PowerShell review gate accepted invalid plan: harness-only flow" -Quiet
}
finally {
    Remove-Item -LiteralPath $PlanTempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$TempTarget = Join-Path ([IO.Path]::GetTempPath()) ("harness-source-verify-" + [Guid]::NewGuid().ToString("N"))
try {
    $RunningOnWindows = ($env:OS -eq "Windows_NT") -or ([IO.Path]::DirectorySeparatorChar -eq [char]'\')
    $Initializer = Join-Path $RepoRoot "scripts/init_harness_project.ps1"
    if ($RunningOnWindows) {
        Invoke-PowerShellScriptProcess -ScriptPath $Initializer -ScriptArguments @(
            "-Target", $TempTarget,
            "-ProjectName", "Harness Source Verify",
            "-Stack", "go",
            "-Provider", "neutral",
            "-IssueProvider", "linear",
            "-IssuePrefix", "HSV"
        ) -FailureMessage "PowerShell initializer failed" -Quiet

        Push-Location $TempTarget
        try {
            Invoke-PowerShellScriptProcess -ScriptPath (Join-Path $TempTarget "scripts/harness/check.ps1") `
                -FailureMessage "initialized target failed PowerShell target check" -Quiet
        }
        finally {
            Pop-Location
        }
    }
    else {
        Invoke-PowerShellScriptProcess -ScriptPath $Initializer -ScriptArguments @("-DryRun") `
            -FailureMessage "PowerShell initializer dry run failed" -Quiet
        Write-Output "PowerShell initializer temp-target smoke: skipped on non-Windows native path contract"
    }
}
finally {
    if (Test-Path -LiteralPath $TempTarget) {
        Remove-Item -LiteralPath $TempTarget -Recurse -Force
    }
}

$Python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -ne $Python) {
    $env:PYTHONDONTWRITEBYTECODE = "1"
    & $Python.Source (Join-Path $TemplateRoot ".agents/skills/project-plan-archive/tests/test_project_plan_archive.py") | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "harness source verify: project plan archive tests failed"
    }
    & $Python.Source (Join-Path $TemplateRoot ".agents/skills/project-version-release/scripts/project_version_release.py") --help | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "harness source verify: project version release helper failed"
    }
}
else {
    throw "harness source verify: python3 is required"
}

Write-Output "harness source verify passed"
