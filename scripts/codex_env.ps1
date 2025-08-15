# Helper to run Codex CLI with permissive defaults (PowerShell)

$env:CODEX_APPROVALS = "never"
$env:CODEX_NETWORK   = "on"
$env:CODEX_FS        = "danger-full-access"
$env:CODEX_LANG      = "ru"
$env:CODEX_AUTO_ESCALATE = "1"
if (-not $env:CODEX_CMD) { $env:CODEX_CMD = "codex" }

# Гарантируем корректный UTF-8 в PowerShell/консоли (кириллица и специальные символы)
try {
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
  [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding $false
} catch {}
try { chcp 65001 | Out-Null } catch {}
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:LESSCHARSET = 'utf-8'
if (-not $env:GIT_PAGER) { $env:GIT_PAGER = 'less -R' }

Write-Host "[codex_env] Applied: APPROVALS=$($env:CODEX_APPROVALS), NETWORK=$($env:CODEX_NETWORK), FS=$($env:CODEX_FS), LANG=$($env:CODEX_LANG), AUTO_ESCALATE=$($env:CODEX_AUTO_ESCALATE), CODEX_CMD=$($env:CODEX_CMD)" -ForegroundColor Green
Write-Host "[codex_env] UTF-8 enabled for console and Python (chcp 65001)" -ForegroundColor Green
Write-Host "Start Codex CLI in this PowerShell so settings take effect." -ForegroundColor Yellow
