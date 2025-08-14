# Codex CLI workspace config

- Файл `config.yaml` содержит желаемые настройки песочницы и сети для разработки.
- Убедитесь, что Codex CLI запущен из корня проекта: `/mnt/c/Razer_Deboounce`.
- Если ваш harness поддерживает чтение `.codex/config.yaml`, эти настройки применятся автоматически.
- Если нет — используйте их как эталон и выставьте эквивалентные параметры вручную.

Рекомендуемые значения:
- filesystem: workspace-write
- network: on
- approvals: on-failure
- workspace root: /mnt/c/Razer_Deboounce
