param(
  [string]$RepoPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [switch]$SetDefaultProfile
)

$ErrorActionPreference = 'Stop'

function Get-WTSettingsPath {
  $candidates = @(
    Join-Path $env:LOCALAPPDATA 'Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'),
    Join-Path $env:LOCALAPPDATA 'Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json'
  foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
  return $null
}

function Ensure-WTProfile([string]$SettingsPath, [string]$RepoPath, [switch]$SetDefault) {
  $json = $null
  try {
    $json = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json -ErrorAction Stop
  } catch {
    $json = [ordered]@{ profiles = [ordered]@{ list = @() } }
  }

  if (-not $json.profiles) { $json | Add-Member -Name profiles -Value ([ordered]@{ list = @() }) -MemberType NoteProperty }
  if (-not $json.profiles.list) { $json.profiles | Add-Member -Name list -Value (@()) -MemberType NoteProperty }

  $name = 'Razer Debounce (Codex)'
  $guid = '{' + ([guid]::NewGuid().Guid) + '}'
  $existing = $null
  foreach ($p in $json.profiles.list) { if ($p.name -eq $name) { $existing = $p; break } }

  $cmd = "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$RepoPath\scripts\open_dev.ps1`""

  if ($existing) {
    $existing.commandline = $cmd
    $existing.startingDirectory = $RepoPath
  } else {
    $profile = [ordered]@{
      name = $name
      commandline = $cmd
      startingDirectory = $RepoPath
      hidden = $false
    }
    $json.profiles.list += (New-Object psobject -Property $profile)
    $existing = $profile
  }

  if ($SetDefault.IsPresent) {
    if (-not $json.defaultProfile -and $existing.guid) {
      $json.defaultProfile = $existing.guid
    }
  }

  $json | ConvertTo-Json -Depth 100 | Set-Content -Path $SettingsPath -Encoding UTF8
  Write-Host "[install] Windows Terminal profile обновлён: $SettingsPath" -ForegroundColor Green
}

function Create-DesktopShortcut([string]$RepoPath) {
  $desktop = [Environment]::GetFolderPath('Desktop')
  $lnk = Join-Path $desktop 'Razer Debounce (Codex).lnk'
  $ws = New-Object -ComObject WScript.Shell
  $sc = $ws.CreateShortcut($lnk)
  $sc.TargetPath = 'powershell.exe'
  $sc.Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$RepoPath\scripts\open_dev.ps1`""
  $sc.WorkingDirectory = $RepoPath
  $sc.WindowStyle = 1
  $sc.IconLocation = "$env:SystemRoot\\System32\\imageres.dll,64"
  $sc.Save()
  Write-Host "[install] Ярлык создан: $lnk" -ForegroundColor Green
}

if (-not (Test-Path (Join-Path $RepoPath 'scripts/open_dev.ps1'))) {
  Write-Error "Неверный RepoPath: $RepoPath"
  exit 2
}

$wt = Get-WTSettingsPath
if ($wt) { Ensure-WTProfile -SettingsPath $wt -RepoPath $RepoPath -SetDefault:$SetDefaultProfile } else { Write-Warning 'Windows Terminal не найден. Пропускаю настройку профиля.' }

Create-DesktopShortcut -RepoPath $RepoPath

Write-Host "[install] Готово: Windows окружение настроено (профиль WT/ярлык)." -ForegroundColor Green

