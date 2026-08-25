"""Gate-3 process archival and knowledge-distillation helpers."""

from __future__ import annotations

import json
import re
from pathlib import Path

from . import paths
from .markdown import extract_section
from .requirement import (
    domain_impact_declares_new_inv,
    domain_impact_inv_ids,
    gate0_is_complete,
    gate0_is_partial,
    gate0_pending_breakpoints,
    gate1_is_approved,
    gate2_is_accepted,
    has_green_trivial_marker,
    is_confirmed_cell,
    is_red_requirement_text,
    parse_closure_table,
    parse_frontmatter_ddd_class,
    parse_frontmatter_openspec_change,
    parse_frontmatter_status,
    parse_frontmatter_type,
    parse_gate_records,
    resolve_tier,
    PATTERN_DOC_REF_RE,
    SYSTEM_LIST_UI_TOUCH_RE,
)

EXPERIENCE_DOC_RE = re.compile(r"docs/(?:pitfalls|patterns)/[A-Za-z0-9_\-./]+\.md")
NO_REUSE_RE = re.compile(r"Experience\s*Reuse\b[^\n]*\bnone\b|无经验复用|未命中(?:任何)?(?:可复用|经验)", re.I)
EXPERIENCE_REUSE_LINE_RE = re.compile(
    r"(?im)^\s*[-*]?\s*Experience\s*Reuse\s*:\s*(.+?)\s*$",
)
DISTILL_MARKER_LINE_RE = re.compile(
    r"(?im)^\s*[-*]?\s*(Patterns|Pitfalls|Capability\s*Index|Living\s*Docs|Flow)\s*:\s*",
)

LIVING_DOC_RELS = (
    "AGENTS.md",
    "README.md",
    "docs/llms.txt",
    "docs/README.md",
    "docs/architecture.md",
    "docs/openspec/config.yaml",
    "docs/constitution.md",
)
NOOP_TOUCH_RULES: dict[str, tuple[str, ...]] = {
    "Patterns": ("docs/patterns/",),
    "Pitfalls": ("docs/pitfalls/",),
    "Capability Index": ("docs/capability-map.md",),
    "Living Docs": LIVING_DOC_RELS + ("docs/domain/",),
    "Flow": ("docs/flow.md",),
    "Domain": ("docs/domain/",),
}


def process_docs_archive_issues(req: Path, text: str) -> list[str]:
    status = parse_frontmatter_status(text)
    if status not in ("shipped", "archived"):
        return []
    issues: list[str] = []
    resolved = req.resolve()
    if paths.INBOX_DIR in resolved.parents:
        issues.append(
            "需求状态为已交付/已归档，但文件仍在 docs/requirements/inbox/："
            "请 Move-Item 至 docs/requirements/shipped/（禁止 Write 重建）"
        )
    if status == "shipped" and paths.SHIPPED_DIR.is_dir() and paths.SHIPPED_DIR not in resolved.parents:
        issues.append("需求状态为已交付，但文件不在 docs/requirements/shipped/")
    if is_red_requirement_text(text) and (change := parse_frontmatter_openspec_change(text)):
        if (paths.CHANGES_DIR / change).is_dir() and not (paths.ARCHIVE_CHANGES_DIR / change).is_dir():
            issues.append(f"红档 OpenSpec change '{change}' 仍在活跃目录，未归档至 docs/openspec/changes/archive/")
    return issues


