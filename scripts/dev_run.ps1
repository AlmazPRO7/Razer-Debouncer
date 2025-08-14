Param(
  [switch]$Debug,
  [switch]$NoStartup,
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$ArgsRest
)

# Run bw3_debounce3.py with sensible defaults for dev
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { Write-Error "Python not found in PATH"; exit 1 }

$argsList = @()
if ($Debug)    { $argsList += '--debug' }
if ($NoStartup){ $argsList += '--no-startup' } else { $argsList += '--no-startup' } # default off in dev
$argsList += $ArgsRest

Write-Host "Launching with: $($argsList -join ' ')"
& $py.Path bw3_debounce3.py @argsList

