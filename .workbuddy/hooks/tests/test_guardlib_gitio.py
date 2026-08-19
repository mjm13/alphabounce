"""Failure semantics for guardlib Git discovery."""

from __future__ import annotations

import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import pipeline_guard  # noqa: E402
from guardlib import gitio  # noqa: E402


class GitIoTests(unittest.TestCase):
    def test_cli_missing_required_argument_returns_two(self) -> None:
        output = io.StringIO()
        with mock.patch.object(
            sys, "argv", ["pipeline_guard.py", "--check-intake"]
        ), redirect_stdout(output):
            rc = pipeline_guard._main()

        self.assertEqual(rc, 2)
        self.assertEqual(
            output.getvalue(),
            "[pipeline-guard] --check-intake 需要 --req <path>\n",
        )

    def test_git_lines_raises_clear_error(self) -> None:
        result = mock.Mock(returncode=128, stderr="bad revision", stdout="")
        with mock.patch.object(gitio.subprocess, "run", return_value=result):
            with self.assertRaisesRegex(gitio.GitCommandError, "bad revision"):
                gitio.git_lines(["diff", "--name-only", "missing"])

    def test_cli_reports_git_failure(self) -> None:
        error = gitio.GitCommandError(["diff"], "repository unavailable")
        with mock.patch.object(pipeline_guard, "_main", side_effect=error):
            with mock.patch.object(sys, "argv", ["pipeline_guard.py", "--audit"]):
                self.assertEqual(pipeline_guard.main(), 2)

    def test_hook_mode_never_blocks_git_failure(self) -> None:
        error = gitio.GitCommandError(["diff"], "repository unavailable")
        with mock.patch.object(pipeline_guard, "_main", side_effect=error):
            with mock.patch.object(sys, "argv", ["pipeline_guard.py"]):
                self.assertEqual(pipeline_guard.main(), 0)


if __name__ == "__main__":
    unittest.main()
