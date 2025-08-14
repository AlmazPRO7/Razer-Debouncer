#!/usr/bin/env python3
import re, os, sys, glob, pathlib


ROOT = pathlib.Path(__file__).resolve().parents[1]
DOCS = [ROOT / "README.md", *(ROOT / "docs").glob("*.md")]


def extract_flags(py_path: pathlib.Path):
    text = py_path.read_text(encoding="utf-8", errors="ignore")
    flags = set()
    for m in re.finditer(r"ap\.add_argument\(\s*\"(--[a-z0-9-]+)\"", text):
        flags.add(m.group(1))
    return sorted(flags)


def docs_text():
    buf = []
    for p in DOCS:
        try:
            buf.append(p.read_text(encoding="utf-8", errors="ignore"))
        except Exception:
            pass
    return "\n".join(buf)


def main():
    py = ROOT / "bw3_debounce3.py"
    if not py.exists():
        print("bw3_debounce3.py не найден", file=sys.stderr)
        sys.exit(2)

    flags = extract_flags(py)
    text = docs_text()
    missing = []
    # Проверяем только ключевые флаги, которые должны быть в руководствах
    key_flags = {
        "--selftest",
        "--no-startup",
        "--no-rate-limit-vks",
        "--allow-multiple",
        "--no-chord-bypass",
    }
    for f in sorted(key_flags):
        if f not in text:
            missing.append(f)

    # Требуемые скрипты должны быть упомянуты
    required_mentions = [
        "scripts/setup_ubuntu.sh",
        "scripts/tail_log.sh",
        "scripts/analyze_log.py",
        "requirements-dev.txt",
        "pytest",
    ]
    for token in required_mentions:
        if token not in text:
            missing.append(token)

    if missing:
        print("Отсутствуют упоминания в документации:")
        for m in missing:
            print("  -", m)
        sys.exit(1)
    print("Документация: OK (флаги и скрипты упомянуты)")


if __name__ == "__main__":
    main()
