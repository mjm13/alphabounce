---
name: /opsx-propose
id: opsx-propose
category: Workflow
description: Propose a new OpenSpec change with design, specs, and tasks in one step
---

Use `openspec-propose` skill for this request.

## Goal

Create a new OpenSpec change with artifacts: `proposal.md`, `design.md`, `tasks.md`, delta specs — ready for `/opsx:analyze` and `/opsx:apply`.

## Input

The argument after `/opsx:propose` should include:

- Change name (kebab-case), or
- Description of what to build (skill will derive name)

## Mandatory behavior

- Invoke and follow `openspec-propose` skill
- After propose, suggest `/opsx:analyze` before implementation
- Implementation entry: `/opsx:apply` (defaults to `openspec-superpowers-apply`)
