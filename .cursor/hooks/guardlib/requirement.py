"""Requirement metadata, Gate records, intake, and plan helpers."""

from __future__ import annotations

import re
from pathlib import Path

from . import paths
from .markdown import cell, extract_section, find_col, find_table, is_placeholder, iter_headings

VALID_TIERS = frozenset({"green", "green-trivial", "yellow", "red"})
TIER_VALUES = {"绿": "green", "绿-轻量": "green-trivial", "黄": "yellow", "红": "red"}
TYPE_VALUES = {"业务": "business", "技术": "technical", "混合": "hybrid", "缺陷": "defect"}
STATUS_VALUES = {"待处理": "inbox", "已交付": "shipped", "已归档": "archived", "积压": "backlog"}
ENGLISH_VALUE_HINTS = {
    "分级": {"green": "绿", "green-trivial": "绿-轻量", "yellow": "黄", "red": "红"},
    "类型": {"business": "业务", "technical": "技术", "hybrid": "混合", "defect": "缺陷"},
    "状态": {"inbox": "待处理", "shipped": "已交付", "archived": "已归档", "backlog": "积压"},
}
# Gate-0/1/2 状态（中文 canonical；英文别名仅兼容未迁移历史文件，deprecated）
GATE0_PASSED = frozenset({"已通过"})
GATE0_PARTIAL = frozenset({"部分通过"})
GATE0_REJECTED = frozenset({"已驳回"})
GATE0_PENDING = frozenset({"待确认"})
GATE0_PASSED_LEGACY = frozenset({"complete", "passed", "pass"})  # deprecated
GATE0_PARTIAL_LEGACY = frozenset({"partial"})  # deprecated
GATE1_APPROVED = frozenset({"已批准"})
GATE1_PENDING = frozenset({"待批准"})
GATE1_APPROVED_LEGACY = frozenset({"approved"})  # deprecated
GATE2_ACCEPTED = frozenset({"已验收"})
GATE2_PENDING = frozenset({"待验收"})
GATE2_ACCEPTED_LEGACY = frozenset({"accepted"})  # deprecated
GATE_PENDING_STATUSES = frozenset({"待确认", "待批准", "待验收", "待处理"})
GATE_ENGLISH_STATUS_HINTS = {
    "complete": "已通过",
    "passed": "已通过",
    "pass": "已通过",
    "partial": "部分通过",
    "reject": "已驳回",
    "rejected": "已驳回",
    "approved": "已批准",
    "accepted": "已验收",
}
CONFIRMED = {"已确认", "闭环", "ok", "done", "✓", "yes", "y", "true"}
ISO_DATE_RE = re.compile(r"\b\d{4}-\d{2}-\d{2}\b")
STATUS_RE = re.compile(r"(?:状态|status)\s*[:：]\s*([^|；;]+)")
APPROVER_RE = re.compile(r"(?:审批人|签字|approver)\s*[:：]\s*([^|；;]+)")
NO_NEW_DATAFLOW_RE = re.compile(
    r"^(?:本需求|缺陷修复)无(?:新增|业务)?数据流(?:[（(]green-trivial[）)])?[。.]?$", re.I,
)
PENDING_CONFIRM_RE = re.compile(r"\[(待确认|待人工确认|待确定|待补充确认)\]")
DEVIATION_APPROVED = ("approved", "已批准", "已确认", "已审批", "rejected", "已拒绝")
DEVIATION_NONE = ("—", "-", "无", "n/a", "na")
GENERIC_APPROVER_RE = re.compile(
    r"^(用户|人工|验收人|审核人|审批人|需求方|产品|测试|开发|owner|user|human|"
    r"approver|reviewer|<name>|name|待填|待补充)$", re.I,
)
PLATFORM_BC_RE = re.compile(
    r"sys_|/api/system|/system/|RbacQueryService|UserAdminService|RoleAdminService|"
    r"MenuAdminService|system\s*BC|系统管理", re.I,
)
TYPE_MATRIX_MARKERS = ("类型判型矩阵", "类型判型结论", "**类型判型**")
CONSTRAINT_REF_NONE_RE = re.compile(r"约束引用\s*:\s*none|约束引用.*(?:未命中|无约束)|无约束引用", re.I)
SYSTEM_LIST_UI_TOUCH_RE = re.compile(
    rf"ListView\.vue|ManagementView\.vue|{paths.FRONTEND_DIR}/src/views/system/|列表页|"
    r"list-page|el-dialog|el-drawer|Modal/Drawer|INV-UI-0|AC-UI-", re.I,
)
PATTERN_DOC_REF_RE = re.compile(r"docs/patterns/[A-Za-z0-9_\-./]+\.md")
CONSTRAINT_DOC_REF_RE = re.compile(
    r"docs/(?:patterns|pitfalls|domain|decisions)/[A-Za-z0-9_\-./]+\.md",
)
PANEL_REF_RE = re.compile(
    rf"{re.escape(paths.FRONTEND_DIR)}/src/components/\w+Panel\.vue",
)
REQUIRED_GATE_SECTIONS = {
    "Gate-0": (
        "原始诉求",
        "歧义登记",
        "业务目标",
        "用例",
        "范围与切片",
        "约束引用",
        "数据流闭环表",
        "原型对齐与偏离",
    ),
    "Gate-1": ("验收标准", "实现方案"),
    "Gate-2": ("验收记录",),
    "Gate-3": ("实现记录与沉淀",),
}
GATE_ORDER = tuple(REQUIRED_GATE_SECTIONS)
CANONICAL_FRONTMATTER_FIELDS = (
    ("标题", "标题"),
    ("状态", "状态"),
    ("负责人", "负责人"),
    ("创建时间", "创建时间"),
    ("分级", "分级"),
    ("类型", "类型"),
    ("Gate-0", "gate-0"),
    ("Gate-1", "gate-1"),
    ("Gate-2", "gate-2"),
)


