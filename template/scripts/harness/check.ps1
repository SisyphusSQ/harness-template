[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
Set-Location $repoRoot

function Fail {
    param([Parameter(Mandatory=$true)][string]$Message)
    [Console]::Error.WriteLine($Message)
    exit 1
}

function Get-FileText {
    param([Parameter(Mandatory=$true)][string]$Path)
    return [System.IO.File]::ReadAllText((Join-Path $repoRoot $Path))
}

function Assert-FileContains {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Pattern,
        [Parameter(Mandatory=$true)][string]$Message
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail -Message "Missing required harness file: $Path"
    }
    if (-not (Get-FileText -Path $Path).Contains($Pattern)) {
        Fail -Message $Message
    }
}

function Invoke-ReviewGateProcess {
    param(
        [Parameter(Mandatory=$true)][string]$Plan,
        [Parameter(Mandatory=$true)][bool]$ShouldPass,
        [Parameter(Mandatory=$true)][string]$Message
    )

    $reviewGate = Join-Path $repoRoot "scripts\harness\review_gate.ps1"
    $powerShellExe = (Get-Process -Id $PID).Path
    $invokeArguments = @("-NoProfile")
    if ((Split-Path -Leaf $powerShellExe) -ieq "powershell.exe") {
        $invokeArguments += @("-ExecutionPolicy", "Bypass")
    }
    $invokeArguments += @("-File", $reviewGate, "-Plan", $Plan)
    & $powerShellExe @invokeArguments *> $null
    $passed = ($LASTEXITCODE -eq 0)
    if ($passed -ne $ShouldPass) {
        Fail -Message $Message
    }
}

function Get-OutputField {
    param(
        [Parameter(Mandatory=$true)][object[]]$Lines,
        [Parameter(Mandatory=$true)][string]$Name
    )

    $prefix = "$Name="
    foreach ($line in $Lines) {
        $text = [string]$line
        if ($text.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
            return $text.Substring($prefix.Length)
        }
    }
    return ""
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
    ".agents/skills/issue-goal-prompt/SKILL.md",
    ".agents/skills/issue-goal-prompt/agents/openai.yaml",
    ".agents/skills/issue-goal-prompt/references/goal-prompt-template.md",
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
    "scripts/harness/evidence.sh",
    "scripts/harness/check.ps1",
    "scripts/harness/common.ps1",
    "scripts/harness/review_gate.ps1",
    "scripts/harness/evidence.ps1"
)

foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail -Message "Missing required harness file: $path"
    }
}

if (Test-Path -LiteralPath "docs/harness/prompt-templates.md" -PathType Leaf) {
    Fail -Message "Obsolete harness file should not exist anymore: docs/harness/prompt-templates.md"
}

$skillFrontmatter = @(
    @(".agents/skills/issue-goal-prompt/SKILL.md", "name: issue-goal-prompt"),
    @(".agents/skills/project-plan-archive/SKILL.md", "name: project-plan-archive"),
    @(".agents/skills/project-version-release/SKILL.md", "name: project-version-release"),
    @(".agents/skills/test-runbook/SKILL.md", "name: test-runbook")
)

foreach ($item in $skillFrontmatter) {
    Assert-FileContains -Path $item[0] -Pattern "---" -Message "Skill frontmatter is incomplete: $($item[0])"
    Assert-FileContains -Path $item[0] -Pattern $item[1] -Message "Skill frontmatter is incomplete: $($item[0])"
    Assert-FileContains -Path $item[0] -Pattern "description:" -Message "Skill frontmatter is incomplete: $($item[0])"
}

$projectSpecific = Get-ChildItem -LiteralPath ".agents/skills" -Recurse -File -Force |
    Select-String -Pattern "DBBridge|db_bridge_test|/Users/suqing|TEA-" -CaseSensitive
if ($projectSpecific) {
    Fail -Message "Default harness skills must not contain project-specific constants"
}

$python = Get-Command python3 -ErrorAction SilentlyContinue
if ($python) {
    & $python.Source ".agents/skills/project-plan-archive/scripts/project_plan_archive.py" --help *> $null
    if ($LASTEXITCODE -ne 0) { Fail -Message "project_plan_archive.py --help failed" }
    & $python.Source ".agents/skills/project-version-release/scripts/project_version_release.py" --help *> $null
    if ($LASTEXITCODE -ne 0) { Fail -Message "project_version_release.py --help failed" }
}

