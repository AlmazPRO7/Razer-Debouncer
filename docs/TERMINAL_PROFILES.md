# Профили терминала: Windows Terminal и tmux

Этот документ помогает быстро открыть 2 панели: слева — чат Codex (cx), справа — ваш шелл.

## Windows Terminal (две панели одной командой)
- Рекомендация: `scripts/open_dev.ps1` — единый launcher; автоматическая установка: `scripts/install_windows_env.ps1` (создаст профиль WT и ярлык на рабочем столе).
- Альтернатива: `scripts/wt_open.ps1` (напрямую через wt.exe).
- Запуск: `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\open_dev.ps1`
- Что делает: открывает Windows Terminal (`wt.exe`) с двумя панелями в корне репо:
  - Левая: загружает `scripts/codex_env.ps1`, `scripts/aliases.ps1` и запускает `cx --project .`.
  - Правая: шелл с тем же окружением.

### JSON-фрагмент профиля (необязательно)
Добавьте в `settings.json` Windows Terminal свой профиль (пример):

```
{
  "name": "Razer Debounce (Codex)",
  "commandline": "powershell.exe -NoLogo -NoProfile -Command \". scripts/codex_env.ps1; . scripts/aliases.ps1; cx --project .\"",
  "startingDirectory": "C:/Razer_Deboounce",
  "icon": "C:/Windows/System32/Keyboard.png",
  "hidden": false
}
```

Путь `startingDirectory` укажите под вашу систему. Для двух панелей используйте скрипт `wt_open.ps1`.

## tmux (WSL/Linux)
- Рекомендация: `scripts/open_dev.sh` — единый launcher (предпочтительно откроет tmux-сессию); автоматическая установка автозапуска: `scripts/install_wsl_env.sh`.
- Альтернатива: `scripts/tmux_session.sh [session_name]` напрямую.
- Запуск: `./scripts/open_dev.sh`.
- Состав:
  - Окно 0, панель 0: запускает `cx --project .` с окружением.
  - Окно 0, панель 1: обычный шелл с окружением.

### Ручной tmux-фрагмент (если хотите прописать в конфиге)
```
# ~/.tmux.conf (пример ключевых настроек)
set -g mouse on
bind r source-file ~/.tmux.conf \; display-message "Reloaded" 
```

Создать сессию вручную:
```
cd /mnt/c/Razer_Deboounce
source scripts/codex_env.sh && source scripts/aliases.sh
# стартовать сессию и панель Codex
TMUX= tmux new-session -s razer_debounce -d "bash -lc 'source scripts/codex_env.sh && source scripts/aliases.sh && cx --project .'"
# добавить вторую панель
TMUX= tmux split-window -h -t razer_debounce:0.0 "bash -lc 'source scripts/codex_env.sh && source scripts/aliases.sh; exec bash'"
TMUX= tmux attach -t razer_debounce
```

## Подсказки
- Если команда Codex другая — задайте `CODEX_CMD` (например, путь к исполняемому файлу).
- В WSL используйте `wslview` для открытия внешних ссылок из консоли.
- Убедитесь, что SSH‑ключи настроены (см. `docs/ONLINE_DEV.md`).

## Кириллица и Юникод (UTF‑8)
- PowerShell/Windows:
  - Загрузите окружение: `.\scripts\codex_env.ps1` — скрипт установит UTF‑8 кодировку консоли (`chcp 65001`) и Python (`PYTHONIOENCODING=utf-8`).
  - В Windows Terminal используйте шрифт с поддержкой кириллицы (напр., Cascadia Mono/Code, Consolas).
- Bash/WSL:
  - Загрузите окружение: `source scripts/codex_env.sh` — устанавливает `LANG/LC_ALL=C.UTF-8`, `PYTHONIOENCODING=utf-8`.
  - Проверьте `locale` — значения должны быть `UTF-8`.
- Git/less:
  - Пейджер установлен на `less -R`, переменная `LESSCHARSET=utf-8`.
  - При необходимости: `git config --global i18n.commitEncoding utf-8` и `git config --global i18n.logOutputEncoding utf-8`.

Если отдельные символы (например, неразрывный дефис `U+2011`) отображаются квадратами, смените шрифт терминала или используйте обычный дефис `-`.
