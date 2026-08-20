---
name: /xijia-defect
id: xijia-defect
category: Workflow
description: Register a bug/defect into inbox requirement doc (symmetric to PRD intake)
---

Use `xijia-defect-to-requirement` skill for this request.

## Goal

Convert a **defect report** (repro steps, actual vs expected behavior, environment) into an inbox requirement document — symmetric to PRD → `xijia-prd-to-requirement`.

**This command registers the defect; it does not fix code.**

## Input

The argument after `/xijia:defect` can be:

- Free-text bug description
- Repro steps + expected behavior
- Link to issue / log / trace_id context

If information is insufficient, the skill stops and asks for missing repro/expected details.

## Mandatory behavior

- Follow `xijia-defect-to-requirement` SOP
- Base document on `.cursor/templates/requirements/defect-template.md`
- Set frontmatter `类型: 缺陷`; default tier `绿` or `绿-轻量`
- Gate-0 simplified: repro + expected + AC → `complete`; only declare no new dataflow when Source/Process/Sink are unchanged, otherwise fill the closure table
- Lightweight codegraph probe when MCP available (code location + regression hints)
- Run `pipeline_guard.py --check-intake --req <file>` before handoff
- **No non-doc code changes** before Gate-1 (that happens in `/xijia:start`)
- After intake passes, tell user: `/xijia:start <req-file>`

## Related commands

| Command | When |
| --- | --- |
| `/xijia:defect` | **Register** new defect → inbox |
| `/xijia:prd` | **Split** PRD → inbox requirements |
| `/xijia:start` | **Fix** after defect doc exists |
| `/xijia:release` | Batch release (hotfix may need merge-back to master) |

## Output format

See `xijia-defect-to-requirement` status block.
