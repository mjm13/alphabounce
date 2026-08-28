#!/usr/bin/env python3
"""Gate-0 intake + apply + resolve-gate orchestrators."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from guardlib import PIPELINE_PREFIX, paths
from guardlib.closeout import resolve_current_gate
from guardlib.openspec import change_dir, missing_apply_artifacts, openspec_structural_issues
from guardlib.requirement import (
    ambiguity_intake_issues,
    canonical_frontmatter_issues,
    conflict_scan_intake_warnings,
    constraint_reference_intake_warnings,
    constraint_reference_path_existence_issues,
    domain_impact_intake_issues,
    frontmatter_language_issues,
    gate0_goals_use_case_issues,
    has_green_trivial_marker,
    has_no_new_dataflow_declaration,
    is_confirmed_cell,
    is_unclosed_cell,
    open_deviation_tickets,
    parse_closure_table,
    parse_frontmatter_type,
    pending_confirmation_lines,
    prototype_table_intake_issues,
    resolve_tier,
    requirement_structure_issues,
    type_classification_intake_warnings,
)


def _run_resolve_gate(req_path: str, output_format: str = "") -> int:
    if output_format == "cta" and not req_path.strip():
        from guardlib.cta_output import render_cta_missing_req

        print(render_cta_missing_req())
        return 0

    if not req_path.strip():
        print(f"{PIPELINE_PREFIX} --resolve-gate 需要 --req <path>")
        return 2

    path = Path(req_path)
    path = path.resolve() if path.is_absolute() else (paths.ROOT / path).resolve()
    if not path.is_file():
        print(f"{PIPELINE_PREFIX} 需求文档不存在：{req_path}")
        return 2

    try:
        text = paths.read_utf8_text(path)
    except UnicodeDecodeError as exc:
        print(f"{PIPELINE_PREFIX} 需求文档不是有效 UTF-8：{req_path}（字节偏移 {exc.start}）")
        return 2

    if output_format == "cta":
        from guardlib.cta_output import render_cta

        print(render_cta(path, text))
        return 0

    resolved = resolve_current_gate(path, text)
    print(f"current_gate={resolved['current_gate']}")
    print(f"reason={resolved['reason']}")
    print(f"next_user_action={resolved['next_user_action']}")
    if resolved.get("hint"):
        print(f"hint={resolved['hint']}")
    if resolved["blocked_gates"]:
        print(f"blocked_gates={resolved['blocked_gates']}")
    return 0


def _gate_priority(gate: str) -> int:
    order = {"Gate-0": 0, "Gate-1": 1, "实现": 2, "Gate-2": 3, "Gate-3": 4, "无": 5}
    return order.get(gate, 99)


def _pick_active_inbox(inbox_files: list[Path], explicit: Path | None = None) -> Path:
    """Pick active req: explicit user path wins; else earliest incomplete gate."""
    if explicit is not None and explicit in inbox_files:
        return explicit
    scored: list[tuple[int, str, Path]] = []
    for req in inbox_files:
        try:
            text = paths.read_utf8_text(req)
        except (OSError, UnicodeDecodeError):
            continue
        gate = resolve_current_gate(req, text)["current_gate"]
        scored.append((_gate_priority(gate), req.stem, req))
    scored.sort(key=lambda item: (item[0], item[1]))
    return scored[0][2] if scored else (explicit or inbox_files[0])


def _inbox_requirement_files() -> list[Path]:
    if not paths.INBOX_DIR.is_dir():
        return []
    return sorted(
        p for p in paths.INBOX_DIR.glob("*.md")
        if re.fullmatch(r"\d{14}-.+", p.stem)
    )


def _run_scan_inbox() -> int:
    from guardlib.cta_output import requirement_short_name

    if not paths.INBOX_DIR.is_dir():
        print(f"{PIPELINE_PREFIX} inbox 目录不存在：{paths.INBOX_DIR}")
        return 2
    inbox_files = _inbox_requirement_files()
    if not inbox_files:
        print(f"{PIPELINE_PREFIX} inbox 为空")
        return 0
    active = _pick_active_inbox(inbox_files)
    for req in inbox_files:
        try:
            text = paths.read_utf8_text(req)
        except (OSError, UnicodeDecodeError) as exc:
            print(f"{req.name}\tERROR\t{exc}")
            continue
        gate = resolve_current_gate(req, text)["current_gate"]
        marker = "*" if req == active else ""
        print(f"{marker}{req.name}\t{gate}\t{requirement_short_name(req)}")
    print(f"active-req={active.relative_to(paths.ROOT).as_posix()}")
    return 0


def _run_check_apply(change: str, tier: str) -> int:
    if tier != "red":
        print(f"{PIPELINE_PREFIX} tier={tier}，跳过 OpenSpec 产物硬校验。")
        return 0
    if not change_dir(change).is_dir():
        print(f"{PIPELINE_PREFIX} 缺失 change 目录：docs/openspec/changes/{change}/")
        print("  → red 档进入 apply 前必须先完成 propose。禁止开始改实现代码。")
        return 1
    # require_domain unknown here; warn separately, hard-fail only on core docs.
    missing_core = missing_apply_artifacts(change, require_domain=False)
    if missing_core:
        print(f"{PIPELINE_PREFIX} red 档进入 apply 前 OpenSpec 产物缺失（change={change}）：")
        for item in missing_core:
            print(f"  - docs/openspec/changes/{item}")
        print("  → 回退补齐 propose/analyze 后再 apply。")
        return 1
    domain_missing = missing_apply_artifacts(change, require_domain=True)
    if domain_missing:
        print(f"{PIPELINE_PREFIX} 提醒：business/hybrid 建议补 domain 草稿（change={change}）：")
        for item in domain_missing:
            print(f"  - docs/openspec/changes/{item}")
    print(f"{PIPELINE_PREFIX} OK：change={change} 核心 OpenSpec 产物齐备，可进入 apply。")
    return 0


@dataclass(frozen=True)
class IntakeResult:
    messages: tuple[str, ...]
    exit_code: int


def _intake_filename_issues(path: Path) -> IntakeResult:
    match = re.fullmatch(r"\d{14}-(.+)", path.stem)
    if not match:
        return IntakeResult((
            f"{PIPELINE_PREFIX} 需求文件名不合规：'{path.name}' 只接受 14 位时间戳前缀（Gate-0 不通过）。",
            "  → 命名规范：`<YYYYMMDDHHMMSS>-<简述>.md`（简述优先中文，可含英文/缩写）。",
        ), 1)
    desc = match.group(1).strip()
    if not desc:
        return IntakeResult((
            f"{PIPELINE_PREFIX} 需求文件名不合规：'{path.name}' 缺少简述后缀（Gate-0 不通过）。",
            "  → 命名规范：`<YYYYMMDDHHMMSS>-<简述>.md`（见 45-requirement-intake）。",
        ), 1)
    return IntakeResult((), 0)


def _closure_issues(text: str, resolved_tier: str) -> tuple[list[dict[str, str]], list[str], bool]:
    req_type = parse_frontmatter_type(text)
    green_trivial = resolved_tier == "green-trivial" and has_green_trivial_marker(text)
    defect = req_type == "defect" and has_no_new_dataflow_declaration(text)
    if green_trivial or defect:
        reason = "green-trivial" if green_trivial else "缺陷需求"
        return [], [f"{PIPELINE_PREFIX} {reason} 已明确声明无新增数据流，跳过闭环表硬校验。"], False

    rows = parse_closure_table(text)
    if rows is None:
        return [], [f"{PIPELINE_PREFIX} 未找到「数据流闭环表」（需含 来源/去向 表头）。Gate-0 不通过。"], True
    if not rows:
        return [], [f"{PIPELINE_PREFIX} 数据流闭环表为空。Gate-0 不通过。"], True

    breaks: list[tuple[str, str, str]] = []
    for row in rows:
        for key, label in (("source", "来源"), ("process", "加工"), ("sink", "去向")):
            if is_unclosed_cell(row[key]):
                breaks.append((row["name"], label, row[key]))
        if not is_confirmed_cell(row["closure"]):
            breaks.append((row["name"], "闭环状态", row["closure"]))
    if not breaks:
        return rows, [], False
    messages = [f"{PIPELINE_PREFIX} 数据流未闭环，存在断点（Gate-0 不通过）："]
    messages.extend(f"  - {name} / {segment}: '{value.strip() or '空'}'" for name, segment, value in breaks)
    messages.append("  → 补齐断点并经二次确认回环（重建+复核+用户终认）后再进入分级。")
    return rows, messages, True


def _decision_issues(text: str) -> list[str]:
    messages: list[str] = []
    pending = pending_confirmation_lines(text)
    if pending:
        messages.append(f"{PIPELINE_PREFIX} 存在未确认决策标记（[待确认]/[待人工确认]），Gate-0 不通过：")
        messages.extend(f"  - {line}" for line in pending)
        messages.append("  → 每项必须给出结论并由用户确认（记确认人/日期）后，方可移出待确认或进入 Deferred。")
    deviations = open_deviation_tickets(text)
    if deviations:
        messages.append(f"{PIPELINE_PREFIX} 存在未审批的原型偏离单（审批=open/待确认），Gate-0 不通过：")
        messages.extend(f"  - {page} / {ticket}: 审批='{approval}'" for page, ticket, approval in deviations)
        messages.append("  → 原型偏离未 approved 前不得纳入 In-Scope；请人工审批（approved/rejected）后再进入分级。")
    return messages


def _intake_warning_messages(text: str) -> list[str]:
    messages: list[str] = []
    warning_specs = (
        (constraint_reference_intake_warnings(text), "提醒（弱校验）：约束引用预检索可能不完整：",
         "  → 见 xijia-prd-to-requirement Step 1.6 / requirements-template「约束引用」："
         "写入预检索表；UI pattern 命中时在 Gate-1「验收标准」衍生 AC-UI-*。"),
        (type_classification_intake_warnings(text), "提醒（弱校验）：类型判型可能偏窄：",
         "  → 见 45-requirement-intake「类型判型」与 xijia-ops-pipeline A.0.1。"),
        (conflict_scan_intake_warnings(text), "提醒（弱校验，能力D）：与现有系统冲突识别可能缺失：",
         "  → 对照 capability-map/domain 不变量/decisions，在 Gate-0「约束引用/冲突识别」写处置结论"
         "（无冲突/改需求/Deviation/ADR）；warning 起步不阻断，见 gate0-intake.md 维度6。"),
    )
    for issues, heading, hint in warning_specs:
        if issues:
            messages.append(f"{PIPELINE_PREFIX} {heading}")
            messages.extend(f"  - {item}" for item in issues)
            messages.append(hint)
    return messages


def _intake_issues(text: str, tier: str, req_path: Path | None = None) -> IntakeResult:
    metadata = canonical_frontmatter_issues(text)
    if metadata:
        messages = [f"{PIPELINE_PREFIX} canonical frontmatter 不完整（Gate-0 不通过）："]
        messages.extend(f"  - {issue}" for issue in metadata)
        return IntakeResult(tuple(messages), 1)

    language = frontmatter_language_issues(text)
    if language:
        messages = [f"{PIPELINE_PREFIX} frontmatter 值语言不合规（Gate-0 不通过）："]
        messages.extend(f"  - {issue}" for issue in language)
        messages.append("  → 见 45-requirement-intake：分级/类型/状态 的值只接受中文。")
        return IntakeResult(tuple(messages), 1)

    resolved_tier, tier_issues = resolve_tier(text, tier.lower())
    messages = [f"{PIPELINE_PREFIX} tier 警告：{issue}" for issue in tier_issues]
    if any("不一致" in issue for issue in tier_issues):
        messages.append("  → 以 YAML properties `分级` 为准；请移除或修正本次 CLI --tier override。")
        return IntakeResult(tuple(messages), 1)
    if resolved_tier is None:
        messages.append(f"{PIPELINE_PREFIX} 未找到分级，Gate-0 后须在 YAML properties 写入 `分级`。")
        return IntakeResult(tuple(messages), 1)

    structure_issues = requirement_structure_issues(text)
    if structure_issues:
        messages.append(f"{PIPELINE_PREFIX} 需求标题结构不合规（Gate-0 不通过）：")
        messages.extend(f"  - {issue}" for issue in structure_issues)
        return IntakeResult(tuple(messages), 1)

    goals_issues = gate0_goals_use_case_issues(text)
    if goals_issues:
        messages.append(f"{PIPELINE_PREFIX} Gate-0 业务目标/用例不完整（Gate-0 不通过）：")
        messages.extend(f"  - {item}" for item in goals_issues)
        messages.append("  → 业务/混合须写非空业务目标与用例；技术/缺陷可写「不适用（类型=技术|缺陷）」。")
        return IntakeResult(tuple(messages), 1)

    rows, closure_messages, blocked = _closure_issues(text, resolved_tier)
    messages.extend(closure_messages)
    if blocked:
        return IntakeResult(tuple(messages), 1)
    decision_messages = _decision_issues(text)
    messages.extend(decision_messages)
    if decision_messages:
        return IntakeResult(tuple(messages), 1)

    ambiguity = ambiguity_intake_issues(text)
    if ambiguity:
        messages.append(f"{PIPELINE_PREFIX} 原始诉求/歧义复核记录不完整（Gate-0 不通过）：")
        messages.extend(f"  - {item}" for item in ambiguity)
        messages.append("  → 原话逐字落盘；多义表述须列出至少两种读法并由用户文字确认。未确认项写 `[待确认]`，由既有决策门禁硬停。")
        return IntakeResult(tuple(messages), 1)

    domain_issues = domain_impact_intake_issues(text)
    if domain_issues:
        messages.append(f"{PIPELINE_PREFIX} 业务/混合领域影响不完整（Gate-0 不通过）：")
        messages.extend(f"  - {item}" for item in domain_issues)
        messages.append(
            "  → 见 section-fragments「领域影响」与 45-requirement-intake："
            "写 BC/术语/`INV-xxx`，或显式「本切片无新 INV（理由）」。"
        )
        return IntakeResult(tuple(messages), 1)

    prototype_issues = prototype_table_intake_issues(text)
    if prototype_issues:
        messages.append(f"{PIPELINE_PREFIX} 原型对照表不完整（Gate-0 不通过）：")
        messages.extend(f"  - {item}" for item in prototype_issues)
        return IntakeResult(tuple(messages), 1)

    constraint_path_issues = constraint_reference_path_existence_issues(text)
    if constraint_path_issues:
        messages.append(f"{PIPELINE_PREFIX} 约束引用路径不存在（Gate-0 不通过）：")
        messages.extend(f"  - {item}" for item in constraint_path_issues)
        messages.append(
            "  → PRD Step 1.6 须检索 docs/patterns/README 并按触达面写入真实 path；"
            "禁止引用仓库中不存在的沉淀文档。"
        )
        return IntakeResult(tuple(messages), 1)

    if req_path is not None:
        os_errors, os_warnings = openspec_structural_issues(text, req_path)
        if os_errors:
            messages.append(f"{PIPELINE_PREFIX} 红档 OpenSpec 结构性检查失败（Gate-0 不通过）：")
            messages.extend(f"  - {item}" for item in os_errors)
            messages.append("  → 修正 frontmatter `openspec变更` 或 propose 新 change 后再进入 Gate-1。")
            return IntakeResult(tuple(messages), 1)
        for warning in os_warnings:
            messages.append(f"{PIPELINE_PREFIX} 提醒（OpenSpec）：{warning}")

    messages.extend(_intake_warning_messages(text))
    messages.append(f"{PIPELINE_PREFIX} OK：{len(rows)} 条能力数据流闭环齐备，且无未确认决策/未审批偏离，可进入分级。")
    return IntakeResult(tuple(messages), 0)


def _run_check_intake(req_path: str, tier: str) -> int:
    path = Path(req_path)
    path = path.resolve() if path.is_absolute() else (paths.ROOT / path).resolve()
    if not path.is_file():
        print(f"{PIPELINE_PREFIX} 需求文档不存在：{req_path}")
        return 2
    result = _intake_filename_issues(path)
    if result.exit_code == 0:
        try:
            result = _intake_issues(paths.read_utf8_text(path), tier, path)
        except UnicodeDecodeError as exc:
            result = IntakeResult((
                f"{PIPELINE_PREFIX} 需求文档不是有效 UTF-8：{req_path}（字节偏移 {exc.start}）",
            ), 2)
    for message in result.messages:
        print(message)
    return result.exit_code
