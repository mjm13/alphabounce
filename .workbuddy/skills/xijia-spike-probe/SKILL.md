---
name: xijia-spike-probe
description: "Load when 链路不清, 数据来源不明, 原型差异未确认, spike 探针."
agent_created: true
---

# Spike Probe

## 目标

用最小成本消解关键未知，避免在假设上直接进入实现。

## When NOT

- 证据已齐、可直接分级实现 → 勿开 spike
- 探针代码不得当交付合入

## 何时使用

- 需求只给模块名称，缺少关键行为细节
- 数据来源未定义（无 API/外部系统/录入路径）
- 原型存在但偏离点未人工确认
- 分级/判型依赖关键信息但证据链断点明显

## 输出要求（必须）

```text
Spike Report:
- Problem: ...
- Timebox: ...（默认 0.5-1 天）
- Hypotheses:
  - H1: ...
  - H2: ...
- Experiments:
  - E1: ... -> Evidence: ...
  - E2: ... -> Evidence: ...
- Findings:
  - H1: true|false|partial
  - H2: true|false|partial
- Decision:
  - Recommended path: green|yellow|red|reject
  - Executable scope now: ...
  - Deferred / needs user confirmation: ...
```

## 执行步骤

1. 列“关键未知清单”，明确哪些未知会阻断实现。
2. 为每个未知建立可证伪假设（H1/H2...）。
3. 设计最小实验（只读取证优先，禁止生产实现）。
4. 收集证据并回写结论。
5. 产出推荐去向：
   - 信息充分：回到正常分级与计划
   - 部分充分：`partial`，仅执行可落地范围
   - 仍不充分：`reject` 或继续补充输入

## 护栏

- 探针产物不是交付代码，不得替代正式实现。
- 未经用户确认，探针结论不得自动转为 In-Scope。
- 若证据不足，只能标记 `[待确认]`，不得写成确定结论。
