# Ubuntu: Python 3.11 и автотесты

Этот гайд настраивает локальное окружение Ubuntu для разработки и автотестов (без Windows‑хуков/GUI).

## Требования
- Ubuntu 20.04/22.04/24.04.
- Доступ к `apt` (или предустановленный `python3.11`).

## Быстрый старт

```
# из корня репозитория
./scripts/setup_ubuntu.sh          # установит python3.11 (через apt) и создаст .venv
source .venv/bin/activate

# быстрая проверка без Windows‑хука/GUI
./scripts/dev_test.sh

# автотесты (pytest)
pytest -q
```

Опционально для Linux‑трея/GUI (pystray) добавьте флаг `--gui`:

```
./scripts/setup_ubuntu.sh --gui
```

Это установит GTK‑зависимости (`python3-gi`, `gir1.2-gtk-3.0`). В обычных автотестах GUI не требуется.

## Что делает скрипт
- Ставит `python3.11` и `python3.11-venv` (на 22.04/20.04 добавляет PPA deadsnakes).
- Создаёт виртуальное окружение `.venv` на Python 3.11.
- Устанавливает `requirements.txt` (кроссплатформенные пакеты) и `requirements-dev.txt` (pytest, linters).

## Примечания
- В `requirements.txt` Windows‑специфичные пакеты помечены маркерами (`sys_platform == "win32"`). В Ubuntu они не устанавливаются.
- Самотест `--selftest` не требует WinAPI/GUI и запускается в Ubuntu.
- Для сборки Windows‑бинарей используйте Windows/WSL‑обёртки (см. `docs/WSL_SETUP.md`).

