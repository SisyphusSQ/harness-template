[CmdletBinding()]
param(
    [string]$Target = "",
    [string]$ProjectName = "",
    [ValidateSet("go", "python", "java", "c", "go-node", "python-node", "java-node", "c-node", "java-c", "java-c-node")]
    [string]$Stack = "",
    [ValidateSet("linear", "github", "gitlab", "repo", "other")]
    [string]$IssueProvider = "linear",
    [string]$IssuePrefix = "",
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$initializerRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$templateDir = Join-Path $initializerRoot "template"
$sharedGitignoreDir = Join-Path $initializerRoot "sources\gitignore"
$utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false

function Show-Usage {
    Write-Output "Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\init_harness_project.ps1"
    Write-Output "  -Target C:\path\to\repo -ProjectName NAME -Stack go"
    Write-Output "  [-IssueProvider linear|github|gitlab|repo|other] [-IssuePrefix PREFIX] [-Force] [-DryRun]"
}

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message, [int]$Code = 1)
    [Console]::Error.WriteLine($Message)
    exit $Code
}

function Log {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Output $Message
}

function Join-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$Relative
    )
    return (Join-Path $Base ($Relative -replace '/', [System.IO.Path]::DirectorySeparatorChar))
}

function Validate-TargetPath {
    if ([string]::IsNullOrWhiteSpace($Target)) {
        Fail "missing required parameter: -Target" 2
    }
    $isDriveAbsolute = $Target -match '^[A-Za-z]:[\\/]'
    $isUncAbsolute = $Target -match '^[\\]{2}[^\\/]'
    if (-not ($isDriveAbsolute -or $isUncAbsolute)) {
        Fail "-Target must be a native absolute path such as C:\path\to\repo or \\server\share\repo: $Target" 2
    }
    if ((Test-Path -LiteralPath $Target) -and -not (Test-Path -LiteralPath $Target -PathType Container)) {
        Fail "target exists and is not a directory: $Target" 2
    }
}

$obsoleteManagedFiles = @(
    "Makefile",
    "docs/harness/control-plane.md",
    "docs/harness/README.md",
    "docs/harness/prompt-templates.md",
    "docs/harness/issue-workflow.md",
    "docs/harness/linear.md",
    "docs/harness/project-constraints.md",
    "scripts/harness/check.sh",
    "scripts/harness/common.sh",
    "scripts/harness/evidence.sh",
    "scripts/harness/review_gate.sh",
    "scripts/harness/check.ps1",
    "scripts/harness/common.ps1",
    "scripts/harness/evidence.ps1",
    "scripts/harness/review_gate.ps1",
    ".agents/prompts/README.md",
    ".agents/prompts/issue-standard-workflow.md",
    ".agents/prompts/orchestrator-thread.md",
    ".agents/prompts/loop-codex.md",
    ".agents/prompts/loop-automation.md",
    ".agents/prompts/maintenance-loop.md",
    ".agents/guides/code-review.md",
    ".agents/guides/linter.md",
    ".agents/mappings/reference-mapping.yaml",
    ".agents/mappings/knowledge-writeback-mapping.example.yaml"
)

$obsoleteManagedDirectories = @(
    "docs/harness",
    "scripts/harness",
    ".agents/prompts",
    ".agents/guides",
    ".agents/mappings"
)

function Cleanup-ObsoleteManagedFiles {
    $found = $false
    foreach ($rel in $obsoleteManagedFiles) {
        $path = Join-RelativePath -Base $Target -Relative $rel
        if (Test-Path -LiteralPath $path) {
            $found = $true
            if ($Force) {
                if ($DryRun) {
                    Log "[dry-run] remove obsolete managed file $path"
                } else {
                    Remove-Item -LiteralPath $path -Force
                }
            }
        }
    }
    if ($found -and -not $Force -and -not $DryRun) {
        Fail "obsolete managed files detected in target; rerun with -Force to clean them before initialization"
    }
    if ($Force) {
        foreach ($rel in $obsoleteManagedDirectories) {
            $directory = Join-RelativePath -Base $Target -Relative $rel
            if (Test-Path -LiteralPath $directory -PathType Container) {
                $children = @(Get-ChildItem -LiteralPath $directory -Force)
                if ($children.Count -eq 0) {
                    if ($DryRun) {
                        Log "[dry-run] remove empty obsolete managed directory $directory"
                    } else {
                        Remove-Item -LiteralPath $directory -Force
                    }
                }
            }
        }
    }
}

function Copy-ManagedFile {
    param([Parameter(Mandatory = $true)][string]$Relative)
    $source = Join-RelativePath -Base $templateDir -Relative $Relative
    $destination = Join-RelativePath -Base $Target -Relative $Relative
    if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        Fail "refusing to overwrite existing file without -Force: $destination"
    }
    if ($DryRun) {
        Log "[dry-run] copy $source -> $destination"
        return
    }
    $destinationDir = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $destinationDir -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

