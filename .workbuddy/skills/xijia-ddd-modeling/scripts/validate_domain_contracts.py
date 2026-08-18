#!/usr/bin/env python3
"""Validate machine-readable DDD contracts."""
from __future__ import annotations
import argparse
import re
from pathlib import Path

INV_RE = re.compile(r"INV-\d{3}")
PATTERN_MARKERS = ("OHS", "ACL", "Conformist", "Partnership", "Shared Kernel")
AGGREGATE_RE = re.compile(r"^\s*##\s*Aggregate\s*:\s*(.+?)\s*$", re.MULTILINE)
BC_HINT_RE = re.compile(r"\bBC\s*:\s*([^\n|]+)")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def pick_file(root: Path, name: str) -> Path:
    md = root / f"{name}.md"
    tmpl = root / f"{name}.md.tmpl"
    if md.exists():
        return md
    if tmpl.exists():
        return tmpl
    return md


def _normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().lower())


def _split_aliases(raw: str) -> list[str]:
    parts = re.split(r"[,，/]", raw)
    return [p.strip() for p in parts if p.strip()]


def _parse_markdown_table_rows(text: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if not cells or all(re.fullmatch(r":?-+:?", c or "-") for c in cells):
            continue
        rows.append(cells)
    return rows


def _parse_ul(text: str) -> tuple[set[str], dict[str, set[str]], dict[str, set[str]]]:
    terms: set[str] = set()
    bcs_by_term: dict[str, set[str]] = {}
    aliases_by_term: dict[str, set[str]] = {}
    for cells in _parse_markdown_table_rows(text):
        if len(cells) < 5:
            continue
        term, bc, alias_raw = cells[0], cells[2], cells[4]
        if term.lower() in {"术语", "term", "<term>"}:
            continue
        term = term.strip()
        bc = bc.strip()
        if not term:
            continue
        terms.add(_normalize(term))
        if bc and "<" not in bc and ">" not in bc:
            bcs_by_term.setdefault(_normalize(term), set()).add(_normalize(bc))
        aliases = {_normalize(a) for a in _split_aliases(alias_raw) if "<" not in a and ">" not in a}
        if aliases:
            aliases_by_term.setdefault(_normalize(term), set()).update(aliases)
    return terms, bcs_by_term, aliases_by_term


def _parse_context_map_bcs(text: str) -> set[str]:
    bcs: set[str] = set()
    in_bc_section = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("##"):
            in_bc_section = "bounded context" in stripped.lower()
        if in_bc_section and stripped.startswith("-"):
            item = stripped.lstrip("-").strip()
            if item and "<" not in item and ">" not in item:
                bcs.add(_normalize(item))
    for cells in _parse_markdown_table_rows(text):
        if len(cells) >= 2:
            for value in (cells[0], cells[1]):
                if value and all(token.lower() not in {"upstream", "downstream", "<context-a>", "<context-b>"} for token in [value]):
                    if "<" not in value and ">" not in value:
                        bcs.add(_normalize(value))
    return bcs


def _parse_aggregate_spec_bcs(text: str) -> set[str]:
    bcs: set[str] = set()
    for match in BC_HINT_RE.findall(text):
        value = match.strip()
        if value and "<" not in value and ">" not in value:
            bcs.add(_normalize(value))
    return bcs


def validate(path: Path) -> int:
    errors: list[str] = []
    warnings: list[str] = []
    ul_path = pick_file(path, "ubiquitous-language")
    dm_path = pick_file(path, "domain-model")
    cm_path = pick_file(path, "context-map")
    as_path = pick_file(path, "aggregate-spec")

    ul = read_text(ul_path)
    dm = read_text(dm_path)
    cm = read_text(cm_path)
    aggs = read_text(as_path)

    if ul:
        if "Aliases to AVOID" not in ul:
            errors.append("UL missing 'Aliases to AVOID'")
        if "| BC |" not in ul and "|BC|" not in ul:
            errors.append("UL table missing BC column")
    else:
        errors.append(f"Missing {ul_path.name}")

    if dm:
        if not INV_RE.search(dm):
            errors.append("domain-model missing INV-xxx invariant")
    else:
        errors.append(f"Missing {dm_path.name}")

    if cm:
        if not any(marker in cm for marker in PATTERN_MARKERS):
            errors.append("context-map missing relationship pattern marker (OHS/ACL/Conformist/Partnership/Shared Kernel)")
    else:
        errors.append(f"Missing {cm_path.name}")

    if dm:
        inv_ids = INV_RE.findall(dm)
        duplicates = sorted({inv for inv in inv_ids if inv_ids.count(inv) > 1})
        if duplicates:
            errors.append(f"domain-model duplicated invariant IDs: {', '.join(duplicates)}")

        agg_names = {_normalize(name) for name in AGGREGATE_RE.findall(dm)}
        ul_terms, ul_bcs_by_term, aliases_by_term = _parse_ul(ul)
        for agg in sorted(agg_names):
            if agg not in ul_terms:
                warnings.append(f"aggregate '{agg}' not found in UL terms")

        canonical_terms = set(ul_terms)
        for term, aliases in aliases_by_term.items():
            for alias in aliases:
                if alias in canonical_terms and alias != term:
                    errors.append(f"alias conflict: '{alias}' is canonical term of another entry")

        ul_bcs = {bc for bcs in ul_bcs_by_term.values() for bc in bcs}
        cm_bcs = _parse_context_map_bcs(cm)
        aggs_bcs = _parse_aggregate_spec_bcs(aggs)
        present_sets = [("UL", ul_bcs), ("context-map", cm_bcs), ("aggregate-spec", aggs_bcs)]
        non_empty = [(name, values) for name, values in present_sets if values]
        if len(non_empty) >= 2:
            merged = set().union(*(values for _, values in non_empty))
            for name, values in non_empty:
                missing = merged - values
                if missing:
                    errors.append(f"{name} BC set inconsistent, missing: {', '.join(sorted(missing))}")

    if errors:
        print("DDD CONTRACT CHECK: ERROR")
        for err in errors:
            print(f"- {err}")
        if warnings:
            print("DDD CONTRACT CHECK: WARN")
            for warning in warnings:
                print(f"- {warning}")
        return 1

    if warnings:
        print("DDD CONTRACT CHECK: PASS_WITH_WARNINGS")
        for warning in warnings:
            print(f"- {warning}")
        return 0

    print("DDD CONTRACT CHECK: PASS")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", required=True, help="Domain directory path")
    args = parser.parse_args()
    return validate(Path(args.path))


if __name__ == "__main__":
    raise SystemExit(main())
