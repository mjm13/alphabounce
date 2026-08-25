"""Experience-doc binding gate on afterFileEdit.

A patterns/pitfalls doc without ``last_verified`` + ``sources[].path`` can never
be shown to have decayed, so it accumulates forever. The rules already carry the
equivalent binding via ``defends:``; before this gate the same requirement was
written down for experience docs but enforced nowhere, and all 11 of them
shipped without a single frontmatter field.

The gate reminds and never blocks: a rejected edit would be a far worse failure
than a stale doc.
"""

from __future__ import annotations

import io
import json
import sys
import unittest
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import drift_guard_scan as scan  # noqa: E402

COMPLETE = """---
last_verified: 2026-08-18
sources:
  - name: list
    path: frontend/src/assets/styles/list.css
---

# 某条经验
"""


class ExperienceBindingTests(unittest.TestCase):
    def test_missing_both_fields_reports_both(self) -> None:
        self.assertEqual(len(scan.experience_binding_gaps("# 某条经验\n")), 2)

    def test_complete_frontmatter_has_no_gaps(self) -> None:
        self.assertEqual(scan.experience_binding_gaps(COMPLETE), [])

    def test_missing_only_sources_reports_one(self) -> None:
        text = "---\nlast_verified: 2026-08-18\n---\n\n# 某条经验\n"
        gaps = scan.experience_binding_gaps(text)
        self.assertEqual(len(gaps), 1)
        self.assertIn("sources", gaps[0])

    def test_compact_list_form_is_not_accepted(self) -> None:
        """``- path:`` on one line is invalid here; score_docs cannot read it either."""
        text = "---\nlast_verified: 2026-08-18\nsources:\n  - path: frontend/a.js\n---\n\n# x\n"
        gaps = scan.experience_binding_gaps(text)
        self.assertEqual(len(gaps), 1)
        self.assertIn("sources", gaps[0])


class ExperienceDocDetectionTests(unittest.TestCase):
    def test_patterns_entry_is_an_experience_doc(self) -> None:
        self.assertTrue(scan._is_experience_doc(scan.EXPERIENCE_ROOTS[0] / "table-first.md"))

    def test_readme_index_is_exempt(self) -> None:
        self.assertFalse(scan._is_experience_doc(scan.EXPERIENCE_ROOTS[0] / "README.md"))

    def test_rule_file_is_not_an_experience_doc(self) -> None:
        self.assertFalse(scan._is_experience_doc(scan.RULES_ROOT / "41-change-boundary.mdc"))


class HookOutputTests(unittest.TestCase):
    def _run(self, rel_path: str, text: str) -> tuple[int, str]:
        target = scan.ROOT / rel_path
        payload = json.dumps({"file_path": str(target), "hook_event_name": "afterFileEdit"})

        class _Stdin:
            buffer = io.BytesIO(payload.encode("utf-8"))

        stdout = io.StringIO()
        with mock.patch.object(sys, "stdin", _Stdin()), mock.patch.object(
            sys, "stdout", stdout
        ), mock.patch.object(Path, "is_file", lambda self: True), mock.patch.object(
            Path, "read_text", lambda self, **kwargs: text
        ):
            rc = scan.main()
        return rc, stdout.getvalue()

    def test_incomplete_experience_doc_reminds_without_blocking(self) -> None:
        rc, out = self._run("docs/patterns/demo.md", "# 某条经验\n")
        self.assertEqual(rc, 0)
        self.assertIn("[experience-scan]", out)

    def test_complete_experience_doc_is_silent(self) -> None:
        rc, out = self._run("docs/patterns/demo.md", COMPLETE)
        self.assertEqual(rc, 0)
        self.assertEqual(out, "")

    def test_experience_doc_may_name_the_product_stack(self) -> None:
        """Docs describe Vue/Element Plus by design; only rules must stay stack-agnostic."""
        text = COMPLETE + "\n用 Element Plus 的 el-table，配合 Vue 的 script setup。\n"
        rc, out = self._run("docs/patterns/demo.md", text)
        self.assertEqual(rc, 0)
        self.assertNotIn("drift-scan", out)


if __name__ == "__main__":
    unittest.main()
