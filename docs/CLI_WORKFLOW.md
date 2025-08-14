# Рабочий процесс: чат ↔ терминал (Codex CLI)

Цель: удобная работа со скриптами/репозиторием, переключение между чатом и терминалом, автоматическая синхронизация с Git.

## 1. Быстрый старт
- Bash/WSL:
  - Загрузить окружение: `source scripts/codex_env.sh && source scripts/aliases.sh`
  - Запустить Codex: `cx --project .` (или `./scripts/codex_run.sh codex --project .`)
  - Ручная синхронизация: `gsync`
- PowerShell (Windows):
  - Загрузить окружение: `.\scripts\codex_env.ps1; .\scripts\aliases.ps1`
  - Запустить Codex: `cx --project .` (или `.\scripts\codex_run.ps1 codex --project .`)
  - Ручная синхронизация: `gsync`

## 2. Авто‑синхронизация
- Обёртки `codex_run.*` запускают команду и при успешном завершении вызывают `git_auto_sync.*`.
- Универсальные раннеры `auto_run.*` поддерживают `AFTER_SUCCESS_CMD` — можно подставить свою пост‑команду.

## 3. Переключение чат ↔ терминал
- Рекомендуется 2 вкладки/панели терминала:
  1) Codex CLI (через `codex_run.*`) для диалога и автоматических действий.
  2) Обычный шелл для ручных экспериментов (`devrun`, `devtest`, `git log`, и т.д.).
- Windows Terminal: создайте профиль с рабочей директорией на корень репо и командой запуска `powershell.exe -NoLogo -NoProfile -Command \". scripts/codex_env.ps1; . scripts/aliases.ps1; cx --project .\"`.
- tmux/screen (WSL/Linux): используйте сплит‑панели, в одной из которых запущен `cx`, в другой — обычный шелл.

## 4. Полезные команды/алиасы
- `cx`: запустить Codex CLI с автосинхронизацией.
- `gsync`: вручную запустить автосинхронизацию Git.
- `amerge`: локальный auto‑merge (rebase фичи на main, fast‑forward main, push).
- `devrun`, `devtest`: примеры запуска скрипта/самотестов (см. содержимое в `scripts/`).

## 5. Переменные окружения
- `CODEX_CMD` — команда запуска Codex CLI (по умолчанию `codex`).
- `AFTER_SUCCESS_CMD` — команда, которая выполняется после успешного завершения основной в `auto_run.*`.
- Профиль Codex: `CODEX_APPROVALS=never`, `CODEX_NETWORK=on`, `CODEX_FS=danger-full-access`, `CODEX_LANG=ru`, `CODEX_AUTO_ESCALATE=1` (см. `scripts/codex_env.*`).

## 6. Git и SSH
- Настройка SSH/remote: `scripts/git_env.*`, `scripts/git_remote_setup.*`, проверка — `scripts/ssh_check.*`.
- Для фича‑веток `git_auto_sync.*` вызывает `auto_merge.*` и пушит обе ветки (`--force-with-lease`).

## 7. Замечания
- Конкретная команда запуска Codex может отличаться (укажите её в `CODEX_CMD`).
- Автосинхронизация безопасна для пустых изменений (коммит пропускается).

