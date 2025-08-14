Param(
  [string]$KeyPath
)

# Git over SSH using a specific key and strict options.
# If -KeyPath not provided, default to workspace key.

$Root = Split-Path -Parent $PSScriptRoot
$DefaultKey = Join-Path $Root '.secrets/ssh/id_ed25519'
if (-not $KeyPath) { $KeyPath = $DefaultKey }

if (-not (Test-Path $KeyPath)) {
  Write-Error "Key file not found: $KeyPath"
  Write-Host "Generate one or pass -KeyPath C:\\Users\\You\\.ssh\\id_ed25519"
  exit 1
}

$env:GIT_SSH_COMMAND = "ssh -i `"$KeyPath`" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
Write-Host "GIT_SSH_COMMAND set → using: $KeyPath"
Write-Host "Use your normal git commands in this session."
