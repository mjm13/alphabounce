#!/usr/bin/env python3
"""Adopt/verify orchestrators: doc-links, doc-anchors, stack-drift, adopt-readiness."""

from __future__ import annotations

import subprocess
import sys
from dataclasses import dataclass
from typing import Any

from guardlib import paths
from guardlib.livingdocs import (
    DOC_ANCHOR_RE,
    agents_command_section_ready,
    ci_or_local_declared,
    inbox_active_requirements,
    iter_living_doc_files,
    living_doc_link_issues,
    stack_drift_issues,
)
from guardlib.requirement import PENDING_CONFIRM_RE


def _run_check_doc_links() -> int:
    issues = living_doc_link_issues()
    if issues:
        print("[doc-links] 未通过：")
        for issue in issues:
            print(f"  - {issue}")
        return 1
    print("[doc-links] OK：活文档索引链接可解析")
    return 0


def _run_check_doc_anchors() -> int:
    """校验活文档中的 `文件#符号` 锚点是否仍可解析（防文档-代码漂移）。

    文件缺失 → 硬失败（真漂移）；文件在但符号未出现 → 警告（可能重命名，人工确认）。
    Gate-3（xijia-sync-knowledge）与 docs-score 定期调用。
    """
    files = iter_living_doc_files()
    if not files:
        print("[doc-anchors] 无活文档，跳过。")
        return 0

    missing_file: list[str] = []
    missing_symbol: list[str] = []
    total = 0
    text_cache: dict[str, str] = {}
    for md in files:
        content = md.read_text(encoding="utf-8", errors="ignore")
        md_rel = md.relative_to(paths.ROOT).as_posix()
        for m in DOC_ANCHOR_RE.finditer(content):
            rel_path, symbol = m.group(1), m.group(2)
            # 跳过占位/模板类锚点
            if "<" in rel_path or "待" in rel_path:
                continue
            total += 1
            target = (paths.ROOT / rel_path).resolve()
            if not target.is_file():
                missing_file.append(f"{md_rel}: 锚点文件不存在 {rel_path}#{symbol}")
                continue
            if rel_path not in text_cache:
                text_cache[rel_path] = target.read_text(encoding="utf-8", errors="ignore")
            if symbol not in text_cache[rel_path]:
                missing_symbol.append(f"{md_rel}: {rel_path} 中未找到符号 '{symbol}'（疑似重命名）")

    for w in missing_symbol:
        print(f"[doc-anchors] WARN: {w}")
    if missing_file:
        print("[doc-anchors] FAIL：以下锚点的目标文件缺失（文档-代码漂移）：")
        for item in missing_file:
            print(f"  - {item}")
        print("  → 修正锚点或补回文件；锚点用 文件+符号名（不写行号）。")
        return 1
    print(
        f"[doc-anchors] OK：{total} 个锚点文件均存在"
        + (f"（{len(missing_symbol)} 个符号疑似重命名，见 WARN）" if missing_symbol else "")
    )
    return 0


def _run_check_stack_drift() -> int:
    issues = stack_drift_issues()
    if issues:
        print("[stack-drift] 未通过：")
        for issue in issues:
            print(f"  - {issue}")
        print("[stack-drift] 栈 reversal 后须同步 README.md、architecture.md、AGENTS.md、openspec/config.yaml")
        return 1
    print("[stack-drift] OK：活文档栈关键词与 architecture 一致")
    return 0


@dataclass(frozen=True)
class AdoptResult:
    hard: tuple[str, ...] = ()
    warnings: tuple[str, ...] = ()
    messages: tuple[str, ...] = ()


def _adopt_required_issues() -> list[str]:
    hard: list[str] = []
    if not (paths.ROOT / ".cursor/rules/00-workflow.mdc").is_file():
        hard.append("H1: 缺少 .cursor/rules/00-workflow.mdc")
    if not (paths.ROOT / ".cursor/hooks/pipeline_guard.py").is_file():
        hard.append("H1: 缺少 .cursor/hooks/pipeline_guard.py")
    required = (
        "AGENTS.md", "docs/constitution.md", "docs/README.md", "docs/llms.txt",
        "docs/domain/README.md",
        ".cursor/templates/requirements/requirements-template.md",
        ".cursor/templates/requirements/technical-requirement-template.md",
        "docs/requirements/backlog.md",
        "docs/requirements/inbox/README.md", "docs/process/project-lifecycle.md",
        "docs/process/release-checklist.md", "docs/process/knowledge-maintenance.md",
        "docs/workspace-manifest.yaml", "docs/decisions/0002-project-adoption.md",
    )
    missing = [rel for rel in required if not (paths.ROOT / rel).is_file()]
    if missing:
        hard.append(f"H2: 文档最小集缺失 {len(missing)} 项：{', '.join(missing[:5])}" + (
            " …" if len(missing) > 5 else ""
        ))
    return hard


