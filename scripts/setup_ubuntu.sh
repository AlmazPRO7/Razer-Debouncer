#!/usr/bin/env bash
set -euo pipefail
# Ubuntu setup for Python 3.11 + dev/test deps
# Usage:
#   ./scripts/setup_ubuntu.sh [--no-sudo] [--no-apt] [--gui]
#
# - Installs python3.11, python3.11-venv (and optionally GUI deps for pystray)
# - Creates .venv (Python 3.11) and installs requirements

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

SUDO=${SUDO:-sudo}
USE_SUDO=1
RUN_APT=1
INSTALL_GUI=0
for a in "$@"; do
  case "$a" in
    --no-sudo) USE_SUDO=0 ;;
    --no-apt) RUN_APT=0 ;;
    --gui) INSTALL_GUI=1 ;;
    *) echo "Unknown arg: $a" >&2; exit 2 ;;
  esac
done
if [[ $USE_SUDO -eq 0 ]]; then SUDO=""; fi

echo "[info] Preparing Ubuntu for Python 3.11 (apt: $RUN_APT, gui: $INSTALL_GUI)"

if [[ $RUN_APT -eq 1 ]]; then
  if command -v lsb_release >/dev/null 2>&1; then
    REL="$(lsb_release -rs || true)"
  else
    REL=""
  fi
  echo "[info] Detected Ubuntu release: ${REL:-unknown}"

  $SUDO apt-get update -y
  $SUDO apt-get install -y software-properties-common curl ca-certificates

  # Python 3.11 availability: for 22.04/20.04 add deadsnakes PPA
  NEED_PPA=0
  case "${REL}" in
    22.04|20.04) NEED_PPA=1 ;;
    *) NEED_PPA=0 ;;
  esac
  if [[ $NEED_PPA -eq 1 ]]; then
    echo "[info] Adding deadsnakes PPA for python3.11"
    $SUDO add-apt-repository -y ppa:deadsnakes/ppa
    $SUDO apt-get update -y
  fi

  $SUDO apt-get install -y \
    python3.11 python3.11-venv python3.11-distutils \
    python3-pip git build-essential

  if [[ $INSTALL_GUI -eq 1 ]]; then
    # Optional: GTK deps for pystray on Linux desktops
    $SUDO apt-get install -y python3-gi gir1.2-gtk-3.0 libgirepository1.0-dev
  fi
fi

PY311="$(command -v python3.11 || true)"
if [[ -z "$PY311" ]]; then
  echo "[error] python3.11 not found in PATH. Rerun with apt enabled or install manually." >&2
  exit 1
fi

echo "[info] Using python: $PY311"

# Create venv with Python 3.11
if [[ ! -d .venv ]]; then
  "$PY311" -m venv .venv
fi
source .venv/bin/activate
python -m pip install --upgrade pip wheel setuptools

# Install runtime + dev deps
if [[ -f requirements.txt ]]; then
  pip install -r requirements.txt
fi
if [[ -f requirements-dev.txt ]]; then
  pip install -r requirements-dev.txt
fi

echo "[ok] Environment ready. Activate with: source .venv/bin/activate"
echo "[ok] Quick check: pytest -q (optional) or ./scripts/dev_test.sh"

