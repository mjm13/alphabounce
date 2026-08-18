#!/usr/bin/env python3
"""Pipeline stage guard — CLI router.

Thin entry point that parses args and dispatches to domain modules. Shared helpers live
in the responsibility-oriented ``guardlib`` package (``paths``, ``markdown``,
``requirement``, ``closeout``, ``openspec``, ``comments``, ``gitio``, ``hookio``,
and ``livingdocs``):

- ``guardlib``      — shared constants plus the responsibility-oriented helper modules above.
- ``guard_intake``  — ``--check-intake`` / ``--check-apply`` / ``--resolve-gate`` (Gate-0).
- ``guard_plan``    — ``--check-plan`` (Gate-1, green/yellow/green-trivial).
- ``guard_release`` — hook mode, ``--check-comment-sync`` / ``--check-release`` (Gate-2),
  ``--check-closeout`` (Gate-3), ``--check-req-ids``, ``--audit``, ``--check-release-readiness``.
- ``guard_adopt``   — ``--check-doc-links`` / ``--check-doc-anchors`` / ``--check-stack-drift``
  / ``--check-adopt-readiness``.

Modes overview:

1. Hook mode (no CLI args): reads a Cursor afterFileEdit JSON payload from stdin and prints
   comment-sync / red-tier reminders. Never blocks (returns 0 always).
2. ``--check-apply --change <name> [--tier red]``: hard check before entering apply.
3. ``--audit``: prints evidence-based stage snapshot for session recovery.
3b. ``--check-intake --req <path>``: Gate-0 hard check (data-flow closure + decision gates).
3c. ``--check-plan --req <path>``: Gate-1 hard check (implementation plan completeness).
4. ``--check-comment-sync [--base <ref>]``: verify-stage comment-sync hard check.
5. ``--check-release [--base <ref>] [--req <path>]``: Gate-2 aggregate backstop.
5b. ``--resolve-gate [--req <path>] [--format cta]``: earliest incomplete human gate; ``--format cta`` without ``--req`` prints specify-doc reminder.
5c. ``--scan-inbox``: summarize current_gate for all inbox requirements.
6. ``--check-closeout --req <path>``: Gate-3 closeout (process-docs archived).
6b. ``--check-gate3-preflight --req <inbox-path>``: Gate-3 Move preflight (inbox exists, Gate-2 accepted).
6c. ``--gate3-trigger-report --req <path> [--base HEAD] [--json]``: Gate-3 living-doc trigger checklist.
6d. ``--check-ui-pattern [--base HEAD]``: Table-First *Panel.vue DOM/CSS structure backstop.
7. ``--check-release-readiness``: Release Gate read-only audit before dev->main.
7b. ``--check-adopt-readiness``: Adoption Gate machine check after ``/xijia:adopt verify``.
8. ``--check-doc-links``: validate relative links in living-doc index files.
8b. ``--check-doc-anchors``: validate ``file#symbol`` anchors in living docs still resolve.
9. ``--check-stack-drift``: detect stale stack keywords vs ``docs/architecture.md``.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from typing import Callable

from guardlib import PIPELINE_PREFIX
from guardlib.gitio import GitCommandError
from guardlib.markdown import FrontmatterError
from guardlib.paths import configure_utf8_streams
from guard_intake import _run_check_apply, _run_check_intake, _run_resolve_gate, _run_scan_inbox
from guard_plan import _run_check_plan
from guard_release import (
    _run_audit,
    _run_check_closeout,
    _run_check_comment_sync,
    _run_check_gate3_preflight,
    _run_gate3_trigger_report,
    _run_check_release,
    _run_check_release_readiness,
    _run_check_req_ids,
    _run_hook,
)
from guard_adopt import (
    _run_check_adopt_readiness,
    _run_check_doc_anchors,
    _run_check_doc_links,
    _run_check_stack_drift,
)
from guard_ui_pattern import run_check_ui_pattern

configure_utf8_streams()


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Pipeline stage guard")
    parser.add_argument("--check-apply", action="store_true", help="hard-check before apply")
    parser.add_argument("--check-intake", action="store_true", help="check Gate-0 data-flow closure table")
    parser.add_argument(
        "--check-plan",
        action="store_true",
        help="check Gate-1 implementation plan completeness (green/yellow)",
    )
    parser.add_argument(
        "--check-comment-sync",
        action="store_true",
        help="verify-stage: changed impl files must carry semantic comment tags",
    )
    parser.add_argument(
        "--check-release",
        action="store_true",
        help="Gate-2 aggregate backstop: comment-sync + tests + approval traces + ADR trigger",
    )
    parser.add_argument(
        "--check-closeout",
        action="store_true",
        help="Gate-3 closeout: process-docs-archived (inbox->shipped, openspec->archive)",
    )
    parser.add_argument(
        "--gate3-trigger-report",
        action="store_true",
        help="Gate-3 trigger report: mandatory/suggested living-doc actions before sync",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="JSON output for --gate3-trigger-report",
    )
    parser.add_argument(
        "--check-gate3-preflight",
        action="store_true",
        help="Gate-3 Move preflight: inbox exists, Gate-2 accepted; warn if shipped without Move",
    )
    parser.add_argument(
        "--check-doc-links",
        action="store_true",
        help="validate relative links in living-doc index files (llms.txt, README.md, etc.)",
    )
    parser.add_argument(
        "--check-doc-anchors",
        action="store_true",
        help="validate `file#symbol` anchors in living docs still resolve (doc-code drift)",
    )
    parser.add_argument(
        "--check-stack-drift",
        action="store_true",
        help="detect stale stack keywords in README/AGENTS/constitution/openspec vs architecture",
    )
    parser.add_argument(
        "--resolve-gate",
        action="store_true",
        help="resolve earliest incomplete human gate for single-gate-per-turn UX",
    )
    parser.add_argument(
        "--scan-inbox",
        action="store_true",
        help="list current_gate for all inbox requirements (active-req hint)",
    )
    parser.add_argument(
        "--format",
        default="",
        help="output format for --resolve-gate (cta = CTA-first markdown skeleton)",
    )
    parser.add_argument(
        "--check-ui-pattern",
        action="store_true",
        help="check Table-First *Panel.vue DOM structure (docs/patterns/*.guard.yaml + foot/drawer)",
    )
    parser.add_argument(
        "--check-adopt-readiness",
        action="store_true",
        help="Adoption Gate audit after /xijia:adopt verify (manifest, AGENTS, codegraph)",
    )
    parser.add_argument(
        "--check-release-readiness",
        action="store_true",
        help="Release Gate audit before dev->main (checklist, AGENTS, CI, inbox warnings)",
    )
    parser.add_argument(
        "--check-req-ids",
        action="store_true",
        help="detect duplicate 14-digit timestamp requirement id prefixes (inbox+shipped)",
    )
    parser.add_argument("--audit", action="store_true", help="print stage evidence snapshot")
    parser.add_argument("--change", default="", help="OpenSpec change name")
    parser.add_argument(
        "--req",
        default="",
        help="requirement markdown path (for intake/plan/release/closeout/gate3-preflight/gate3-trigger-report/resolve-gate)",
    )
    parser.add_argument("--base", default="HEAD", help="git base ref for diff-based checks (comment-sync, release, gate3-trigger-report)")
    parser.add_argument("--tier", default="", help="requirement tier override when frontmatter missing (green/yellow/red/green-trivial)")
    return parser


@dataclass(frozen=True)
class ModeSpec:
    flag: str
    handler: Callable[[argparse.Namespace], int]
    required: tuple[tuple[str, str], ...] = ()


MODE_SPECS = (
    ModeSpec("check_req_ids", lambda args: _run_check_req_ids()),
    ModeSpec("audit", lambda args: _run_audit()),
    ModeSpec("check_release_readiness", lambda args: _run_check_release_readiness()),
    ModeSpec("check_adopt_readiness", lambda args: _run_check_adopt_readiness()),
    ModeSpec("check_doc_links", lambda args: _run_check_doc_links()),
    ModeSpec("check_doc_anchors", lambda args: _run_check_doc_anchors()),
    ModeSpec("check_stack_drift", lambda args: _run_check_stack_drift()),
    ModeSpec("check_closeout", lambda args: _run_check_closeout(args.req)),
    ModeSpec(
        "gate3_trigger_report",
        lambda args: _run_gate3_trigger_report(args.req, args.base, args.json),
        (("req", "<path>"),),
    ),
    ModeSpec(
        "check_gate3_preflight",
        lambda args: _run_check_gate3_preflight(args.req),
        (("req", "<inbox-path>"),),
    ),
    ModeSpec("scan_inbox", lambda args: _run_scan_inbox()),
    ModeSpec(
        "resolve_gate",
        lambda args: _run_resolve_gate(args.req, args.format),
    ),
    ModeSpec("check_release", lambda args: _run_check_release(args.base, args.req)),
    ModeSpec("check_comment_sync", lambda args: _run_check_comment_sync(args.base)),
    ModeSpec("check_ui_pattern", lambda args: run_check_ui_pattern(args.base)),
    ModeSpec(
        "check_intake",
        lambda args: _run_check_intake(args.req, args.tier.lower() if args.tier else ""),
        (("req", "<path>"),),
    ),
    ModeSpec(
        "check_plan",
        lambda args: _run_check_plan(args.req, args.tier.lower() if args.tier else ""),
        (("req", "<path>"),),
    ),
    ModeSpec(
        "check_apply",
        lambda args: _run_check_apply(args.change, args.tier.lower() if args.tier else "red"),
        (("change", "<name>"),),
    ),
)


def _dispatch(args: argparse.Namespace, parser: argparse.ArgumentParser) -> int:
    for mode in MODE_SPECS:
        if not getattr(args, mode.flag):
            continue
        for attribute, placeholder in mode.required:
            if not getattr(args, attribute):
                option = mode.flag.replace("_", "-")
                print(f"{PIPELINE_PREFIX} --{option} 需要 --{attribute} {placeholder}")
                return 2
        return mode.handler(args)
    parser.print_help()
    return 0


def _main() -> int:
    if len(sys.argv) <= 1:
        return _run_hook()
    parser = _build_parser()
    return _dispatch(parser.parse_args(), parser)


def main() -> int:
    try:
        return _main()
    except FrontmatterError as exc:
        print(f"{PIPELINE_PREFIX} requirement frontmatter 不合规：{exc}")
        return 1
    except GitCommandError as exc:
        print(f"{PIPELINE_PREFIX} Git 变更检测失败：{exc}")
        print("  → 无法可信判断变更范围；请修复 git 命令/仓库状态后重试。")
        return 0 if len(sys.argv) <= 1 else 2


if __name__ == "__main__":
    raise SystemExit(main())
