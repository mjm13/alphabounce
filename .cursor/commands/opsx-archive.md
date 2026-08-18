---
name: /opsx-archive
id: opsx-archive
category: Workflow
description: Archive a completed OpenSpec change after implementation
---

Use `openspec-archive-change` skill for this request.

## Goal

Finalize and archive a completed change. Typically followed by Gate-3 `xijia-sync-knowledge` for red-tier requirements.

## Input

Optionally specify change name after `/opsx:archive`. If omitted, skill prompts — **do not guess**.

## Mandatory behavior

- Invoke and follow `openspec-archive-change` skill
- After archive, remind: run `/xijia:sync-knowledge` when requirement Gate-2 is signed (red tier)
