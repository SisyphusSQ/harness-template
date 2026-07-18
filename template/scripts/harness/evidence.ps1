[CmdletBinding()]
param(
    [string]$Action = "Snapshot"
)

$ErrorActionPreference = "Stop"

# Canonical Git inputs: git diff --binary --no-ext-diff, git ls-files --others --exclude-standard -z,
# git ls-files -u, git ls-files -v, and git submodule status/foreach.

function Write-SnapshotResult {
    param(
        [Parameter(Mandatory=$true)][string]$Result,
        [Parameter(Mandatory=$true)][string]$Head,
        [Parameter(Mandatory=$true)][string]$WorktreeDigest,
        [Parameter(Mandatory=$true)][string]$EvidenceId,
        [Parameter(Mandatory=$true)][string]$Reusable,
        [Parameter(Mandatory=$true)][string]$Reason
    )

    Write-Output "result=$Result"
    Write-Output "head=$Head"
    Write-Output "worktree_digest=$WorktreeDigest"
    Write-Output "evidence_id=$EvidenceId"
    Write-Output "reusable=$Reusable"
    Write-Output "reason=$Reason"
}

function Invoke-GitLines {
    param([Parameter(Mandatory=$true)][string[]]$Arguments)

    $lines = @(& git @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
    return $lines
}

function Get-UntrackedBlobHash {
    param([Parameter(Mandatory=$true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force
    $linkProperty = $item.PSObject.Properties["LinkTarget"]
    if ($null -eq $linkProperty -or $null -eq $linkProperty.Value) {
        $linkProperty = $item.PSObject.Properties["Target"]
    }

    if ($null -ne $linkProperty -and $null -ne $linkProperty.Value) {
        $linkTarget = [string](@($linkProperty.Value) | Select-Object -First 1)
        $linkInput = [System.IO.Path]::GetTempFileName()
        try {
            [System.IO.File]::WriteAllText($linkInput, $linkTarget, $utf8NoBom)
            return (Invoke-GitLines -Arguments @("hash-object", $linkInput) | Select-Object -First 1)
        } finally {
            Remove-Item -LiteralPath $linkInput -Force -ErrorAction SilentlyContinue
        }
    }

    return (Invoke-GitLines -Arguments @("hash-object", "--", $Path) | Select-Object -First 1)
}

if ($Action -ine "Snapshot") {
    Write-SnapshotResult -Result "error" -Head "UNKNOWN" -WorktreeDigest "UNKNOWN" `
        -EvidenceId "UNKNOWN" -Reusable "false" -Reason "unsupported_action"
    exit 2
}

try {
    $repoRoot = (Invoke-GitLines -Arguments @("rev-parse", "--show-toplevel") | Select-Object -First 1)
} catch {
    Write-SnapshotResult -Result "error" -Head "UNKNOWN" -WorktreeDigest "UNKNOWN" `
        -EvidenceId "UNKNOWN" -Reusable "false" -Reason "not_git_repository"
    exit 1
}

Push-Location $repoRoot
$snapshotFile = [System.IO.Path]::GetTempFileName()
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

try {
    try {
        $headCommit = (Invoke-GitLines -Arguments @("rev-parse", "--verify", "HEAD") | Select-Object -First 1)
        $diffBase = $headCommit
    } catch {
        $headCommit = "UNBORN"
        $diffBase = ""
    }

    if ($headCommit -eq "UNBORN") {
        $emptyTreeInput = [System.IO.Path]::GetTempFileName()
        try {
            [System.IO.File]::WriteAllBytes($emptyTreeInput, [byte[]]@())
            $diffBase = (Invoke-GitLines -Arguments @("hash-object", "-t", "tree", $emptyTreeInput) | Select-Object -First 1)
        } finally {
            Remove-Item -LiteralPath $emptyTreeInput -Force -ErrorAction SilentlyContinue
        }
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append("head`0$headCommit`0")

    [void]$builder.Append("index`0")
    $indexDiffLines = Invoke-GitLines -Arguments @("diff", "--binary", "--no-ext-diff", "--cached", $diffBase, "--")
    if ($indexDiffLines.Count -gt 0) {
        [void]$builder.Append(($indexDiffLines -join "`n"))
        [void]$builder.Append("`n")
    }

    [void]$builder.Append("worktree`0")
    $worktreeDiffLines = Invoke-GitLines -Arguments @("diff", "--binary", "--no-ext-diff", "--")
    if ($worktreeDiffLines.Count -gt 0) {
        [void]$builder.Append(($worktreeDiffLines -join "`n"))
        [void]$builder.Append("`n")
    }

    $untrackedRaw = (Invoke-GitLines -Arguments @("ls-files", "--others", "--exclude-standard", "-z")) -join "`n"
    foreach ($path in $untrackedRaw.Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries)) {
        $blobHash = Get-UntrackedBlobHash -Path $path
        [void]$builder.Append("untracked`0$path`0$blobHash`0")
    }

    $submoduleSnapshot = Invoke-GitLines -Arguments @("submodule", "status", "--recursive")
    [void]$builder.Append("submodules`0")
    if ($submoduleSnapshot.Count -gt 0) {
        [void]$builder.Append(($submoduleSnapshot -join "`n"))
    }
    [void]$builder.Append("`0")

    [System.IO.File]::WriteAllText($snapshotFile, $builder.ToString(), $utf8NoBom)
    $worktreeDigest = (Invoke-GitLines -Arguments @("hash-object", $snapshotFile) | Select-Object -First 1)

    $evidenceInput = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($evidenceInput, "$headCommit`n$worktreeDigest`n", $utf8NoBom)
        $evidenceId = (Invoke-GitLines -Arguments @("hash-object", $evidenceInput) | Select-Object -First 1)
    } finally {
        Remove-Item -LiteralPath $evidenceInput -Force -ErrorAction SilentlyContinue
    }

    $reusable = "true"
    $reason = "snapshot_stable"
    $unmerged = Invoke-GitLines -Arguments @("ls-files", "-u")

    if ($unmerged.Count -gt 0) {
        $reusable = "false"
        $reason = "unmerged_entries"
    } else {
        $indexVisibility = Invoke-GitLines -Arguments @("ls-files", "-v")
        if ($indexVisibility | Where-Object { $_ -match '^[a-zS]' }) {
            $reusable = "false"
            $reason = "index_visibility_flags"
        } else {
            $submoduleStatus = @(& git submodule status --recursive 2>$null)
            if ($LASTEXITCODE -ne 0 -or ($submoduleStatus | Where-Object { $_ -match '^[+\-U]' })) {
                $reusable = "false"
                $reason = "dirty_or_unavailable_submodule"
            } else {
                & git submodule foreach --quiet --recursive 'test -z "$(git status --porcelain --untracked-files=normal)"' *> $null
                if ($LASTEXITCODE -ne 0) {
                    $reusable = "false"
                    $reason = "dirty_or_unavailable_submodule"
                }
            }
        }
    }

    Write-SnapshotResult -Result "ok" -Head $headCommit -WorktreeDigest $worktreeDigest `
        -EvidenceId $evidenceId -Reusable $reusable -Reason $reason
} catch {
    Write-SnapshotResult -Result "error" -Head $(if ($headCommit) { $headCommit } else { "UNKNOWN" }) `
        -WorktreeDigest "UNKNOWN" -EvidenceId "UNKNOWN" -Reusable "false" -Reason "snapshot_failed"
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
} finally {
    Remove-Item -LiteralPath $snapshotFile -Force -ErrorAction SilentlyContinue
    Pop-Location
}
