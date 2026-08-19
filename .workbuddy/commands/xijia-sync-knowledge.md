---
name: /xijia-sync-knowledge
id: xijia-sync-knowledge
category: Workflow
description: Gate-3 knowledge sync for all tiers — living docs, archive, ADR, domain promotion
---

Run **Gate-3** knowledge sync using the project standard. **All tiers** (green/yellow/red) must execute this after Gate-2 sign-off — not only red/OpenSpec changes.

**When Gate-2 is signed and the requirement is still in inbox**, this command is a **mandatory same-turn continuation** — not a second user invocation. Do not ask「是否继续 Gate-3」. If `--check-release` still has blockers after Gate-2, fix them **inside** this chain before Move; blockers are not a reason to stop the turn.

## Goal

After requirement Gate-2 approval, invoke `xijia-sync-knowledge` to:

- Run **Gate-3 trigger report** (`--gate3-trigger-report`) and present deposition candidates
- Promote stable conclusions to living docs (`AGENTS.md`, `docs/README.md`, `docs/llms.txt`, etc.)
- Archive process docs (`inbox` → `shipped`; red OpenSpec → `changes/archive/`)
- Capture ADR / patterns / pitfalls / domain (tier-dependent scope per skill)
- Run `--check-closeout` and remind user to commit

## Mandatory behavior

1. Confirm target requirement path (`docs/requirements/inbox/<file>.md`).
2. Verify Gate-2 approval is recorded in the requirement; if not, stop and explain.
3. **First command:** `python .cursor/hooks/pipeline_guard.py --gate3-trigger-report --req <inbox-path>`
4. Present **Gate-3 沉淀候选（须人确认）**; on B-class patterns/pitfalls, confirm or mark「跳过」before Move — **do not stop the turn** waiting for a second user command after Gate-2 sign-off.
5. **Invoke and follow** `xijia-sync-knowledge` skill (full tier-scoped steps — do not skip green/yellow because there is no OpenSpec change).
6. Produce sync report per skill output format below.
7. Run `python .cursor/hooks/pipeline_guard.py --check-closeout --req <shipped-requirement-path>`.

## Tier scope (summary)

| Tier | domain promotion | OpenSpec archive | living docs / patterns |
| --- | --- | --- | --- |
| green / green-trivial / yellow | skip | skip | on trigger |
| red | yes (`changes/<name>/domain` → `docs/domain`) | yes | on trigger |

Details: see `xijia-sync-knowledge` skill — it is the single source of truth.

## Output format

```markdown
## Xijia Knowledge Sync Result

- Requirement: <path>
- Tier: <green|yellow|red>

### Gate-3 沉淀候选（须人确认）
- 强制：<capability / domain / Experience Reuse …>
- 建议 patterns：<path> [待确认|已确认|跳过]
- 建议 pitfalls：<path> [待确认|已确认|跳过]

- Living Docs: <updated paths or no-op>
- Archived: <inbox→shipped yes/no; openspec archive yes/no/n/a>
- Promoted to docs/domain: <items or n/a>
- ADR / patterns / pitfalls: <items or none>
- check-closeout: <pass|fail>
- Next: commit code + Gate-3 docs together
```

## Guardrails

- Do not skip Gate-3 for green/yellow requirements.
- Do not skip `--gate3-trigger-report` before writing deposition markers.
- Do not write to `docs/domain/*` from unarchived red changes.
- If evidence is insufficient, keep content in change draft and report uncertainty.
