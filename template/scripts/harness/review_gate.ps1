[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [Alias("PlanPath")]
    [string]$Plan
)

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $scriptDir "common.ps1")

function Fail {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [int]$Code = 1
    )
    [Console]::Error.WriteLine($Message)
    exit $Code
}

if ([string]::IsNullOrWhiteSpace($Plan)) {
    Fail -Message "review gate: pass a plan path via -Plan or the first argument" -Code 2
}

if (-not (Test-Path -LiteralPath $Plan -PathType Leaf)) {
    Fail -Message "review gate: missing plan file: $Plan" -Code 2
}

$planStructureErrors = Get-PlanImplementationSkeletonErrors -Path $Plan
if ($planStructureErrors.Count -gt 0) {
    [Console]::Error.WriteLine("result=fail")
    [Console]::Error.WriteLine("reason=plan implementation skeleton is incomplete")
    foreach ($item in $planStructureErrors) {
        [Console]::Error.WriteLine($item)
    }
    [Console]::Error.WriteLine("plan=$Plan")
    exit 1
}

$blockingFindings = Get-SectionField -Path $Plan -Section "## Review Summary" -Field "blocking_findings"
if ([string]::IsNullOrWhiteSpace($blockingFindings)) {
    Fail -Message "review gate: missing blocking_findings in $Plan" -Code 2
}

$normalized = ($blockingFindings -replace '`', '').Trim().ToLowerInvariant()
if ($normalized -eq "none") {
    Write-Output "result=pass"
    Write-Output "blocking_findings=none"
    Write-Output "plan=$Plan"
    exit 0
}

[Console]::Error.WriteLine("result=fail")
[Console]::Error.WriteLine("blocking_findings=$blockingFindings")
[Console]::Error.WriteLine("plan=$Plan")
exit 1
