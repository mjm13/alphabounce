---
name: xijia-project-overview
description: "Load when /xijia:overview, 项目概览, 了解项目."
---

# Xijia Project Overview

## 目标

10 秒内回答「这个项目是什么」：

- 技术栈与代码路径锚点
- 模块与能力索引（来源→去向摘要）
- 跨模块 BC 关系
- **业务主流程**（端到端主线，能力C）
- 已交付需求数量（仅计数）

**不是** `/xijia:status`（那条看当前 inbox 需求进度）。

## 只读范围（<=6 轮工具）

1. `AGENTS.md` §Project overview、§Build and test commands
2. `docs/workspace-manifest.yaml`（模块 path / commands SSOT）
3. `docs/capability-map.md`（存在则读；按 moduleKey 分组展示）
3. `docs/domain/context-map.md`（存在则读 BC 列表 + Relationship Matrix 摘要）
4. `docs/flow.md`（存在则读，摘出**业务主流程**；缺失则由 capability-map 的来源→去向链推导主线摘要 + 提示 backfill）
5. `docs/requirements/shipped/*.md` **仅计数**（禁止读正文）

## 禁止

- 读 inbox、openspec 活跃 change、shipped 正文
- 跑 `pipeline_guard.py`
- 写任何文件

## 索引为空时

输出：

- `知识库状态：冷启动（capability-map 缺失或仅有占位行）`
- 建议：若 `shipped/` 有文件 → `/xijia:backfill-index`；否则先交付业务需求并走 Gate-3

## 输出格式

```markdown
## 项目速览

- 项目：<name> | 栈：<summary>
- 模块：backend | frontend（见 manifest）
- 模块数：<N> | 能力索引行：<K> | 已交付需求：<M>
- 知识库：capability-map <有|无|冷启动> | context-map <有|无>

### 模块与能力（capability-map）
| 模块 | 入口数 | 代表能力（来源→去向） |
| --- | --- | --- |
| ... | ... | ... |

### 跨模块关系（context-map）
| Upstream | Downstream | Pattern |
| --- | --- | --- |
| ... | ... | ... |

### 业务主流程（flow.md；缺失则由 capability-map 推导 + 提示 backfill）
- 主流程 1：<入口> → <步骤> → <去向>
- 主流程 2：...
- 若 `docs/flow.md` 缺失：`业务流程：未沉淀（flow.md 缺失）；已由能力索引推导主线，建议 Gate-3 补 flow.md`

### 数据流读法
- 细节真相源：各 shipped 需求「数据流闭环表」（按需 @ 引用，默认不加载）
- **实现前**：capability-map 命中行时，须 `@` 该行「需求来源」中最近 1 条 shipped（定点读闭环表，禁止整目录加载）
- 新 PRD 对照：`/xijia:prd` Step 1.7

### 下一步
- 接 PRD：`/xijia:prd`
- 推进需求：`/xijia:start`
- 补历史索引：`/xijia:backfill-index`（若 shipped>0 且 cap 空）
```

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 读 shipped 正文 | 上下文污染 | 仅计数 `*.md` |
| 跑 pipeline_guard | 越界 | 只读聚合，不写文件 |
| cap 空却不说冷启动 | 误导用户 | 提示 backfill 或先 Gate-3 |