def gate3_preflight_issues(req: Path, text: str | None = None) -> tuple[list[str], list[str]]:
    """Gate-3 Move 前预检。返回 (errors, warnings)。

    - inbox 路径必须存在；不存在 → 硬失败，并提示禁止 rebuild shipped
    - Gate-2 须已验收；frontmatter 宜为已交付（Move 前在 inbox 写齐）
    - 已交付仍在 inbox → warning「请 Move」
    - inbox 缺失但 shipped 同名存在 → warning「疑似 rebuild 非 Move」
    """
    errors: list[str] = []
    warnings: list[str] = []
    req = req.resolve() if req.is_absolute() else (paths.ROOT / req).resolve()
    shipped_same = paths.SHIPPED_DIR / req.name

    if not req.is_file():
        errors.append(
            f"需求文档不存在：{req}。"
            "禁止用会话记忆在 shipped 全量重建；请用 Shell Test-Path / git status 定位。"
        )
        if shipped_same.is_file():
            warnings.append(
                f"shipped 已存在同名文件 {shipped_same.as_posix()}；"
                "若非 Move 归档，疑似 rebuild。勿用 Cursor Write/Task 覆盖。"
            )
        return errors, warnings

    body = text if text is not None else paths.read_utf8_text(req)
    gates = parse_gate_records(body)
    gate2_ok, gate2_reason = gate2_is_accepted(gates.get("Gate-2"))
    if not gate2_ok:
        errors.append(f"Gate-2 未验收（{gate2_reason}）。须先完成 Gate-2 签字，再在 inbox 改状态/写总结后 Move。")

    status = parse_frontmatter_status(body)
    in_inbox = paths.INBOX_DIR in req.parents
    in_shipped = paths.SHIPPED_DIR in req.parents

    if in_shipped:
        warnings.append("当前 --req 已在 shipped；Move 前预检应对 inbox 路径调用。")
    elif in_inbox:
        if status == "shipped":
            warnings.append(
                "状态已为已交付但仍在 inbox：内容写齐后请 Move-Item 至 "
                "docs/requirements/shipped/（禁止 Write 重建）。"
            )
        else:
            warnings.append(
                "frontmatter 状态尚未为已交付：Move 前须在 inbox 完成「改状态 → 写总结」。"
            )
    else:
        warnings.append(f"需求路径不在 inbox/shipped：{req}")

    if not in_shipped and shipped_same.is_file() and req.is_file():
        warnings.append(
            f"inbox 与 shipped 同时存在同名文件（{shipped_same.name}）；"
            "归档脚本拒绝覆盖 shipped，请人工确认是否误 rebuild。"
        )

    try:
        from .gitio import changed_all_files

        changed = changed_all_files("HEAD")
    except Exception:
        changed = []
    from .gate3_triggers import gate3_preflight_trigger_warnings

    warnings.extend(gate3_preflight_trigger_warnings(body, changed))

    return errors, warnings


def _gate0_resolve_action(text: str, gate0: dict[str, str] | None) -> tuple[str, str]:
    """Return (next_user_action, optional hint) when Gate-0 is not complete."""
    breakpoints = gate0_pending_breakpoints(text)
    if breakpoints:
        preview = "；".join(breakpoints[:3])
        more = f" 等共 {len(breakpoints)} 处" if len(breakpoints) > 3 else ""
        action = (
            f"请确认并闭合待确认断点（歧义登记/数据流闭环表/Open Questions）：{preview}{more}"
        )
        return action, ""
    if gate0_is_partial(gate0):
        hint = (
            "Gate-0 标为「部分通过」但正文无待确认断点；"
            "若 DEF 仅作延期，请确认后改为「已通过」。"
        )
        return "正文无待确认断点，请文字确认 Gate-0 完整性并改为「已通过」", hint
    return "请补充需求缺口或确认 Gate-0 完整性", ""


_UI_RUNTIME_EVIDENCE_RE = re.compile(r"截图|实机|组件测试")
_UNEXECUTED_EVIDENCE_RE = re.compile(r"未执行|未验证|仅推断|待执行")
_VERIFY_PASSED_RE = re.compile(r"verify.*通过|全通过|tests?\s+passed|exit\s+0", re.I)


def gate2_acceptance_has_evidence(text: str) -> bool:
    """True when Gate-2 验收记录已有可提交的 verify / 运行时证据。

    支持 AC 表格行、bullet 组件测试/实机/截图、verify 通过描述、已勾选 AC。
    """
    section = extract_section(text, "验收记录")
    if not section:
        return False
    for line in section.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("|"):
            cells = [cell.strip() for cell in stripped.strip("|").split("|")]
            if len(cells) < 2:
                continue
            ac_cell, conclusion = cells[0], cells[1]
            if ac_cell.lower() in {"ac", "—", "-"} or "结论" in ac_cell:
                continue
            if re.match(r"^:?-+:?$", ac_cell.replace(" ", "")):
                continue
            if conclusion and conclusion not in {"未执行", "—", "-", ""}:
                return True
            continue
        if _UI_RUNTIME_EVIDENCE_RE.search(stripped) and not _UNEXECUTED_EVIDENCE_RE.search(stripped):
            return True
        if _VERIFY_PASSED_RE.search(stripped) and not _UNEXECUTED_EVIDENCE_RE.search(stripped):
            return True
        if re.match(r"^-\s*\[[x~]\]", stripped, re.I):
            return True
    criteria = extract_section(text, "验收标准")
    if criteria and re.search(r"^-\s*\[~]", criteria, re.M | re.I):
        return True
    return False


