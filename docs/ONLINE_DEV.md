# Онлайн‑разработка (режим по умолчанию)

Этот гайд описывает онлайн‑режим (сеть ON) для работы с GitHub и быстрых тестов через Codex CLI. Онлайн — это дефолт проекта.

## Профиль среды (по умолчанию)
- Filesystem: danger-full-access (или workspace-write при необходимости)
- Network: ON (онлайн)
- Approvals: never (без подтверждений)
- Запуск терминала/раннера от администратора при работе с хук‑функциями/реестром

## SSH‑доступ к GitHub
1. Убедитесь, что приватный ключ установлен локально и соответствует отпечатку:
   - SHA256:0ldmpkCK0crOOOshAGlz7elHMv0lWO5PCsUqyy1NPvk
   - Проверка (пример):
     - PowerShell: `ssh-keygen -lf $HOME/.ssh/id_ed25519.pub`
     - Bash: `ssh-keygen -lf ~/.ssh/id_ed25519.pub`
2. Инициализируйте переменные окружения для git:
   - PowerShell: `.\\scripts\\git_env.ps1 -KeyPath C:\\Users\\YOU\\.ssh\\id_ed25519`
   - Bash: `SSH_KEY_PATH=/c/Users/YOU/.ssh/id_ed25519 ./scripts/git_env.sh`
3. Настройте `origin` на SSH‑URL вашего репозитория:
   - PowerShell: `.\\scripts\\git_remote_setup.ps1 -RepoSshUrl git@github.com:USER/REPO.git`
   - Bash: `GITHUB_SSH_URL=git@github.com:USER/REPO.git ./scripts/git_remote_setup.sh`

После этого используйте обычные команды `git pull`, `git push` (в текущей сессии действует `GIT_SSH_COMMAND`).
Для полной автоматизации установите хуки: `./scripts/install_git_hooks.sh` или `.\\scripts\\install_git_hooks.ps1`.

## Быстрые тесты и запуск
- Самотест без хука/GUI: `./scripts/dev_test.sh` или `./scripts/dev_test.ps1`
- Запуск приложения (dev): `./scripts/dev_run.sh` или `./scripts/dev_run.ps1 -Debug`

## Локальный auto-merge (без GitHub Actions)
- Авто‑слияние делаем локально: ребейзим фичу на `main` и fast‑forward‑мерджим `main`.
- Bash: `./scripts/auto_merge.sh [--feature <ветка>] [--main main] [--push]`
- PowerShell: `.\\scripts\\auto_merge.ps1 -Feature <ветка> -Main main -Push`
- Скрипт сам выполнит `git fetch`, `git pull --rebase`, `git rebase`, опционально быстрый тест и `git merge --ff-only`.
- При грязном дереве используется auto‑stash/unstash.

## Автосинхронизация с Git (без подтверждений)
- Скрипты: `scripts/git_auto_sync.sh` (Bash/WSL) и `scripts/git_auto_sync.ps1` (PowerShell).
- Что делает: авто‑стейдж/коммит (если есть изменения) → `fetch` → `pull --rebase` →
  - если текущая ветка `main` — `push` в `origin/main`;
  - если фича‑ветка — вызовет `scripts/auto_merge.(sh|ps1)` для ребейза на `main`, fast‑forward‑мерджа `main` и пуша обеих веток.

Варианты включения:
- Установить git‑хуки (рекомендуется): `./scripts/install_git_hooks.sh` или `.\\scripts\\install_git_hooks.ps1`.
  - pre-commit: автогенерация `docs/CLI_FLAGS.md` + проверка docs.
  - post-commit: авто‑push через `git_auto_sync.sh`.
  - post-merge: регенерация `docs/CLI_FLAGS.md`.
- Разово после завершения работы: `./scripts/git_auto_sync.sh` или `.\\scripts\\git_auto_sync.ps1`.
- Обёртки «всё‑в‑одном» для Codex CLI:
  - Bash/WSL: `./scripts/codex_run.sh codex [опции Codex]`
  - PowerShell: `.\\scripts\\codex_run.ps1 codex [опции Codex]`
  Эти обёртки подхватывают окружение из `scripts/codex_env.*`, запускают указанную команду и после успеха вызывают авто‑sync.
- Через универсальную обёртку `auto_run` с переменной `AFTER_SUCCESS_CMD`:
  - Bash: `AFTER_SUCCESS_CMD=./scripts/git_auto_sync.sh ./scripts/auto_run.sh codex`
  - PowerShell: `$env:AFTER_SUCCESS_CMD = ".\\scripts\\git_auto_sync.ps1"; .\\scripts\\auto_run.ps1 codex`
- Через конфиг `.codex/config.yaml` (раздел `hooks.post_task`) — соглашение команды; фактический вызов выполняет ваша обёртка запуска.

Примечания безопасности:
- Скрипт использует `--force-with-lease` при пуше фича‑ветки после ребейза.
- Для корректной работы SSH задайте окружение через `scripts/git_env.(sh|ps1)`.
 - Если нет `origin`, задайте `GITHUB_SSH_URL` — `git_auto_sync.sh` настроит remote автоматически.

## Авто‑документация
- Генерация списка флагов CLI: `scripts/docs_autoupdate.py` → файл `docs/CLI_FLAGS.md` (запускается pre-commit/post-merge хуками).
- Проверка упоминаний в документации: `scripts/docs_check.py` (блокирует коммит при несоответствиях).

## Политики и рекомендации
- CI/CD в облаке не используем. Проверки запускаем локально.
- Логи храним локально, секреты/ключи в репозиторий не коммитим.