def parse_frontmatter_block(text: str) -> dict[str, str] | None:
    from .markdown import parse_frontmatter
    return parse_frontmatter(text)


def _heading_gate(title: str) -> str | None:
    match = re.match(r"^(Gate-[0-3])(?:\s|[：:（(]|$)", title)
    return match.group(1) if match else None


def _matches_required_h2(title: str, required: str) -> bool:
    return bool(re.match(rf"^{re.escape(required)}(?:\s|[：:（(]|$)", title))


def requirement_structure_issues(text: str) -> list[str]:
    """Validate the canonical requirement H1/Gate/H2 hierarchy."""
    headings = [heading for heading in iter_headings(text) if heading.level <= 2]
    h1s = [heading for heading in headings if heading.level == 1]
    issues: list[str] = []

    if not h1s or h1s[0].title.startswith("Gate-"):
        issues.append("第一个 H1 必须是非 Gate 的需求名称")

    later_h1s = h1s[1:] if h1s else []
    actual_gates: list[str] = []
    for heading in later_h1s:
        gate = _heading_gate(heading.title)
        if gate:
            actual_gates.append(gate)
        else:
            issues.append(f"不允许额外 H1「{heading.title}」；需求名称后只允许 Gate-0..3")
    if actual_gates != list(GATE_ORDER):
        actual = " → ".join(actual_gates) or "无"
        issues.append(
            "H1 Gate 顺序不合规：期望 Gate-0 → Gate-1 → Gate-2 → Gate-3 各一次，"
            f"实际 {actual}"
        )

    seen = {
        gate: {required: 0 for required in required_sections}
        for gate, required_sections in REQUIRED_GATE_SECTIONS.items()
    }
    current_gate: str | None = None
    for heading in headings:
        if heading.level == 1:
            current_gate = _heading_gate(heading.title)
            continue
        matching = next(
            (
                (gate, required)
                for gate, required_sections in REQUIRED_GATE_SECTIONS.items()
                for required in required_sections
                if _matches_required_h2(heading.title, required)
            ),
            None,
        )
        if current_gate is None:
            issues.append(f"H2「{heading.title}」位于 Gate 之外")
            continue
        if matching:
            expected_gate, required = matching
            if current_gate == expected_gate:
                seen[expected_gate][required] += 1
            else:
                issues.append(
                    f"H2「{required}」必须位于 {expected_gate}，实际位于 {current_gate}"
                )

    for gate, required_sections in REQUIRED_GATE_SECTIONS.items():
        for required in required_sections:
            count = seen[gate][required]
            if count == 0:
                issues.append(f"{gate} 缺少必需 H2「{required}」")
            elif count > 1:
                issues.append(f"{gate} H2「{required}」重复 {count} 次")
    return issues


def _normalized_field(text: str, key: str, values: dict[str, str]) -> str | None:
    block = parse_frontmatter_block(text)
    if not block:
        return None
    return values.get(block.get(key, "").strip())


def parse_frontmatter_type(text: str) -> str | None:
    return _normalized_field(text, "类型", TYPE_VALUES)


def parse_frontmatter_status(text: str) -> str | None:
    return _normalized_field(text, "状态", STATUS_VALUES)


def parse_frontmatter_tier(text: str) -> str | None:
    return _normalized_field(text, "分级", TIER_VALUES)


def parse_frontmatter_openspec_change(text: str) -> str | None:
    block = parse_frontmatter_block(text) or {}
    return block.get("openspec变更", "").strip() or None


def parse_frontmatter_ui_evidence(text: str) -> str | None:
    """Return component|playwright|integration from frontmatter ``UI验收证据``, or None."""
    block = parse_frontmatter_block(text) or {}
    raw = ""
    for key, value in block.items():
        if key.lower().replace(" ", "") == "ui验收证据":
            raw = (value or "").strip()
            break
    if not raw:
        return None
    lower = raw.lower()
    if "playwright" in lower:
        return "playwright"
    if "集成" in raw:
        return "integration"
    if "组件" in raw:
        return "component"
    return None


_AC_UI_RE = re.compile(r"\bAC-UI-\d+", re.I)
_NO_UI_LAYOUT_RE = re.compile(r"不适用\s*[（(]?\s*无\s*UI", re.I)
_FRONTEND_ENTRY_NONE = frozenset({"", "—", "-", "–", "n/a", "无", "不适用"})


