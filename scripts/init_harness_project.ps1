[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][string]$ProjectName,
    [Parameter(Mandatory = $true)][string]$Stack,
    [string]$IssueProvider = "linear",
    [string]$IssuePrefix = "",
    [string[]]$Skill = @(),
    [string[]]$Overwrite = @(),
    [switch]$DryRun,
    [switch]$Force
)
$ErrorActionPreference = "Stop"
$arguments = @((Join-Path $PSScriptRoot "init_harness_project.py"),
    "--target", $Target, "--project-name", $ProjectName,
    "--stack", $Stack, "--issue-provider", $IssueProvider)
if ($IssuePrefix) { $arguments += @("--issue-prefix", $IssuePrefix) }
foreach ($name in $Skill) { $arguments += @("--skill", $name) }
foreach ($path in $Overwrite) { $arguments += @("--overwrite", $path) }
if ($DryRun) { $arguments += "--dry-run" }
if ($Force) { $arguments += "--force" }
if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 @arguments
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    & python3 @arguments
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python @arguments
} else {
    throw "Python 3.10+ is required; install it before initializing a project."
}
exit $LASTEXITCODE
