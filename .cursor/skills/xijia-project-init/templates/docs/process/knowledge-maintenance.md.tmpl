# 知识库维护规范

> 过时的过程文档比没有文档更有害。活文档持续修正；过程文档任务结束后归档离场。

## 活文档 vs 过程文档

| 分类 | 代表路径 | 维护方式 |
| --- | --- | --- |
| 活文档 | `AGENTS.md`、`docs/README.md`、`docs/llms.txt`、`docs/constitution.md`、`docs/domain/`、`docs/decisions/`、`docs/patterns/`、`docs/pitfalls/`、`docs/architecture.md`、`docs/capability-map.md`、`docs/requirements/backlog.md` | Gate-3 增量修正 |
| 过程文档 | `docs/requirements/inbox/`、活跃 `docs/openspec/changes/<name>/` | 收尾后归档 |
| 归档区 | `docs/requirements/shipped/`、`docs/openspec/changes/archive/`、`docs/archive/` | 只读审计，默认不索引 |

## Gate-3 活文档触发（命中即改）

| 场景 | 更新目标 |
| --- | --- |
| dev/build/test/deploy 命令变化 | `AGENTS.md` **Build and test commands** |
| 顶层目录/模块职责、路径锚点变化 | `AGENTS.md` **Project overview** / **Dev environment tips**、`docs/README.md` |
| 文档树或流程命令路由变化 | `docs/README.md`、`docs/llms.txt`、`docs/process/project-lifecycle.md`（**禁止**把文档树路由写回 `AGENTS.md`） |
| 技术栈/依赖版本变化 | `AGENTS.md` **Project overview** |
| 安全边界变化 | `AGENTS.md` **Security**、`docs/constitution.md`（重大时 + ADR） |
| 日志 schema / 关联 ID 变化 | `AGENTS.md` **Observability** |
| 提交/PR 约定变化 | `AGENTS.md` **Commit and PR instructions** |
| 领域语义稳定结论 | `docs/domain/`（red 为主） |
| 架构权衡 | `docs/decisions/*.md` |
| 业务/混合需求 Gate-3（默认） | `docs/capability-map.md` 行级 ADD/UPDATE（`extract_capability_index.py`） |
| 跨模块关系（须验收确认） | `docs/domain/context-map.md` Relationship Matrix |
| 可复用经验（人确认后） | `docs/patterns/`、`docs/pitfalls/` |

未命中任何触发：在 requirement「实现记录与沉淀（Gate-3）」写 `Living Docs: no-op`。

### AGENTS.md 追加限度

`AGENTS.md` 每轮请求全量进上下文，一次追加即长期占用指令预算。命中上表 `AGENTS.md` 行时按序判定：

1. **就地替换优先**：同一事实已在文中 → 改写原句，不新增段落
2. **归属判定**：每轮任务都需要 → 留在 `AGENTS.md`；仅单一领域或阶段需要 → 写入对应 `docs/*` 或 `.cursor/rules/*`，`AGENTS.md` 只留一行指针；一次性操作步骤 → 不进 `AGENTS.md`
3. **净增守恒**：确需新增 ≥3 行时，同轮评估能否下沉等量既有内容；无法下沉则在沉淀段写明理由
4. **稳定性优先**：写能力与领域概念（比路径稳定），不写会失效的文件坐标

## 过程文档归档触发（Gate-3 强制）

| 场景 | 动作 |
| --- | --- |
| 需求 Gate-2 签字完成 | `docs/requirements/inbox/` → `docs/requirements/shipped/`，`状态: 已交付` |
| red OpenSpec 收尾 | `docs/openspec/changes/<name>/` → `docs/openspec/changes/archive/<name>/` |
| spike 结束 | → `docs/archive/spikes/` 或随 requirement shipped |
| 低价值/废弃长文 | → `docs/archive/<yyyy>/`，标 `deprecated` |

收尾后运行：`python .cursor/hooks/pipeline_guard.py --check-closeout --req <shipped-requirement-path>`

## 禁止

- 在根目录堆叠「总结 v2 / 复盘副本」代替活文档就地更新
- 把 shipped 需求留在 inbox
- 把归档区路径写入 `docs/llms.txt`
- 在 `AGENTS.md` 重复文档树路由、技能地图或 lifecycle 全文（链到 `docs/llms.txt` / `project-lifecycle.md`）；允许 **Xijia workflow** 一行命令表
- 因「Agent 某次没照做」就向 `AGENTS.md` 追加新规则：先判断该约束是否已属某条 rule/skill 职责，重复即冲突源
- 在 `AGENTS.md` 镜像目录树、代码文件清单或入口文件路径（改名即失效并误导 Agent；坐标真相源为 `docs/capability-map.md` 与代码本身）