def _frontend_entry_touches_ui(value: str) -> bool:
    cell_value = (value or "").strip()
    return cell_value.lower() not in _FRONTEND_ENTRY_NONE


def requirement_touches_ui(text: str) -> bool:
    """True when the requirement appears to touch frontend UI (for Gate-1 CTA).

    Hits any of: ``AC-UI-*``, dataflow 前端入口 ≠ empty/—, 页面布局预览 not
    「不适用（无 UI…）」, or 实现方案 contains ``frontend/src/``.
    """
    if _AC_UI_RE.search(text):
        return True

    rows = parse_closure_table(text)
    if rows:
        for row in rows:
            if _frontend_entry_touches_ui(row.get("frontend", "")):
                return True

    layout = extract_section(text, "页面布局预览")
    if layout is not None and layout.strip() and not _NO_UI_LAYOUT_RE.search(layout):
        return True

    plan = extract_section(text, "实现方案") or ""
    if "frontend/src/" in plan:
        return True

    return False


def parse_frontmatter_ddd_class(text: str) -> str | None:
    """Return A|B|C|D from frontmatter `DDD主类`, or None if missing/invalid."""
    block = parse_frontmatter_block(text) or {}
    raw = (block.get("DDD主类") or block.get("DDD 主类") or "").strip().upper()
    # Allow values like "B" or "B（…）"
    match = re.match(r"^([ABCD])\b", raw)
    return match.group(1) if match else None


_DOMAIN_IMPACT_HEADING_RE = re.compile(r"^#{2,3}\s*领域影响\s*$", re.M)
_INV_ID_RE = re.compile(r"\bINV-[A-Za-z0-9][-A-Za-z0-9]*", re.I)
_NO_NEW_INV_RE = re.compile(
    r"(?:本切片|本期|本次)?无新(?:增)?(?:INV|不变量)|无新不变量|不适用\s*[（(]\s*无新\s*INV",
    re.I,
)


def _domain_impact_section(text: str) -> str:
    section = extract_section(text, "领域影响") or ""
    if section.strip():
        return section
    match = re.search(
        r"^#{2,3}\s*领域影响\s*$([\s\S]*?)(?=^#{2,3}\s|\Z)",
        text,
        re.M,
    )
    return match.group(1) if match else ""


def domain_impact_declares_new_inv(text: str) -> bool:
    """True when 领域影响 lists INV-xxx (not an explicit「无新 INV」waiver)."""
    section = _domain_impact_section(text)
    if not section.strip():
        return False
    if _NO_NEW_INV_RE.search(section) and not _INV_ID_RE.search(section):
        return False
    return bool(_INV_ID_RE.search(section))


def domain_impact_inv_ids(text: str) -> list[str]:
    """Return INV ids from 领域影响 (deduped, original order)."""
    section = _domain_impact_section(text)
    if not section.strip():
        return []
    seen: set[str] = set()
    out: list[str] = []
    for match in _INV_ID_RE.finditer(section):
        inv = match.group(0).upper()
        if inv not in seen:
            seen.add(inv)
            out.append(inv)
    return out


def domain_impact_intake_issues(text: str) -> list[str]:
    """Hard-fail: business|hybrid (non green-trivial) must document 领域影响 + INV or explicit none."""
    if parse_frontmatter_type(text) not in ("business", "hybrid"):
        return []
    tier, _ = resolve_tier(text, "green")
    if tier == "green-trivial" or has_green_trivial_marker(text):
        return []
    issues: list[str] = []
    if not _DOMAIN_IMPACT_HEADING_RE.search(text):
        issues.append(
            "业务/混合需求缺少「领域影响」章节（`## 领域影响` 或 `### 领域影响`；"
            "须含 BC、术语、INV-xxx 或显式无新 INV 理由）"
        )
        return issues
    section = _domain_impact_section(text)
    if not (_INV_ID_RE.search(section) or _NO_NEW_INV_RE.search(section)):
        issues.append(
            "「领域影响」须含至少一条 `INV-xxx`，或显式写「本切片无新 INV（理由）」"
        )
    return issues


_NO_PROTOTYPE_RE = re.compile(r"无原型(?:对照)?", re.I)
_PROTOTYPE_REF_RE = re.compile(
    r"(?:document/|页面DEMO/|\.html\b|indicator-platform|metric-hub-butter|DEMO/)",
    re.I,
)
_PROTOTYPE_TABLE_TEMPLATE = """\
| 维度 | PRD 描述 | 原型实际 | 结论 |
| --- | --- | --- | --- |
| （示例）页面布局 | … | … | 一致 / 偏离 / 以 PRD 为准 |
"""


def declares_no_prototype(text: str) -> bool:
    section = extract_section(text, "原型对齐与偏离") or ""
    return bool(_NO_PROTOTYPE_RE.search(section or text))


def has_prototype_reference(text: str) -> bool:
    if declares_no_prototype(text):
        return False
    return bool(_PROTOTYPE_REF_RE.search(text))


def has_prototype_status_table(text: str) -> bool:
    for scope in (
        extract_section(text, "原型对齐与偏离") or "",
        extract_section(text, "原型现状（相对 PRD）") or "",
        text,
    ):
        table = find_table(scope, ("PRD", "原型")) or find_table(scope, ("PRD", "结论"))
        if table is not None:
            headers, _ = table
            header_line = " ".join(headers)
            if "PRD" in header_line and "原型" in header_line and "结论" in header_line:
                return True
    return False


