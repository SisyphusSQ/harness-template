[CmdletBinding()]
param(
    [string]$Target = "",
    [string]$ProjectName = "",
    [ValidateSet("go", "python", "java", "c", "go-node", "python-node", "java-node", "c-node", "java-c", "java-c-node")]
    [string]$Stack = "",
    [ValidateSet("neutral", "github", "gitlab")]
    [string]$Provider = "neutral",
    [ValidateSet("linear", "github", "gitlab", "repo", "other")]
    [string]$IssueProvider = "linear",
    [string]$IssuePrefix = "",
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$harnessRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$templateDir = Join-Path $harnessRoot "template"
$sharedGitignoreDir = Join-Path $harnessRoot "sources\gitignore"
$utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false

function Show-Usage {
    Write-Output @"
Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\init_harness_project.ps1 `
  -Target C:\path\to\repo `
  -ProjectName NAME `
  -Stack go|python|java|c|go-node|python-node|java-node|c-node|java-c|java-c-node `
  [-Provider neutral|github|gitlab] `
  [-IssueProvider linear|github|gitlab|repo|other] `
  [-IssuePrefix PREFIX] `
  [-Force] `
  [-DryRun]
"@
}

function Fail {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [int]$Code = 1
    )

    [Console]::Error.WriteLine($Message)
    exit $Code
}

function Log {
    param([Parameter(Mandatory=$true)][string]$Message)

    Write-Output $Message
}

function Join-RelativePath {
    param(
        [Parameter(Mandatory=$true)][string]$Base,
        [Parameter(Mandatory=$true)][string]$Relative
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
    "docs/harness/README.md",
    "docs/harness/prompt-templates.md",
    ".agents/mappings/reference-mapping.yaml",
    ".agents/mappings/knowledge-writeback-mapping.example.yaml",
    "scripts/harness/merge_gate.sh",
    "scripts/harness/escalation_gate.sh"
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
        Fail "obsolete managed files detected in target; rerun with -Force to clean them before post-check"
    }
}

function Copy-ManagedFile {
    param([Parameter(Mandatory=$true)][string]$Relative)

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
    $parts = New-Object System.Collections.Generic.List[string]
    [void]$parts.Add((Join-Path $sharedGitignoreDir "base.gitignore"))

    switch ($Stack) {
        "go" { [void]$parts.Add((Join-Path $sharedGitignoreDir "go.gitignore")) }
        "python" { [void]$parts.Add((Join-Path $sharedGitignoreDir "python.gitignore")) }
        "java" { [void]$parts.Add((Join-Path $sharedGitignoreDir "java.gitignore")) }
        "c" { [void]$parts.Add((Join-Path $sharedGitignoreDir "c.gitignore")) }
        "go-node" {
            [void]$parts.Add((Join-Path $sharedGitignoreDir "go.gitignore"))
            [void]$parts.Add((Join-Path $sharedGitignoreDir "node-frontend.gitignore"))
        }
        "python-node" {
            [void]$parts.Add((Join-Path $sharedGitignoreDir "python.gitignore"))
            [void]$parts.Add((Join-Path $sharedGitignoreDir "node-frontend.gitignore"))
        }
        "java-node" {
            [void]$parts.Add((Join-Path $sharedGitignoreDir "java.gitignore"))
            [void]$parts.Add((Join-Path $sharedGitignoreDir "node-frontend.gitignore"))
        }
        "c-node" {
            [void]$parts.Add((Join-Path $sharedGitignoreDir "c.gitignore"))
            [void]$parts.Add((Join-Path $sharedGitignoreDir "node-frontend.gitignore"))
        }
        "java-c" {
            [void]$parts.Add((Join-Path $sharedGitignoreDir "java.gitignore"))
            [void]$parts.Add((Join-Path $sharedGitignoreDir "c.gitignore"))
        }
        "java-c-node" {
            [void]$parts.Add((Join-Path $sharedGitignoreDir "java.gitignore"))
            [void]$parts.Add((Join-Path $sharedGitignoreDir "c.gitignore"))
            [void]$parts.Add((Join-Path $sharedGitignoreDir "node-frontend.gitignore"))
        }
    }

    return @($parts)
}

