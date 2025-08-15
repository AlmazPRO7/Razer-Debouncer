#!/usr/bin/env bash
set -euo pipefail

# Устанавливает глобальные переменные окружения для Codex CLI (для всех репозиториев)
# и копирует шаблон конфига в ~/.codex/config.yaml. Идемпотентно обновляет ~/.bashrc и ~/.zshrc.

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

CONFIG_SRC="$ROOT/.codex/config.yaml"
CONFIG_DIR="$HOME/.codex"
CONFIG_DST="$CONFIG_DIR/config.yaml"

mkdir -p "$CONFIG_DIR"
if [[ -f "$CONFIG_SRC" ]]; then
  cp -f "$CONFIG_SRC" "$CONFIG_DST"
else
  # Создать минимальный конфиг, если исходник не найден
  cat >"$CONFIG_DST" <<'YAML'
# Global Codex CLI config
defaults:
  approvals: never
  language: ru
  auto_escalate: true
sandbox:
  filesystem: danger-full-access
  network: on
YAML
fi

BLOCK_START="# BEGIN CODEX_GLOBAL"
BLOCK_END="# END CODEX_GLOBAL"
BLOCK_CONTENT=$(cat <<'EOF'
# BEGIN CODEX_GLOBAL
# Глобальные переменные для Codex CLI (применяются во всех репозиториях)
export CODEX_APPROVALS=never
export CODEX_NETWORK=on
export CODEX_FS=danger-full-access
export CODEX_LANG=ru
export CODEX_AUTO_ESCALATE=1
export CODEX_CONFIG="$HOME/.codex/config.yaml"
# END CODEX_GLOBAL
EOF
)

patch_rc() {
  local rcfile="$1"
  touch "$rcfile"
  if grep -q "$BLOCK_START" "$rcfile" 2>/dev/null; then
    # заменить существующий блок
    awk -v start="$BLOCK_START" -v end="$BLOCK_END" -v repl="$BLOCK_CONTENT" '
      BEGIN{printed=0}
      {
        if ($0 ~ start) { inblock=1; if (!printed) { print repl; printed=1 } }
        else if ($0 ~ end) { inblock=0; next }
        else if (!inblock) { print }
      }' "$rcfile" >"$rcfile.tmp"
    mv "$rcfile.tmp" "$rcfile"
  else
    printf "\n%s\n" "$BLOCK_CONTENT" >>"$rcfile"
  fi
}

patch_rc "$HOME/.bashrc"
patch_rc "$HOME/.zshrc"

echo "[codex-global] Установлено: $CONFIG_DST"
echo "[codex-global] Добавлены глобальные переменные в ~/.bashrc и ~/.zshrc"
echo "[codex-global] Перезапустите shell или выполните: source ~/.bashrc (или ~/.zshrc)"

