#!/usr/bin/env bash
set -euo pipefail

# Auto-sync repo after task completion.
# - Stages and commits changes if any
# - Rebases on origin/<main> and pushes
# - If on feature branch, uses local auto_merge to ff-merge main and push
#
# Env vars:
#   GIT_MAIN               name of main branch (default: main)
#   COMMIT_MESSAGE_PREFIX  prefix for commit message (default: chore: auto-sync)
#   NO_PUSH                if set to 1, do not push

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

MAIN_BRANCH="${GIT_MAIN:-main}"
PREFIX="${COMMIT_MESSAGE_PREFIX:-chore: auto-sync}"

# Ensure repo
git rev-parse --git-dir >/dev/null 2>&1 || { echo "[auto-sync] not a git repo" >&2; exit 2; }

# Stage all changes
git add -A

# Make a commit if there are staged changes
if ! git diff --cached --quiet; then
  TS="$(date -u +%FT%TZ)"
  MSG="$PREFIX by Codex CLI ($TS)"
  if [[ -n "${CODEX_TASK_SUMMARY:-}" ]]; then
    MSG+=" — ${CODEX_TASK_SUMMARY}"
  fi
  git commit -m "$MSG"
  echo "[auto-sync] committed: $MSG"
else
  echo "[auto-sync] no staged changes to commit"
fi

# Nothing to push? we still ensure we rebase/push if commits exist locally
BR="$(git rev-parse --abbrev-ref HEAD)"
export GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-"ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"}

# Ensure origin remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
  if [[ -n "${GITHUB_SSH_URL:-}" ]] && [[ -x "$HERE/git_remote_setup.sh" ]]; then
    echo "[auto-sync] setting up origin from GITHUB_SSH_URL=$GITHUB_SSH_URL"
    GITHUB_SSH_URL="$GITHUB_SSH_URL" "$HERE/git_remote_setup.sh"
  else
    echo "[auto-sync] remote 'origin' not set; set GITHUB_SSH_URL env and rerun to auto-configure" >&2
  fi
fi

echo "[auto-sync] fetching origin..."
git fetch origin --prune || { echo "[auto-sync] fetch failed (origin missing?)" >&2; exit 0; }

# If current branch tracks origin, rebase
UPSTREAM="origin/${BR}"
if git show-ref --verify --quiet "refs/remotes/${UPSTREAM}"; then
  echo "[auto-sync] pull --rebase for $BR"
  git pull --rebase origin "$BR" || true
fi

if [[ "${NO_PUSH:-0}" != "1" ]]; then
  if [[ "$BR" == "$MAIN_BRANCH" ]]; then
    echo "[auto-sync] pushing $BR"
    git push origin "$BR"
  else
    # Use local auto-merge helper to ff main and push both branches
    if [[ -x "$HERE/auto_merge.sh" ]]; then
      echo "[auto-sync] feature branch detected ($BR) → auto-merge to $MAIN_BRANCH with push"
      "$HERE/auto_merge.sh" --main "$MAIN_BRANCH" --feature "$BR" --no-tests --push
    else
      echo "[auto-sync] auto_merge.sh not found, pushing current branch"
      git push --force-with-lease origin "$BR"
    fi
  fi
else
  echo "[auto-sync] NO_PUSH=1 → skip push"
fi

echo "[auto-sync] done"
