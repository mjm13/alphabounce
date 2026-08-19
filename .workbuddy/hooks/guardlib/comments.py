"""Comment-sync file scope and endpoint annotation checks."""

from __future__ import annotations

import re
from datetime import date

from . import paths

SEMANTIC_TAG_RE = re.compile(r"\[(核心目的|接口地址|功能描述|业务逻辑)\]")
ENDPOINT_REQUIRED_TAGS = ("接口地址", "功能描述", "业务逻辑")
FASTAPI_ROUTER_REL_RE = re.compile(rf"^{paths.BACKEND_DIR}/.*_router\.py$", re.I)
FASTAPI_ROUTER_DECORATOR_RE = re.compile(r"^\s*@router\.(get|post|put|patch|delete)\b", re.I)
FRONTEND_API_CALL_RE = re.compile(
    r"http\.(get|post|put|delete|patch)\b[^;]*?['\"`](/api/[^'\"`\s]+)['\"`]", re.I,
)
_frontend_entries_cache: set[tuple[str, str]] | None = None


def normalize_api_path_template(path: str) -> str:
    return re.sub(r"\{[^}]+\}", "{id}", re.sub(r"\$\{[^}]+\}", "{id}", path.strip()))


def frontend_api_entries() -> set[tuple[str, str]]:
    global _frontend_entries_cache
    if _frontend_entries_cache is not None:
        return _frontend_entries_cache
    entries: set[tuple[str, str]] = set()
    api_dir = paths.ROOT / paths.FRONTEND_DIR / "src/api"
    if api_dir.is_dir():
        for file in api_dir.rglob("*.ts"):
            for match in FRONTEND_API_CALL_RE.finditer(file.read_text(encoding="utf-8", errors="ignore")):
                entries.add((match.group(1).upper(), normalize_api_path_template(match.group(2))))
    _frontend_entries_cache = entries
    return entries


def endpoint_addr(block: str) -> str:
    match = re.search(r"\[接口地址\]\s*:?\s*(.+)", block)
    return match.group(1).strip() if match else ""


def is_ui_mapped_endpoint(addr: str) -> bool:
    match = re.search(r"(GET|POST|PUT|DELETE|PATCH)\s+(/api/\S+)", addr, re.I)
    return bool(match and (match.group(1).upper(), normalize_api_path_template(match.group(2))) in frontend_api_entries())


def python_docstring_after_def(lines: list[str], index: int) -> str | None:
    while index < len(lines) and not lines[index].rstrip().endswith(":"):
        index += 1
    index += 1
    while index < len(lines) and not lines[index].strip():
        index += 1
    if index >= len(lines):
        return None
    for quote in ('"""', "'''"):
        if lines[index].strip().startswith(quote):
            parts = [lines[index].strip()]
            if parts[0].count(quote) >= 2 and len(parts[0]) > 6:
                return parts[0].strip(quote).strip()
            for line in lines[index + 1:]:
                parts.append(line)
                if quote in line:
                    return "\n".join(parts).strip().strip(quote).strip()
    return None


def extract_fastapi_router_docstrings(text: str) -> list[tuple[int, str | None]]:
    lines = text.splitlines()
    result: list[tuple[int, str | None]] = []
    for index, line in enumerate(lines):
        if not FASTAPI_ROUTER_DECORATOR_RE.search(line):
            continue
        def_index = index + 1
        while def_index < len(lines) and not lines[def_index].strip().startswith(("def ", "async def ")):
            def_index += 1
        if def_index < len(lines):
            result.append((def_index + 1, python_docstring_after_def(lines, def_index)))
    return result


def extract_django_comment_blocks(text: str) -> list[str]:
    lines, blocks = text.splitlines(), []
    for index, line in enumerate(lines):
        if "@api_view" not in line:
            continue
        block: list[str] = []
        index -= 1
        while index >= 0 and lines[index].strip().startswith("#"):
            block.insert(0, lines[index].strip())
            index -= 1
        if block:
            blocks.append("\n".join(block))
    return blocks


def endpoint_block_issues(label: str, block: str | None, *, missing_label: str) -> list[str]:
    if not block:
        return [missing_label]
    addr = endpoint_addr(block)
    display = f"{label} ({addr or 'unknown'})"
    issues = [f"{display} 缺少 [{tag}]" for tag in ENDPOINT_REQUIRED_TAGS if f"[{tag}]" not in block]
    api_dir_exists = (paths.ROOT / paths.FRONTEND_DIR / "src/api").is_dir()
    if api_dir_exists and addr and is_ui_mapped_endpoint(addr):
        if "[前端路径]" not in block:
            issues.append(f"{display} 已在 {paths.FRONTEND_DIR}/src/api 映射，缺少 [前端路径]")
        if "/system/" in addr and "[业务菜单]" not in block:
            issues.append(f"{display} 已在 {paths.FRONTEND_DIR}/src/api 映射，缺少 [业务菜单]")
    return issues


def fastapi_router_endpoint_issues(rel: str, text: str) -> list[str]:
    endpoints = extract_fastapi_router_docstrings(text)
    if not endpoints:
        return [f"{rel}: FastAPI router 缺少映射端点"]
    issues: list[str] = []
    for line, block in endpoints:
        issues.extend(endpoint_block_issues(
            f"{rel}:{line}", block, missing_label=f"{rel}:{line} 缺少端点 docstring 注释块",
        ))
    return issues


def django_endpoint_comment_issues(rel: str, text: str) -> list[str]:
    blocks = extract_django_comment_blocks(text)
    if not blocks:
        return [f"{rel}: 存在 @api_view 但缺少端点注释块"]
    issues: list[str] = []
    for index, block in enumerate(blocks, 1):
        issues.extend(endpoint_block_issues(f"{rel} 端点#{index}", block, missing_label=""))
    return issues


def endpoint_comment_issues(rel: str, text: str) -> list[str]:
    if FASTAPI_ROUTER_REL_RE.search(rel):
        return fastapi_router_endpoint_issues(rel, text)
    if paths.BACKEND_ENDPOINT_RE.search(rel) and "@api_view" in text:
        return django_endpoint_comment_issues(rel, text)
    return []


def collect_endpoint_comment_issues(files: list[str]) -> list[str]:
    issues: list[str] = []
    for rel in files:
        target = (paths.ROOT / rel).resolve()
        if target.is_file():
            issues.extend(endpoint_comment_issues(rel, target.read_text(encoding="utf-8", errors="ignore")))
    return issues


def file_has_semantic_comment(rel: str) -> bool:
    target = (paths.ROOT / rel).resolve()
    if not target.is_file():
        return True
    text = target.read_text(encoding="utf-8", errors="ignore")
    return not fastapi_router_endpoint_issues(rel, text) if FASTAPI_ROUTER_REL_RE.search(rel) else bool(SEMANTIC_TAG_RE.search(text))


def already_noticed_today() -> bool:
    today = date.today().isoformat()
    if paths.NOTICE_MARKER.is_file() and paths.NOTICE_MARKER.read_text(encoding="utf-8", errors="ignore").strip() == today:
        return True
    paths.NOTICE_MARKER.parent.mkdir(parents=True, exist_ok=True)
    paths.NOTICE_MARKER.write_text(today, encoding="utf-8")
    return False
