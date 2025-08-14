#!/usr/bin/env bash
set -euo pipefail

# Wrapper: запускает Codex CLI (или любую команду),
# а после успешного завершения выполняет git авто‑синхронизацию.

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

# Загрузить профиль окружения Codex (если есть)
if [[ -f "$HERE/codex_env.sh" ]]; then
  # shellcheck source=/dev/null
  . "$HERE/codex_env.sh"
fi

if [[ $# -eq 0 ]]; then
  if command -v "$CODEX_CMD" >/dev/null 2>&1; then
    set -- "$CODEX_CMD" --project .
  else
    echo "Использование: scripts/codex_run.sh <команда Codex> [аргументы...]" >&2
    echo "Пример: scripts/codex_run.sh codex --project ." >&2
    exit 2
  fi
fi

export AFTER_SUCCESS_CMD="${AFTER_SUCCESS_CMD:-$HERE/git_auto_sync.sh}"

exec "$HERE/auto_run.sh" "$@"
