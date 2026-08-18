"""Fence-aware Markdown and simple table/frontmatter primitives."""

from __future__ import annotations

import re
from collections.abc import Iterable, Iterator
from dataclasses import dataclass

SEP_CELL_RE = re.compile(r"^:?-+:?$")
PLACEHOLDER_RE = re.compile(r"^(-+|待.?补|待.?填|tbd|todo|n/?a|none|\.\.\.|…|<.*>)$", re.I)


@dataclass(frozen=True)
class Heading:
    level: int
    title: str
    line: int


class FrontmatterError(ValueError):
    def __init__(self, key: str) -> None:
        self.key = key
        super().__init__(f"frontmatter 重复键 '{key}'")


def _iter_unfenced_lines(
    text: str,
    *,
    skip_frontmatter: bool,
) -> Iterator[tuple[int, str]]:
    """Yield line number and text outside fenced code."""
    lines = text.removeprefix("\ufeff").splitlines()
    in_frontmatter = bool(skip_frontmatter and lines and lines[0] == "---")
    fence_char = ""
    fence_len = 0
    for line_number, line in enumerate(lines, start=1):
        stripped = line.rstrip()
        if in_frontmatter:
            if line_number > 1 and line == "---":
                in_frontmatter = False
            continue
        if fence_char:
            if re.match(rf"^[ \t]{{0,3}}{fence_char}{{{fence_len},}}[ \t]*$", stripped):
                fence_char, fence_len = "", 0
            continue
        fence = re.match(r"^[ \t]{0,3}(`{3,}|~{3,})", stripped)
        if fence:
            marker = fence.group(1)
            fence_char, fence_len = marker[0], len(marker)
            continue
        yield line_number, line


def iter_headings(text: str) -> Iterator[Heading]:
    """Yield ATX headings outside frontmatter and fenced code."""
    for line_number, line in _iter_unfenced_lines(text, skip_frontmatter=True):
        stripped = line.rstrip()
        match = re.match(r"^[ \t]{0,3}(#{1,6})[ \t]+(.+?)\s*$", stripped)
        if match:
            title = re.sub(r"[ \t]+#+[ \t]*$", "", match.group(2)).strip()
            yield Heading(len(match.group(1)), title, line_number)


def extract_section(text: str, heading_prefix: str) -> str | None:
    """Return body for the first ATX heading matching prefix (any level).

    Ends at the next heading of the same or higher level. Ignores headings
    inside fenced code. Compatible with H1 shipped habit and H2 templates.
    """
    lines = text.removeprefix("\ufeff").splitlines(keepends=True)
    headings = list(iter_headings(text))
    for index, heading in enumerate(headings):
        if not heading.title.lower().startswith(heading_prefix.lower()):
            continue
        end_line = next(
            (item.line for item in headings[index + 1:] if item.level <= heading.level),
            len(lines) + 1,
        )
        return "".join(lines[heading.line:end_line - 1]).strip()
    return None


def parse_frontmatter(text: str, aliases: dict[str, str] | None = None) -> dict[str, str] | None:
    text = text.removeprefix("\ufeff")
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return None
    try:
        end = lines.index("---", 1)
    except ValueError:
        return None
    fields: dict[str, str] = {}
    seen_keys: set[str] = set()
    for line in lines[1:end]:
        match = re.match(r"^\s*([^:\s][^:]*)\s*:\s*(.*?)\s*$", line)
        if not match:
            continue
        raw = match.group(1).strip()
        lookup = raw.lower().replace(" ", "")
        key = (aliases or {}).get(lookup, lookup)
        if key in seen_keys:
            raise FrontmatterError(key)
        seen_keys.add(key)
        value = match.group(2).strip()
        if "|" not in value or key.lower() in {"gate-0", "gate-1", "gate-2"}:
            fields[key] = value
    return fields


def find_col(headers: list[str], keys: Iterable[str]) -> int | None:
    lowered = tuple(key.lower() for key in keys)
    return next(
        (idx for idx, cell in enumerate(headers) if any(key in cell.lower() for key in lowered)),
        None,
    )


def split_table_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def is_separator_row(cells: list[str]) -> bool:
    return bool(cells) and all(SEP_CELL_RE.match(cell or "-") for cell in cells)


def table_rows_after(lines: list[str], header_idx: int) -> Iterable[list[str]]:
    for line in lines[header_idx + 1:]:
        stripped = line.strip()
        if not stripped.startswith("|"):
            break
        cells = split_table_row(stripped)
        if not is_separator_row(cells):
            yield cells


def find_table(text: str, required_headers: Iterable[str]) -> tuple[list[str], list[list[str]]] | None:
    """Return the first pipe table whose header contains every required token."""
    required = tuple(token.lower() for token in required_headers)
    lines = text.splitlines()
    for line_number, line in _iter_unfenced_lines(text, skip_frontmatter=False):
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        lowered = stripped.lower()
        if all(token in lowered for token in required):
            index = line_number - 1
            return split_table_row(stripped), list(table_rows_after(lines, index))
    return None


def cell(cells: list[str], index: int | None) -> str:
    return cells[index] if index is not None and index < len(cells) else ""


def is_placeholder(value: str) -> bool:
    text = (value or "").strip()
    return not text or bool(PLACEHOLDER_RE.match(text))
