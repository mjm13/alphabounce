#!/usr/bin/env python3
"""Extract capability-map rows from requirement closure tables with merge semantics.

Row primary key: normalize(moduleKey) + normalize(frontend_entry).

Operations: ADD | UPDATE | SUPERSEDE | RENAME | DEPRECATE | MERGE | SKIP
Default mode is --merge (no blind append).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from datetime import date
from pathlib import Path
from typing import Any

from guardlib.markdown import (
    FrontmatterError,
    cell as _cell,
    extract_section as _extract_markdown_section,
    find_col as _find_col,
    find_table as _find_table,
    parse_frontmatter,
)
from guardlib.paths import ROOT, configure_utf8_streams
from guardlib.requirement import (
    parse_closure_table as parse_requirement_closure_table,
    parse_frontmatter_tier,
    parse_frontmatter_type,
)

configure_utf8_streams()

_GREEN_TRIVIAL_RE = re.compile(
    r"^(?:本需求|缺陷修复)无(?:新增|业务)?数据流"
    r"[（(]green-trivial[）)][。.]?$",
    re.IGNORECASE | re.MULTILINE,
)
_CONFIRMED_RE = re.compile(r"已确认|confirmed", re.I)

CAPABILITY_MAP_REL = "docs/capability-map.md"

def _is_seed_requirement(path: Path) -> bool:
    """Identify engineering seeds from the canonical YAML property."""
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False
    return (parse_frontmatter(text) or {}).get("种子", "").strip().lower() == "true"


@dataclass
class ClosureRow:
    name: str
    source: str
    process: str
    sink: str
    closure: str
    frontend: str = ""
    table: str = ""


@dataclass
class CapabilityRow:
    module: str
    module_key: str
    frontend: str
    backend: str
    table: str
    source_summary: str
    sink_summary: str
    status: str
    req_source: str

    def primary_key(self) -> str:
        return f"{normalize_key(self.module_key)}|{normalize_key(self.frontend)}"


@dataclass
class RevisionEntry:
    date: str
    operation: str
    primary_key: str
    req_source: str
    note: str


@dataclass
class MergeAction:
    operation: str
    primary_key: str
    before: dict[str, str] | None
    after: dict[str, str]
    note: str = ""


@dataclass
class ExtractResult:
    req_path: str
    eligible: bool
    skip_reason: str = ""
    closure_rows: list[ClosureRow] = field(default_factory=list)
    proposed: list[CapabilityRow] = field(default_factory=list)
    actions: list[MergeAction] = field(default_factory=list)
    cross_module_hints: list[dict[str, str]] = field(default_factory=list)


def normalize_key(value: str) -> str:
    text = (value or "").strip().lower()
    text = re.sub(r"\s+", " ", text)
    text = re.sub(r"[\\/]+", "/", text)
    return text


def truncate(text: str, limit: int = 80) -> str:
    text = re.sub(r"\s+", " ", (text or "").strip())
    if len(text) <= limit:
        return text
    return text[: limit - 1] + "…"


def _parse_frontmatter(text: str) -> dict[str, str]:
    return parse_frontmatter(text) or {}


def parse_closure_table(text: str) -> list[ClosureRow] | None:
    rows = parse_requirement_closure_table(text)
    if rows is None:
        return None
    return [ClosureRow(**row) for row in rows]


def infer_module_key(text: str, capability_name: str) -> tuple[str, str]:
    """Return (module_label, module_key)."""
    fm = _parse_frontmatter(text)
    for key in ("模块", "module", "bc", "限界上下文"):
        if fm.get(key):
            label = fm[key]
            return label, slugify(label)

    scope = _extract_markdown_section(text, "范围与切片") or ""
    for line in scope.splitlines():
        if re.search(r"BC|限界上下文|模块", line, re.I):
            m = re.search(r"[：:]\s*([^\s|，,]+)", line)
            if m:
                label = m.group(1).strip()
                return label, slugify(label)

    constraint = _extract_markdown_section(text, "约束引用") or ""
    for line in constraint.splitlines():
        if "|" in line and not line.strip().startswith("| --"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if len(cells) >= 2 and cells[0] not in ("类型", "—", "-"):
                for ctx in cells[:2]:
                    if ctx.startswith("docs/") or "domain" in ctx or "BC" in ctx or "/" in ctx:
                        part = Path(ctx).stem.replace("-", " ")
                        return part, slugify(part)

    proto = _extract_markdown_section(text, "原型对齐与偏离") or ""
    for line in proto.splitlines():
        if "页面" in line or "菜单" in line or "模块" in line:
            m = re.search(r"[：:]\s*([^\s|]+)", line)
            if m:
                label = m.group(1).strip()
                return label, slugify(label)

    prefix = capability_name.split("-")[0].split("_")[0].strip()
    if prefix and prefix not in ("(未命名能力)", "<能力A>"):
        return prefix, slugify(prefix)

    return "general", "general"


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[\s_]+", "-", text)
    text = re.sub(r"[^\w\u4e00-\u9fff\-]+", "", text)
    return text or "general"


def infer_frontend_entry(text: str, capability_name: str) -> str:
    proto = _extract_markdown_section(text, "原型对齐与偏离") or ""
    for line in proto.splitlines():
        if capability_name[:4] in line or capability_name in line:
            m = re.search(r"`([^`]+)`", line)
            if m:
                return m.group(1)
    impl = _extract_markdown_section(text, "实现记录") or ""
    for line in impl.splitlines():
        if "[前端路径]" in line or "前端路径" in line:
            m = re.search(r"[：:]\s*(\S+)", line)
            if m:
                return m.group(1)
    return slugify(capability_name) or capability_name


def infer_table_from_sink(sink: str) -> str:
    m = re.search(r"`?([a-zA-Z_][\w]*)`?", sink)
    if m and len(m.group(1)) > 2:
        return m.group(1)
    return truncate(sink, 40)


def is_eligible_requirement(text: str, path: Path) -> tuple[bool, str]:
    tier = parse_frontmatter_tier(text) or ""
    req_type = parse_frontmatter_type(text) or ""

    if tier == "green-trivial":
        return False, "green-trivial"
    if _GREEN_TRIVIAL_RE.search(text):
        return False, "no-dataflow-declared"
    if req_type == "technical":
        return False, "technical-only"

    rows = parse_closure_table(text)
    if rows is None or not rows:
        return False, "no-closure-table"

    confirmed = [r for r in rows if _CONFIRMED_RE.search(r.closure)]
    if not confirmed:
        return False, "no-confirmed-rows"

    return True, ""


def closure_to_capability(text: str, req_rel: str, row: ClosureRow) -> CapabilityRow:
    module_label, module_key = infer_module_key(text, row.name)
    frontend = (row.frontend or "").strip() or infer_frontend_entry(text, row.name)
    table = (row.table or "").strip() or infer_table_from_sink(row.sink)
    return CapabilityRow(
        module=module_label,
        module_key=module_key,
        frontend=frontend,
        backend=truncate(row.process or row.source, 60),
        table=table,
        source_summary=truncate(row.source, 80),
        sink_summary=truncate(row.sink, 80),
        status="active",
        req_source=req_rel,
    )


def parse_capability_map(path: Path) -> tuple[list[CapabilityRow], list[RevisionEntry]]:
    if not path.is_file():
        return [], []
    text = path.read_text(encoding="utf-8", errors="ignore")
    table = _find_table(text, ("moduleKey",))
    if table is None:
        return [], []
    header_cells, table_rows = table

    cols = {
        "module": _find_col(header_cells, ("模块",)),
        "module_key": _find_col(header_cells, ("moduleKey", "module_key")),
        "frontend": _find_col(header_cells, ("前端入口", "frontend")),
        "backend": _find_col(header_cells, ("后端能力", "backend")),
        "table": _find_col(header_cells, ("相关表", "table")),
        "source_summary": _find_col(header_cells, ("来源摘要", "source")),
        "sink_summary": _find_col(header_cells, ("去向摘要", "sink")),
        "status": _find_col(header_cells, ("状态", "status")),
        "req_source": _find_col(header_cells, ("需求来源", "req")),
    }

    rows: list[CapabilityRow] = []
    for cells in table_rows:
        if cells[0].startswith("<"):
            continue
        rows.append(
            CapabilityRow(
                module=_cell(cells, cols["module"]),
                module_key=_cell(cells, cols["module_key"]),
                frontend=_cell(cells, cols["frontend"]),
                backend=_cell(cells, cols["backend"]),
                table=_cell(cells, cols["table"]),
                source_summary=_cell(cells, cols["source_summary"]),
                sink_summary=_cell(cells, cols["sink_summary"]),
                status=_cell(cells, cols["status"]) or "active",
                req_source=_cell(cells, cols["req_source"]),
            )
        )

    revisions: list[RevisionEntry] = []
    revision_table = _find_table(text, ("操作", "需求来源", "说明"))
    if revision_table:
        _, revision_rows = revision_table
        revisions = [
            RevisionEntry(
                date=cells[0],
                operation=cells[1],
                primary_key=cells[2].replace("&#124;", "|"),
                req_source=cells[3],
                note=cells[4],
            )
            for cells in revision_rows
            if len(cells) >= 5
        ]
    return rows, revisions


def row_to_dict(row: CapabilityRow) -> dict[str, str]:
    return asdict(row)


def compute_merge_actions(
    existing: dict[str, CapabilityRow],
    incoming: list[CapabilityRow],
    req_source: str,
) -> list[MergeAction]:
    actions: list[MergeAction] = []
    today = date.today().isoformat()

    for inc in incoming:
        pk = inc.primary_key()
        if pk not in existing:
            actions.append(
                MergeAction("ADD", pk, None, row_to_dict(inc), f"new capability from {req_source}")
            )
            existing[pk] = inc
            continue

        cur = existing[pk]
        changed = any(
            getattr(cur, f) != getattr(inc, f)
            for f in (
                "backend",
                "table",
                "source_summary",
                "sink_summary",
                "module",
                "module_key",
            )
        )
        if not changed:
            actions.append(
                MergeAction("SKIP", pk, row_to_dict(cur), row_to_dict(cur), "no column change")
            )
            continue

        updated = CapabilityRow(
            module=inc.module or cur.module,
            module_key=inc.module_key or cur.module_key,
            frontend=inc.frontend or cur.frontend,
            backend=inc.backend or cur.backend,
            table=inc.table or cur.table,
            source_summary=inc.source_summary or cur.source_summary,
            sink_summary=inc.sink_summary or cur.sink_summary,
            status=cur.status if cur.status else "active",
            req_source=req_source,
        )
        actions.append(
            MergeAction(
                "UPDATE",
                pk,
                row_to_dict(cur),
                row_to_dict(updated),
                f"columns changed via {req_source}",
            )
        )
        existing[pk] = updated

    return actions


def render_capability_map(rows: list[CapabilityRow], revisions: list[RevisionEntry]) -> str:
    lines = [
        "# 能力追溯索引（Capability Map）",
        "",
        "> 行主键：`moduleKey` + `前端入口`（normalize 后）。Gate-3 **动态合并**（ADD/UPDATE/DEPRECATE），禁止同主键重复行。",
        "> 操作级细节真相源：各 `docs/requirements/shipped/*` 需求「数据流闭环表」。",
        "",
        "| 模块 | moduleKey | 前端入口 | 后端能力 | 相关表 | 来源摘要 | 去向摘要 | 状态 | 需求来源 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for r in sorted(rows, key=lambda x: (x.module_key, x.frontend)):
        lines.append(
            f"| {r.module} | {r.module_key} | {r.frontend} | {r.backend} | {r.table} | "
            f"{r.source_summary} | {r.sink_summary} | {r.status or 'active'} | {r.req_source} |"
        )
    lines.extend(["", "## 修订记录", "", "| 日期 | 操作 | 主键 | 需求来源 | 说明 |", "| --- | --- | --- | --- | --- |"])
    for rev in revisions[-200:]:
        lines.append(
            f"| {rev.date} | {rev.operation} | {rev.primary_key.replace('|', '&#124;')} | "
            f"{rev.req_source} | {rev.note} |"
        )
    lines.append("")
    return "\n".join(lines)


def extract_from_requirement(req_path: Path, root: Path = ROOT) -> ExtractResult:
    req_path = req_path.resolve() if req_path.is_absolute() else (root / req_path).resolve()
    try:
        rel = req_path.relative_to(root).as_posix()
    except ValueError:
        rel = str(req_path)
    text = req_path.read_text(encoding="utf-8-sig")

    eligible, reason = is_eligible_requirement(text, req_path)
    result = ExtractResult(req_path=rel, eligible=eligible, skip_reason=reason)
    if not eligible:
        return result

    closure_rows = parse_closure_table(text) or []
    confirmed = [r for r in closure_rows if _CONFIRMED_RE.search(r.closure)]
    result.closure_rows = confirmed

    shipped_rel = rel
    if "inbox" in shipped_rel:
        shipped_rel = shipped_rel.replace("/inbox/", "/shipped/")

    for row in confirmed:
        cap = closure_to_capability(text, shipped_rel, row)
        result.proposed.append(cap)
        src_key = slugify(infer_module_key(text, row.name)[1])
        sink_key = slugify(infer_table_from_sink(row.sink).split(".")[0])
        if src_key != sink_key and src_key != "general" and sink_key != "general":
            result.cross_module_hints.append(
                {
                    "upstream": src_key,
                    "downstream": sink_key,
                    "capability": row.name,
                    "req_source": shipped_rel,
                }
            )

    return result


def apply_merge(req_path: Path, root: Path = ROOT, dry_run: bool = False) -> int:
    result = extract_from_requirement(req_path, root)
    if not result.eligible:
        print(f"[extract-capability] SKIP {result.req_path}: {result.skip_reason}")
        return 0

    cap_path = root / CAPABILITY_MAP_REL
    existing_rows, revisions = parse_capability_map(cap_path)
    existing_map = {r.primary_key(): r for r in existing_rows}
    req_source = result.req_path.replace("/inbox/", "/shipped/")
    result.actions = compute_merge_actions(existing_map, result.proposed, req_source)
    for act in result.actions:
        if act.operation in ("ADD", "UPDATE", "MERGE"):
            revisions.append(
                RevisionEntry(
                    date=date.today().isoformat(),
                    operation=act.operation,
                    primary_key=act.primary_key,
                    req_source=req_source,
                    note=act.note,
                )
            )

    print(f"[extract-capability] {result.req_path}: {len(result.proposed)} row(s)")
    for act in result.actions:
        print(f"  {act.operation:8} {act.primary_key} — {act.note}")

    if dry_run:
        print("[extract-capability] dry-run: no files written")
        return 0

    cap_path.parent.mkdir(parents=True, exist_ok=True)
    cap_path.write_text(
        render_capability_map(list(existing_map.values()), revisions),
        encoding="utf-8",
    )
    print(f"[extract-capability] wrote {CAPABILITY_MAP_REL}")
    return 0


def backfill_from_shipped(root: Path = ROOT, dry_run: bool = False, skip_seed: bool = True) -> int:
    shipped_dir = root / "docs/requirements/shipped"
    if not shipped_dir.is_dir():
        print("[extract-capability] no shipped directory")
        return 1

    files = sorted(shipped_dir.glob("*.md"))
    merged: dict[str, CapabilityRow] = {}
    all_revisions: list[RevisionEntry] = []

    for path in files:
        try:
            if skip_seed and _is_seed_requirement(path):
                continue
            result = extract_from_requirement(path, root)
        except FrontmatterError as exc:
            print(f"[extract-capability] ERROR {path.name}: {exc} (backfill fail-fast)")
            return 1
        if not result.eligible:
            print(f"  skip {path.name}: {result.skip_reason}")
            continue
        shipped_rel = path.relative_to(root).as_posix()
        actions = compute_merge_actions(merged, result.proposed, shipped_rel)
        for act in actions:
            if act.operation in ("ADD", "UPDATE", "MERGE"):
                all_revisions.append(
                    RevisionEntry(
                        date=date.today().isoformat(),
                        operation=act.operation,
                        primary_key=act.primary_key,
                        req_source=shipped_rel,
                        note=f"backfill: {act.note}",
                    )
                )
        print(f"  merged {path.name}: {len(result.proposed)} rows, {len(actions)} actions")

    if dry_run:
        print(f"[extract-capability] backfill dry-run: {len(merged)} unique keys")
        return 0

    cap_path = root / CAPABILITY_MAP_REL
    cap_path.parent.mkdir(parents=True, exist_ok=True)
    cap_path.write_text(render_capability_map(list(merged.values()), all_revisions), encoding="utf-8")
    print(f"[extract-capability] backfill wrote {len(merged)} rows to {CAPABILITY_MAP_REL}")
    return 0


def _main() -> int:
    parser = argparse.ArgumentParser(description="Extract and merge capability-map from requirements")
    parser.add_argument("--req", help="requirement markdown path")
    parser.add_argument("--backfill", action="store_true", help="merge all shipped requirements")
    parser.add_argument("--dry-run", action="store_true", help="preview only")
    parser.add_argument("--json", action="store_true", help="JSON output (with --req)")
    parser.add_argument("--root", default=str(ROOT), help="project root")
    args = parser.parse_args()
    root = Path(args.root)

    if args.backfill:
        return backfill_from_shipped(root, dry_run=args.dry_run)

    if not args.req:
        parser.error("--req or --backfill required")

    if args.json:
        result = extract_from_requirement(Path(args.req), root)
        if result.eligible:
            existing_rows, _ = parse_capability_map(root / CAPABILITY_MAP_REL)
            existing_map = {row.primary_key(): row for row in existing_rows}
            req_source = result.req_path.replace("/inbox/", "/shipped/")
            result.actions = compute_merge_actions(existing_map, result.proposed, req_source)
        payload: dict[str, Any] = {
            "req_path": result.req_path,
            "eligible": result.eligible,
            "skip_reason": result.skip_reason,
            "proposed": [row_to_dict(r) for r in result.proposed],
            "actions": [asdict(a) for a in result.actions],
            "cross_module_hints": result.cross_module_hints,
        }
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0

    return apply_merge(Path(args.req), root, dry_run=args.dry_run)


def main() -> int:
    try:
        return _main()
    except (FrontmatterError, UnicodeDecodeError, OSError) as exc:
        print(f"[extract-capability] ERROR {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
