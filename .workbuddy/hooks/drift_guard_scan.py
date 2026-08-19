#!/usr/bin/env python3
"""Scan updated rules/skills files for stack drift terms and unbound rules.

Two independent scans:
1. stack drift — legacy/product stack terms leaking into stack-agnostic rules.
2. defends binding — every rule must name the concrete failure it defends
   against, so that a rule whose failure no longer reproduces can be retired.
   Without this binding a rule can never be judged expired, which is why
   instruction files only ever grow.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from guardlib.hookio import extract_paths
from guardlib.paths import ROOT

SCAN_ROOTS = (
    (ROOT / ".cursor" / "rules").resolve(),
    (ROOT / ".cursor" / "skills").resolve(),
)

# Legacy / wrong-stack terms: scan both rules and skills.
LEGACY_DRIFT_RE = re.compile(
    r"Flyway|MyBatis|Spring|JUnit|@SpringBootTest|Mapper|Maven|BCrypt|Vitest|vite\.config"
)

# Current product-stack terms: rules must stay stack-agnostic; skills may hold stack detail.
# Only applied under .cursor/rules (except the blacklist rule file itself).
PRODUCT_DRIFT_RE = re.compile(
    r"FastAPI|uvicorn|SQLAlchemy|Alembic|pytest-asyncio|fakeredis|"
    r"\bVue\b|Vue3|Pinia|Element Plus|element-plus|ElementPlus|"
    r"Playwright|Iconify|OpenTelemetry|"
    r"\bReact\b|\bDjango\b|\bFlask\b"
)

RULES_SKIP = {
    (ROOT / ".cursor" / "rules" / "06-rule-drift-guard.mdc").resolve(),
}

FRONTMATTER_RE = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.S)
DEFENDS_RE = re.compile(r"^defends:\s*(\S.*?)\s*$", re.M)


def _normalize(path_value: str) -> Path | None:
    candidate = Path(path_value)
    if not candidate.is_absolute():
        candidate = (ROOT / candidate).resolve()
    else:
        candidate = candidate.resolve()
    for scan_root in SCAN_ROOTS:
        try:
            candidate.relative_to(scan_root)
            return candidate
        except ValueError:
            continue
    return None


def _is_under_rules(path: Path) -> bool:
    try:
        path.relative_to((ROOT / ".cursor" / "rules").resolve())
        return True
    except ValueError:
        return False


def missing_defends(text: str) -> bool:
    """True when the rule does not name the failure it defends against."""
    frontmatter = FRONTMATTER_RE.match(text)
    if not frontmatter:
        return True
    value = DEFENDS_RE.search(frontmatter.group(1))
    if value is None:
        return True
    return value.group(1).strip('"\'' ) == ""


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return 0

    checked: set[Path] = set()
    for raw_path in extract_paths(payload):
        path = _normalize(raw_path)
        if path is None or path in checked or not path.is_file():
            continue
        checked.add(path)
        text = path.read_text(encoding="utf-8", errors="ignore")
        rel = path.relative_to(ROOT).as_posix()

        if _is_under_rules(path) and path.suffix == ".mdc" and missing_defends(text):
            print(
                f"[defends-scan] {rel} 缺少 frontmatter `defends:`："
                "写清这条规则防的是哪个具体失败（含出处），否则无法判断它何时该删"
            )

        if path in RULES_SKIP:
            continue
        hits = set(LEGACY_DRIFT_RE.findall(text))
        if _is_under_rules(path):
            hits.update(PRODUCT_DRIFT_RE.findall(text))
        if hits:
            print(f"[drift-scan] potential stack term in {rel}: {', '.join(sorted(hits))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
