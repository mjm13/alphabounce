"""Artifact classification and requirement binding for the beforeReadFile hook.

Two behaviours are pinned here:

1. The hook fires for every Read, but ``_resolve_doc`` used to accept only
   ``docs/`` paths, so every rule and skill load was silently discarded.
2. Usage events recorded the Cursor conversation UUID as ``session`` while
   ``closeout.reuse_logging_gaps`` matches on a requirement stem, so the usage
   log was invisible to the only consumer that reads it.
"""

from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import log_doc_usage  # noqa: E402
from guardlib import closeout, paths  # noqa: E402


class _Stdin:
    def __init__(self, data: bytes) -> None:
        self.buffer = io.BytesIO(data)


def _run_hook(file_path: str, log: Path, stem: str | None) -> list[dict]:
    payload = {"file_path": file_path, "hook_event_name": "beforeReadFile", "session_id": "uuid-1"}
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    with mock.patch.object(sys, "stdin", _Stdin(data)), mock.patch.object(
        log_doc_usage, "USAGE_LOG", log
    ), mock.patch.object(log_doc_usage, "_inflight_stem", lambda: stem), mock.patch.object(
        sys, "stdout", io.StringIO()
    ):
        log_doc_usage.main()
    if not log.is_file():
        return []
    return [json.loads(line) for line in log.read_text(encoding="utf-8").splitlines()]


class ClassifyTests(unittest.TestCase):
    """``_classify`` maps a read path to (artifact, doc, signal)."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        root = Path(self._tmp.name).resolve()
        self.root = root
        docs = root / "docs"
        rules = root / ".codebuddy/rules"
        cursor_skills = root / ".codebuddy/skills"
        agent_skills = root / ".agents/skills"
        for path in (docs / "patterns", rules, cursor_skills, agent_skills):
            path.mkdir(parents=True, exist_ok=True)

        (docs / "patterns/table-first.md").write_text("x", encoding="utf-8")
        (rules / "41-change-boundary.mdc").write_text("x", encoding="utf-8")

        skill = cursor_skills / "xijia-git-commit"
        (skill / "references").mkdir(parents=True, exist_ok=True)
        (skill / "scripts").mkdir(parents=True, exist_ok=True)
        (skill / "SKILL.md").write_text("x", encoding="utf-8")
        (skill / "references/commit-format.md").write_text("x", encoding="utf-8")
        (skill / "scripts/run.py").write_text("x", encoding="utf-8")

        # Nested third-party pack: the leaf skill owns the event, not the pack.
        leaf = agent_skills / "element-plus-skills/components/el-button"
        leaf.mkdir(parents=True, exist_ok=True)
        (agent_skills / "element-plus-skills/SKILL.md").write_text("x", encoding="utf-8")
        (leaf / "SKILL.md").write_text("x", encoding="utf-8")

        (root / "observability").mkdir(parents=True, exist_ok=True)
        (root / "observability/docs_usage.jsonl").write_text("", encoding="utf-8")
        (root / "backend").mkdir(parents=True, exist_ok=True)
        (root / "backend/main.py").write_text("x", encoding="utf-8")

        self._patches = [
            mock.patch.object(log_doc_usage, "ROOT", root),
            mock.patch.object(log_doc_usage, "DOCS_ROOT", docs.resolve()),
            mock.patch.object(log_doc_usage, "RULES_ROOT", rules.resolve()),
            mock.patch.object(
                log_doc_usage, "SKILLS_ROOTS", (cursor_skills.resolve(), agent_skills.resolve())
            ),
        ]
        for patch in self._patches:
            patch.start()

    def tearDown(self) -> None:
        for patch in self._patches:
            patch.stop()
        self._tmp.cleanup()

    def classify(self, rel: str):
        return log_doc_usage._classify(str(self.root / rel))

    def test_doc_keeps_the_doc_field_for_downstream_consumers(self) -> None:
        artifact, doc, signal = self.classify("docs/patterns/table-first.md")
        self.assertEqual(artifact, "doc:docs/patterns/table-first.md")
        self.assertEqual(doc, "docs/patterns/table-first.md")
        self.assertIsNone(signal)

    def test_on_demand_rule_is_collected(self) -> None:
        artifact, doc, signal = self.classify(".codebuddy/rules/41-change-boundary.mdc")
        self.assertEqual(artifact, "rule:41-change-boundary.mdc")
        self.assertIsNone(doc)

    def test_skill_entry_point_is_a_weak_signal(self) -> None:
        artifact, _, signal = self.classify(".codebuddy/skills/xijia-git-commit/SKILL.md")
        self.assertEqual(artifact, "skill:xijia-git-commit")
        self.assertEqual(signal, "weak")

    def test_skill_reference_is_a_strong_signal(self) -> None:
        artifact, _, signal = self.classify(
            ".codebuddy/skills/xijia-git-commit/references/commit-format.md"
        )
        self.assertEqual(artifact, "skill:xijia-git-commit")
        self.assertEqual(signal, "strong")

    def test_skill_own_script_is_only_a_weak_signal(self) -> None:
        """Reading a skill's implementation is maintenance, not execution."""
        artifact, _, signal = self.classify(".codebuddy/skills/xijia-git-commit/scripts/run.py")
        self.assertEqual(artifact, "skill:xijia-git-commit")
        self.assertEqual(signal, "weak")

    def test_nested_pack_resolves_to_the_leaf_skill(self) -> None:
        artifact, _, signal = self.classify(
            ".agents/skills/element-plus-skills/components/el-button/SKILL.md"
        )
        self.assertEqual(artifact, "skill:element-plus-skills/components/el-button")
        self.assertEqual(signal, "weak")

    def test_observability_is_out_of_scope(self) -> None:
        self.assertIsNone(self.classify("observability/docs_usage.jsonl"))

    def test_product_code_is_out_of_scope(self) -> None:
        self.assertIsNone(self.classify("backend/main.py"))

    def test_path_outside_the_repo_is_out_of_scope(self) -> None:
        self.assertIsNone(log_doc_usage._classify(str(Path.home() / ".codebuddy/skills-cursor/x.md")))