def gate1_ac_premature_full_checks(text: str, *, gate2_accepted: bool) -> list[str]:
    """Return AC ids marked [x] in 验收标准 while Gate-2 is not yet accepted."""
    if gate2_accepted:
        return []
    section = extract_section(text, "验收标准")
    if not section:
        return []
    premature: list[str] = []
    for line in section.splitlines():
        match = re.match(r"^-\s*\[x\]\s*\*\*(AC-[^*]+)\*\*", line.strip(), re.I)
        if match:
            premature.append(match.group(1))
    return premature


def resolve_current_gate(req: Path, text: str) -> dict[str, str]:
    records, status = parse_gate_records(text), parse_frontmatter_status(text)
    gate0 = records.get("Gate-0")
    gate0_ok, gate0_reason = gate0_is_complete(gate0, status)
    if not gate0_ok:
        action, hint = _gate0_resolve_action(text, gate0)
        result = {
            "current_gate": "Gate-0",
            "reason": gate0_reason,
            "next_user_action": action,
            "blocked_gates": "Gate-1,Gate-2,Gate-3",
        }
        if hint:
            result["hint"] = hint
        return result
    gate1_ok, gate1_reason = gate1_is_approved(records.get("Gate-1"))
    if not gate1_ok:
        return {
            "current_gate": "Gate-1",
            "reason": gate1_reason,
            "next_user_action": "请用户文字批准方案与验收（Gate-1）",
            "blocked_gates": "Gate-2,Gate-3",
        }
    gate2_ok, gate2_reason = gate2_is_accepted(records.get("Gate-2"))
    if not gate2_ok:
        if not gate2_acceptance_has_evidence(text):
            return {
                "current_gate": "实现",
                "reason": "Gate-1 已批准；验收记录未齐备，须先实现并 verify",
                "next_user_action": "无，继续执行",
                "blocked_gates": "Gate-3",
                "hint": "禁止反问「是否开始实现」；同轮进入 OpenSpec apply（红档）或 Gate-1 切片 TDD（绿/黄）",
            }
        return {
            "current_gate": "Gate-2",
            "reason": gate2_reason,
            "next_user_action": "请用户验收签字（Gate-2）",
            "blocked_gates": "Gate-3",
        }
    if "shipped" not in req.parts and status != "shipped":
        from .gate3_triggers import build_gate3_trigger_report

        try:
            from .gitio import changed_all_files

            changed = changed_all_files("HEAD")
        except Exception:
            changed = []
        hint = build_gate3_trigger_report(text, changed).hint_summary()
        return {
            "current_gate": "Gate-3",
            "reason": "Gate-2 已验收，需求尚未归档至 shipped",
            "next_user_action": "执行 xijia-sync-knowledge 并 inbox→shipped 归档",
            "blocked_gates": "",
            "hint": f"{hint}；首步：--gate3-trigger-report --req <inbox>",
        }
    issues = process_docs_archive_issues(req, text)
    if issues:
        return {"current_gate": "Gate-3", "reason": "; ".join(issues[:3]), "next_user_action": "完成 Gate-3 归档并运行 --check-closeout", "blocked_gates": ""}
    return {"current_gate": "无", "reason": "收尾完成", "next_user_action": "无，继续执行或提醒用户 commit", "blocked_gates": ""}


def load_usage_sessions(path: Path) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    if not path.is_file():
        return result
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict) and isinstance(row.get("doc"), str):
            result.setdefault(row["doc"], set()).add(str(row.get("session") or ""))
    return result


def constraint_listed_experience_docs(text: str) -> list[str]:
    section = extract_section(text, "约束引用") or ""
    return sorted(set(EXPERIENCE_DOC_RE.findall(section)))


def experience_reuse_line_value(text: str) -> str | None:
    distill = gate3_distill_section(text)
    for area in (distill, text):
        if not area:
            continue
        match = EXPERIENCE_REUSE_LINE_RE.search(area)
        if match:
            return match.group(1).strip()
    return None


def _is_none_reuse_value(value: str) -> bool:
    return bool(re.search(r"\bnone\b|无经验复用|未命中", value, re.I))


_SKIP_REUSE_LINE_RE = re.compile(r"（跳过）|（未采用）|\(跳过\)|\(未采用\)", re.I)


