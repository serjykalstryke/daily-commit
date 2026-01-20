#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

REPO="/Users/davidstinnett/dev/daily-commit"
cd "$REPO"

echo "dailycommit ran at $(date)"  # breadcrumb

date -u +"%Y-%m-%dT%H:%M:%SZ" >> logs/daily.log

IFS=$'\t' read -r QUOTE AUTHOR < <(/usr/bin/python3 - <<'PY'
import json, urllib.request, random

# Quote-of-the-day (changes at 00:00 UTC)
url = "https://zenquotes.io/api/today"

fallback = [
  ("Talk is cheap. Show me the code.", "Linus Torvalds"),
  ("Simplicity is prerequisite for reliability.", "Edsger W. Dijkstra"),
  ("Programs must be written for people to read.", "Harold Abelson"),
  ("Premature optimization is the root of all evil.", "Donald Knuth"),
]

try:
    with urllib.request.urlopen(url, timeout=10) as r:
        data = json.load(r)  # ZenQuotes returns a JSON array
    q = data[0]["q"].replace("\n", " ").strip()
    a = data[0]["a"].replace("\n", " ").strip()
except Exception:
    q, a = random.choice(fallback)

print(q + "\t" + a)
PY
)

export QUOTE AUTHOR
/usr/bin/python3 - <<'PY'
import os, re, datetime, pathlib

quote = os.environ["QUOTE"]
author = os.environ["AUTHOR"]
today = datetime.date.today().isoformat()

readme_path = pathlib.Path("README.md")
text = readme_path.read_text(encoding="utf-8")

block = (
    "<!-- TODAY_QUOTE_START -->\n"
    f'> “{quote}” — {author}\n\n'
    f"<sub>Updated: {today} • Source: [ZenQuotes AP](https://zenquotes.io/)</sub>\n"
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

