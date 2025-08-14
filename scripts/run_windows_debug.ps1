param(
  [int]$Ms = 100,
  [int]$ModBounce = 30,
  [int]$RepeatJitter = 5,
  [switch]$NoStartup = $true,
  [string]$NoRateLimitVKs = ''
)

function Ensure-Admin {
  $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
  $wp = New-Object Security.Principal.WindowsPrincipal($wi)
  if (-not $wp.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host 'Re-launching as Administrator...'
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",
      '-Ms', $Ms, '-ModBounce', $ModBounce, '-RepeatJitter', $RepeatJitter)
    if ($NoStartup) { $args += '-NoStartup' }
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $args | Out-Null
    exit
  }
}

Ensure-Admin

Set-Location -Path (Split-Path -Parent $PSScriptRoot)
Set-Location -Path (Split-Path -Parent (Get-Location))
Write-Host "Working dir: $(Get-Location)"

$python = $null
try { $python = (Get-Command py -ErrorAction Stop).Source; $python = @($python,'-3') } catch {}
if (-not $python) { try { $python = (Get-Command python -ErrorAction Stop).Source } catch {} }
if (-not $python) { Write-Error 'Python not found in PATH. Install Python 3.x and retry.'; exit 1 }

Write-Host "Launching debounce with console logs..."
$args = @('bw3_debounce3.py','--debug','--ms',"$Ms",'--mod-bounce',"$ModBounce",'--repeat-jitter',"$RepeatJitter")
if ($NoStartup) { $args += '--no-startup' }
if ($NoRateLimitVKs -and $NoRateLimitVKs.Trim().Length -gt 0) {
  $args += @('--no-rate-limit-vks', $NoRateLimitVKs)
}

if ($python -is [array]) {
  & $python[0] $python[1] @args
} else {
  & $python @args
}
