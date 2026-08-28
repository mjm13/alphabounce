#!/usr/bin/env python3
"""Contract coverage for policy-flow semantic checks."""

from __future__ import annotations

import io
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import policy_flow_drift_check as drift  # noqa: E402


class PolicyFlowDriftCheckTests(unittest.TestCase):
    def test_requirement_contract_semantic_check_is_registered(self) -> None:
        checks = {label: (path, needles) for label, path, needles in drift.CHECKS}
        path, needles = checks["requirement canonical contract"]

        self.assertEqual(path, ".codebuddy/rules/45-requirement-intake.mdc")
        self.assertIn("H1 需求名 + H1 Gate-0..3 + H2 具体环节", needles)
        self.assertIn("只从 YAML properties 读取", needles)
        self.assertIn("仅接受 14 位时间戳前缀", needles)
        self.assertIn("Gate-0 → Gate-1 → Gate-2 → Gate-3", needles)
        self.assertIn("H2 必须位于对应 Gate 父层", needles)

    def test_project_init_templates_reject_legacy_requirement_contracts(self) -> None:
        checks = {label: (path, needles) for label, path, needles in drift.NEGATIVE_CHECKS}

        pitfall_path, pitfall_needles = checks["approver pitfall tmpl yaml only"]
        self.assertEqual(
            pitfall_path,
            ".codebuddy/skills/xijia-project-init/templates/docs/pitfalls/gate-approver-git-identity.md.tmpl",
        )
        self.assertIn("正文 Gate 表", pitfall_needles)

        regex_checks = {
            label: (path, patterns)
            for label, path, patterns in drift.REGEX_NEGATIVE_CHECKS
        }
        lifecycle_path, patterns = regex_checks["project lifecycle tmpl no numbered seeds"]
        self.assertEqual(
            lifecycle_path,
            ".codebuddy/skills/xijia-project-init/templates/docs/process/project-lifecycle.md.tmpl",
        )
        self.assertTrue(
            any(
                re.search(pattern, "/xijia:start docs/requirements/inbox/001-后端工程初始化.md")
                for pattern in patterns
            )
        )
        self.assertFalse(any(re.search(pattern, "步骤 001：准备项目") for pattern in patterns))

    def test_main_rejects_numbered_requirement_path_without_false_positive(self) -> None:
        regex_checks = [
            (
                "numbered seeds",
                "template.md",
                [r"(?:requirements/(?:inbox|shipped)/|/xijia:start\s+)00[123]-"],
            )
        ]
        cases = (
            ("/xijia:start docs/requirements/inbox/001-后端工程初始化.md", 1),
            ("步骤 001：准备项目", 0),
        )
        for text, expected in cases:
            with self.subTest(text=text), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / "template.md").write_text(text, encoding="utf-8")
                output = io.StringIO()
                with (
                    mock.patch.object(drift, "ROOT", root),
                    mock.patch.object(drift, "CHECKS", []),
                    mock.patch.object(drift, "NEGATIVE_CHECKS", []),
                    mock.patch.object(drift, "REGEX_NEGATIVE_CHECKS", regex_checks),
                    mock.patch.object(drift, "ENTRYPOINTS", []),
                    redirect_stdout(output),
                ):
                    self.assertEqual(drift.main(), expected)


if __name__ == "__main__":
    unittest.main()
