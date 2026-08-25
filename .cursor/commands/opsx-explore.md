---
name: /opsx-explore
id: opsx-explore
category: Workflow
description: Enter explore mode - think through ideas, investigate problems, clarify requirements
---

Use `openspec-explore` skill for this request.

## Goal

Enter **explore mode** — thinking partner for ideas, problems, and requirements **before** implementation.

**Explore is for thinking, not implementing.** No code changes unless user explicitly asks for OpenSpec artifacts (proposal/design/spec).

## Input

The argument after `/opsx:explore` can be:

- A vague idea, specific problem, change name, or comparison
- Nothing (enter explore mode in current context)

## Mandatory behavior

- Invoke and follow `openspec-explore` skill (stance + guardrails are defined there)
- If user asks to implement, redirect to `/opsx:propose` then `/opsx:apply`
