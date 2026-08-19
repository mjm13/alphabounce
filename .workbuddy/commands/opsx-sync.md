---
name: /opsx-sync
id: opsx-sync
category: Workflow
description: Sync delta specs from a change to main specs without archiving
---

Use `openspec-sync-specs` skill for this request.

## Goal

Merge delta specs from an active change into main specs **without** archiving the change.

## Input

Optionally specify change name after `/opsx:sync`. If omitted, skill prompts via `openspec list`.

## Mandatory behavior

- Invoke and follow `openspec-sync-specs` skill
- Do not archive the change as part of sync
