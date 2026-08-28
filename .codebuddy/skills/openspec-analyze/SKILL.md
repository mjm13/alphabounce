---
name: openspec-analyze
description: 在实现前做 OpenSpec 一致性闸门（AC↔tasks↔spec↔test↔DDD契约）。
---

# OpenSpec Analyze

## 必查项

1. Gate-1 验收标准 / OpenSpec AC ↔ tasks 映射完整。
2. Gate-1 验收标准 / OpenSpec AC ↔ delta spec 映射完整。
3. Gate-1 验收标准 / OpenSpec AC ↔ tests/checks 映射完整。
4. DDD 契约完整：
   - UL 含 BC + Aliases to AVOID
   - domain-model 含 `INV-xxx`
   - context-map 含关系 Pattern
5. `Deferred/Out of Scope` 不进入完成判定。
6. 关键未知是否已闭环：
   - 若存在数据来源不明、原型差异未确认、核心交互未定义，必须有 spike 报告支撑。
   - 无 spike 证据时，判定为 `blocked`。
7. **跨文档冲突（仅红档，advisory）**：当前 change `specs/` 与 `docs/decisions/*` 是否存在明显矛盾；若同轮次既改 spec 又改 code，后续 `xijia-quality-judge` 须以工作区**最新 spec** 为准。绿/黄档跳过本项。硬冲突（与已批 ADR 直接对立且无 Gate-1 消歧）可将 Verdict 标为 `blocked`；其余矛盾只作 advisory 提示，不单独改变主判定。

## 校验命令

- `python .codebuddy/skills/xijia-ddd-modeling/scripts/validate_domain_contracts.py --path "<change-domain-dir>"`

## Verdict

- `ready`: 所有映射与契约校验通过（含红档无硬冲突的跨文档 advisory 已披露）
- `blocked`: 任一缺口未闭合（含关键未知未被 spike 证据消解；或红档跨文档硬冲突）
