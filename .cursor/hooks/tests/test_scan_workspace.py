#!/usr/bin/env python3
"""Tests for scan_workspace module discovery and manifest building."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import scan_workspace as sw  # noqa: E402


class ScanWorkspaceTests(unittest.TestCase):
    def test_discover_maven_module(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mod = root / "services" / "api"
            mod.mkdir(parents=True)
            (mod / "pom.xml").write_text(
                "<project><artifactId>api</artifactId></project>", encoding="utf-8"
            )
            modules = sw.discover_modules(root)
            keys = {m.key for m in modules}
            self.assertIn("api", keys)
            backend = [m for m in modules if m.key == "api"][0]
            self.assertEqual(backend.kind, "backend")
            self.assertTrue(backend.primary)

    def test_infer_npm_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mod = root / "web"
            mod.mkdir()
            (mod / "package.json").write_text(
                json.dumps({"scripts": {"dev": "vite", "test": "vitest", "build": "vite build"}}),
                encoding="utf-8",
            )
            cmds = sw.infer_commands(mod)
            self.assertIn("npm run test", cmds["test"])

    def test_ddd_discovery_finds_entity(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mod = root / "svc"
            java = mod / "src" / "main" / "java" / "com" / "example"
            java.mkdir(parents=True)
            (mod / "pom.xml").write_text("<project/>", encoding="utf-8")
            (java / "Order.java").write_text(
                "@Entity\npublic class Order {}\n", encoding="utf-8"
            )
            modules = sw.discover_modules(root)
            ddd = sw.ddd_discovery_from_modules(modules, root)
            terms = [t["term"] for t in ddd["terms"]]
            self.assertIn("Order", terms)

    def test_classify_entity_conservative(self) -> None:
        self.assertEqual(sw.classify_entity("Order"), "aggregate")
        self.assertEqual(sw.classify_entity("OrderLog"), "infrastructure")
        self.assertEqual(sw.classify_entity("UserRole"), "supporting")
        self.assertEqual(sw.classify_entity("OrderDTO"), "dto")
        # *Record 不因命名降级
        self.assertEqual(sw.classify_entity("PaymentRecord"), "aggregate")
        # 支撑类承载状态机 → 提升为聚合候选
        self.assertEqual(sw.classify_entity("OrderConfig", "status = ..."), "aggregate")

    def test_ddd_discovery_python_model_and_classification(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mod = root / "app"
            mod.mkdir()
            (mod / "pyproject.toml").write_text("[project]\nname='app'", encoding="utf-8")
            (mod / "models.py").write_text(
                "from django.db import models\n"
                "class Collection(models.Model):\n    status = models.CharField(max_length=10)\n"
                "class CollectionMessageLog(models.Model):\n    body = models.TextField()\n",
                encoding="utf-8",
            )
            modules = sw.discover_modules(root)
            ddd = sw.ddd_discovery_from_modules(modules, root)
            by_name = {t["term"]: t for t in ddd["terms"]}
            self.assertIn("Collection", by_name)
            self.assertIn("CollectionMessageLog", by_name)
            self.assertEqual(by_name["CollectionMessageLog"]["classification"], "infrastructure")
            self.assertTrue(by_name["Collection"]["anchor"].endswith("#Collection"))
            self.assertIn("classification_summary", ddd)

    def test_scan_entrypoints_python(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mod = root / "app"
            mod.mkdir()
            (mod / "pyproject.toml").write_text("[project]\nname='app'", encoding="utf-8")
            (mod / "tasks.py").write_text(
                "from celery import shared_task\n\n@shared_task\ndef sync_orders():\n    pass\n",
                encoding="utf-8",
            )
            modules = sw.discover_modules(root)
            eps = sw.scan_entrypoints(modules, root)
            names = {e["name"]: e for e in eps}
            self.assertIn("sync_orders", names)
            self.assertEqual(names["sync_orders"]["kind"], "task")
            self.assertTrue(names["sync_orders"]["anchor"].endswith("#sync_orders"))

    def test_render_flow_draft_no_hallucination(self) -> None:
        out = sw.render_flow_draft(
            [{"kind": "task", "name": "sync", "anchor": "app/tasks.py#sync"}],
            [{"path": "/api/order", "controller": "OrderController", "file": "app/O.java"}],
        )
        self.assertIn("[待确认：调用链]", out)
        self.assertIn("app/tasks.py#sync", out)
        self.assertIn("/api/order", out)

    def test_dump_and_load_manifest(self) -> None:
        data = {
            "workspace": {"name": "demo"},
            "modules": [{"key": "a", "path": "a", "kind": "backend"}],
        }
        text = sw.dump_manifest(data)
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "m.yaml"
            p.write_text(text, encoding="utf-8")
            loaded = sw.load_manifest(p)
        self.assertEqual(loaded.get("workspace", {}).get("name"), "demo")
        self.assertIsInstance(loaded.get("modules"), list)
        self.assertGreaterEqual(len(loaded.get("modules") or []), 1)


if __name__ == "__main__":
    unittest.main()