def prototype_table_intake_issues(text: str) -> list[str]:
    if not has_prototype_reference(text):
        return []
    if has_prototype_status_table(text):
        return []
    return [
        "有原型引用但缺少「原型现状（相对 PRD）」三列表（表头须含 PRD + 原型 + 结论）。"
        f"可粘贴模板：\n{_PROTOTYPE_TABLE_TEMPLATE}"
    ]


def canonical_frontmatter_issues(text: str) -> list[str]:
    """Require canonical, resolved metadata before Gate-0 intake proceeds."""
    block = parse_frontmatter_block(text) or {}
    required = list(CANONICAL_FRONTMATTER_FIELDS)
    if block.get("分级", "").strip() == "红":
        required.append(("openspec变更", "openspec变更"))
    return [
        f"缺少必填项 `{label}`（字段不存在、为空或仍为占位符）"
        for label, key in required
        if is_placeholder(block.get(key, ""))
    ]


def frontmatter_language_issues(text: str) -> list[str]:
    block = parse_frontmatter_block(text) or {}
    issues: list[str] = []
    checks = (
        ("分级", TIER_VALUES),
        ("类型", TYPE_VALUES),
        ("状态", STATUS_VALUES),
    )
    for key, values in checks:
        raw = block.get(key, "").strip()
        if not raw or raw in values:
            continue
        translation = ENGLISH_VALUE_HINTS[key].get(raw.lower())
        hint = f"（请改为 '{translation}'）" if translation else ""
        issues.append(f"{key} 值 '{raw}' 非中文{hint}")
    for gate_key in ("gate-0", "gate-1", "gate-2"):
        raw = block.get(gate_key, "").strip()
        if not raw:
            continue
        gate = parse_gate_cell(raw)
        status = (gate.get("status") or "").strip()
        if not status:
            continue
        hint = GATE_ENGLISH_STATUS_HINTS.get(status.lower())
        if hint:
            label = {"gate-0": "Gate-0", "gate-1": "Gate-1", "gate-2": "Gate-2"}[gate_key]
            issues.append(f"{label} 状态 '{status}' 非中文（请改为 '{hint}'）")
    return issues


def resolve_tier(text: str, cli_tier: str) -> tuple[str | None, list[str]]:
    tier = parse_frontmatter_tier(text)
    if tier:
        issues = [f"CLI --tier={cli_tier} 与 YAML properties 分级={tier} 不一致"] if cli_tier and cli_tier != tier else []
        return tier, issues
    if cli_tier in VALID_TIERS:
        return cli_tier, ["frontmatter 缺少 `分级`，当前回退使用 CLI --tier"]
    return None, ["未找到分级（YAML properties `分级` / CLI --tier 均缺失）"]


def is_red_requirement_text(text: str) -> bool:
    return parse_frontmatter_tier(text) == "red"


def red_requirements() -> list[str]:
    if not paths.INBOX_DIR.is_dir():
        return []
    return [
        item.stem for item in sorted(paths.INBOX_DIR.glob("*.md"))
        if is_red_requirement_text(item.read_text(encoding="utf-8", errors="ignore"))
    ]


def dataflow_declaration_lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if NO_NEW_DATAFLOW_RE.fullmatch(line.strip())]


def has_green_trivial_marker(text: str) -> bool:
    return any("green-trivial" in line.lower() for line in dataflow_declaration_lines(text))


def has_no_new_dataflow_declaration(text: str) -> bool:
    return bool(dataflow_declaration_lines(text))


def is_unclosed_cell(value: str) -> bool:
    value = (value or "").strip()
    return not value or "<" in value or ">" in value or "待确认" in value or "..." in value or "…" in value


def is_confirmed_cell(value: str) -> bool:
    return (value or "").strip().lower() in CONFIRMED


def parse_closure_table(text: str) -> list[dict[str, str]] | None:
    section = extract_section(text, "数据流闭环表")
    if section is None:
        return None
    table = find_table(section, ("来源", "去向"))
    if table is None:
        # Legacy tables: 来源 + 前端入口 without 去向(Sink)
        table = find_table(section, ("来源", "前端"))
    if table is None:
        return None
    headers, rows = table
    columns = {
        "name": find_col(headers, ("能力", "AC")),
        "source": find_col(headers, ("来源", "source")),
        "process": find_col(headers, ("加工", "process")),
        "sink": find_col(headers, ("去向", "sink")),
        "closure": find_col(headers, ("闭环", "closure")),
        "frontend": find_col(headers, ("前端入口", "frontend")),
        "table": find_col(headers, ("相关表", "table")),
    }

    def _row_to_dict(row: list[str]) -> dict[str, str]:
        sink = cell(row, columns["sink"])
        frontend = cell(row, columns["frontend"])
        if not (sink or "").strip() and (frontend or "").strip():
            sink = frontend
        return {
            "name": cell(row, columns["name"]) or "(未命名能力)",
            "source": cell(row, columns["source"]),
            "process": cell(row, columns["process"]),
            "sink": sink,
            "closure": cell(row, columns["closure"]),
            "frontend": frontend,
            "table": cell(row, columns["table"]),
        }

    return [_row_to_dict(row) for row in rows]


