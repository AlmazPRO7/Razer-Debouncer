Param()
$ErrorActionPreference = 'Stop'

function Get-GitRoot {
  $p = & git rev-parse --show-toplevel 2>$null
  if (-not $?) { throw "Not a git repository" }
  return $p.Trim()
}

$root = Get-GitRoot
Set-Location $root
$hooks = & git rev-parse --git-path hooks
if (-not (Test-Path $hooks)) { New-Item -ItemType Directory -Path $hooks | Out-Null }

$pre = @'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
if command -v python3 >/dev/null 2>&1; then
  python3 scripts/docs_autoupdate.py || true
  python3 scripts/docs_check.py || { echo "[pre-commit] docs_check failed — обновите документацию" >&2; exit 1; }
  git add docs/CLI_FLAGS.md || true
fi
'@
Set-Content -Path (Join-Path $hooks 'pre-commit') -Value $pre -Encoding UTF8
& git update-index --chmod=+x (Join-Path $hooks 'pre-commit') | Out-Null

$postCommit = @'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
NO_PUSH=${NO_PUSH:-0} scripts/git_auto_sync.sh || true
'@
Set-Content -Path (Join-Path $hooks 'post-commit') -Value $postCommit -Encoding UTF8
& git update-index --chmod=+x (Join-Path $hooks 'post-commit') | Out-Null

$postMerge = @'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
if command -v python3 >/dev/null 2>&1; then
  python3 scripts/docs_autoupdate.py || true
  git add docs/CLI_FLAGS.md || true
fi
'@
Set-Content -Path (Join-Path $hooks 'post-merge') -Value $postMerge -Encoding UTF8
& git update-index --chmod=+x (Join-Path $hooks 'post-merge') | Out-Null

Write-Host "Installed git hooks into $hooks"

