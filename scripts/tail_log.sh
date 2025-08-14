#!/usr/bin/env bash
set -euo pipefail

# Try resolve bw3_chatter.log path automatically (WSL)
guess() {
  if [[ -n "${APPDATA:-}" ]] && [[ -f "$APPDATA/bw3_chatter.log" ]]; then
    printf '%s' "$APPDATA/bw3_chatter.log"
    return
  fi
  latest=""; newest=0
  for p in /mnt/c/Users/*/AppData/Roaming/bw3_chatter.log; do
    [[ -e "$p" ]] || continue
    m=$(stat -c %Y "$p" 2>/dev/null || echo 0)
    if (( m > newest )); then newest=$m; latest="$p"; fi
  done
  printf '%s' "$latest"
}

LOG_PATH=${1:-}
if [[ -z "$LOG_PATH" ]]; then
  LOG_PATH=$(guess)
fi

if [[ -z "$LOG_PATH" ]] || [[ ! -f "$LOG_PATH" ]]; then
  echo "Не удалось найти bw3_chatter.log. Укажите путь явно: scripts/tail_log.sh /mnt/c/Users/YOU/AppData/Roaming/bw3_chatter.log" >&2
  exit 2
fi

echo "Tailing: $LOG_PATH"
exec tail -f "$LOG_PATH"

