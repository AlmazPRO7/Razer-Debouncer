Param(
  [string]$Main = 'main',
  [string]$Feature,
  [switch]$Push,
  [switch]$NoTests
)

$ErrorActionPreference = 'Stop'

# Default feature = current branch
if (-not $Feature) {
  $Feature = (& git rev-parse --abbrev-ref HEAD).Trim()
}
if (-not $Feature -or -not $Main) {
  Write-Error 'Provide -Main and/or -Feature'
  exit 2
}

Write-Host "[auto-merge] main=$Main; feature=$Feature; push=$Push; tests=$NoTests"

Push-Location (Split-Path -Parent $PSScriptRoot) | Out-Null
try {
  # Autostash if dirty
  $didStash = $false
  $dirty = (& git diff-index --quiet HEAD --) -ne $null
  $untracked = (& git ls-files --others --exclude-standard) -ne $null
  if ($dirty -or $untracked) {
    Write-Host "[auto-merge] Working tree not clean → autostash"
    & git stash push -u -m ("auto-merge autostash {0:yyyy-MM-ddTHH:mm:ssZ}" -f (Get-Date).ToUniversalTime()) | Out-Null
    $didStash = $true
  }

  try {
    Write-Host "[auto-merge] Fetching origin..."
    & git fetch origin --prune

    Write-Host "[auto-merge] Updating main ($Main)"
    & git checkout $Main
    & git pull --rebase

    Write-Host "[auto-merge] Rebasing feature ($Feature) onto $Main"
    & git checkout $Feature
    & git rebase $Main

    if (-not $NoTests -and (Test-Path "$PSScriptRoot/dev_test.ps1")) {
      Write-Host "[auto-merge] Running tests..."
      & "$PSScriptRoot/dev_test.ps1"
    } else {
      Write-Host "[auto-merge] Tests skipped"
    }

    Write-Host "[auto-merge] Fast-forwarding $Main to $Feature"
    & git checkout $Main
    & git merge --ff-only $Feature

    if ($Push) {
      Write-Host "[auto-merge] Pushing $Main to origin"
      & git push origin $Main
      Write-Host "[auto-merge] Pushing $Feature to origin"
      & git push --force-with-lease origin $Feature
    }
  } finally {
    if ($didStash) {
      Write-Host "[auto-merge] Restoring autostash"
      & git stash pop -q
    }
  }
  Write-Host "[auto-merge] Done"
} finally {
  Pop-Location | Out-Null
}

