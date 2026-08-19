#!/usr/bin/env python3
"""Fixture tests for pipeline_guard core checks: intake / plan / comment-sync / release."""

from __future__ import annotations

import re
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

HOOKS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOOKS_DIR))

import guard_release as gr  # noqa: E402
import guard_plan as gp  # noqa: E402
import guard_intake as gi  # noqa: E402
import extract_capability_index as eci  # noqa: E402
import pipeline_guard as pg  # noqa: E402  (router re-exports _run_check_*)
from guardlib import closeout, comments, markdown, openspec, paths, requirement  # noqa: E402


def _write(root: Path, rel: str, content: str) -> Path:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    return p


class IntakeCheckTests(unittest.TestCase):
    def test_intake_failure_output_and_exit_code_are_stable(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            req = _write(Path(tmp), "010-用户导入批量校验.md", "# stub\n")
            output = io.StringIO()
            with redirect_stdout(output):
                rc = pg._run_check_intake(str(req), "green")

        self.assertEqual(rc, 1)
        self.assertEqual(
            output.getvalue(),
            "[pipeline-guard] 需求文件名不合规：'010-用户导入批量校验.md' "
            "只接受 14 位时间戳前缀（Gate-0 不通过）。\n"
            "  → 命名规范：`<YYYYMMDDHHMMSS>-<简述>.md`（简述优先中文，可含英文/缩写）。\n",
        )

    def test_section_extractors_accept_nested_gate_sections(self) -> None:
        text = """\
# 需求名称
# Gate-0 澄清与范围
## 范围与切片
- AC-1：模板按 Gate 组织
## 约束引用
约束引用: none
# Gate-1 方案
## 实现方案
- 回归验证点：`python -m pytest`
### 深层环节
深层内容
"""
        self.assertEqual(
            markdown.extract_section(text, "范围与切片"),
            "- AC-1：模板按 Gate 组织",
        )
        self.assertNotIn(
            "Gate-1",
            markdown.extract_section(text, "约束引用") or "",
        )
        self.assertEqual(
            markdown.extract_section(text, "深层环节"),
            "深层内容",
        )

    def test_section_extractors_accept_h1_requirement_steps(self) -> None:
        text = """\
# 范围与切片（Gate-0）
- AC-1：旧结构
# 实现方案（Gate-1）
- 回归验证点：`python -m pytest`
"""
        self.assertEqual(
            markdown.extract_section(text, "范围与切片"),
            "- AC-1：旧结构",
        )
        self.assertEqual(
            markdown.extract_section(text, "实现方案"),
            "- 回归验证点：`python -m pytest`",
        )

    def test_gate3_distill_accepts_h1_implementation_record(self) -> None:
        text = """\
# 验收记录
- 通过
# 实现记录与沉淀（Gate-3）
- Patterns: no-op
- Pitfalls: no-op
# 附录
- 其它
"""
        section = closeout.gate3_distill_section(text)
        self.assertIn("Patterns: no-op", section)
        self.assertNotIn("附录", section)

    def test_section_extractor_ignores_target_h2_inside_fence(self) -> None:
        for fence in ("```markdown", "~~~markdown"):
            marker = fence[0] * 3
            with self.subTest(fence=fence):
                text = f"""\
{fence}
## 实现方案
- 围栏内示例
{marker}
"""
                self.assertIsNone(markdown.extract_section(text, "实现方案"))

    def test_section_extractor_finds_real_h2_after_fenced_example(self) -> None:
        text = """\
```markdown
## 实现方案
- 围栏内示例
```
## 实现方案
- 真实方案
## 验收记录
- 不应包含
"""
        self.assertEqual(markdown.extract_section(text, "实现方案"), "- 真实方案")

    def test_section_extractor_ignores_headings_inside_fenced_code(self) -> None:
        for fence, close in (("````bash", "````"), ("~~~shell", "~~~~")):
            with self.subTest(fence=fence):
                text = f"""\
## 实现方案
执行示例：
{fence}
## 这不是下一章节
# bash 注释
{close}
围栏后的方案内容。
## 验收记录
不应包含。
"""
                section = markdown.extract_section(text, "实现方案")
                self.assertIsNotNone(section)
                assert section is not None
                self.assertIn("## 这不是下一章节", section)
                self.assertIn("# bash 注释", section)
                self.assertIn("围栏后的方案内容。", section)
                self.assertNotIn("不应包含。", section)

    def test_heading_iterator_ignores_frontmatter_and_fences(self) -> None:
        text = """\
---
# frontmatter comment
---
```markdown
# 围栏伪需求
## 围栏伪环节
```
# 真实需求
## 孤立环节
"""
        self.assertEqual(
            [(heading.level, heading.title) for heading in markdown.iter_headings(text)],
            [(1, "真实需求"), (2, "孤立环节")],
        )

    def test_closure_table_requires_named_section_any_level(self) -> None:
        table = """\
| 能力/AC | 来源(Source) | 加工(Process) | 去向(Sink) | 闭环 |
|---|---|---|---|---|
| AC-1 | 输入 | 校验 | 输出 | 已确认 |
"""
        self.assertIsNone(requirement.parse_closure_table(table))
        for heading in ("# 数据流闭环表", "## 数据流闭环表"):
            with self.subTest(heading=heading):
                rows = requirement.parse_closure_table(f"{heading}\n{table}")
                self.assertIsNotNone(rows)
                assert rows is not None
                self.assertEqual(rows[0]["name"], "AC-1")
                self.assertEqual(rows[0]["frontend"], "")
                self.assertEqual(rows[0]["table"], "")

    def test_closure_table_parses_frontend_entry_column(self) -> None:
        text = """\
## 数据流闭环表
| 能力 | 来源(Source) | 加工(Process) | 去向(Sink) | 前端入口 | 相关表 | 闭环 |
|---|---|---|---|---|---|---|
| 角色列表 | GET /api/roles | 校验 | 列表展示 | /w/system-roles | sys_role | 已确认 |
"""
        rows = requirement.parse_closure_table(text)
        self.assertIsNotNone(rows)
        assert rows is not None
        self.assertEqual(rows[0]["frontend"], "/w/system-roles")
        self.assertEqual(rows[0]["table"], "sys_role")

    def test_closure_table_legacy_frontend_without_sink(self) -> None:
        text = """\
## 数据流闭环表
| 能力 | 来源 | 加工 | 前端入口 | 闭环 |
|---|---|---|---|---|
| 发布 Shuttle | /api/mcp-services/publish/candidates | 分页+穿梭 | /w/mcp-publish | 已确认 |
"""
        rows = requirement.parse_closure_table(text)
        self.assertIsNotNone(rows)
        assert rows is not None
        self.assertEqual(rows[0]["name"], "发布 Shuttle")
        self.assertEqual(rows[0]["frontend"], "/w/mcp-publish")
        self.assertEqual(rows[0]["sink"], "/w/mcp-publish")

    def test_gate3_preflight_missing_inbox_blocks_rebuild(self) -> None:
        missing = paths.INBOX_DIR / "__gate3_preflight_missing__.md"
        errors, warnings = closeout.gate3_preflight_issues(missing)
        self.assertTrue(any("不存在" in e for e in errors))
        self.assertTrue(any("禁止" in e for e in errors))

    def test_gate3_preflight_requires_gate2_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            inbox = root / "docs" / "requirements" / "inbox"
            inbox.mkdir(parents=True)
            req = inbox / "demo.md"
            req.write_text(
                "---\n状态: 待处理\n分级: 绿\n类型: 技术\n"
                "Gate-2: 状态:待验收；审批人:tester；2026-08-04\n---\n# demo\n",
                encoding="utf-8",
            )
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "INBOX_DIR", inbox.resolve()
            ), mock.patch.object(
                paths, "SHIPPED_DIR", (root / "docs" / "requirements" / "shipped").resolve()
            ):
                errors, _warnings = closeout.gate3_preflight_issues(req)
            self.assertTrue(any("Gate-2" in e for e in errors))

    def test_gate3_preflight_warns_when_shipped_status_still_in_inbox(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            inbox = root / "docs" / "requirements" / "inbox"
            inbox.mkdir(parents=True)
            req = inbox / "demo.md"
            req.write_text(
                "---\n状态: 已交付\n分级: 绿\n类型: 技术\n"
                "Gate-2: 状态:已验收；审批人:tester；2026-08-04\n---\n# demo\n",
                encoding="utf-8",
            )
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "INBOX_DIR", inbox.resolve()
            ), mock.patch.object(
                paths, "SHIPPED_DIR", (root / "docs" / "requirements" / "shipped").resolve()
            ):
                errors, warnings = closeout.gate3_preflight_issues(req)
            self.assertEqual(errors, [])
            self.assertTrue(any("Move-Item" in w or "请 Move" in w for w in warnings))

    def test_find_table_ignores_fenced_examples(self) -> None:
        fenced = """\
```markdown
| 能力/AC | 来源(Source) | 去向(Sink) |
|---|---|---|
| fake | 输入 | 输出 |
```
"""
        self.assertIsNone(markdown.find_table(fenced, ("来源", "去向")))
        self.assertIsNone(
            requirement.parse_closure_table(f"## 数据流闭环表\n{fenced}")
        )

    def test_ambiguity_issues_require_h2_verbatim_and_register(self) -> None:
        self.assertEqual(
            requirement.ambiguity_intake_issues("# 范围与切片（Gate-0）\n- AC-1：展示页签\n"),
            [
                "缺少「原始诉求」章节，无法核对 AC 是否改写了用户/PRD 原话",
                "缺少「歧义登记」结论，无法确认多义表述已经人工消歧",
            ],
        )

    def test_ambiguity_issues_accept_explicit_none_after_review(self) -> None:
        text = """\
# Gate-0 澄清与范围
## 原始诉求（verbatim，禁止改写）
> 点击菜单打开页签。

## 歧义登记
歧义登记: none（已逐句复核，触达面：菜单点击与页签状态；确认人:张三；日期:2026-07-29）
"""
        self.assertEqual(requirement.ambiguity_intake_issues(text), [])

    def test_ambiguity_none_rejects_generic_confirmer(self) -> None:
        text = """\
## 原始诉求（verbatim，禁止改写）
> 点击菜单打开页签。

## 歧义登记
歧义登记: none（确认人:用户；日期:2026-07-29）
"""
        self.assertEqual(
            requirement.ambiguity_intake_issues(text),
            ["`歧义登记: none` 缺少具体确认人"],
        )

    def test_ambiguity_issues_reject_bare_none_without_h2_section(self) -> None:
        text = """\
## 原始诉求（verbatim，禁止改写）
> 点击菜单打开页签。

歧义登记: none（确认人:张三；日期:2026-07-29）
"""
        self.assertEqual(
            requirement.ambiguity_intake_issues(text),
            ["缺少「歧义登记」结论，无法确认多义表述已经人工消歧"],
        )

    def test_ambiguity_issues_reject_empty_h2_sections(self) -> None:
        text = """\
## 原始诉求（verbatim，禁止改写）
## 歧义登记
"""
        issues = requirement.ambiguity_intake_issues(text)
        self.assertEqual(len(issues), 2)
        self.assertIn("缺少有效原始诉求内容", issues[0])
        self.assertIn("缺少有效结论", issues[1])

    def test_ambiguity_table_rejects_unclosed_conclusion_and_confirmation(self) -> None:
        text = """\
## 原始诉求（verbatim，禁止改写）
> 一个菜单一个页签。

## 歧义登记
| 原话片段 | 读法A | 读法B | 结论 | 确认人/日期 |
|---|---|---|---|---|
| 一个菜单一个页签 | 常驻页签 | 点击新增 | — | — |
"""
        issues = requirement.ambiguity_intake_issues(text)
        self.assertTrue(any("结论" in issue for issue in issues))
        self.assertTrue(any("确认人" in issue for issue in issues))
        self.assertTrue(any("日期" in issue for issue in issues))

    def test_ambiguity_table_accepts_complete_confirmed_rows(self) -> None:
        cases = (
            (
                "| 原话片段 | 读法A | 读法B | 结论 | 确认人/日期 |\n"
                "|---|---|---|---|---|\n"
                "| 一个菜单一个页签 | 常驻页签 | 点击新增 | 采用读法B | 张三；2026-07-29 |"
            ),
            (
                "| 原话片段 | 读法A | 读法B | 结论 | 确认人 | 日期 |\n"
                "|---|---|---|---|---|---|\n"
                "| 一个菜单一个页签 | 常驻页签 | 点击新增 | 采用读法B | 张三 | 2026-07-29 |"
            ),
        )
        for table in cases:
            with self.subTest(table=table.splitlines()[0]):
                text = f"""\
## 原始诉求（verbatim，禁止改写）
> 一个菜单一个页签。

## 歧义登记
{table}
"""
                self.assertEqual(requirement.ambiguity_intake_issues(text), [])

    def test_ambiguity_table_accepts_approver_column_with_name_and_date(self) -> None:
        section = """\
| 原话片段 | 读法A | 读法B | 结论 | 确认人 |
|---|---|---|---|---|
| 一个菜单一个页签 | 常驻页签 | 点击新增 | 采用读法B | meijianming；2026-07-28 |
"""
        self.assertEqual(requirement.ambiguity_table_issues(section), [])

    def test_ambiguity_table_rejects_approver_column_without_date(self) -> None:
        section = """\
| 原话片段 | 读法A | 读法B | 结论 | 确认人 |
|---|---|---|---|---|
| 一个菜单一个页签 | 常驻页签 | 点击新增 | 采用读法B | meijianming |
"""
        issues = requirement.ambiguity_table_issues(section)
        self.assertTrue(any("日期" in issue for issue in issues))

    def test_ambiguity_table_requires_conclusion_and_confirmation_columns(self) -> None:
        text = """\
## 原始诉求（verbatim，禁止改写）
> 一个菜单一个页签。

## 歧义登记
| 原话片段 | 读法A | 读法B |
|---|---|---|
| 一个菜单一个页签 | 常驻页签 | 点击新增 |
"""
        issues = requirement.ambiguity_intake_issues(text)
        self.assertTrue(any("缺少必要列" in issue for issue in issues))

    def test_ambiguity_issues_accept_h1_verbatim_section(self) -> None:
        text = """\
# 原始诉求（verbatim，禁止改写）
> 点击菜单打开页签。

## 歧义登记
歧义登记: none（确认人:张三；日期:2026-07-29）
"""
        self.assertEqual(requirement.ambiguity_intake_issues(text), [])

    def test_all_requirement_timestamps_enforce_ambiguity_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 旧时间戳需求
