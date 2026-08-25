#!/usr/bin/env python3
"""Verify a text file is strict UTF-8 (optional BOM), LF-preferred, no U+FFFD.

Usage:
  python verify_utf8.py <path> [--require-frontmatter]

Exit 0 on success; non-zero with message on failure.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def verify(path: Path, require_frontmatter: bool) -> list[str]:
    issues: list[str] = []
    if not path.is_file():
        return [f"not a file: {path}"]

    raw = path.read_bytes()
    if not raw:
        return []

    has_bom = raw.startswith(b"\xef\xbb\xbf")
    body = raw[3:] if has_bom else raw

    try:
        text = body.decode("utf-8")
    except UnicodeDecodeError as exc:
        return [f"invalid UTF-8 at offset {exc.start}: {exc.reason}"]

    if "\ufffd" in text:
        issues.append("contains U+FFFD (replacement character); file may be corrupted")

    # CRLF: warn only (existing Windows checkouts may still have CRLF until re-normalized)
    if "\r" in text:
        print(
            f"[verify_utf8] WARN: CR/CRLF present on {path.as_posix()}; prefer LF "
            "(see .gitattributes eol=lf)",
            file=sys.stderr,
        )

    # Literal backtick-n left by broken PowerShell string replace (e.g. "`n- Living")
    if path.suffix.lower() == ".md" and "`n-" in text:
        issues.append(
            "suspicious literal `n- sequences (possible PowerShell newline corruption)"
        )

    check_fm = require_frontmatter or (
        path.suffix.lower() == ".md" and "requirements" in path.as_posix()
    )
    if check_fm:
        stripped = text.lstrip("\ufeff")
        if not stripped.startswith("---"):
            issues.append("frontmatter does not start with --- (after optional BOM)")

    if has_bom:
        # informational: guard accepts BOM; new writes should avoid it
        print(f"[verify_utf8] WARN: UTF-8 BOM present on {path.as_posix()}", file=sys.stderr)

    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify UTF-8 text file integrity")
    parser.add_argument("path", type=Path, help="file to verify")
    parser.add_argument(
        "--require-frontmatter",
        action="store_true",
        help="require YAML frontmatter starting with ---",
    )
    args = parser.parse_args()
    issues = verify(args.path, args.require_frontmatter)
    if issues:
        for item in issues:
            print(f"[verify_utf8] FAIL: {item}", file=sys.stderr)
        return 1
    print(f"[verify_utf8] OK: {args.path.as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
