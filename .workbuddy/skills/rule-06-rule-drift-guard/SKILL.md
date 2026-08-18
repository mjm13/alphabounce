---
name: rule-06-rule-drift-guard
description: "规则漂移检测（防止回流到栈绑定术语） [globs:- '.cursor/rules/**/*.mdc' - '.cursor/skills/**/*.md']"
agent_created: true
---

# 目标

单一执行点为 `afterFileEdit` hook：`python .cursor/hooks/drift_guard_scan.py`，跑两项独立扫描：

1. **栈漂移**：避免基线**规则**回流到技术栈绑定表述；skills 可承载栈细节，但不得把错误历史栈写成默认基线。
2. **defends 绑定**：每条规则须在 frontmatter 写清它防的具体失败。

# 适用范围

- `.cursor/rules/**/*.mdc` — 扫**遗留错误栈词 + 当前产品栈词**（rules 须栈无关）
- `.cursor/skills/**/*.md` — 仅扫**遗留错误栈词**（产品栈允许出现在 skills）
- 本文件自身（词库定义）不参与扫描

# 黑名单关键词（仅扫描词库，不构成基线约束）

**遗留 / 错误栈（rules + skills）：**

`Flyway|MyBatis|Spring|JUnit|@SpringBootTest|Mapper|Maven|BCrypt|Vitest|vite.config`

**当前产品栈（仅 rules）：**

`FastAPI|uvicorn|SQLAlchemy|Alembic|pytest-asyncio|fakeredis|Vue|Vue3|Pinia|Element Plus|element-plus|ElementPlus|Playwright|Iconify|OpenTelemetry|React|Django|Flask`

> 词库与 `drift_guard_scan.py` 必须同步。
> 注：`org_node` 等项目既有真实表名不纳入黑名单——它是事实而非栈绑定术语。

# 执行方式（单一执行点）

- 默认只通过 `hooks.json` 的 `afterFileEdit -> drift_guard_scan.py` 执行扫描。
- 本规则负责维护词库与处置口径，不再要求额外二次扫描。

# 处理策略

1. 命中黑名单时，优先改为技术栈无关表达；栈细节下沉到 `AGENTS.md` 或对应 skill。
2. 若确需出现（例如 skill 内生态示例、迁移说明）：
   - 必须在同段附加「仅示例，不构成基线约束」或「当前栈」说明。
   - 不得把该术语写进 `.cursor/rules` 作为默认流程要求。
3. 若 hook 输出命中项，编辑当次必须完成处置或显式记录豁免原因。

# defends 绑定（失败模式）

每个 `.cursor/rules/*.mdc` 的 frontmatter 须有非空 `defends:`，一句话写清**它防的是哪个具体失败**，并尽量带出处（`docs/pitfalls/*` 路径、可复现的 guard 命令、或技能 GOTCHAS 条目）。

写法：

- 具体到可复现：「审批人被写成泛称『用户』」而不是「保证质量」。
- 属 L3（不可逆动作、责任边界）的写明「不到期」；属补模型能力缺口的写明**到期信号**——即「当模型不再犯这个错时可删」的判断依据。
- 新增规则时先写 `defends:`；**写不出来说明这条规则不该加**。

`defends:` 的作用是让「已被模型内化」变得可检测：没有它，规则只增不减，因为谁也判断不了它是否还起作用。到期审计流程见 `xijia-policy-drift-check`。

# 通过标准

- rules 无产品栈 / 遗留栈命中（本词库文件除外）。
- skills 无遗留错误栈命中；或命中项均附免责说明且不构成默认约束。
- rules 无 `[defends-scan]` 命中。
