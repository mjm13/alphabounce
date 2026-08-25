"""Load and apply Table-First guard specs from docs/patterns/*.guard.yaml."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

from . import paths

GUARD_SPEC_REL = "docs/patterns/table-first-list-page.guard.yaml"
GUARD_DOC_REF = "docs/patterns/table-first-list-page.md §结构门禁"

_LIST_ITEM_RE = re.compile(r"^\s*-\s+(.+)$")
_SECTION_RE = re.compile(r"^(\w+):\s*$")
_NESTED_KEY_RE = re.compile(r"^  (\w+):\s*(.*)$")


@dataclass
class TableFirstGuardSpec:
    trigger_requires_all: list[str] = field(default_factory=list)
    required_tokens: list[str] = field(default_factory=list)
    filter_head_one_of: list[str] = field(default_factory=list)
    filter_search_one_of: list[str] = field(default_factory=list)
    forbidden_tokens: list[str] = field(default_factory=list)
    drawer_requires: list[str] = field(default_factory=list)
    drawer_visibility_binding: str = "is-on"


def _parse_inline_list(value: str) -> list[str]:
    inner = value.strip()
    if inner.startswith("[") and inner.endswith("]"):
        inner = inner[1:-1].strip()
    if not inner:
        return []
    return [part.strip().strip("'\"") for part in inner.split(",") if part.strip()]


def _parse_guard_yaml(text: str) -> TableFirstGuardSpec:
    spec = TableFirstGuardSpec()
    section: str | None = None
    nested_key: str | None = None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        section_match = _SECTION_RE.match(stripped)
        if section_match and not line.startswith(" "):
            section = section_match.group(1)
            nested_key = None
            continue

        nested_match = _NESTED_KEY_RE.match(line)
        if nested_match and section:
            nested_key = nested_match.group(1)
            value = nested_match.group(2).strip()
            if section == "trigger" and nested_key == "requires_all":
                if value:
                    spec.trigger_requires_all = _parse_inline_list(value)
                else:
                    spec.trigger_requires_all = []
            elif section == "drawer":
                if nested_key == "requires":
                    spec.drawer_requires = _parse_inline_list(value) if value else []
                elif nested_key == "visibility_binding":
                    spec.drawer_visibility_binding = value.strip("'\"")
            continue

        list_match = _LIST_ITEM_RE.match(line)
        if list_match and section:
            item = list_match.group(1).strip().strip("'\"")
            if section == "trigger" and nested_key == "requires_all":
                spec.trigger_requires_all.append(item)
            elif section == "required_tokens":
                spec.required_tokens.append(item)
            elif section == "filter_head_one_of":
                spec.filter_head_one_of.append(item)
            elif section == "filter_search_one_of":
                spec.filter_search_one_of.append(item)
            elif section == "forbidden_tokens":
                spec.forbidden_tokens.append(item)
            elif section == "drawer" and nested_key == "requires":
                spec.drawer_requires.append(item)
            continue

        if section and not line.startswith(" ") and ":" in stripped:
            key, value = stripped.split(":", 1)
            items = _parse_inline_list(value)
            if key == "required_tokens":
                spec.required_tokens = items
            elif key == "filter_head_one_of":
                spec.filter_head_one_of = items
            elif key == "filter_search_one_of":
                spec.filter_search_one_of = items
            elif key == "forbidden_tokens":
                spec.forbidden_tokens = items

    return spec


def load_table_first_guard_spec(spec_path: Path | None = None) -> TableFirstGuardSpec:
    path = spec_path or (paths.ROOT / GUARD_SPEC_REL)
    if not path.is_file():
        raise FileNotFoundError(f"guard spec not found: {path}")
    return _parse_guard_yaml(path.read_text(encoding="utf-8"))


def _trigger_matches(body: str, spec: TableFirstGuardSpec) -> bool:
    if not spec.trigger_requires_all:
        return False
    return all(token in body for token in spec.trigger_requires_all)


def table_first_structure_issues(rel: str, body: str, spec: TableFirstGuardSpec | None = None) -> list[str]:
    """Return structural issues for a Table-First *Panel.vue body."""
    loaded = spec or load_table_first_guard_spec()
    if not _trigger_matches(body, loaded):
        return []

    issues: list[str] = []
    for token in loaded.required_tokens:
        if token not in body:
            issues.append(
                f"{rel}: Table-First 缺少必选结构 `{token}`（见 {GUARD_DOC_REF}）"
            )

    if loaded.filter_head_one_of and not any(token in body for token in loaded.filter_head_one_of):
        options = " / ".join(f"`{token}`" for token in loaded.filter_head_one_of)
        issues.append(f"{rel}: Table-First 筛选栏缺少 {options}（见 {GUARD_DOC_REF}）")

    if loaded.filter_search_one_of and not any(token in body for token in loaded.filter_search_one_of):
        options = " / ".join(f"`{token}`" for token in loaded.filter_search_one_of)
        issues.append(f"{rel}: Table-First 筛选栏缺少 {options}（见 {GUARD_DOC_REF}）")

    for token in loaded.forbidden_tokens:
        if token in body:
            issues.append(
                f"{rel}: Table-First 使用了禁止结构 `{token}`（见 {GUARD_DOC_REF}）"
            )

    return issues
