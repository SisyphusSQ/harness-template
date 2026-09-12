$ErrorActionPreference = "Stop"
$script = Join-Path $PSScriptRoot "verify_harness_source.py"
if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 $script
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    & python3 $script
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python $script
} else {
    throw "Python 3.10+ is required."
}
exit $LASTEXITCODE
