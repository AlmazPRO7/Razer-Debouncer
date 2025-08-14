#!/usr/bin/env bash
set -euo pipefail
# Check SSH connectivity to GitHub with a given key
# Usage: SSH_KEY_PATH=~/.ssh/id_ed25519 ./scripts/ssh_check.sh

if [ -z "${SSH_KEY_PATH:-}" ]; then
  echo "Set SSH_KEY_PATH to your private key" >&2
  exit 1
fi

ssh -i "$SSH_KEY_PATH" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -T git@github.com || true

