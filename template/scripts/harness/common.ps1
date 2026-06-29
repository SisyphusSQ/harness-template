$Script:HarnessScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$Script:RepoRoot = (Resolve-Path (Join-Path $Script:HarnessScriptDir "..\..")).Path

function Get-TextLines {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "missing file: $Path"
    }

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Test-PlaceholderLine {
    param([Parameter(Mandatory=$true)][string]$Line)

    return (
        $Line -match '<请替换为真实[^>]*>' -or
        $Line -match '<路径 / 类型>' -or
        $Line -match '<新增/复用>' -or
        $Line -match '<任务名>' -or
        $Line -match '<todo-id>' -or
        $Line -match '\[待补充\]' -or
        $Line -match '\[请替换\]'
    )
}

function Get-SectionField {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Field
    )

    $lines = Get-TextLines -Path $Path
    $inSection = $false
    $pattern = '^\s*-\s*`?' + [regex]::Escape($Field) + '`?:\s*(.*)$'

    foreach ($line in $lines) {
        if ($line -eq $Section) {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^## ') {
            break
        }

        if ($inSection -and $line -match $pattern) {
            return $Matches[1]
        }
    }

    return ""
}

function Resolve-PlanImplementationSection {
    param([Parameter(Mandatory=$true)][string]$Path)

    $lines = Get-TextLines -Path $Path
    foreach ($candidate in @("## Architecture / Data Flow", "## 0. 现有架构回顾与核心设计决策")) {
        if ($lines -contains $candidate) {
            return $candidate
        }
    }

    return $null
}

function Test-MeaningfulLine {
    param([Parameter(Mandatory=$true)][string]$Line)

    $trimmed = $Line.Trim()
    if ($trimmed -eq "" -or $trimmed -match '^```' -or $trimmed -match '^<!--') {
        return $false
    }
    if ($trimmed -match '^[-*]\s*$' -or $trimmed -match '^[0-9]+\.\s*$') {
        return $false
    }
    if ($trimmed -match '^\|[ \t]*模块/类型[ \t]*\|[ \t]*新增/复用') {
        return $false
    }
    if ($trimmed -match '^\|([ \t]*:?-+:?[ \t]*\|)+$') {
        return $false
    }
    if (Test-PlaceholderLine -Line $trimmed) {
        return $false
    }

    return $true
}

function Test-SubsectionHasMeaningfulContent {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Subsection
    )

    $lines = Get-TextLines -Path $Path
    $inSection = $false
    $found = $false
    $inSubsection = $false
    $content = $false
    $bulletField = $Subsection -match '^-\s*'

    foreach ($line in $lines) {
        if ($line -eq $Section) {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^## ') {
            if ($inSubsection) { break }
            $inSection = $false
        }

        if ($inSection -and -not $bulletField -and $line -eq $Subsection) {
            $found = $true
            $inSubsection = $true
            continue
        }

        if ($inSection -and $bulletField) {
            $trimmed = $line.Trim()
            if (-not $inSubsection -and $trimmed.StartsWith($Subsection)) {
                $found = $true
                $inSubsection = $true
                $rest = $trimmed.Substring($Subsection.Length).Trim() -replace '^[：:]\s*', ''
                if ($rest -ne "" -and -not (Test-PlaceholderLine -Line $rest)) {
                    $content = $true
                }
                continue
            }

            if ($inSubsection -and $line -match '^-\s*`') {
                break
            }
        }

        if ($inSection -and $inSubsection -and $line -match '^### ') {
            break
        }

        if ($inSubsection -and (Test-MeaningfulLine -Line $line)) {
            $content = $true
        }
    }

    return ($found -and $content)
}

function Test-SectionHasMeaningfulContent {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Section
    )

    $lines = Get-TextLines -Path $Path
    $inSection = $false

    foreach ($line in $lines) {
        if ($line -eq $Section) {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^## ') {
            break
        }

        if ($inSection) {
            $trimmed = $line.Trim()
            if ($trimmed -eq "至少锁定一个与当前关键调用链直接相关的真实接口 / 结构 / 命令 / 配置片段，不要保留占位内容。") {
                continue
            }
            if ($trimmed -eq "至少锁定一个与当前关键调用链直接相关的真实接口 / 结构 / 命令 / 配置片段。复杂任务推荐放两段：一段锁定接口 / 结构，一段锁定规则 / 配置 / SQL / CLI。") {
                continue
            }
            if ($trimmed -match '^-\s*`片段说明`:\s*$') {
                continue
            }
            if (Test-MeaningfulLine -Line $line) {
                return $true
            }
        }
    }

    return $false
}

function Test-SubsectionHasRealTableEntry {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Subsection
    )

    $lines = Get-TextLines -Path $Path
    $inSection = $false
    $inSubsection = $false

    foreach ($line in $lines) {
        if ($line -eq $Section) {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^## ') {
            if ($inSubsection) { break }
            $inSection = $false
        }

        if ($inSection -and $line -eq $Subsection) {
            $inSubsection = $true
            continue
        }

        if ($inSection -and $inSubsection -and $line -match '^### ') {
            break
        }

        if ($inSubsection) {
            $trimmed = $line.Trim()
            if ($trimmed -eq "" -or
                $trimmed -match '^\|[ \t]*模块/类型[ \t]*\|[ \t]*新增/复用' -or
                $trimmed -match '^\|([ \t]*:?-+:?[ \t]*\|)+$') {
                continue
            }
            if ($trimmed -match '^\|' -and -not (Test-PlaceholderLine -Line $trimmed)) {
                return $true
            }
        }
    }

    return $false
}

function Get-PlanImplementationSkeletonErrors {
    param([Parameter(Mandatory=$true)][string]$Path)

    $errors = New-Object System.Collections.Generic.List[string]
    $implementationSection = Resolve-PlanImplementationSection -Path $Path

    if ([string]::IsNullOrEmpty($implementationSection)) {
        $errors.Add("missing implementation section: expected ## Architecture / Data Flow or ## 0. 现有架构回顾与核心设计决策")
    } else {
        foreach ($subsection in @(
            "### 真实入口与触发",
            "### 输入装配与边界校验",
            "### 组件职责与代码落点",
            "### 关键执行时序",
            "### 停止 / 错误 / 恢复"
        )) {
            if (-not (Test-SubsectionHasMeaningfulContent -Path $Path -Section $implementationSection -Subsection $subsection)) {
                $errors.Add("missing or placeholder-only subsection: $implementationSection / $subsection")
            }
        }

        foreach ($field in @(
            '- `入口代码位置`',
            '- `装配结果 / 核心对象`',
            '- `步骤化时序`',
            '- `关键分支 / 降级路径`'
        )) {
            if (-not (Test-SubsectionHasMeaningfulContent -Path $Path -Section $implementationSection -Subsection $field)) {
                $errors.Add("missing or placeholder-only field: $implementationSection / $field")
            }
        }

        if (-not (Test-SubsectionHasRealTableEntry -Path $Path -Section $implementationSection -Subsection "### 组件职责与代码落点")) {
            $errors.Add("missing real module/path/type entry: $implementationSection / ### 组件职责与代码落点")
        }
    }

    if (-not (Test-SubsectionHasMeaningfulContent -Path $Path -Section "## Concrete Steps" -Subsection "### 实现步骤")) {
        $errors.Add("missing or placeholder-only subsection: ## Concrete Steps / ### 实现步骤")
    }

    if (-not (Test-SectionHasMeaningfulContent -Path $Path -Section "## Reference Snippets")) {
        $errors.Add("missing or placeholder-only section: ## Reference Snippets")
    }

    return @($errors)
}
