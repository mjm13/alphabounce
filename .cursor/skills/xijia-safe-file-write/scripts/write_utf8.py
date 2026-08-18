#!/usr/bin/env python3
"""Write stdin to a path as UTF-8 without BOM, LF newlines; then verify.

Usage:
  python write_utf8.py <path> < content.md
  type content.md | python write_utf8.py <path>   # Windows cmd

Exit 0 on success after verify_utf8.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Allow running as script from any cwd
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from verify_utf8 import verify  # noqa: E402


def normalize_newlines(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Write UTF-8 LF file from stdin")
    parser.add_argument("path", type=Path, help="destination path")
    parser.add_argument(
        "--require-frontmatter",
        action="store_true",
        help="require YAML frontmatter after write",
    )
    args = parser.parse_args()

    raw = sys.stdin.buffer.read()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        print(f"[write_utf8] FAIL: stdin invalid UTF-8: {exc}", file=sys.stderr)
        return 1

    text = normalize_newlines(text)
    args.path.parent.mkdir(parents=True, exist_ok=True)
    # encoding=utf-8 writes without BOM; newline=\n forces LF on Windows
    args.path.write_text(text, encoding="utf-8", newline="\n")

    require_fm = args.require_frontmatter or (
        "requirements" in args.path.as_posix() and args.path.suffix.lower() == ".md"
    )
    issues = verify(args.path, require_fm)
    if issues:
        for item in issues:
            print(f"[write_utf8] FAIL after write: {item}", file=sys.stderr)
        return 1
    print(f"[write_utf8] OK: {args.path.as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
