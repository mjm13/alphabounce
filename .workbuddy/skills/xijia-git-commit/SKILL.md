---
name: xijia-git-commit
description: "Load when commit, 提交代码, 帮我提交."
agent_created: true
---

# Git 提交（关联需求 + 范围总结）

每次提交可追溯：关联需求/bug，message 说明**为什么**改，遵守 `00-workflow.mdc` 收尾门禁与 Git 安全协议。

## 触发

准备 commit、用户说「提交/commit」、需求切片收尾最终提交时。

## 执行（意图式）

1. **收集变更证据**并对齐本仓近期提交风格（status、diff、log）。
2. **关联需求**：分支名 `change/<name>` → requirement 路径；或 inbox 进行中需求。唯一命中直接关联；多/零命中才问用户。
3. **归纳范围**：按目录归类「改了什么 + 为什么」，不逐行复述 diff。
4. **生成 message**：
   - 关联 requirement：标题固定为 `【<需求文件名>】`（basename 含 `.md`）；同一需求的分批提交使用同一标题；正文含 `Refs: <requirement-path>`。
   - 不关联 requirement：沿用约定式 `feat|fix|refactor|chore|docs|test`。
5. **提交前门禁**：无密钥文件；Gate-2 已签字才可对外称「已完成提交」；不改 git config、不 `--no-verify`、不擅自 push/amend 已推送提交。
6. **提交并核验**：暂存相关文件提交；**中文 message 见 GOTCHAS**；`git log -1` 确认未损坏。

## Message 模板

```
【<需求文件名>】

- <要点 1>
- <要点 2>

Refs: docs/requirements/inbox/<file>.md
```

缺陷需求同样使用需求文件名标题，可在正文保留 `Fixes:` 脚注。Approval Gate 命中先暂停确认。

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| `git log` 中文变 `?` | PowerShell 管道非 UTF-8 | message 写 UTF-8 文件，`git commit -F <file>` |
| 关联不存在的 requirement | 路径臆造 | 提交前确认文件存在 |
| 未 Gate-2 却称需求完成 | 收尾顺序错 | 状态迁移在 commit 前按 closeout 走完 |
| 含 `.env` 仍提交 | 未做密钥扫描 | 警告并暂停，等用户确认 |

## 约束

push 仅用户明确要求；需求状态迁移与 Gate-3 文档仍按 `xijia-ops-pipeline/references/closeout-steps.md`。
