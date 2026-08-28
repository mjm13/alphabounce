"""Project paths and UTF-8/path helpers."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BACKEND_DIR = "backend"
FRONTEND_DIR = "frontend"
INBOX_DIR = (ROOT / "docs/requirements/inbox").resolve()
SHIPPED_DIR = (ROOT / "docs/requirements/shipped").resolve()
CHANGES_DIR = (ROOT / "docs/openspec/changes").resolve()
ARCHIVE_CHANGES_DIR = (CHANGES_DIR / "archive").resolve()
OBSERVABILITY_DIR = (ROOT / "observability").resolve()
NOTICE_MARKER = OBSERVABILITY_DIR / "pipeline_guard_notice.txt"
DOCS_USAGE_LOG = OBSERVABILITY_DIR / "docs_usage.jsonl"
DOCS_JUDGMENTS_LOG = OBSERVABILITY_DIR / "docs_judgments.jsonl"

CODE_FILE_RE = re.compile(
    r"\.(py|ts|tsx|js|jsx|java|kt|go|rs|cs|php|rb|swift|c|cc|cpp|h|hpp|vue)$",
    re.I,
)
NON_IMPL_RE = re.compile(r"(^|/)(tests?|__tests__)/|(^|/)test_|\.(test|spec)\.|\.md$|\.json$")
NON_IMPL_PREFIXES = (
    ".codebuddy/", "docs/", "document/", f"{FRONTEND_DIR}/node_modules/",
    f"{FRONTEND_DIR}/dist/", f"{BACKEND_DIR}/.venv/", f"{BACKEND_DIR}/logs/",
    "scripts/", "assets/", "mcps/",
)
COMMENT_SYNC_EXCLUDE_RE = re.compile(
    r"(^|/)(__init__\.py|apps\.py|urls\.py|wsgi\.py|asgi\.py|manage\.py|settings\.py|seed_baseline\.py)$|(^|/)migrations/"
)
BACKEND_ENDPOINT_RE = re.compile(
    rf"^{BACKEND_DIR}/.*(/api/|/views\.py$|/controllers?\.py$|/endpoints?\.py$|"
    r"_router\.py$|_admin_service\.py$|/service\.py$)", re.I,
)


def configure_utf8_streams() -> None:
    for stream in (sys.stdin, sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass


def read_utf8_text(path: Path) -> str:
    """Read UTF-8 strictly while accepting an optional BOM."""
    return path.read_text(encoding="utf-8-sig")


def to_rel(path_value: str, root: Path | None = None) -> str | None:
    base = (root or ROOT).resolve()
    candidate = Path(path_value)
    candidate = candidate.resolve() if candidate.is_absolute() else (base / candidate).resolve()
    try:
        return candidate.relative_to(base).as_posix()
    except ValueError:
        return None


def is_impl_code(rel: str) -> bool:
    return bool(CODE_FILE_RE.search(rel)) and not rel.startswith(NON_IMPL_PREFIXES) and not NON_IMPL_RE.search(rel)


def is_comment_sync_code(rel: str) -> bool:
    return (
        is_impl_code(rel)
        and not NON_IMPL_RE.search(rel)
        and not COMMENT_SYNC_EXCLUDE_RE.search(rel)
        and bool(BACKEND_ENDPOINT_RE.search(rel))
    )
