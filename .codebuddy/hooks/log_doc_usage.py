#!/usr/bin/env python3
"""Log harness artifact read events from the Cursor beforeReadFile hook.

Covers three artifact families, all of which the agent loads through the Read
tool and therefore pass through this hook:

- ``doc:``   experience docs, ADRs, living docs — anything under ``docs/``
- ``rule:``  on-demand rules (``alwaysApply: false``) under ``.codebuddy/rules/``
- ``skill:`` model-invoked skills under ``.codebuddy/skills/`` and ``.agents/skills/``

Command-driven skills (``/xijia:*``) are injected by Cursor without a Read call
and are invisible here. ``alwaysApply: true`` rules are injected unconditionally
every turn, so their frequency carries no information and is not collected.

``observability/`` and user-level ``~/.codebuddy/skills-cursor/`` fall outside every
whitelisted root, so they are excluded without any explicit rule.
"""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

from guardlib.hookio import extract_paths, read_hook_payload
from guardlib.paths import DOCS_USAGE_LOG as USAGE_LOG
from guardlib.paths import INBOX_DIR, ROOT

DOCS_ROOT = (ROOT / "docs").resolve()
RULES_ROOT = (ROOT / ".codebuddy/rules").resolve()
SKILLS_ROOTS = (
    (ROOT / ".codebuddy/skills").resolve(),
    (ROOT / ".agents/skills").resolve(),
)

GATE1_APPROVED_RE = re.compile(r"^Gate-1:\s*状态:\s*已批准", re.M)
# Requirement frontmatter sits in the first lines; avoid reading whole files per read event.
FRONTMATTER_PROBE_CHARS = 2000


def _under(candidate: Path, root: Path) -> bool:
    return candidate == root or root in candidate.parents


def _classify_skill(candidate: Path, skills_root: Path) -> tuple[str, str] | None:
    """Map a file to its owning skill by the nearest ancestor holding SKILL.md.

    Nested packs (``element-plus-skills/components/el-button/SKILL.md``) must
    resolve to the leaf skill, not the pack, so the walk stops at the first
    ancestor that actually declares a skill.

    Only a ``references/`` read counts as a strong signal: reaching for a skill's
    step-by-step material means it is actually being followed. Reading SKILL.md
    or a skill's own scripts is just as likely to be diagnosis or maintenance.
    """
    for parent in candidate.parents:
        if parent == skills_root:
            break
        if (parent / "SKILL.md").is_file():
            skill_id = parent.relative_to(skills_root).as_posix()
            following = (parent / "references") in candidate.parents
            return f"skill:{skill_id}", "strong" if following else "weak"
    return None


def _classify(path_value: str) -> tuple[str, str | None, str | None] | None:
    """Return ``(artifact, doc, signal)`` for a read path, or None when out of scope.

    ``doc`` stays populated only for ``docs/`` paths: ``closeout.load_usage_sessions``
    and ``score_docs`` both key off it, so keeping it untouched preserves them.
    """
    candidate = Path(path_value)
    candidate = candidate.resolve() if candidate.is_absolute() else (ROOT / candidate).resolve()

    if _under(candidate, DOCS_ROOT):
        doc = f"docs/{candidate.relative_to(DOCS_ROOT).as_posix()}"
        return f"doc:{doc}", doc, None

    if _under(candidate, RULES_ROOT):
        return f"rule:{candidate.relative_to(RULES_ROOT).as_posix()}", None, None

    for skills_root in SKILLS_ROOTS:
        if _under(candidate, skills_root):
            classified = _classify_skill(candidate, skills_root)
            if classified:
                artifact, signal = classified
                return artifact, None, signal
            return None
    return None


def _inflight_stem() -> str | None:
    """Stem of the requirement currently in implementation, or None.

    ``closeout.reuse_logging_gaps`` matches usage sessions against a requirement
    stem; a Cursor conversation UUID can never match it, which left every usage
    event invisible to the only consumer that reads them.
    """
    if not INBOX_DIR.is_dir():
        return None
    approved: list[Path] = []
    for path in INBOX_DIR.glob("*.md"):
        if path.stem.lower() == "readme":
            continue
        try:
            head = path.read_text(encoding="utf-8-sig", errors="ignore")[:FRONTMATTER_PROBE_CHARS]
        except OSError:
            continue
        if GATE1_APPROVED_RE.search(head):
            approved.append(path)
    if not approved:
        return None
    return max(approved, key=lambda path: path.stat().st_mtime).stem


def _allow() -> int:
    """Emit the beforeReadFile contract. Logging must never block a read."""
    print(json.dumps({"permission": "allow"}))
    return 0


def main() -> int:
    payload = read_hook_payload()
    if payload is None:
        return _allow()

    path_values = extract_paths(payload)
    if not path_values:
        return _allow()

    classified = _classify(path_values[0])
    if not classified:
        return _allow()
    artifact, doc, signal = classified

    stem = _inflight_stem()
    event = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "artifact": artifact,
        "source": "hook",
        "session": stem,
        "scope": "in-flow" if stem else "out-of-flow",
        # The hook cannot tell which requirement this conversation is about, so it
        # attributes every read to whatever sits in the inbox. Recording the
        # conversation makes that ambiguity visible: several conversation ids under
        # one stem means the attribution is a guess, not a fact.
        "conversation": payload.get("conversation_id") or payload.get("session_id"),
    }
    if doc:
        event["doc"] = doc
    if signal:
        event["signal"] = signal

    USAGE_LOG.parent.mkdir(parents=True, exist_ok=True)
    with USAGE_LOG.open("a", encoding="utf-8") as file:
        file.write(json.dumps(event, ensure_ascii=False) + "\n")
    return _allow()


if __name__ == "__main__":
    raise SystemExit(main())
