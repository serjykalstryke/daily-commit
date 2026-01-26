#!/usr/bin/env bash
set -euo pipefail

# --- Environment hardening (cron/launchd-safe) ---
# Ensure HOME is set (some schedulers provide a minimal env)
if [[ -z "${HOME:-}" ]]; then
  if command -v getent >/dev/null 2>&1; then
    HOME="$(getent passwd "$(id -un)" | cut -d: -f6)"
  else
    # macOS fallback (no getent by default)
    HOME="$(dscl . -read "/Users/$(id -un)" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
  fi
  export HOME
fi

# Ensure PATH includes common locations (cron/launchd may be minimal)
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Prefer python3, but allow override
PYTHON_BIN="${PYTHON_BIN:-}"
if [[ -z "$PYTHON_BIN" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python3)"
  elif command -v /usr/bin/python3 >/dev/null 2>&1; then
    PYTHON_BIN="/usr/bin/python3"
  else
    echo "ERROR: python3 not found. Install Python 3 or set PYTHON_BIN." >&2
    exit 1
  fi
fi

# Force SSH key selection (optional, helps in non-interactive environments)
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
if [[ -f "$SSH_KEY" ]]; then
  export GIT_SSH_COMMAND="ssh -i \"$SSH_KEY\" -o IdentitiesOnly=yes"
fi

# --- Repo resolution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${REPO:-}" ]]; then
  echo "ERROR: REPO is not set." >&2
  echo "Set it like: REPO=\"\$HOME/dev/daily-commit\" /path/to/dailycommit.sh" >&2
  exit 1
fi

cd "$REPO"

echo "dailycommit ran at $(date)"  # breadcrumb

mkdir -p logs
date -u +"%Y-%m-%dT%H:%M:%SZ" >> logs/daily.log

# --- Fetch quote (ZenQuotes 'today') with fallback ---
IFS=$'\t' read -r QUOTE AUTHOR < <("$PYTHON_BIN" - <<'PY'
import json, urllib.request, random

url = "https://zenquotes.io/api/today"

fallback = [
  ("Talk is cheap. Show me the code.", "Linus Torvalds"),
  ("Simplicity is prerequisite for reliability.", "Edsger W. Dijkstra"),
  ("Programs must be written for people to read.", "Harold Abelson"),
  ("Premature optimization is the root of all evil.", "Donald Knuth"),
]

try:
    with urllib.request.urlopen(url, timeout=10) as r:
        data = json.load(r)
    q = data[0]["q"].replace("\n", " ").strip()
    a = data[0]["a"].replace("\n", " ").strip()
except Exception:
    q, a = random.choice(fallback)

print(q + "\t" + a)
PY
)

export QUOTE AUTHOR
"$PYTHON_BIN" - <<'PY'
import os, re, datetime, pathlib

quote = os.environ["QUOTE"]
author = os.environ["AUTHOR"]
today = datetime.date.today().isoformat()

readme_path = pathlib.Path("README.md")
text = readme_path.read_text(encoding="utf-8")

block = (
    "<!-- TODAY_QUOTE_START -->\n"
    f'> “{quote}” — {author}\n\n'
    f"<sub>Updated: {today} • Source: [ZenQuotes API](https://zenquotes.io/)</sub>\n"
    "<!-- TODAY_QUOTE_END -->"
)

new_text, n = re.subn(
    r"<!-- TODAY_QUOTE_START -->.*?<!-- TODAY_QUOTE_END -->",
    block,
    text,
    flags=re.S
)

if n != 1:
    raise SystemExit("README markers not found (or found multiple times).")

readme_path.write_text(new_text, encoding="utf-8")
PY

git add logs/daily.log README.md

if ! git diff --cached --quiet; then
  git commit -m "daily: $(date +%Y-%m-%d)"
  git push
fi