$makefileText = Get-FileText -Path "Makefile"
foreach ($target in @("harness-check", "harness-verify", "harness-review-gate")) {
    if ($makefileText -notmatch "(?m)^$([regex]::Escape($target)):") {
        Fail -Message "Makefile missing target: $target"
    }
}

foreach ($pattern in @(
    ".DS_Store", ".idea/", ".vscode/", "*.log", "logs/", "tmp/", "temp/",
    ".agents/state/*", "!.agents/state/TEMPLATE.md", ".agents/runs/*",
    "!.agents/runs/TEMPLATE.md", ".cursor/*", "!.cursor/rules/", "!.cursor/rules/*.mdc"
)) {
    Assert-FileContains -Path ".gitignore" -Pattern $pattern -Message ".gitignore missing required pattern: $pattern"
}

$projectPlaceholder = "__PROJECT" + "_NAME__"
$providerPlaceholder = "__PROVIDER" + "__"
$issueProviderPlaceholder = "__ISSUE" + "_PROVIDER__"
$issuePrefixPlaceholder = "__ISSUE" + "_PREFIX__"
$readmeText = Get-FileText -Path "README.md"
$controlPlaneText = Get-FileText -Path "docs/harness/control-plane.md"
$sourceHarnessRoot = (Resolve-Path (Join-Path $repoRoot "..")).Path
$canonicalSourceTemplate = ""
if (Test-Path -LiteralPath (Join-Path $sourceHarnessRoot "template") -PathType Container) {
    $canonicalSourceTemplate = (Resolve-Path (Join-Path $sourceHarnessRoot "template")).Path
}
$templateSource = $readmeText.Contains("# $projectPlaceholder") -and
    $controlPlaneText.Contains($providerPlaceholder) -and
    $controlPlaneText.Contains($issueProviderPlaceholder) -and
    (Test-Path -LiteralPath (Join-Path $sourceHarnessRoot "scripts/verify_harness_source.sh") -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $sourceHarnessRoot "scripts/verify_harness_source.ps1") -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $sourceHarnessRoot "sources/agent_extensions") -PathType Container) -and
    (-not [string]::IsNullOrWhiteSpace($canonicalSourceTemplate)) -and
    ($repoRoot -eq $canonicalSourceTemplate)

if (-not $templateSource) {
    $placeholderFiles = @(
        Get-Item -LiteralPath "AGENTS.md", "README.md", "Makefile"
        Get-ChildItem -LiteralPath "docs", ".agents" -Recurse -File -Force
    )
    foreach ($file in $placeholderFiles) {
        if ($file.FullName -eq (Join-Path $repoRoot "scripts\harness\check.ps1")) { continue }
        $text = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($placeholder in @($projectPlaceholder, $providerPlaceholder, $issueProviderPlaceholder, $issuePrefixPlaceholder)) {
            if ($text.Contains($placeholder)) {
                Fail -Message "Unresolved harness initializer placeholder detected"
            }
        }
    }

    $mergeMatch = [regex]::Match($controlPlaneText, '当前 merge provider：\s*- `([^`]+)`')
    $issueMatch = [regex]::Match($controlPlaneText, '当前 issue provider：\s*- `([^`]+)`')
    $mergeProvider = if ($mergeMatch.Success) { $mergeMatch.Groups[1].Value } else { "" }
    $issueProvider = if ($issueMatch.Success) { $issueMatch.Groups[1].Value } else { "" }
    if ($mergeProvider -notin @("neutral", "github", "gitlab")) {
        Fail -Message "Invalid merge provider: $mergeProvider"
    }
    if ($issueProvider -notin @("linear", "github", "gitlab", "repo", "other")) {
        Fail -Message "Invalid issue provider: $issueProvider"
    }
}

if (Test-Path -LiteralPath ".cursor/rules/harness.mdc" -PathType Leaf) {
    Assert-FileContains -Path ".cursor/rules/harness.mdc" -Pattern "alwaysApply: true" `
        -Message ".cursor/rules/harness.mdc missing alwaysApply: true"
    Assert-FileContains -Path ".cursor/rules/harness.mdc" -Pattern "make harness-verify" `
        -Message ".cursor/rules/harness.mdc missing harness verification entry"
}

