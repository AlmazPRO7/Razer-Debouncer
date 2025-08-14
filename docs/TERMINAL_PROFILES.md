# Профили терминала: Windows Terminal и tmux

Этот документ помогает быстро открыть 2 панели: слева — чат Codex (cx), справа — ваш шелл.

## Windows Terminal (две панели одной командой)
- Скрипт: `scripts/wt_open.ps1`
- Запуск: `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\wt_open.ps1`
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
- Скрипт: `scripts/tmux_session.sh [session_name]`
- Запуск: `./scripts/tmux_session.sh` (по умолчанию создает/подключается к сессии `razer_debounce`).
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

