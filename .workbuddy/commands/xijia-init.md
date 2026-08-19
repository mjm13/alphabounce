---
name: /xijia-init
id: xijia-init
category: Workflow
description: Xijia project bootstrap entrypoint for empty repository
---

Use `xijia-project-init` as the single initialization skill for this request.

## Goal

Cold-start an empty repository in one flow:

1. Guard against overwriting existing initialized repositories
2. Collect bootstrap info (stack, paths, frontend/DB flags)
3. **docs-render**: skeleton docs and workflow files
4. Confirm technology stack and install top-rated skills (**hard cap: 10**; skip if not found)
5. Optionally generate `.cursor/mcp.json` when paths confirmed (no default DB credentials)
6. **code-shell**: create empty backend/frontend dirs (merged into init; not a separate main step)
7. **seed-bootstrap-reqs**: write technical inbox seeds (backend always when new; frontend if needed; runtime baseline if DB=yes)
8. Keep `docs/architecture.md` and `docs/capability-map.md` on-demand (not init pre-generated)

**Do not** run framework CLIs inside init. Runnable apps are created via `/xijia:start` on seeded requirements after Gate-1.

## Input

The argument after `/xijia:init` can be:

- A project bootstrap description
- A request to initialize docs and process structure from scratch

## Mandatory behavior

- Stop by default if `docs/` or `AGENTS.md` already exists; use **supplement-only** mode when user only needs missing code-shell dirs (code-shell stage only; no re-seeding)
- Do not set technology stack without user confirmation
- Stage name for docs writing is **`docs-render`** (never call it `scaffold`)
- **UTF-8**：渲染 `templates/*.tmpl` 时用 `scripts/render_init_templates.py` 或 Agent Write；禁止 PowerShell 默认 `Get-Content` 管道（见 skill「UTF-8 编码」节）
- Support two install strategies after stack confirmation:
  - auto install: per stack top 2–3, **≤10 skills total**
  - recommendation-only (do not install, only report candidates and scores)
- Default strategy is `auto install`; use `recommendation-only` only when user explicitly selects it
- **找不到就不装**：单个 skill 安装失败或未找到匹配项时，记录 skipped + 原因，**禁止**用其它 skill、整库或其它 repo 顶替
- In `auto install` mode, **zero stack skills installed is allowed** if all candidates failed/skipped; do not mark `blocked` solely for that reason
- If installed count **>10** or bulk install detected, status must be `blocked`
- `Skills Installed` must include objective evidence: command used + success/fail + retry reason for failures
- Skip seeding “from-scratch bootstrap” reqs when target code roots already non-empty
- Run `self-check` before marking `done`
- **Next** must point to `/xijia:start docs/requirements/inbox/<first-seed>.md` when seeds exist
- Remind: after engineering baseline Gate-3, use `xijia-prd-to-requirement` for business PRDs

## Output format

Always return a concise status block:

```markdown
## Xijia Init Status

- Stage: <guard|interview|manifest-confirm|docs-render|skills-bootstrap|code-shell|seed-bootstrap-reqs|self-check|done>
- Mode: <empty-repo|supplement-only>
- Created: <files/directories>
- CodeShell: <created|skipped>
- Seeded Requirements: <list or none>
- Skipped: <existing files kept untouched>
- Stack Confirmed: <yes/no + summary>
- Skills Selected: <name + score + source>
- Skills Installed: <success list or recommendation-only>
- Skills Skipped: <name + reason>
- Install Evidence: <commands run + key outputs + retries>
- SelfCheck:
  - requiredFiles: <pass/fail + details>
  - frontmatterValidity: <pass/fail + details>
  - entrypointAvailability: <pass/fail + details>
  - driftScan: <pass/fail + details>
  - policyFlowDrift: <pass/fail + details>
- Next: /xijia:start docs/requirements/inbox/<YYYYMMDDHHMMSS-…>.md
- Blockers: <none or list>
```
