#!/usr/bin/env bash
# show_poem.sh — picks a random public-domain poem and opens it as a plain
# text file so it doesn't fight with Claude Code's TUI for terminal pixels.
# Uses macOS `open`, which hands the file to the default .txt handler
# (TextEdit by default) — no lingering shell process to confirm closing.
#
# The poem is overlaid onto a random background from ../backgrounds/*.txt,
# which must contain a `[POEM]` marker on one line. Subsequent poem lines
# are indented to align with the column where [POEM] begins.
#
# Requires: macOS, jq, python3, open (preinstalled on macOS).
# Fails silently on other platforms.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POEMS_FILE="${SCRIPT_DIR}/../poems/poems.json"
BACKGROUNDS_DIR="${SCRIPT_DIR}/../backgrounds"

[[ "$(uname)" == "Darwin" ]] || exit 0
[[ -f "$POEMS_FILE" ]] || exit 0
[[ -d "$BACKGROUNDS_DIR" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
command -v open >/dev/null 2>&1 || exit 0

if [[ ! -t 0 ]]; then
  { timeout 0.2 cat >/dev/null 2>&1; } || true
fi

COUNT=$(jq 'length' "$POEMS_FILE")
[[ -n "$COUNT" && "$COUNT" -gt 0 ]] || exit 0
INDEX=$((RANDOM % COUNT))

TITLE=$(jq -r ".[$INDEX].title" "$POEMS_FILE")
AUTHOR=$(jq -r ".[$INDEX].author" "$POEMS_FILE")
TEXT=$(jq -r ".[$INDEX].text" "$POEMS_FILE")

shopt -s nullglob
BACKGROUNDS=("${BACKGROUNDS_DIR}"/*.txt)
shopt -u nullglob
BG_COUNT=${#BACKGROUNDS[@]}
[[ $BG_COUNT -gt 0 ]] || exit 0
BG_FILE="${BACKGROUNDS[$((RANDOM % BG_COUNT))]}"

POEM_FILE="/tmp/poetry-in-code-$$.txt"

export PIC_TITLE="$TITLE"
export PIC_AUTHOR="$AUTHOR"
export PIC_TEXT="$TEXT"
export PIC_BG="$BG_FILE"
export PIC_OUT="$POEM_FILE"

python3 - <<'PYEOF'
import os
import unicodedata

bg_path = os.environ["PIC_BG"]
title = os.environ["PIC_TITLE"]
author = os.environ["PIC_AUTHOR"]
text = os.environ["PIC_TEXT"]
out_path = os.environ["PIC_OUT"]

with open(bg_path, encoding="utf-8") as f:
    bg = f.read()

header = f"{title} — {author}"
poem_lines = text.split("\n")


def to_indent(prefix: str) -> str:
    """Turn the [POEM] prefix into an indent: keep whitespace and zero-width
    format chars as-is, replace every other visible glyph with a space so
    subsequent lines land at the same visual column."""
    out = []
    for c in prefix:
        if c.isspace() or unicodedata.category(c) == "Cf":
            out.append(c)
        else:
            out.append(" ")
    return "".join(out)


result = []
for bg_line in bg.split("\n"):
    marker = "[POEM]"
    if marker not in bg_line:
        result.append(bg_line)
        continue

    idx = bg_line.index(marker)
    prefix = bg_line[:idx]
    suffix = bg_line[idx + len(marker):]
    indent = to_indent(prefix)

    result.append(f"{prefix}{header}{suffix}")
    result.append("")
    for line in poem_lines:
        result.append(f"{indent}{line}" if line.strip() else "")

with open(out_path, "w", encoding="utf-8") as f:
    f.write("\n".join(result))
PYEOF

open "$POEM_FILE" >/dev/null 2>&1 || true

exit 0
