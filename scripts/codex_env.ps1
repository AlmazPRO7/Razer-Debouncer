# Helper to run Codex CLI with permissive defaults (PowerShell)

$env:CODEX_APPROVALS = "never"
$env:CODEX_NETWORK   = "on"
$env:CODEX_FS        = "danger-full-access"
$env:CODEX_LANG      = "ru"
$env:CODEX_AUTO_ESCALATE = "1"

Write-Host "[codex_env] Applied: APPROVALS=$($env:CODEX_APPROVALS), NETWORK=$($env:CODEX_NETWORK), FS=$($env:CODEX_FS), LANG=$($env:CODEX_LANG), AUTO_ESCALATE=$($env:CODEX_AUTO_ESCALATE)" -ForegroundColor Green
Write-Host "Start Codex CLI in this PowerShell so settings take effect." -ForegroundColor Yellow
