#!/usr/bin/env python3
"""Lightweight policy/flow semantic drift check for xijia-base init self-check.

Complements drift_guard_scan.py (stack terminology). Verifies key lifecycle
wiring strings exist in rules/skills/commands — not a full rg replacement.
"""

from __future__ import annotations

import re

from guardlib.paths import ROOT

# (label, path relative to ROOT, list of substrings — all must appear)
CHECKS: list[tuple[str, str, list[str]]] = [
    (
        "ops-pipeline hub",
        ".cursor/skills/xijia-ops-pipeline/SKILL.md",
        ["项目阶段路由", "xijia:release", "xijia-ops-pipeline"],
    ),
    (
        "ops-pipeline closeout ref",
        ".cursor/skills/xijia-ops-pipeline/references/closeout-steps.md",
        ["check-closeout", "check-release", "check-gate3-preflight", "gate3-trigger-report", "archive-requirement"],
    ),
    (
        "release rule",
        ".cursor/rules/47-release-lifecycle.mdc",
        ["Release Gate", "check-release-readiness"],
    ),
    (
        "release command",
        ".cursor/commands/xijia-release.md",
        ["check-release-readiness"],
    ),
    (
        "release skill",
        ".cursor/skills/xijia-release/SKILL.md",
        ["check-release-readiness", "Release Gate"],
    ),
    (
        "xijia-feature-pipeline alias",
        ".cursor/skills/xijia-feature-pipeline/SKILL.md",
        ["xijia-ops-pipeline"],
    ),
    (
        "xijia-start CTA",
        ".cursor/commands/xijia-start.md",
        ["--format cta", "**本步指令：**", "**请你：**", "请指定需求文档"],
    ),
    (
        "session-recovery CTA",
        ".cursor/skills/xijia-ops-pipeline/references/session-recovery.md",
        ["--format cta", "**本步指令：**", "**请你：**", "**然后：**", "Gate-0(需求澄清)", "字段换行"],
    ),
    (
        "xijia-start closeout",
        ".cursor/commands/xijia-start.md",
        ["check-closeout", "xijia:release"],
    ),
    (
        "defect routing",
        ".cursor/skills/xijia-ops-pipeline/SKILL.md",
        ["缺陷", "xijia-defect-to-requirement", "xijia:defect"],
    ),
    (
        "defect command",
        ".cursor/commands/xijia-defect.md",
        ["xijia-defect-to-requirement"],
    ),
    (
        "prd prototype early-diff",
        ".cursor/skills/xijia-prd-to-requirement/references/gate0-checklist.md",
        ["原型现状（相对 PRD）", "Step 1.2", "以PRD为准"],
    ),
    (
        "init docs-render",
        ".cursor/skills/xijia-project-init/SKILL.md",
        ["docs-render", "code-shell", "seed-bootstrap-reqs"],
    ),
    (
        "sync-knowledge capability",
        ".cursor/skills/xijia-sync-knowledge/references/gate3-archive.md",
        ["extract_capability_index", "18b", "Capability Index", "check-gate3-preflight", "gate3-trigger-report", "archive-requirement"],
    ),
    (
        "sync-knowledge hub pointer",
        ".cursor/skills/xijia-sync-knowledge/SKILL.md",
        ["gate3-archive.md", "Capability Index", "domain-merge.md"],
    ),
    (
        "prd step 1.7",
        ".cursor/skills/xijia-prd-to-requirement/SKILL.md",
        ["Step 1.7", "capability-map"],
    ),
    (
        "prd ambiguity gate",
        ".cursor/skills/xijia-prd-to-requirement/SKILL.md",
        ["原始诉求逐字", "静态 HTML/图片", "人工文字确认"],
    ),
    (
        "verify UI runtime evidence",
        ".cursor/skills/xijia-ops-pipeline/references/verify-closeout.md",
        ["xijia-frontend-test", "lint/build", "运行时证据"],
    ),
    (
        "visible state machine tiering",
        ".cursor/skills/xijia-ops-pipeline/references/tier-routing.md",
        ["用户可见状态机", "最低为 **yellow**", "brainstorming"],
    ),
    (
        "init rule D+",
        ".cursor/rules/05-project-init.mdc",
        ["docs-render", "seed-bootstrap-reqs", "后端工程初始化", "supplement-only"],
    ),
    (
        "requirement canonical contract",
        ".cursor/rules/45-requirement-intake.mdc",
        [
            "H1 需求名 + H1 Gate-0..3 + H2 具体环节",
            "只从 YAML properties 读取",
            "仅接受 14 位时间戳前缀",
            "Gate-0 → Gate-1 → Gate-2 → Gate-3",
            "H2 必须位于对应 Gate 父层",
            ".cursor/templates/requirements/requirements-template.md",
        ],
    ),
    (
        "public templates SSOT",
        ".cursor/templates/README.md",
        [
            "requirements/requirements-template.md",
            "禁止",
            "docs/requirements/",
        ],
    ),
    (
        "adopt rule",
        ".cursor/rules/05b-project-adopt.mdc",
        ["/xijia:adopt", "xijia-project-adopt", "check-adopt-readiness"],
    ),
    (
        "adopt skill",
        ".cursor/skills/xijia-project-adopt/SKILL.md",
        ["preflight", "discover", "check-adopt-readiness", "workspace-manifest.yaml"],
    ),
    (
        "adopt command",
        ".cursor/commands/xijia-adopt.md",
        ["xijia-project-adopt", "check-adopt-readiness"],
    ),
    (
        "init command D+",
        ".cursor/commands/xijia-init.md",
        ["docs-render", "seed-bootstrap-reqs", "code-shell"],
    ),
    (
        "agents tmpl runtime panel",
        ".cursor/skills/xijia-project-init/templates/AGENTS.md.tmpl",
        [
            "agents.md",
            "docs/llms.txt",
            "Build and test commands",
            "Testing instructions",
            "Xijia workflow",
            "/xijia:start",
            "/xijia:overview",
            "Backend root",
            "Frontend root",
            "UI reference",
            "--check-release --req",
        ],
    ),
    (
        "prd command",
        ".cursor/commands/xijia-prd.md",
        ["xijia-prd-to-requirement"],
    ),
    (
        "sync-knowledge all tiers",
        ".cursor/commands/xijia-sync-knowledge.md",
        ["All tiers", "xijia-sync-knowledge"],
    ),
    (
        "git branching",
        ".cursor/rules/46-git-branching.mdc",
        ["master", "release/", "worktree"],
    ),
    (
        "opsx explore thin",
        ".cursor/commands/opsx-explore.md",
        ["openspec-explore"],
    ),
    (
        "opsx propose thin",
        ".cursor/commands/opsx-propose.md",
        ["openspec-propose"],
    ),
    (
        "opsx sync thin",
        ".cursor/commands/opsx-sync.md",
        ["openspec-sync-specs"],
    ),
    (
        "opsx archive thin",
        ".cursor/commands/opsx-archive.md",
        ["openspec-archive-change"],
    ),
    (
        "opsx apply superpowers",
        ".cursor/commands/opsx-apply.md",
        ["openspec-superpowers-apply"],
    ),
]