def _manifest_issues(manifest: dict[str, Any], manifest_rel: str) -> list[str]:
    if not manifest:
        return [f"H3: 无法解析 {manifest_rel}"]
    hard: list[str] = []
    modules = manifest.get("modules") or []
    commands = manifest.get("commands") or {}
    if not modules:
        hard.append("H3: workspace-manifest 无 modules")
    skip_codegraph = bool((manifest.get("adopt") or {}).get("skip_codegraph"))
    for mod in (item for item in modules if isinstance(item, dict)):
        rel_path = str(mod.get("path", ""))
        if not rel_path:
            hard.append("H3: module 缺少 path")
            continue
        if not (paths.ROOT / rel_path).is_dir():
            hard.append(f"H3: 模块路径不存在 {rel_path}")
        if (mod.get("discovery") or {}).get("status") == "draft":
            hard.append(f"H10: 模块 {mod.get('key')} discovery 仍为 draft")
        codegraph = mod.get("codegraph") or {}
        if not skip_codegraph and mod.get("kind") in ("backend", "frontend"):
            status = codegraph.get("status")
            if status not in ("ready", "skipped"):
                hard.append(f"H11: 模块 {mod.get('key')} codegraph.status={status!r}（须 ready 或 skipped+理由）")
            elif status == "skipped" and not codegraph.get("skip_reason"):
                hard.append(f"H11: 模块 {mod.get('key')} codegraph skipped 缺少 skip_reason")
    hard.extend(_manifest_command_issues(modules, commands))
    ddd_required = bool(manifest.get("ddd_required") or (manifest.get("workspace") or {}).get("ddd_required"))
    if ddd_required and not (paths.ROOT / "docs/domain/context-map.md").is_file():
        hard.append("H12: ddd_required 但缺少 docs/domain/context-map.md")
    return hard


def _manifest_command_issues(modules: list[Any], commands: dict[str, Any]) -> list[str]:
    issues: list[str] = []
    for key, command in commands.items():
        if isinstance(command, dict) and (command.get("discovery") or {}).get("status") == "draft":
            issues.append(f"H10: commands.{key} discovery 仍为 draft")
    for module in (item for item in modules if isinstance(item, dict) and item.get("primary")):
        key = module.get("key")
        command = commands.get(key) if key else None
        if not isinstance(command, dict) or not command.get("install") or not command.get("test"):
            issues.append(f"H5: primary 模块 {key} 缺少 install/test 命令")
    return issues


def _agents_and_policy_issues() -> AdoptResult:
    hard: list[str] = []
    messages: list[str] = []
    ok, message = agents_command_section_ready()
    if ok:
        messages.append(f"[adopt-readiness] AGENTS: {message}")
    else:
        hard.append(f"H4: {message}")
    agents = paths.ROOT / "AGENTS.md"
    if agents.is_file():
        text = agents.read_text(encoding="utf-8", errors="ignore")
        for section in ("Layout", "Testing", "Security"):
            if section in text and "<待补充>" in text.split(f"## {section}", 1)[-1].split("##", 1)[0]:
                hard.append(f"H9: AGENTS {section} 含 <待补充>")
    script = paths.ROOT / ".cursor/hooks/policy_flow_drift_check.py"
    if not script.is_file():
        hard.append("H6: 缺少 policy_flow_drift_check.py")
    elif subprocess.run(
        [sys.executable, str(script)], cwd=paths.ROOT, capture_output=True, text=True,
        encoding="utf-8", errors="replace",
    ).returncode != 0:
        hard.append("H6: policy_flow_drift_check 未通过")
    return AdoptResult(tuple(hard), messages=tuple(messages))


def _adopt_living_doc_issues() -> AdoptResult:
    hard: list[str] = []
    messages: list[str] = []
    link_issues = living_doc_link_issues()
    if link_issues:
        messages.append("[doc-links] 未通过：")
        messages.extend(f"  - {issue}" for issue in link_issues)
        hard.append("H7: --check-doc-links 未通过")
    else:
        messages.append("[doc-links] OK：活文档索引链接可解析")
    drift_issues = stack_drift_issues()
    if drift_issues:
        messages.append("[stack-drift] 未通过：")
        messages.extend(f"  - {issue}" for issue in drift_issues)
        messages.append("[stack-drift] 栈 reversal 后须同步 README.md、architecture.md、AGENTS.md、openspec/config.yaml")
        hard.append("H8: --check-stack-drift 未通过（需 docs/architecture.md）")
    else:
        messages.append("[stack-drift] OK：活文档栈关键词与 architecture 一致")
    return AdoptResult(tuple(hard), messages=tuple(messages))


