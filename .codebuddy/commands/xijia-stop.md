---
name: /xijia-stop
id: xijia-stop
category: Workflow
description: Stop current change — revert code/data and reset Gate-1 to 待批准
---

Terminate the current change: revert implementation and reset Gate-1 approval.

## Goal

Provide a safe stop flow without leaving orphan code or a falsely「已批准」Gate-1.

## Mandatory behavior

1. Confirm which requirement or change is being stopped.
2. Confirm stop reason (required).
3. Invoke and follow `xijia-abandon-change`.
4. Ensure abandon is complete:
   - Code and data impact reverted per skill
   - Do not run `/opsx:sync`
   - OpenSpec change folder deleted (not archived), if any
   - Requirement Gate-1 reset to `待批准` (only YAML line changed; no `dropped/` folder)
5. Summarize what was reverted vs retained.

## Output format

```markdown
## Xijia Stop Result

- Requirement: <path>
- Reason: <text>
- Gate-1 reset: 待批准
- Code reverted: <summary>
- Data: <DB/Redis summary>
- OpenSpec: deleted <name> | n/a
- Synced Specs: no
- Tests: <command + exit code>
- Next: <optional follow-up, e.g. re-request Gate-1 approval>
```

## Guardrails

- Do not silently delete uncertain data; ask when scope is unclear.
- Do not modify `inbox/README` or move requirements to `dropped/` as part of stop.
- If change has already been archived/released, stop and ask for explicit offboarding plan.
