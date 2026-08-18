#!/usr/bin/env python3
"""Log docs read events from Cursor beforeReadFile hook."""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from guardlib.hookio import extract_paths
from guardlib.paths import DOCS_USAGE_LOG as USAGE_LOG
from guardlib.paths import ROOT

DOCS_ROOT = (ROOT / "docs").resolve()


def _resolve_doc(path_value: str) -> str | None:
    candidate = Path(path_value)
    if not candidate.is_absolute():
        candidate = (ROOT / candidate).resolve()
    else:
        candidate = candidate.resolve()
    try:
        rel = candidate.relative_to(DOCS_ROOT)
    except ValueError:
        return None
    return f"docs/{rel.as_posix()}"


def _extract_session(payload: Any) -> str | None:
    if not isinstance(payload, dict):
        return None
    for key in ("session_id", "sessionId", "conversation_id", "conversationId", "chat_id", "chatId"):
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    for nested_key in ("input", "arguments", "data", "payload", "tool_input"):
        nested = payload.get(nested_key)
        candidate = _extract_session(nested)
        if candidate:
            return candidate
    return None


def _allow() -> int:
    """Emit the beforeReadFile contract. Logging must never block a read."""
    print(json.dumps({"permission": "allow"}))
    return 0


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return _allow()

    path_values = extract_paths(payload)
    if not path_values:
        return _allow()

    doc = _resolve_doc(path_values[0])
    if not doc:
        return _allow()

    USAGE_LOG.parent.mkdir(parents=True, exist_ok=True)
    event = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "doc": doc,
        "source": "hook",
        "session": _extract_session(payload),
    }
    with USAGE_LOG.open("a", encoding="utf-8") as file:
        file.write(json.dumps(event, ensure_ascii=False) + "\n")
    return _allow()


if __name__ == "__main__":
    raise SystemExit(main())
