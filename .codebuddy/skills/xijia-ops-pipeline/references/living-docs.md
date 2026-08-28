# 活文档与知识边界

> **职责边界（四份真相源收束）**
> - 本文件：活文档 vs 过程文档边界 + **读闭环契约**
> - Gate-3 操作细则：[`xijia-sync-knowledge/SKILL.md`](../../xijia-sync-knowledge/SKILL.md)
> - 加载白名单：[`.codebuddy/rules/50-context-engineering.mdc`](../../../rules/50-context-engineering.mdc)
> - 触发索引表：[`docs/process/knowledge-maintenance.md`](../../../../docs/process/knowledge-maintenance.md)

## 活文档 vs 过程文档

- **活文档（Gate-3 持续修正）**：`README.md`、`AGENTS.md`、`docs/README.md`、`docs/llms.txt`、`docs/constitution.md`、`docs/domain/*`、`docs/decisions/*`、`docs/patterns/*`、`docs/pitfalls/*`、`docs/architecture.md`、`docs/flow.md`、`docs/roadmap.md`、`docs/capability-map.md`、`docs/requirements/backlog.md`。
- **过程文档（任务后离场）**：`docs/requirements/inbox/*`、活跃 `docs/openspec/changes/<name>/`、spike 长文。
- **归档区（默认不读）**：`docs/requirements/shipped/`、`docs/openspec/changes/archive/`、`docs/archive/`。

## 领域边界

- **红档草稿**只写 `docs/openspec/changes/<name>/domain/`；`sync → archive → Gate-3` 后**提升**到 `docs/domain/<bc>/*`。
- **黄/绿业务|混合**：无 change 草稿时，Gate-3 **直写** `docs/domain/<bc>/`（按 BC 建夹，不按菜单）；`context-map.md` 登记关系。领域影响含 `INV-xxx` 时必须写/建 `domain-model.md`（细则：`xijia-sync-knowledge/references/domain-merge.md` §11b）。
- `docs/architecture.md`、`docs/capability-map.md` 仅 Gate-3 更新。
- `docs/flow.md`（业务主流程，能力C）：**业务/混合需求 Gate-3 按需更新**——命中业务主流程变化才改，否则「实现记录与沉淀」写 `Flow: no-op`；`/xijia:overview` 读它输出「业务主流程」段。
- 栈 reversal 需求：「实现记录与沉淀」禁止 `Living Docs: no-op`；须同步 `README.md`、`docs/architecture.md`、`AGENTS.md`、`docs/openspec/config.yaml`。

## 经验复用读闭环

1. **Gate-0**：主动检索并填「约束引用」top-N（含触达面）；业务/混合禁止空 `约束引用: none`。
2. **apply 前（绿/黄第4步）**：**只读 Gate-0 已列路径**（patterns/pitfalls/domain/decisions），不重开全库假检索；命中后：
   - 在「实现记录与沉淀」写 `Experience Reuse: <path>`（**文档真相源**，release/closeout 认此行）
   - Gate-3 对命中 path 跑 `--judge-doc`（主）；`--use-doc` 可选辅记
3. Gate-0 已列 patterns/pitfalls 时**禁止** `Experience Reuse: none`。
4. 未命中且约束引用无经验路径：写 `Experience Reuse: none（已检索，触达面：…）`。
5. `architecture.md` / `capability-map.md` 仅收尾更新。

## capability-map → shipped 定点读

- 命中 `docs/capability-map.md` 行时，实现前须 `@` 该行「需求来源」列中**最近 1 条** shipped 路径（读其「数据流闭环表」），禁止默认加载整个 `shipped/`。
- overview / 日常任务仍遵守归档区默认不读。

## DDD 同步（business/hybrid）

先 A/B/C/D 分类（新 BC / 改聚合不变量 / 仅字段语义 / 无领域影响）；同词异义先 stop-and-report。禁止只追加不更新。