$optionalModeFiles = @(
    ".agents/prompts/orchestrator-thread.md",
    ".agents/prompts/issue-standard-workflow.md",
    ".agents/prompts/loop-codex.md",
    ".agents/prompts/loop-automation.md",
    ".agents/prompts/maintenance-loop.md",
    ".agents/guides/code-review.md",
    ".agents/guides/linter.md"
)
$optionalBundleFiles = @(".agents/prompts/README.md") + $optionalModeFiles
$hasOptionalBundle = $false
foreach ($path in $optionalBundleFiles) {
    if (Test-Path -LiteralPath $path -PathType Leaf) { $hasOptionalBundle = $true; break }
}

if ($hasOptionalBundle) {
    foreach ($path in $optionalBundleFiles) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Fail -Message "Optional agent extension bundle is incomplete: missing $path"
        }
    }

    $detectedMode = ""
    foreach ($path in $optionalModeFiles) {
        $firstLine = Get-Content -LiteralPath $path -TotalCount 1
        if ($firstLine -notin @("Mode: placeholder", "Mode: full")) {
            Fail -Message "Optional harness file missing valid mode marker: $path"
        }
        $currentMode = $firstLine.Substring("Mode: ".Length)
        if ([string]::IsNullOrEmpty($detectedMode)) {
            $detectedMode = $currentMode
        } elseif ($detectedMode -ne $currentMode) {
            Fail -Message "Optional agent extension bundle has mixed modes: expected $detectedMode, got $currentMode in $path"
        }
    }
}

$tmpPlan = [System.IO.Path]::GetTempFileName()
$tmpBlockingPlan = [System.IO.Path]::GetTempFileName()
$tmpEvidenceRepo = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-evidence-smoke-" + [guid]::NewGuid().ToString("N"))

try {
    Copy-Item -LiteralPath ".agents/plans/EXAMPLE-implementation.md" -Destination $tmpPlan -Force
    $blockingText = [System.IO.File]::ReadAllText($tmpPlan).Replace(
        '`blocking_findings`: none',
        '`blocking_findings`: correctness regression'
    )
    [System.IO.File]::WriteAllText($tmpBlockingPlan, $blockingText)
    Invoke-ReviewGateProcess -Plan $tmpPlan -ShouldPass $true `
        -Message "review gate should pass for the implementation example"
    Invoke-ReviewGateProcess -Plan $tmpBlockingPlan -ShouldPass $false `
        -Message "review gate should fail when blocking findings are present"

    New-Item -ItemType Directory -Path $tmpEvidenceRepo -Force | Out-Null
    & git init -q $tmpEvidenceRepo
    & git -C $tmpEvidenceRepo config user.name "Harness Check"
    & git -C $tmpEvidenceRepo config user.email "harness-check@example.invalid"
    [System.IO.File]::WriteAllText((Join-Path $tmpEvidenceRepo "value.txt"), "base`n")
    & git -C $tmpEvidenceRepo add value.txt
    & git -C $tmpEvidenceRepo commit -qm "test: evidence base"

    Push-Location $tmpEvidenceRepo
    try {
        $evidenceScript = Join-Path $repoRoot "scripts\harness\evidence.ps1"
        $first = @(& $evidenceScript -Action Snapshot)
        $second = @(& $evidenceScript -Action Snapshot)
        $firstId = Get-OutputField -Lines $first -Name "evidence_id"
        $secondId = Get-OutputField -Lines $second -Name "evidence_id"
        if ([string]::IsNullOrWhiteSpace($firstId) -or $firstId -ne $secondId) {
            Fail -Message "evidence helper should be stable for an unchanged repository"
        }

        [System.IO.File]::AppendAllText((Join-Path $tmpEvidenceRepo "value.txt"), "changed`n")
        $changed = @(& $evidenceScript -Action Snapshot)
        $changedId = Get-OutputField -Lines $changed -Name "evidence_id"
        if ([string]::IsNullOrWhiteSpace($changedId) -or $changedId -eq $firstId) {
            Fail -Message "evidence helper should change after repository content changes"
        }
    } finally {
        Pop-Location
    }
} finally {
    Remove-Item -LiteralPath $tmpPlan, $tmpBlockingPlan -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmpEvidenceRepo -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "harness check passed"
