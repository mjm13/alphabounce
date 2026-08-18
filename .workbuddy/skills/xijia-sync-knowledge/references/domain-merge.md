# Domain 合并与沉淀四问（步骤 5–13）

进入本文件前须已完成主文步骤 1–4。

- 步骤 **5–7**（OpenSpec 契约**提升** + validate）：仅 `分级=红`。
- 步骤 **8–13**（四问 / context-map / **BC 目录** / ADR）：**所有档位**执行与本次变更相关的部分；黄/绿**不得**因「非红」整段跳过。

## 5. 读取 red change 产物

若 `分级=红`：读取归档 change 的 design/tasks/specs。

**完成：** change 路径已定位，或本步跳过（非红）。

## 6. Domain 契约提升（red + business/hybrid）

若 `分级=红` 且 change type 为 business/hybrid：将 `docs/openspec/changes/<name>/domain/*` 提升到 `docs/domain/<bc>/*`（及系统级 context-map / data-dictionary 若草稿含之）。

**完成：** 目标 domain 文件已更新，或本步跳过。

> 非红**没有** change 草稿可提升，属正常；**不等于**禁止写 `docs/domain/<bc>/`。黄/绿走步骤 10–11b **直写**。

## 7. DDD 契约校验（red）

```bash
python .cursor/skills/xijia-ddd-modeling/scripts/validate_domain_contracts.py --path "docs/domain"
```

**完成：** 脚本 exit 0，或本步跳过（非红）。

## 8. 动态合并协议（先 diff 再写）

- 判定口径复用 `xijia-ddd-modeling`「专业 DDD 判定提示词」（严格版/轻量版）；勿临时改写分类标准。
- 读取 `docs/domain/*` 现状与（红）change 草稿 /（黄绿）需求「领域影响」逐条对比。
- 每个术语/聚合/INV/关系先分类：`ADD | UPDATE | SUPERSEDE | RENAME | DEPRECATE`。
- `UPDATE`：就地更新定义，并追加「修订记录：日期 + change-id/需求号」。
- `SUPERSEDE`：旧 INV 标注被新 INV 替代，不静默删除。
- `RENAME`：旧名进入 `Aliases to AVOID`。
- 写入前按锚点/别名查重；已存在概念必须走 `UPDATE/SUPERSEDE/RENAME`。

**完成：** 每条变更已标注操作类，无盲 append。

## 9. 冲突停审

同词异义、术语重定义、BC 边界不一致 → stop-and-report，列待确认清单，用户确认后再写入。

**完成：** 无未确认冲突，或已获用户文字确认。

## 10. 沉淀四问

| 问 | 落点 |
| --- | --- |
| 规则/不变量 | `docs/domain/<bc>/domain-model.md`（INV，ADD/SUPERSEDE） |
| 关键决策/权衡 | `docs/decisions/*.md` |
| 数据语义（字段/枚举/状态） | `docs/domain/data-dictionary.md` |
| 语言/边界（新术语、新 BC、同词异义） | `docs/domain/<bc>/ubiquitous-language.md` + `docs/domain/context-map.md` |

**黄档落点纪律：**

- ADR **不是** INV 唯一落点。可在 ADR 写决策背景，但凡「领域影响」出现 `INV-xxx`，须在 `domain-model.md` 有对应条目（或 SUPERSEDE 链）。
- 「无新 INV」时：四问中规则行写不适用即可，不强制新建空 `domain-model.md`。

**完成：** 四问均有落点或显式不适用说明。

## 11. BC 注册表（黄/绿业务|混合硬触点）

以 `docs/domain/context-map.md` 的 Bounded Context 列表判定「新建 vs 更新」；不存在则按本次迭代增量创建（仅写本次涉及 BC）。

当 `类型=业务|混合`、非 green-trivial、且 `DDD主类=A|B`（或未填）：

1. **必须** UPDATE `context-map.md`（BC 说明与/或 Relationship Matrix），或写 `Domain: no-op（理由）`。
2. Gate-3「实现记录与沉淀」写 `Domain: updated（…）`，路径须覆盖实际改动的 domain 文件。
3. **禁止**仅用 `Living Docs: AGENTS.md` 代替本步。

**完成：** BC 列表与本次变更一致，且 Domain 标记已写。

## 11b. BC 目录首次创建 / 增量（黄绿直写；红提升后也适用）

按 **BC（限界上下文）** 建 `docs/domain/<bc>/`，**不要**按前端菜单一人一夹。

| 触发条件 | 动作 |
| --- | --- |
| context-map 已登记 BC，但 `docs/domain/<bc>/` **不存在**，且本次有 INV 或新术语 | **首次建夹**：至少创建命中的 `domain-model.md` 和/或 `ubiquitous-language.md` |
| 领域影响含 `INV-xxx` | ADD/UPDATE `docs/domain/<bc>/domain-model.md`；context-map 可保留 INV **指针**，真相源在 domain-model |
| 仅有 Relationship / BC 说明变化、显式无新 INV | 只改 `context-map.md` 即可 |
| 新术语 / Aliases to AVOID | ADD/UPDATE `ubiquitous-language.md` |
| `aggregate-spec` / ACL 等 | **按需**增量，不要求黄档一次铺满 |

Domain 标记示例（有 INV）：

`Domain: updated（docs/domain/context-map.md + docs/domain/<bc>/domain-model.md；…）`

**完成：** 有 INV 时磁盘存在含该 INV 的 `docs/domain/<bc>/domain-model.md`；有新术语时存在 UL；无则已写不适用理由。

## 12. green/yellow 补充

命中 C 类（仅字段语义）时，可只更新 `docs/domain/data-dictionary.md`，仍遵循动态合并 + 人工确认。

**完成：** 字段语义已合并或本步不适用。

## 13. ADR 强制触点

命中 Approval Gate 类权衡（新增关键外部依赖、权限/安全策略变更、跨上下文架构权衡）→ 新增 `docs/decisions/*.md` 后才能宣告收尾（`pipeline_guard.py --check-release` 兜底）。

**完成：** 无 Approval Gate 缺口，或 ADR 已落盘。
