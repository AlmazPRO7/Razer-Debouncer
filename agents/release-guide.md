# Release Agent — руководство

## Обязанности
- Сборка исполняемого файла PyInstaller по `bw3_debounce.spec`.
- Проверка артефактов и обновление `docs/CHANGELOG.md`.
- Публикация сборок в `dist/` (вручную).

## Порядок действий
1) Обновить CHANGELOG (раздел Unreleased → версия + дата).
2) Собрать:
```
pyinstaller bw3_debounce.spec
```
3) Проверить запускаемость `dist/bw3_debounce.exe` на чистой системе.
4) Пройти краткий QA‑чек‑лист (см. `agents/qa-checklist.md`).
5) Создать git‑тег `vX.Y.Z` и опубликовать артефакты.

Подробнее: `docs/RELEASE.md`.

