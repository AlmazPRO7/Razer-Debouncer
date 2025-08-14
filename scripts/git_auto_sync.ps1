param(
  [string]$Main = 'main',
  [switch]$NoPush
)

$ErrorActionPreference = 'Stop'

Push-Location (Split-Path -Parent $PSScriptRoot) | Out-Null
try {
  # Ensure repo
  git rev-parse --git-dir *> $null

  # Stage all
  git add -A

  # Commit if needed
  $hasStaged = -not (& git diff --cached --quiet $null 2>$null; $?)
  if ($hasStaged) {
    $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $prefix = $env:COMMIT_MESSAGE_PREFIX
    if (-not $prefix) { $prefix = 'chore: auto-sync' }
    $msg = "$prefix by Codex CLI ($ts)"
    if ($env:CODEX_TASK_SUMMARY) { $msg = "$msg — $($env:CODEX_TASK_SUMMARY)" }
    git commit -m "$msg"
    Write-Host "[auto-sync] committed: $msg"
  } else {
    Write-Host "[auto-sync] no staged changes to commit"
  }

  $br = (& git rev-parse --abbrev-ref HEAD).Trim()

  Write-Host "[auto-sync] fetching origin..."
  git fetch origin --prune

  # Rebase on origin/<branch> if present
  $upstream = "origin/$br"
  $exists = (& git show-ref --verify --quiet "refs/remotes/$upstream"; $?) -eq $true
  if ($exists) {
    Write-Host "[auto-sync] pull --rebase for $br"
    git pull --rebase origin $br | Out-Null
  }

  if (-not $NoPush) {
    if ($br -eq $Main) {
      Write-Host "[auto-sync] pushing $br"
      git push origin $br
    } else {
      $am = Join-Path $PSScriptRoot 'auto_merge.ps1'
      if (Test-Path $am) {
        Write-Host "[auto-sync] feature branch detected ($br) → auto-merge to $Main with push"
        & $am -Main $Main -Feature $br -NoTests -Push
      } else {
        Write-Host "[auto-sync] auto_merge.ps1 not found, pushing branch"
        git push --force-with-lease origin $br
      }
    }
  } else {
    Write-Host "[auto-sync] NoPush → skip push"
  }

  Write-Host "[auto-sync] done"
} finally {
  Pop-Location | Out-Null
}

