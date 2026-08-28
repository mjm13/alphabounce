---
name: /xijia-backfill-index
id: xijia-backfill-index
category: Workflow
description: One-time merge of shipped requirements into capability-map (bootstrap)
---

Use `xijia-backfill-index` skill for this request.

## Goal

Bootstrap `docs/capability-map.md` from historical `docs/requirements/shipped/*.md` using **merge** semantics (no blind append).

## When

- Existing project with shipped requirements but empty/stale capability-map
- After `INDEX_STALE` warning from PRD Step 1.7

## Mandatory behavior

1. Run dry-run first: `python .codebuddy/hooks/extract_capability_index.py --backfill --dry-run`
2. Show merge preview (ADD/UPDATE counts) to user
3. Apply only after user confirms: same command without `--dry-run`
4. Skip engineering seed requirements marked with YAML property `种子: true` by default

## Forbidden

- Overwriting without dry-run preview
- Daily use (normal path is Gate-3 per requirement)

## Output

See `xijia-backfill-index` skill status block.
