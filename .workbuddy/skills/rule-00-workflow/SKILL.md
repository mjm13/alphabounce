---
name: rule-00-workflow
description: "xijia 研发宪法（硬停 + guard 指针）；详细步骤见 xijia-ops-pipeline [alwaysApply]"
agent_created: true
---

# 核心定位

- 真相源：测试 > spec；代码与已发布文档共同构成事实。
- 流程入口：优先 `/xijia:start`（`xijia-ops-pipeline`）；**空仓库**用 `/xijia:init`；**历史多模块**用 `/xijia:adopt`；单步命令见 `docs/process/project-lifecycle.md`。
- **详细执行步骤在技能中**；本文件只保留硬门禁与 guard 指针。
- 项目级硬约束：`docs/constitution.md`。

# 需求分级（摘要）

- Gate-0 先于分级：`已通过|部分通过|已驳回`（schema 见 `45-requirement-intake.mdc`；程序见 `.cursor/templates/requirements/gate0-intake.md`）。
- 分级矩阵与路由：`xijia-ops-pipeline/references/tier-routing.md`。
- frontmatter 须写 `分级`/`类型`（中文值）；`分级=红` 填 `openspec变更`。
- 🟢/🟡 Gate-1 前须有「验收标准 + 实现方案」：优先在 `/xijia:prd` 按分档写满（见 `.cursor/templates/requirements/gate1-by-tier.md`）；缺失由 A.0.5 + `writing-plans` 增量补全。红档须在 Gate-1 说明 OpenSpec 路径；无包时同黄档写满草案。
- 🔴：`explore → propose → analyze → apply → verify → sync → archive → Gate-2 → Gate-3`。
- 🧪 spike：链路不清先探针，代码非交付。

# 人审门禁（硬停）

1. **Gate-0**：`部分通过` = 歧义登记/闭环表/OQ 仍有待确认；`已驳回` stop-and-report。`DEF-*` 不触发部分通过。`待*` 态仅写状态；其它 Gate 状态须写审批人/日期。
2. **Gate-1**：方案后停止；未**文字**批准禁止改代码/迁移/依赖（AskQuestion 不算）；批准后留痕**审批人 = git config user.name**（可选 email），禁止泛称「用户」；**批准后同轮进入实现**（禁止反问是否开工；见 `session-recovery.md` Gate-1→实现链式）。
3. **Gate-2**：验收前须人工签字；Agent 只提请，不得自标完成；签字留痕**审批人 = git config user.name**（可选 email），禁止泛称「用户」；**`--check-release` 须在 Gate-2 前执行**（closeout 步骤 4，不得签字后以外科方式首次跑 release 并停轮）；**签字后同轮进入 Gate-3**（禁止反问「是否归档」；见 `session-recovery.md` Gate-2→Gate-3 链式）。
4. **Gate-3**：Gate-2 后立即 `xijia-sync-knowledge`；任何档位强制；未完成不得开下一需求；若 `--check-release` 仍有 blocking，**在 Gate-3 链内修复后继续 Move**，不得停轮。

# Change 类型

`business|technical|hybrid|defect`（业务|技术|混合|缺陷）；technical/defect 不得虚构 DDD；technical 用 `.cursor/templates/requirements/technical-requirement-template.md`，defect 用 `.cursor/templates/requirements/defect-template.md`；权衡写 ADR 不写 domain。

# 文档边界（摘要）

活文档 vs 过程文档 / 经验复用 / DDD 分类：见 `xijia-ops-pipeline/references/living-docs.md`。

# 收尾（9 步，不得跳过）

verify → comment-sync → 验收记录 → `--check-release` → Gate-2 → Gate-3 → `--check-closeout` → commit（用户触发）→ Deferred 入 backlog。详见 `xijia-ops-pipeline/references/closeout-steps.md`。

Gate-3 归档（`xijia-sync-knowledge` 步骤 17.5–18）：inbox **改状态 → 写总结 → Move-Item**；**禁止** inbox 不可见时 rebuild shipped；**禁止**对 `docs/requirements/shipped/` 用 Cursor Write（见 `xijia-safe-file-write`）。

# Approval Gates（命中即停）

破坏性 DB、清库/重置（`22-db-destructive-safety.mdc`）、新外部依赖、下线能力、权限/密钥变更、跨 BC 大规模调整。

# Guard 命令

可执行 guard / 提交约定见根目录 `AGENTS.md`（Commit and PR instructions）。

# 关联规则（按需）

`40-evidence-chain` `41-change-boundary` `42-verification-output` `43-correction-learning` `44-comment-sync` `45-requirement-intake` `46-git-branching` `47-release-lifecycle` `07-xijia-skill-naming` `22-db-destructive-safety`
