"""Gate-3 living-doc trigger report (触发表 → 机器可读候选清单)."""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path

from . import paths
from .closeout import (
    _business_hybrid_needs_distill,
    _inv_ids_present_in_domain_models,
    _needs_domain_closeout_marker,
    constraint_listed_experience_docs,
    distill_marker_value,
    gate3_distill_section,
)
from .markdown import extract_section
from .requirement import (
    domain_impact_declares_new_inv,
    domain_impact_inv_ids,
    has_green_trivial_marker,
    parse_frontmatter_ddd_class,
    parse_frontmatter_type,
    PATTERN_DOC_REF_RE,
    resolve_tier,
    SYSTEM_LIST_UI_TOUCH_RE,
)

REMINDER_FOOTER = (
    "[gate3-trigger] 签字后同轮须：1) 运行本报告 "
    "2) 向用户展示「沉淀候选」并确认 patterns/pitfalls "
    "3) 再写实现记录与沉淀"
)

TABLE_FIRST_PATTERN = "docs/patterns/table-first-list-page.md"
FRONTEND_TEST_SKILL = ".cursor/skills/xijia-frontend-test/SKILL.md"

VIEW_PATH_RE = re.compile(rf"{re.escape(paths.FRONTEND_DIR)}/src/views/.+View\.vue$", re.I)
E2E_PATH_RE = re.compile(rf"{re.escape(paths.FRONTEND_DIR)}/e2e/", re.I)
API_ROUTER_RE = re.compile(rf"{re.escape(paths.BACKEND_DIR)}/app/.+_router\.py$", re.I)
API_SERVICE_RE = re.compile(
    rf"{re.escape(paths.BACKEND_DIR)}/app/.+(?:_service|_admin_service)\.py$", re.I,
)
# 共享层约定目录：后端公共层与前端共享状态机；components/ 混有业务 Panel 不纳入
SHARED_LAYER_RE = re.compile(
    rf"^{paths.BACKEND_DIR}/app/common/|^{paths.FRONTEND_DIR}/src/composables/", re.I,
)
LIVING_DOC_TOUCH_RE = re.compile(
    r"^(AGENTS\.md|docs/(?:llms\.txt|README\.md|architecture\.md|capability-map\.md|"
    r"domain/|patterns/|pitfalls/|decisions/|flow\.md))",
    re.I,
)
PATTERN_SKIP_RE = re.compile(r"用户确认跳过|确认跳过|已确认跳过|skip.*pattern", re.I)
CANDIDATE_SECTION_RE = re.compile(r"^#{2,3}\s*沉淀候选\s*[（(]Gate-3[）)]?\s*$", re.M)


@dataclass
class TriggerItem:
    tier: str  # mandatory | suggested | noop_ok
    target: str
    action: str
    reason: str


@dataclass
class Gate3TriggerReport:
    mandatory: list[TriggerItem] = field(default_factory=list)
    suggested: list[TriggerItem] = field(default_factory=list)
    noop_ok: list[TriggerItem] = field(default_factory=list)
    changed_files: list[str] = field(default_factory=list)

    def hint_summary(self, limit: int = 3) -> str:
        items = self.mandatory[:limit]
        if not items and self.suggested:
            items = self.suggested[:limit]
        if not items:
            return "运行 --gate3-trigger-report 查看 Gate-3 沉淀触发表"
        parts = [f"{it.target}（{it.action}）" for it in items]
        return "Gate-3 优先：" + "；".join(parts)

    def to_dict(self) -> dict:
        return {
            "mandatory": [asdict(i) for i in self.mandatory],
            "suggested": [asdict(i) for i in self.suggested],
            "noop_ok": [asdict(i) for i in self.noop_ok],
            "changed_files": self.changed_files,
            "reminder": REMINDER_FOOTER,
            "hint_summary": self.hint_summary(),
        }


def _normalize_changed(changed_files: list[str] | None) -> list[str]:
    if not changed_files:
        return []
    return sorted({rel.replace("\\", "/") for rel in changed_files if rel})


def _touched_living_docs(changed: list[str]) -> bool:
    return any(LIVING_DOC_TOUCH_RE.match(rel) for rel in changed)


