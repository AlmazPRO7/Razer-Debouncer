param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ArgsRest
)

# Wrapper: запускает Codex CLI (или любую команду),
# а после успешного завершения выполняет git авто‑синхронизацию.

Push-Location (Split-Path -Parent $PSScriptRoot) | Out-Null
try {
  # Подхватить профиль окружения, если есть
  $envPath = Join-Path $PSScriptRoot 'codex_env.ps1'
  if (Test-Path $envPath) { . $envPath }

  if (-not $ArgsRest -or $ArgsRest.Count -eq 0) {
    Write-Error "Использование: scripts/codex_run.ps1 <команда Codex> [аргументы...]"
    Write-Host "Пример: scripts/codex_run.ps1 codex --project ."
    exit 2
  }

  if (-not $env:AFTER_SUCCESS_CMD) {
    $env:AFTER_SUCCESS_CMD = (Join-Path $PSScriptRoot 'git_auto_sync.ps1')
  }

  & (Join-Path $PSScriptRoot 'auto_run.ps1') @ArgsRest
  exit $LASTEXITCODE
} finally {
  Pop-Location | Out-Null
}

