param(
  [switch]$NoWT,
  [string]$RepoPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

function Start-WindowsTerminal {
  param([string]$Path)
  if ($NoWT) { return $false }
  if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) { return $false }

  $envCmd = ". `"$($Path)\scripts\codex_env.ps1`"; . `"$($Path)\scripts\aliases.ps1`";"
  $codexCmd = "$envCmd cx --project ."
  $shellCmd = "$envCmd powershell"

  $args = @(
    '-w', 'razer_debounce',
    '-d', $Path, 'powershell', '-NoExit', '-NoLogo', '-NoProfile', '-Command', $codexCmd,
    ';', 'split-pane', '-H', '-d', $Path, 'powershell', '-NoExit', '-NoLogo', '-NoProfile', '-Command', $shellCmd
  )
  Start-Process wt.exe -ArgumentList $args | Out-Null
  return $true
}

function Start-PowerShellTwoWindows {
  param([string]$Path)
  $envCmd = ". `"$($Path)\scripts\codex_env.ps1`"; . `"$($Path)\scripts\aliases.ps1`";"
  Start-Process powershell -ArgumentList @('-NoLogo','-NoProfile','-Command',"$envCmd cx --project .") | Out-Null
  Start-Process powershell -ArgumentList @('-NoLogo','-NoProfile','-Command',"$envCmd") | Out-Null
}

# Main
if (-not (Test-Path (Join-Path $RepoPath 'scripts/codex_env.ps1'))) {
  Write-Error "Некорректный путь RepoPath: $RepoPath"
  exit 2
}

if (-not (Start-WindowsTerminal -Path $RepoPath)) {
  Start-PowerShellTwoWindows -Path $RepoPath
}

Write-Host "Среда разработчика запущена." -ForegroundColor Green