def _patterns_marker_is_noop(text: str) -> bool:
    distill = gate3_distill_section(text)
    value = distill_marker_value(distill, "Patterns") or ""
    return bool(re.search(r"no-?op", value, re.I))


def _has_distill_section(text: str) -> bool:
    return bool(gate3_distill_section(text).strip())


def _has_candidate_section(text: str) -> bool:
    return bool(CANDIDATE_SECTION_RE.search(text))


def _user_confirmed_pattern_skip(text: str) -> bool:
    section = gate3_distill_section(text) or ""
    if PATTERN_SKIP_RE.search(section):
        return True
    match = CANDIDATE_SECTION_RE.search(text)
    if not match:
        return False
    tail = text[match.end() : match.end() + 2000]
    return bool(re.search(r"跳过|skip", tail, re.I)) and "pattern" in tail.lower()


def build_gate3_trigger_report(
    text: str,
    changed_files: list[str] | None = None,
) -> Gate3TriggerReport:
    """Evaluate knowledge-maintenance triggers for Gate-3 sync."""
    changed = _normalize_changed(changed_files)
    report = Gate3TriggerReport(changed_files=changed)
    tier, _ = resolve_tier(text, "green")
    req_type = parse_frontmatter_type(text)
    ddd = parse_frontmatter_ddd_class(text)
    needs_distill = _business_hybrid_needs_distill(text)
    green_trivial = tier == "green-trivial" or has_green_trivial_marker(text)

    if needs_distill:
        report.mandatory.append(TriggerItem(
            tier="mandatory",
            target="docs/capability-map.md",
            action="extract_capability_index.py --dry-run 后落盘",
            reason="业务/混合且非 green-trivial",
        ))

    if _needs_domain_closeout_marker(text):
        report.mandatory.append(TriggerItem(
            tier="mandatory",
            target="docs/domain/context-map.md",
            action="UPDATE + Domain: updated 标记",
            reason="业务/混合 DDD A|B（或未填主类）",
        ))

    if domain_impact_declares_new_inv(text):
        inv_ids = domain_impact_inv_ids(text)
        on_disk = _inv_ids_present_in_domain_models(inv_ids)
        report.mandatory.append(TriggerItem(
            tier="mandatory",
            target="docs/domain/<bc>/domain-model.md",
            action="ADD/UPDATE INV" if on_disk else "首缺建夹并写入 INV",
            reason=f"领域影响含 INV：{', '.join(inv_ids[:5])}",
        ))

    constraint_docs = constraint_listed_experience_docs(text)
    if constraint_docs:
        report.mandatory.append(TriggerItem(
            tier="mandatory",
            target="Experience Reuse",
            action="写路径（禁止 none）",
            reason=f"约束引用已列：{', '.join(constraint_docs[:3])}",
        ))

    if any(VIEW_PATH_RE.match(rel) for rel in changed):
        report.suggested.append(TriggerItem(
            tier="suggested",
            target=TABLE_FIRST_PATTERN,
            action="增补/新建 Table-First 列表操作页 pattern（须人确认）",
            reason="变更含 frontend View 页",
        ))

    if any(E2E_PATH_RE.match(rel) for rel in changed):
        report.suggested.append(TriggerItem(
            tier="suggested",
            target=FRONTEND_TEST_SKILL,
            action="链 Playwright AC 与 verify 命令（须人确认是否写 pitfall）",
            reason="变更含 frontend/e2e",
        ))

    if any(SHARED_LAYER_RE.match(rel) for rel in changed):
        report.suggested.append(TriggerItem(
            tier="suggested",
            target="docs/patterns/<topic>.md",
            action="公共/共享层变更：评估沉淀可复用 pattern（须人确认）",
            reason="变更含 backend/app/common/ 或 frontend/src/composables/",
        ))

    has_api = any(API_ROUTER_RE.match(rel) or API_SERVICE_RE.match(rel) for rel in changed)
    if has_api and needs_distill:
        report.suggested.append(TriggerItem(
            tier="suggested",
            target="docs/decisions/*.md",
            action="若含架构权衡则 ADD ADR",
            reason="变更含 backend router/service",
        ))

    if "AGENTS.md" in changed:
        report.suggested.append(TriggerItem(
            tier="suggested",
            target="AGENTS.md",
            action="Living Docs: updated（Build/test 或 overview 段）",
            reason="git 触及 AGENTS.md",
        ))

    ui_signal = any(SYSTEM_LIST_UI_TOUCH_RE.search(rel) for rel in changed)
    if not ui_signal and SYSTEM_LIST_UI_TOUCH_RE.search(text):
        ui_signal = True
    if ui_signal:
        constraint_section = extract_section(text, "约束引用") or ""
        pattern_targets = sorted(set(PATTERN_DOC_REF_RE.findall(constraint_section)))
        target = pattern_targets[0] if pattern_targets else "docs/patterns/（见约束引用）"
        report.suggested.append(TriggerItem(
            tier="suggested",
            target=target,
            action="确认 Modal/Drawer 分工（须人确认）",
            reason="列表页 UI / AC-UI 相关变更",
        ))

    if green_trivial and not _touched_living_docs(changed):
        report.noop_ok.append(TriggerItem(
            tier="noop_ok",
            target="Living Docs / Patterns / Pitfalls / Capability Index",
            action="可写 no-op（green-trivial 快路径）",
            reason="green-trivial 且未触及活文档",
        ))
    elif req_type in ("technical", "defect") and ddd in ("C", "D"):
        report.noop_ok.append(TriggerItem(
            tier="noop_ok",
            target="docs/domain/<bc>/",
            action="Domain: no-op（DDD C/D）",
            reason=f"类型={req_type} DDD主类={ddd or '?'}",
        ))
    elif not report.mandatory and not report.suggested:
        report.noop_ok.append(TriggerItem(
            tier="noop_ok",
            target="活文档触发表",
            action="Living Docs: no-op + 各标记 no-op（须写明理由）",
            reason="未命中强制/建议触发",
        ))

    return report


