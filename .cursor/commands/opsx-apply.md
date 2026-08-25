---
name: /opsx-apply
id: opsx-apply
category: Workflow
description: Implement tasks from an OpenSpec change (Experimental)
---

Use `openspec-superpowers-apply` skill for this request — **default and recommended**.

## Goal

Implement tasks from an OpenSpec change with TDD, verification, comment-sync, and xijia-quality-judge gates.

## Input

Optionally specify change name (e.g., `/opsx:apply add-auth`). If omitted, infer from context or prompt.

## Mandatory behavior

1. **Default**: invoke `openspec-superpowers-apply` (do not裸跑).
2. **Fallback only**: if user explicitly requests「裸跑 apply / 不加载 superpowers」, invoke `openspec-apply-change` instead and warn that TDD/quality gates are skipped.

## Related

| Command | When |
| --- | --- |
| `/opsx:propose` | Create change artifacts |
| `/opsx:analyze` | Pre-implementation consistency gate |
| `/opsx:apply` | Implement (this command) |
| `/opsx:archive` | Archive after verify |