function Get-GitignoreParts {
    $parts = @((Join-Path $sharedGitignoreDir "base.gitignore"))
    switch ($Stack) {
        "go" { $parts += (Join-Path $sharedGitignoreDir "go.gitignore") }
        "python" { $parts += (Join-Path $sharedGitignoreDir "python.gitignore") }
        "java" { $parts += (Join-Path $sharedGitignoreDir "java.gitignore") }
        "c" { $parts += (Join-Path $sharedGitignoreDir "c.gitignore") }
        "go-node" {
            $parts += (Join-Path $sharedGitignoreDir "go.gitignore")
            $parts += (Join-Path $sharedGitignoreDir "node-frontend.gitignore")
        }
        "python-node" {
            $parts += (Join-Path $sharedGitignoreDir "python.gitignore")
            $parts += (Join-Path $sharedGitignoreDir "node-frontend.gitignore")
        }
        "java-node" {
            $parts += (Join-Path $sharedGitignoreDir "java.gitignore")
            $parts += (Join-Path $sharedGitignoreDir "node-frontend.gitignore")
        }
        "c-node" {
            $parts += (Join-Path $sharedGitignoreDir "c.gitignore")
            $parts += (Join-Path $sharedGitignoreDir "node-frontend.gitignore")
        }
        "java-c" {
            $parts += (Join-Path $sharedGitignoreDir "java.gitignore")
            $parts += (Join-Path $sharedGitignoreDir "c.gitignore")
        }
        "java-c-node" {
            $parts += (Join-Path $sharedGitignoreDir "java.gitignore")
            $parts += (Join-Path $sharedGitignoreDir "c.gitignore")
            $parts += (Join-Path $sharedGitignoreDir "node-frontend.gitignore")
        }
    }
    return $parts
}

function Build-Gitignore {
    $output = Join-Path $Target ".gitignore"
    $parts = Get-GitignoreParts
    if ($DryRun) {
        Log "[dry-run] build .gitignore from:"
        foreach ($part in $parts) { Log "  - $part" }
        return
    }
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine("# Generated by the project initializer.")
    [void]$builder.AppendLine()
    foreach ($part in $parts) {
        [void]$builder.AppendLine([System.IO.File]::ReadAllText($part, [System.Text.Encoding]::UTF8))
        [void]$builder.AppendLine()
    }
    [System.IO.File]::WriteAllText($output, $builder.ToString(), $utf8NoBom)
}

function Replace-Placeholders {
    param([Parameter(Mandatory = $true)][string]$Path)
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $text = $text.Replace("__PROJECT_NAME__", $ProjectName)
    $text = $text.Replace("__ISSUE_PREFIX__", $IssuePrefix)
    $text = $text.Replace("__ISSUE_PROVIDER__", $IssueProvider)
    [System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
}

function Postprocess-TextFiles {
    $files = @(
        "AGENTS.md",
        "README.md",
        ".agents/PLANS.md",
        ".agents/plans/TEMPLATE.md",
        ".agents/plans/EXAMPLE-implementation.md",
        ".agents/state/TEMPLATE.md",
        ".agents/runs/TEMPLATE.md",
        "docs/test/RUNBOOK_TEMPLATE.md"
    )
    if ($IssueProvider -eq "repo") {
        $files += "docs/issues/README.md"
        $files += "docs/issues/TEMPLATE.md"
    }
    if ($DryRun) {
        Log "[dry-run] replace placeholders in template text files"
        return
    }
    foreach ($rel in $files) {
        Replace-Placeholders -Path (Join-RelativePath -Base $Target -Relative $rel)
    }
}

if ($DryRun -and [string]::IsNullOrWhiteSpace($Target) -and [string]::IsNullOrWhiteSpace($ProjectName) -and [string]::IsNullOrWhiteSpace($Stack)) {
    Show-Usage
    Log "[dry-run] parameter parser loaded; provide -Target, -ProjectName, and -Stack for a full dry run"
    exit 0
}
if ([string]::IsNullOrWhiteSpace($ProjectName)) { Fail "missing required parameter: -ProjectName" 2 }
if ([string]::IsNullOrWhiteSpace($Stack)) { Fail "missing required parameter: -Stack" 2 }

Validate-TargetPath
if (-not $DryRun -and -not (Test-Path -LiteralPath $Target -PathType Container)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}
Cleanup-ObsoleteManagedFiles

$managedFiles = @(
    "AGENTS.md",
    "README.md",
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
    "docs/test/RUNBOOK_TEMPLATE.md"
)
if ($IssueProvider -eq "repo") {
    $managedFiles += "docs/issues/README.md"
    $managedFiles += "docs/issues/TEMPLATE.md"
}
foreach ($rel in $managedFiles) { Copy-ManagedFile -Relative $rel }

$gitignorePath = Join-Path $Target ".gitignore"
if ((Test-Path -LiteralPath $gitignorePath) -and -not $Force -and -not $DryRun) {
    Fail "refusing to overwrite existing file without -Force: $gitignorePath"
}
if ($DryRun) {
    Log "[dry-run] copy $(Join-Path $templateDir '.gitignore') -> $gitignorePath (will be rebuilt)"
} else {
    $targetDir = Split-Path -Parent $gitignorePath
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $templateDir ".gitignore") -Destination $gitignorePath -Force
}

Build-Gitignore
Postprocess-TextFiles

Log "initialized project baseline into: $Target"
Log "stack: $Stack"
Log "issue provider: $IssueProvider"
Log "next steps:"
Log "  1. fill AGENTS.md with repo-specific build, test, lint, live E2E, and release constraints"
Log "  2. read the skills or runbook that match the task"
Log "  3. create a plan under .agents\plans\ only when the task needs one"
Log "  4. keep real .agents\state\ and .agents\runs\ files local unless the project explicitly tracks them"
