#!/usr/bin/env python3
"""Scan edited rules, skills and experience docs for unretirable artifacts.

Three independent scans:
1. stack drift — legacy/product stack terms leaking into stack-agnostic rules.
2. defends binding — every rule must name the concrete failure it defends
   against, so that a rule whose failure no longer reproduces can be retired.
   Without this binding a rule can never be judged expired, which is why
   instruction files only ever grow.
3. experience decay binding — every patterns/pitfalls doc must name the code it
   describes and the date it was last confirmed, which is what turns "is this
   still true?" into a computable question in the scoring report.

Skills carry neither binding on purpose: unlike rules, skill loads are visible
to ``log_doc_usage`` through the Read tool, so their retirement evidence is
measured usage rather than a declared failure mode.
"""

from __future__ import annotations

import re
from pathlib import Path

from guardlib.hookio import extract_paths, read_hook_payload
from guardlib.paths import ROOT

RULES_ROOT = (ROOT / ".cursor" / "rules").resolve()
EXPERIENCE_ROOTS = (
    (ROOT / "docs" / "patterns").resolve(),
    (ROOT / "docs" / "pitfalls").resolve(),
)
SCAN_ROOTS = (RULES_ROOT, (ROOT / ".cursor" / "skills").resolve(), *EXPERIENCE_ROOTS)

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
# Kept in sync with score_docs.extract_frontmatter_fields: the gate and the
# staleness report must agree on what counts as a complete experience doc.
LAST_VERIFIED_RE = re.compile(r"^last_verified:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$", re.M)
SOURCE_PATH_RE = re.compile(r"^\s*path:\s*([^\n#]+?)\s*$", re.M)


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
        path.relative_to(RULES_ROOT)
        return True
    except ValueError:
        return False


def _is_experience_doc(path: Path) -> bool:
    """True for patterns/pitfalls entries, excluding index files like README.md."""
    if path.suffix != ".md" or path.stem.lower() == "readme" or path.name.startswith("_"):
        return False
    return any(root in path.parents for root in EXPERIENCE_ROOTS)


def experience_binding_gaps(text: str) -> list[str]:
    """Missing frontmatter fields that would make decay undetectable."""
    frontmatter = FRONTMATTER_RE.match(text)
    body = frontmatter.group(1) if frontmatter else ""
    gaps = []
    if not LAST_VERIFIED_RE.search(body):
        gaps.append("last_verified（YYYY-MM-DD，最后一次确认这条经验仍成立的日期）")
    if not SOURCE_PATH_RE.search(body):
        gaps.append("sources[].path（这条经验描述的代码坐标，用于检测源码变更后是否腐化）")
    return gaps


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
    payload = read_hook_payload()
    if payload is None:
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

        if _is_experience_doc(path):
            gaps = experience_binding_gaps(text)
            if gaps:
                print(f"[experience-scan] {rel} 缺少 frontmatter：{'；'.join(gaps)}")
            continue

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
