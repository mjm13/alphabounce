#!/usr/bin/env python3
"""Verify/Gate-2/Gate-3 + hook + audit + release-readiness orchestrators."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

from guardlib import PIPELINE_PREFIX, paths as gc
from guardlib.closeout import (
    capability_index_closeout_issues as _capability_index_closeout_issues,
    domain_closeout_issues as _domain_closeout_issues,
    experience_distill_closeout_issues as _experience_distill_closeout_issues,
    false_noop_closeout_issues as _false_noop_closeout_issues,
    gate3_preflight_issues as _gate3_preflight_issues,
    modal_drawer_gaps as _modal_drawer_gaps,
    process_docs_archive_issues as _process_docs_archive_issues,
    reuse_logging_gaps as _reuse_logging_gaps,
)
from guardlib.comments import (
    already_noticed_today as _already_noticed_today,
    collect_endpoint_comment_issues as _collect_endpoint_comment_issues,
    file_has_semantic_comment as _file_has_semantic_comment,
)
from guardlib.gitio import (
    GitCommandError,
    TEST_RE as _TEST_RE,
    changed_all_files as _changed_all_files,
    changed_impl_files as _changed_impl_files,
    changed_test_files as _changed_test_files,
    needs_adr as _needs_adr,
)
from guardlib.hookio import extract_paths as _extract_paths
from guardlib.livingdocs import (
    agents_command_section_ready as _agents_command_section_ready,
    ci_or_local_declared as _ci_or_local_declared,
    inbox_active_requirements as _inbox_active_requirements,
    living_doc_link_issues as _living_doc_link_issues,
    stack_drift_issues as _stack_drift_issues,
)
from guardlib.markdown import extract_section as _extract_markdown_section, is_placeholder as _is_placeholder
from guardlib.openspec import active_change_dirs as _active_change_dirs, has_any_change_product as _has_any_change_product
from guardlib.requirement import (
    extract_deferred_ids as _extract_deferred_ids,
    frontmatter_language_issues as _frontmatter_language_issues,
    gate0_is_complete as _gate0_is_complete,
    gate0_is_partial as _gate0_is_partial,
    gate1_is_approved as _gate1_is_approved,
    gate2_is_accepted as _gate2_is_accepted,
    gate_requires_approver_audit as _gate_requires_approver_audit,
    is_invalid_approver as _is_invalid_approver,
    is_red_requirement_text as _is_red_requirement_text,
    missing_deferred_in_backlog as _missing_deferred_in_backlog,
    parse_frontmatter_status as _parse_frontmatter_status,
    parse_frontmatter_tier as _parse_frontmatter_tier,
    parse_frontmatter_type as _parse_frontmatter_type,
    parse_frontmatter_ui_evidence as _parse_frontmatter_ui_evidence,
    PATTERN_DOC_REF_RE,
    parse_gate_records as _parse_gate_records,
    red_requirements as _red_requirements,
)

BACKEND_DIR = gc.BACKEND_DIR
FRONTEND_DIR = gc.FRONTEND_DIR
INBOX_DIR = gc.INBOX_DIR
SHIPPED_DIR = gc.SHIPPED_DIR
CHANGES_DIR = gc.CHANGES_DIR


def _to_rel(value: str) -> str | None:
    return gc.to_rel(value)


def _is_comment_sync_code(rel: str) -> bool:
    return gc.is_comment_sync_code(rel)


def _read_utf8_text(path: Path) -> str:
    return gc.read_utf8_text(path)


_PLAYWRIGHT_EVIDENCE_RE = re.compile(r"Playwright|webapp-testing|e2e|frontend/e2e", re.I)
_INTEGRATION_EVIDENCE_RE = re.compile(r"集成|parity|with_server|verify-frontend", re.I)
_COMPONENT_EVIDENCE_RE = re.compile(r"截图|实机|组件测试|frontend/tests/", re.I)
_AC_UI_RE = re.compile(r"AC-UI-\d", re.I)
_SPEC_STRUCTURE_TOKEN_RE = re.compile(
    r"role-panel-foot__pager|role-panel-foot|menu-panel|role-panel-head|menu-panel-head|"
    r"role-search-field|menu-drawer\.is-on|menu-drawer.*is-on|pager-btns|data-testid=.*pagination",
    re.I,
)
_UI_PATTERN_GUARD_EVIDENCE_RE = re.compile(r"check-ui-pattern", re.I)
_UNEXECUTED_EVIDENCE_RE = re.compile(r"未执行|未验证|仅推断|待执行")
_FRONTEND_UI_FILE_RE = re.compile(
    rf"^{re.escape(FRONTEND_DIR)}/src/.*\.(?:vue|tsx?|jsx?)$",
    re.IGNORECASE,
)


def _ui_evidence_tier(req_text: str) -> str:
    """Resolved UI evidence tier: component (default), playwright, or integration."""
    return _parse_frontmatter_ui_evidence(req_text) or "component"


def _line_has_ui_evidence_for_tier(line: str, tier: str) -> bool:
    if _UNEXECUTED_EVIDENCE_RE.search(line):
        return False
    if tier == "playwright":
        return bool(_PLAYWRIGHT_EVIDENCE_RE.search(line))
    if tier == "integration":
        return bool(_INTEGRATION_EVIDENCE_RE.search(line))
    return bool(_COMPONENT_EVIDENCE_RE.search(line))


def _changed_frontend_specs(base: str) -> list[str]:
    return [
        rel for rel in _changed_test_files(base)
        if rel.startswith(f"{FRONTEND_DIR}/tests/") and rel.endswith(".spec.js")
    ]


def _req_needs_ui_pattern_spec(req_text: str) -> bool:
    constraint = _extract_markdown_section(req_text, "约束引用") or ""
    acceptance = _extract_markdown_section(req_text, "验收标准") or ""
    return bool(PATTERN_DOC_REF_RE.search(constraint) and _AC_UI_RE.search(acceptance))


def _acceptance_has_ui_pattern_guard_evidence(req_text: str) -> bool:
    acceptance = _extract_markdown_section(req_text, "验收记录") or ""
    return bool(_UI_PATTERN_GUARD_EVIDENCE_RE.search(acceptance))


def _component_spec_structure_gaps(base: str, req_text: str) -> list[str]:
    if _ui_evidence_tier(req_text) != "component":
        return []
    if not _req_needs_ui_pattern_spec(req_text):
        return []
    if _acceptance_has_ui_pattern_guard_evidence(req_text):
        return []
    gaps: list[str] = []
    for rel in _changed_frontend_specs(base):
        spec_path = gc.ROOT / rel
        if not spec_path.is_file():
            continue
        body = spec_path.read_text(encoding="utf-8", errors="ignore")
        if not _SPEC_STRUCTURE_TOKEN_RE.search(body):
            gaps.append(rel)
    return gaps


def _has_ui_runtime_evidence(req_text: str, tier: str | None = None) -> bool:
    """验收记录须含已执行的 UI 运行时证据；档位见 frontmatter ``UI验收证据``。"""
    acceptance = _extract_markdown_section(req_text, "验收记录")
    if not acceptance:
        return False
    resolved = tier or _ui_evidence_tier(req_text)
    return any(_line_has_ui_evidence_for_tier(line, resolved) for line in acceptance.splitlines())


def _changed_frontend_ui_files(changed_files: list[str]) -> list[str]:
    return sorted(
        rel
        for rel in changed_files
        if _FRONTEND_UI_FILE_RE.search(rel) and not _TEST_RE.search(rel)
    )


def _run_hook() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return 0

    edited_endpoints = {
        rel for raw in _extract_paths(payload) if (rel := _to_rel(raw)) and _is_comment_sync_code(rel)
    }
    if not edited_endpoints:
        return 0

    missing_comments = sorted(rel for rel in edited_endpoints if not _file_has_semantic_comment(rel))
    endpoint_issues = _collect_endpoint_comment_issues(sorted(edited_endpoints))
    if missing_comments:
        print(f"{PIPELINE_PREFIX} 核心业务代码已编辑，但文件缺少 xijia 语义注释标签：")
        for rel in missing_comments:
            print(f"  - {rel}")
        print(
            "  → 写代码阶段必须同步注释：新增核心代码需按 xijia-comment-enhancer 输出注释；"
            "修改核心逻辑需同步更新既有注释。不得等到 verify 再补。"
        )
    if endpoint_issues:
        print(f"{PIPELINE_PREFIX} 端点注释块不完整（缺少必填维或 UI 映射维）：")
        for issue in endpoint_issues:
            print(f"  - {issue}")
        print("  → 按 xijia-comment-enhancer 补全 [接口地址]/[功能描述]/[业务逻辑]，"
              f"且 {FRONTEND_DIR}/src/api 已映射的端点须补 [前端路径]/[业务菜单]。")
    if missing_comments or endpoint_issues:
        return 0

    red_reqs = _red_requirements()
    if not red_reqs or _has_any_change_product():
        return 0

    if _already_noticed_today():
        return 0

    print(
        f"{PIPELINE_PREFIX} 正在编辑实现代码，但检测到疑似 🔴/hybrid 需求且 "
        "docs/openspec/changes/ 无 proposal 产物："
    )
    for name in red_reqs:
        print(f"  - inbox/{name}.md")
    print(
        "  → 若为 red 档，应先补 explore→propose→analyze（OpenSpec change 产物）再 apply；"
        "运行 `python .cursor/hooks/pipeline_guard.py --audit` 核对阶段证据。"
    )
    return 0


def _run_check_comment_sync(base: str) -> int:
    impl_files = _changed_impl_files(base)
    if not impl_files:
        print(f"{PIPELINE_PREFIX} 本次未触达核心实现代码，comment-sync 可跳过。")
        return 0

    missing = [rel for rel in impl_files if not _file_has_semantic_comment(rel)]
    endpoint_issues = _collect_endpoint_comment_issues(impl_files)
    if missing:
        print(f"{PIPELINE_PREFIX} 以下实现文件无任何语义注释标签（comment-sync 未完成）：")
        for rel in missing:
            print(f"  - {rel}")
        print(
            "  → 必须调用 xijia-comment-enhancer 按内部层/端点层补注释后再宣告完成；"
            "纯文档/配置/样式/测试改动不应出现在此清单。"
        )
        return 1
    if endpoint_issues:
        print(f"{PIPELINE_PREFIX} 以下端点/Service 方法注释块不完整（comment-sync 未完成）：")
        for issue in endpoint_issues:
            print(f"  - {issue}")
        print(
            "  → Controller 每个 Spring Mapping 须含 [接口地址]/[功能描述]/[业务逻辑]；"
            f"Service 每个 public 业务方法须含 [核心目的]/[业务逻辑]；"
            f"{FRONTEND_DIR}/src/api 已映射端点还须补 [前端路径]（/system/* 另需 [业务菜单]）。"
        )
        return 1

    print(
        f"{PIPELINE_PREFIX} OK：{len(impl_files)} 个变更实现文件均含语义注释标签"
        "（含端点块必填维与 UI 映射维校验）。"
    )
    return 0


@dataclass
class ReleaseResult:
    messages: list[str] = field(default_factory=list)
    blocking: list[str] = field(default_factory=list)
    fatal: bool = False


def _release_comment_test_issues(base: str, impl_files: list[str]) -> ReleaseResult:
    result = ReleaseResult()
    missing = [rel for rel in impl_files if not _file_has_semantic_comment(rel)]
    endpoint_issues = _collect_endpoint_comment_issues(impl_files)
    if missing:
        result.blocking.append("comment-sync 未完成")
        result.messages.append("[release] comment-sync 缺失（核心业务文件无语义注释）：")
        result.messages.extend(f"  - {rel}" for rel in missing)
    elif endpoint_issues:
        result.blocking.append("端点注释块不完整")
        result.messages.append("[release] comment-sync 缺失（端点注释块不完整）：")
        result.messages.extend(f"  - {issue}" for issue in endpoint_issues)
    elif impl_files:
        result.messages.append(f"[release] comment-sync OK：{len(impl_files)} 个核心业务文件均含语义注释标签。")
    else:
        result.messages.append("[release] 本次未触达核心业务代码（comment-sync 不适用）。")
    backend_impl = [rel for rel in impl_files if rel.startswith(f"{BACKEND_DIR}/")]
    if backend_impl and not _changed_test_files(base):
        result.blocking.append("后端业务代码变更但无测试文件变更")
        result.messages.append(f"[release] 后端核心业务代码已改，但未见 {BACKEND_DIR}/tests 下测试变更（TDD 门禁存疑）：")
        result.messages.extend(f"  - {rel}" for rel in backend_impl)
        result.messages.append("  → 按 xijia-backend-test / test-driven-development 补可执行验证，或在验收记录说明豁免理由。")
    return result


def _release_content_issues(base: str, req: Path, text: str, changed_files: list[str]) -> ReleaseResult:
    result = ReleaseResult()
    language = _frontmatter_language_issues(text)
    if language:
        result.blocking.append("frontmatter 值非中文")
        result.messages.append("[release] frontmatter 值语言不合规（分级/类型/状态 须用中文）：")
        result.messages.extend(f"  - {issue}" for issue in language)
    frontend_files = _changed_frontend_ui_files(changed_files)
    ui_tier = _ui_evidence_tier(text)
    if frontend_files and not _parse_frontmatter_ui_evidence(text):
        result.messages.append(
            "[release] 提醒（advisory）：前端 UI 已变更但未声明 frontmatter `UI验收证据`；"
            "默认按组件测试校验。Gate-1 批准时应写入 `UI验收证据: 组件测试|Playwright|集成测试`。"
        )
    if frontend_files and not _has_ui_runtime_evidence(text, ui_tier):
        result.blocking.append("前端 UI 变更但验收记录无运行时证据")
        tier_hint = {
            "component": "组件测试或 frontend/tests/ 路径",
            "playwright": "Playwright / webapp-testing / frontend/e2e",
            "integration": "集成 / parity / with_server / verify-frontend",
        }
        result.messages.append(
            f"[release] 前端 UI 已变更，但验收记录缺少已执行的运行时证据（UI验收证据={ui_tier}）："
        )
        result.messages.extend(f"  - {rel}" for rel in frontend_files)
        result.messages.append(
            f"  → 补{tier_hint.get(ui_tier, '运行时证据')}；lint/build 仅证明语法、类型与构建合法，不能证明 UI 行为满足 AC。"
        )
    reuse_gaps = _reuse_logging_gaps(text, req.stem)
    if reuse_gaps:
        result.blocking.append("经验文档复用未记录读闭环")
        result.messages.append(
            "[release] 经验复用闭环未闭合（Gate-0 约束引用已列路径时禁止 Experience Reuse: none；"
            "否则须在「实现记录与沉淀」写 Experience Reuse: <path> 作为文档真相源）："
        )
        result.messages.extend(f"  - {doc}" for doc in reuse_gaps)
        result.messages.extend((
            f"  → 在 Gate-3 写：Experience Reuse: <doc>（文档真相源）",
            "    并对命中 path 跑 score_docs.py --judge-doc … --judge-session "
            f"{req.stem} --judge-verdict useful|neutral|misleading --judge-reason \"…\"",
            "    或已读未采用：Experience Reuse: <doc>（未采用）+ --judge-verdict neutral|misleading",
            "    仅当约束引用未列出 patterns/pitfalls 时可写 Experience Reuse: none。",
            "    （--use-doc 可选辅记，非必须）",
        ))
    modal_gaps = _modal_drawer_gaps(base, text)
    if modal_gaps:
        result.messages.append("[release] 提醒（弱校验）：约束引用含 UI pattern，但以下 system 列表页未同时含 el-dialog 与 el-drawer：")
        result.messages.extend(f"  - {rel}" for rel in modal_gaps)
        result.messages.append("  → 对照 INV-UI-01：新增用 Modal（el-dialog）、编辑/详情用 Drawer（el-drawer.admin-drawer），不得共用容器。")
    spec_gaps = _component_spec_structure_gaps(base, text)
    if spec_gaps:
        result.blocking.append("前端组件测缺少 Table-First 结构断言")
        result.messages.append(
            "[release] 约束引用含 UI pattern 且 Gate-1 有 AC-UI-*，但以下 spec 缺少结构 token"
            "（menu-panel / role-panel-foot__pager / role-search-field / menu-drawer.is-on / *-pagination）："
        )
        result.messages.extend(f"  - {rel}" for rel in spec_gaps)
        result.messages.append(
            "  → 补 xijia-frontend-test 结构断言，或在验收记录写明 "
            "`python .cursor/hooks/pipeline_guard.py --check-ui-pattern` exit 0。"
        )
    return result


def _release_gate0_issues(text: str, status: str | None, gate: dict[str, str] | None) -> ReleaseResult:
    result = ReleaseResult()
    gate_ok, _ = _gate0_is_complete(gate, status)
    if not gate:
        result.blocking.append("Gate-0 记录缺失")
        result.messages.append("[release] 审批留痕缺失：未找到 Gate-0 记录。")
        return result
    allow_partial = _gate0_is_partial(gate) and status == "shipped"
    if not gate_ok:
        result.blocking.append("Gate-0 状态未通过")
        result.messages.append(f"[release] Gate-0 状态不合规：{gate['raw']}")
    elif allow_partial:
        deferred_ids = _extract_deferred_ids(text)
        if not deferred_ids:
            result.blocking.append("Gate-0 部分通过但缺少 Deferred 标识")
            result.messages.append(
                "[release] Gate-0=部分通过 且 状态=已交付，但未在需求文档找到 DEF-xxx 标识。"
            )
        else:
            missing = _missing_deferred_in_backlog(deferred_ids)
            if missing:
                result.blocking.append("Deferred 未入 backlog")
                result.messages.append(
                    "[release] Gate-0=部分通过 且 状态=已交付，但以下 Deferred 未写入 backlog："
                )
                result.messages.extend(f"  - {item}" for item in missing)
            else:
                result.messages.append(
                    "[release] Gate-0=部分通过（已交付）且 Deferred 已入 backlog，按已交付留痕通过。"
                )
    # 非待*态（部分通过/已通过/已驳回/已批准/已验收等）强制审批人+日期
    if _gate_requires_approver_audit(gate):
        if _is_invalid_approver(gate["approver"]) or _is_placeholder(gate["date"]):
            result.blocking.append("Gate-0 审批人/日期不合规")
            result.messages.append(
                f"[release] Gate-0 审批人须为 git config user.name（可选附 email），禁止泛称「用户」：{gate['raw']}"
            )
    return result


def _release_gate12_issues(records: dict[str, dict[str, str]]) -> ReleaseResult:
    result = ReleaseResult()
    gate1 = records.get("Gate-1")
    gate1_ok, _ = _gate1_is_approved(gate1)
    if not gate1:
        result.blocking.append("Gate-1 记录缺失")
        result.messages.append("[release] 审批留痕缺失：未找到 Gate-1 记录。")
    else:
        if not gate1_ok:
            result.blocking.append("Gate-1 状态未批准")
            result.messages.append(f"[release] Gate-1 状态不合规：{gate1['raw']}")
        # 非待*态强制审批人+日期；待批准可不写
        if _gate_requires_approver_audit(gate1):
            if _is_invalid_approver(gate1["approver"]) or _is_placeholder(gate1["date"]):
                result.blocking.append("Gate-1 审批人/日期不合规")
                result.messages.append(
                    f"[release] Gate-1 审批人须为 git config user.name（可选附 email），禁止泛称「用户」：{gate1['raw']}"
                )
    gate2 = records.get("Gate-2")
    gate2_ok, _ = _gate2_is_accepted(gate2)
    if gate2 and gate2_ok:
        missing_approver = (
            not gate2.get("approver")
            or _is_placeholder(gate2["approver"])
            or _is_placeholder(gate2.get("date", ""))
        )
        if missing_approver:
            result.messages.append(
                f"[release] 提醒（advisory）：Gate-2 已验收但缺审批人/日期，建议补全："
                f"Gate-2 验收通过，审批人 <git config user.name>，YYYY-MM-DD — {gate2['raw']}"
            )
        elif _is_invalid_approver(gate2["approver"]):
            result.blocking.append("Gate-2 审批人/日期不合规")
            result.messages.append(
                f"[release] Gate-2 审批人须为 git config user.name（可选附 email），禁止泛称「用户」：{gate2['raw']}"
            )
    elif gate2:
        result.messages.append("[release] 提醒：Gate-2 尚未签字，状态迁移/归档前必须用户人工验收签字。")
    else:
        result.messages.append("[release] 提醒：未找到 Gate-2 行，归档前请在需求文档补齐验收签字记录。")
    return result


def _release_ac_premature_full_issues(text: str, gate2_ok: bool) -> ReleaseResult:
    """Advisory when 验收标准 AC marked [x] before Gate-2 sign-off."""
    from guardlib.closeout import gate1_ac_premature_full_checks

    result = ReleaseResult()
    premature = gate1_ac_premature_full_checks(text, gate2_accepted=gate2_ok)
    if premature:
        joined = "、".join(premature)
        result.messages.append(
            f"[release] 提醒：Gate-2 未签字但验收标准已标 [x]：{joined}。"
            " verify 后应标 [~]（程序已检），Gate-2 签字后再改 [x]。"
        )
    return result


def _merge_release(target: ReleaseResult, source: ReleaseResult) -> None:
    target.messages.extend(source.messages)
    target.blocking.extend(source.blocking)
    target.fatal = target.fatal or source.fatal


def _release_requirement_issues(
    base: str, req_path: str, changed_files: list[str],
) -> ReleaseResult:
    result = ReleaseResult()
    if not req_path:
        return result
    req = Path(req_path)
    req = req.resolve() if req.is_absolute() else (gc.ROOT / req).resolve()
    if not req.is_file():
        result.blocking.append("需求文档不存在")
        result.messages.append(f"[release] 审批留痕校验失败：需求文档不存在 {req_path}")
        return result
    try:
        text = _read_utf8_text(req)
    except UnicodeDecodeError as exc:
        result.messages.append(f"[release] 需求文档不是有效 UTF-8：{req_path}（字节偏移 {exc.start}）")
        result.fatal = True
        return result
    _merge_release(result, _release_content_issues(base, req, text, changed_files))
    records = _parse_gate_records(text)
    _merge_release(result, _release_gate0_issues(text, _parse_frontmatter_status(text), records.get("Gate-0")))
    _merge_release(result, _release_gate12_issues(records))
    gate2_ok, _ = _gate2_is_accepted(records.get("Gate-2"))
    gate1_ok, _ = _gate1_is_approved(records.get("Gate-1"))
    _merge_release(result, _release_ac_premature_full_issues(text, gate2_ok))
    if gate1_ok and not gate2_ok:
        from guardlib.closeout import _business_hybrid_needs_distill

        if _business_hybrid_needs_distill(text):
            req_rel = req.relative_to(gc.ROOT).as_posix() if req.is_relative_to(gc.ROOT) else req.as_posix()
            result.messages.append(
                "[release] Gate-2 签字后将同轮 Gate-3；可先预览沉淀触发表："
                f"python .cursor/hooks/pipeline_guard.py --gate3-trigger-report --req {req_rel}"
            )
    archive_issues = _process_docs_archive_issues(req, text)
    if archive_issues:
        result.blocking.append("process-docs-archived 未通过")
        result.messages.append("[release] process-docs-archived 未通过：")
        result.messages.extend(f"  - {issue}" for issue in archive_issues)
    return result


def _release_repository_issues(
    changed_files: list[str],
    impl_files: list[str],
    req_text: str = "",
) -> ReleaseResult:
    result = ReleaseResult()
    if _needs_adr(changed_files) and not any(
        rel.startswith("docs/decisions/") and rel.endswith(".md") for rel in changed_files
    ):
        result.blocking.append("命中 ADR 触发条件但未新增/更新 docs/decisions/*.md")
        result.messages.append("[release] 命中 ADR 触发条件（依赖/迁移/权限安全），但未检测到 docs/decisions/*.md 变更。")
    has_domain = any(rel.startswith("docs/domain/") for rel in changed_files)
    has_cap = "docs/capability-map.md" in changed_files
    if impl_files and not has_domain:
        from guardlib.closeout import _needs_domain_closeout_marker

        if req_text and _needs_domain_closeout_marker(req_text):
            result.messages.extend((
                "[release] 提醒：业务/混合（DDD A|B）有实现变更，但未检测到 docs/domain/ 变更。",
                "  → Gate-3 须更新 context-map；若领域影响含 INV-xxx，还须直写 docs/domain/<bc>/domain-model.md"
                "（首缺建夹；capability-map/ADR 不能代替 Domain INV）。",
            ))
        elif not has_cap:
            result.messages.extend((
                "[release] 提醒：核心业务代码有变更，但未检测到 docs/domain/ 或 docs/capability-map.md 变更。",
                "  → 请在 xijia-sync-knowledge 阶段确认是否需要更新领域知识文档。",
            ))
    return result


def _release_issues(
    base: str, req_path: str, changed_files: list[str], impl_files: list[str],
) -> ReleaseResult:
    result = _release_comment_test_issues(base, impl_files)
    _merge_release(result, _release_requirement_issues(base, req_path, changed_files))
    if result.fatal:
        return result
    req_text = ""
    if req_path:
        req = Path(req_path)
        req = req.resolve() if req.is_absolute() else (gc.ROOT / req).resolve()
        if req.is_file():
            try:
                req_text = _read_utf8_text(req)
            except UnicodeDecodeError:
                req_text = ""
    _merge_release(result, _release_repository_issues(changed_files, impl_files, req_text))
    result.messages.append(
        "[release] 人工门禁（脚本无法客观判定，须在 verify 输出与 Gate-2 留痕）：\n"
        "  - requesting-code-review: done|skipped+reason\n"
        "  - xijia-quality-judge: pass|revise（revise 不得宣告完成）\n"
        "  - Gate-2: 验收人须为 git config user.name（可选附 email）；禁止泛称「用户」；签字后方可状态迁移/归档\n"
        "  - Deferred 项是否已写入 docs/requirements/backlog.md"
    )
    if result.blocking:
        result.messages.append(f"[release] BLOCKED：{', '.join(result.blocking)} —— 不得进入 Gate-2/归档。")
    else:
        stack_issues = _stack_drift_issues()
        if stack_issues:
            result.messages.append("[release] stack-drift 未通过：")
            result.messages.extend(f"  - {issue}" for issue in stack_issues)
            result.messages.append("[release] BLOCKED：栈漂移须在进入 Gate-2 前修复（README/architecture/AGENTS/openspec）。")
            result.blocking.append("stack-drift 未通过")
            return result
        else:
            result.messages.append("[release] 客观项通过；人工门禁请按上方清单逐条确认后再签字。")
    if req_path:
        result.messages.append(f"[release] hint: 当前门禁见 --resolve-gate --req {req_path}")
    return result


def _run_check_release(base: str, req_path: str) -> int:
    """Gate-2 aggregate backstop: comment-sync + test presence + manual-gate reminder."""
    result = _release_issues(
        base,
        req_path,
        _changed_all_files(base),
        _changed_impl_files(base),
    )
    for message in result.messages:
        print(message)
    return 1 if result.fatal or result.blocking else 0


def _run_check_gate3_preflight(req_path: str) -> int:
    """Gate-3 Move preflight: inbox exists, Gate-2 accepted; warn on rebuild smell."""
    if not req_path:
        print("[gate3-preflight] 必须提供 --req <inbox-requirement-file>")
        return 1

    req = Path(req_path)
    req = req.resolve() if req.is_absolute() else (gc.ROOT / req).resolve()
    text: str | None = None
    if req.is_file():
        try:
            text = _read_utf8_text(req)
        except UnicodeDecodeError as exc:
            print(f"[gate3-preflight] 需求文档不是有效 UTF-8：{req_path}（字节偏移 {exc.start}）")
            return 1

    errors, warnings = _gate3_preflight_issues(req, text)
    for warning in warnings:
        print(f"[gate3-preflight] WARN: {warning}")
    if errors:
        print("[gate3-preflight] BLOCKED：")
        for issue in errors:
            print(f"  - {issue}")
        print("  → 禁止 rebuild shipped；先定位 inbox 或完成 Gate-2 后再归档。")
        return 1

    print("[gate3-preflight] OK：可继续 inbox 改状态/写总结，或执行 Move（archive-requirement.ps1）。")
    return 0


def _run_gate3_trigger_report(req_path: str, base: str, as_json: bool) -> int:
    """Print Gate-3 living-doc trigger report from requirement + git diff."""
    if not req_path:
        print("[gate3-trigger] 必须提供 --req <requirement-file>")
        return 1

    req = Path(req_path)
    req = req.resolve() if req.is_absolute() else (gc.ROOT / req).resolve()
    if not req.is_file():
        print(f"[gate3-trigger] 需求文档不存在：{req_path}")
        return 2

    try:
        text = _read_utf8_text(req)
    except UnicodeDecodeError as exc:
        print(f"[gate3-trigger] 需求文档不是有效 UTF-8：{req_path}（字节偏移 {exc.start}）")
        return 1

    try:
        changed = _changed_all_files(base)
    except GitCommandError:
        changed = []

    from guardlib.gate3_triggers import (
        build_gate3_trigger_report,
        format_gate3_trigger_json,
        format_gate3_trigger_report,
    )

    report = build_gate3_trigger_report(text, changed)
    if as_json:
        print(format_gate3_trigger_json(report))
    else:
        print(format_gate3_trigger_report(report))
    return 0


def _run_check_closeout(req_path: str) -> int:
    """Gate-3 closeout: verify process documents left active paths."""
    if not req_path:
        print("[closeout] 必须提供 --req <requirement-file>")
        return 1

    req = Path(req_path)
    req = req.resolve() if req.is_absolute() else (gc.ROOT / req).resolve()
    if not req.is_file():
        print(f"[closeout] 需求文档不存在 {req_path}")
        return 1

    try:
        req_text = _read_utf8_text(req)
    except UnicodeDecodeError as exc:
        print(f"[closeout] 需求文档不是有效 UTF-8：{req_path}（字节偏移 {exc.start}）")
        return 1
    req_status = _parse_frontmatter_status(req_text)
    issues = _process_docs_archive_issues(req, req_text)

    if req_status not in ("shipped", "archived"):
        print(
            "[closeout] 提醒：frontmatter 状态尚未标记为 已交付/已归档；"
            "process-docs-archived 校验已跳过。"
        )
        print("  → Gate-3 收尾须更新状态并迁移 inbox -> shipped。")
        return 0

    if issues:
        print("[closeout] process-docs-archived 未通过：")
        for issue in issues:
            print(f"  - {issue}")
        print("[closeout] BLOCKED：不得开启下一需求。")
        return 1

    try:
        req_rel = req.relative_to(gc.ROOT).as_posix()
    except ValueError:
        req_rel = str(req)

    cap_issues = _capability_index_closeout_issues(req_text, req_rel)
    if cap_issues:
        print("[closeout] capability-index 未通过：")
        for issue in cap_issues:
            print(f"  - {issue}")
        print("[closeout] BLOCKED：不得开启下一需求。")
        return 1

    distill_issues = _experience_distill_closeout_issues(req_text)
    if distill_issues:
        print("[closeout] experience-distill 未通过：")
        for issue in distill_issues:
            print(f"  - {issue}")
        print(
            "[closeout] BLOCKED：业务/混合需求须沉淀 Patterns/Pitfalls/Living Docs/Flow/Domain "
            "或显式 no-op。"
        )
        return 1

    try:
        changed_for_noop = _changed_all_files("HEAD")
    except GitCommandError:
        changed_for_noop = []

    domain_issues = _domain_closeout_issues(req_text, req_rel, changed_for_noop)
    if domain_issues:
        print("[closeout] domain 未通过：")
        for issue in domain_issues:
            print(f"  - {issue}")
        print("[closeout] BLOCKED：业务/混合 A|B 须 Domain 标记并触及 docs/domain/。")
        return 1

    noop_issues = _false_noop_closeout_issues(req_text, req_rel, changed_for_noop)
    if noop_issues:
        print("[closeout] false-noop 未通过：")
        for issue in noop_issues:
            print(f"  - {issue}")
        print("[closeout] BLOCKED：沉淀标记与活文档变更/引用矛盾，不得开启下一需求。")
        return 1

    reuse_gaps = _reuse_logging_gaps(req_text, req.stem)
    if reuse_gaps:
        print("[closeout] experience-reuse 未通过：")
        print(
            "  - Gate-0 约束引用已列出经验文档，但 Experience Reuse 未声明对应路径（禁止 none 逃逸）："
        )
        for doc in reuse_gaps:
            print(f"  - {doc}")
        print("[closeout] BLOCKED：须在「实现记录与沉淀」写 Experience Reuse: <path> 后再开启下一需求。")
        return 1

    link_issues = _living_doc_link_issues()
    if link_issues:
        print("[closeout] doc-links 未通过：")
        for issue in link_issues:
            print(f"  - {issue}")
        print("[closeout] BLOCKED：活文档索引含断链，须修复后再开启下一需求。")
        return 1

    stack_issues = _stack_drift_issues()
    if stack_issues:
        print("[closeout] stack-drift 未通过：")
        for issue in stack_issues:
            print(f"  - {issue}")
        print("[closeout] BLOCKED：活文档栈漂移，须同步 README/architecture 后再开启下一需求。")
        return 1

    print("[closeout] process-docs-archived OK")
    return 0


def _run_check_req_ids() -> int:
    """Lightweight duplicate-prefix backstop for timestamp requirement ids (能力/编号方案 §7).

    Scans inbox ∪ shipped for duplicate 14-digit timestamp prefixes. Filename validity is
    enforced by the per-requirement intake check; this mode has no counter or continuity check.
    """
    ts_prefixes: dict[str, list[str]] = {}
    for base in (INBOX_DIR, SHIPPED_DIR):
        if not base.is_dir():
            continue
        for md in sorted(base.glob("*.md")):
            stem = md.stem
            ts_match = re.match(r"^(\d{14})-", stem)
            if ts_match:
                ts_prefixes.setdefault(ts_match.group(1), []).append(md.name)

    duplicates = {ts: names for ts, names in ts_prefixes.items() if len(names) > 1}
    if duplicates:
        print("[req-ids] 检测到重复的 14 位时间戳前缀（编号撞车，须人工改名解决）：")
        for ts, names in sorted(duplicates.items()):
            print(f"  - {ts}: {', '.join(names)}")
        print("  → 后创建者秒数 +1（或加 -2 后缀）；ID 一经创建不可变，不 renumber 历史。")
        return 1

    print(f"[req-ids] OK：{len(ts_prefixes)} 个时间戳编号无重复前缀。")
    return 0


def _run_audit() -> int:
    print("== pipeline-guard 阶段证据自检 ==")

    if INBOX_DIR.is_dir():
        for md in sorted(INBOX_DIR.glob("*.md")):
            text = md.read_text(encoding="utf-8", errors="ignore")
            fm_tier = _parse_frontmatter_tier(text) or "(frontmatter 缺失)"
            fm_type = _parse_frontmatter_type(text) or "(未填)"
            red_flag = "🔴" if _is_red_requirement_text(text) else "—"
            print(f"[inbox] {md.stem}: tier={fm_tier} type={fm_type} red={red_flag}")
    else:
        print("[inbox] docs/requirements/inbox/ 不存在")

    red_reqs = _red_requirements()
    print(f"[inbox] red-tier 需求: {', '.join(red_reqs) or '(无)'}")

    if CHANGES_DIR.is_dir():
        change_dirs = _active_change_dirs()
    else:
        change_dirs = []
    if not change_dirs:
        print("[openspec] docs/openspec/changes/ 无任何 change 目录")
    for change in change_dirs:
        products = [
            name
            for name in ("proposal.md", "design.md", "tasks.md")
            if (change / name).is_file()
        ]
        has_specs = (change / "specs").is_dir() and any((change / "specs").rglob("*.md"))
        has_domain = (change / "domain").is_dir() and any((change / "domain").glob("*.md"))
        tasks_file = change / "tasks.md"
        if tasks_file.is_file():
            text = tasks_file.read_text(encoding="utf-8", errors="ignore")
            done = len(re.findall(r"^\s*-\s*\[x\]", text, re.MULTILINE | re.IGNORECASE))
            total = len(re.findall(r"^\s*-\s*\[[ xX]\]", text, re.MULTILINE))
            tasks_progress = f"{done}/{total}"
        else:
            tasks_progress = "n/a"
        extras = []
        if has_specs:
            extras.append("specs")
        if has_domain:
            extras.append("domain")
        print(
            f"[openspec] {change.name}: products={products + extras or '(空)'} "
            f"tasks={tasks_progress}"
        )

    impl_files = _changed_impl_files("HEAD")
    if impl_files:
        missing = [rel for rel in impl_files if not _file_has_semantic_comment(rel)]
        print(
            f"[comment-sync] 变更实现文件 {len(impl_files)} 个，"
            f"疑似缺语义注释 {len(missing)} 个"
            + (f"：{', '.join(missing)}" if missing else "（文件级启发式）")
        )
    else:
        print("[comment-sync] 本次未触达核心实现代码")

    print("[hint] verify 三件套（comment-enhancer/code-review/xijia-quality-judge）若无产出记录，按未完成处理。")
    return 0


def _run_check_release_readiness() -> int:
    hard: list[str] = []
    warn: list[str] = []

    checklist = gc.ROOT / "docs" / "process" / "release-checklist.md"
    if not checklist.is_file():
        hard.append("缺少 docs/process/release-checklist.md")
    lifecycle = gc.ROOT / "docs" / "process" / "project-lifecycle.md"
    if not lifecycle.is_file():
        warn.append("缺少 docs/process/project-lifecycle.md（建议 init 生成）")

    ok, msg = _agents_command_section_ready()
    if not ok:
        hard.append(msg)
    else:
        print(f"[release-readiness] AGENTS: {msg}")

    ci_ok, ci_msg = _ci_or_local_declared()
    if not ci_ok:
        hard.append(ci_msg)
    else:
        print(f"[release-readiness] CI: {ci_msg}")

    stack_issues = _stack_drift_issues()
    if stack_issues:
        hard.append(f"stack-drift 未通过：{stack_issues[0]}" + (
            f"（共 {len(stack_issues)} 项）" if len(stack_issues) > 1 else ""
        ))
    else:
        print("[release-readiness] stack-drift: OK")

    active = _inbox_active_requirements()
    if active:
        warn.append(f"inbox 仍有未完成需求 {len(active)} 个：{', '.join(active[:5])}" + (
            " …" if len(active) > 5 else ""
        ))

    try:
        branch = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=gc.ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=True,
        ).stdout
        if branch and branch.strip() != "dev":
            warn.append(f"当前分支为 {branch.strip()!r}，发布合并通常应在 dev 上完成")
    except subprocess.CalledProcessError:
        warn.append("无法检测 git 分支")

    try:
        status = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=gc.ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=True,
        ).stdout
        if status and status.strip():
            warn.append("工作区有未提交改动")
    except subprocess.CalledProcessError:
        warn.append("无法检测 git status")

    for w in warn:
        print(f"[release-readiness] WARN: {w}")
    if hard:
        print("[release-readiness] FAIL（Release Gate 前须修复）：")
        for item in hard:
            print(f"  - {item}")
        print("  → 运行 /xijia:release 或见 47-release-lifecycle.mdc")
        return 1

    print("[release-readiness] OK：客观项通过（警告项请人工确认后提请 Release Gate）")
    return 0
