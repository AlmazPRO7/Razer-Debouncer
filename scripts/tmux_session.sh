#!/usr/bin/env bash
set -euo pipefail

# Создаёт tmux-сессию с 2 панелями: слева Codex (cx), справа обычный шелл.
# Usage: ./scripts/tmux_session.sh [session_name]

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SESSION="${1:-razer_debounce}"

cd "$ROOT"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux не найден. Установите tmux." >&2
  exit 2
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Подключение к существующей сессии: $SESSION"
  exec tmux attach -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -c "$ROOT" \
  "bash -lc 'source scripts/codex_env.sh && source scripts/aliases.sh && cx --project .'"

# верт. сплит с обычным шеллом
tmux split-window -h -t "$SESSION:0.0" -c "$ROOT" \
  "bash -lc 'source scripts/codex_env.sh && source scripts/aliases.sh; exec bash'"

tmux select-pane -t "$SESSION:0.0"
tmux attach -t "$SESSION"