class SessionBindingTests(unittest.TestCase):
    DOC = "docs/patterns/table-first.md"

    def test_event_binds_the_inflight_requirement_stem(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp) / "usage.jsonl"
            events = _run_hook(
                str(log_doc_usage.DOCS_ROOT / "patterns/table-first.md"),
                log,
                "20260729123456-demo",
            )
        self.assertEqual(events[0]["session"], "20260729123456-demo")
        self.assertEqual(events[0]["scope"], "in-flow")

    def test_event_without_inflight_requirement_is_marked_out_of_flow(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp) / "usage.jsonl"
            events = _run_hook(
                str(log_doc_usage.DOCS_ROOT / "patterns/table-first.md"), log, None
            )
        self.assertIsNone(events[0]["session"])
        self.assertEqual(events[0]["scope"], "out-of-flow")

    def _reuse_gaps(self, session: str, stem: str) -> list[str]:
        with tempfile.TemporaryDirectory() as tmp:
            usage = Path(tmp) / "usage.jsonl"
            judgments = Path(tmp) / "judgments.jsonl"
            usage.write_text(
                json.dumps({"artifact": f"doc:{self.DOC}", "doc": self.DOC, "session": session})
                + "\n",
                encoding="utf-8",
            )
            judgments.write_text("", encoding="utf-8")
            text = f"实现中对照了 {self.DOC}（见方案说明）"
            with (
                mock.patch.object(paths, "DOCS_USAGE_LOG", usage),
                mock.patch.object(paths, "DOCS_JUDGMENTS_LOG", judgments),
            ):
                return closeout.reuse_logging_gaps(text, stem)

    def test_stem_session_closes_the_reuse_loop(self) -> None:
        self.assertEqual(self._reuse_gaps("20260729123456-demo", "20260729123456-demo"), [])

    def test_conversation_uuid_never_closes_the_reuse_loop(self) -> None:
        gaps = self._reuse_gaps("2f10d333-3e4c-430c-acf4-9db5864f2062", "20260729123456-demo")
        self.assertEqual(gaps, [self.DOC])


if __name__ == "__main__":
    unittest.main()
