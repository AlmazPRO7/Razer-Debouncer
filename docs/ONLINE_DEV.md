# Онлайн‑разработка (режим по умолчанию)

Этот гайд описывает онлайн‑режим (сеть ON) для работы с GitHub и быстрых тестов через Codex CLI. Онлайн — это дефолт проекта.

## Профиль среды (по умолчанию)
- Filesystem: workspace-write (или danger-full-access по задаче)
- Network: ON
- Approvals: on-request или never
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

## Быстрые тесты и запуск
- Самотест без хука/GUI: `./scripts/dev_test.sh` или `./scripts/dev_test.ps1`
- Запуск приложения (dev): `./scripts/dev_run.sh` или `./scripts/dev_run.ps1 -Debug`

## Локальный auto-merge (без GitHub Actions)
- Авто‑слияние делаем локально: ребейзим фичу на `main` и fast‑forward‑мерджим `main`.
- Bash: `./scripts/auto_merge.sh [--feature <ветка>] [--main main] [--push]`
- PowerShell: `.\\scripts\\auto_merge.ps1 -Feature <ветка> -Main main -Push`
- Скрипт сам выполнит `git fetch`, `git pull --rebase`, `git rebase`, опционально быстрый тест и `git merge --ff-only`.
- При грязном дереве используется auto‑stash/unstash.

## Политики и рекомендации
- CI/CD в облаке не используем. Проверки запускаем локально.
- Логи храним локально, секреты/ключи в репозиторий не коммитим.
