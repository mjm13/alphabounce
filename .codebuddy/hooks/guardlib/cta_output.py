"""CTA-first markdown output for ``--resolve-gate --format cta``."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from guard_intake import _intake_issues
from guard_plan import collect_plan_check

from .closeout import resolve_current_gate
from .openspec import openspec_structural_issues
from .requirement import (
    parse_frontmatter_tier,
    parse_frontmatter_type,
    requirement_touches_ui,
    resolve_tier,
)

TIER_DISPLAY = {
    "green": "绿",
    "green-trivial": "绿-轻量",
    "yellow": "黄",
    "red": "红",
}

TYPE_DISPLAY = {
    "business": "业务",
    "technical": "技术",
    "hybrid": "混合",
    "defect": "缺陷",
}

SUBSTATE_TITLES = {
    "Gate-0": "Gate-0(需求澄清)",
    "OpenSpec 不匹配": "OpenSpec(变更包)",
    "Gate-1 方案缺口": "Gate-1(方案审核) 方案缺口",
    "Gate-1 待批准": "Gate-1(方案审核) 待批准",
    "实现中": "实现(编码验证) 进行中",
    "Gate-2 待验收": "Gate-2(人工检查) 待验收",
    "Gate-3": "Gate-3(沉淀知识库)",
    "已收尾": "已收尾",
}


@dataclass(frozen=True)
class CtaContext:
    req_path: Path
    text: str
    resolved: dict[str, str]
    tier: str | None
    req_type: str | None
    short_name: str
    substate: str
    intake_exit: int
    intake_blockers: tuple[str, ...]
    plan_ok: bool
    plan_issues: tuple[str, ...]
    openspec_errors: tuple[str, ...]
    openspec_warnings: tuple[str, ...]
    release_blockers: tuple[str, ...] = ()


def _req_rel_path(req_path: Path) -> str:
    try:
        from .paths import ROOT

        return req_path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return req_path.name


def _fetch_release_blockers(req_path: Path) -> tuple[str, ...]:
    """Objective ``--check-release`` blocking items for CTA hints."""
    try:
        from guard_release import _release_issues
        from .gitio import changed_all_files, changed_impl_files

        rel = _req_rel_path(req_path)
        result = _release_issues(
            "HEAD",
            rel,
            changed_all_files("HEAD"),
            changed_impl_files("HEAD"),
        )
        return tuple(result.blocking)
    except Exception:
        return ()


def _inbox_requirement_files() -> list[Path]:
    from .paths import INBOX_DIR

    if not INBOX_DIR.is_dir():
        return []
    return sorted(
        p for p in INBOX_DIR.glob("*.md")
        if re.fullmatch(r"\d{14}-.+", p.stem)
    )


def requirement_short_name(path: Path) -> str:
    stem = path.stem
    match = re.fullmatch(r"(\d{14})-(.+)", stem)
    if match:
        seq = match.group(1)[-3:]
        return f"{seq} {match.group(2)}"
    return stem


def _tier_label(tier: str | None) -> str:
    if not tier:
        return "未知"
    return TIER_DISPLAY.get(tier, tier)


def _type_label(req_type: str | None) -> str:
    if not req_type:
        return "未知"
    return TYPE_DISPLAY.get(req_type, req_type)


def _intake_blocker_lines(result_messages: tuple[str, ...]) -> tuple[str, ...]:
    blockers: list[str] = []
    for message in result_messages:
        stripped = message.strip()
        if not stripped or stripped.startswith("[pipeline] OK"):
            continue
        if stripped.startswith("[pipeline]"):
            stripped = stripped[len("[pipeline]") :].strip()
        if stripped.startswith("- "):
            blockers.append(stripped[2:])
        elif stripped.startswith("→"):
            if blockers:
                blockers[-1] = f"{blockers[-1]} {stripped}"
        elif "Gate-0 不通过" in stripped or "不完整" in stripped or "不合规" in stripped:
            blockers.append(stripped)
        elif stripped.startswith("  - "):
            blockers.append(stripped[4:])
    deduped: list[str] = []
    seen: set[str] = set()
    for item in blockers:
        if item not in seen:
            seen.add(item)
            deduped.append(item)
    return tuple(deduped[:3])


def build_cta_context(req_path: Path, text: str) -> CtaContext:
    resolved = resolve_current_gate(req_path, text)
    tier, _ = resolve_tier(text, "")
    req_type = parse_frontmatter_type(text)
    short_name = requirement_short_name(req_path)

    intake = _intake_issues(text, tier or "", req_path)
    intake_blockers = _intake_blocker_lines(intake.messages)

    plan = collect_plan_check(text, "")
    os_errors, os_warnings = openspec_structural_issues(text, req_path)

    current_gate = resolved["current_gate"]
    substate = current_gate

    if os_errors:
        substate = "OpenSpec 不匹配"
    elif current_gate == "Gate-0":
        substate = "Gate-0"
    elif current_gate == "Gate-1":
        substate = "Gate-1 方案缺口" if not plan.ok else "Gate-1 待批准"
    elif current_gate == "实现":
        substate = "实现中"
    elif current_gate == "Gate-2":
        substate = "Gate-2 待验收"
    elif current_gate == "Gate-3":
        substate = "Gate-3"
    elif current_gate == "无":
        substate = "已收尾"

    release_blockers: tuple[str, ...] = ()
    if substate in ("实现中", "Gate-2 待验收"):
        release_blockers = _fetch_release_blockers(req_path)

    return CtaContext(
        req_path=req_path,
        text=text,
        resolved=resolved,
        tier=tier,
        req_type=req_type,
        short_name=short_name,
        substate=substate,
        intake_exit=intake.exit_code,
        intake_blockers=intake_blockers,
        plan_ok=plan.ok,
        plan_issues=plan.issues,
        openspec_errors=tuple(os_errors),
        openspec_warnings=tuple(os_warnings),
        release_blockers=release_blockers,
    )


def _blockers(ctx: CtaContext) -> tuple[str, ...]:
    items: list[str] = []
    if ctx.openspec_errors:
        items.extend(f"- {err} → 确认 openspec 变更名或 propose 新 change" for err in ctx.openspec_errors)
    if ctx.resolved["current_gate"] == "Gate-0" and ctx.intake_exit != 0:
        for blocker in ctx.intake_blockers:
            items.append(f"- {blocker} → 补文档后重跑 `--check-intake`")
    if ctx.resolved["current_gate"] == "Gate-1" and not ctx.plan_ok:
        for issue in ctx.plan_issues[:3]:
            items.append(f"- 缺 {issue} → Agent 执行 A.0.5 + writing-plans")
    if ctx.release_blockers:
        for blocker in ctx.release_blockers[:3]:
            items.append(f"- release：{blocker} → Agent 按 **然后** 修复后重跑 `--check-release`")
    if ctx.resolved["current_gate"] == "Gate-3" and ctx.resolved.get("reason"):
        items.append(f"- {ctx.resolved['reason']} → 完成 sync/Move/closeout")
    return tuple(items[:4])


def _step_instruction(ctx: CtaContext) -> str:
    """单行、可执行的本步动作（用户或 Agent 一眼可知做什么）。"""
    rel = _req_rel_path(ctx.req_path)
    sub = ctx.substate
    reason = ctx.resolved.get("reason", "")

    if sub == "OpenSpec 不匹配":
        return "确认 OpenSpec change 名与需求 scope 一致，或 propose 新 change"
    if sub == "Gate-0":
        return "你：逐条确认歧义/OQ/闭环表 → Agent 回写 Gate-0 并 `--check-intake --req`"
    if sub == "Gate-1 方案缺口":
        return "Agent：A.0.5 + writing-plans 补 Gate-1 → `--check-plan --req`"
    if sub == "Gate-1 待批准":
        return ""
    if sub == "实现中":
        if ctx.release_blockers:
            return f"Agent：消除 release 阻塞 → `python .codebuddy/hooks/pipeline_guard.py --check-release --req {rel}`"
        if "验收记录未齐备" in reason:
            return f"Agent：跑 verify → 填「验收记录」（含组件测试/AC 证据）→ `--check-release --req {rel}`"
        return f"Agent：完成当前切片 + verify → `--check-release --req {rel}` → 提请 Gate-2"
    if sub == "Gate-2 待验收":
        if ctx.release_blockers:
            return f"Agent：先消除 release 阻塞 → `--check-release --req {rel}`，再请你 Gate-2 签字"
        return "你：回复「Gate-2 验收通过，审批人 <git config user.name>，YYYY-MM-DD」"
    if sub == "Gate-3":
        return f"Agent：`--gate3-trigger-report --req {rel}` → xijia-sync-knowledge → Move inbox→shipped → `--check-closeout`"
    if sub == "已收尾":
        return "可选 `/xijia:start <下一需求>` 或显式 `git commit`"
    return ctx.resolved.get("next_user_action", "见附录")


def _please_and_then(ctx: CtaContext) -> tuple[str, str]:
    sub = ctx.substate
    tier = ctx.tier or "yellow"
    rel = _req_rel_path(ctx.req_path)
    release_cmd = f"`python .codebuddy/hooks/pipeline_guard.py --check-release --req {rel}`"

    if sub == "OpenSpec 不匹配":
        return (
            "确认 OpenSpec change 名与需求 scope 一致，或 propose 新 change 并更新 frontmatter `openspec变更`",
            "Agent 跑 `--check-intake` → propose/analyze → 再输出 Gate-1 CTA",
        )
    if sub == "Gate-0":
        return (
            "确认歧义/OQ/闭环表断点（逐条文字回复）",
            f"Agent 回写 Gate-0 → `python .codebuddy/hooks/pipeline_guard.py --check-intake --req {rel}` → 再输出 CTA",
        )
    if sub == "Gate-1 方案缺口":
        return (
            "无（Agent 继续）",
            f"Agent 执行 A.0.5 + writing-plans 补 Gate-1 → `python .codebuddy/hooks/pipeline_guard.py --check-plan --req {rel}` → 再输出待批准 CTA",
        )
    if sub == "Gate-1 待批准":
        if requirement_touches_ui(ctx.text):
            return (
                "审阅 Gate-1（页面布局预览 → 验收标准 → UI 验收证据约定 → 实现方案）后回复 → "
                "`批准 Gate-1` 或 `批准 Gate-1；UI验收证据: 组件测试|Playwright|集成测试`",
                "Agent 同轮按 frontmatter `UI验收证据` 档位切片 TDD → comment-sync → verify"
                "（未声明则按组件测试）→ 填验收记录 → 提请 Gate-2（不再问是否开工）",
            )
        return (
            "审阅 Gate-1（页面布局预览 → 验收标准 → 实现方案）后回复 → `批准 Gate-1`",
            "Agent 同轮切片 TDD → comment-sync → verify → 填验收记录 → 提请 Gate-2（不再问是否开工）",
        )
    if sub == "实现中":
        verify_hint = "`cd frontend && npm run lint && npm run test && npm run build`（或 AGENTS 等价 verify）"
        if ctx.release_blockers:
            return (
                "无（Agent 继续）",
                f"Agent 按 **阻塞** 逐项修复 → {release_cmd} 通过 → 填验收记录 → 再输出 Gate-2 CTA",
            )
        if "验收记录未齐备" in ctx.resolved.get("reason", ""):
            return (
                "无（Agent 继续）",
                f"Agent 同轮 {verify_hint} → 填「验收记录」→ {release_cmd}",
            )
        return (
            "无（Agent 继续）",
            f"Agent 同轮切片 TDD → comment-sync → {verify_hint} → {release_cmd} → 提请 Gate-2",
        )
    if sub == "Gate-2 待验收":
        if ctx.release_blockers:
            return (
                "无（Agent 继续）",
                f"Agent 消除 release 阻塞 → {release_cmd} 通过后，再请你 Gate-2 签字",
            )
        return (
            "回复「Gate-2 验收通过，审批人 <git config user.name>，YYYY-MM-DD」",
            f"Agent 同轮更新 frontmatter Gate-2 → `--check-gate3-preflight --req {rel}` → archive-requirement → `--check-closeout`",
        )
    if sub == "Gate-3":
        return (
            "无（Agent 继续）",
            f"Agent 跑 `--gate3-trigger-report --req {rel}` → xijia-sync-knowledge → Move → `--check-closeout`；commit 另触发",
        )
    if sub == "已收尾":
        return (
            "无（Agent 继续）",
            "Agent 提示 `/xijia:release` 或 `/xijia:start <next>`；commit 由你显式触发",
        )
    return (
        ctx.resolved.get("next_user_action", "见附录"),
        "Agent 按 session-recovery 路由表执行当前门禁动作",
    )


def _inbox_summary_line() -> str:
    from .paths import read_utf8_text

    items: list[str] = []
    for req in _inbox_requirement_files():
        try:
            text = read_utf8_text(req)
            gate = resolve_current_gate(req, text)["current_gate"]
            items.append(f"{requirement_short_name(req)} · {gate}")
        except (OSError, UnicodeDecodeError):
            items.append(f"{requirement_short_name(req)} · ?")
    if not items:
        return "进行中：inbox 暂无需求文档"
    return "进行中：" + " | ".join(items)


def _append_cta_fields(lines: list[str], *fields: str) -> None:
    """Append labeled CTA fields with blank lines so Markdown keeps them as paragraphs.

    Consecutive ``**label：**`` lines without a blank line collapse into one paragraph
    in CommonMark / Cursor chat.
    """
    nonempty = [field for field in fields if field]
    for index, field in enumerate(nonempty):
        if index:
            lines.append("")
        lines.append(field)


def render_cta_missing_req() -> str:
    lines = [
        "## 请指定需求文档",
        "",
        _inbox_summary_line(),
        "",
    ]
    _append_cta_fields(
        lines,
        "**请你：** 在 `/xijia:start` 后带上 inbox 路径或文件名，"
        "例如 `docs/requirements/inbox/20260806100901-系统参数设置.md`",
        "**然后：** Agent 对该篇执行 `--resolve-gate --req <path> --format cta` 并照贴输出（含 **本步指令**）",
    )
    return "\n".join(lines)


def format_cta_markdown(ctx: CtaContext) -> str:
    tier_type = f"{_tier_label(ctx.tier)} · {_type_label(ctx.req_type)}"
    title_label = SUBSTATE_TITLES.get(ctx.substate, ctx.substate)
    title = f"## {title_label} · {ctx.short_name}（{tier_type}）"
    lines = [title, ""]

    blockers = _blockers(ctx)
    if blockers:
        lines.append("**阻塞：**")
        lines.extend(blockers)
        lines.append("")

    please, then = _please_and_then(ctx)
    step = _step_instruction(ctx)
    ui_line = ""
    if ctx.substate == "Gate-1 待批准" and requirement_touches_ui(ctx.text):
        ui_line = (
            "**UI 验收证据：** 本需求触达 UI。请在批准时声明档位（默认组件测试）。"
            "可选：Playwright / 集成测试。"
        )
    step_line = f"**本步指令：** {step}" if step else ""
    _append_cta_fields(
        lines,
        ui_line,
        step_line,
        f"**请你：** {please}",
        f"**然后：** {then}",
    )

    rel = _req_rel_path(ctx.req_path)

    appendix: list[str] = []
    if ctx.substate == "Gate-1 待批准":
        appendix.append(f"- 需求路径：`{rel}`")
    if ctx.substate == "Gate-2 待验收" and not ctx.release_blockers:
        appendix.append(f"- 需求路径：`{rel}`")
        appendix.append("- 快速验收：浏览器打开四页确认页头面包屑 + 功能说明（可选）")
    if ctx.openspec_warnings:
        appendix.extend(f"- OpenSpec 提醒：{w}" for w in ctx.openspec_warnings)

    if appendix:
        lines.extend(["", "### 附录", *appendix])

    return "\n".join(lines)


def render_cta(req_path: Path, text: str) -> str:
    ctx = build_cta_context(req_path, text)
    return format_cta_markdown(ctx)
