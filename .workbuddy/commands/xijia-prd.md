---
name: /xijia:prd
id: xijia-prd
category: Workflow
description: Convert PRD (with optional prototype) into inbox requirement docs (symmetric to defect intake)
---

Use `xijia-prd-to-requirement` skill for this request.

## Goal

Convert a **PRD** (optionally with prototype references) into one or more inbox requirement documents — symmetric to defect → `/xijia:defect`.

**This command creates requirement docs; it does not implement features.**

Recommended after engineering baseline Gate-3. See `docs/process/project-lifecycle.md`.

## Input

The argument after `/xijia:prd` can be:

- PRD text or file path
- Module scope for multi-doc split
- Prototype links or references (triggers Step 1.1/1.2 early-diff hard stop)

If information is insufficient, the skill stops and asks for missing scope/details.

## Mandatory behavior

- Follow `xijia-prd-to-requirement` SOP
- Run codegraph architecture probe when MCP available
- **Step 1.1/1.2**: produce「原型现状（相对 PRD）」table and confirm口径 before multi-doc落盘
- Gate-0: data flow closure table + tier/type in frontmatter
- **Gate-1 by tier**: 无原型+UI 时 fill `## 页面布局预览` → `## 验收标准` + `## 实现方案` at落盘（see `.cursor/templates/requirements/gate1-by-tier.md`）；红档须说明 OpenSpec 变更名/目录与建包时机
- Run `pipeline_guard.py --check-intake` **and** `--check-plan` before handoff
- **No non-doc code changes** before Gate-1
- After intake+plan pass, tell user: `/xijia:start <req-file>`

## Related commands

| Command | When |
| --- | --- |
| `/xijia:prd` | **Split** PRD → inbox（含按分档写满 Gate-1） |
| `/xijia:defect` | **Register** defect → inbox |
| `/xijia:start` | **Implement**；plan 缺口时 A.0.5 增量补全 |
| `/xijia:release` | Batch release |

## Output format

See `xijia-prd-to-requirement` status block.
