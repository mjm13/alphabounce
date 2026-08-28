---
name: xijia-memory
description: "Load when checkpoint 写回 episodic 记忆. Optional; not living-doc truth."
---

# xijia-memory

> **可选能力**：默认 init **不**创建 `docs/memory/`。仅当用户显式启用 optional memory 模板时使用；与 `50-context-engineering.mdc` 一致——episodic 草稿，**非**活文档真相源；稳定语义须 Gate-3 提升到 ADR/domain。

## 目标

把跨会话可复用的决策沉淀为结构化记忆，避免重复踩坑。

## When NOT

- 稳定语义 / 活文档真相 → Gate-3 ADR/domain，勿写 memory

## 存储

- `docs/memory/decisions.jsonl`

## 记录结构

```json
{"ts":"...","source":"...","decision":"...","result":"...","confidence":0.0,"staleness":"30d","tags":["domain","contract"]}
```

## 规则

1. 只写提炼后的决策，不写原始长对话。
2. 每条必须包含 `ts/source/confidence`。
3. 在任务完成、收尾、用户纠正后写回。
4. 语义稳定后再蒸馏到 ADR/domain。

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 把 memory 当活文档真相 | 边界混淆 | 稳定语义走 Gate-3 ADR/domain |
| 写入原始长对话 | 违反提炼规则 | 只写 decision/result 摘要 |
| 缺 confidence/ts | schema 不完整 | memory_lint 修复 |
