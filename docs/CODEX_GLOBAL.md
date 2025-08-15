# Codex CLI — глобальные настройки

Цель: сделать так, чтобы дефолтные параметры Codex CLI (одобрения, сеть, доступ к ФС и язык) применялись автоматически во всех репозиториях.

## Что настраивается
- approvals: `never`
- network: `on`
- filesystem: `danger-full-access`
- language: `ru`
- auto_escalate: `true`
- путь к конфигу: `~/.codex/config.yaml`

## Быстрый старт

WSL/Linux:
- Выполните: `bash scripts/install_codex_global.sh`
- Перезапустите shell или выполните: `source ~/.bashrc` (или `~/.zshrc`)

Windows (PowerShell):
- Выполните: `powershell -ExecutionPolicy Bypass -File scripts/install_codex_global.ps1`
- Закройте и откройте новое окно PowerShell

Скрипты:
- Скопируют шаблон `.codex/config.yaml` из репозитория в `~/.codex/config.yaml` (создадут минимальную версию, если исходник отсутствует)
- Добавят блок с переменными окружения в профиль shell (идемпотентно)
 - Рекомендуется: установить git‑хуки для авто‑документации и авто‑push: `./scripts/install_git_hooks.sh` или `.\\scripts\\install_git_hooks.ps1`.

## Проверка
- В новом терминале в любой папке выполните: `env | grep CODEX_` (Linux) или `Get-ChildItem Env:CODEX*` (Windows)
  Ожидается: `CODEX_APPROVALS=never`, `CODEX_NETWORK=on`, `CODEX_FS=danger-full-access`, `CODEX_LANG=ru`, `CODEX_AUTO_ESCALATE=1`, `CODEX_CONFIG=~/.codex/config.yaml`.
- Запустите Codex CLI. Он должен подхватить переменные автоматически.
 - В Codex проекте включены хуки post_task для авто‑push (`.codex/config.yaml`).

## Переопределения для конкретного репозитория
- Поместите локальный конфиг в корень репозитория: `.codex/config.yaml` — он перекроет глобальные значения при запуске с `--project .`.
- Переменные окружения имеют приоритет над файлом конфига.

## Отключение или изменение
- Удалите блок `CODEX_GLOBAL` из соответствующего профиля (`~/.bashrc`, `~/.zshrc`, или `$PROFILE` в PowerShell) или поправьте значения.
- Можно временно переопределить в текущей сессии: например, `export CODEX_APPROVALS=on-failure`.
