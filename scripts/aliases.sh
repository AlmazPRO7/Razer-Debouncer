#!/usr/bin/env bash
# Common aliases/functions for Codex workflow (source this file)

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default Codex command
export CODEX_CMD=${CODEX_CMD:-codex}

cx() {
  "$HERE/codex_run.sh" "$CODEX_CMD" "$@"
}

gsync() {
  "$HERE/git_auto_sync.sh" "$@"
}

amerge() {
  "$HERE/auto_merge.sh" "$@"
}

devrun() {
  "$HERE/dev_run.sh" "$@"
}

devtest() {
  "$HERE/dev_test.sh" "$@"
}

echo "[aliases] Доступны команды: cx, gsync, amerge, devrun, devtest (CODEX_CMD=$CODEX_CMD)"

