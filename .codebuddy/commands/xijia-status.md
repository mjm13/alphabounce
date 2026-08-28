---
name: /xijia-status
id: xijia-status
category: Workflow
description: Lightweight pipeline snapshot (fast, no full guard audit)
---

Provide a **fast, read-only** Xijia pipeline snapshot. Optimized for speed - not a release/verify audit.

## Goal

Decision-ready snapshot in **<=3 tool rounds**:

- Active requirement / change (if any)
- Tier, change type, stage (from file evidence only)
- Git working tree summary
- Optional quick test signal (only when implementation code changed per AGENTS.md)
- Compressed CTA lines (①–④ 各 1 行)

## Scope (strict - do NOT expand)

### Allowed reads (pick minimal set)

1. **Active requirement** — 选取规则与 `/xijia:start` **一致**（见 `multi-inbox.md`）：
   - 用户指定 path；或
   - `python .codebuddy/hooks/pipeline_guard.py --scan-inbox`（优先）；或
   - 单篇 inbox 时读该篇
2. **If red tier suspected**: list `docs/openspec/changes/<name>/` for that change only.
3. `git status --short` (once).
4. **Optional** quick test per `AGENTS.md` (60s budget).

### Forbidden in this command

- Do **not** run full guard audit (`--check-release`, `--audit`, `--check-intake`, `--check-plan`).
- Do **not** load full ops-pipeline verify chain or implement code.

## How to determine status

1. From active requirement YAML: `分级` / `类型` / `状态` / Gate records only.
2. Infer stage from doc + change folder (if red).
3. Mark `unknown` when evidence missing; ask **one** focused follow-up max.

## Output format（压缩 CTA，不跑 guard）

```markdown
## Xijia 流水线状态（轻量）

- 需求: `<path>` · active-req 规则同 start
- 环节: Gate-1 待批准 · 001 系统参数设置（黄 · 混合）
- 进度: Gate-0 ✅ → Plan ✅ → Gate-1 ⏳ → …
- 阻塞: （无则省略本行）
- **请你:** （1 行，来自 frontmatter/环节推断）
- **然后:** （1 行 Agent 动作推断）
- Git: <干净 | N 修改>
- 测试: <通过|失败|跳过>
- 备注: 完整 CTA → `/xijia:start`；诊断 → 「展开诊断」
```

## Guardrails

- Target latency: minimal reads; **禁止**用 mtime 单独 override active-req 规则。
- Full Gate-2 / CTA skeleton → `/xijia:start`（`--format cta`）。