def gate3_preflight_trigger_warnings(text: str, changed_files: list[str] | None = None) -> list[str]:
    """Non-blocking warnings for gate3 preflight."""
    warnings: list[str] = []
    if _business_hybrid_needs_distill(text) and not _has_distill_section(text):
        warnings.append(
            "须先在 inbox 写入「实现记录与沉淀（Gate-3）」段（含 Patterns/Pitfalls/Living Docs/Flow/Domain）"
        )
    report = build_gate3_trigger_report(text, changed_files)
    if report.suggested and _patterns_marker_is_noop(text) and not _user_confirmed_pattern_skip(text):
        targets = ", ".join(item.target for item in report.suggested if "pattern" in item.target.lower())
        if targets:
            warnings.append(
                f"触发报告有 pattern 建议（{targets}），但 Patterns: no-op；"
                "须人确认后写 updated 或在「沉淀候选」标跳过"
            )
    if report.mandatory and not _has_candidate_section(text) and not _has_distill_section(text):
        warnings.append(
            "强制触发表已命中：Move 前建议写入「### 沉淀候选（Gate-3）」并运行 --gate3-trigger-report"
        )
    return warnings


def format_gate3_trigger_report(report: Gate3TriggerReport) -> str:
    lines = ["[gate3-trigger] Gate-3 沉淀触发表", ""]
    if report.mandatory:
        lines.append("A. 强制（closeout 会拦）")
        for item in report.mandatory:
            lines.append(f"  - {item.target} → {item.action}（{item.reason}）")
        lines.append("")
    if report.suggested:
        lines.append("B. 建议（patterns/pitfalls 须人确认后写）")
        for item in report.suggested:
            lines.append(f"  - {item.target} → {item.action}（{item.reason}）")
        lines.append("")
    if report.noop_ok:
        lines.append("C. 可 no-op")
        for item in report.noop_ok:
            lines.append(f"  - {item.target} → {item.action}（{item.reason}）")
        lines.append("")
    if report.changed_files:
        preview = ", ".join(report.changed_files[:8])
        if len(report.changed_files) > 8:
            preview += f" …共 {len(report.changed_files)} 个"
        lines.append(f"变更文件（{len(report.changed_files)}）：{preview}")
        lines.append("")
    lines.append(REMINDER_FOOTER)
    return "\n".join(lines)


def format_gate3_trigger_json(report: Gate3TriggerReport) -> str:
    return json.dumps(report.to_dict(), ensure_ascii=False, indent=2)
