#!/usr/bin/env bash
# Helper to run Codex CLI with permissive defaults

export CODEX_APPROVALS=never
export CODEX_NETWORK=on
export CODEX_FS=danger-full-access
export CODEX_LANG=ru
export CODEX_AUTO_ESCALATE=1
export CODEX_CMD=${CODEX_CMD:-codex}

# Гарантируем корректный вывод/ввод UTF-8 (кириллица, тире, неразрывные дефисы)
export LANG=${LANG:-C.UTF-8}
export LC_ALL=${LC_ALL:-C.UTF-8}
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8
export LESSCHARSET=utf-8
export GIT_PAGER=${GIT_PAGER:-less -R}

echo "[codex_env] Applied: APPROVALS=$CODEX_APPROVALS, NETWORK=$CODEX_NETWORK, FS=$CODEX_FS, LANG=$CODEX_LANG, AUTO_ESCALATE=$CODEX_AUTO_ESCALATE, CODEX_CMD=$CODEX_CMD"
echo "[codex_env] UTF-8 locale: LANG=$LANG LC_ALL=$LC_ALL PYTHONIOENCODING=$PYTHONIOENCODING"
echo "Start your CLI in this shell so settings take effect."