def _module_readiness_issues(manifest: dict[str, Any]) -> AdoptResult:
    hard: list[str] = []
    warnings: list[str] = []
    modules = manifest.get("modules") or []
    commands = manifest.get("commands") or {}
    for module in (item for item in modules if isinstance(item, dict)):
        key = module.get("key")
        module_dir = paths.ROOT / str(module.get("path", ""))
        if module_dir.is_dir() and not any(module_dir.iterdir()):
            hard.append(f"L2: 模块 {key} 目录为空")
        command = commands.get(key) if key else None
        if isinstance(command, dict):
            if not command.get("install") or not command.get("test"):
                hard.append(f"L2: 模块 {key} 缺少 install/test")
            if module.get("kind") == "frontend" and not (command.get("dev") or command.get("build")):
                warnings.append(f"L2: 前端模块 {key} 建议补充 dev/build")
    backends = [item for item in modules if isinstance(item, dict) and item.get("kind") == "backend"]
    if backends and not any(item.get("primary") for item in backends):
        hard.append("L2: 无 primary backend 模块")
    return AdoptResult(tuple(hard), tuple(warnings))


def _adopt_warning_issues(manifest: dict[str, Any]) -> list[str]:
    warnings: list[str] = []
    if not (paths.ROOT / "docs/capability-map.md").is_file():
        warnings.append("W1: capability-map 空（可接受；可选 /xijia:backfill-index）")
    domain_dir = paths.ROOT / "docs/domain"
    if domain_dir.is_dir() and not (domain_dir / "context-map.md").is_file():
        warnings.append("W7: DDD 仅在 _draft，content 未提升" if (domain_dir / "_draft").is_dir()
                        else "W2: domain 仅 README（可接受）")
    pending = [
        file.parent.name for file in domain_dir.rglob("ubiquitous-language.md")
        if "_draft" not in file.parts
        and PENDING_CONFIRM_RE.search(file.read_text(encoding="utf-8", errors="ignore"))
    ] if domain_dir.is_dir() else []
    if pending:
        warnings.append(
            f"W9: {len(pending)} 个 BC 仍含 [待确认]（partial-BC 允许，可分批推进；"
            f"Adoption Gate 请知悉）：{', '.join(sorted(set(pending))[:5])}"
        )
    if (manifest.get("adopt") or {}).get("skip_codegraph"):
        warnings.append("W8: codegraph 已降级 skip-codegraph")
    try:
        branch = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=paths.ROOT, capture_output=True,
            text=True, encoding="utf-8", errors="replace", check=True,
        ).stdout.strip()
        if branch and branch != "master":
            warnings.append(f"W3: 当前分支 {branch!r}，建议 master")
    except subprocess.CalledProcessError:
        warnings.append("W3: 无法检测 git 分支")
    ci_ok, ci_message = ci_or_local_declared()
    if not ci_ok:
        warnings.append(f"W4: {ci_message}")
    active = inbox_active_requirements()
    if active:
        warnings.append(f"W5: inbox 未完成 {len(active)} 项")
    return warnings


def _adopt_readiness_issues(manifest: dict[str, Any], manifest_rel: str) -> AdoptResult:
    parts = (
        AdoptResult(tuple(_adopt_required_issues())),
        AdoptResult(tuple(_manifest_issues(manifest, manifest_rel))),
        _agents_and_policy_issues(),
        _adopt_living_doc_issues(),
        _module_readiness_issues(manifest) if manifest else AdoptResult(),
    )
    return AdoptResult(
        tuple(issue for part in parts for issue in part.hard),
        tuple(issue for part in parts for issue in part.warnings) + tuple(_adopt_warning_issues(manifest)),
        tuple(message for part in parts for message in part.messages),
    )


def _run_check_adopt_readiness() -> int:
    """Iteration readiness for historical multi-module adoption (H1–H12 + L2)."""
    if not (paths.ROOT / "docs").is_dir():
        print("[adopt-readiness] SKIP：模板基座未初始化 docs/；请在 adopt 目标完成 scaffold 后运行。")
        return 0
    import scan_workspace as sw  # noqa: WPS433 — hook sibling module
    result = _adopt_readiness_issues(
        sw.load_manifest(paths.ROOT / sw.MANIFEST_REL),
        sw.MANIFEST_REL,
    )
    for message in result.messages:
        print(message)
    for warning in result.warnings:
        print(f"[adopt-readiness] WARN: {warning}")
    if result.hard:
        print("[adopt-readiness] FAIL:")
        for issue in result.hard:
            print(f"  - {issue}")
        print("  → 回到 /xijia:adopt content 补全后重跑 verify")
        return 1
    print("[adopt-readiness] OK：H1–H11 通过（警告项请 Adoption Gate 人审）")
    return 0
