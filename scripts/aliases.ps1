param(
  [string]$CodexCmd = 'codex'
)

$script:Here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $env:CODEX_CMD) { $env:CODEX_CMD = $CodexCmd }

Set-Alias cx (Join-Path $script:Here 'codex_run.ps1')
Set-Alias gsync (Join-Path $script:Here 'git_auto_sync.ps1')
Set-Alias amerge (Join-Path $script:Here 'auto_merge.ps1')
Set-Alias devrun (Join-Path $script:Here 'dev_run.ps1')
Set-Alias devtest (Join-Path $script:Here 'dev_test.ps1')

Write-Host "[aliases] Доступны команды: cx, gsync, amerge, devrun, devtest (CODEX_CMD=$($env:CODEX_CMD))" -ForegroundColor Green

