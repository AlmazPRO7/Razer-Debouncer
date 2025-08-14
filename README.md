# Razer_Deboounce — документация

Утилита для подавления дребезга и корректного автоповтора клавиш на Windows. В репозитории — Python‑скрипты и конфигурация PyInstaller для сборки исполняемого файла (`bw3_debounce.spec`).

Основная точка входа: `bw3_debounce3.py`.

## Ключевые возможности
- Подавление дребезга per‑key до начала системного автоповтора.
- Совместимость с системным авто‑повтором; быстрые аккорды модификаторов (Ctrl/Shift/Alt/Win).
- Настраиваемые пороги и поведение через конфиг `%APPDATA%/bw3_chatter_cfg.json`.
- Сборка standalone‑исполняемого файла через PyInstaller.

## Быстрый старт
- Windows: см. `docs/DEVELOPMENT.md` (рекомендуется Python 3.11).
- Ubuntu/WSL (разработка, автотесты): см. `docs/UBUNTU_SETUP.md` и `docs/WSL_SETUP.md`.
- Сборка релиза (PyInstaller/Windows): см. раздел «Сборка» в `docs/DEVELOPMENT.md`.

## Параметры CLI
- `--selftest`: консольный самотест (без WinAPI/GUI) — удобно в WSL/pytest.
- `--no-startup`: не добавлять программу в автозапуск Windows.
- `--no-rate-limit-vks CSV`: VK‑коды, для которых не ограничивается интервал автоповтора (по умолчанию `8` — Backspace).
- `--allow-multiple`: разрешить запуск нескольких копий (по умолчанию запрещено — единственный экземпляр).
- `--no-chord-bypass`: выключить ускорение аккордов (Ctrl/Shift/Alt/Win + X).

## Логи и анализ
- Лог: `%APPDATA%/bw3_chatter.log` (Windows пользователь).
- Просмотр в WSL: `scripts/tail_log.sh` (автоматически найдёт путь и сделает `tail -f`).
- Сводка блокировок: `python3 scripts/analyze_log.py` (покажет топ `BLOCK_*` событий и проблемные клавиши).

## Навигация по документации
- Руководство разработчика: `docs/DEVELOPMENT.md`
- Разработка через WSL: `docs/WSL_SETUP.md`
- Правила участия: `docs/CONTRIBUTING.md`
- Архитектура и структура: `docs/ARCHITECTURE.md`
- История изменений: `docs/CHANGELOG.md`
- Обзор ролей/процессов: `AGENTS.md`, папка `agents/`
- Онлайн‑режим разработки и git: `docs/ONLINE_DEV.md`
- Рабочий процесс чат ↔ терминал: `docs/CLI_WORKFLOW.md`
- Профили терминала (Windows Terminal/tmux): `docs/TERMINAL_PROFILES.md`

## Конфигурация
- Хранится в `%APPDATA%/bw3_chatter_cfg.json` (персональные пороги и параметры).
- Идентификатор клавиши — `"<scanCode>:<extended>"` (например, `"30:0"`). При отсутствии нового ключа используется старый (`"<scanCode>"`) для обратной совместимости.
- По умолчанию Backspace (VK=8) не ограничивается по минимальному интервалу при автоповторе, чтобы не замедлять удаление. Переопределить можно флагом `--no-rate-limit-vks`.

## Лицензия
Уточните лицензию перед публикацией кода (например, MIT/Apache-2.0/Proprietary).
