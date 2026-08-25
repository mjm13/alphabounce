"""Hook stdin decoding: a BOM plus a non-UTF-8 locale must not silence hooks.

Regression for 2026-08-19: Cursor writes hook payloads as UTF-8 with a BOM. The
hooks read them through the text ``sys.stdin`` wrapper, which decodes with the
machine locale (GBK on zh-CN Windows). The BOM and the leading brace merged into
one mojibake character, ``json.loads`` raised, and every hook took its silent
"allow / return 0" branch — exit code 0 with no side effect, for a whole day.
"""

from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import log_doc_usage  # noqa: E402
from guardlib.hookio import read_hook_payload  # noqa: E402

BOM = b"\xef\xbb\xbf"
PAYLOAD = {
    "file_path": "D:\\repo\\docs\\llms.txt",
    "content": "# 中文内容",
    "session_id": "s-1",
    "hook_event_name": "beforeReadFile",
}


class _Stdin:
    """Minimal stdin double exposing only the binary buffer, as hooks require."""

    def __init__(self, data: bytes) -> None:
        self.buffer = io.BytesIO(data)


def _stdin_bytes(data: bytes):
    return mock.patch.object(sys, "stdin", _Stdin(data))


def _encode(payload: dict) -> bytes:
    return json.dumps(payload, ensure_ascii=False).encode("utf-8")


class ReadHookPayloadTests(unittest.TestCase):
    def test_utf8_with_bom_is_parsed(self) -> None:
        with _stdin_bytes(BOM + _encode(PAYLOAD)):
            self.assertEqual(read_hook_payload(), PAYLOAD)

    def test_utf8_without_bom_is_parsed(self) -> None:
        with _stdin_bytes(_encode(PAYLOAD)):
            self.assertEqual(read_hook_payload(), PAYLOAD)

    def test_empty_stdin_yields_empty_payload(self) -> None:
        with _stdin_bytes(b""):
            self.assertEqual(read_hook_payload(), {})

    def test_malformed_json_yields_none(self) -> None:
        with _stdin_bytes(b"not json"):
            self.assertIsNone(read_hook_payload())

    def test_non_object_payload_yields_none(self) -> None:
        with _stdin_bytes(b"[1, 2]"):
            self.assertIsNone(read_hook_payload())


class LogDocUsageHookTests(unittest.TestCase):
    def test_bom_payload_still_reaches_the_usage_log(self) -> None:
        payload = {**PAYLOAD, "file_path": str(log_doc_usage.DOCS_ROOT / "llms.txt")}

        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp) / "docs_usage.jsonl"
            stdout = io.StringIO()
            with _stdin_bytes(BOM + _encode(payload)), mock.patch.object(
                log_doc_usage, "USAGE_LOG", log
            ), mock.patch.object(
                log_doc_usage, "_inflight_stem", lambda: "20260729123456-demo"
            ), mock.patch.object(sys, "stdout", stdout):
                rc = log_doc_usage.main()

            events = [json.loads(line) for line in log.read_text(encoding="utf-8").splitlines()]

        self.assertEqual(rc, 0)
        self.assertEqual(json.loads(stdout.getvalue()), {"permission": "allow"})
        self.assertEqual([event["doc"] for event in events], ["docs/llms.txt"])


if __name__ == "__main__":
    unittest.main()
