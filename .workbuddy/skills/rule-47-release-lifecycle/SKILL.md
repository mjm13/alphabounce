---
name: rule-47-release-lifecycle
description: "发布生命周期（Release Gate、dev→main、与需求 Gate-2 分层） [globs:- docs/process/** - docs/requirements/** - AGENTS.md]"
agent_created: true
---

# 定位说明

本规则定义 **发布级** 流程，与单需求 **Gate-2（需求验收）** 分层：

| 门禁 | 范围 | 含义 |
| --- | --- | --- |
| Gate-2 | 单个 requirement | 本需求 AC 满足、可归档 |
| Release Gate | dev→main 集成 | 本次上线批次可发布 |

**需求完成 ≠ 可发布**：需求 Gate-3 完成后仍须走发布流程（若本批次要上线）。

# 触发条件

- 计划将 `dev` 合并入 `main`（见 `46-git-branching.mdc`）
- 用户执行 `/xijia:release` 或等价发布意图

# 硬约束（Must）

1. 合并 `main` 前须运行 `python .cursor/hooks/pipeline_guard.py --check-release-readiness`；客观项 exit≠0 须修复或记录豁免后再提请 Release Gate。
2. Release Gate 须用户在对话中**文字批准**（含版本号或发布范围）；AskQuestion 点选不构成批准。
3. `commit` / `push` / 合并到 `main` 须用户显式触发（同 `46-git-branching.mdc`）。
4. `docs/process/release-checklist.md` 须存在；Release Gate 签字须回填该文档。
5. inbox 中未完成需求不得静默打入发布批次；须归档、延期入 backlog 或明确排除在本次 Release Notes 外。

# 发布前检查（方向）

| 项 | 说明 |
| --- | --- |
| verify 证据 | dev 上测试/构建可执行证据（本地或 CI，见 `AGENTS.md`） |
| 迁移与回滚 | 有 DB 变更时须方案与回滚路径 |
| 变更说明 | Release Notes / 变更日志 |
| 环境晋升 | dev → staging → prod 步骤在 checklist 或 AGENTS 可追溯 |
| 冒烟 | 发布后最小验证清单（checklist 或 runbook） |

# hotfix 例外

- 基于 `main` 的紧急修复：合入 `main` 后 **必须回合** `dev`。
- hotfix 仍建议走 `/xijia:defect` 登记 + `/xijia:start` 留痕；Release Gate 可简化为「hotfix 范围 + 验证命令」文字批准。

# 与 CI 的关系

- CI 配置为占位或真实流水线均可；truth 为 `AGENTS.md` 可执行命令 + `--check-release-readiness` 审计。
- init 模板提供 `.github/workflows/ci.yml` 占位；未启用 CI 须在 AGENTS 或 checklist 声明等价本地验证命令。

# 升级触发（When to Escalate）

- 跨多个 BC 的大规模发布 → 补充 ADR / 发布 runbook
- 需停机或破坏性迁移 → Approval Gates（`00-workflow.mdc`）
- 发布后 SEV-1/2 → `docs/process/incident-response.md`

# 验收口径（Release Done Means）

- `--check-release-readiness` 客观项通过或豁免已记录
- Release Gate 人工签字已写入 `release-checklist.md`
- dev→main 合并由用户触发且已完成（或用户明确取消发布）
- 发布后冒烟项已执行或明确 defer 入 backlog
