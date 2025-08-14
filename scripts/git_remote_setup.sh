#!/usr/bin/env bash
set -euo pipefail

# Configure git remote 'origin' to SSH URL
# Usage: GITHUB_SSH_URL=git@github.com:USER/REPO.git ./scripts/git_remote_setup.sh

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

if [ -z "${GITHUB_SSH_URL:-}" ]; then
  echo "Set GITHUB_SSH_URL, e.g. git@github.com:USER/REPO.git" >&2
  exit 1
fi

git remote get-url origin >/dev/null 2>&1 && git remote set-url origin "$GITHUB_SSH_URL" || git remote add origin "$GITHUB_SSH_URL"
git remote -v

