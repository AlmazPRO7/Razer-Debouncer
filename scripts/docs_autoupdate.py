#!/usr/bin/env python3
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "bw3_debounce3.py"
OUT = ROOT / "docs" / "CLI_FLAGS.md"

def parse_flags(text: str):
    # грубый парсер аргументов из argparse add_argument("--flag", ..., help="...")
    pat = re.compile(r"ap\.add_argument\(\s*\"(--[a-z0-9-]+)\"[^\)]*?help=\"([^\"]*)\"", re.I)
    return sorted(pat.findall(text), key=lambda t: t[0])

def render_md(pairs):
    lines = [
        "# CLI-флаги (генерируется автоматически)",
        "",
        "Источник: парсинг аргументов из `bw3_debounce3.py`.",
        "",
    ]
    for flag, help_text in pairs:
        lines.append(f"- `{flag}`: {help_text}")
    lines.append("")
    return "\n".join(lines)

def main():
    if not SRC.exists():
        print("bw3_debounce3.py не найден", file=sys.stderr)
        sys.exit(2)
    text = SRC.read_text(encoding="utf-8", errors="ignore")
    pairs = parse_flags(text)
    OUT.write_text(render_md(pairs), encoding="utf-8")
    print(f"Обновлено: {OUT}")

if __name__ == "__main__":
    main()

