#!/usr/bin/env bash
set -euo pipefail

# Local auto-merge helper (no GitHub Actions).
# Rebase feature onto main, fast-forward main, optional push.
#
# Usage examples:
#   ./scripts/auto_merge.sh                 # use current branch as feature, main=main, run tests, no push
#   ./scripts/auto_merge.sh --push          # same, but push main (+feature) to origin
#   ./scripts/auto_merge.sh --feature my-branch --main develop --no-tests --push

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

MAIN="main"
FEATURE="$(git rev-parse --abbrev-ref HEAD)"
PUSH=0
RUN_TESTS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --main) MAIN="$2"; shift 2 ;;
    --feature) FEATURE="$2"; shift 2 ;;
    --push) PUSH=1; shift ;;
    --no-push) PUSH=0; shift ;;
    --no-tests) RUN_TESTS=0; shift ;;
    -h|--help)
      echo "Local auto-merge: rebase feature onto main, fast-forward main, optional push"
      echo "Options: --main <name> --feature <name> [--push|--no-push] [--no-tests]"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$FEATURE" || -z "$MAIN" ]]; then
  echo "Both --feature and --main must be set" >&2
  exit 2
fi

echo "[auto-merge] main=$MAIN; feature=$FEATURE; push=$PUSH; tests=$RUN_TESTS"

# Ensure we are in a git repo
git rev-parse --git-dir >/dev/null 2>&1

# Autostash if dirty
DID_STASH=0
if ! git diff-index --quiet HEAD -- 2>/dev/null || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  echo "[auto-merge] Working tree not clean → autostash"
  git stash push -u -m "auto-merge autostash $(date -u +%FT%TZ)" >/dev/null
  DID_STASH=1
fi

cleanup() {
  local code=$?
  if [[ $DID_STASH -eq 1 ]]; then
    echo "[auto-merge] Restoring autostash"
    git stash pop -q || true
  fi
  exit $code
}
trap cleanup EXIT

echo "[auto-merge] Fetching origin..."
git fetch origin --prune

echo "[auto-merge] Updating main ($MAIN)"
git checkout "$MAIN"
git pull --rebase

echo "[auto-merge] Rebasing feature ($FEATURE) onto $MAIN"
git checkout "$FEATURE"
git rebase "$MAIN"

if [[ $RUN_TESTS -eq 1 && -x "$HERE/dev_test.sh" ]]; then
  echo "[auto-merge] Running tests..."
  "$HERE/dev_test.sh" || { echo "[auto-merge] Tests failed" >&2; exit 1; }
else
  echo "[auto-merge] Tests skipped"
fi

echo "[auto-merge] Fast-forwarding $MAIN to $FEATURE"
git checkout "$MAIN"
git merge --ff-only "$FEATURE"

if [[ $PUSH -eq 1 ]]; then
  echo "[auto-merge] Pushing $MAIN to origin"
  git push origin "$MAIN"
  # Push feature as well to share rebased history
  echo "[auto-merge] Pushing $FEATURE to origin"
  git push --force-with-lease origin "$FEATURE"
fi

echo "[auto-merge] Done"

