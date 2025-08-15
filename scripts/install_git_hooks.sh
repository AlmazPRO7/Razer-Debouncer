#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository: $ROOT" >&2
  exit 2
fi

HOOKS_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOKS_DIR"

cat > "$HOOKS_DIR/pre-commit" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
if command -v python3 >/dev/null 2>&1; then
  python3 scripts/docs_autoupdate.py || true
  python3 scripts/docs_check.py || { echo "[pre-commit] docs_check failed — обновите документацию" >&2; exit 1; }
  git add docs/CLI_FLAGS.md || true
fi
SH
chmod +x "$HOOKS_DIR/pre-commit"

cat > "$HOOKS_DIR/post-commit" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
# Автосинхронизация (commit уже создан)
NO_PUSH=${NO_PUSH:-0} scripts/git_auto_sync.sh || true
SH
chmod +x "$HOOKS_DIR/post-commit"

cat > "$HOOKS_DIR/post-merge" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
# Перегенерировать CLI-флаги после merge
if command -v python3 >/dev/null 2>&1; then
  python3 scripts/docs_autoupdate.py || true
  git add docs/CLI_FLAGS.md || true
fi
SH
chmod +x "$HOOKS_DIR/post-merge"

echo "Installed git hooks into $HOOKS_DIR"

