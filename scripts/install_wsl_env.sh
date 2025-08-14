#!/usr/bin/env bash
set -euo pipefail

# Устанавливает автозапуск tmux-сессии Codex при входе в shell, если доступен tmux.
# Добавляет блоки в ~/.bashrc и ~/.zshrc (идемпотентно), использует абсолютный путь к репозиторию.

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

SNIPPET_START="# BEGIN RAZER_DEBOUNCE"
SNIPPET_END="# END RAZER_DEBOUNCE"
SNIPPET_CONTENT=$(cat <<EOF
$SNIPPET_START
# Автозапуск окружения Razer_Deboounce с tmux (идемпотентно). Установите DISABLE_RAZER_TMUX=1 чтобы отключить.
if [ -z "${DISABLE_RAZER_TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
  if [ -z "${TMUX:-}" ]; then
    if [ -f "$ROOT/scripts/codex_env.sh" ]; then . "$ROOT/scripts/codex_env.sh"; fi
    if [ -f "$ROOT/scripts/aliases.sh" ]; then . "$ROOT/scripts/aliases.sh"; fi
    # создаём/обновляем сессию и подключаемся
    tmux has-session -t razer_debounce 2>/dev/null || tmux new-session -d -s razer_debounce -c "$ROOT" "bash -lc 'source scripts/codex_env.sh && source scripts/aliases.sh && cx --project .'"
    exec tmux attach -t razer_debounce
  fi
fi
$SNIPPET_END
EOF
)

install_snippet() {
  local rcfile="$1"
  touch "$rcfile"
  if grep -q "$SNIPPET_START" "$rcfile"; then
    # replace existing block
    awk -v start="$SNIPPET_START" -v end="$SNIPPET_END" -v repl="$SNIPPET_CONTENT" '
      BEGIN{printed=0}
      {
        if ($0 ~ start) { inblock=1; if (!printed) { print repl; printed=1 } }
        else if ($0 ~ end) { inblock=0; next }
        else if (!inblock) { print }
      }' "$rcfile" >"$rcfile.tmp"
    mv "$rcfile.tmp" "$rcfile"
  else
    printf '\n%s\n' "$SNIPPET_CONTENT" >>"$rcfile"
  fi
}

install_snippet "$HOME/.bashrc"
install_snippet "$HOME/.zshrc"

echo "[install] Добавлены автозапусковые блоки в ~/.bashrc и ~/.zshrc (если они существуют)."
echo "[install] Готово: при следующем входе откроется tmux-сессия с Codex. Отключение: export DISABLE_RAZER_TMUX=1"

