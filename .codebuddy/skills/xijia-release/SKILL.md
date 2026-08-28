---
name: xijia-release
description: "Load when /xijia:release, 发版, release, 封版切发布分支. Not Gate-2."
---

# Xijia Release（发布）

## 边界

| Gate-2（单需求） | Release Gate（本技能） |
| --- | --- |
| 本 requirement AC 验收 | `master` 集成批次可上线 |
| `/xijia:start` 收尾 | `/xijia:release` |
| `--check-release --req` | `--check-release-readiness` |

**需求完成 ≠ 可发布**：各需求须已 Gate-3 + `--check-closeout` 通过。

## 何时使用

- 计划从 `master` 切出 `release/<版本>` 封版
- 用户说「发布 / 上线 / 发版」

## 硬约束

1. 先运行 `python .codebuddy/hooks/pipeline_guard.py --check-release-readiness`
2. 审阅 `docs/process/release-checklist.md`；Release Gate 须**文字**批准（含版本或范围）
3. **禁止**自动切分支/merge/push；须用户显式触发（`47-release-lifecycle.mdc`、`46-git-branching.mdc`）
4. hotfix 基于已发布 `release/<版本>` 修复后须回合 `master`

## 执行步骤

1. `--check-release-readiness`；exit≠0 列修复项或记录书面豁免
2. 检查 inbox 未完成需求、git 分支、工作区状态
3. 核对 AGENTS 命令与 CI/「仅本地 CI」声明
4. **（旁路）经验文档复用评分**：`python .codebuddy/skills/xijia-docs-score/scripts/score_docs.py`（默认 patterns/pitfalls/decisions；非阻断；复用/修订候选记入 checklist，勿当全库删除清单）
5. 提请 Release Gate；用户文字批准后更新 checklist 签字行
6. 提醒用户从 `master` 切出 `release/<版本>` 并执行发布后 smoke（checklist 内）

## 输出格式

与 [`/xijia:release`](../../commands/xijia-release.md) 命令一致。

## 相关

- 规则：`.codebuddy/rules/47-release-lifecycle.mdc`
- 生命周期：`docs/process/project-lifecycle.md`

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 单需求 Gate-2 当可发布 | 混淆 Gate | 须全批次 Gate-3 + closeout |
| 自动切发布分支 | 硬约束 | 仅用户显式触发 |
| readiness WARN 忽略 | inbox/未提交 | 人工确认后再 Release Gate |
| hotfix 未回合 master | 修复只存在发布分支 | 合入 `release/<版本>` 后必须 merge 回 `master` |
