#!/usr/bin/env bash
set -euo pipefail

# Универсальный вход в окружение разработки под WSL/Linux.
# Предпочитает tmux; если tmux недоступен — запускает 2 терминала в i3/sway/gnome-terminal, либо fallback в один шелл.

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

if command -v tmux >/dev/null 2>&1; then
  exec "$HERE/tmux_session.sh"
fi

# Fallback: одно окно с окружением
if [[ -f "$HERE/codex_env.sh" ]]; then
  # shellcheck source=/dev/null
  . "$HERE/codex_env.sh"
fi
if [[ -f "$HERE/aliases.sh" ]]; then
  # shellcheck source=/dev/null
  . "$HERE/aliases.sh"
fi
echo "tmux не найден — запущена одиночная сессия. Рекомендуется установить tmux." >&2
exec bash

