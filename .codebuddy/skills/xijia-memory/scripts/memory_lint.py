#!/usr/bin/env python3
"""Lint memory decisions jsonl."""
from __future__ import annotations
import json
from pathlib import Path

PATH = Path("docs/memory/decisions.jsonl")
REQUIRED = ("ts", "source", "decision", "result", "confidence")


def main() -> int:
    if not PATH.exists():
        print("memory_lint: file not found")
        return 1
    errors = 0
    for idx, line in enumerate(PATH.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            print(f"line {idx}: invalid json")
            errors += 1
            continue
        for key in REQUIRED:
            if key not in row:
                print(f"line {idx}: missing {key}")
                errors += 1
        conf = row.get("confidence")
        if conf is not None and not isinstance(conf, (int, float)):
            print(f"line {idx}: confidence must be number")
            errors += 1
    if errors:
        print(f"memory_lint: FAIL ({errors})")
        return 1
    print("memory_lint: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
