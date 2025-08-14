param(
  [string]$RepoPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

# Открывает Windows Terminal с 2 панелями: слева — Codex (cx), справа — обычный шелл с окружением.

$ErrorActionPreference = 'Stop'

if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
  Write-Error 'Не найден wt.exe (Windows Terminal). Установите Windows Terminal из Microsoft Store.'
  exit 2
}

$envCmd = ". `"$($RepoPath)\scripts\codex_env.ps1`"; . `"$($RepoPath)\scripts\aliases.ps1`";"
$codexCmd = "$envCmd cx --project ."
$shellCmd = "$envCmd powershell"

# -d задаёт рабочую директорию панели.
$args = @(
  '-w', 'razer_debounce',
  '-d', $RepoPath, 'powershell', '-NoExit', '-NoLogo', '-NoProfile', '-Command', $codexCmd,
  ';', 'split-pane', '-H', '-d', $RepoPath, 'powershell', '-NoExit', '-NoLogo', '-NoProfile', '-Command', $shellCmd
)

Start-Process wt.exe -ArgumentList $args

