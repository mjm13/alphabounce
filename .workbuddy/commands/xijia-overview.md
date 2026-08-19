---
name: /xijia-overview
id: xijia-overview
category: Workflow
description: Read-only project snapshot (modules, capability index, BC relations)
---

Use `xijia-project-overview` skill for this request.

## Goal

Answer **what this project is** (not current requirement progress — use `/xijia:status` for that):

- Tech stack and path anchors from `AGENTS.md`
- Module/capability index from `docs/capability-map.md`
- Cross-module relations from `docs/domain/context-map.md`
- **Business main flows** from `docs/flow.md` (derive from capability-map if missing)
- Shipped requirement **count only** (do not read shipped bodies)

## Scope (strict)

### Allowed reads (<=6 tool rounds)

1. `AGENTS.md` §2–§3
2. `docs/capability-map.md` (if exists)
3. `docs/domain/context-map.md` (if exists)
4. `docs/flow.md` (if exists; main business flows)
5. `docs/requirements/shipped/` file count only (`glob` or `ls`, no body read)

### Forbidden

- `pipeline_guard.py` full audit
- Reading `docs/requirements/shipped/*.md` bodies
- Reading `docs/requirements/inbox/`
- Loading full `xijia-ops-pipeline`

## Output

See `xijia-project-overview` skill status block.

## Related

| Command | When |
| --- | --- |
| `/xijia:status` | Current requirement pipeline stage |
| `/xijia:backfill-index` | Bootstrap capability-map from shipped history |
| `/xijia:prd` | PRD → inbox with Step 1.7 cross-check |
