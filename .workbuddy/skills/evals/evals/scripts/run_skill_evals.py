#!/usr/bin/env python3
"""Skill routing eval: verify description keyword contracts (Perplexity eval-first)."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore

ROOT = Path(__file__).resolve().parents[4]
SKILLS_DIR = ROOT / ".cursor" / "skills"
EVAL_FILE = Path(__file__).resolve().parents[1] / "skill-routing.eval.yaml"

SKILL_PATHS = list(SKILLS_DIR.glob("xijia-*/SKILL.md"))
SKILL_PATHS += [
    SKILLS_DIR / "xijia-feature-pipeline" / "SKILL.md",
    SKILLS_DIR / "xijia-policy-drift-check" / "SKILL.md",
]


def load_descriptions() -> dict[str, str]:
    out: dict[str, str] = {}
    for path in SKILL_PATHS:
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
        m = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
        if not m:
            continue
        fm = m.group(1)
        name = desc = ""
        for line in fm.splitlines():
            if line.startswith("name:"):
                name = line.split(":", 1)[1].strip().strip('"').strip("'")
            elif line.startswith("description:"):
                raw = line.split(":", 1)[1].strip()
                if raw.startswith('"') or raw.startswith("'"):
                    desc = raw.strip('"').strip("'")
                else:
                    desc = raw
        if name and desc:
            out[name] = desc.lower()
    return out


def contains_all(desc: str, tokens: list[str]) -> bool:
    d = desc.lower()
    for t in tokens:
        if t.lower() not in d:
            return False
    return True


def run_case(case: dict, descriptions: dict[str, str]) -> tuple[bool, str]:
    cid = case["id"]
    expect = case.get("expect_skill")
    if expect and expect not in descriptions:
        return False, f"{cid}: skill {expect} not found"
    if expect:
        req = case.get("require_in_description", [])
        desc = descriptions[expect]
        if req and not contains_all(desc, req):
            missing = [t for t in req if t.lower() not in desc]
            return False, f"{cid}: {expect} description missing tokens: {missing}"

    for forbidden in case.get("forbidden_skills", []):
        if forbidden not in descriptions:
            continue
        req = case.get("require_in_description", [])
        if req and contains_all(descriptions[forbidden], req):
            return False, f"{cid}: forbidden {forbidden} also matches all required tokens"

    for forbidden in case.get("forbidden_match_all_in", []):
        if forbidden not in descriptions:
            continue
        user_tokens = re.findall(r"[\w:/.-]+|[\u4e00-\u9fff]{2,}", case["user"].lower())
        if user_tokens and contains_all(descriptions[forbidden], user_tokens[:3]):
            return False, f"{cid}: forbidden {forbidden} matches user keywords"

    return True, f"{cid}: ok ({expect})"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--case")
    args = parser.parse_args()
    if yaml is None:
        print("PyYAML required", file=sys.stderr)
        return 1

    descriptions = load_descriptions()
    cases = yaml.safe_load(EVAL_FILE.read_text(encoding="utf-8")).get("cases", [])
    if args.case:
        cases = [c for c in cases if c["id"] == args.case]

    failed = 0
    for case in cases:
        ok, msg = run_case(case, descriptions)
        print(msg)
        if not ok:
            failed += 1
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
