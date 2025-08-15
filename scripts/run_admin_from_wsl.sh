#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WIN_ROOT=$(wslpath -w "$PROJECT_ROOT")

# Usage:
#   ./scripts/run_admin_from_wsl.sh --setup
#   ./scripts/run_admin_from_wsl.sh --build
#   ./scripts/run_admin_from_wsl.sh --build-na
#   ./scripts/run_admin_from_wsl.sh -- --debug --no-startup

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 [--setup|--build|-- <args to bw3_debounce3.py>]" >&2
  exit 1
fi

PS=powershell.exe
PSFLAGS=(-NoProfile -ExecutionPolicy Bypass)

case "${1:-}" in
  --setup)
    "$PS" "${PSFLAGS[@]}" -File "$WIN_ROOT\\scripts\\run_admin.ps1" -Setup
    ;;
  --build)
    "$PS" "${PSFLAGS[@]}" -File "$WIN_ROOT\\scripts\\run_admin.ps1" -Build
    ;;
  --build-na)
    "$PS" "${PSFLAGS[@]}" -File "$WIN_ROOT\\scripts\\run_admin.ps1" -BuildNoAdmin
    ;;
  --)
    shift
    if [[ $# -gt 0 ]]; then
      "$PS" "${PSFLAGS[@]}" -File "$WIN_ROOT\\scripts\\run_admin.ps1" -- @args $*
    else
      "$PS" "${PSFLAGS[@]}" -File "$WIN_ROOT\\scripts\\run_admin.ps1"
    fi
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
esac
