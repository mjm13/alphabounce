"""Living-document links, anchors, stack drift, AGENTS, and CI helpers."""

from __future__ import annotations

import re
from pathlib import Path

from . import paths
from .markdown import extract_section
from .requirement import gate2_is_accepted, parse_frontmatter_status, parse_gate_records

DOC_LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")
BACKTICK_DOC_RE = re.compile(r"`((?:docs/|AGENTS\.md|README\.md|\.codebuddy/)[^`]+)`")
LIVING_DOC_LINK_SOURCES = (
    "README.md", "docs/llms.txt", "docs/README.md", "docs/architecture.md", "docs/flow.md",
    "docs/roadmap.md", "docs/constitution.md", "docs/process/knowledge-maintenance.md",
)
DOC_ANCHOR_RE = re.compile(r"(?<![\w./#-])([\w./\-]+\.(?:java|py|ts|tsx|js|jsx|vue|go|rs|kt|cs))#(\w+)")
ARCHITECTURE_REL = "docs/architecture.md"
STACK_STALE_PATTERNS = tuple(
    (label, re.compile(pattern, re.I)) for label, pattern in (
        ("Spring Boot", r"Spring\s*Boot"), ("Flyway", r"\bFlyway\b"), ("MyBatis", r"\bMyBatis\b"),
        ("Maven", r"\bMaven\b"), ("JUnit", r"\bJUnit\b"), ("@SpringBootTest", r"@SpringBootTest\b"),
    )
)
STACK_DRIFT_SCAN_FILES = ("README.md", "AGENTS.md", "docs/constitution.md", "docs/openspec/config.yaml")
STACK_TRUTH_MARKERS = ("FastAPI", "Vue3", "Element Plus", "SQLAlchemy", "Alembic", "metric_hub")
README_STACK_MARKERS = ("FastAPI", "Vue3", "MySQL", "backend", "frontend")


def collect_links_from_text(text: str, source_rel: str) -> list[str]:
    links = [match.group(2) for match in DOC_LINK_RE.finditer(text)]
    links.extend(match.group(1) for match in BACKTICK_DOC_RE.finditer(text))
    if source_rel == "docs/llms.txt":
        for line in text.splitlines():
            body = line.strip()[2:].strip() if line.strip().startswith("- ") else ""
            candidate = body.split(" — ", 1)[0].strip() if " — " in body else (body.split()[0] if body else "")
            if candidate.startswith(("docs/", "AGENTS.md", "README.md", ".codebuddy/")):
                links.append(candidate)
    return links


def resolve_doc_link(link: str, source_rel: str) -> Path | None:
    raw = link.strip()
    if not raw or raw.startswith(("http://", "https://", "mailto:")):
        return None
    part = raw.split("#")[0].split("?")[0].strip()
    if not part:
        return None
    if part.startswith("/"):
        return (paths.ROOT / part.lstrip("/")).resolve()
    if part.startswith(("docs/", ".codebuddy/")) or part in ("AGENTS.md", "README.md"):
        return (paths.ROOT / part).resolve()
    return (paths.ROOT / source_rel).parent.joinpath(part).resolve()


def living_doc_link_issues() -> list[str]:
    issues, seen = [], set()
    for source_rel in LIVING_DOC_LINK_SOURCES:
        source = paths.ROOT / source_rel
        if not source.is_file():
            issues.append(f"活文档链接源缺失: {source_rel}")
            continue
        for link in collect_links_from_text(source.read_text(encoding="utf-8", errors="ignore"), source_rel):
            if (source_rel, link) in seen or "*" in link or "<" in link or ">" in link or link.startswith(("http://", "https://", "mailto:")):
                continue
            seen.add((source_rel, link))
            resolved = resolve_doc_link(link, source_rel)
            if resolved and not any(candidate.is_file() or candidate.is_dir() for candidate in (resolved, resolved.with_suffix(".md"), resolved.with_suffix(".mdc"))):
                try:
                    rel = resolved.relative_to(paths.ROOT).as_posix()
                except ValueError:
                    rel = str(resolved)
                issues.append(f"断链 [{link}] @ {source_rel} → {rel}")
    return issues


def iter_living_doc_files() -> list[Path]:
    docs = paths.ROOT / "docs"
    if not docs.is_dir():
        return []
    return [
        file for file in docs.rglob("*.md")
        if "_draft" not in file.parts and ".generated" not in file.parts
        and not file.relative_to(docs).as_posix().startswith("requirements/")
    ]