def open_deviation_tickets(text: str) -> list[tuple[str, str, str]]:
    table = (
        find_table(text, ("偏离", "审批"))
        or find_table(text, ("原型", "审批"))
        or find_table(text, ("原型", "偏离"))
    )
    if table is None:
        return []
    headers, rows = table
    i_approval = find_col(headers, ("审批", "approval"))
    i_page = find_col(headers, ("页面", "能力", "page"))
    i_ticket = find_col(headers, ("偏离单", "单号", "ticket"))
    result: list[tuple[str, str, str]] = []
    for row in rows:
        approval, ticket = cell(row, i_approval), cell(row, i_ticket)
        if ticket.lower() in DEVIATION_NONE and approval.lower() in DEVIATION_NONE:
            continue
        if any(token in approval.lower() or token in approval for token in DEVIATION_APPROVED):
            continue
        if "open" in approval.lower() or "待" in approval:
            result.append((cell(row, i_page) or "(未命名页面/能力)", ticket or "(无单号)", approval or "(空)"))
    return result


def pending_confirmation_lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if PENDING_CONFIRM_RE.search(line)]


def gate0_pending_breakpoints(text: str) -> list[str]:
    """Locate Gate-0 待确认断点（歧义登记 / 数据流闭环表 / OQ·[待确认]）。

    DEF-* 延期项不计入。供 ``--resolve-gate`` 指引用户关注具体位置。
    """
    breakpoints: list[str] = []
    for line in pending_confirmation_lines(text):
        breakpoints.append(f"待确认标记: {line[:120]}")

    rows = parse_closure_table(text)
    if rows is not None:
        for row in rows:
            name = row["name"]
            for key, label in (("source", "来源"), ("process", "加工"), ("sink", "去向")):
                if is_unclosed_cell(row[key]):
                    breakpoints.append(f"数据流闭环表 {name} / {label} 未闭环")
            if not is_confirmed_cell(row["closure"]):
                breakpoints.append(f"数据流闭环表 {name} / 闭环状态未确认（'{row['closure'].strip() or '空'}'）")

    ambiguity = extract_section(text, "歧义登记")
    if ambiguity:
        none = re.search(r"^歧义登记\s*:\s*none[^\n]*$", ambiguity, re.M | re.I)
        if not none:
            for issue in ambiguity_table_issues(ambiguity):
                if "缺少必要列" in issue or "缺少数据行" in issue:
                    breakpoints.append(f"歧义登记: {issue}")
                elif "结论未闭合" in issue or "确认人" in issue or "确认日期" in issue:
                    breakpoints.append(issue)

    # Open Questions：含 [待确认] 的行已由 pending_confirmation_lines 覆盖；
    # 另捕获「OQ-… → 结论：」后为空或占位的行（无方括号时）
    oq_section = extract_section(text, "范围与切片") or text
    for line in oq_section.splitlines():
        stripped = line.strip()
        if not re.match(r"^-?\s*OQ-\d+", stripped, re.I):
            continue
        if PENDING_CONFIRM_RE.search(stripped) or "待确认" in stripped:
            if stripped not in {bp.split(": ", 1)[-1] for bp in breakpoints if bp.startswith("待确认标记:")}:
                breakpoints.append(f"Open Questions: {stripped[:120]}")
            continue
        match = re.search(r"结论\s*[:：]\s*(.+)$", stripped)
        if match and is_unclosed_cell(match.group(1)):
            breakpoints.append(f"Open Questions 结论未闭合: {stripped[:120]}")

    # 去重保序
    seen: set[str] = set()
    unique: list[str] = []
    for item in breakpoints:
        if item not in seen:
            seen.add(item)
            unique.append(item)
    return unique


def is_invalid_approver(value: str) -> bool:
    return is_placeholder(value) or bool(GENERIC_APPROVER_RE.match((value or "").strip()))


def parse_gate_cell(value: str) -> dict[str, str]:
    value = (value or "").strip()
    status_match, approver_match, date_match = STATUS_RE.search(value), APPROVER_RE.search(value), ISO_DATE_RE.search(value)
    status = status_match.group(1).strip() if status_match else value.split("|")[0].split("（")[0].strip()
    return {
        "status": status,
        "approver": approver_match.group(1).strip() if approver_match else "",
        "date": date_match.group(0) if date_match else "",
        "raw": value,
    }


def parse_gate_records(text: str) -> dict[str, dict[str, str]]:
    frontmatter = parse_frontmatter_block(text) or {}
    return {
        gate: parse_gate_cell(frontmatter[gate.lower()])
        for gate in ("Gate-0", "Gate-1", "Gate-2")
        if frontmatter.get(gate.lower())
    }


def _gate_status_token(gate: dict[str, str] | None) -> str:
    if not gate:
        return ""
    return (gate.get("status") or "").strip()


