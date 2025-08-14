#!/usr/bin/env python3
import os, re, sys, glob, argparse, collections


EVENT_RE = re.compile(r"\b(BLOCK_[A-Z_]+)\b(?:\s+(\S+))?")


def find_log(path_hint: str | None = None) -> str | None:
    if path_hint:
        return path_hint if os.path.isfile(path_hint) else None
    # Try APPDATA path
    appdata = os.getenv("APPDATA")
    if appdata:
        p = os.path.join(appdata, "bw3_chatter.log")
        if os.path.isfile(p):
            return p
    # Try common Windows path from WSL
    candidates = glob.glob("/mnt/c/Users/*/AppData/Roaming/bw3_chatter.log")
    candidates.sort(key=lambda p: os.path.getmtime(p) if os.path.exists(p) else 0, reverse=True)
    return candidates[0] if candidates else None


def analyze(path: str, top: int = 10):
    counts = collections.Counter()
    sc_counts = collections.Counter()
    total = 0
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = EVENT_RE.search(line)
            if not m:
                continue
            total += 1
            ev = m.group(1)
            sc = (m.group(2) or "").strip(",")
            counts[ev] += 1
            if ev.startswith("BLOCK_") and sc:
                sc_counts[(ev, sc)] += 1

    print(f"Log: {path}")
    print("Events summary:")
    for ev, c in counts.most_common():
        print(f"  {ev:16} {c}")
    if not counts:
        print("  (no BLOCK_* events found)")
    print()
    if sc_counts:
        print(f"Top {top} blocked keys (by event, sc):")
        for (ev, sc), c in sc_counts.most_common(top):
            print(f"  {ev:16} sc={sc:8}  {c}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--path", help="Путь к bw3_chatter.log (опционально)")
    ap.add_argument("--top", type=int, default=10, help="Сколько строк топа показать")
    args = ap.parse_args()

    path = find_log(args.path)
    if not path:
        print("Не найден bw3_chatter.log. Укажите путь через --path.", file=sys.stderr)
        sys.exit(2)
    analyze(path, top=args.top)


if __name__ == "__main__":
    main()

