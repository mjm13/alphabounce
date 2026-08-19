---
name: /opsx-analyze
id: opsx-analyze
category: Workflow
description: Analyze spec/design/tasks/test traceability before implementation
---

Run `openspec-analyze` to validate cross-artifact consistency before implementation.

## Goal

Block implementation if `In Scope` AC cannot be traced to:

- `tasks.md` execution items
- delta `spec.md` requirements
- verification/test strategy

## Mandatory behavior

- Prefer running after `/opsx:propose` and before implementation.
- Report gaps as blocking items with remediation steps.
- If no blocking gaps remain, state "ready for openspec-superpowers-apply".
