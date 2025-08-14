Param(
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$ArgsRest
)

# Quick self-test (no Windows hook) for bw3_debounce3.py
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { Write-Error "Python not found in PATH"; exit 1 }

& $py.Path bw3_debounce3.py --selftest @ArgsRest

