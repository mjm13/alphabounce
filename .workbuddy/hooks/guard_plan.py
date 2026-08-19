#!/usr/bin/env python3
"""Gate-1 plan check (green/yellow/green-trivial; red without OpenSpec package)."""

from __future__ import annotations

import re
from pathlib import Path

from guardlib import PIPELINE_PREFIX, paths
from guardlib.markdown import extract_section
from guardlib.openspec import change_dir, missing_apply_artifacts
from dataclasses import dataclass

from guardlib.requirement import (
    acceptance_criteria_issues,
    domain_impact_intake_issues,
    gate1_is_approved,
    gate1_is_pending,
    green_trivial_has_verify_steps,
    has_green_trivial_marker,
    parse_frontmatter_openspec_change,
    parse_gate_records,
    plan_has_placeholders,
    plan_has_red_placeholder,
    plan_has_regression_commands,
    plan_has_slice_items,
    resolve_tier,
)


@dataclass(frozen=True)
class PlanCheckResult:
    ok: bool
    issues: tuple[str, ...]
    tier: str | None
    red_skipped: bool = False


def _red_openspec_package_ready(text: str) -> bool:
    """True when red tier has an OpenSpec change dir with core artifacts."""
    change = parse_frontmatter_openspec_change(text)
    if not change:
        return False
    if not change_dir(change).is_dir():
        return False
    return not missing_apply_artifacts(change, require_domain=False)


def collect_plan_check(text: str, tier: str) -> PlanCheckResult:
    """Silent plan check for CTA substate (no stdout)."""
    resolved_tier, tier_issues = resolve_tier(text, tier.lower())
    if any("不一致" in issue for issue in tier_issues):
        return PlanCheckResult(False, ("tier override 与 frontmatter 不一致",), resolved_tier)
    if resolved_tier is None:
        return PlanCheckResult(False, ("未找到分级",), None)

    if resolved_tier == "red" and _red_openspec_package_ready(text):
        return PlanCheckResult(True, (), resolved_tier, red_skipped=True)

    issues: list[str] = []
    green_trivial_fast_path = resolved_tier == "green-trivial" and has_green_trivial_marker(text)
    if green_trivial_fast_path:
        if not green_trivial_has_verify_steps(text):
            issues.append("green-trivial 的「实施与验证」/「实现方案」缺少可执行验证命令")
    else:
        issues.extend(domain_impact_intake_issues(text))
        issues.extend(acceptance_criteria_issues(text))
        plan_text = extract_section(text, "实现方案")
        if not plan_text:
            issues.append("缺少「实现方案」章节")
        else:
            if not re.search(r"复用映射|代码落点", plan_text):
                issues.append("缺少「复用映射 / 代码落点」")
            if not plan_has_slice_items(plan_text):
                issues.append("缺少「切片拆解」（需 ≥1 条编号项或 AC 映射表）")
            if not plan_has_regression_commands(plan_text):
                issues.append("缺少「回归验证点」（需含可执行验证命令，见 AGENTS.md）")
            placeholders = plan_has_placeholders(plan_text)
            if placeholders:
                issues.append(f"实现方案含占位符：{', '.join(placeholders)}")
            if plan_has_red_placeholder(plan_text):
                issues.append("实现方案含红档占位文案（黄档/无 OpenSpec 包须写满方案，禁止「红档以 OpenSpec…(黄档无)」）")

    gate1 = parse_gate_records(text).get("Gate-1")
    gate1_pending = gate1_is_pending(gate1)
    gate1_approved, _ = gate1_is_approved(gate1)
    if not gate1_pending and not gate1_approved:
        issues.append("YAML properties 缺少 Gate-1 状态（待批准/已批准）")

    return PlanCheckResult(not issues, tuple(issues), resolved_tier)


def _run_check_plan(req_path: str, tier: str) -> int:
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
    result = collect_plan_check(text, tier)
    resolved_tier = result.tier
    _, tier_issues = resolve_tier(text, tier.lower())
    for issue in tier_issues:
        print(f"{PIPELINE_PREFIX} tier 警告：{issue}")
    if any("不一致" in issue for issue in tier_issues):
        print("  → 以 YAML properties `分级` 为准；请移除或修正本次 CLI --tier override。")
        return 1
    if resolved_tier is None:
        print(f"{PIPELINE_PREFIX} 未找到分级，Gate-0 后须在 YAML properties 写入 `分级`。")
        return 1

    if result.red_skipped:
        print(f"{PIPELINE_PREFIX} 红档：OpenSpec 产物齐备，跳过 requirement 验收标准/实现方案内容校验。")
        return 0
    if resolved_tier == "red":
        print(
            f"{PIPELINE_PREFIX} 红档但 OpenSpec change 目录缺失或核心产物不齐："
            "按黄档校验 Gate-1 验收标准 + 实现方案。"
        )

    if resolved_tier == "green-trivial" and has_green_trivial_marker(text) and result.ok:
        print(f"{PIPELINE_PREFIX} green-trivial：「实施与验证」或「实现方案」含可执行命令，跳过完整方案字段校验。")

    issues = list(result.issues)
    if issues:
        print(f"{PIPELINE_PREFIX} 实现方案/验收标准不完整（Gate-1 前须补全）：{path.name}")
        for item in issues:
            print(f"  - {item}")
        print("  → PRD 落盘应已写满 Gate-1；缺口请跑 A.0.5 + writing-plans，或 `/xijia:start`。")
        return 1

    gate1 = parse_gate_records(text).get("Gate-1")
    gate1_pending = gate1_is_pending(gate1)
    state = "待批准" if gate1_pending else "已批准"
    print(f"{PIPELINE_PREFIX} OK：验收标准与实现方案齐备（Gate-1={state}），可提请或继续实现。")
    return 0
