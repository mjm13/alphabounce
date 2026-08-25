"""OpenSpec change-product helpers."""

from __future__ import annotations

import re
from pathlib import Path

from . import paths
from .requirement import is_red_requirement_text, parse_frontmatter_openspec_change


def active_change_dirs() -> list[Path]:
    if not paths.CHANGES_DIR.is_dir():
        return []
    return [item for item in paths.CHANGES_DIR.iterdir() if item.is_dir() and item.name != "archive"]


def has_any_change_product() -> bool:
    return any((item / "proposal.md").is_file() for item in active_change_dirs())


def change_dir(change: str) -> Path:
    return (paths.CHANGES_DIR / change).resolve()


def missing_apply_artifacts(change: str, *, require_domain: bool) -> list[str]:
    base = change_dir(change)
    missing: list[str] = []
    for name in ("proposal.md", "tasks.md"):
        if not (base / name).is_file():
            missing.append(f"{change}/{name}")
    specs = base / "specs"
    if not (specs.is_dir() and any(specs.rglob("*.md"))):
        missing.append(f"{change}/specs/**/*.md")
    if require_domain:
        domain = base / "domain"
        if not (domain.is_dir() and any(domain.glob("*.md"))):
            missing.append(f"{change}/domain/*.md")
    return missing


def _requirement_stem_tokens(req_path: Path) -> list[str]:
    stem = req_path.stem
    tokens: list[str] = []
    if match := re.fullmatch(r"(\d{14})-(.+)", stem):
        tokens.append(match.group(1)[-3:])
        tokens.append(match.group(2))
    else:
        tokens.append(stem)
    return [t for t in tokens if t]


def _proposal_out_of_scope_warning(change: str, req_path: Path, proposal_text: str) -> str | None:
    if not re.search(r"out\s*of\s*scope", proposal_text, re.I):
        return None
    scope_section = proposal_text
    match = re.search(
        r"(?ims)^#{1,3}\s*out\s*of\s*scope\s*$([\s\S]*?)(?=^#{1,3}\s|\Z)",
        proposal_text,
    )
    if match:
        scope_section = match.group(1)
    for token in _requirement_stem_tokens(req_path):
        if len(token) >= 2 and token in scope_section:
            return (
                f"proposal Out of Scope 命中需求标识「{token}」"
                f"（change={change}）；请确认 change 名与需求 1:1"
            )
    return None


def openspec_structural_issues(text: str, req_path: Path) -> tuple[list[str], list[str]]:
    """Structural OpenSpec checks for red-tier active requirements.

    Returns (errors, warnings). Errors block intake/CTA; warnings are advisory only.
    """
    if not is_red_requirement_text(text):
        return [], []
    change = parse_frontmatter_openspec_change(text)
    if not change:
        return [], []

    errors: list[str] = []
    warnings: list[str] = []
    active = change_dir(change)
    archived = paths.ARCHIVE_CHANGES_DIR / change

    if not active.is_dir():
        errors.append(f"openspec变更目录不存在：docs/openspec/changes/{change}/")
    if archived.is_dir():
        errors.append(f"openspec变更已归档但 inbox 仍 active：{change}")

    proposal = active / "proposal.md"
    if proposal.is_file():
        proposal_text = proposal.read_text(encoding="utf-8", errors="replace")
        warning = _proposal_out_of_scope_warning(change, req_path, proposal_text)
        if warning:
            warnings.append(warning)

    return errors, warnings
