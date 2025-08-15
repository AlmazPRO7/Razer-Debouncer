param(
  [string]$ConfigSource = $(Join-Path (Split-Path -Parent $PSScriptRoot) '.codex/config.yaml')
)

$ErrorActionPreference = 'Stop'

# Глобальная установка для Codex CLI: копирует конфиг в $HOME\.codex\config.yaml
# и добавляет переменные окружения в профиль PowerShell текущего пользователя.

$home = [Environment]::GetFolderPath('UserProfile')
$cfgDir = Join-Path $home '.codex'
$cfgDst = Join-Path $cfgDir 'config.yaml'
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null

if (Test-Path $ConfigSource) {
  Copy-Item -Force -Path $ConfigSource -Destination $cfgDst
} else {
  @"
# Global Codex CLI config
defaults:
  approvals: never
  language: ru
  auto_escalate: true
sandbox:
  filesystem: danger-full-access
  network: on
"@ | Set-Content -Path $cfgDst -Encoding UTF8
}

$profilePath = $PROFILE.CurrentUserCurrentHost
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $profilePath) | Out-Null
if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Force -Path $profilePath | Out-Null }

$start = '# BEGIN CODEX_GLOBAL'
$end   = '# END CODEX_GLOBAL'
$block = @"
# BEGIN CODEX_GLOBAL
# Глобальные переменные для Codex CLI (применяются во всех репозиториях)

$env:CODEX_APPROVALS = 'never'
$env:CODEX_NETWORK   = 'on'
$env:CODEX_FS        = 'danger-full-access'
$env:CODEX_LANG      = 'ru'
$env:CODEX_AUTO_ESCALATE = '1'
$env:CODEX_CONFIG    = "$cfgDst"

# END CODEX_GLOBAL
"@

$content = Get-Content -Raw -Path $profilePath
if ($content -match [regex]::Escape($start)) {
  $pattern = [regex]::Escape($start) + '[\s\S]*?' + [regex]::Escape($end)
  $new = [regex]::Replace($content, $pattern, $block)
  $new | Set-Content -Path $profilePath -Encoding UTF8
} else {
  Add-Content -Path $profilePath -Value "`n$block" -Encoding UTF8
}

Write-Host "[codex-global] Установлено: $cfgDst" -ForegroundColor Green
Write-Host "[codex-global] Профиль PowerShell обновлён: $profilePath" -ForegroundColor Green
Write-Host "[codex-global] Перезапустите PowerShell окно, чтобы переменные применились." -ForegroundColor Yellow