def _text_excluding_distill_candidate_sections(text: str) -> str:
    """Body for reuse scan: omit Gate-3 沉淀候选 (advisory only, not Experience Reuse truth)."""
    candidate = extract_section(text, "沉淀候选")
    if not candidate:
        return text
    return text.replace(candidate, "", 1)


def _experience_docs_excluding_distill_markers(text: str) -> set[str]:
    docs: set[str] = set()
    scan_text = _text_excluding_distill_candidate_sections(text)
    for line in scan_text.splitlines():
        if DISTILL_MARKER_LINE_RE.match(line):
            continue
        if _SKIP_REUSE_LINE_RE.search(line):
            continue
        docs.update(EXPERIENCE_DOC_RE.findall(line))
    return docs


def reuse_logging_gaps(text: str, stem: str) -> list[str]:
    """Gaps in experience-reuse closed loop.

    Document truth: paths listed on ``Experience Reuse:`` satisfy the check
    without jsonl. ``Experience Reuse: none`` is forbidden when Gate-0
    「约束引用」 already listed patterns/pitfalls.
    """
    constraint_docs = set(constraint_listed_experience_docs(text))
    reuse_value = experience_reuse_line_value(text)

    if reuse_value is not None and _is_none_reuse_value(reuse_value):
        return sorted(constraint_docs)

    declared = set(EXPERIENCE_DOC_RE.findall(reuse_value or ""))
    gaps = sorted(constraint_docs - declared)

    if reuse_value is None and NO_REUSE_RE.search(text):
        return gaps

    referenced = _experience_docs_excluding_distill_markers(text) - declared - constraint_docs
    if not referenced:
        return gaps

    prefix = re.match(r"^(\d{14})", stem)
    req_id = prefix.group(1) if prefix else ""
    combined = load_usage_sessions(paths.DOCS_USAGE_LOG)
    for doc, sessions in load_usage_sessions(paths.DOCS_JUDGMENTS_LOG).items():
        combined.setdefault(doc, set()).update(sessions)

    def matches(session: str) -> bool:
        return bool(session and ((stem and (stem == session or stem in session or session in stem))
            or (req_id and (session == req_id or session.startswith(f"{req_id}-") or f"{req_id}-" in session))))

    for doc in sorted(referenced):
        if not any(matches(session) for session in combined.get(doc, set())):
            gaps.append(doc)
    return gaps


def gate3_distill_section(text: str) -> str:
    return extract_section(text, "实现记录") or ""


def distill_marker_value(section: str, label: str) -> str | None:
    match = re.search(rf"(?im)^\s*[-*]?\s*{label}:\s*(.+?)\s*$", section)
    if not match:
        return None
    value = match.group(1).strip().strip("`").strip()
    if "<" in value and ">" in value:
        return None
    return value


def distill_marker_resolved(section: str, label: str) -> bool:
    value = distill_marker_value(section, label)
    if value is None:
        return False
    return bool(re.search(r"no-?op", value, re.I)) or value.startswith("docs/") or ".md" in value or bool(
        re.search(r"\bupdated\b", value, re.I)
    )


def _business_hybrid_needs_distill(text: str) -> bool:
    tier, _ = resolve_tier(text, "green")
    if tier == "green-trivial" or has_green_trivial_marker(text):
        return False
    return parse_frontmatter_type(text) in ("business", "hybrid")


def _needs_domain_closeout_marker(text: str) -> bool:
    """Business|hybrid A|B (or missing DDD class) must record Domain: at Gate-3."""
    if not _business_hybrid_needs_distill(text):
        return False
    ddd = parse_frontmatter_ddd_class(text)
    if ddd in ("C", "D"):
        return False
    return True


_DOMAIN_MODEL_REL_RE = re.compile(
    r"docs/domain/[^/\s）);，,]+/domain-model\.md",
    re.I,
)


def _domain_model_paths_on_disk() -> list[Path]:
    root = paths.ROOT / "docs" / "domain"
    if not root.is_dir():
        return []
    return sorted(root.glob("*/domain-model.md"))


def _inv_ids_present_in_domain_models(inv_ids: list[str]) -> bool:
    if not inv_ids:
        return False
    for path in _domain_model_paths_on_disk():
        try:
            body = path.read_text(encoding="utf-8", errors="ignore").upper()
        except OSError:
            continue
        if any(inv.upper() in body for inv in inv_ids):
            return True
    return False


