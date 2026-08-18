#!/usr/bin/env python3
"""Tests for --check-adopt-readiness (minimal fixture workspace)."""

from __future__ import annotations

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import guard_adopt as ga  # noqa: E402  (adopt-readiness lives here after split)
import scan_workspace as sw  # noqa: E402
from guardlib import paths  # noqa: E402


MINIMAL_AGENTS = """# AGENTS

## Project overview

## Layout

All modules listed.

## Build and test commands

```bash
npm install
npm test
npm run build
```

## Testing instructions

Run npm test.

## Security

No secrets in repo.
"""


class AdoptReadinessTests(unittest.TestCase):
    def test_adopt_readiness_skips_template_base_without_docs(self) -> None:
        """模板基座尚未渲染 adopt 文档时不应被 Adoption Gate 误报。"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with mock.patch.object(paths, "ROOT", root):
                self.assertEqual(ga._run_check_adopt_readiness(), 0)

    def _seed_workspace(self, root: Path) -> None:
        (root / ".cursor" / "rules").mkdir(parents=True)
        (root / ".cursor" / "rules" / "00-workflow.mdc").write_text("workflow", encoding="utf-8")
        (root / ".cursor" / "hooks").mkdir(parents=True, exist_ok=True)
        hooks = [
            "pipeline_guard.py",
            "policy_flow_drift_check.py",
            "scan_workspace.py",
        ]
        for name in hooks:
            src = HOOKS_DIR / name
            if src.is_file():
                (root / ".cursor" / "hooks" / name).write_text(
                    src.read_text(encoding="utf-8"), encoding="utf-8"
                )
        docs = [
            "docs/constitution.md",
            "docs/README.md",
            "docs/llms.txt",
            "docs/domain/README.md",
            ".cursor/templates/requirements/requirements-template.md",
            ".cursor/templates/requirements/technical-requirement-template.md",
            "docs/requirements/backlog.md",
            "docs/requirements/inbox/README.md",
            "docs/process/project-lifecycle.md",
            "docs/process/release-checklist.md",
            "docs/process/knowledge-maintenance.md",
            "docs/decisions/0002-project-adoption.md",
            "docs/architecture.md",
        ]
        for rel in docs:
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("# stub\n", encoding="utf-8")
        (root / "AGENTS.md").write_text(MINIMAL_AGENTS, encoding="utf-8")
        mod = root / "backend"
        mod.mkdir()
        (mod / "package.json").write_text('{"scripts":{"test":"npm test"}}', encoding="utf-8")
        manifest = {
            "workspace": {"name": "demo", "ddd_required": False},
            "adopt": {"stage": "content", "skip_codegraph": True},
            "modules": [
                {
                    "key": "backend",
                    "path": "backend",
                    "kind": "backend",
                    "primary": True,
                    "discovery": {"status": "confirmed", "confidence": "high"},
                    "codegraph": {"status": "skipped", "skip_reason": "test"},
                }
            ],
            "commands": {
                "backend": {
                    "install": "cd backend && npm install",
                    "test": "cd backend && npm test",
                    "discovery": {"status": "confirmed"},
                }
            },
        }
        (root / "docs/workspace-manifest.yaml").write_text(
            sw.dump_manifest(manifest), encoding="utf-8"
        )

    def test_adopt_readiness_passes_minimal(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._seed_workspace(root)
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(sw, "ROOT", root):
                with mock.patch.object(ga, "living_doc_link_issues", return_value=[]):
                    with mock.patch.object(ga, "stack_drift_issues", return_value=[]):
                        with mock.patch.object(
                            ga.subprocess,
                            "run",
                            side_effect=lambda *a, **k: mock.Mock(returncode=0, stdout="dev\n"),
                        ):
                            rc = ga._run_check_adopt_readiness()
            self.assertEqual(rc, 0)

    def test_adopt_readiness_failure_prints_each_nested_check_once(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._seed_workspace(root)
            output = io.StringIO()
            with (
                mock.patch.object(paths, "ROOT", root),
                mock.patch.object(sw, "ROOT", root),
                mock.patch.object(ga, "living_doc_link_issues", return_value=["断链"]),
                mock.patch.object(ga, "stack_drift_issues", return_value=["漂移"]),
                mock.patch.object(
                    ga.subprocess,
                    "run",
                    side_effect=lambda *a, **k: mock.Mock(returncode=0, stdout="dev\n"),
                ),
                redirect_stdout(output),
            ):
                rc = ga._run_check_adopt_readiness()

        self.assertEqual(rc, 1)
        rendered = output.getvalue()
        self.assertEqual(rendered.count("[doc-links] 未通过："), 1)
        self.assertEqual(rendered.count("[stack-drift] 未通过："), 1)
        self.assertEqual(rendered.count("  - 断链"), 1)
        self.assertEqual(rendered.count("  - 漂移"), 1)
        self.assertIn("[adopt-readiness] FAIL:", rendered)


if __name__ == "__main__":
    unittest.main()
