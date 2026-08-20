---
name: xijia-ddd-modeling
description: "Load when 红档 DDD 契约, change/domain 草稿, business|hybrid modeling."
---

# 目标

把业务语义沉淀为可校验契约，而非散文描述，减少 AI 同义词漂移与上下文污染。

# 输出文件（🔴 草稿：docs/openspec/changes/<name>/domain/）

- `ubiquitous-language.md`（必须含 BC、锚点、Aliases to AVOID）
- `domain-model.md`（必须含每个聚合的 `INV-xxx`）
- `context-map.md`（必须标注关系 Pattern）
- `aggregate-spec.md`（聚合规格）
- `anti-corruption-layer.md`（ACL 规格）
- `bounded-context-canvas.md`

# 必做约束

1. 每个聚合至少 1 条 `INV-xxx` 不变量。
2. 每个新增术语必须给出 BC + 锚点 + 至少 1 个禁用别名（Aliases to AVOID）。
3. `aggregate-spec` 与 `anti-corruption-layer` 标注为“人写优先，LLM 仅消费”。
4. 技术 change 不调用本技能。
5. **propose-not-mint**：AI 不得自主铸造术语/BC/INV 最终定义；只能给候选并在收尾请求用户确认。

# DDD 变更分类（先判定，再写文档）

仅 `business/hybrid` 进入本表，按证据选择唯一主类：

| 类别 | 触发条件（满足其一） | 领域动作 | 应改文件 |
|---|---|---|---|
| A 新建 BC | 同词异义；目的/业务阶段不同；生命周期/团队/泳道独立 | 新建 BC 条目与关系 | `ubiquitous-language.md`、`domain-model.md`、`context-map.md`（必要时 `bounded-context-canvas.md`） |
| B 既有 BC 内改聚合/不变量 | 新不变量、事务一致性边界变化、状态机变化 | 更新聚合与 INV（可 supersede） | `domain-model.md`（必要时 `aggregate-spec.md`） |
| C 仅字段语义 | 字段/枚举/状态语义变化；无新不变量；无语言漂移 | 仅更新数据语义 | `data-dictionary.md`（由 `xijia-sync-knowledge` 在已发布域执行） |
| D 无领域影响 | technical/UI 壳层；不涉及业务语义 | 跳过领域文档 | 无 |

判定启发（用于 A/B 边界）：
- A 看语言与目的边界（Bounded Context），不是模块/命名空间边界。
- B 看一致性边界（Aggregate/Invariant），不是“字段数量变多”。

# 专业 DDD 判定提示词（内置）

在执行步骤第 2 步前，先使用以下提示词生成判定草案。

## 严格版（核心域 / red）

```text
你是资深 DDD 架构师。仅基于当前需求与 docs/domain 现状，判定本次变更属于：
A 新建 BC / B 既有 BC 内改聚合或不变量 / C 仅字段语义 / D 无领域影响。

必须输出：
1) 分类结论（A|B|C|D）
2) 证据链（语言差异、目的/阶段、生命周期、事务一致性、不变量）
3) 影响文件清单（仅本次应改文件）
4) 更新方式（ADD/UPDATE/SUPERSEDE/RENAME/DEPRECATE）
5) 冲突清单（同词异义、边界冲突、别名冲突）+ 需人工确认项
6) 禁止项核对（不得无异议累加；不得在未确认下铸造术语/BC/INV）

判定规则：
- A：同词异义，或目的/生命周期明显独立，才新建 BC
- B：出现新不变量/一致性边界变化，才改聚合
- C：仅字段/枚举/状态语义变化，且无新不变量
- D：technical/UI 壳层，无领域语义变化

若证据不足，输出“待确认”，不得强行分类。
```

## 轻量版（常规 business/hybrid）

```text
请先做 DDD 影响判定（A/B/C/D），再给出：
- 本次必须更新的最小文档集合
- 更新方式（ADD/UPDATE/SUPERSEDE/RENAME/DEPRECATE）
- 需要人工确认的冲突项（若有）

规则：
- 不能因为有新字段就判为 B
- 不能因为新模块名就判为 A
- 不允许追加流水账，必须基于现有文档做更新决策
```

# 执行步骤

1. 判定 change 类型（business/hybrid 才继续）。
2. 先完成 DDD 变更分类（A/B/C/D），并在输出中写明证据与影响文件。
3. A/B：按模板补齐或更新 6 份契约文档草稿（`docs/openspec/changes/<name>/domain/`）。
4. C：在 change 草稿中仅记录字段语义变化，收尾由 `xijia-sync-knowledge` 更新 `docs/domain/data-dictionary.md`。
5. 运行校验脚本：
   - `python .cursor/skills/xijia-ddd-modeling/scripts/validate_domain_contracts.py --path "<domain-dir>"`
6. 若校验失败，修正文档后重跑。

# 完成判定

- 校验脚本通过（无 ERROR）
- `INV-xxx`、BC、Aliases to AVOID、关系 Pattern 均存在
- 已输出分类结果（A/B/C/D）+ 人工确认清单（术语/BC/INV 候选）
