---
name: xijia-quality-judge
description: "Load when 实现后质量评审, quality-judge, pass|revise before Gate-2."
agent_created: true
---

# Quality Judge

## 目标

在实现完成后，由独立评审代理给出 `pass|revise` 判定，避免实现者自评偏差。产品层审查**仅在本技能出口**产出 findings（不在 code-review 重复）。

## 输入

- change 名称（红档）或当前需求路径（绿/黄）
- 原始诉求（verbatim）+ 歧义登记结论
- proposal/design/tasks/spec（红档）或 Gate-1 `## 验收标准` / `## 范围与切片`
- AC↔Test 追溯表
- DDD 不变量（INV-xxx）
- **产品层上下文**（按 `50-context-engineering.mdc` 白名单组装，替代独立 yaml）：
  - 当前需求 Gate-0「约束引用」表内路径（须 Read，不得只靠摘要）
  - `docs/constitution.md` Safety Gates
  - 触达 BC 的 `docs/domain/<bc>/`（UL / INV）与相关 `docs/decisions/*`
  - 范围/战略对照：需求 Out of Scope +（必要时）`docs/roadmap.md`
  - 红档额外加载活跃 `docs/openspec/changes/<name>/specs/`（以工作区最新内容为准）

## 评审维度（rubric）

1. **意图保真**：AC 是否忠实表达 verbatim 与人工消歧结论，而非只检查“实现是否符合 AC”
2. AC 覆盖完整性与可证伪性（交互/状态类须有状态迁移 AC 与反例）
3. INV-xxx 不变量是否被实现与验证
4. 变更边界是否符合 scope
5. **证据真实性**：每条「通过」是否有已执行证据；UI 行为不得用 lint/build 代替运行时证据
6. 风险披露是否充分（未执行项/人工验证项）
7. 规范一致性（EARS、术语、BC 边界）
8. **产品意图与范围**（BusinessLogic + ScopeCreep + StrategicDrift）：实现是否 silent 改写业务规则；是否超出 In Scope / Deferred；是否偏离 roadmap 做未批准的战略扩张
9. **约束与合规**（Compliance + ToolingInfra）：是否触碰 constitution Safety Gates（破坏性数据、权限/密钥、下线能力、关键外部依赖）而未获人工确认；是否违反 Gate-0 约束引用 / ADR
10. **领域一致性**（DomainLanguage）：术语是否与触达 BC 的 UL / Aliases to AVOID 一致；是否与已批 ADR / INV 矛盾

维度 4、7 与 8–10 有重叠时，**产品漂移结论统一写入 Product Drift Findings**，避免两处矛盾表述。

## 输出

```markdown
## Quality Judge Verdict

- Verdict: <pass|revise>
- Reasons:
  - ...
- Required Fixes:
  - ...
- Residual Risks:
  - ...

### Product Drift Findings
- Verdict: <pass|advisory|blocked>
1. **[维度] 简述**（无则写「无产品漂移」）
   - Violation: ...
   - Spec: `path` §...
   - Suggested fix: ...
```

### Product Drift 与总 verdict 的关系

- 🔴：Product Drift `blocked` 或任一 High 级 finding → 总 Verdict 必须为 `revise`
- 绿/黄：Product Drift `advisory` 时总 Verdict 仍可为 `pass`；findings 须写入验收包「产品层审查（引用 quality-judge）」段
- Product Drift `pass` 且无 finding → Findings 写「无产品漂移」

## 约束

- 评审者与实现者角色分离。
- `revise` 状态不得宣告完成。
- code-review 保持技术向；不在此技能外二次生成 Product Drift Findings。
