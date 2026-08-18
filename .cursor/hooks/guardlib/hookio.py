"""Cursor hook payload helpers."""

from __future__ import annotations

from typing import Any

PATH_KEYS = ("path", "file_path", "relativePath", "filePath", "target_file", "oldPath", "newPath")
NESTED_KEYS = ("input", "arguments", "data", "payload", "tool_input", "edits", "changes")


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
