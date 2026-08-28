---
name: /xijia-adopt
id: xijia-adopt
category: Workflow
description: Historical multi-module project adoption (scaffold through verify)
---

Use `xijia-project-adopt` as the single adoption skill for this request.

## Goal

Onboard an **existing multi-module workspace** (not greenfield):

1. **scaffold** — docs skeleton, manifest shell, `.cursorignore` / `.gitignore`, ADR-0002
2. **preflight** — codegraph CLI + per-module init + dynamic `.codebuddy/mcp.json`
3. **discover** — scan code → draft manifest / AGENTS / architecture / DDD candidates
4. **content** — human confirm drafts (`discovery.status=confirmed`)
5. **verify** — `--check-adopt-readiness` + Adoption Gate sign-off

**Do not** use `/xijia:init` for historical adoption. **Do not** create bootstrap requirement seeds.

## Input

The argument after `/xijia:adopt` can be:

- `scaffold` | `preflight` | `discover` | `content` | `verify`
- `全量` / full flow from current `adopt.stage`
- A description of the legacy workspace to adopt

## Mandatory behavior

- Hard block if `.codebuddy/rules/` missing (Step 2 xijia-base copy not done)
- Hard block if `adopt.stage=done` and user reruns verify → point to `/xijia:start`
- **supplement-scaffold** when `docs/` exists but manifest missing (only add missing files)
- Never copy default MySQL MCP credentials from xijia-base template
- discover output is **draft only**; verify blocked until content confirms (H10)
- preflight: install/init codegraph per backend/frontend module unless `--skip-codegraph`
- verify must run: `pipeline_guard.py --check-adopt-readiness`, `policy_flow_drift_check.py`, `--check-doc-links`
- After Adoption Gate: write `docs/process/adopt-readiness.md`; set `adopt.stage=done`
- **Next** after done: `/xijia:prd` or `/xijia:start`

## Output format

```markdown
## Xijia Adopt Status

- Stage: <guard|interview|manifest-confirm|scaffold|preflight|discover|content|verify|done>
- Mode: <adopt|supplement-scaffold>
- AdoptStage: <manifest adopt.stage value>
- Created/Updated: <files>
- Modules: <count + keys>
- Codegraph: <ready|skipped|blocked>
- Discovery: <draft paths>
- DDD Draft: <docs/domain/_draft/* or none>
- Readiness: <check-adopt-readiness pass/fail summary>
- Warnings: <W* list>
- Next: </xijia:adopt next-stage | /xijia:start | /xijia:prd>
- Blockers: <none or list>
```
