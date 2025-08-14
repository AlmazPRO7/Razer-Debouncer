param(
  [Parameter(Mandatory=$true)][string]$Source,
  [Parameter(Mandatory=$true)][string]$Target
)

if (-not (Test-Path $Source)) { Write-Error "Source not found: $Source"; exit 1 }
if (-not (Test-Path $Target)) { Write-Error "Target not found: $Target"; exit 1 }

Write-Host "Applying payload from: $Source" -ForegroundColor Cyan
Write-Host "Into repo: $Target" -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'

function Copy-ItemSafe([string]$RelPath) {
  $src = Join-Path $Source $RelPath
  $dst = Join-Path $Target $RelPath
  $dstDir = Split-Path -Parent $dst
  if (-not (Test-Path $src)) { Write-Error "Missing in payload: $RelPath"; return }
  if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
  Copy-Item -Path $src -Destination $dst -Force
  Write-Host "Updated: $RelPath"
}

# List of files included in payload
$files = @(
  'bw3_debounce3.py',
  'README.md',
  'docs/CHANGELOG.md',
  'scripts/run_windows_debug.ps1'
)

foreach ($f in $files) { Copy-ItemSafe $f }

Write-Host "Done. Review changes, then: git add -A; git commit -m 'Apply offline payload'; git push" -ForegroundColor Green

