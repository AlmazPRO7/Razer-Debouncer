#!/usr/bin/env bash
# Git over SSH using a specific key and strict options.
# If SSH_KEY_PATH env not set, use workspace key by default.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

DEFAULT_KEY="$ROOT/.secrets/ssh/id_ed25519"
SSH_KEY_PATH="${SSH_KEY_PATH:-$DEFAULT_KEY}"

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "Key file not found: $SSH_KEY_PATH" >&2
  echo "Run key generation or pass SSH_KEY_PATH=/path/to/key $0" >&2
  exit 1
fi

# Accept new host keys automatically; prefer IdentitiesOnly to avoid agent confusion.
export GIT_SSH_COMMAND="ssh -i '$SSH_KEY_PATH' -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
echo "GIT_SSH_COMMAND set → using: $SSH_KEY_PATH"
echo "Use your normal git commands now (git pull/push)."
