#!/usr/bin/env python3
"""Prune expired memory entries by moving them to an archive file.

auto_archive semantics: expired rows are MOVED from decisions.jsonl to
decisions.archive.jsonl (never physically deleted). Rows without a parseable
`staleness` are kept in the main file (treated as never-expiring).
"""
from __future__ import annotations
import json
import re
from datetime import datetime, timezone
from pathlib import Path

MAIN = Path("docs/memory/decisions.jsonl")
ARCHIVE = Path("docs/memory/decisions.archive.jsonl")

_STALENESS_UNITS = {"d": 1, "w": 7, "m": 30, "y": 365}


def parse_staleness_days(value: object) -> int | None:
    """Return staleness in days, or None if absent/unparseable (never expire)."""
    if not isinstance(value, str):
        return None
    match = re.fullmatch(r"\s*(\d+)\s*([dwmy])\s*", value.lower())
    if not match:
        return None
    return int(match.group(1)) * _STALENESS_UNITS[match.group(2)]


def parse_ts(value: object) -> datetime | None:
    if not isinstance(value, str):
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def is_expired(row: dict, now: datetime) -> bool:
    days = parse_staleness_days(row.get("staleness"))
    if days is None:
        return False
    ts = parse_ts(row.get("ts"))
    if ts is None:
        return False
    return (now - ts).total_seconds() > days * 86400


def main() -> int:
    if not MAIN.exists():
        print("memory_prune: SKIP (not initialized; expected for base template repo)")
        return 0

    now = datetime.now(timezone.utc)
    kept: list[str] = []
    archived: list[str] = []
    malformed = 0

    for line in MAIN.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            kept.append(line)
            malformed += 1
            continue
        if is_expired(row, now):
            archived.append(line)
        else:
            kept.append(line)

    if not archived:
        print(f"memory_prune: PASS (archived 0, kept {len(kept)}, malformed {malformed})")
        return 0

    with ARCHIVE.open("a", encoding="utf-8") as fh:
        for line in archived:
            fh.write(line + "\n")

    MAIN.write_text(
        ("\n".join(kept) + "\n") if kept else "",
        encoding="utf-8",
    )

    print(
        f"memory_prune: PASS (archived {len(archived)} -> {ARCHIVE}, "
        f"kept {len(kept)}, malformed {malformed})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