function Build-Gitignore {
    $output = Join-Path $Target ".gitignore"
    $parts = Get-GitignoreParts

    if ($DryRun) {
        Log "[dry-run] build .gitignore from:"
        foreach ($part in $parts) {
            Log "  - $part"
        }
        return
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine("# Generated by init_harness_project.ps1")
    [void]$builder.AppendLine()

    foreach ($part in $parts) {
        [void]$builder.AppendLine([System.IO.File]::ReadAllText($part, [System.Text.Encoding]::UTF8))
        [void]$builder.AppendLine()
    }

    [System.IO.File]::WriteAllText($output, $builder.ToString(), $utf8NoBom)
}

function Replace-Placeholders {
    param([Parameter(Mandatory=$true)][string]$Path)

    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $text = $text.Replace("__PROJECT_NAME__", $ProjectName)
    $text = $text.Replace("__ISSUE_PREFIX__", $IssuePrefix)
    $text = $text.Replace("__PROVIDER__", $Provider)
    $text = $text.Replace("__ISSUE_PROVIDER__", $IssueProvider)
    [System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
}

function Postprocess-TextFiles {
    $files = @(
        "AGENTS.md",
        "README.md",
        ".agents/PLANS.md",
        ".agents/plans/TEMPLATE.md",
        ".agents/state/TEMPLATE.md",
        ".agents/runs/TEMPLATE.md",
        "docs/harness/control-plane.md",
        "docs/harness/issue-workflow.md",
        "docs/harness/linear.md",
        "docs/issues/README.md",
        "docs/issues/TEMPLATE.md"
    )

    if ($DryRun) {
        Log "[dry-run] replace placeholders in template text files"
        return
    }

    foreach ($rel in $files) {
        Replace-Placeholders -Path (Join-RelativePath -Base $Target -Relative $rel)
    }
}

function Run-PostCheck {
    if ($DryRun) {
        Log "[dry-run] run powershell -File scripts\harness\check.ps1"
        return
    }

    $check = Join-Path $Target "scripts\harness\check.ps1"
    Push-Location -LiteralPath $Target
    try {
        & $check
    } finally {
        Pop-Location
    }
}

if ($DryRun -and [string]::IsNullOrWhiteSpace($Target) -and [string]::IsNullOrWhiteSpace($ProjectName) -and [string]::IsNullOrWhiteSpace($Stack)) {
    Show-Usage
    Log "[dry-run] parameter parser loaded; provide -Target, -ProjectName, and -Stack for a full dry run"
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Fail "missing required parameter: -ProjectName" 2
}

if ([string]::IsNullOrWhiteSpace($Stack)) {
    Fail "missing required parameter: -Stack" 2
}

Validate-TargetPath

if (-not $DryRun -and -not (Test-Path -LiteralPath $Target -PathType Container)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}

$managedFiles = @(
    "AGENTS.md",
    "README.md",
    "Makefile",
    ".agents/PLANS.md",
    ".agents/plans/TEMPLATE.md",
    ".agents/plans/EXAMPLE-implementation.md",
    ".agents/state/TEMPLATE.md",
    ".agents/runs/TEMPLATE.md",
    "docs/harness/control-plane.md",
    "docs/harness/issue-workflow.md",
    "docs/harness/linear.md",
    "docs/harness/project-constraints.md",
    "docs/issues/README.md",
    "docs/issues/TEMPLATE.md",
    "docs/test/RUNBOOK_TEMPLATE.md",
    "scripts/harness/check.sh",
    "scripts/harness/common.sh",
    "scripts/harness/review_gate.sh",
    "scripts/harness/check.ps1",
    "scripts/harness/common.ps1",
    "scripts/harness/review_gate.ps1"
)

foreach ($rel in $managedFiles) {
    Copy-ManagedFile -Relative $rel
}

Cleanup-ObsoleteManagedFiles

$gitignorePath = Join-Path $Target ".gitignore"
if ((Test-Path -LiteralPath $gitignorePath) -and -not $Force -and -not $DryRun) {
    Fail "refusing to overwrite existing file without -Force: $gitignorePath"
}

if ($DryRun) {
    $templateGitignore = Join-Path $templateDir ".gitignore"
    Log "[dry-run] copy $templateGitignore -> $gitignorePath (will be rebuilt)"
} else {
    $targetDir = Split-Path -Parent $gitignorePath
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $templateDir ".gitignore") -Destination $gitignorePath -Force
}

Build-Gitignore
Postprocess-TextFiles
Run-PostCheck

Log "initialized harness into: $Target"
Log "stack: $Stack"
Log "provider: $Provider"
Log "issue provider: $IssueProvider"
Log "next steps:"
Log "  1. inspect .gitignore and add repo-specific local files"
Log "  2. read docs\harness\, docs\issues\, and docs\test\RUNBOOK_TEMPLATE.md"
Log "  3. fill docs\harness\project-constraints.md with repo-specific mechanical constraints"
Log "  4. update README and AGENTS with real project context"
Log "  5. create the first plan in .agents\plans\"
Log "  6. run powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\harness\check.ps1"
Log "  7. if an agent is driving init, follow $harnessRoot\agent-init-project.md to add .agents\prompts\ + .agents\guides\"