def gate0_is_partial(gate: dict[str, str] | None) -> bool:
    """True when Gate-0 is 部分通过 (or deprecated English partial)."""
    status = _gate_status_token(gate)
    if not status:
        return False
    return status in GATE0_PARTIAL or status.lower() in GATE0_PARTIAL_LEGACY


def gate0_is_complete(gate: dict[str, str] | None, status: str | None) -> tuple[bool, str]:
    if not gate:
        return False, "未找到 Gate-0 记录"
    token = _gate_status_token(gate)
    if token in GATE0_PASSED or token.lower() in GATE0_PASSED_LEGACY:
        return True, ""
    # 部分通过 + 需求已交付：release 允许（Deferred 须入 backlog，见 guard_release）
    if gate0_is_partial(gate) and status == "shipped":
        return True, ""
    return False, gate["raw"]


def gate1_is_approved(gate: dict[str, str] | None) -> tuple[bool, str]:
    if not gate:
        return False, "未找到 Gate-1 记录"
    token = _gate_status_token(gate)
    if token in GATE1_APPROVED or "已批准" in token:
        return True, ""
    # deprecated: English alias for unmigrated history
    if token.lower() in GATE1_APPROVED_LEGACY or "approved" in token.lower():
        return True, ""
    return False, gate["raw"]


def gate1_is_pending(gate: dict[str, str] | None) -> bool:
    return bool(gate and ("待批准" in gate["status"] or gate["status"].strip() in GATE1_PENDING))


def gate2_is_accepted(gate: dict[str, str] | None) -> tuple[bool, str]:
    if not gate:
        return False, "未找到 Gate-2 记录"
    token = _gate_status_token(gate)
    if token in GATE2_ACCEPTED or "已验收" in token:
        return True, ""
    # deprecated: English alias for unmigrated history
    if token.lower() in GATE2_ACCEPTED_LEGACY or "accepted" in token.lower():
        return True, ""
    return False, gate["raw"]


def gate_status_is_pending(gate: dict[str, str] | None) -> bool:
    """True when Gate 处于待*态，无需审批人/日期留痕。"""
    token = _gate_status_token(gate)
    if not token:
        return True
    return token in GATE_PENDING_STATUSES or token.startswith("待")


def gate_requires_approver_audit(gate: dict[str, str] | None) -> bool:
    """非待*态 Gate 须写审批人+日期（部分通过/已通过/已驳回/已批准/已验收等）。"""
    token = _gate_status_token(gate)
    if not token:
        return False
    return not gate_status_is_pending(gate)


def gate_is_signed(gate: dict[str, str] | None, *, gate_name: str) -> bool:
    """True when the gate is in a signed/passed state (已通过/已批准/已验收)."""
    if not gate:
        return False
    token = _gate_status_token(gate)
    if gate_name == "Gate-0":
        return token in GATE0_PASSED or token.lower() in GATE0_PASSED_LEGACY
    if gate_name == "Gate-1":
        ok, _ = gate1_is_approved(gate)
        return ok
    if gate_name == "Gate-2":
        ok, _ = gate2_is_accepted(gate)
        return ok
    return False


def extract_deferred_ids(text: str) -> list[str]:
    return sorted(set(re.findall(r"\bDEF-\d+(?:-\d+)?\b", text)))


def missing_deferred_in_backlog(ids: list[str]) -> list[str]:
    backlog = paths.ROOT / "docs/requirements/backlog.md"
    if not ids:
        return []
    if not backlog.is_file():
        return ids
    body = backlog.read_text(encoding="utf-8", errors="ignore")
    return [item for item in ids if item not in body]


def ambiguity_table_issues(section: str) -> list[str]:
    table = find_table(section, ())
    if table is None:
        return ["歧义登记表缺少必要列：结论、确认人/日期"]
    headers, rows = table
    i_conclusion, i_approver, i_date = (
        find_col(headers, ("结论",)), find_col(headers, ("确认人",)), find_col(headers, ("日期",)),
    )
    if i_approver is not None and i_date is None:
        i_date = i_approver
    missing = [label for label, index in (("结论", i_conclusion), ("确认人", i_approver), ("日期", i_date)) if index is None]
    if missing:
        return [f"歧义登记表缺少必要列：{'、'.join(missing)}"]
    issues: list[str] = []
    for number, row in enumerate(rows, 1):
        label = row[0] or f"第 {number} 行"
        conclusion = cell(row, i_conclusion)
        if is_unclosed_cell(conclusion) or is_placeholder(conclusion) or PENDING_CONFIRM_RE.search(conclusion) or conclusion.lower() in DEVIATION_NONE:
            issues.append(f"歧义登记 {label} 的结论未闭合")
        approver_raw, date_raw = cell(row, i_approver), cell(row, i_date)
        approver = approver_raw
        if i_approver == i_date:
            approver = ISO_DATE_RE.sub("", approver)
            approver = re.sub(r"(?:确认人|日期)\s*[:：]?", "", approver).strip(" \t；;,，/|（）()")
        if is_unclosed_cell(approver) or is_invalid_approver(approver) or approver.lower() in DEVIATION_NONE:
            issues.append(f"歧义登记 {label} 缺少具体非泛称确认人")
        if is_unclosed_cell(date_raw) or is_placeholder(date_raw) or not ISO_DATE_RE.search(date_raw):
            issues.append(f"歧义登记 {label} 缺少 YYYY-MM-DD 确认日期")
    if not rows:
        issues.append("歧义登记表缺少数据行")
    return issues


