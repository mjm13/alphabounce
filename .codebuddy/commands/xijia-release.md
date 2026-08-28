---
name: /xijia-release
id: xijia-release
category: Workflow
description: Release readiness audit and Release Gate request (dev to main)
---

Read-only release audit + Release Gate workflow. Rules: `.codebuddy/rules/47-release-lifecycle.mdc`.

Use `xijia-release` skill (single orchestration entry for this request).

## Goal

1. Run objective release readiness check
2. Review `docs/process/release-checklist.md`
3. Report blockers and request **Release Gate** human approval (text reply)
4. Do **not** merge to `main` or push until user explicitly asks after approval

## Mandatory steps

1. Run:

```bash
python .codebuddy/hooks/pipeline_guard.py --check-release-readiness
```

2. Read `docs/process/release-checklist.md` — note version, scope, unchecked items
3. Summarize:
   - Active inbox requirements (if any)
   - AGENTS.md command readiness
   - CI file presence vs local-only declaration
   - Git branch and working tree ( `git status --short`, current branch )
4. If audit exit≠0: list fixes; stop before Release Gate request unless user acknowledges exemptions in writing
5. If audit pass: present Release Gate checklist; ask user for **text approval** including version or release scope

## Forbidden

- Auto-cut `release/<version>` from `master`
- Auto-push
- Treat Gate-2 (single requirement) as Release Gate

## Output format

```markdown
## Xijia Release 状态

- 审计: `check-release-readiness` exit <0|1|2>
- 客观项: <pass/fail 摘要>
- 警告: <inbox 未完成 / 非 dev 分支 / 未提交改动 等>
- Checklist: <release-checklist.md 完成度>
- Release Gate: <待批准 | 已批准 + 审批人/日期>
- 下一步: <用户触发 merge/push | 修复阻塞项>
- 阻塞项: <无或列表>
```

## Related

- Single requirement verify: `/xijia:start` + `--check-release --req`
- Git policy: `46-git-branching.mdc`
- Lifecycle map: `docs/process/project-lifecycle.md`
