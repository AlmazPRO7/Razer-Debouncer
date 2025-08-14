Param(
  [string]$RepoSshUrl
)

# Configure git remote 'origin' to SSH URL
# Usage: .\scripts\git_remote_setup.ps1 -RepoSshUrl git@github.com:USER/REPO.git

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not $RepoSshUrl) {
  Write-Host "Provide -RepoSshUrl git@github.com:USER/REPO.git"
  exit 1
}

$existing = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
  git remote set-url origin $RepoSshUrl
} else {
  git remote add origin $RepoSshUrl
}
git remote -v

