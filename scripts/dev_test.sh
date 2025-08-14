#!/usr/bin/env bash
set -euo pipefail
# Quick self-test (no Windows hook) for bw3_debounce3.py
# Usage: ./scripts/dev_test.sh [extra-args]

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

cd "$ROOT"

if command -v python >/dev/null 2>&1; then
  PY=python
elif command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v py >/dev/null 2>&1; then
  PY=py
else
  echo "Python not found in PATH" >&2
  exit 1
fi

exec "$PY" bw3_debounce3.py --selftest "$@"
