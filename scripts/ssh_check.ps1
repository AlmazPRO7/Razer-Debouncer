Param(
  [string]$KeyPath
)

if (-not $KeyPath) {
  Write-Host "Usage: .\\scripts\\ssh_check.ps1 -KeyPath C:\\Users\\YOU\\.ssh\\id_ed25519"
  exit 1
}

ssh -i "$KeyPath" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -T git@github.com
if ($LASTEXITCODE -ne 0) { Write-Warning "Non-zero exit; if you see 'successfully authenticated' it's OK" }

