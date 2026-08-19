#!/usr/bin/env python3
"""Tests for --check-doc-anchors (file#symbol drift detection)."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import pipeline_guard as pg  # noqa: E402  (router re-exports _run_check_doc_anchors)
from guardlib import paths  # noqa: E402


class DocAnchorTests(unittest.TestCase):
    def _seed(self, root: Path, doc_body: str, code: dict[str, str]) -> None:
        for rel, content in code.items():
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
        domain = root / "docs" / "domain" / "orders"
        domain.mkdir(parents=True, exist_ok=True)
        (domain / "ubiquitous-language.md").write_text(doc_body, encoding="utf-8")

    def _run(self, root: Path) -> int:
        with mock.patch.object(paths, "ROOT", root):
            return pg._run_check_doc_anchors()

    def test_anchor_resolves_ok(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._seed(
                root,
                "| Order | aggregate | app/models.py#Order |\n",
                {"app/models.py": "class Order(models.Model):\n    pass\n"},
            )
            self.assertEqual(self._run(root), 0)

    def test_missing_file_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._seed(root, "| Order | aggregate | app/gone.py#Order |\n", {})
            self.assertEqual(self._run(root), 1)

    def test_missing_symbol_warns_not_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._seed(
                root,
                "| Order | aggregate | app/models.py#Renamed |\n",
                {"app/models.py": "class Order(models.Model):\n    pass\n"},
            )
            # symbol drift is a warning, exit stays 0
            self.assertEqual(self._run(root), 0)

    def test_placeholder_anchor_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._seed(root, "| X | aggregate | [待确认] |\n", {})
            self.assertEqual(self._run(root), 0)


if __name__ == "__main__":
    unittest.main()
