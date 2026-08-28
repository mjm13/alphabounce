"""Cursor hook payload helpers."""

from __future__ import annotations

import json
import sys
from typing import Any

PATH_KEYS = ("path", "file_path", "relativePath", "filePath", "target_file", "oldPath", "newPath")
NESTED_KEYS = ("input", "arguments", "data", "payload", "tool_input", "edits", "changes")


def read_hook_payload() -> dict[str, Any] | None:
    """Decode the Cursor hook payload from stdin, or None when unusable.

    Cursor writes the payload as UTF-8 with a BOM. Reading it through the text
    ``sys.stdin`` wrapper decodes with the machine locale (GBK on zh-CN Windows),
    which turns the BOM plus the leading brace into mojibake and makes every hook
    fail parsing while still exiting 0 — a silent no-op. Read bytes and decode
    ``utf-8-sig`` so the payload survives regardless of locale.
    """
    try:
        raw = sys.stdin.buffer.read().decode("utf-8-sig", errors="replace")
    except (AttributeError, OSError, ValueError):
        return None
    try:
        payload = json.loads(raw or "{}")
    except json.JSONDecodeError:
        return None
    return payload if isinstance(payload, dict) else None


def extract_paths(payload: Any) -> list[str]:
    found: list[str] = []
    if isinstance(payload, dict):
        found.extend(
            value.strip()
            for key in PATH_KEYS
            if isinstance((value := payload.get(key)), str) and value.strip()
        )
        for key in NESTED_KEYS:
            found.extend(extract_paths(payload.get(key)))
    elif isinstance(payload, list):
        for item in payload:
            found.extend(extract_paths(item))
    return found
