#!/usr/bin/env python3
"""Workspace scanner for /xijia:adopt (discover, preflight, DDD candidates).

Layers: L0 module discovery, L1 stack, L2 commands, L3 heuristic API scan,
L4 DDD candidates. Secrets files are never read.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from guardlib.paths import ROOT, configure_utf8_streams

configure_utf8_streams()
MANIFEST_REL = "docs/workspace-manifest.yaml"
DISCOVERY_REL = "docs/.generated/adopt-discovery.json"
DDD_DISCOVERY_REL = "docs/.generated/ddd-discovery.json"

BUILD_MARKERS = {
    "package.json": ("nodejs", "frontend"),
    "pom.xml": ("maven", "backend"),
    "build.gradle": ("gradle", "backend"),
    "build.gradle.kts": ("gradle", "backend"),
    "go.mod": ("go", "backend"),
    "Cargo.toml": ("rust", "backend"),
    "pyproject.toml": ("python", "backend"),
    "setup.py": ("python", "backend"),
}

SKIP_DIR_NAMES = {
    ".git",
    ".hg",
    ".svn",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    "dist",
    "build",
    "target",
    ".codegraph",
    ".venv",
    "venv",
    ".idea",
    ".cursor",
    "docs",
}

SECRET_NAME_RE = re.compile(
    r"^\.env|credentials|secrets?\.|\.pem$|\.key$|id_rsa",
    re.IGNORECASE,
)

MAX_DISCOVER_DEPTH = 4
ENTITY_RE = re.compile(r"@Entity\b|@Table\s*\(")
FEIGN_RE = re.compile(r"@FeignClient\s*\(\s*name\s*=\s*[\"']([^\"']+)")
CONTROLLER_RE = re.compile(
    r"@(?:RestController|Controller)\s*(?:\([^)]*\))?\s*(?:public\s+)?class\s+(\w+)",
)
REQUEST_MAPPING_RE = re.compile(r"@RequestMapping\s*\(\s*[\"']([^\"']+)")
GET_MAPPING_RE = re.compile(r"@GetMapping\s*\(\s*[\"']([^\"']+)")
ENUM_RE = re.compile(r"enum\s+(\w+)")
PY_MODEL_RE = re.compile(r"class\s+(\w+)\s*\([^)]*models\.Model[^)]*\)")

# 入口点识别（行为驱动流程重建的起点）：API 已由 scan_apis_heuristic 收集，这里补任务/命令。
JAVA_SCHEDULED_RE = re.compile(r"@Scheduled\b[\s\S]{0,120}?(?:public|private|protected)?\s+\w[\w<>\[\]]*\s+(\w+)\s*\(")
PY_TASK_RE = re.compile(r"@(?:shared_task|app\.task|celery\.task|task)\b[\s\S]{0,200}?def\s+(\w+)\s*\(")
PY_COMMAND_RE = re.compile(r"class\s+(Command)\s*\(\s*BaseCommand")

# 实体分类启发式（保守：命名 + 轻结构信号；只折叠不丢弃，核心宁多列不漏）。
# 注意：`*Record` 故意不在 infra 后缀内——不单凭命名降级（见优化计划 §10）。
_DTO_SUFFIX_RE = re.compile(r"(DTO|VO|BO|DO|Request|Response|Resp|Req|Param|Params|Query|Form|Payload)$")
_INFRA_SUFFIX_RE = re.compile(r"(Log|Logs|Message|Msg|Audit|History|Snapshot|Trace)$")
_SUPPORTING_SUFFIX_RE = re.compile(
    r"(UserRole|Role|Permission|Perm|Relation|Rel|Mapping|Ref|Config|Setting|Settings|Dict|Category|Tag|Type)$"
)
_STATE_FIELD_RE = re.compile(r"\b(status|state|stage|phase|lifecycle)\b", re.I)


def classify_entity(name: str, body: str = "") -> str:
    """将实体归类为 aggregate | supporting | infrastructure | dto。

    命名为主 + 轻结构信号：支撑类若承载状态机字段则提升为聚合候选；未命中降级规则默认 aggregate。
    `*Record` 不在任何降级后缀内 → 默认 aggregate（不因命名被误降级）。
    """
    if _DTO_SUFFIX_RE.search(name):
        return "dto"
    if _INFRA_SUFFIX_RE.search(name):
        return "infrastructure"
    if _SUPPORTING_SUFFIX_RE.search(name):
        return "aggregate" if _STATE_FIELD_RE.search(body) else "supporting"
    return "aggregate"


@dataclass
class ModuleCandidate:
    key: str
    path: str
    kind: str
    signals: list[str] = field(default_factory=list)
    confidence: str = "high"
    primary: bool = False

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _slug_key(name: str) -> str:
    text = re.sub(r"[^a-zA-Z0-9]+", "-", name.strip()).strip("-").lower()
    return text or "module"


def _is_secret_path(path: Path) -> bool:
    return bool(SECRET_NAME_RE.search(path.name))


def _read_text_safe(path: Path, limit: int = 200_000) -> str:
    if _is_secret_path(path):
        return ""
    try:
        data = path.read_bytes()
        if b"\x00" in data[:4096]:
            return ""
        return data[:limit].decode("utf-8", errors="ignore")
    except OSError:
        return ""


def _find_build_marker(module_dir: Path) -> tuple[str | None, list[str]]:
    signals: list[str] = []
    for marker, (stack, default_kind_hint) in BUILD_MARKERS.items():
        if (module_dir / marker).is_file():
            signals.append(marker.replace(".", "-"))
            if "spring" in _read_text_safe(module_dir / marker, 8000).lower():
                signals.append("spring")
            return default_kind_hint, signals
    return None, signals


def _infer_kind_from_content(module_dir: Path, hint: str | None, signals: list[str]) -> str:
    if hint == "frontend":
        return "frontend"
    text_blob = ""
    for name in ("package.json", "pom.xml", "build.gradle", "build.gradle.kts"):
        p = module_dir / name
        if p.is_file():
            text_blob += _read_text_safe(p, 4000).lower()
    if "vue" in text_blob or "react" in text_blob or "vite" in text_blob:
        return "frontend"
    if hint:
        return hint
    if (module_dir / "src" / "main").is_dir():
        return "backend"
    return "library"


def discover_modules(root: Path = ROOT, max_depth: int = MAX_DISCOVER_DEPTH) -> list[ModuleCandidate]:
    found: list[ModuleCandidate] = []
    seen_paths: set[str] = set()

    def walk(dir_path: Path, depth: int) -> None:
        if depth > max_depth:
            return
        rel = dir_path.relative_to(root).as_posix()
        if rel == ".":
            rel_key = "."
        else:
            rel_key = rel
        hint, signals = _find_build_marker(dir_path)
        if hint and rel_key not in seen_paths:
            seen_paths.add(rel_key)
            kind = _infer_kind_from_content(dir_path, hint, signals)
            found.append(
                ModuleCandidate(
                    key=_slug_key(dir_path.name if rel != "." else root.name),
                    path=rel if rel != "." else ".",
                    kind=kind,
                    signals=signals or [hint],
                    confidence="high" if signals else "medium",
                )
            )
            return
        if depth >= max_depth:
            return
        try:
            children = sorted(dir_path.iterdir())
        except OSError:
            return
        for child in children:
            if child.is_dir() and child.name not in SKIP_DIR_NAMES:
                walk(child, depth + 1)

    walk(root.resolve(), 0)

    if not found:
        return found

    backends = [m for m in found if m.kind == "backend"]
    frontends = [m for m in found if m.kind == "frontend"]
    if backends:
        backends[0].primary = True
    if frontends:
        frontends[0].primary = True
    return found


def infer_commands(module_path: Path) -> dict[str, str]:
    cmds: dict[str, str] = {}
    rel = module_path.as_posix()
    pkg = module_path / "package.json"
    if pkg.is_file():
        try:
            data = json.loads(_read_text_safe(pkg, 50_000) or "{}")
        except json.JSONDecodeError:
            data = {}
        scripts = data.get("scripts") or {}
        prefix = f"cd {rel} && " if rel != "." else ""
        if "install" in scripts or pkg.is_file():
            cmds["install"] = f"{prefix}npm install"
        for name, key in (("dev", "dev"), ("test", "test"), ("build", "build")):
            if key in scripts:
                cmds[name] = f"{prefix}npm run {key}"
        if "test" not in cmds and "build" in scripts:
            cmds["test"] = f"{prefix}npm run build"
        return cmds

    if (module_path / "pom.xml").is_file() or (module_path / "mvnw").is_file():
        prefix = f"cd {rel} && " if rel != "." else ""
        mvn = "./mvnw" if (module_path / "mvnw").is_file() else "mvn"
        cmds["install"] = f"{prefix}{mvn} install -DskipTests"
        cmds["test"] = f"{prefix}{mvn} test"
        cmds["build"] = f"{prefix}{mvn} package -DskipTests"
        return cmds

    if (module_path / "go.mod").is_file():
        prefix = f"cd {rel} && " if rel != "." else ""
        cmds["install"] = f"{prefix}go mod download"
        cmds["test"] = f"{prefix}go test ./..."
        cmds["build"] = f"{prefix}go build ./..."
        return cmds

    return cmds


def infer_stack_summary(modules: list[ModuleCandidate]) -> str:
    stacks: list[str] = []
    for mod in modules:
        for sig in mod.signals:
            if sig in ("maven", "spring", "nodejs", "gradle", "go", "python", "rust"):
                label = {"maven": "Java/Maven", "spring": "Spring Boot", "nodejs": "Node.js",
                         "gradle": "Gradle", "go": "Go", "python": "Python", "rust": "Rust"}.get(sig, sig)
                if label not in stacks:
                    stacks.append(label)
    return ", ".join(stacks) if stacks else "待确认"


def codegraph_cli_available() -> tuple[bool, str]:
    exe = shutil.which("codegraph")
    if not exe:
        return False, "codegraph CLI 不在 PATH"
    try:
        proc = subprocess.run(
            [exe, "--version"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=15,
            cwd=ROOT,
        )
        if proc.returncode == 0:
            version = (proc.stdout or proc.stderr or "").strip().splitlines()[0]
            return True, version or "ok"
    except (subprocess.TimeoutExpired, OSError):
        pass
    return bool(exe), "codegraph 可执行（--version 未验证）"


def codegraph_initialized(module_dir: Path) -> bool:
    if (module_dir / ".codegraph").is_dir():
        return True
    if (module_dir / "codegraph.json").is_file():
        return True
    exe = shutil.which("codegraph")
    if not exe:
        return False
    try:
        proc = subprocess.run(
            [exe, "status", "--path", str(module_dir.resolve())],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=30,
            cwd=ROOT,
        )
        return proc.returncode == 0
    except (subprocess.TimeoutExpired, OSError):
        return False


def codegraph_init(module_dir: Path, dry_run: bool = False) -> tuple[str, str]:
    if codegraph_initialized(module_dir):
        return "ready", str(module_dir / ".codegraph")
    exe = shutil.which("codegraph")
    if not exe:
        return "init_failed", "codegraph CLI 不可用"
    if dry_run:
        return "pending", "dry-run"
    try:
        proc = subprocess.run(
            [exe, "init", "--path", str(module_dir.resolve())],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=120,
            cwd=ROOT,
        )
        if proc.returncode == 0 or codegraph_initialized(module_dir):
            return "ready", str(module_dir / ".codegraph")
        err = (proc.stderr or proc.stdout or "").strip()[:200]
        return "init_failed", err or f"exit {proc.returncode}"
    except (subprocess.TimeoutExpired, OSError) as exc:
        return "init_failed", str(exc)


def scan_apis_heuristic(module_dir: Path) -> list[dict[str, str]]:
    apis: list[dict[str, str]] = []
    src_roots = [module_dir / "src" / "main" / "java", module_dir / "src"]
    for src in src_roots:
        if not src.is_dir():
            continue
        for java_file in src.rglob("*.java"):
            if _is_secret_path(java_file):
                continue
            text = _read_text_safe(java_file, 30_000)
            if "@RestController" not in text and "@Controller" not in text:
                continue
            cls = CONTROLLER_RE.search(text)
            base = ""
            m = REQUEST_MAPPING_RE.search(text)
            if m:
                base = m.group(1).rstrip("/")
            for gm in GET_MAPPING_RE.finditer(text):
                path = gm.group(1)
                full = f"{base}/{path}".replace("//", "/")
                apis.append({
                    "controller": cls.group(1) if cls else java_file.stem,
                    "path": full,
                    "file": java_file.relative_to(ROOT).as_posix(),
                })
    return apis[:50]


def ddd_discovery_from_modules(
    modules: list[ModuleCandidate], root: Path = ROOT
) -> dict[str, Any]:
    bc_candidates: list[dict[str, Any]] = []
    terms: list[dict[str, Any]] = []
    relations: list[dict[str, Any]] = []
    aggregates: list[dict[str, Any]] = []
    apis: list[dict[str, Any]] = []

    for mod in modules:
        module_dir = (root / mod.path).resolve()
        if not module_dir.is_dir():
            continue
        bc_candidates.append({
            "name": mod.key,
            "module_key": mod.key,
            "path": mod.path,
            "confidence": "low" if mod.kind == "library" else "medium",
            "source": "module-boundary",
        })
        module_apis = scan_apis_heuristic(module_dir)
        for item in module_apis:
            apis.append({**item, "module_key": mod.key})
        for java_file in module_dir.rglob("*.java"):
            if _is_secret_path(java_file):
                continue
            text = _read_text_safe(java_file, 20_000)
            src = java_file.relative_to(root).as_posix()
            if ENTITY_RE.search(text):
                name = java_file.stem
                classification = classify_entity(name, text)
                # anchor = 文件+符号名（不含行号），供 --check-doc-anchors 稳定校验
                term = {
                    "term": name,
                    "bc_candidate": mod.key,
                    "definition": "[待确认]",
                    "confidence": "medium",
                    "classification": classification,
                    "symbol": name,
                    "anchor": f"{src}#{name}",
                    "source": src,
                }
                terms.append(term)
                if classification == "aggregate":
                    aggregates.append({
                        "name": name,
                        "bc_candidate": mod.key,
                        "confidence": "medium",
                        "symbol": name,
                        "anchor": f"{src}#{name}",
                        "source": src,
                    })
            for em in ENUM_RE.finditer(text):
                ename = em.group(1)
                terms.append({
                    "term": ename,
                    "bc_candidate": mod.key,
                    "definition": "[待确认]",
                    "confidence": "low",
                    "classification": "supporting",
                    "symbol": ename,
                    "anchor": f"{src}#{ename}",
                    "source": src,
                })
            for fm in FEIGN_RE.finditer(text):
                relations.append({
                    "upstream": mod.key,
                    "downstream": fm.group(1),
                    "pattern": "[待确认]",
                    "confidence": "low",
                    "source": src,
                })
        for py_file in module_dir.rglob("*.py"):
            if _is_secret_path(py_file):
                continue
            text = _read_text_safe(py_file, 20_000)
            if "models.Model" not in text:
                continue
            src = py_file.relative_to(root).as_posix()
            for pm in PY_MODEL_RE.finditer(text):
                name = pm.group(1)
                classification = classify_entity(name, text)
                terms.append({
                    "term": name,
                    "bc_candidate": mod.key,
                    "definition": "[待确认]",
                    "confidence": "medium",
                    "classification": classification,
                    "symbol": name,
                    "anchor": f"{src}#{name}",
                    "source": src,
                })
                if classification == "aggregate":
                    aggregates.append({
                        "name": name,
                        "bc_candidate": mod.key,
                        "confidence": "medium",
                        "symbol": name,
                        "anchor": f"{src}#{name}",
                        "source": src,
                    })

    summary: dict[str, int] = {"aggregate": 0, "supporting": 0, "infrastructure": 0, "dto": 0}
    for t in terms:
        summary[t.get("classification", "aggregate")] = summary.get(t.get("classification", "aggregate"), 0) + 1

    return {
        "bc_candidates": bc_candidates,
        "terms": terms[:100],
        "aggregates": aggregates[:50],
        "relations": relations[:50],
        "apis": apis,
        "classification_summary": summary,
        "rejected": [],
    }


def render_mcp_json(modules: list[dict[str, Any]], root: Path = ROOT) -> dict[str, Any]:
    servers: dict[str, Any] = {}
    for mod in modules:
        cg = mod.get("codegraph") or {}
        if cg.get("status") != "ready":
            continue
        key = mod.get("key") or "module"
        path = mod.get("path") or "."
        servers[f"codegraph-{key}"] = {
            "command": "codegraph",
            "args": ["serve", "--mcp", "--path", f"${{workspaceFolder}}/{path}"],
        }
    return {"mcpServers": servers}


def _yaml_quote(value: str) -> str:
    if re.search(r"[:\[\]{}#&*!|>'\"%@`]", value) or value.strip() != value:
        return json.dumps(value, ensure_ascii=False)
    return value


def dump_manifest(data: dict[str, Any]) -> str:
    lines: list[str] = []

    def emit(key: str, val: Any, indent: int = 0) -> None:
        pad = "  " * indent
        if isinstance(val, dict):
            if indent == 0:
                lines.append(f"{pad}{key}:")
                for k, v in val.items():
                    emit(k, v, indent + 1)
            else:
                lines.append(f"{pad}{key}:")
                for k, v in val.items():
                    emit(k, v, indent + 1)
        elif isinstance(val, list):
            lines.append(f"{pad}{key}:")
            for item in val:
                if isinstance(item, dict) and len(item) == 1:
                    only_k, only_v = next(iter(item.items()))
                    lines.append(f"{pad}  - {only_k}: {_yaml_quote(str(only_v))}")
                elif isinstance(item, dict):
                    lines.append(f"{pad}  -")
                    for k, v in item.items():
                        emit(k, v, indent + 2)
                else:
                    lines.append(f"{pad}  - {_yaml_quote(str(item))}")
        else:
            lines.append(f"{pad}{key}: {_yaml_quote(str(val))}")

    for k, v in data.items():
        emit(k, v, 0)
    return "\n".join(lines) + "\n"


def load_manifest(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8", errors="ignore")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    return _parse_simple_yaml(text)


def _parse_simple_yaml(text: str) -> dict[str, Any]:
    """Minimal YAML subset for workspace-manifest."""
    root: dict[str, Any] = {}
    # stack of (container, indent, is_list_item_dict)
    stack: list[tuple[Any, int, bool]] = [(root, -1, False)]

    for raw_line in text.splitlines():
        if not raw_line.strip() or raw_line.strip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        line = raw_line.strip()

        while len(stack) > 1 and indent <= stack[-1][1]:
            stack.pop()

        parent, _, _ = stack[-1]

        if line.startswith("-"):
            item_line = line.lstrip("-").strip()
            if not isinstance(parent, list):
                continue
            if not item_line:
                new_item: dict[str, Any] = {}
                parent.append(new_item)
                stack.append((new_item, indent, True))
                continue
            if ":" in item_line:
                k, _, v = item_line.partition(":")
                new_item = {k.strip(): v.strip().strip('"').strip("'")}
                parent.append(new_item)
                stack.append((new_item, indent, True))
            else:
                parent.append(item_line.strip('"'))
            continue

        if ":" not in line:
            continue
        key, _, rest = line.partition(":")
        key = key.strip()
        val = rest.strip()

        if not val:
            list_keys = {"modules"}
            new_container: Any = [] if key in list_keys else {}
            if isinstance(parent, dict):
                parent[key] = new_container
            elif isinstance(parent, list) and parent and isinstance(parent[-1], dict):
                parent[-1][key] = new_container
            stack.append((new_container, indent, False))
            continue

        parsed_val: Any
        if val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            parsed_val = [x.strip().strip('"') for x in inner.split(",") if x.strip()] if inner else []
        elif val.lower() in ("true", "false"):
            parsed_val = val.lower() == "true"
        else:
            parsed_val = val.strip('"').strip("'")

        if isinstance(parent, dict):
            parent[key] = parsed_val
        elif isinstance(parent, list) and parent and isinstance(parent[-1], dict):
            parent[-1][key] = parsed_val

    return root


def build_manifest_from_discovery(
    modules: list[ModuleCandidate],
    commands_map: dict[str, dict[str, str]],
    root: Path,
    *,
    stage: str = "discover",
    xijia_base_ref: str = "",
    skip_codegraph: bool = False,
) -> dict[str, Any]:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    mod_entries: list[dict[str, Any]] = []
    for mod in modules:
        mod_dir = root / mod.path
        cg_status = "skipped" if skip_codegraph else "pending"
        cg_note = "skip-codegraph" if skip_codegraph else ""
        if not skip_codegraph and mod.kind in ("backend", "frontend") and mod_dir.is_dir():
            if codegraph_initialized(mod_dir):
                cg_status = "ready"
            else:
                cg_status = "pending"
        entry: dict[str, Any] = {
            "key": mod.key,
            "path": mod.path,
            "kind": mod.kind,
            "primary": mod.primary,
            "discovery": {
                "status": "draft",
                "confidence": mod.confidence,
                "source": ",".join(mod.signals),
            },
            "codegraph": {
                "status": cg_status,
                "index_path": ".codegraph/",
            },
        }
        if cg_note:
            entry["codegraph"]["skip_reason"] = cg_note
        mod_entries.append(entry)

    cmd_entries: dict[str, Any] = {}
    for mod in modules:
        cmds = commands_map.get(mod.key) or infer_commands(root / mod.path)
        if cmds:
            cmd_entries[mod.key] = {
                **cmds,
                "discovery": {"status": "draft", "source": "scan_workspace.py"},
            }

    return {
        "workspace": {"name": root.name, "adopted_at": now[:10]},
        "adopt": {"stage": stage, "skip_codegraph": skip_codegraph},
        "xijia_base_ref": xijia_base_ref or "unknown",
        "discovery": {
            "scanned_at": now,
            "scanner": "scan_workspace.py",
            "report": DISCOVERY_REL,
        },
        "modules": mod_entries,
        "commands": cmd_entries,
    }


def render_architecture_draft(modules: list[ModuleCandidate], stack: str) -> str:
    lines = [
        "# Architecture（Adopt Draft）",
        "",
        "> 由 `/xijia:adopt discover` 生成；content 阶段确认后转为活文档。",
        "",
        f"## Stack（draft）",
        "",
        stack or "待确认",
        "",
        "## Modules",
        "",
        "| moduleKey | path | kind | primary |",
        "| --- | --- | --- | --- |",
    ]
    for mod in modules:
        lines.append(f"| {mod.key} | {mod.path} | {mod.kind} | {mod.primary} |")
    lines.extend(["", "## 待确认", "", "- [ ] 模块职责描述", "- [ ] 跨模块依赖", ""])
    return "\n".join(lines)


def render_domain_draft(ddd: dict[str, Any]) -> tuple[str, dict[str, str]]:
    files: dict[str, str] = {}
    ctx_lines = [
        "# Context Map（Draft — candidates）",
        "",
        "> `[candidate]` 项须 content 阶段人工确认。",
        "",
        "## Bounded Contexts（candidates）",
        "",
    ]
    for bc in ddd.get("bc_candidates") or []:
        ctx_lines.append(f"- [candidate] {bc.get('name')} ({bc.get('confidence')})")
    ctx_lines.extend(["", "## Relationship Matrix（candidates）", "", "| Upstream | Downstream | Pattern |", "| --- | --- | --- |"])
    for rel in ddd.get("relations") or []:
        ctx_lines.append(
            f"| {rel.get('upstream')} | {rel.get('downstream')} | [待确认] |"
        )
    files["docs/domain/_draft/context-map.md"] = "\n".join(ctx_lines) + "\n"

    by_bc: dict[str, list[dict[str, Any]]] = {}
    for term in ddd.get("terms") or []:
        bc = term.get("bc_candidate") or "unknown"
        by_bc.setdefault(bc, []).append(term)
    for bc, terms in by_bc.items():
        # 分层：核心（聚合+支撑）进主表优先确认；基础设施/DTO 折叠为附录（不丢弃、可展开）。
        core = [t for t in terms if t.get("classification", "aggregate") in ("aggregate", "supporting")]
        folded = [t for t in terms if t.get("classification", "aggregate") in ("infrastructure", "dto")]
        core.sort(key=lambda t: 0 if t.get("classification") == "aggregate" else 1)
        ul_lines = [
            f"# Ubiquitous Language — {bc}（Draft）",
            "",
            "> 主表=核心聚合+关键支撑（优先确认）；基础设施/DTO 已折叠至文末附录（不丢弃，需要时展开）。",
            "",
            "| 术语 | 分类 | 定义 | confidence | anchor |",
            "| --- | --- | --- | --- | --- |",
        ]
        for t in core[:30]:
            ul_lines.append(
                f"| {t.get('term')} | {t.get('classification', 'aggregate')} | [待确认] | "
                f"{t.get('confidence')} | {t.get('anchor') or t.get('source')} |"
            )
        if folded:
            ul_lines.extend([
                "",
                f"<details><summary>附录：{len(folded)} 个基础设施/DTO 术语（默认折叠，确认时展开）</summary>",
                "",
                "| 术语 | 分类 | anchor |",
                "| --- | --- | --- |",
            ])
            for t in folded[:50]:
                ul_lines.append(
                    f"| {t.get('term')} | {t.get('classification')} | {t.get('anchor') or t.get('source')} |"
                )
            ul_lines.extend(["", "</details>"])
        files[f"docs/domain/_draft/{bc}/ubiquitous-language.md"] = "\n".join(ul_lines) + "\n"
    return files["docs/domain/_draft/context-map.md"], files


def render_capability_draft(ddd: dict[str, Any]) -> str:
    lines = [
        "# Capability Map（Draft — 非活文档）",
        "",
        "> API 索引草稿；活文档 `docs/capability-map.md` 由 Gate-3 合并。",
        "",
        "| moduleKey | API | source |",
        "| --- | --- | --- |",
    ]
    for api in ddd.get("apis") or []:
        lines.append(f"| {api.get('module_key')} | {api.get('path')} | {api.get('file')} |")
    return "\n".join(lines) + "\n"


def scan_entrypoints(modules: list[ModuleCandidate], root: Path = ROOT) -> list[dict[str, Any]]:
    """收集入口点：Java 定时任务 + Python celery 任务 / 管理命令（API 入口由 apis 承载）。

    每个入口带 anchor（文件+符号名，无行号），作为流程重建的起点。
    """
    entrypoints: list[dict[str, Any]] = []
    for mod in modules:
        module_dir = (root / mod.path).resolve()
        if not module_dir.is_dir():
            continue
        for java_file in module_dir.rglob("*.java"):
            if _is_secret_path(java_file):
                continue
            text = _read_text_safe(java_file, 20_000)
            if "@Scheduled" not in text:
                continue
            src = java_file.relative_to(root).as_posix()
            for m in JAVA_SCHEDULED_RE.finditer(text):
                entrypoints.append({
                    "kind": "scheduled",
                    "name": m.group(1),
                    "bc_candidate": mod.key,
                    "anchor": f"{src}#{m.group(1)}",
                    "source": src,
                })
        for py_file in module_dir.rglob("*.py"):
            if _is_secret_path(py_file):
                continue
            text = _read_text_safe(py_file, 20_000)
            src = py_file.relative_to(root).as_posix()
            for m in PY_TASK_RE.finditer(text):
                entrypoints.append({
                    "kind": "task",
                    "name": m.group(1),
                    "bc_candidate": mod.key,
                    "anchor": f"{src}#{m.group(1)}",
                    "source": src,
                })
            if PY_COMMAND_RE.search(text):
                # Django 管理命令：以文件名（命令名）作为符号
                cmd_name = py_file.stem
                entrypoints.append({
                    "kind": "command",
                    "name": cmd_name,
                    "bc_candidate": mod.key,
                    "anchor": f"{src}#Command",
                    "source": src,
                })
    return entrypoints


def render_flow_draft(entrypoints: list[dict[str, Any]], apis: list[dict[str, Any]]) -> str:
    """行为驱动业务流程草稿：按入口聚合候选流程，每条带锚点 + [待确认] 调用链占位。

    调用链在有 codegraph 时于 content 阶段补全；此处只落起点与业务含义占位，绝不臆造。
    """
    lines = [
        "# Business Flow（Adopt Draft — 行为驱动重建）",
        "",
        "> 由 `/xijia:adopt discover` 从入口（API/任务/命令）生成。每条流程为候选，`[待确认]` 项须 content 阶段人工确认；",
        "> 调用链在 codegraph 可用时补全，否则保留占位——**不臆造**。确认后合入活文档 `docs/flow.md`。",
        "",
    ]
    kind_label = {"api": "API", "task": "异步任务", "scheduled": "定时任务", "command": "命令行"}

    # API 入口
    if apis:
        lines.extend(["## API 触发的流程（候选）", "", "| 入口 | 业务含义 | 调用链 | anchor |", "| --- | --- | --- | --- |"])
        for api in apis[:50]:
            anchor = f"{api.get('file')}#{api.get('controller')}"
            lines.append(f"| {api.get('path')} | [待确认] | [待确认：调用链] | {anchor} |")
        lines.append("")

    if entrypoints:
        lines.extend(["## 任务 / 命令触发的流程（候选）", "", "| 入口 | 类型 | 业务含义 | 调用链 | anchor |", "| --- | --- | --- | --- | --- |"])
        for ep in entrypoints[:50]:
            label = kind_label.get(ep.get("kind", ""), ep.get("kind", ""))
            lines.append(
                f"| {ep.get('name')} | {label} | [待确认] | [待确认：调用链] | {ep.get('anchor')} |"
            )
        lines.append("")

    if not apis and not entrypoints:
        lines.extend(["> 未发现显式入口（API/任务/命令）；主流程需 content 阶段人工补全。", ""])

    lines.extend([
        "## 待确认",
        "",
        "- [ ] 每条流程的业务含义（一句话）",
        "- [ ] 调用链关键节点（codegraph 可用时补全）",
        "- [ ] 归并为 ≤N 条主流程（供 `/xijia:overview` 业务主流程段引用）",
        "",
    ])
    return "\n".join(lines)


def run_discover_modules_only(root: Path, out: Path | None) -> int:
    modules = discover_modules(root)
    payload = {
        "modules": [m.to_dict() for m in modules],
        "stack": infer_stack_summary(modules),
    }
    if out:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[scan-workspace] discovered {len(modules)} module(s)")
    for mod in modules:
        print(f"  - {mod.key}: {mod.path} ({mod.kind})")
    return 0


def run_preflight_codegraph(root: Path, *, dry_run: bool = False, skip: bool = False) -> int:
    manifest_path = root / MANIFEST_REL
    manifest = load_manifest(manifest_path)
    modules_raw = manifest.get("modules") or []
    if not modules_raw:
        modules = discover_modules(root)
        manifest = build_manifest_from_discovery(
            modules,
            {},
            root,
            stage="preflight",
            skip_codegraph=skip,
        )
        modules_raw = manifest["modules"]

    if skip:
        print("[scan-workspace] preflight: skip-codegraph")
        for mod in modules_raw:
            if isinstance(mod, dict) and mod.get("kind") in ("backend", "frontend"):
                mod.setdefault("codegraph", {})["status"] = "skipped"
                mod["codegraph"]["skip_reason"] = "user skip-codegraph"
        manifest["adopt"] = manifest.get("adopt") or {}
        manifest["adopt"]["stage"] = "preflight"
        manifest["adopt"]["skip_codegraph"] = True
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(dump_manifest(manifest), encoding="utf-8")
        return 0

    ok, msg = codegraph_cli_available()
    if not ok:
        print(f"[scan-workspace] preflight FAIL: {msg}")
        return 1
    print(f"[scan-workspace] codegraph CLI: {msg}")

    failed = 0
    for mod in modules_raw:
        if not isinstance(mod, dict):
            continue
        if mod.get("kind") not in ("backend", "frontend"):
            mod.setdefault("codegraph", {})["status"] = "not_applicable"
            continue
        mod_path = root / str(mod.get("path", "."))
        status, note = codegraph_init(mod_path, dry_run=dry_run)
        mod.setdefault("codegraph", {})
        mod["codegraph"]["status"] = status
        mod["codegraph"]["index_path"] = note if status == "ready" else ".codegraph/"
        if status == "init_failed":
            mod["codegraph"]["error"] = note
            failed += 1
        print(f"  - {mod.get('key')}: {status}")

    mcp = render_mcp_json(modules_raw, root)
    mcp_path = root / ".cursor" / "mcp.json"
    mcp_path.parent.mkdir(parents=True, exist_ok=True)
    mcp_path.write_text(json.dumps(mcp, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[scan-workspace] wrote {mcp_path.relative_to(root)}")

    manifest["adopt"] = manifest.get("adopt") or {}
    manifest["adopt"]["stage"] = "preflight"
    manifest_path.write_text(dump_manifest(manifest), encoding="utf-8")
    return 1 if failed else 0


def run_full_discover(root: Path, *, skip_codegraph: bool = False) -> int:
    modules = discover_modules(root)
    commands_map = {m.key: infer_commands(root / m.path) for m in modules}
    stack = infer_stack_summary(modules)
    ddd = ddd_discovery_from_modules(modules, root)

    discovery = {
        "scanned_at": datetime.now(timezone.utc).isoformat(),
        "modules": [m.to_dict() for m in modules],
        "commands": commands_map,
        "stack": stack,
    }
    gen_dir = root / "docs" / ".generated"
    gen_dir.mkdir(parents=True, exist_ok=True)
    (gen_dir / "adopt-discovery.json").write_text(
        json.dumps(discovery, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (gen_dir / "ddd-discovery.json").write_text(
        json.dumps(ddd, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    manifest = build_manifest_from_discovery(
        modules, commands_map, root, stage="discover", skip_codegraph=skip_codegraph
    )
    manifest_path = root / MANIFEST_REL
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(dump_manifest(manifest), encoding="utf-8")

    arch = root / "docs" / "architecture.md"
    if not arch.exists() or "[待确认]" in _read_text_safe(arch, 500):
        arch.write_text(render_architecture_draft(modules, stack), encoding="utf-8")

    _, draft_files = render_domain_draft(ddd)
    for rel, content in draft_files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")

    cap_draft = root / "docs" / "capability-map.draft.md"
    cap_draft.write_text(render_capability_draft(ddd), encoding="utf-8")

    entrypoints = scan_entrypoints(modules, root)
    (gen_dir / "adopt-entrypoints.json").write_text(
        json.dumps(entrypoints, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    flow_draft = root / "docs" / "flow.draft.md"
    flow_draft.write_text(render_flow_draft(entrypoints, ddd.get("apis") or []), encoding="utf-8")

    print(
        f"[scan-workspace] discover done: {len(modules)} modules, stack={stack}, "
        f"{len(entrypoints)} entrypoint(s), classes={ddd.get('classification_summary')}"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Xijia adopt workspace scanner")
    parser.add_argument("--root", default=str(ROOT), help="workspace root")
    parser.add_argument("--discover-modules-only", action="store_true")
    parser.add_argument("--preflight-codegraph", action="store_true")
    parser.add_argument("--discover", action="store_true", help="full discover (default if no flag)")
    parser.add_argument("--ddd-discovery", action="store_true")
    parser.add_argument("--out", default="", help="output json path")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-codegraph", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out = Path(args.out) if args.out else None

    if args.discover_modules_only:
        return run_discover_modules_only(root, out or root / DISCOVERY_REL)
    if args.preflight_codegraph:
        return run_preflight_codegraph(root, dry_run=args.dry_run, skip=args.skip_codegraph)
    if args.ddd_discovery:
        modules = discover_modules(root)
        ddd = ddd_discovery_from_modules(modules, root)
        target = out or root / DDD_DISCOVERY_REL
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(ddd, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"[scan-workspace] wrote {target.relative_to(root)}")
        return 0
    return run_full_discover(root, skip_codegraph=args.skip_codegraph)


if __name__ == "__main__":
    raise SystemExit(main())
