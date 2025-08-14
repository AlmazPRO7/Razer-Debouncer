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
    $cmd = $env:CODEX_CMD; if (-not $cmd) { $cmd = 'codex' }
    # Попробуем вызвать дефолтную команду с --project .
    $ArgsRest = @($cmd, '--project', '.')
  }

  if (-not $env:AFTER_SUCCESS_CMD) {
    $env:AFTER_SUCCESS_CMD = (Join-Path $PSScriptRoot 'git_auto_sync.ps1')
  }

  & (Join-Path $PSScriptRoot 'auto_run.ps1') @ArgsRest
  exit $LASTEXITCODE
} finally {
  Pop-Location | Out-Null
}
