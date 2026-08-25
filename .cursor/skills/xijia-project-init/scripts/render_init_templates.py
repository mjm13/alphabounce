#!/usr/bin/env python3
"""Render xijia-project-init templates with UTF-8 safety (Windows-safe).

Usage (from repo root):
  python .cursor/skills/xijia-project-init/scripts/render_init_templates.py \\
    --project-name "指标平台" \\
    --project-goal "..." \\
    --primary-modules "..." \\
    --chosen-stack-summary "..." \\
    --author meijianming \\
    --date 2026-07-29 \\
    --backend-path backend \\
    --frontend-path frontend

Optional seeds (14-digit timestamp, comma-separated types):
  --seed-timestamp 20260729141500 --seeds backend,frontend,runtime

Supplement-only (skip existing outputs):
  --supplement-only
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Common UTF-8 misread-as-GBK mojibake fragments (init regression guard)
_MOJIBAKE_MARKERS = ("鏍囬", "鐘舵€", "鍒嗙骇", "缂洪櫡", "婢勬竻")


def _skill_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _templates_root() -> Path:
    return _skill_root() / "templates"


def _build_replacements(args: argparse.Namespace) -> dict[str, str]:
    return {
        "project_name": args.project_name,
        "project_goal": args.project_goal,
        "primary_modules": args.primary_modules,
        "chosen_stack_summary": args.chosen_stack_summary,
        "author": args.author,
        "date": args.date,
        "backend_path": args.backend_path,
        "frontend_path": args.frontend_path,
        "req_seq": args.seed_timestamp or "",
    }


def _apply_placeholders(text: str, replacements: dict[str, str]) -> str:
    for key, value in replacements.items():
        if value:
            text = text.replace(f"{{{{{key}}}}}", value)
    return text


def _render_file(
    src: Path,
    dst: Path,
    replacements: dict[str, str],
    supplement_only: bool,
) -> str:
    if supplement_only and dst.exists():
        return "skipped"
    text = src.read_text(encoding="utf-8")
    text = _apply_placeholders(text, replacements)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(text, encoding="utf-8", newline="\n")
    return "created"


# Not pre-generated at init (see SKILL.md Manifest — 按需创建)
_EXCLUDE_OUT_REL = {
    "docs/architecture.md",
    "docs/capability-map.md",
    "docs/conventions.md",
    "docs/glossary.md",
    # Copy 骨架 SSOT：.cursor/templates/requirements/（不渲染到 docs/）
    "docs/requirements/requirements-template.md",
    "docs/requirements/technical-requirement-template.md",
    "docs/requirements/defect-template.md",
}


def _iter_doc_templates() -> list[tuple[Path, Path]]:
    """Map templates/**/*.tmpl -> repo-relative output (excludes inbox-seed & optional)."""
    root = _templates_root()
    pairs: list[tuple[Path, Path]] = []
    for src in sorted(root.rglob("*.tmpl")):
        rel = src.relative_to(root)
        if rel.parts[0] == "optional":
            continue
        if "inbox-seed" in rel.parts:
            continue
        if "domain/established" in str(rel).replace("\\", "/"):
            continue
        out_rel = Path(str(rel).removesuffix(".tmpl"))
        if str(out_rel).replace("\\", "/") in _EXCLUDE_OUT_REL:
            continue
        pairs.append((src, out_rel))
    return pairs


_SEED_MAP = {
    "backend": ("docs/requirements/inbox-seed/backend-bootstrap.md.tmpl", "-后端工程初始化.md"),
    "frontend": ("docs/requirements/inbox-seed/frontend-bootstrap.md.tmpl", "-前端工程初始化.md"),
    "runtime": ("docs/requirements/inbox-seed/runtime-baseline.md.tmpl", "-本地运行与CI基线.md"),
}


def _render_seeds(
    repo_root: Path,
    replacements: dict[str, str],
    timestamp: str,
    seed_types: list[str],
    supplement_only: bool,
) -> list[tuple[str, str]]:
    if not timestamp or not seed_types:
        return []
    results: list[tuple[str, str]] = []
    templates_root = _templates_root()
    offset = 0
    for kind in seed_types:
        if kind not in _SEED_MAP:
            print(f"warn: unknown seed type {kind!r}, skip", file=sys.stderr)
            continue
        rel_src, suffix = _SEED_MAP[kind]
        src = templates_root / rel_src
        ts = str(int(timestamp) + offset) if offset else timestamp
        offset += 1
        dst = repo_root / "docs/requirements/inbox" / f"{ts}{suffix}"
        status = _render_file(src, dst, {**replacements, "req_seq": ts}, supplement_only)
        results.append((str(dst.relative_to(repo_root)), status))
    return results


def _encoding_smoke(repo_root: Path, paths: list[Path]) -> list[str]:
    bad: list[str] = []
    for p in paths:
        if not p.exists():
            continue
        sample = p.read_text(encoding="utf-8")[:800]
        if any(m in sample for m in _MOJIBAKE_MARKERS):
            bad.append(str(p.relative_to(repo_root)))
    return bad


def main() -> int:
    parser = argparse.ArgumentParser(description="Render xijia-project-init templates (UTF-8 safe)")
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--supplement-only", action="store_true")
    parser.add_argument("--project-name", required=True)
    parser.add_argument("--project-goal", required=True)
    parser.add_argument("--primary-modules", required=True)
    parser.add_argument("--chosen-stack-summary", required=True)
    parser.add_argument("--author", required=True)
    parser.add_argument("--date", required=True)
    parser.add_argument("--backend-path", default="backend")
    parser.add_argument("--frontend-path", default="frontend")
    parser.add_argument("--seed-timestamp", default="")
    parser.add_argument(
        "--seeds",
        default="",
        help="Comma-separated: backend,frontend,runtime",
    )
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    replacements = _build_replacements(args)
    created: list[str] = []
    skipped: list[str] = []

    for src, out_rel in _iter_doc_templates():
        dst = repo_root / out_rel
        status = _render_file(src, dst, replacements, args.supplement_only)
        rel = str(out_rel)
        if status == "created":
            created.append(rel)
        else:
            skipped.append(rel)

    seed_types = [s.strip() for s in args.seeds.split(",") if s.strip()]
    for rel, status in _render_seeds(
        repo_root, replacements, args.seed_timestamp, seed_types, args.supplement_only
    ):
        if status == "created":
            created.append(rel)
        else:
            skipped.append(rel)

    check_paths = [repo_root / p for p in created if p.endswith(".md")]
    bad = _encoding_smoke(repo_root, check_paths)
    if bad:
        print("encoding-check: FAIL", file=sys.stderr)
        for p in bad:
            print(f"  mojibake suspected: {p}", file=sys.stderr)
        return 1

    print(f"render: created={len(created)} skipped={len(skipped)}")
    for p in created:
        print(f"  + {p}")
    for p in skipped:
        print(f"  ~ {p}")
    print("encoding-check: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