def ambiguity_intake_issues(text: str) -> list[str]:
    issues: list[str] = []
    original = extract_section(text, "原始诉求")
    if original is None:
        issues.append("缺少「原始诉求」章节，无法核对 AC 是否改写了用户/PRD 原话")
    elif not original:
        issues.append("缺少有效原始诉求内容，无法核对 AC 是否改写了用户/PRD 原话")
    ambiguity = extract_section(text, "歧义登记")
    if ambiguity is None:
        issues.append("缺少「歧义登记」结论，无法确认多义表述已经人工消歧")
    elif not ambiguity:
        issues.append("「歧义登记」章节缺少有效结论，无法确认多义表述已经人工消歧")
    else:
        none = re.search(r"^歧义登记\s*:\s*none[^\n]*$", ambiguity, re.M | re.I)
        if none:
            line = none.group(0)
            match = re.search(r"确认人\s*[:：]\s*([^；;,，）)\n]+)", line)
            confirmer = match.group(1).strip() if match else ""
            if is_invalid_approver(confirmer) or confirmer.lower() in DEVIATION_NONE:
                issues.append("`歧义登记: none` 缺少具体确认人")
            if not re.search(r"日期\s*[:：]\s*20\d{2}-\d{2}-\d{2}", line):
                issues.append("`歧义登记: none` 缺少确认日期")
        else:
            issues.extend(ambiguity_table_issues(ambiguity))
    return issues


def type_classification_intake_warnings(text: str) -> list[str]:
    if parse_frontmatter_type(text) != "technical":
        return []
    warnings: list[str] = []
    if not any(marker in text for marker in TYPE_MATRIX_MARKERS):
        warnings.append("YAML properties 缺少「类型判型结论」；须记录类型及判型依据（见 45-requirement-intake）。")
    if not any(marker in text for marker in ("DDD主类", "DDD 主类", "DDD 影响", "A/B/C/D", "无领域影响", "领域影响")):
        warnings.append("`类型=技术` 但未记录 DDD 影响判定（主类 D 或 A/B/C/D 证据）；不得仅凭「无指标不变量」标技术。")
    rows = parse_closure_table(text) or []
    if any(PLATFORM_BC_RE.search(f"{row['source']} {row['process']} {row['sink']}") for row in rows if is_confirmed_cell(row["closure"])):
        warnings.append("frontmatter `类型=技术`，但数据流闭环表触及 platform BC（sys_* / system API / 系统管理服务等）；建议改判 `混合` 并规划 Gate-3 domain+capability 沉淀。")
    return warnings


def extract_constraint_doc_paths(text: str) -> list[str]:
    section = extract_section(text, "约束引用") or ""
    return list(dict.fromkeys(CONSTRAINT_DOC_REF_RE.findall(section)))


def constraint_reference_path_existence_issues(text: str) -> list[str]:
    issues: list[str] = []
    for rel in extract_constraint_doc_paths(text):
        if not (paths.ROOT / rel).is_file():
            issues.append(f"约束引用路径不存在：{rel}")
    return issues


def constraint_reference_panel_ref_warnings(text: str) -> list[str]:
    section = extract_section(text, "约束引用") or ""
    if not PATTERN_DOC_REF_RE.search(section):
        return []
    if CONSTRAINT_REF_NONE_RE.search(section or text):
        return []
    impl_section = extract_section(text, "实现方案") or ""
    search_scope = f"{section}\n{impl_section}"
    if PANEL_REF_RE.search(search_scope):
        return []
    return [
        "约束引用含 UI pattern（docs/patterns/），但 Gate-1「复用映射」未写 "
        f"{paths.FRONTEND_DIR}/src/components/*Panel.vue 参照坐标",
    ]


def constraint_reference_intake_warnings(text: str) -> list[str]:
    warnings: list[str] = []
    section = extract_section(text, "约束引用") or ""
    if parse_frontmatter_type(text) in ("business", "hybrid") and CONSTRAINT_REF_NONE_RE.search(section or text):
        if "触达面" not in section:
            warnings.append(
                "业务/混合需求「约束引用: none」缺少「触达面」关键词——"
                "须写「约束引用: none（已检索，触达面：模块|BC|关键词）」且触达面非空"
            )
        elif re.search(r"触达面\s*[:：]\s*(?:…|\.\.\.|<.*>|\s*)）", section):
            warnings.append("业务/混合需求「约束引用: none」的触达面为空或仍为占位符")
    warnings.extend(constraint_reference_panel_ref_warnings(text))
    if not SYSTEM_LIST_UI_TOUCH_RE.search(text):
        return warnings
    has_reference = (
        bool(CONSTRAINT_REF_NONE_RE.search(text))
        or bool(PATTERN_DOC_REF_RE.search(section))
        or bool(re.search(r"docs/(?:pitfalls|domain|decisions)/", section))
        or ("Experience Reuse" in text and bool(PATTERN_DOC_REF_RE.search(text)))
    )
    if not has_reference:
        warnings.append("触达 system 列表页 UI，但缺少「约束引用」章节（或 docs/patterns/ 引用 / 约束引用: none）")
    return warnings


