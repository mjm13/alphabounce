#!/usr/bin/env python3
"""Audit xijia-* skill metrics: description budget, body size, negation, disclosure."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SKILLS_DIR = ROOT / ".cursor" / "skills"

WF_IN_DESC = re.compile(
    r"(Orchestrates|Outputs|步骤摘要|End-to-end|alias\s*—)",
    re.I,
)
NEG = re.compile(r"(禁止|不得|不要|Never|Do not|MUST NOT)", re.I)
DONE = re.compile(r"(完成：|完成标准|completion criterion|verify:|exit 0|硬停)", re.I)


def parse_skill(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
    lines = text.count("\n") + 1
    name = path.parent.name
    desc = ""
    m = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if m:
        for line in m.group(1).splitlines():
            if line.startswith("name:"):
                name = line.split(":", 1)[1].strip().strip('"').strip("'")
            elif line.startswith("description:"):
                raw = line.split(":", 1)[1].strip()
                desc = raw.strip('"').strip("'")
    refs = [
        f
        for f in path.parent.rglob("*")
        if f.is_file()
        and f.name != "SKILL.md"
        and "__pycache__" not in f.parts
        and f.suffix != ".pyc"
    ]
    has_refs_dir = (path.parent / "references").is_dir()
    return {
        "name": name,
        "path": str(path.relative_to(ROOT)).replace("\\", "/"),
        "lines": lines,
        "desc_chars": len(desc),
        "desc": desc,
        "wf_in_desc": bool(WF_IN_DESC.search(desc)),
        "negations": len(NEG.findall(text)),
        "done_hints": len(DONE.findall(text)),
        "extra_files": len(refs),
        "has_references_dir": has_refs_dir,
        "over_desc_120": len(desc) > 120,
        "over_body_100": lines > 100,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    parser.add_argument(
        "--fail-over-desc",
        action="store_true",
        help="Exit 1 if any description > 120 chars",
    )
    args = parser.parse_args()

    rows = [parse_skill(p) for p in sorted(SKILLS_DIR.glob("xijia-*/SKILL.md"))]
    if not rows:
        print("No xijia-*/SKILL.md found", file=sys.stderr)
        return 1

    total_desc = sum(r["desc_chars"] for r in rows)
    over_desc = [r for r in rows if r["over_desc_120"]]
    over_body = sorted([r for r in rows if r["over_body_100"]], key=lambda x: -x["lines"])
    top_neg = sorted(rows, key=lambda x: -x["negations"])[:8]
    wf = [r for r in rows if r["wf_in_desc"]]

    report = {
        "count": len(rows),
        "total_desc_chars": total_desc,
        "avg_desc_chars": total_desc // len(rows),
        "over_desc_120": [{"name": r["name"], "desc_chars": r["desc_chars"]} for r in over_desc],
        "over_body_100": [
            {
                "name": r["name"],
                "lines": r["lines"],
                "extra_files": r["extra_files"],
                "has_references_dir": r["has_references_dir"],
            }
            for r in over_body
        ],
        "workflow_in_desc": [r["name"] for r in wf],
        "top_negation": [{"name": r["name"], "negations": r["negations"]} for r in top_neg],
        "skills": rows,
    }

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"xijia skills: {report['count']}")
        print(f"total_desc_chars: {total_desc}  avg: {report['avg_desc_chars']}")
        print()
        print("OVER_DESC_120:")
        if not over_desc:
            print("  (none)")
        for r in over_desc:
            print(f"  {r['name']}: {r['desc_chars']}  wf_in_desc={r['wf_in_desc']}")
            print(f"    {r['desc']}")
        print()
        print("OVER_BODY_100:")
        if not over_body:
            print("  (none)")
        for r in over_body:
            print(
                f"  {r['name']}: lines={r['lines']} extras={r['extra_files']} "
                f"refs_dir={r['has_references_dir']} neg={r['negations']} done={r['done_hints']}"
            )
        print()
        print("WORKFLOW_IN_DESC:", ", ".join(report["workflow_in_desc"]) or "(none)")
        print("TOP_NEGATION:")
        for r in top_neg:
            if r["negations"] == 0:
                continue
            print(f"  {r['name']}: {r['negations']}")

    if args.fail_over_desc and over_desc:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