# (label, path relative to ROOT, substrings that must NOT appear)
NEGATIVE_CHECKS: list[tuple[str, str, list[str]]] = [
    (
        "agents tmpl no legacy routing",
        ".cursor/skills/xijia-project-init/templates/AGENTS.md.tmpl",
        ["## 0. 第一步读什么", "## 1.1", "§4 本地命令", "Agent 操作面板"],
    ),
    (
        "approver pitfall tmpl yaml only",
        ".cursor/skills/xijia-project-init/templates/docs/pitfalls/gate-approver-git-identity.md.tmpl",
        ["正文 Gate 表"],
    ),
]

# (label, path relative to ROOT, regex patterns that must NOT match)
REGEX_NEGATIVE_CHECKS: list[tuple[str, str, list[str]]] = [
    (
        "project lifecycle tmpl no numbered seeds",
        ".cursor/skills/xijia-project-init/templates/docs/process/project-lifecycle.md.tmpl",
        [
            r"(?:requirements/(?:inbox|shipped)/|/xijia:start[ \t]+"
            r"(?:docs/requirements/(?:inbox|shipped)/)?)00[123]-",
        ],
    ),
]

_LEGACY_DOCS_TEMPLATE = re.compile(
    r"docs/requirements/(?:requirements|technical|defect)-template\.md"
)
_LEGACY_REFINEMENT_GATE = re.compile(
    r"xijia-requirement-refinement/references/(?:gate0-intake|gate1-plan-template|section-fragments)\.md"
)
_LEGACY_PRD_GATE1 = re.compile(
    r"xijia-prd-to-requirement/references/gate1-by-tier\.md"
)
_LEGACY_SCAN_SUFFIXES = (".md", ".mdc", ".py")
_LEGACY_SCAN_EXCLUDE = frozenset(
    {
        ".cursor/skills/xijia-project-init/scripts/render_init_templates.py",
        ".cursor/hooks/policy_flow_drift_check.py",
        ".cursor/hooks/tests/test_pipeline_guard_checks.py",
    }
)