def domain_closeout_issues(
    text: str,
    req_rel: str,
    changed_files: list[str] | None = None,
) -> list[str]:
    if not _needs_domain_closeout_marker(text):
        return []
    distill = gate3_distill_section(text)
    if not distill_marker_resolved(distill, "Domain"):
        return [
            "业务/混合（DDD主类 A|B）实现记录与沉淀缺少已决策的 'Domain: <path|updated>|no-op'",
            "  → 须更新 docs/domain/context-map.md；若领域影响含 INV-xxx，"
            "还须首次/增量写 docs/domain/<bc>/domain-model.md（不得用 Living Docs 顶替 Domain）",
        ]
    value = distill_marker_value(distill, "Domain") or ""
    if re.search(r"no-?op", value, re.I):
        return []
    value_norm = value.replace("\\", "/")
    changed = [rel.replace("\\", "/") for rel in (changed_files or [])]
    touched_domain = (
        "docs/domain" in value_norm
        or bool(_knowledge_files_mention_req("docs/domain/", req_rel))
        or any(rel.startswith("docs/domain/") for rel in changed)
    )
    if not touched_domain:
        return [
            "Domain: updated 但 docs/domain/ 未引用本需求且未检测到 domain 变更",
            "  → 更新 context-map（及有 INV 时的 domain/<bc>/domain-model.md）并在 Domain 行写明路径",
        ]

    # 有新 INV 时：仅改 context-map / 只写 ADR 不够；须落 BC 契约 domain-model
    if not domain_impact_declares_new_inv(text):
        return []
    inv_ids = domain_impact_inv_ids(text)
    if _DOMAIN_MODEL_REL_RE.search(value_norm):
        return []
    if any(
        rel.startswith("docs/domain/") and rel.endswith("/domain-model.md")
        for rel in changed
    ):
        return []
    if _inv_ids_present_in_domain_models(inv_ids):
        return []
    return [
        "领域影响含 INV-xxx，但未落盘 docs/domain/<bc>/domain-model.md（且磁盘上无对应 INV）",
        "  → 黄/绿业务|混合：直写创建/更新 domain/<bc>/（首缺则建目录）；"
        "ADR 可承载权衡，不得以 ADR 或仅 context-map 代替 INV 真相源",
    ]


def capability_index_closeout_issues(text: str, req_rel: str) -> list[str]:
    if not _business_hybrid_needs_distill(text):
        return []
    distill = gate3_distill_section(text)
    value = distill_marker_value(distill, "Capability Index")
    cap = paths.ROOT / "docs/capability-map.md"
    req_name = Path(req_rel).name
    cap_text = cap.read_text(encoding="utf-8", errors="ignore") if cap.is_file() else ""
    referenced = bool(req_name and req_name in cap_text)

    if value and re.search(r"no-?op", value, re.I) and referenced:
        return [
            "Capability Index: no-op 但 capability-map 已引用本需求（false no-op）",
            "  → 改为 'Capability Index: updated' 或从 capability-map 撤销本需求引用",
        ]
    if value and (re.search(r"no-?op", value, re.I) or re.search(r"\bupdated\b", value, re.I)):
        return []
    rows = [row for row in (parse_closure_table(text) or []) if is_confirmed_cell(row["closure"])]
    if not rows or referenced:
        return []
    return [
        "业务/混合需求含已确认数据流闭环行，但实现记录与沉淀未写 'Capability Index: updated|no-op'，且 capability-map 未引用本需求",
        f"  → Gate-3 须运行: python .cursor/hooks/extract_capability_index.py --req {req_rel}",
    ]


def experience_distill_closeout_issues(text: str) -> list[str]:
    if not _business_hybrid_needs_distill(text):
        return []
    section = gate3_distill_section(text)
    labels = ["Patterns", "Pitfalls", "Living Docs", "Flow"]
    if _needs_domain_closeout_marker(text):
        labels.append("Domain")
    missing = [
        label
        for label in labels
        if not distill_marker_resolved(section, label)
    ]
    if not missing:
        return []
    return [
        "业务/混合需求实现记录与沉淀缺少已决策的沉淀标记："
        + "、".join(f"'{label}: <path|updated>|no-op'" for label in missing)
        + "（能力B 沉淀兜底）",
        "  → Gate-3 请在「实现记录与沉淀」写 Patterns/Pitfalls/Living Docs/Flow/Domain 或显式 no-op；"
        "占位符 <...> 不算已决策",
    ]


