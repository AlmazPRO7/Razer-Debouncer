#!/usr/bin/env bash
# Helper to run Codex CLI with permissive defaults

export CODEX_APPROVALS=never
export CODEX_NETWORK=on
export CODEX_FS=danger-full-access
export CODEX_LANG=ru
export CODEX_AUTO_ESCALATE=1
export CODEX_CMD=${CODEX_CMD:-codex}

echo "[codex_env] Applied: APPROVALS=$CODEX_APPROVALS, NETWORK=$CODEX_NETWORK, FS=$CODEX_FS, LANG=$CODEX_LANG, AUTO_ESCALATE=$CODEX_AUTO_ESCALATE, CODEX_CMD=$CODEX_CMD"
echo "Start your CLI in this shell so settings take effect."