def _legacy_template_path_issues() -> list[str]:
    failures: list[str] = []
    scan_roots = [
        ROOT / ".cursor" / "rules",
        ROOT / ".cursor" / "skills",
        ROOT / ".cursor" / "commands",
        ROOT / ".cursor" / "hooks",
    ]
    for root in scan_roots:
        if not root.is_dir():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            rel = path.relative_to(ROOT).as_posix()
            if rel in _LEGACY_SCAN_EXCLUDE:
                continue
            if path.suffix not in _LEGACY_SCAN_SUFFIXES:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for pattern, label in (
                (_LEGACY_DOCS_TEMPLATE, "docs/requirements/*-template.md"),
                (_LEGACY_REFINEMENT_GATE, "refinement/references gate templates"),
                (_LEGACY_PRD_GATE1, "prd/references/gate1-by-tier.md"),
            ):
                if pattern.search(text):
                    failures.append(f"legacy template ref ({label}): {rel}")
                    break
    return failures


ENTRYPOINTS = [
    ".cursor/commands/xijia-init.md",
    ".cursor/commands/xijia-adopt.md",
    ".cursor/commands/xijia-start.md",
    ".cursor/commands/xijia-status.md",
    ".cursor/commands/xijia-stop.md",
    ".cursor/commands/xijia-sync-knowledge.md",
    ".cursor/commands/xijia-release.md",
    ".cursor/commands/xijia-defect.md",
    ".cursor/commands/xijia-prd.md",
    ".cursor/commands/xijia-overview.md",
    ".cursor/commands/xijia-backfill-index.md",
    ".cursor/commands/xijia-finish-branch.md",
    ".cursor/commands/opsx-explore.md",
    ".cursor/commands/opsx-propose.md",
    ".cursor/commands/opsx-analyze.md",
    ".cursor/commands/opsx-apply.md",
    ".cursor/commands/opsx-sync.md",
    ".cursor/commands/opsx-archive.md",
]


def main() -> int:
    failures: list[str] = []
    for label, rel, needles in CHECKS:
        path = ROOT / rel
        if not path.is_file():
            failures.append(f"{label}: missing file {rel}")
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for needle in needles:
            if needle not in text:
                failures.append(f"{label}: {rel} missing {needle!r}")

    for label, rel, forbidden in NEGATIVE_CHECKS:
        path = ROOT / rel
        if not path.is_file():
            failures.append(f"{label}: missing file {rel}")
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for needle in forbidden:
            if needle in text:
                failures.append(f"{label}: {rel} must not contain {needle!r}")

    for label, rel, patterns in REGEX_NEGATIVE_CHECKS:
        path = ROOT / rel
        if not path.is_file():
            failures.append(f"{label}: missing file {rel}")
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in patterns:
            if re.search(pattern, text):
                failures.append(f"{label}: {rel} must not match /{pattern}/")

    for rel in ENTRYPOINTS:
        if not (ROOT / rel).is_file():
            failures.append(f"entrypoint missing: {rel}")

    failures.extend(_legacy_template_path_issues())

    if failures:
        print("[policy-flow-drift] FAIL:")
        for item in failures:
            print(f"  - {item}")
        return 1

    print(
        f"[policy-flow-drift] OK: {len(CHECKS)} semantic checks + "
        f"{len(NEGATIVE_CHECKS) + len(REGEX_NEGATIVE_CHECKS)} negative checks + "
        f"legacy template scan + "
        f"{len(ENTRYPOINTS)} entrypoints"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