def stack_drift_issues() -> list[str]:
    architecture = paths.ROOT / ARCHITECTURE_REL
    if not architecture.is_file():
        return [f"缺少栈真相源 {ARCHITECTURE_REL}"]
    arch_text = architecture.read_text(encoding="utf-8", errors="ignore")
    compiled = extract_section(arch_text, "compiled_truth") or ""
    issues = [] if compiled.strip() else [f"{ARCHITECTURE_REL} 缺少 compiled_truth 段（栈真相源）"]
    truth = compiled or arch_text
    issues.extend(f"{ARCHITECTURE_REL} compiled_truth 缺少当前栈标记 {marker!r}" for marker in STACK_TRUTH_MARKERS if marker not in truth)
    for rel in STACK_DRIFT_SCAN_FILES:
        file = paths.ROOT / rel
        if not file.is_file():
            continue
        body = file.read_text(encoding="utf-8", errors="ignore")
        scan = body if rel.endswith(".yaml") else (extract_section(body, "compiled_truth") or body)
        issues.extend(f"过时栈关键词 {label!r} @ {rel}" for label, pattern in STACK_STALE_PATTERNS if pattern.search(scan))
    readme = paths.ROOT / "README.md"
    if readme.is_file():
        text = readme.read_text(encoding="utf-8", errors="ignore")
        if not any(marker in text for marker in README_STACK_MARKERS) and not re.search(r"docs/architecture\.md", text, re.I):
            issues.append("README.md 须链接 docs/architecture.md（栈真相源），或包含项目声明的现行栈关键词")
    return issues


def extract_agents_build_section(text: str) -> str | None:
    for heading in ("Build and test commands", r"\d+\.\s+本地命令", "本地命令"):
        match = re.search(rf"^##\s+{heading}[^\n]*\n(.*?)(?=^##\s|\Z)", text, re.M | re.S)
        if match:
            return match.group(1).strip()
    return None


def agents_command_section_ready() -> tuple[bool, str]:
    agents = paths.ROOT / "AGENTS.md"
    if not agents.is_file():
        return False, "缺少 AGENTS.md"
    section = extract_agents_build_section(agents.read_text(encoding="utf-8", errors="ignore"))
    if not section:
        return False, "AGENTS.md 缺少「Build and test commands」章节"
    if "<待补充>" in section:
        return False, "AGENTS.md Build and test commands 仍为占位"
    blocks = re.findall(r"```(?:bash|sh)?\s*\n(.*?)```", section, re.S)
    combined = "\n".join(blocks)
    if not blocks:
        return False, "AGENTS.md Build and test commands 缺少可执行 bash 块"
    if not re.search(r"\b(mvnw|npm|gradle|pnpm|yarn|pytest|uvicorn|pip)\b", combined, re.I):
        return False, "AGENTS.md Build and test commands 未检测到 npm/pytest/uvicorn 等构建/测试命令"
    if not re.search(r"\b(test|build|package|lint)\b", combined, re.I):
        return False, "AGENTS.md Build and test commands 未检测到 test/build 类命令"
    return True, "AGENTS 命令段已填写"


def ci_or_local_declared() -> tuple[bool, str]:
    if any((paths.ROOT / rel).is_file() for rel in (".github/workflows/ci.yml", ".gitlab-ci.yml")):
        return True, "CI 配置文件存在"
    for rel, pattern, message in (
        ("AGENTS.md", r"仅本地|local.?only|workflow_dispatch", "AGENTS 已声明本地/占位 CI"),
        ("docs/process/release-checklist.md", r"仅本地 CI", "release-checklist 已声明仅本地 CI"),
    ):
        file = paths.ROOT / rel
        if file.is_file() and re.search(pattern, file.read_text(encoding="utf-8", errors="ignore"), re.I):
            return True, message
    return False, "未发现 CI 配置且未声明「仅本地 CI」"


def inbox_active_requirements() -> list[str]:
    inbox = paths.ROOT / "docs/requirements/inbox"
    if not inbox.is_dir():
        return []
    active = []
    for file in sorted(inbox.glob("*.md")):
        if file.name.upper() == "README.MD":
            continue
        text = file.read_text(encoding="utf-8", errors="ignore")
        accepted, _ = gate2_is_accepted(parse_gate_records(text).get("Gate-2"))
        if parse_frontmatter_status(text) != "shipped" and not accepted:
            active.append(file.relative_to(paths.ROOT).as_posix())
    return active
