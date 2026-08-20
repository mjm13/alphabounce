#!/usr/bin/env python3
"""Minimal tests for extract_capability_index merge semantics."""

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

import extract_capability_index as eci  # noqa: E402


SAMPLE_REQ = """---
标题: 测试能力
状态: 已交付
分级: 黄
类型: 业务
---

# 测试能力

# Gate-0 澄清与范围

## 范围与切片

- 数据源列表

## 数据流闭环表

| 能力/AC | 来源(Source) | 加工(Process) | 去向(Sink) | 闭环 |
|---|---|---|---|---|
| 数据源-列表 | GET /api/datasources | 校验分页 | datasource 表 + 列表展示 | 已确认 |

# Gate-3 知识同步

## 实现记录与沉淀
Capability Index: updated
"""


class ExtractCapabilityIndexTests(unittest.TestCase):
    @staticmethod
    def duplicate_frontmatter_requirement() -> str:
        return SAMPLE_REQ.replace("分级: 黄", "分级: 黄\n分级: 红")

    def test_frontmatter_parser_accepts_utf8_bom(self) -> None:
        frontmatter = eci._parse_frontmatter("\ufeff" + SAMPLE_REQ)
        self.assertEqual(frontmatter["标题"], "测试能力")
        self.assertEqual(frontmatter["状态"], "已交付")

    def test_parse_closure_table(self) -> None:
        rows = eci.parse_closure_table(SAMPLE_REQ)
        self.assertIsNotNone(rows)
        assert rows is not None
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].name, "数据源-列表")
        self.assertIn("已确认", rows[0].closure)

    def test_closure_to_capability_prefers_frontend_column(self) -> None:
        text = """\
---
标题: 角色
状态: 已交付
分级: 黄
类型: 业务
---
## 数据流闭环表
| 能力 | 来源(Source) | 加工(Process) | 去向(Sink) | 前端入口 | 相关表 | 闭环 |
|---|---|---|---|---|---|---|
| 角色授权 | PUT /api/roles | 写菜单 | sys_role_menu | /w/system-roles | sys_role_menu | 已确认 |
"""
        rows = eci.parse_closure_table(text)
        assert rows is not None
        cap = eci.closure_to_capability(text, "docs/requirements/shipped/demo.md", rows[0])
        self.assertEqual(cap.frontend, "/w/system-roles")
        self.assertEqual(cap.table, "sys_role_menu")

    def test_parse_closure_table_legacy_without_sink_column(self) -> None:
        text = """\
---
标题: 发布页
状态: 已交付
分级: 黄
类型: 混合
---
## 数据流闭环表
| 能力 | 来源 | 加工 | 前端入口 | 闭环 |
|---|---|---|---|---|
| 发布 Shuttle | GET /api/candidates | 穿梭 | /w/mcp-publish | 已确认 |
"""
        rows = eci.parse_closure_table(text)
        self.assertIsNotNone(rows)
        assert rows is not None
        self.assertEqual(rows[0].frontend, "/w/mcp-publish")
        self.assertEqual(rows[0].sink, "/w/mcp-publish")

    def test_parse_closure_table_requires_named_section_any_level(self) -> None:
        table = """\
| 能力/AC | 来源(Source) | 加工(Process) | 去向(Sink) | 闭环 |
|---|---|---|---|---|
| 数据源-列表 | API | 校验 | 页面 | 已确认 |
"""
        self.assertIsNone(eci.parse_closure_table(table))
        for heading in ("# 数据流闭环表", "## 数据流闭环表"):
            with self.subTest(heading=heading):
                rows = eci.parse_closure_table(f"{heading}\n{table}")
                self.assertIsNotNone(rows)
                assert rows is not None
                self.assertEqual(rows[0].name, "数据源-列表")

    def test_parse_closure_table_is_thin_requirement_adapter(self) -> None:
        raw_rows = [
            {
                "name": "共享能力",
                "source": "共享来源",
                "process": "共享加工",
                "sink": "共享去向",
                "closure": "已确认",
            }
        ]
        with mock.patch.object(
            eci,
            "parse_requirement_closure_table",
            return_value=raw_rows,
            create=True,
        ) as parser:
            rows = eci.parse_closure_table("不含任何 Markdown 表")
        parser.assert_called_once_with("不含任何 Markdown 表")
        self.assertEqual(
            rows,
            [
                eci.ClosureRow(
                    name="共享能力",
                    source="共享来源",
                    process="共享加工",
                    sink="共享去向",
                    closure="已确认",
                )
            ],
        )

    def test_infer_module_key_accepts_compact_constraint_table(self) -> None:
        text = """\
# Gate-0 澄清与范围
## 约束引用
| 相关项 | 匹配依据与关联点 | 本需求处置 |
|---|---|---|
| docs/domain/metric.md | 指标/BC/INV-1 | 复用 |
"""
        self.assertEqual(eci.infer_module_key(text, "<能力A>"), ("metric", "metric"))

    def test_extract_does_not_parse_or_compute_capability_map_actions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req_dir = root / "docs/requirements/shipped"
            req_dir.mkdir(parents=True)
            req_path = req_dir / "20260729100000-测试能力.md"
            req_path.write_text(SAMPLE_REQ, encoding="utf-8")

            cap_path = root / "docs" / "capability-map.md"
            cap_path.parent.mkdir(parents=True, exist_ok=True)
            cap_path.write_text(
                eci.render_capability_map(
                    [
                        eci.CapabilityRow(
                            module="数据源",
                            module_key="数据源",
                            frontend="数据源-列表",
                            backend="old",
                            table="old_table",
                            source_summary="old source",
                            sink_summary="old sink",
                            status="active",
                            req_source="docs/requirements/shipped/009-old.md",
                        )
                    ],
                    [],
                ),
                encoding="utf-8",
            )

            result = eci.extract_from_requirement(req_path, root)
            self.assertTrue(result.eligible)
            self.assertEqual(result.actions, [])

    def test_seed_requirement_uses_yaml_marker_not_filename_prefix(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            old_prefix = root / "001-后端工程初始化.md"
            old_prefix.write_text("# 无种子属性\n", encoding="utf-8")
            marked = root / "20260729100000-后端工程初始化.md"
            marked.write_text("---\n种子: true\n---\n", encoding="utf-8")

            self.assertFalse(eci._is_seed_requirement(old_prefix))
            self.assertTrue(eci._is_seed_requirement(marked))

    def test_eligibility_does_not_fallback_to_english_metadata_keys(self) -> None:
        text = SAMPLE_REQ.replace("分级: 黄", "tier: yellow").replace("类型: 业务", "type: technical")
        eligible, reason = eci.is_eligible_requirement(
            text,
            Path("docs/requirements/shipped/20260729100000-测试能力.md"),
        )
        self.assertTrue(eligible)
        self.assertEqual(reason, "")

    def test_apply_merge_writes_data_row_and_revision_entry(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req_path = root / "docs/requirements/shipped/20260729100000-测试能力.md"
            req_path.parent.mkdir(parents=True)
            req_path.write_text(SAMPLE_REQ, encoding="utf-8")

            self.assertEqual(eci.apply_merge(req_path, root), 0)

            rows, revisions = eci.parse_capability_map(root / eci.CAPABILITY_MAP_REL)
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0].frontend, "数据源-列表")
            self.assertEqual(rows[0].req_source, "docs/requirements/shipped/20260729100000-测试能力.md")
            self.assertEqual(len(revisions), 1)
            self.assertEqual(revisions[0].operation, "ADD")
            self.assertEqual(revisions[0].primary_key, rows[0].primary_key())

    def test_apply_merge_dry_run_does_not_write_capability_map(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req_path = root / "docs/requirements/shipped/20260729100000-测试能力.md"
            req_path.parent.mkdir(parents=True)
            req_path.write_text(SAMPLE_REQ, encoding="utf-8")

            self.assertEqual(eci.apply_merge(req_path, root, dry_run=True), 0)
            self.assertFalse((root / eci.CAPABILITY_MAP_REL).exists())

    def test_json_mode_computes_actions_without_mutating_map(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req_path = root / "docs/requirements/shipped/20260729100000-测试能力.md"
            req_path.parent.mkdir(parents=True)
            req_path.write_text(SAMPLE_REQ, encoding="utf-8")
            cap_path = root / eci.CAPABILITY_MAP_REL

            stdout = io.StringIO()
            argv = [
                "extract_capability_index.py",
                "--req",
                str(req_path),
                "--root",
                str(root),
                "--json",
            ]
            with mock.patch.object(sys, "argv", argv), mock.patch("sys.stdout", stdout):
                self.assertEqual(eci.main(), 0)

            payload = json.loads(stdout.getvalue())
            self.assertEqual([action["operation"] for action in payload["actions"]], ["ADD"])
            self.assertFalse(cap_path.exists())

    def test_req_and_json_cli_report_frontmatter_error_without_traceback(self) -> None:
        for extra_args in ([], ["--json"]):
            with self.subTest(args=extra_args), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                req_path = root / "docs/requirements/shipped/20260729100000-重复分级.md"
                req_path.parent.mkdir(parents=True)
                req_path.write_text(self.duplicate_frontmatter_requirement(), encoding="utf-8")
                stdout = io.StringIO()
                argv = [
                    "extract_capability_index.py",
                    "--req",
                    str(req_path),
                    "--root",
                    str(root),
                    *extra_args,
                ]
                with mock.patch.object(sys, "argv", argv), mock.patch("sys.stdout", stdout):
                    rc = eci.main()

                self.assertEqual(rc, 1)
                self.assertIn("[extract-capability] ERROR", stdout.getvalue())
                self.assertIn("重复键 '分级'", stdout.getvalue())
                self.assertNotIn("Traceback", stdout.getvalue())

    def test_req_cli_reports_missing_file_without_traceback(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            missing = root / "docs/requirements/shipped/20260729100000-不存在.md"
            stdout = io.StringIO()
            argv = [
                "extract_capability_index.py",
                "--req",
                str(missing),
                "--root",
                str(root),
            ]
            with mock.patch.object(sys, "argv", argv), mock.patch("sys.stdout", stdout):
                rc = eci.main()

        self.assertEqual(rc, 1)
        self.assertIn("[extract-capability] ERROR", stdout.getvalue())
        self.assertNotIn("Traceback", stdout.getvalue())

    def test_json_cli_reports_directory_as_file_without_traceback(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req_dir = root / "docs/requirements/shipped"
            req_dir.mkdir(parents=True)
            stdout = io.StringIO()
            argv = [
                "extract_capability_index.py",
                "--req",
                str(req_dir),
                "--root",
                str(root),
                "--json",
            ]
            with mock.patch.object(sys, "argv", argv), mock.patch("sys.stdout", stdout):
                rc = eci.main()

        self.assertEqual(rc, 1)
        self.assertIn("[extract-capability] ERROR", stdout.getvalue())
        self.assertNotIn("Traceback", stdout.getvalue())

    def test_req_cli_reports_invalid_utf8_without_traceback(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req_path = root / "docs/requirements/shipped/20260729100000-编码错误.md"
            req_path.parent.mkdir(parents=True)
            req_path.write_bytes(b"---\n\xff\n---\n")
            stdout = io.StringIO()
            argv = [
                "extract_capability_index.py",
                "--req",
                str(req_path),
                "--root",
                str(root),
            ]
            with mock.patch.object(sys, "argv", argv), mock.patch("sys.stdout", stdout):
                rc = eci.main()

        self.assertEqual(rc, 1)
        self.assertIn("[extract-capability] ERROR", stdout.getvalue())
        self.assertNotIn("Traceback", stdout.getvalue())

    def test_backfill_frontmatter_error_is_fail_fast(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            shipped = root / "docs/requirements/shipped"
            shipped.mkdir(parents=True)
            bad = shipped / "20260729100000-重复分级.md"
            bad.write_text(self.duplicate_frontmatter_requirement(), encoding="utf-8")
            good = shipped / "20260729100001-正常需求.md"
            good.write_text(SAMPLE_REQ, encoding="utf-8")

            stdout = io.StringIO()
            argv = [
                "extract_capability_index.py",
                "--backfill",
                "--root",
                str(root),
                "--dry-run",
            ]
            with mock.patch.object(sys, "argv", argv), mock.patch("sys.stdout", stdout):
                rc = eci.main()

        self.assertEqual(rc, 1)
        self.assertIn("[extract-capability] ERROR", stdout.getvalue())
        self.assertIn(bad.name, stdout.getvalue())
        self.assertIn("fail-fast", stdout.getvalue())
        self.assertNotIn(f"merged {good.name}", stdout.getvalue())
        self.assertNotIn("Traceback", stdout.getvalue())

    def test_backfill_reports_invalid_utf8_without_traceback(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            shipped = root / "docs/requirements/shipped"
            shipped.mkdir(parents=True)
            bad = shipped / "20260729100000-编码错误.md"
            bad.write_bytes(b"---\n\xff\n---\n")
            stdout = io.StringIO()
            argv = [
                "extract_capability_index.py",
                "--backfill",
                "--root",
                str(root),
                "--dry-run",
            ]
            with mock.patch.object(sys, "argv", argv), mock.patch("sys.stdout", stdout):
                rc = eci.main()

        self.assertEqual(rc, 1)
        self.assertIn("[extract-capability] ERROR", stdout.getvalue())
        self.assertNotIn("Traceback", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()