状态: 待处理
分级: 绿
类型: 技术
---
# 旧时间戳需求
# Gate-0 澄清与范围
## 数据流闭环表
| 能力/AC | 来源(Source) | 加工(Process) | 去向(Sink) | 闭环 |
|---|---|---|---|---|
| AC-1 | 输入 | 校验 | 输出 | 已确认 |
"""
            req = _write(Path(tmp), "20260720100730-旧时间戳需求.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green"), 1)

    def test_pending_ambiguity_register_blocks_intake(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 调整页签交互
状态: 待处理
分级: 绿-轻量
类型: 技术
---
# Gate-0 澄清与范围
## 原始诉求（verbatim，禁止改写）
> 一个菜单一个页签。

## 歧义登记
| 原话片段 | 读法A | 读法B | 消歧证据 | 结论 | 确认人 |
|---|---|---|---|---|---|
| 一个菜单一个页签 | 四项常驻 | 点击后新增 | — | [待确认] | — |

本需求无新增数据流（green-trivial）。
"""
            req = _write(Path(tmp), "20260720100730-调整页签交互.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green-trivial"), 1)

    def test_intake_rejects_english_filename(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            req = _write(Path(tmp), "20260720100730-import-batch.md", "# stub\n")
            self.assertEqual(pg._run_check_intake(str(req), "green"), 1)

    def test_intake_accepts_timestamp_name_but_fails_missing_closure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = "---\n标题: 用户导入\n状态: 待处理\n---\n\n# 范围\n无闭环表。\n"
            req = _write(Path(tmp), "20260720100730-用户导入批量校验.md", body)
            # 命名合规（时间戳+中文），但缺数据流闭环表 → Gate-0 不通过
            self.assertEqual(pg._run_check_intake(str(req), "green"), 1)

    def test_intake_rejects_legacy_three_digit_name(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            req = _write(Path(tmp), "010-用户导入批量校验.md", "# stub\n")
            with mock.patch("builtins.print") as printer:
                self.assertEqual(pg._run_check_intake(str(req), "green"), 1)
            output = "\n".join(str(call.args[0]) for call in printer.call_args_list)
            self.assertIn("只接受 14 位时间戳", output)

    def test_intake_rejects_legacy_three_digit_name_in_shipped(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            req = _write(
                Path(tmp),
                "docs/requirements/shipped/010-用户导入批量校验.md",
                "# stub\n",
            )
            with mock.patch("builtins.print") as printer:
                self.assertEqual(pg._run_check_intake(str(req), "green"), 1)
            output = "\n".join(str(call.args[0]) for call in printer.call_args_list)
            self.assertIn("只接受 14 位时间戳", output)

    def test_open_deviation_detected_without_original_word_in_header(self) -> None:
        text = """\
| 偏离单号 | 差异点 | 建议方案 | 审批 |
|---|---|---|---|
| DEV-001 | 标签位置不同 | 以原型为准 | open |
"""
        self.assertEqual(
            requirement.open_deviation_tickets(text),
            [("(未命名页面/能力)", "DEV-001", "open")],
        )

    def test_gate_ordered_template_sample_passes_intake_and_plan(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 需求模板重排
状态: 待处理
负责人: 张三
创建时间: 2026-07-26
分级: 绿
类型: 技术
openspec变更:
分级理由: 未命中 red 触发器
类型判型结论: 技术；流程文档调整
DDD主类: D
Gate-0: 状态:已通过；审批人:张三；2026-07-26
Gate-1: 状态:待批准；审批人:张三；2026-07-26
Gate-2: 状态:待验收；审批人:张三；2026-07-26
---
# 需求模板重排

# Gate-0 澄清与范围

## 原始诉求（verbatim，禁止改写）
> 将需求模板按 Gate 重排。

## 歧义登记
歧义登记: none（已逐句复核，触达面：需求模板；确认人:张三；日期:2026-07-26）

## 业务目标
不适用（类型=技术）

## 用例 / 用户故事
不适用（类型=技术）

## 范围与切片
- 模板按 Gate 排序

## 约束引用
约束引用: none（已检索，触达面：流程文档）

## 数据流闭环表
| 能力 | 来源(Source) | 加工(Process) | 去向(Sink) | 闭环 |
|---|---|---|---|---|
| 模板按 Gate 排序 | 现有模板 | 章节重排 | 新模板 | 已确认 |

## 原型对齐与偏离
> 审批取值：open / approved / rejected；无偏离填 `—`。
| 偏离单号 | 原型差异点 | 建议方案 | 审批 |
|---|---|---|---|
| — | — | — | — |

# Gate-1 方案与验收

## 验收标准
- [ ] **AC-1**：GIVEN 旧模板 WHEN 按 Gate 重排 THEN 四 H1 顺序正确
  - **反例（本 AC 排除）**：仅改文案未改结构

## 实现方案
- 复用映射 / 代码落点：`.cursor/templates/requirements/requirements-template.md`
- 切片拆解：
  1. [AC-1] 重排模板
- 回归验证点：`python -m pytest .cursor/hooks/tests -q`

# Gate-2 验收
## 验收记录
- 待验收

# Gate-3 知识同步
## 实现记录与沉淀
- Living Docs: no-op
"""
            req = _write(Path(tmp), "20260720100730-需求模板重排.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green"), 0)
            self.assertEqual(pg._run_check_plan(str(req), "green"), 0)

    def test_defect_green_accepts_explicit_no_new_dataflow(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 修复用户列表空白
状态: 待处理
负责人: 张三
创建时间: 2026-07-26
分级: 绿
类型: 缺陷
分级理由: 单点修复
类型判型结论: 缺陷；不改变业务能力
DDD主类: D
Gate-0: 状态:已通过；审批人:张三；2026-07-26
Gate-1: 状态:待批准；审批人:张三；2026-07-26
Gate-2: 状态:待验收；审批人:张三；2026-07-26
---
# 修复用户列表空白

# Gate-0 澄清与范围
## 原始诉求（verbatim，禁止改写）
> 修复用户列表空白。

## 歧义登记
歧义登记: none（确认人:张三；日期:2026-07-26）

## 业务目标
不适用（类型=缺陷）

## 用例 / 用户故事
不适用（类型=缺陷）

## 范围与切片
- 修复用户列表空白

## 约束引用
约束引用: none

## 数据流闭环表
缺陷修复无新增数据流。

## 原型对齐与偏离
- 无

# Gate-1 方案与验收
## 验收标准
- [ ] **AC-1**：修复后列表非空
  - **反例（本 AC 排除）**：仅改文案未修查询

## 实现方案
- 复用映射 / 代码落点：`frontend/src`
- 切片拆解：
  1. [AC-1] 修复空白
- 回归验证点：`cd frontend && npm run build`

# Gate-2 验收
## 验收记录
- 待验收

# Gate-3 知识同步
## 实现记录与沉淀
- Living Docs: no-op
"""
            req = _write(Path(tmp), "20260720100730-修复用户列表空白.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green"), 0)

    def test_green_trivial_accepts_no_new_dataflow_wording(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 调整提示文案
状态: 待处理
负责人: 张三
创建时间: 2026-07-26
分级: 绿-轻量
类型: 技术
分级理由: 文案微调
类型判型结论: 技术；无业务语义
DDD主类: D
Gate-0: 状态:已通过；审批人:张三；2026-07-26
Gate-1: 状态:待批准；审批人:张三；2026-07-26
Gate-2: 状态:待验收；审批人:张三；2026-07-26
---
# 调整提示文案

# Gate-0 澄清与范围
## 原始诉求（verbatim，禁止改写）
> 调整提示文案。

## 歧义登记
歧义登记: none（确认人:张三；日期:2026-07-26）

## 业务目标
不适用（类型=技术）

## 用例 / 用户故事
不适用（类型=技术）

## 范围与切片
- 调整提示文案

## 约束引用
约束引用: none

## 数据流闭环表
本需求无新增数据流（green-trivial）。

## 原型对齐与偏离
- 无

# Gate-1 方案与验收
## 验收标准
不适用（green-trivial）

## 实现方案
- 回归验证点：`cd frontend && npm run build`

# Gate-2 验收
## 验收记录
- 待验收

# Gate-3 知识同步
## 实现记录与沉淀
- Living Docs: no-op
"""
            req = _write(Path(tmp), "20260720100730-调整提示文案.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green-trivial"), 0)

    def test_defect_guidance_text_does_not_bypass_closure_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 修复用户列表空白
状态: 待处理
分级: 绿
类型: 缺陷
---
# 修复用户列表空白

> 无新增数据流的缺陷可声明 `缺陷修复无新增数据流`。
"""
            req = _write(Path(tmp), "20260720100730-修复用户列表空白.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green"), 1)

    def test_no_dataflow_negation_is_not_a_declaration(self) -> None:
        self.assertFalse(requirement.has_no_new_dataflow_declaration("本需求并非无新增数据流。"))

    def test_green_trivial_does_not_bypass_pending_confirmation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 调整提示文案
状态: 待处理
分级: 绿-轻量
类型: 技术
---
# 调整提示文案

本需求无新增数据流（green-trivial）。
- OQ-001：是否调整全部页面 → 结论：[待确认]
"""
            req = _write(Path(tmp), "20260720100730-调整提示文案.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green-trivial"), 1)

    def test_green_trivial_does_not_bypass_open_deviation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 调整提示文案
状态: 待处理
分级: 绿-轻量
类型: 技术
---
# 调整提示文案

本需求无新增数据流（green-trivial）。

| 偏离单号 | 原型差异点 | 建议方案 | 审批 |
|---|---|---|---|
| DEV-001 | 标签位置不同 | 跟随原型 | open |
"""
            req = _write(Path(tmp), "20260720100730-调整提示文案.md", body)
            self.assertEqual(pg._run_check_intake(str(req), "green-trivial"), 1)


class PlanCheckTests(unittest.TestCase):
    def test_plan_delegates_gate1_approval_to_shared_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 共享审批判定
状态: 待处理
分级: 绿
类型: 技术
Gate-1: 状态:共享判定；审批人:张三；2026-07-29
---
## 验收标准
- [ ] **AC-1**：共享判定可用
  - **反例（本 AC 排除）**：判定被绕过
## 实现方案
- 复用映射：`guardlib.requirement`
- 切片拆解：
  1. 使用共享 Gate-1 判定
- 回归验证点：`python -m pytest`
"""
            req = _write(Path(tmp), "20260729111600-共享审批判定.md", body)
            with mock.patch.object(gp, "gate1_is_approved", return_value=(True, "")) as shared:
                self.assertEqual(pg._run_check_plan(str(req), "green"), 0)
            shared.assert_called_once()

    def test_plan_red_skips_when_openspec_package_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            change = root / "docs" / "openspec" / "changes" / "sample-red-change"
            (change / "specs" / "demo").mkdir(parents=True)
            (change / "proposal.md").write_text("# proposal\n", encoding="utf-8")
            (change / "tasks.md").write_text("# tasks\n", encoding="utf-8")
            (change / "specs" / "demo" / "spec.md").write_text("# spec\n", encoding="utf-8")
            body = """\
---
标题: 红档需求
状态: 待处理
分级: 红
类型: 业务
openspec变更: sample-red-change
Gate-1: 状态:待批准
---
# 红档需求
红档走 OpenSpec。
"""
            req = _write(root, "docs/requirements/inbox/20260720100730-红档需求.md", body)
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "CHANGES_DIR", root / "docs" / "openspec" / "changes"
            ):
                self.assertEqual(pg._run_check_plan(str(req), "red"), 0)

    def test_plan_red_without_package_requires_gate1_content(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 红档无包
状态: 待处理
分级: 红
类型: 业务
openspec变更: missing-change
Gate-1: 状态:待批准
---
# 红档无包
## 实现方案
- 红档以 OpenSpec 产物为准（黄档无）
"""
            req = _write(Path(tmp), "20260720100730-红档无包.md", body)
            self.assertEqual(pg._run_check_plan(str(req), "red"), 1)

    def test_plan_rejects_missing_acceptance_criteria(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 缺验收标准
状态: 待处理
分级: 绿
类型: 技术
Gate-1: 状态:待批准
---
## 实现方案
- 复用映射 / 代码落点：`src/a.py`
- 切片拆解：
  1. 做一件事
- 回归验证点：`python -m pytest`
"""
            req = _write(Path(tmp), "20260720100730-缺验收标准.md", body)
            self.assertEqual(pg._run_check_plan(str(req), "green"), 1)

    def test_plan_rejects_acceptance_without_counterexample(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 缺反例
状态: 待处理
分级: 绿
类型: 技术
Gate-1: 状态:待批准
---
## 验收标准
- [ ] **AC-1**：GIVEN a WHEN b THEN c
## 实现方案
- 复用映射 / 代码落点：`src/a.py`
- 切片拆解：
  1. [AC-1] 实现
- 回归验证点：`python -m pytest`
"""
            req = _write(Path(tmp), "20260720100730-缺反例.md", body)
            self.assertEqual(pg._run_check_plan(str(req), "green"), 1)

    def test_plan_green_missing_plan_section_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            req = _write(Path(tmp), "20260720100730-绿档需求.md", "# 需求\n无实现方案章节。\n")
            self.assertEqual(pg._run_check_plan(str(req), "green"), 1)

    def test_green_trivial_uses_implementation_plan_for_verify_steps(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 文档微调
状态: 待处理
分级: 绿-轻量
类型: 技术
分级理由: 文档微调
类型判型结论: 技术；无业务语义
DDD主类: D
Gate-0: 状态:已通过；审批人:张三；2026-07-26
Gate-1: 状态:待批准；审批人:张三；2026-07-26
Gate-2: 状态:待验收；审批人:张三；2026-07-26
---
# 文档微调
本需求无数据流（green-trivial）

# Gate-1 实现方案
## 实现方案
- 回归验证点：`python -m pytest`
"""
            req = _write(Path(tmp), "20260720100730-文档微调.md", body)
            self.assertEqual(pg._run_check_plan(str(req), "green-trivial"), 0)

    def test_green_trivial_checks_both_verify_sections_when_both_exist(self) -> None:
        text = """\
# Gate-1 实现方案
## 实施与验证
仅记录手动说明。

## 实现方案
- 回归验证点：`python -m pytest`
"""
        self.assertTrue(requirement.green_trivial_has_verify_steps(text))

    def test_plan_slice_table_with_ac_mapping_is_valid(self) -> None:
        text = """\
- 切片拆解：

| 切片 | 覆盖 AC | 代码落点 | 验证命令 |
|---|---|---|---|
| 最小改动 | AC-1 | `src/example.py` | `python -m pytest` |
"""
        self.assertTrue(requirement.plan_has_slice_items(text))

    def test_green_trivial_still_requires_gate1_status(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 文档微调
状态: 待处理
分级: 绿-轻量
类型: 技术
---
# 文档微调

本需求无数据流（green-trivial）

# Gate-1 实现方案
## 实现方案
- 回归验证点：`python -m pytest`
"""
            req = _write(Path(tmp), "20260720100730-文档微调.md", body)
            self.assertEqual(pg._run_check_plan(str(req), "green-trivial"), 1)


class RequirementHeadingStructureTests(unittest.TestCase):
    @staticmethod
    def valid_structure() -> str:
        return """\
# 示例需求
# Gate-0 澄清与范围
## 原始诉求（verbatim）
## 歧义登记
## 业务目标
## 用例 / 用户故事
## 范围与切片
## 约束引用
## 数据流闭环表
## 原型对齐与偏离
## 可选补充
# Gate-1 方案与验收
## 验收标准
## 实现方案
# Gate-2 验收
## 验收记录（一屏验收包）
# Gate-3 知识同步
## 实现记录与沉淀
"""

    def test_valid_structure_allows_gate_suffixes_and_optional_h2(self) -> None:
        self.assertEqual(requirement.requirement_structure_issues(self.valid_structure()), [])

    def test_isolated_h2_is_rejected(self) -> None:
        issues = requirement.requirement_structure_issues("## 原始诉求\n")
        self.assertTrue(any("第一个 H1" in issue for issue in issues))
        self.assertTrue(any("Gate-0 → Gate-1 → Gate-2 → Gate-3" in issue for issue in issues))
        self.assertTrue(any("Gate 之外" in issue for issue in issues))

    def test_missing_or_out_of_order_gates_are_rejected(self) -> None:
        missing = self.valid_structure().replace("# Gate-2 验收\n## 验收记录（一屏验收包）\n", "")
        out_of_order = self.valid_structure().replace(
            "# Gate-1 方案与验收\n## 验收标准\n## 实现方案\n# Gate-2 验收\n## 验收记录（一屏验收包）",
            "# Gate-2 验收\n## 验收记录（一屏验收包）\n# Gate-1 方案与验收\n## 验收标准\n## 实现方案",
        )
        for name, text in (("missing", missing), ("out-of-order", out_of_order)):
            with self.subTest(case=name):
                issues = requirement.requirement_structure_issues(text)
                self.assertTrue(any("Gate-0 → Gate-1 → Gate-2 → Gate-3" in issue for issue in issues))

    def test_extra_h1_is_rejected(self) -> None:
        text = self.valid_structure().replace("# Gate-2 验收", "# 额外一级标题\n# Gate-2 验收")
        issues = requirement.requirement_structure_issues(text)
        self.assertTrue(any("不允许额外 H1" in issue for issue in issues))

    def test_required_h2_under_wrong_gate_is_rejected(self) -> None:
        text = self.valid_structure().replace(
            "## 原型对齐与偏离\n## 可选补充\n# Gate-1 方案与验收\n## 验收标准\n## 实现方案",
            "## 原型对齐与偏离\n## 实现方案\n## 可选补充\n# Gate-1 方案与验收\n## 验收标准",
        )
        issues = requirement.requirement_structure_issues(text)
        self.assertIn("H2「实现方案」必须位于 Gate-1，实际位于 Gate-0", issues)
        self.assertIn("Gate-1 缺少必需 H2「实现方案」", issues)

    def test_acceptance_criteria_must_live_under_gate1(self) -> None:
        text = self.valid_structure().replace(
            "## 原型对齐与偏离\n## 可选补充\n# Gate-1 方案与验收\n## 验收标准\n## 实现方案",
            "## 原型对齐与偏离\n## 验收标准\n## 可选补充\n# Gate-1 方案与验收\n## 实现方案",
        )
        issues = requirement.requirement_structure_issues(text)
        self.assertIn("H2「验收标准」必须位于 Gate-1，实际位于 Gate-0", issues)
        self.assertIn("Gate-1 缺少必需 H2「验收标准」", issues)

    def test_duplicate_required_h2_is_rejected(self) -> None:
        text = self.valid_structure().replace(
            "## 原始诉求（verbatim）",
            "## 原始诉求（verbatim）\n## 原始诉求（二次副本）",
        )
        self.assertIn(
            "Gate-0 H2「原始诉求」重复 2 次",
            requirement.requirement_structure_issues(text),
        )

    def test_fenced_fake_headings_do_not_satisfy_structure(self) -> None:
        text = f"""\
```markdown
{self.valid_structure()}
```
"""
        issues = requirement.requirement_structure_issues(text)
        self.assertTrue(any("第一个 H1" in issue for issue in issues))
        self.assertTrue(any("Gate-0 → Gate-1 → Gate-2 → Gate-3" in issue for issue in issues))

    def test_intake_collector_blocks_invalid_structure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            body = """\
---
标题: 示例需求
状态: 待处理
负责人: 张三
创建时间: 2026-07-29
分级: 绿
类型: 技术
Gate-0: 状态:已通过；审批人:张三；2026-07-29
Gate-1: 状态:待批准；审批人:张三；2026-07-29
Gate-2: 状态:待验收；审批人:张三；2026-07-29
---
## 原始诉求
"""
            req = _write(Path(tmp), "20260729120000-示例需求.md", body)
            output = io.StringIO()
            with redirect_stdout(output):
                rc = pg._run_check_intake(str(req), "green")

        self.assertEqual(rc, 1)
        self.assertIn("需求标题结构不合规", output.getvalue())
        self.assertIn("第一个 H1", output.getvalue())

    def test_intake_rejects_fenced_only_closure_table(self) -> None:
        table = """\
```markdown
| 能力/AC | 来源(Source) | 加工(Process) | 去向(Sink) | 闭环 |
|---|---|---|---|---|
| AC-1 | 输入 | 校验 | 输出 | 已确认 |
```
"""
        body = (
            "---\n标题: 示例需求\n状态: 待处理\n负责人: 张三\n创建时间: 2026-07-29\n"
            "分级: 绿\n类型: 技术\nGate-0: 状态:已通过；审批人:张三；2026-07-29\n"
            "Gate-1: 状态:待批准；审批人:张三；2026-07-29\n"
            "Gate-2: 状态:待验收；审批人:张三；2026-07-29\n---\n"
            + self.valid_structure().replace("## 数据流闭环表", f"## 数据流闭环表\n{table}")
        )
        with tempfile.TemporaryDirectory() as tmp:
            req = _write(Path(tmp), "20260729120000-示例需求.md", body)
            output = io.StringIO()
            with redirect_stdout(output):
                rc = pg._run_check_intake(str(req), "green")

        self.assertEqual(rc, 1)
        self.assertIn("未找到「数据流闭环表」", output.getvalue())


class RequirementTemplateStructureTests(unittest.TestCase):
    TEMPLATE_PATHS = (
        ".cursor/templates/requirements/requirements-template.md",
        ".cursor/templates/requirements/technical-requirement-template.md",
        ".cursor/templates/requirements/defect-template.md",
        ".cursor/skills/xijia-project-init/templates/docs/requirements/inbox-seed/backend-bootstrap.md.tmpl",
        ".cursor/skills/xijia-project-init/templates/docs/requirements/inbox-seed/frontend-bootstrap.md.tmpl",
        ".cursor/skills/xijia-project-init/templates/docs/requirements/inbox-seed/runtime-baseline.md.tmpl",
    )

    GATE_TEMPLATE_PATHS = (
        ".cursor/templates/requirements/gate0-intake.md",
        ".cursor/templates/requirements/gate1-plan-template.md",
        ".cursor/templates/requirements/gate1-by-tier.md",
        ".cursor/templates/requirements/section-fragments.md",
    )

    def test_general_technical_and_defect_templates_pass_structure_validator(self) -> None:
        for rel in (
            ".cursor/templates/requirements/requirements-template.md",
            ".cursor/templates/requirements/technical-requirement-template.md",
            ".cursor/templates/requirements/defect-template.md",
        ):
            with self.subTest(template=rel):
                text = (paths.ROOT / rel).read_text(encoding="utf-8")
                self.assertEqual(requirement.requirement_structure_issues(text), [])

    def test_general_requirement_template_contains_ambiguity_and_evidence_gates(self) -> None:
        rel = ".cursor/templates/requirements/requirements-template.md"
        text = (paths.ROOT / rel).read_text(encoding="utf-8")
        self.assertIn("## 原始诉求（verbatim，禁止改写）", text)
        self.assertIn("## 歧义登记", text)
        self.assertIn("## 业务目标", text)
        self.assertIn("## 用例 / 用户故事", text)
        self.assertIn("## 验收标准", text)
        acceptance = markdown.extract_section(text, "验收标准") or ""
        self.assertIn("反例（本 AC 排除）", acceptance)
        self.assertIn("交互语义", text)
        self.assertIn("证据（类型 + 出处）", text)

    def test_gate_templates_exist(self) -> None:
        for rel in self.GATE_TEMPLATE_PATHS:
            with self.subTest(template=rel):
                self.assertTrue((paths.ROOT / rel).is_file(), rel)

    def test_template_has_gate_order_and_no_duplicate_top_level_sections(self) -> None:
        expected = (
            "## 业务目标",
            "## 用例",
            "## 范围与切片",
            "## 数据流闭环表",
            "## 原型对齐与偏离",
            "## 验收标准",
            "## 实现方案",
            "## 验收记录",
            "## 实现记录与沉淀",
        )
        for rel in self.TEMPLATE_PATHS:
            with self.subTest(template=rel):
                text = (paths.ROOT / rel).read_text(encoding="utf-8")
                top_level = re.findall(r"^#\s+(.+)$", text, re.MULTILINE)
                self.assertEqual(len(top_level), 5)
                self.assertFalse(top_level[0].startswith("Gate-"))
                self.assertEqual(
                    [heading.split()[0] for heading in top_level[1:]],
                    ["Gate-0", "Gate-1", "Gate-2", "Gate-3"],
                )
                gate_matches = [
                    re.search(rf"(?m)^{re.escape(heading)}(?:\s|$)", text)
                    for heading in ("# Gate-0", "# Gate-1", "# Gate-2", "# Gate-3")
                ]
                self.assertTrue(all(gate_matches))
                gate_positions = [match.start() for match in gate_matches if match]
                self.assertEqual(gate_positions, sorted(gate_positions))
                section_matches = [
                    re.search(rf"(?m)^{re.escape(heading)}(?:\s|（|$)", text)
                    for heading in expected
                ]
                self.assertTrue(all(section_matches))
                positions = [match.start() for match in section_matches if match]
                self.assertEqual(positions, sorted(positions))
                for marker in (
                    "Experience Reuse:",
                    "Capability Index:",
                    "Living Docs:",
                    "Flow:",
                    "Patterns:",
                    "Pitfalls:",
                ):
                    self.assertRegex(text, rf"(?m)^-\s+{re.escape(marker)}")
                self.assertNotIn("\n# Gate 台账", text)
                self.assertNotIn("\n# 目标与非目标", text)
                self.assertNotIn("\n# 任务分解", text)
                self.assertNotIn("\n# 验收标准", text)
                self.assertNotIn("\n# 附录", text)
                self.assertNotIn("类型判型矩阵", text)
                self.assertNotIn("PRD现状对照（Step 1.7）", text)
                self.assertNotIn("Spike 探针记录", text)

    def test_all_new_requirement_templates_use_gate_properties(self) -> None:
        for rel in self.TEMPLATE_PATHS:
            with self.subTest(template=rel):
                text = (paths.ROOT / rel).read_text(encoding="utf-8")
                frontmatter = requirement.parse_frontmatter_block(text) or {}
                for gate in ("gate-0", "gate-1", "gate-2"):
                    self.assertIn(gate, frontmatter)
                for key in ("分级理由", "类型判型结论", "ddd主类"):
                    self.assertIn(key, frontmatter)
                self.assertNotIn("\n# Gate 台账", text)
                self.assertNotIn("\n# 分级与判型", text)


class GatePropertiesTests(unittest.TestCase):
    @staticmethod
    def canonical_frontmatter(**overrides: str | None) -> str:
        fields: dict[str, str | None] = {
            "标题": "元数据校验",
            "状态": "待处理",
            "负责人": "张三",
            "创建时间": "2026-07-29",
            "分级": "绿",
            "类型": "技术",
            "Gate-0": "状态:已通过；审批人:张三；2026-07-29",
            "Gate-1": "状态:待批准；审批人:张三；2026-07-29",
            "Gate-2": "状态:待验收；审批人:张三；2026-07-29",
            "openspec变更": "",
        }
        fields.update(overrides)
        lines = ["---", *(f"{key}: {value}" for key, value in fields.items() if value is not None), "---"]
        return "\n".join(lines)

    def test_intake_rejects_missing_canonical_type(self) -> None:
        result = gi._intake_issues(self.canonical_frontmatter(类型=None), "green")
        self.assertEqual(result.exit_code, 1)
        self.assertTrue(any("缺少必填项 `类型`" in message for message in result.messages))

    def test_intake_rejects_missing_canonical_status(self) -> None:
        result = gi._intake_issues(self.canonical_frontmatter(状态=None), "green")
        self.assertEqual(result.exit_code, 1)
        self.assertTrue(any("缺少必填项 `状态`" in message for message in result.messages))

    def test_intake_rejects_red_without_openspec_change(self) -> None:
        result = gi._intake_issues(
            self.canonical_frontmatter(分级="红", openspec变更=""),
            "red",
        )
        self.assertEqual(result.exit_code, 1)
        self.assertTrue(any("缺少必填项 `openspec变更`" in message for message in result.messages))

    def test_frontmatter_requires_strict_delimiter_lines(self) -> None:
        for opening in ("---oops", "----"):
            with self.subTest(opening=opening):
                self.assertIsNone(markdown.parse_frontmatter(f"{opening}\n分级: 红\n---\n"))
        self.assertIsNone(markdown.parse_frontmatter("---\n分级: 红\n---oops\n----\n"))

    def test_frontmatter_duplicate_keys_raise_clear_error(self) -> None:
        cases = (
            ("分级", "---\n分级: 绿\n分级: 红\n---\n"),
            ("gate-0", "---\nGate-0: 状态:已通过\nGate-0: 状态:部分通过\n---\n"),
        )
        for key, text in cases:
            with self.subTest(key=key):
                with self.assertRaises(markdown.FrontmatterError) as caught:
                    markdown.parse_frontmatter(text)
                self.assertEqual(caught.exception.key, key)

    def test_pipeline_cli_reports_duplicate_frontmatter_without_traceback(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            req = _write(
                Path(tmp),
                "20260729120000-重复分级.md",
                "---\n分级: 绿\n分级: 红\n---\n# 重复分级\n",
            )
            output = io.StringIO()
            argv = ["pipeline_guard.py", "--check-intake", "--req", str(req)]
            with mock.patch.object(sys, "argv", argv), redirect_stdout(output):
                rc = pg.main()

        self.assertEqual(rc, 1)
        self.assertIn("frontmatter 不合规", output.getvalue())
        self.assertIn("重复键 '分级'", output.getvalue())
        self.assertNotIn("Traceback", output.getvalue())

    def test_requirement_metadata_accepts_canonical_yaml_keys_only(self) -> None:
        aliases = """\
---
tier: red
type: business
status: inbox
openspec_change: change-a
---
"""
        self.assertIsNone(requirement.parse_frontmatter_tier(aliases))
        self.assertIsNone(requirement.parse_frontmatter_type(aliases))
        self.assertIsNone(requirement.parse_frontmatter_status(aliases))
        self.assertIsNone(requirement.parse_frontmatter_openspec_change(aliases))

        canonical = """\
---
分级: 红
类型: 业务
状态: 待处理
openspec变更: change-a
---
"""
        self.assertEqual(requirement.parse_frontmatter_tier(canonical), "red")
        self.assertEqual(requirement.parse_frontmatter_type(canonical), "business")
        self.assertEqual(requirement.parse_frontmatter_status(canonical), "inbox")
        self.assertEqual(requirement.parse_frontmatter_openspec_change(canonical), "change-a")

    def test_red_requirement_requires_frontmatter_red_tier(self) -> None:
        body_table = """\
| 项 | 值 |
|---|---|
| 分级 | 红 |
"""
        emoji = "# 需求\n🔴 红档需求\n"
        frontmatter = "---\n分级: 红\n类型: 技术\n---\n# 需求\n"

        self.assertFalse(requirement.is_red_requirement_text(body_table))
        self.assertFalse(requirement.is_red_requirement_text(emoji))
        self.assertTrue(requirement.is_red_requirement_text(frontmatter))

    def test_red_requirements_only_lists_frontmatter_red(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            inbox = Path(tmp)
            _write(inbox, "20260729100000-正文红档.md", "| 分级 | 红 |\n🔴\n")
            _write(inbox, "20260729100001-属性红档.md", "---\n分级: 红\n---\n")
            with mock.patch.object(paths, "INBOX_DIR", inbox):
                self.assertEqual(requirement.red_requirements(), ["20260729100001-属性红档"])

    def test_inbox_active_requirements_uses_frontmatter_completion_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                "docs/requirements/inbox/20260729100000-正文验收.md",
                "# 需求\nGate-2: 状态:已验收；审批人:张三；2026-07-29\n",
            )
            _write(
                root,
                "docs/requirements/inbox/20260729100001-属性验收.md",
                "---\nGate-2: 状态:已验收；审批人:张三；2026-07-29\n---\n# 需求\n",
            )
            _write(
                root,
                "docs/requirements/inbox/20260729100002-已交付.md",
                "---\n状态: 已交付\n---\n# 需求\n",
            )
            from guardlib import livingdocs
            with mock.patch.object(paths, "ROOT", root):
                self.assertEqual(
                    livingdocs.inbox_active_requirements(),
                    ["docs/requirements/inbox/20260729100000-正文验收.md"],
                )

    def test_frontmatter_parser_accepts_utf8_bom(self) -> None:
        text = "\ufeff---\n标题: 中文需求\nGate-0: 状态:已通过；审批人:张三；2026-07-28\n---\n"
        frontmatter = requirement.parse_frontmatter_block(text)
        self.assertIsNotNone(frontmatter)
        assert frontmatter is not None
        self.assertEqual(frontmatter["标题"], "中文需求")
        self.assertEqual(requirement.parse_gate_records(text)["Gate-0"]["status"], "已通过")

    def test_utf8_reader_strips_bom_and_rejects_invalid_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            bom_file = root / "bom.md"
            bom_file.write_bytes(('\ufeff---\nGate-0: 状态:已通过\n---\n'.encode('utf-8')))
            self.assertTrue(paths.read_utf8_text(bom_file).startswith("---"))

            invalid_file = root / "invalid.md"
            invalid_file.write_bytes(b"---\n\xff\n---\n")
            with self.assertRaises(UnicodeDecodeError):
                paths.read_utf8_text(invalid_file)

    def test_resolve_gate_reports_invalid_utf8(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = root / "invalid.md"
            req.write_bytes(b"---\n\xff\n---\n")
            with mock.patch.object(paths, "ROOT", root), mock.patch("builtins.print") as printer:
                result = pg._run_resolve_gate("invalid.md")
            self.assertEqual(result, 2)
            output = "\n".join(str(call.args[0]) for call in printer.call_args_list)
            self.assertIn("不是有效 UTF-8", output)

    def test_parse_gate_records_from_frontmatter_properties(self) -> None:
        text = """\
---
Gate-0: 状态:已通过；审批人:张三；2026-07-26
Gate-1: 状态:已批准；审批人:李四；2026-07-27
Gate-2: 状态:已验收；审批人:王五；2026-07-28
---
"""
        records = requirement.parse_gate_records(text)
        self.assertEqual(records["Gate-0"]["status"], "已通过")
        self.assertEqual(records["Gate-1"]["approver"], "李四")
        self.assertEqual(records["Gate-2"]["date"], "2026-07-28")

    def test_frontmatter_gate_properties_ignore_body_table(self) -> None:
        text = """\
---
Gate-1: 状态:已批准 | 审批人:张三 | 2026-07-26
---
| 项 | 值 |
|---|---|
| Gate-1 | 状态:待批准；审批人:旧审批人；2026-07-20 |
"""
        records = requirement.parse_gate_records(text)
        self.assertEqual(records["Gate-1"]["status"], "已批准")
        self.assertEqual(records["Gate-1"]["approver"], "张三")

    def test_body_gate_table_is_not_supported(self) -> None:
        text = """\
| 项 | 值 |
|---|---|
| Gate-0 | 状态:已通过；审批人:张三；2026-07-26 |
"""
        records = requirement.parse_gate_records(text)
        self.assertEqual(records, {})

    def test_resolve_tier_ignores_body_table(self) -> None:
        text = """\
| 项 | 值 |
|---|---|
| 分级 | 黄 |
"""
        tier, issues = requirement.resolve_tier(text, "")
        self.assertIsNone(tier)
        self.assertEqual(issues, ["未找到分级（YAML properties `分级` / CLI --tier 均缺失）"])

    def test_technical_classification_accepts_property_markers(self) -> None:
        text = """\
---
类型: 技术
类型判型结论: 技术；仅工程壳层
DDD主类: D
---
"""
        self.assertEqual(requirement.type_classification_intake_warnings(text), [])

    def test_defect_type_is_normalized_and_english_value_is_rejected(self) -> None:
        self.assertEqual(requirement.parse_frontmatter_type("---\n类型: 缺陷\n---\n"), "defect")
        self.assertEqual(
            requirement.frontmatter_language_issues("---\n类型: defect\n---\n"),
            ["类型 值 'defect' 非中文（请改为 '缺陷'）"],
        )

    def test_gate_english_status_triggers_frontmatter_language_warning(self) -> None:
        issues = requirement.frontmatter_language_issues(
            "---\nGate-0: 状态:complete\nGate-1: 状态:approved\nGate-2: 状态:accepted\n---\n"
        )
        self.assertIn("Gate-0 状态 'complete' 非中文（请改为 '已通过'）", issues)
        self.assertIn("Gate-1 状态 'approved' 非中文（请改为 '已批准'）", issues)
        self.assertIn("Gate-2 状态 'accepted' 非中文（请改为 '已验收'）", issues)

    def test_gate0_chinese_status_helpers(self) -> None:
        passed = requirement.parse_gate_cell("状态:已通过；审批人:张三；2026-07-30")
        partial = requirement.parse_gate_cell("状态:部分通过；审批人:张三；2026-07-30")
        pending = requirement.parse_gate_cell("状态:待确认")
        self.assertTrue(requirement.gate0_is_complete(passed, "待处理")[0])
        self.assertFalse(requirement.gate0_is_complete(partial, "待处理")[0])
        self.assertTrue(requirement.gate0_is_complete(partial, "shipped")[0])
        self.assertFalse(requirement.gate0_is_complete(pending, "待处理")[0])
        self.assertTrue(requirement.gate0_is_partial(partial))
        self.assertTrue(requirement.gate_is_signed(passed, gate_name="Gate-0"))
        self.assertFalse(requirement.gate_is_signed(partial, gate_name="Gate-0"))
        self.assertFalse(requirement.gate_is_signed(pending, gate_name="Gate-0"))
        self.assertTrue(requirement.gate_requires_approver_audit(partial))
        self.assertTrue(requirement.gate_requires_approver_audit(passed))
        self.assertFalse(requirement.gate_requires_approver_audit(pending))

    def test_unsigned_gates_without_approver_do_not_fail_approver_check(self) -> None:
        """待* 态无审批人不阻断；非待* 态缺审批人仍阻断。"""
        pending_gate0 = requirement.parse_gate_cell("状态:待确认")
        pending_gate1 = requirement.parse_gate_cell("状态:待批准")
        result_pending0 = gr._release_gate0_issues("# DEF-1\n", "待处理", pending_gate0)
        self.assertIn("Gate-0 状态未通过", result_pending0.blocking)
        self.assertNotIn("Gate-0 审批人/日期不合规", result_pending0.blocking)

        result_pending1 = gr._release_gate12_issues(
            {"Gate-1": pending_gate1, "Gate-2": requirement.parse_gate_cell("状态:待验收")}
        )
        self.assertIn("Gate-1 状态未批准", result_pending1.blocking)
        self.assertNotIn("Gate-1 审批人/日期不合规", result_pending1.blocking)

        partial_no_approver = requirement.parse_gate_cell("状态:部分通过")
        result_partial0 = gr._release_gate0_issues("# DEF-1\n", "待处理", partial_no_approver)
        self.assertIn("Gate-0 审批人/日期不合规", result_partial0.blocking)

        signed_no_approver = requirement.parse_gate_cell("状态:已通过")
        result_signed0 = gr._release_gate0_issues("# ok\n", "待处理", signed_no_approver)
        self.assertIn("Gate-0 审批人/日期不合规", result_signed0.blocking)

        signed_gate1 = requirement.parse_gate_cell("状态:已批准")
        result_signed1 = gr._release_gate12_issues(
            {
                "Gate-1": signed_gate1,
                "Gate-2": requirement.parse_gate_cell("状态:待验收"),
            }
        )
        self.assertIn("Gate-1 审批人/日期不合规", result_signed1.blocking)

    def test_resolve_gate_accepts_status_only_pending_frontmatter(self) -> None:
        text = """\
---
标题: 示例
状态: 待处理
Gate-0: 状态:待确认
Gate-1: 状态:待批准
Gate-2: 状态:待验收
---
"""
        resolved = closeout.resolve_current_gate(Path("docs/requirements/inbox/example.md"), text)
        self.assertEqual(resolved["current_gate"], "Gate-0")

    def test_gate0_pending_breakpoints_from_closure_and_oq(self) -> None:
        text = """\
# Gate-0
## 歧义登记
歧义登记: none（已逐句复核，触达面：测试；确认人:张三；日期:2026-07-30）
## 范围与切片
- OQ-001：是否导出 → 结论：[待确认]
## 数据流闭环表
| 能力/AC | 来源 | 加工 | 去向 | 闭环 |
|---|---|---|---|---|
| AC-1 | api | 校验 | 表 | 待确认 |
"""
        bps = requirement.gate0_pending_breakpoints(text)
        self.assertTrue(any("待确认标记" in bp or "OQ-001" in bp for bp in bps))
        self.assertTrue(any("闭环状态未确认" in bp for bp in bps))

    def test_def_alone_is_not_a_pending_breakpoint(self) -> None:
        text = """\
## 范围与切片
- DEF-001：外链菜单延期
## 数据流闭环表
| 能力/AC | 来源 | 加工 | 去向 | 闭环 |
|---|---|---|---|---|
| AC-1 | /api/system/menus | 组树 | Result | 已确认 |
"""
        self.assertEqual(requirement.gate0_pending_breakpoints(text), [])

    def test_resolve_gate_implementation_after_gate1_approved(self) -> None:
        text = """\
---
标题: 示例
状态: 待处理
Gate-0: 状态:已通过；审批人:张三；2026-07-30
Gate-1: 状态:已批准；审批人:张三；2026-07-30
Gate-2: 状态:待验收
---
# Gate-2 验收
## 验收记录
| AC | 结论 | 验证方式 | 证据 | 结果摘要 |
|---|---|---|---|---|
| — | 未执行 | — | — | — |
"""
        resolved = closeout.resolve_current_gate(Path("docs/requirements/inbox/example.md"), text)
        self.assertEqual(resolved["current_gate"], "实现")
        self.assertEqual(resolved["next_user_action"], "无，继续执行")
        self.assertIn("Gate-1 已批准", resolved["reason"])

    def test_resolve_gate_gate2_when_acceptance_has_evidence(self) -> None:
        text = """\
---
标题: 示例
状态: 待处理
Gate-0: 状态:已通过；审批人:张三；2026-07-30
Gate-1: 状态:已批准；审批人:张三；2026-07-30
Gate-2: 状态:待验收
---
# Gate-2 验收
## 验收记录
| AC | 结论 | 验证方式 | 证据 | 结果摘要 |
|---|---|---|---|---|
| AC-1 | 通过 | pytest | log | ok |
"""
        resolved = closeout.resolve_current_gate(Path("docs/requirements/inbox/example.md"), text)
        self.assertEqual(resolved["current_gate"], "Gate-2")
        self.assertIn("验收", resolved["next_user_action"])

    def test_resolve_gate_gate2_when_bullet_runtime_evidence(self) -> None:
        text = """\
---
标题: 示例
状态: 待处理
Gate-0: 状态:已通过；审批人:张三；2026-07-30
Gate-1: 状态:已批准；审批人:张三；2026-07-30
Gate-2: 状态:待验收
---
# Gate-2 验收
## 验收记录
### UI 组件测试
- **组件测试（已执行）**：`npm run test` — 36 tests 全通过
"""
        resolved = closeout.resolve_current_gate(Path("docs/requirements/inbox/example.md"), text)
        self.assertEqual(resolved["current_gate"], "Gate-2")
        self.assertTrue(closeout.gate2_acceptance_has_evidence(text))

    def test_gate2_acceptance_has_evidence_when_ac_half_checked_in_criteria(self) -> None:
        text = """\
# Gate-1 方案与验收
## 验收标准
- [~] **AC-1**：GIVEN x WHEN y THEN z
# Gate-2 验收
## 验收记录
| AC | 结论 | 证据 |
| --- | --- | --- |
| AC-1 | 程序已检 | pytest exit 0 |
"""
        self.assertTrue(closeout.gate2_acceptance_has_evidence(text))

    def test_gate1_ac_premature_full_checks_before_gate2(self) -> None:
        text = """\
## 验收标准
- [x] **AC-UI-1**：done
- [~] **AC-UI-2**：verified
- [ ] **AC-UI-3**：pending
"""
        premature = closeout.gate1_ac_premature_full_checks(text, gate2_accepted=False)
        self.assertEqual(premature, ["AC-UI-1"])
        self.assertEqual(closeout.gate1_ac_premature_full_checks(text, gate2_accepted=True), [])

    def test_resolve_gate_partial_without_breakpoints_hints_upgrade(self) -> None:
        text = """\
---
标题: 示例
状态: 待处理
Gate-0: 状态:部分通过；审批人:张三；2026-07-30
Gate-1: 状态:待批准
Gate-2: 状态:待验收
---
# 示例
# Gate-0 澄清与范围
## 原始诉求
> 做菜单
## 歧义登记
歧义登记: none（已逐句复核，触达面：菜单；确认人:张三；日期:2026-07-30）
## 范围与切片
- DEF-001：外链延期
## 约束引用
约束引用: none（已检索，触达面：system）
## 数据流闭环表
| 能力/AC | 来源 | 加工 | 去向 | 闭环 |
|---|---|---|---|---|
| AC-1 | /api | 校验 | 表 | 已确认 |
## 原型对齐与偏离
无原型对照。
# Gate-1 实现方案
## 实现方案
- 步骤与验证：pytest
# Gate-2 验收
## 验收记录
| AC | 结论 | 验证方式 | 证据 | 结果摘要 |
|---|---|---|---|---|
| AC-1 | 未执行 | — | — | — |
# Gate-3 沉淀
## 实现记录与沉淀
- Experience Reuse: none
"""
        resolved = closeout.resolve_current_gate(Path("docs/requirements/inbox/example.md"), text)
        self.assertEqual(resolved["current_gate"], "Gate-0")
        self.assertIn("改为「已通过」", resolved["next_user_action"])
        self.assertIn("无待确认断点", resolved.get("hint", ""))

    def test_resolve_gate_partial_with_breakpoints_points_to_them(self) -> None:
        text = """\
---
标题: 示例
状态: 待处理
Gate-0: 状态:部分通过；审批人:张三；2026-07-30
Gate-1: 状态:待批准
Gate-2: 状态:待验收
---
# 示例
## 数据流闭环表
| 能力/AC | 来源 | 加工 | 去向 | 闭环 |
|---|---|---|---|---|
| AC-1 | x | y | z | 待确认 |
"""
        resolved = closeout.resolve_current_gate(Path("docs/requirements/inbox/example.md"), text)
        self.assertEqual(resolved["current_gate"], "Gate-0")
        self.assertIn("待确认断点", resolved["next_user_action"])
        self.assertIn("闭环", resolved["next_user_action"])


class CloseoutReuseLoggingTests(unittest.TestCase):
    DOC = "docs/patterns/example.md"

    def reuse_gaps(self, stem: str, session: str) -> list[str]:
        """Body references a pattern without Experience Reuse line → needs usage log."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            usage = root / "usage.jsonl"
            judgments = root / "judgments.jsonl"
            usage.write_text(
                f'{{"doc": "{self.DOC}", "session": "{session}"}}\n',
                encoding="utf-8",
            )
            judgments.write_text("", encoding="utf-8")
            text = f"实现中对照了 {self.DOC}（见方案说明）"
            with (
                mock.patch.object(paths, "DOCS_USAGE_LOG", usage),
                mock.patch.object(paths, "DOCS_JUDGMENTS_LOG", judgments),
            ):
                return closeout.reuse_logging_gaps(text, stem)

    def test_three_digit_requirement_id_does_not_match_usage_session(self) -> None:
        self.assertEqual(self.reuse_gaps("010-旧需求", "010-review"), [self.DOC])

    def test_fourteen_digit_requirement_id_matches_usage_session(self) -> None:
        self.assertEqual(
            self.reuse_gaps("20260729123456-新需求", "20260729123456-review"),
            [],
        )

    def test_experience_reuse_line_is_document_truth(self) -> None:
        text = f"## 实现记录与沉淀\nExperience Reuse: {self.DOC}\n"
        with (
            mock.patch.object(paths, "DOCS_USAGE_LOG", Path("missing-usage.jsonl")),
            mock.patch.object(paths, "DOCS_JUDGMENTS_LOG", Path("missing-judgments.jsonl")),
        ):
            self.assertEqual(closeout.reuse_logging_gaps(text, "20260729123456-新需求"), [])


class CommentSyncHelperTests(unittest.TestCase):
    def test_semantic_comment_presence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "src/tagged.py", "# [核心目的] 处理导入\ndef run():\n    pass\n")
            _write(root, "src/untagged.py", "def run():\n    pass\n")
            with mock.patch.object(paths, "ROOT", root):
                self.assertTrue(comments.file_has_semantic_comment("src/tagged.py"))
                self.assertFalse(comments.file_has_semantic_comment("src/untagged.py"))

    def test_fastapi_router_is_comment_sync_scope(self) -> None:
        rel = "backend/app/system/user_router.py"
        self.assertTrue(paths.is_comment_sync_code(rel))

    def test_fastapi_router_docstring_parsing_multiline_signature(self) -> None:
        source = '''
@router.get("")
def list_users(
    db: Session = Depends(get_db),
) -> Result[PageResult]:
    """
    [接口地址] GET /api/system/users
    [功能描述] 用户分页列表
    [业务逻辑] 1. 校验权限 -> 2. 返回 PageResult
    """
    return Result.ok([])
'''
        blocks = comments.extract_fastapi_router_docstrings(source)
        self.assertEqual(len(blocks), 1)
        _line_no, block = blocks[0]
        self.assertIsNotNone(block)
        assert block is not None
        self.assertIn("[接口地址]", block)
        with mock.patch.object(comments, "frontend_api_entries", return_value=set()):
            issues = comments.fastapi_router_endpoint_issues("backend/app/x_router.py", source)
        self.assertEqual(issues, [])


class ReleaseDeferredTests(unittest.TestCase):
    def test_release_failure_output_and_exit_code_are_stable(self) -> None:
        output = io.StringIO()
        with (
            mock.patch.object(gr, "_changed_all_files", return_value=[]),
            mock.patch.object(gr, "_changed_impl_files", return_value=[]),
            mock.patch.object(gr, "_changed_test_files", return_value=[]),
            redirect_stdout(output),
        ):
            rc = gr._run_check_release("HEAD", "missing.md")

        self.assertEqual(rc, 1)
        self.assertEqual(
            output.getvalue(),
            "[release] 本次未触达核心业务代码（comment-sync 不适用）。\n"
            "[release] 审批留痕校验失败：需求文档不存在 missing.md\n"
            "[release] 人工门禁（脚本无法客观判定，须在 verify 输出与 Gate-2 留痕）：\n"
            "  - requesting-code-review: done|skipped+reason\n"
            "  - xijia-quality-judge: pass|revise（revise 不得宣告完成）\n"
            "  - Gate-2: 验收人须为 git config user.name（可选附 email）；禁止泛称「用户」；签字后方可状态迁移/归档\n"
            "  - Deferred 项是否已写入 docs/requirements/backlog.md\n"
            "[release] BLOCKED：需求文档不存在 —— 不得进入 Gate-2/归档。\n"
            "[release] hint: 当前门禁见 --resolve-gate --req missing.md\n",
        )

    def test_frontend_ui_files_exclude_tests_and_non_runtime_docs(self) -> None:
        changed = [
            "frontend/src/views/UsersView.vue",
            "frontend/src/router/index.ts",
            "frontend/src/views/UsersView.spec.ts",
            "frontend/README.md",
            "docs/requirements/foo.md",
        ]
        self.assertEqual(
            gr._changed_frontend_ui_files(changed),
            [
                "frontend/src/router/index.ts",
                "frontend/src/views/UsersView.vue",
            ],
        )

    def test_ui_runtime_evidence_rejects_build_only_and_unexecuted_screenshot(self) -> None:
        build_only = """\
# Gate-2 验收
## 验收记录
| AC | 结论 | 证据类型 | 证据出处 |
|---|---|---|---|
| AC-1 | 通过 | 命令输出 | npm run lint && npm run build exit 0 |
"""
        screenshot_not_run = """\
# Gate-2 验收
## 验收记录
AC-1 截图：未执行，仅通过 build 推断。
"""
        self.assertFalse(gr._has_ui_runtime_evidence(build_only))
        self.assertFalse(gr._has_ui_runtime_evidence(screenshot_not_run))

    def test_ui_runtime_evidence_accepts_executed_component_test_or_screenshot(self) -> None:
        component_test = """\
# Gate-2 验收
## 验收记录
| AC | 结论 | 证据类型 | 证据出处 |
|---|---|---|---|
| AC-1 | 通过 | 组件测试 | `npm run test:unit`，3 passed |
"""
        screenshot = """\
# Gate-2 验收
## 验收记录
| AC | 结论 | 证据类型 | 证据出处 |
|---|---|---|---|
| AC-1 | 通过 | 截图 | `artifacts/tabs.png`，浏览器实机已执行 |
"""
        self.assertTrue(gr._has_ui_runtime_evidence(component_test))
        self.assertTrue(gr._has_ui_runtime_evidence(screenshot))

    def test_ui_runtime_evidence_playwright_tier(self) -> None:
        playwright_ok = """\
---
UI验收证据: Playwright
---
# Gate-2 验收
## 验收记录
| AC | 证据 |
|---|---|
| AC-1 | webapp-testing `frontend/e2e/publish.py` exit 0 |
"""
        component_only = """\
---
UI验收证据: Playwright
---
# Gate-2 验收
## 验收记录
| AC | 证据 |
|---|---|
| AC-1 | 组件测试 npm run test 8 passed |
"""
        self.assertTrue(gr._has_ui_runtime_evidence(playwright_ok))
        self.assertFalse(gr._has_ui_runtime_evidence(component_only))

    def test_ui_runtime_evidence_integration_tier(self) -> None:
        integration_ok = """\
---
UI验收证据: 集成测试
---
# Gate-2 验收
## 验收记录
| AC | 证据 |
|---|---|
| AC-1 | verify-frontend parity exit 0 |
"""
        self.assertTrue(gr._has_ui_runtime_evidence(integration_ok))

    def test_parse_frontmatter_ui_evidence(self) -> None:
        self.assertEqual(
            requirement.parse_frontmatter_ui_evidence("---\nUI验收证据: Playwright\n---\n"),
            "playwright",
        )
        self.assertEqual(
            requirement.parse_frontmatter_ui_evidence("---\nUI验收证据: 组件测试\n---\n"),
            "component",
        )
        self.assertEqual(
            requirement.parse_frontmatter_ui_evidence("---\nUI验收证据: 集成测试\n---\n"),
            "integration",
        )

    def test_extract_deferred_ids_simplified_and_legacy(self) -> None:
        ids = requirement.extract_deferred_ids("见 DEF-002 与旧 DEF-013-02。")
        self.assertEqual(ids, ["DEF-002", "DEF-013-02"])

    def test_invalid_approver_rejects_generic_user(self) -> None:
        self.assertTrue(requirement.is_invalid_approver("用户"))
        self.assertTrue(requirement.is_invalid_approver("人工"))
        self.assertFalse(requirement.is_invalid_approver("张三"))
        self.assertFalse(requirement.is_invalid_approver("张三 <zhang@example.com>"))

    def test_missing_deferred_in_backlog(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "docs/requirements/backlog.md", "# Backlog\n- DEF-001 已登记\n")
            with mock.patch.object(paths, "ROOT", root):
                missing = requirement.missing_deferred_in_backlog(["DEF-001", "DEF-002"])
            self.assertEqual(missing, ["DEF-002"])

    def test_gate3_closeout_markers_work_in_new_location(self) -> None:
        text = self._business_closeout_text(
            """\
# Gate-2 验收
## 验收记录
AC-1: 通过

# Gate-3 知识同步
## 实现记录与沉淀
Capability Index: no-op
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
"""
        )
        self.assertEqual(closeout.capability_index_closeout_issues(text, "req.md"), [])
        self.assertEqual(closeout.experience_distill_closeout_issues(text), [])

    def test_gate3_closeout_requires_living_docs_and_flow_markers(self) -> None:
        text = self._business_closeout_text(
            """\
## 实现记录与沉淀
Capability Index: no-op
Patterns: no-op
Pitfalls: no-op
Domain: no-op
"""
        )
        # Strip auto Domain append for this negative case: pass sections that already
        # include Domain so helper won't double-append; then remove Domain lines.
        text = text.replace("Domain: no-op\n", "")
        issues = closeout.experience_distill_closeout_issues(text)
        self.assertTrue(issues)
        self.assertIn("Living Docs", issues[0])
        self.assertIn("Flow", issues[0])

    def test_gate3_closeout_requires_domain_marker_for_ddd_b(self) -> None:
        text = """\
---
标题: 业务需求
状态: 已交付
分级: 黄
类型: 混合
DDD主类: B
---
## 实现记录与沉淀
Capability Index: no-op
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
"""
        issues = closeout.experience_distill_closeout_issues(text)
        self.assertTrue(any("Domain" in item for item in issues))
        domain_issues = closeout.domain_closeout_issues(text, "docs/requirements/shipped/demo.md")
        self.assertTrue(domain_issues)

    def test_domain_impact_intake_requires_section(self) -> None:
        text = """\
---
标题: 混合需求
状态: 待处理
分级: 黄
类型: 混合
DDD主类: B
---
## 范围与切片
- 能力
"""
        issues = requirement.domain_impact_intake_issues(text)
        self.assertTrue(any("领域影响" in item for item in issues))

    def test_domain_impact_intake_accepts_inv(self) -> None:
        text = """\
---
标题: 混合需求
状态: 待处理
分级: 黄
类型: 混合
DDD主类: B
---
## 领域影响
- 限界上下文：platform
- 领域规则与不变量：INV-ROLE-01 SUPER_ADMIN 不可删
"""
        self.assertEqual(requirement.domain_impact_intake_issues(text), [])
        self.assertTrue(requirement.domain_impact_declares_new_inv(text))
        self.assertEqual(requirement.domain_impact_inv_ids(text), ["INV-ROLE-01"])

    def test_domain_closeout_blocks_inv_without_bc_domain_model(self) -> None:
        text = """\
---
标题: 混合需求
状态: 已交付
分级: 黄
类型: 混合
DDD主类: B
---
## 领域影响
- 限界上下文：platform
- INV-ROLE-99 测试不变量
## 实现记录与沉淀
Capability Index: no-op
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
Domain: updated（docs/domain/context-map.md；仅登记关系）
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "docs/domain/context-map.md", "platform\n")
            with mock.patch.object(paths, "ROOT", root):
                issues = closeout.domain_closeout_issues(
                    text,
                    "docs/requirements/shipped/demo.md",
                    ["docs/domain/context-map.md"],
                )
        self.assertTrue(any("domain-model" in item for item in issues))

    def test_domain_closeout_accepts_inv_when_domain_model_on_disk(self) -> None:
        text = """\
---
标题: 混合需求
状态: 已交付
分级: 黄
类型: 混合
DDD主类: B
---
## 领域影响
- INV-ROLE-99 测试不变量
## 实现记录与沉淀
Domain: updated（docs/domain/context-map.md）
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
Capability Index: no-op
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "docs/domain/context-map.md", "platform\n")
            _write(
                root,
                "docs/domain/platform/domain-model.md",
                "**INV-ROLE-99**: test\n",
            )
            with mock.patch.object(paths, "ROOT", root):
                issues = closeout.domain_closeout_issues(
                    text,
                    "docs/requirements/shipped/demo.md",
                    ["docs/domain/context-map.md"],
                )
        self.assertEqual(issues, [])

    def test_false_noop_blocks_when_patterns_changed(self) -> None:
        text = self._business_closeout_text(
            """\
## 实现记录与沉淀
Patterns: no-op
Pitfalls: no-op
Capability Index: no-op
Living Docs: no-op
Flow: no-op
"""
        )
        req_rel = "docs/requirements/shipped/20260729120000-demo.md"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                "docs/patterns/admin-list-page.md",
                "来源需求号：20260729120000-demo\n",
            )
            with mock.patch.object(paths, "ROOT", root):
                issues = closeout.false_noop_closeout_issues(
                    text,
                    req_rel,
                    [req_rel, "docs/patterns/admin-list-page.md"],
                )
        self.assertTrue(any("Patterns: no-op" in item for item in issues))

    def test_capability_false_noop_when_map_references_req(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req_name = "20260729120000-demo.md"
            _write(root, "docs/capability-map.md", f"| x | y | {req_name} |\n")
            text = self._business_closeout_text(
                """\
## 实现记录与沉淀
Capability Index: no-op
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
"""
            )
            with mock.patch.object(paths, "ROOT", root):
                issues = closeout.capability_index_closeout_issues(
                    text, f"docs/requirements/shipped/{req_name}"
                )
            self.assertTrue(any("false no-op" in item for item in issues))

    def test_experience_reuse_none_blocked_when_constraint_lists_pattern(self) -> None:
        text = self._business_closeout_text(
            """\
## 约束引用
| 相关项 | 匹配依据 | 处置 |
|---|---|---|
| docs/patterns/admin-list-page.md | 列表页 | 复用 |

## 实现记录与沉淀
Experience Reuse: none（已检索，触达面：列表）
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
Capability Index: no-op
"""
        )
        gaps = closeout.reuse_logging_gaps(text, "20260729120000-demo")
        self.assertEqual(gaps, ["docs/patterns/admin-list-page.md"])

    def test_experience_reuse_path_is_document_truth_without_usage_log(self) -> None:
        text = self._business_closeout_text(
            """\
## 约束引用
| 相关项 | 匹配依据 | 处置 |
|---|---|---|
| docs/patterns/admin-list-page.md | 列表页 | 复用 |

## 实现记录与沉淀
Experience Reuse: docs/patterns/admin-list-page.md
Patterns: docs/patterns/admin-list-page.md
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
Capability Index: no-op
"""
        )
        with (
            mock.patch.object(paths, "DOCS_USAGE_LOG", Path("missing-usage.jsonl")),
            mock.patch.object(paths, "DOCS_JUDGMENTS_LOG", Path("missing-judgments.jsonl")),
        ):
            self.assertEqual(closeout.reuse_logging_gaps(text, "20260729120000-demo"), [])

    def test_distill_candidate_section_does_not_trigger_reuse_gap(self) -> None:
        skipped_doc = "docs/patterns/list-page-modal-drawer.md"
        text = self._business_closeout_text(
            f"""\
### 沉淀候选（Gate-3）
| 候选 | 处置 |
|---|---|
| {skipped_doc} | 跳过 |

## 实现记录与沉淀
Experience Reuse: none
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
Capability Index: no-op
"""
        )
        with (
            mock.patch.object(paths, "DOCS_USAGE_LOG", Path("missing-usage.jsonl")),
            mock.patch.object(paths, "DOCS_JUDGMENTS_LOG", Path("missing-judgments.jsonl")),
        ):
            self.assertEqual(closeout.reuse_logging_gaps(text, "20260729120000-demo"), [])

    def test_constraint_none_without_touch_surface_warns_for_business(self) -> None:
        text = """\
---
类型: 业务
分级: 绿
---
## 约束引用
约束引用: none
"""
        warnings = requirement.constraint_reference_intake_warnings(text)
        self.assertTrue(any("触达面" in item for item in warnings))

    def test_constraint_reference_path_existence_blocks_ghost_path(self) -> None:
        text = """\
---
类型: 业务
分级: 绿
---
## 约束引用
| 相关项 | 匹配依据 | 处置 |
|---|---|---|
| docs/patterns/does-not-exist-ghost.md | 列表页 | 复用 |
"""
        issues = requirement.constraint_reference_path_existence_issues(text)
        self.assertEqual(len(issues), 1)
        self.assertIn("does-not-exist-ghost", issues[0])

    def test_constraint_reference_system_list_ui_no_hardcoded_modal_drawer(self) -> None:
        text = """\
---
类型: 业务
分级: 绿
---
## 约束引用
| 相关项 | 匹配依据 | 处置 |
|---|---|---|
| docs/patterns/table-first-list-page.md | 列表页 UI | 复用 |

# Gate-1 方案与验收
## 验收标准
- [ ] **AC-UI-1**：GIVEN 列表页 WHEN 点击编辑 THEN Drawer 打开

## 数据流闭环表
| 能力 | 来源 | 加工 | 去向 | 前端入口 | 相关表 | 闭环 |
|---|---|---|---|---|---|---|
| 列表 | API | CRUD | DB | /w/settings | sys_config | 已确认 |
"""
        warnings = requirement.constraint_reference_intake_warnings(text)
        self.assertFalse(any("list-page-modal-drawer" in w for w in warnings))

    def test_constraint_reference_panel_ref_warns_without_panel_coordinate(self) -> None:
        text = """\
---
类型: 业务
分级: 绿
---
## 约束引用
| 相关项 | 匹配依据 | 处置 |
|---|---|---|
| docs/patterns/table-first-list-page.md | 列表页 | 复用 |

# Gate-1 方案与验收
## 实现方案
- 复用 list.css
"""
        warnings = requirement.constraint_reference_intake_warnings(text)
        self.assertTrue(any("Panel.vue" in w for w in warnings))

    @staticmethod
    def _business_closeout_text(sections: str) -> str:
        # Default Domain: no-op so legacy closeout fixtures stay valid unless testing Domain.
        if "Domain:" not in sections:
            sections = sections.rstrip() + "\nDomain: no-op\n"
        return f"""\
---
标题: 业务需求
状态: 已交付
分级: 绿
类型: 业务
DDD主类: B
---
| 能力/AC | 来源(Source) | 加工(Process) | 去向(Sink) | 闭环 |
|---|---|---|---|---|
| AC-1 | 输入 | 校验 | 输出 | 已确认 |

{sections}
"""


class Gate3TriggerReportTests(unittest.TestCase):
    _HYBRID_INV = """\
---
标题: 角色管理
状态: 待处理
分级: 黄
类型: 混合
DDD主类: B
Gate-0: 状态:已通过 | 审批人: tester | 2026-08-01
Gate-1: 状态:已批准 | 审批人: tester | 2026-08-02
Gate-2: 状态:已验收 | 审批人: tester | 2026-08-05
---
## 领域影响
- INV-ROLE-01 SUPER_ADMIN 不可删
## 约束引用
| 相关项 | 匹配依据 | 处置 |
|---|---|---|
| docs/patterns/frontend-butter-shell.md | 壳层 | 复用 |
"""

    def test_gate3_trigger_mandatory_capability_domain_inv(self) -> None:
        from guardlib.gate3_triggers import build_gate3_trigger_report

        report = build_gate3_trigger_report(self._HYBRID_INV, [])
        targets = {item.target for item in report.mandatory}
        self.assertIn("docs/capability-map.md", targets)
        self.assertIn("docs/domain/context-map.md", targets)
        self.assertIn("docs/domain/<bc>/domain-model.md", targets)
        self.assertTrue(any(item.target == "Experience Reuse" for item in report.mandatory))

    def test_gate3_trigger_suggested_table_first_for_view(self) -> None:
        from guardlib.gate3_triggers import build_gate3_trigger_report

        changed = ["frontend/src/views/RoleManageView.vue"]
        report = build_gate3_trigger_report(self._HYBRID_INV, changed)
        suggested_targets = {item.target for item in report.suggested}
        self.assertIn("docs/patterns/table-first-list-page.md", suggested_targets)

    def test_gate3_trigger_suggested_shared_layer_pattern(self) -> None:
        from guardlib.gate3_triggers import build_gate3_trigger_report

        changed = [
            "backend/app/common/async_job/progress.py",
            "frontend/src/composables/useAsyncJobProgress.js",
        ]
        report = build_gate3_trigger_report(self._HYBRID_INV, changed)
        shared_items = [
            item for item in report.suggested
            if item.target == "docs/patterns/<topic>.md"
        ]
        self.assertEqual(len(shared_items), 1)
        self.assertIn("人确认", shared_items[0].action)

    def test_gate3_trigger_no_shared_layer_for_business_module(self) -> None:
        from guardlib.gate3_triggers import build_gate3_trigger_report

        changed = ["backend/app/mcp_services/router.py"]
        report = build_gate3_trigger_report(self._HYBRID_INV, changed)
        self.assertFalse(
            any(item.target == "docs/patterns/<topic>.md" for item in report.suggested)
        )

    def test_gate3_trigger_green_trivial_noop_ok(self) -> None:
        from guardlib.gate3_triggers import build_gate3_trigger_report

        text = """\
---
标题: 小修
分级: 绿-轻量
类型: 业务
---
本需求无数据流（green-trivial）。
"""
        report = build_gate3_trigger_report(text, ["backend/app/foo.py"])
        self.assertFalse(report.mandatory)
        self.assertTrue(any("no-op" in item.action for item in report.noop_ok))

    def test_gate3_preflight_warns_missing_distill_section(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = _write(root, "docs/requirements/inbox/demo.md", self._HYBRID_INV)
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                closeout.paths, "ROOT", root,
            ), mock.patch.object(
                closeout.paths, "INBOX_DIR", root / "docs/requirements/inbox",
            ), mock.patch.object(
                closeout.paths, "SHIPPED_DIR", root / "docs/requirements/shipped",
            ), mock.patch(
                "guardlib.gitio.changed_all_files", return_value=[],
            ):
                errors, warnings = closeout.gate3_preflight_issues(req)
        self.assertEqual(errors, [])
        self.assertTrue(any("实现记录与沉淀" in w for w in warnings))

    def test_gate3_preflight_warns_pattern_noop_with_suggestion(self) -> None:
        text = self._HYBRID_INV + """
## 实现记录与沉淀
Patterns: no-op
Pitfalls: no-op
Living Docs: no-op
Flow: no-op
Capability Index: no-op
Domain: no-op
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = _write(root, "docs/requirements/inbox/demo.md", text)
            changed = ["frontend/src/views/RoleManageView.vue"]
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                closeout.paths, "ROOT", root,
            ), mock.patch.object(
                closeout.paths, "INBOX_DIR", root / "docs/requirements/inbox",
            ), mock.patch.object(
                closeout.paths, "SHIPPED_DIR", root / "docs/requirements/shipped",
            ), mock.patch(
                "guardlib.gitio.changed_all_files", return_value=changed,
            ):
                errors, warnings = closeout.gate3_preflight_issues(req)
        self.assertEqual(errors, [])
        self.assertTrue(any("pattern" in w.lower() for w in warnings))

    def test_resolve_gate_gate3_includes_trigger_hint(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = _write(root, "docs/requirements/inbox/demo.md", self._HYBRID_INV)
            with mock.patch.object(paths, "ROOT", root), mock.patch(
                "guardlib.gitio.changed_all_files", return_value=[],
            ):
                resolved = closeout.resolve_current_gate(req, self._HYBRID_INV)
        self.assertEqual(resolved["current_gate"], "Gate-3")
        self.assertIn("hint", resolved)
        self.assertIn("gate3-trigger-report", resolved["hint"])

    def test_run_gate3_trigger_report_cli(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = _write(root, "docs/requirements/inbox/demo.md", self._HYBRID_INV)
            req_rel = "docs/requirements/inbox/demo.md"
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                gr.gc, "ROOT", root,
            ), mock.patch.object(
                gr, "_changed_all_files", return_value=["frontend/src/views/RoleManageView.vue"],
            ):
                buf = io.StringIO()
                with redirect_stdout(buf):
                    rc = gr._run_gate3_trigger_report(req_rel, "HEAD", False)
        self.assertEqual(rc, 0)
        out = buf.getvalue()
        self.assertIn("[gate3-trigger]", out)
        self.assertIn("table-first-list-page", out)


class CtaOutputTests(unittest.TestCase):
    _GATE1_PENDING = """\
---
标题: 系统参数设置
状态: 待处理
分级: 黄
类型: 混合
Gate-0: 状态:已通过；审批人:张三；2026-08-06
Gate-1: 状态:待批准
Gate-2: 状态:待验收
---
# 系统参数设置
# Gate-0 澄清与范围
## 原始诉求
> 做参数
## 歧义登记
歧义登记: none（已逐句复核，触达面：参数；确认人:张三；日期:2026-08-06）
## 业务目标
- 维护参数
## 用例 / 用户故事
1. 作为管理员维护参数
## 范围与切片
In Scope: API
## 领域影响
- BC: platform
- 本切片无新INV
## 约束引用
约束引用: none（已检索，触达面：system）
## 数据流闭环表
| 能力/AC | 来源 | 加工 | 去向 | 闭环 |
|---|---|---|---|---|
| AC-1 | /api | 校验 | 表 | 已确认 |
## 原型对齐与偏离
无原型对照。
# Gate-1 实现方案
## 页面布局预览
Table + Drawer
## 验收标准
- AC-API-1: GET /api/system/configs 返回 200
- 反例（本 AC 排除）: 未授权访问返回 401
## 实现方案
复用映射: RoleManageView
切片拆解:
1. 后端 API — Files: backend/app/system/config_router.py — Done: pytest
回归验证点: cd backend && pytest tests/system/test_config_admin.py -q
# Gate-2 验收
## 验收记录
| AC | 结论 | 验证方式 | 证据 | 结果摘要 |
|---|---|---|---|---|
| AC-1 | 未执行 | — | — | — |
# Gate-3 沉淀
## 实现记录与沉淀
- Experience Reuse: none
"""

    def test_format_cta_includes_please_and_then(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                "docs/requirements/inbox/20260806100901-系统参数设置.md",
                self._GATE1_PENDING,
            )
            req_rel = "docs/requirements/inbox/20260806100901-系统参数设置.md"
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "INBOX_DIR", root / "docs/requirements/inbox"
            ):
                buf = io.StringIO()
                with redirect_stdout(buf):
                    rc = gi._run_resolve_gate(req_rel, "cta")
        self.assertEqual(rc, 0)
        out = buf.getvalue()
        self.assertIn("**请你：**", out)
        self.assertIn("**然后：**", out)
        self.assertIn("**本步指令：**", out)
        self.assertIn("\n\n**本步指令：**", out)
        self.assertIn("\n\n**请你：**", out)
        self.assertIn("\n\n**然后：**", out)
        self.assertIn("Gate-1(方案审核)", out)
        self.assertNotIn("另有", out)
        self.assertNotIn("Gate-0(需求澄清) ✅", out)

    def test_format_cta_gate1_ui_touch_includes_evidence_reminder(self) -> None:
        from guardlib.cta_output import build_cta_context, format_cta_markdown
        from guardlib import requirement as req_mod

        ui_text = (
            self._GATE1_PENDING.replace(
                "- AC-API-1: GET /api/system/configs 返回 200",
                "- [ ] AC-1: GET /api/system/configs 返回 200",
            ).replace(
                "回归验证点: cd backend && pytest tests/system/test_config_admin.py -q",
                "回归验证点: `cd backend && pytest tests/system/test_config_admin.py -q`",
            )
        )
        self.assertTrue(req_mod.requirement_touches_ui(ui_text))
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = root / "docs/requirements/inbox/20260806100901-系统参数设置.md"
            req.parent.mkdir(parents=True, exist_ok=True)
            req.write_text(ui_text, encoding="utf-8")
            with mock.patch.object(paths, "ROOT", root):
                ctx = build_cta_context(req, ui_text)
        self.assertEqual(ctx.substate, "Gate-1 待批准", msg=str(ctx.plan_issues))
        md = format_cta_markdown(ctx)
        self.assertIn("**UI 验收证据：**", md)
        self.assertIn("\n\n**UI 验收证据：**", md)
        self.assertNotIn("**本步指令：**", md)
        self.assertIn("\n\n**请你：**", md)
        self.assertIn("组件测试|Playwright|集成测试", md)
        self.assertIn("默认组件测试", md)

    def test_format_cta_gate1_no_ui_omits_evidence_reminder(self) -> None:
        from guardlib.cta_output import build_cta_context, format_cta_markdown
        from guardlib import requirement as req_mod

        no_ui = (
            self._GATE1_PENDING.replace(
                "- AC-API-1: GET /api/system/configs 返回 200",
                "- [ ] AC-1: GET /api/system/configs 返回 200",
            )
            .replace(
                "回归验证点: cd backend && pytest tests/system/test_config_admin.py -q",
                "回归验证点: `cd backend && pytest tests/system/test_config_admin.py -q`",
            )
            .replace(
                "## 页面布局预览\nTable + Drawer\n",
                "## 页面布局预览\n不适用（无 UI 触达）\n",
            )
            .replace(
                "复用映射: RoleManageView\n切片拆解:\n1. 后端 API — Files: backend/app/system/config_router.py — Done: pytest\n",
                "复用映射: none\n切片拆解:\n1. 后端 API — Files: backend/app/system/config_router.py — Done: pytest\n",
            )
        )
        self.assertFalse(req_mod.requirement_touches_ui(no_ui))
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = root / "docs/requirements/inbox/20260806100903-纯后端.md"
            req.parent.mkdir(parents=True, exist_ok=True)
            req.write_text(no_ui, encoding="utf-8")
            with mock.patch.object(paths, "ROOT", root):
                ctx = build_cta_context(req, no_ui)
        self.assertEqual(ctx.substate, "Gate-1 待批准", msg=str(ctx.plan_issues))
        md = format_cta_markdown(ctx)
        self.assertNotIn("**UI 验收证据：**", md)
        self.assertNotIn("Playwright|集成测试", md)
        self.assertNotIn("**本步指令：**", md)
        self.assertIn("`批准 Gate-1`", md)

    def test_format_cta_without_req_is_reminder_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                "docs/requirements/inbox/20260806100901-系统参数设置.md",
                self._GATE1_PENDING,
            )
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "INBOX_DIR", root / "docs/requirements/inbox"
            ):
                buf = io.StringIO()
                with redirect_stdout(buf):
                    rc = gi._run_resolve_gate("", "cta")
        self.assertEqual(rc, 0)
        out = buf.getvalue()
        self.assertIn("请指定需求文档", out)
        self.assertIn("**请你：**", out)
        self.assertIn("**然后：**", out)
        self.assertIn("\n\n**请你：**", out)
        self.assertIn("\n\n**然后：**", out)
        self.assertNotIn("Gate-1(方案审核) ⏳", out)
        self.assertNotIn("Gate-1 待批准", out)
        self.assertNotIn("Gate-0(需求澄清) ✅", out)

    def test_format_cta_with_req_no_multi_inbox_note(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "docs/requirements/inbox/20260806100901-系统参数设置.md", self._GATE1_PENDING)
            _write(root, "docs/requirements/inbox/20260806100902-字典.md", self._GATE1_PENDING)
            req_rel = "docs/requirements/inbox/20260806100901-系统参数设置.md"
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "INBOX_DIR", root / "docs/requirements/inbox"
            ):
                buf = io.StringIO()
                with redirect_stdout(buf):
                    rc = gi._run_resolve_gate(req_rel, "cta")
        self.assertEqual(rc, 0)
        out = buf.getvalue()
        self.assertNotIn("另有", out)

    def test_requirement_short_name_uses_timestamp_suffix(self) -> None:
        from guardlib.cta_output import requirement_short_name

        name = requirement_short_name(Path("20260806100901-系统参数设置.md"))
        self.assertEqual(name, "901 系统参数设置")

    def test_format_cta_plan_gap_substate(self) -> None:
        text = self._GATE1_PENDING.replace(
            "切片拆解:\n1. 后端 API",
            "切片拆解:\n（待补）",
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "docs/requirements/inbox/20260806100902-缺口.md", text)
            with mock.patch.object(paths, "ROOT", root):
                from guardlib.cta_output import build_cta_context

                ctx = build_cta_context(
                    root / "docs/requirements/inbox/20260806100902-缺口.md",
                    text,
                )
        self.assertEqual(ctx.substate, "Gate-1 方案缺口")
        md = __import__("guardlib.cta_output", fromlist=["format_cta_markdown"]).format_cta_markdown(ctx)
        self.assertIn("无（Agent 继续）", md)
        self.assertIn("A.0.5", md)


class PrototypeGuardTests(unittest.TestCase):
    def test_skips_when_no_prototype_declared(self) -> None:
        text = "## 原型对齐与偏离\n无原型对照。\n"
        self.assertEqual(requirement.prototype_table_intake_issues(text), [])

    def test_requires_table_when_html_reference(self) -> None:
        text = "## 原型对齐与偏离\n参照 document/DEMO/foo.html\n"
        issues = requirement.prototype_table_intake_issues(text)
        self.assertTrue(issues)
        self.assertIn("PRD", issues[0])


class OpenSpecStructuralTests(unittest.TestCase):
    def test_missing_change_dir_is_error(self) -> None:
        text = """\
---
分级: 红
类型: 业务
openspec变更: missing-change
---
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            req = root / "docs/requirements/inbox/20260806123456-红档.md"
            req.parent.mkdir(parents=True)
            req.write_text(text, encoding="utf-8")
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "CHANGES_DIR", root / "docs/openspec/changes"
            ), mock.patch.object(
                paths, "ARCHIVE_CHANGES_DIR", root / "docs/openspec/changes/archive"
            ):
                errors, warnings = openspec.openspec_structural_issues(text, req)
        self.assertTrue(errors)
        self.assertFalse(warnings)


class ScanInboxTests(unittest.TestCase):
    def test_scan_inbox_marks_active(self) -> None:
        text_a = CtaOutputTests._GATE1_PENDING
        text_b = text_a.replace(
            "Gate-0: 状态:已通过；审批人:张三；2026-08-06",
            "Gate-0: 状态:待确认",
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "docs/requirements/inbox/20260806100902-字典.md", text_b)
            _write(root, "docs/requirements/inbox/20260806100901-参数.md", text_a)
            with mock.patch.object(paths, "ROOT", root), mock.patch.object(
                paths, "INBOX_DIR", root / "docs/requirements/inbox"
            ):
                buf = io.StringIO()
                with redirect_stdout(buf):
                    rc = gi._run_scan_inbox()
        self.assertEqual(rc, 0)
        out = buf.getvalue()
        self.assertIn("active-req=", out)
        self.assertIn("*20260806100902", out)


class UiPatternGuardTests(unittest.TestCase):
    def test_ui_pattern_issues_detects_role_table_foot(self) -> None:
        from guard_ui_pattern import ui_pattern_issues

        bad_panel = (
            '<footer class="role-table-foot">\n'
            '  <span>分页</span>\n'
            '</footer>\n'
            '<aside class="menu-drawer">\n'
            '</aside>\n'
        )
        with mock.patch("guard_ui_pattern.changed_files", return_value=["frontend/src/components/BadPanel.vue"]):
            with mock.patch.object(paths, "ROOT", paths.ROOT):
                panel_path = paths.ROOT / "frontend/src/components/BadPanel.vue"
                panel_path.parent.mkdir(parents=True, exist_ok=True)
                try:
                    panel_path.write_text(bad_panel, encoding="utf-8")
                    issues = ui_pattern_issues("HEAD")
                finally:
                    if panel_path.is_file():
                        panel_path.unlink()
        self.assertTrue(any("role-table-foot" in issue for issue in issues))
        self.assertTrue(any("role-panel-foot" in issue for issue in issues))
        self.assertTrue(any("is-on" in issue for issue in issues))

    def test_ui_pattern_issues_ok_for_compliant_panel(self) -> None:
        from guard_ui_pattern import ui_pattern_issues

        good_panel = (
            '<div class="menu-manage good-manage">\n'
            '  <header class="menu-page-toolbar">\n'
            '    <PageHeadBar group="系统" current="示例" description="说明" />\n'
            "  </header>\n"
            '  <section class="menu-panel">\n'
            '    <div class="menu-panel-head role-panel-head">\n'
            '      <div class="role-search-field"><input type="search" /></div>\n'
            "    </div>\n"
            '    <div class="role-table-wrap">\n'
            '      <table class="role-table"><tbody></tbody></table>\n'
            "    </div>\n"
            '    <div class="role-panel-foot">\n'
            '      <span class="role-panel-foot__summary">共 1 条</span>\n'
            '      <div class="role-panel-foot__pager">\n'
            '        <div class="pager-btns"><button class="pager-btn">1</button></div>\n'
            "      </div>\n"
            "    </div>\n"
            "  </section>\n"
            '  <div class="menu-overlay" :class="{ \'is-on\': open }" />\n'
            '  <aside class="menu-drawer" :class="{ \'is-on\': open }">\n'
            "  </aside>\n"
            "</div>\n"
        )
        with mock.patch("guard_ui_pattern.changed_files", return_value=["frontend/src/components/GoodPanel.vue"]):
            panel_path = paths.ROOT / "frontend/src/components/GoodPanel.vue"
            panel_path.parent.mkdir(parents=True, exist_ok=True)
            try:
                panel_path.write_text(good_panel, encoding="utf-8")
                issues = ui_pattern_issues("HEAD")
            finally:
                if panel_path.is_file():
                    panel_path.unlink()
        self.assertEqual(issues, [])

    def test_ui_pattern_issues_detects_menu_filter_bar(self) -> None:
        from guard_ui_pattern import ui_pattern_issues

        bad_panel = (
            '<div class="menu-manage bad-manage">\n'
            '  <header class="menu-page-toolbar"><PageHeadBar /></header>\n'
            '  <div class="menu-filter-bar"><input /></div>\n'
            '  <div class="role-table-wrap"><table class="role-table"></table></div>\n'
            '  <div class="role-panel-foot"><div class="role-panel-foot__pager"></div></div>\n'
            "</div>\n"
        )
        with mock.patch(
            "guard_ui_pattern.changed_files",
            return_value=["frontend/src/components/FilterBarPanel.vue"],
        ):
            panel_path = paths.ROOT / "frontend/src/components/FilterBarPanel.vue"
            panel_path.parent.mkdir(parents=True, exist_ok=True)
            try:
                panel_path.write_text(bad_panel, encoding="utf-8")
                issues = ui_pattern_issues("HEAD")
            finally:
                if panel_path.is_file():
                    panel_path.unlink()
        self.assertTrue(any("menu-filter-bar" in issue for issue in issues))

    def test_ui_pattern_issues_detects_missing_menu_panel(self) -> None:
        from guard_ui_pattern import ui_pattern_issues

        bad_panel = (
            '<div class="menu-manage bad-manage">\n'
            '  <header class="menu-page-toolbar"><PageHeadBar /></header>\n'
            '  <div class="role-table-wrap"><table class="role-table"></table></div>\n'
            '  <div class="role-panel-foot"><div class="role-panel-foot__pager"></div></div>\n'
            "</div>\n"
        )
        with mock.patch(
            "guard_ui_pattern.changed_files",
            return_value=["frontend/src/components/NoMenuPanel.vue"],
        ):
            panel_path = paths.ROOT / "frontend/src/components/NoMenuPanel.vue"
            panel_path.parent.mkdir(parents=True, exist_ok=True)
            try:
                panel_path.write_text(bad_panel, encoding="utf-8")
                issues = ui_pattern_issues("HEAD")
            finally:
                if panel_path.is_file():
                    panel_path.unlink()
        self.assertTrue(any("menu-panel" in issue for issue in issues))

    def test_pattern_guard_spec_loads_yaml(self) -> None:
        from guardlib.pattern_guard_spec import load_table_first_guard_spec

        spec = load_table_first_guard_spec()
        self.assertIn("PageHeadBar", spec.trigger_requires_all)
        self.assertIn("menu-panel", spec.required_tokens)
        self.assertIn("menu-filter-bar", spec.forbidden_tokens)

    def test_ui_pattern_issues_detects_missing_pager(self) -> None:
        from guard_ui_pattern import ui_pattern_issues

        panel_missing_pager = (
            "const pageSize = ref(10)\n"
            '<div class="role-panel-foot">\n'
            '  <span class="role-panel-foot__summary">共 1 条</span>\n'
            "</div>\n"
        )
        with mock.patch(
            "guard_ui_pattern.changed_files",
            return_value=["frontend/src/components/MissingPagerPanel.vue"],
        ):
            panel_path = paths.ROOT / "frontend/src/components/MissingPagerPanel.vue"
            panel_path.parent.mkdir(parents=True, exist_ok=True)
            try:
                panel_path.write_text(panel_missing_pager, encoding="utf-8")
                issues = ui_pattern_issues("HEAD")
            finally:
                if panel_path.is_file():
                    panel_path.unlink()
        self.assertTrue(any("role-panel-foot__pager" in issue for issue in issues))


if __name__ == "__main__":
    unittest.main()
