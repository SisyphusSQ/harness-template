param()

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TemplateRoot = Join-Path $RepoRoot "template"
$BashInitializer = Join-Path $RepoRoot "scripts/init_harness_project.sh"
$PowerShellInitializer = Join-Path $RepoRoot "scripts/init_harness_project.ps1"

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    throw "initializer source verify: $Message"
}

function Assert-File {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $Path = Join-Path $RepoRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail "missing source file: $RelativePath"
    }
    return $Path
}

function Assert-TemplateFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $Path = Join-Path $TemplateRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail "missing template file: $RelativePath"
    }
    return $Path
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Expected
    )
    $Content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if (-not $Content.Contains($Expected)) {
        Fail "$Path missing source contract: $Expected"
    }
}

function Assert-NotContains {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Forbidden
    )
    $Content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if ($Content.Contains($Forbidden)) {
        Fail "$Path contains forbidden source contract: $Forbidden"
    }
}

function Assert-TemplateHasNoForbiddenTerms {
    param([Parameter(Mandatory = $true)][string]$Root)
    $Pattern = '(?i)harness|control-plane|write_lease|review_policy|evidence_id|post[._]integration|make harness|scripts/harness|docs/harness'
    foreach ($File in Get-ChildItem -LiteralPath $Root -File -Recurse) {
        $Content = [System.IO.File]::ReadAllText($File.FullName, [System.Text.Encoding]::UTF8)
        if ($Content -match $Pattern) {
            Fail "default template contains Harness-specific flow terms: $($File.FullName)"
        }
    }
}

$RootFiles = @(
    "README.md",
    "agent-init-project.md",
    "init-harness-project-sop.md",
    "Makefile",
    "scripts/init_harness_project.sh",
    "scripts/init_harness_project.ps1",
    "scripts/verify_harness_source.sh",
    "scripts/verify_harness_source.ps1",
    "sources/gitignore/base.gitignore",
    "tests/source_verify_contract_test.sh",
    "tests/target_check_contract_test.sh",
    "tests/policy_contract_test.sh"
)
foreach ($RelativePath in $RootFiles) {
    [void](Assert-File -RelativePath $RelativePath)
}

$TemplateFiles = @(
    "AGENTS.md",
    "README.md",
    ".gitignore",
    ".agents/PLANS.md",
    ".agents/plans/TEMPLATE.md",
    ".agents/plans/EXAMPLE-implementation.md",
    ".agents/state/TEMPLATE.md",
    ".agents/runs/TEMPLATE.md",
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
    "docs/test/RUNBOOK_TEMPLATE.md",
    "docs/issues/README.md",
    "docs/issues/TEMPLATE.md"
)
foreach ($RelativePath in $TemplateFiles) {
    [void](Assert-TemplateFile -RelativePath $RelativePath)
}

foreach ($RelativePath in @("Makefile", "docs/harness", "scripts/harness")) {
    $Path = Join-Path $TemplateRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $Path) {
        Fail "obsolete source path still exists: template/$RelativePath"
    }
}

$AgentsPath = Join-Path $TemplateRoot "AGENTS.md"
$GitignorePath = Join-Path $TemplateRoot ".gitignore"
Assert-Contains -Path $AgentsPath -Expected ".agents/PLANS.md"
Assert-Contains -Path $AgentsPath -Expected ".agents/state/"
Assert-Contains -Path $AgentsPath -Expected ".agents/runs/"
Assert-Contains -Path $AgentsPath -Expected "__ISSUE_PROVIDER__"
Assert-Contains -Path $GitignorePath -Expected ".agents/state/*"
Assert-Contains -Path $GitignorePath -Expected ".agents/runs/*"
Assert-NotContains -Path $GitignorePath -Forbidden "Harness local auxiliary run surfaces"

Assert-Contains -Path $BashInitializer -Expected 'issue_provider="linear"'
Assert-Contains -Path $PowerShellInitializer -Expected 'IssueProvider = "linear"'
Assert-NotContains -Path $BashInitializer -Forbidden "--provider"
Assert-NotContains -Path $PowerShellInitializer -Forbidden "-Provider"
Assert-Contains -Path $BashInitializer -Expected "docs/issues/README.md"
Assert-Contains -Path $PowerShellInitializer -Expected "docs/issues/README.md"

foreach ($RelativePath in @(
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
    ".agents/skills/test-runbook/agents/openai.yaml"
)) {
    Assert-Contains -Path $BashInitializer -Expected ('"' + $RelativePath + '"')
    Assert-Contains -Path $PowerShellInitializer -Expected ('"' + $RelativePath + '"')
}

foreach ($RelativePath in @(
    "AGENTS.md",
    "README.md",
    ".agents/PLANS.md",
    ".agents/plans/TEMPLATE.md",
    ".agents/plans/EXAMPLE-implementation.md",
    ".agents/state/TEMPLATE.md",
    ".agents/runs/TEMPLATE.md",
    "docs/test/RUNBOOK_TEMPLATE.md"
)) {
    Assert-Contains -Path $BashInitializer -Expected ('"' + $RelativePath + '"')
    Assert-Contains -Path $PowerShellInitializer -Expected ('"' + $RelativePath + '"')
}

Assert-NotContains -Path (Join-Path $RepoRoot "README.md") -Forbidden "--provider"
Assert-NotContains -Path (Join-Path $RepoRoot "agent-init-project.md") -Forbidden "--provider"
Assert-NotContains -Path (Join-Path $RepoRoot "init-harness-project-sop.md") -Forbidden "--provider"
Assert-TemplateHasNoForbiddenTerms -Root $TemplateRoot

Write-Output "initializer source verify passed"
