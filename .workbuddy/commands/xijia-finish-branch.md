---
name: /xijia-finish-branch
id: xijia-finish-branch
category: Workflow
description: Complete dev work and integrate (wraps Superpowers finishing-a-development-branch)
---

## Xijia override

Load **`finishing-a-development-branch`** Superpowers skill for the full process.

**Xijia constraints (in addition to vendor skill):**

- Default integration target: **`dev`** branch (see `46-git-branching.mdc`); merge to `main` only via `/xijia:release` + Release Gate
- Before finish: requirement in scope should have passed Gate-3 or user explicitly accepts partial state
- Tests: use commands from `AGENTS.md`, not hardcoded stack examples in vendor body
- Do not force-push `main`

## When to use

- Implementation complete, tests pass, choosing merge / PR / cleanup on **dev**

## Output

Follow vendor skill output + note xijia branch policy and next step (`/xijia:release` if targeting production).
