#!/usr/bin/env python3
"""UI pattern structure guard for Table-First *Panel.vue diffs."""

from __future__ import annotations

import re

from guardlib import PIPELINE_PREFIX, paths
from guardlib.gitio import GitCommandError, changed_files
from guardlib.pattern_guard_spec import GUARD_DOC_REF, load_table_first_guard_spec, table_first_structure_issues

PANEL_FILE_RE = re.compile(rf"^{re.escape(paths.FRONTEND_DIR)}/src/components/\w+Panel\.vue$")
UNDEFINED_FOOT_CLASS_RE = re.compile(r"role-table-foot\b")
PAGINATION_SIGNAL_RE = re.compile(
    r"totalCount|pageSize|currentPage|pagination|pager|@page-change|role-panel-foot",
    re.I,
)
PAGER_DOM_RE = re.compile(
    r"role-panel-foot__pager|data-testid=[\"'][^\"']*pagination",
    re.I,
)
DRAWER_CLASS_RE = re.compile(r"menu-drawer\b")
IS_ON_BINDING_RE = re.compile(r"['\"]is-on['\"]|is-on:")


def ui_pattern_issues(base: str) -> list[str]:
    issues: list[str] = []
    try:
        guard_spec = load_table_first_guard_spec()
    except FileNotFoundError as exc:
        return [str(exc)]

    for rel in changed_files(base):
        if not PANEL_FILE_RE.match(rel):
            continue
        path = paths.ROOT / rel
        if not path.is_file():
            continue
        body = path.read_text(encoding="utf-8", errors="ignore")

        issues.extend(table_first_structure_issues(rel, body, guard_spec))

        if UNDEFINED_FOOT_CLASS_RE.search(body):
            issues.append(
                f"{rel}: 使用了未在 list.css 定义的 class `role-table-foot`（应使用 `role-panel-foot`）"
            )
        if PAGINATION_SIGNAL_RE.search(body) and "role-panel-foot" not in body:
            issues.append(f"{rel}: 含分页逻辑但缺少 `.role-panel-foot` 分页脚结构")
        if PAGINATION_SIGNAL_RE.search(body) and not PAGER_DOM_RE.search(body):
            issues.append(
                f"{rel}: 含分页逻辑但缺少 `.role-panel-foot__pager` 或 `data-testid=\"*-pagination\"`"
            )
        if DRAWER_CLASS_RE.search(body):
            if not IS_ON_BINDING_RE.search(body):
                issues.append(f"{rel}: Drawer 缺少 `menu-drawer.is-on` 可见性绑定")
            if "menu-overlay" not in body:
                issues.append(f"{rel}: Drawer 缺少 `menu-overlay` 遮罩层")
    return issues


def run_check_ui_pattern(base: str) -> int:
    try:
        issues = ui_pattern_issues(base)
    except GitCommandError as exc:
        print(f"{PIPELINE_PREFIX} --check-ui-pattern: {exc}")
        return 2
    if not issues:
        print(f"{PIPELINE_PREFIX} --check-ui-pattern OK：无 *Panel.vue 结构违规。")
        return 0
    print(f"{PIPELINE_PREFIX} --check-ui-pattern 未通过：")
    for issue in issues:
        print(f"  - {issue}")
    print(
        f"  → 对照 {GUARD_DOC_REF} 与 Gate-1 复用映射参照 Panel，"
        "修正 menu-panel / 筛选栏 / foot / drawer DOM。"
    )
    return 1