def conflict_scan_intake_warnings(text: str) -> list[str]:
    if parse_frontmatter_type(text) not in ("business", "hybrid"):
        return []
    if any(marker in text for marker in ("冲突识别", "冲突结论", "无冲突", "冲突清单")):
        return []
    return ["业务/混合需求缺少「冲突识别」处置结论——未记录是否与 capability-map/domain 不变量/decisions 冲突（写『无冲突』或冲突清单+处置）"]


def section_has_executable_command(section: str) -> bool:
    return bool(
        re.search(r"```[\w-]*\r?\n[^\n`]+", section)
        or re.search(r"`[^`\n]{3,}`", section)
        or re.search(r"验证命令|Run:|执行[:：]", section, re.I)
    )


def plan_has_slice_items(plan: str) -> bool:
    if "切片拆解" not in plan:
        return False
    chunk = re.split(r"^##\s+", plan.split("切片拆解", 1)[-1], maxsplit=1, flags=re.M)[0]
    return bool(
        re.search(r"^\s*\d+\.\s", chunk, re.M)
        or (re.search(r"^\|\s*切片\s*\|\s*覆盖\s*AC\s*\|", chunk, re.M | re.I)
            and re.search(r"^\|[^|\n]+\|\s*AC-\d+", chunk, re.M | re.I))
    )


def plan_has_regression_commands(plan: str) -> bool:
    if "回归验证" not in plan:
        return False
    return section_has_executable_command(re.split(r"^##\s+", plan.split("回归验证", 1)[-1], maxsplit=1, flags=re.M)[0])


def plan_has_placeholders(plan: str) -> list[str]:
    hits = [token for token in ("待填充", "TODO", "TBD") if re.search(rf"\b{token}\b", plan, re.I)]
    return hits + (["<...>"] if re.search(r"<[^>\n/]+>", plan) else [])


RED_PLAN_PLACEHOLDER_RE = re.compile(
    r"红档以\s*OpenSpec|OpenSpec\s*产物为准\s*[（(]\s*黄档无|黄档无\s*[）)]",
    re.I,
)
GREEN_TRIVIAL_ACCEPTANCE_NA_RE = re.compile(r"不适用\s*[（(]\s*green-trivial\s*[）)]", re.I)
AC_ITEM_RE = re.compile(r"(?:^|\n)\s*(?:-\s*\[[ xX]\]\s*)?\*?\*?AC-[A-Za-z0-9]+\*?\*?\s*[：:]", re.M)
GWT_RE = re.compile(r"\bGIVEN\b.+\bWHEN\b.+\bTHEN\b", re.I | re.S)


def gate0_goals_use_case_issues(text: str) -> list[str]:
    """Content checks for Gate-0 业务目标 / 用例 (business|hybrid must be non-empty)."""
    req_type = parse_frontmatter_type(text)
    issues: list[str] = []
    goals = extract_section(text, "业务目标")
    use_cases = extract_section(text, "用例")
    if goals is None:
        issues.append("缺少「业务目标」章节")
    if use_cases is None:
        issues.append("缺少「用例 / 用户故事」章节")
    if req_type in ("business", "hybrid"):
        if goals is not None and not (goals or "").strip():
            issues.append("「业务目标」章节为空")
        if use_cases is not None and not (use_cases or "").strip():
            issues.append("「用例 / 用户故事」章节为空")
        for label, body in (("业务目标", goals), ("用例 / 用户故事", use_cases)):
            if body and re.search(r"不适用\s*[（(]\s*类型\s*=\s*(?:技术|缺陷)", body):
                issues.append(f"{req_type} 需求「{label}」不得写类型=技术|缺陷 的不适用声明")
    return issues


def acceptance_criteria_issues(text: str) -> list[str]:
    """Content checks for Gate-1 ## 验收标准 (used by --check-plan)."""
    section = extract_section(text, "验收标准")
    if section is None:
        return ["缺少「验收标准」章节"]
    body = (section or "").strip()
    if not body:
        return ["「验收标准」章节为空"]
    if GREEN_TRIVIAL_ACCEPTANCE_NA_RE.search(body):
        return []
    issues: list[str] = []
    if not AC_ITEM_RE.search(body):
        issues.append("验收标准缺少 ≥1 条 AC-* 条目")
    if "反例（本 AC 排除）" not in body and "反例(本 AC 排除)" not in body:
        issues.append("验收标准缺少「反例（本 AC 排除）」")
    if SYSTEM_LIST_UI_TOUCH_RE.search(text) and not GWT_RE.search(body):
        issues.append("触达 system 列表页 UI 时，验收标准至少一条须含 GIVEN/WHEN/THEN")
    return issues


def plan_has_red_placeholder(plan: str) -> bool:
    return bool(RED_PLAN_PLACEHOLDER_RE.search(plan or ""))


def green_trivial_has_verify_steps(text: str) -> bool:
    return any(section_has_executable_command(section) for name in ("实施与验证", "实现方案") if (section := extract_section(text, name)))