def _path_matches_rule(rel: str, rule: str) -> bool:
    rel = rel.replace("\\", "/")
    rule = rule.replace("\\", "/")
    if rule.endswith("/"):
        return rel.startswith(rule)
    return rel == rule


def _req_stem_tokens(req_rel: str) -> list[str]:
    name = Path(req_rel).name
    stem = Path(req_rel).stem
    tokens = [name, stem]
    prefix = re.match(r"^(\d{14})", stem)
    if prefix:
        tokens.append(prefix.group(1))
    return [token for token in tokens if token]


def _knowledge_files_mention_req(prefix: str, req_rel: str) -> list[str]:
    root = paths.ROOT
    hits: list[str] = []
    tokens = _req_stem_tokens(req_rel)
    if not tokens:
        return hits
    base = root / prefix.rstrip("/")
    if prefix.endswith(".md"):
        candidates = [base] if base.is_file() else []
    elif base.is_dir():
        candidates = sorted(base.rglob("*.md"))
    else:
        return hits
    for path in candidates:
        try:
            body = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if any(token in body for token in tokens):
            try:
                hits.append(path.relative_to(root).as_posix())
            except ValueError:
                hits.append(path.as_posix())
    return hits


def false_noop_closeout_issues(
    text: str,
    req_rel: str,
    changed_files: list[str] | None = None,
) -> list[str]:
    """Block no-op markers that contradict git changes or knowledge-base references.

    Git working-tree attribution applies only when this requirement file itself is
    among the changes (or still under inbox). Re-checking historical shipped while
    unrelated WIP is dirty must not inherit other files' diffs.
    """
    distill = gate3_distill_section(text)
    if not distill:
        return []
    req_norm = req_rel.replace("\\", "/")
    changed = [rel.replace("\\", "/") for rel in (changed_files or [])]
    req_in_change = (
        req_norm in changed
        or Path(req_norm).name in {Path(rel).name for rel in changed}
        or "docs/requirements/inbox/" in req_norm
    )
    scoped_changed = changed if req_in_change else []
    issues: list[str] = []
    for label, rules in NOOP_TOUCH_RULES.items():
        value = distill_marker_value(distill, label)
        if value is None or not re.search(r"no-?op", value, re.I):
            continue
        touched = [rel for rel in scoped_changed if any(_path_matches_rule(rel, rule) for rule in rules)]
        if label in ("Patterns", "Pitfalls") and touched:
            # Only count git-touched experience docs that mention this requirement
            tokens = _req_stem_tokens(req_rel)
            linked = []
            for rel in touched:
                path = paths.ROOT / rel
                body = path.read_text(encoding="utf-8", errors="ignore") if path.is_file() else ""
                if any(token in body for token in tokens):
                    linked.append(rel)
            touched = linked
        if touched:
            issues.append(
                f"{label}: no-op 但本次变更触及 {', '.join(touched[:5])}（false no-op）"
            )
            continue
        if label == "Capability Index":
            continue  # handled in capability_index_closeout_issues
        if label in ("Patterns", "Pitfalls"):
            prefix = "docs/patterns/" if label == "Patterns" else "docs/pitfalls/"
            mentions = _knowledge_files_mention_req(prefix, req_rel)
            if mentions:
                issues.append(
                    f"{label}: no-op 但 {', '.join(mentions[:5])} 已引用本需求（false no-op）"
                )
    if issues:
        issues.append("  → 已改对应活文档时须写 updated/路径，禁止 false no-op（见 xijia-sync-knowledge）")
    return issues


def modal_drawer_gaps(base: str, text: str) -> list[str]:
    section = extract_section(text, "约束引用") or ""
    if not PATTERN_DOC_REF_RE.search(section):
        return []
    if not SYSTEM_LIST_UI_TOUCH_RE.search(text):
        return []
    from .gitio import changed_all_files
    gaps = []
    for rel in changed_all_files(base):
        if not rel.startswith(f"{paths.FRONTEND_DIR}/src/views/system/"):
            continue
        if not rel.endswith(("ListView.vue", "ManagementView.vue")):
            continue
        file = paths.ROOT / rel
        body = file.read_text(encoding="utf-8", errors="ignore") if file.is_file() else ""
        if "el-dialog" not in body or "el-drawer" not in body:
            gaps.append(rel)
    return gaps
