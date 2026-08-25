# 文档索引（Docs Index）

本目录承载 **Alphabounce_M** 的需求、方案、规格、决策与领域知识沉淀。

## 文档生命周期（必读）

| 类型 | 路径 | 行为 |
| --- | --- | --- |
| **活文档** | `AGENTS.md`、`docs/README.md`、`docs/domain/`、`docs/decisions/`、`docs/patterns/`、`docs/pitfalls/` | Gate-3 **持续修正**；同一事实只保留一处 |
| **过程文档** | `requirements/inbox/`、活跃 `openspec/changes/<name>/` | 任务结束后**必须归档** |
| **归档区** | `requirements/shipped/`、`openspec/changes/archive/`、`docs/archive/` | 默认**不进入**后续任务上下文（见 `.cursorignore`） |

默认加载：活文档 + 当前 `inbox` 需求 +（red）当前活跃 change。追溯历史须显式 `@` 归档路径。

## 核心目录职责

- `requirements/inbox/`：进行中的需求（过程文档）
- `requirements/shipped/`：已交付需求归档（审计用，默认不索引）
- `requirements/backlog.md`：Deferred 任务池（活文档，不归档清空）
- `openspec/changes/`：🔴 活跃变更；`changes/archive/` 为已归档变更
- `decisions/`：ADR，记录「为什么这样决策」
- `domain/`：已发布领域语义（AI 读现状只读这里；开发草稿在 change 文件夹）
- `archive/`：spike、废弃长文等过程产物归档
- `process/`：流程文档
- `patterns/`、`pitfalls/`：经验文档

## 何时写到哪里

1. 新需求先进入 `docs/requirements/inbox/`（功能：`/xijia:prd`；缺陷：`/xijia:defect`）
2. 若为 🟢/🟡/🟢-trivial，分级判型、实现方案与验收记录直接写进该 requirement 文档（不再单建 `plans/`）
3. 若为 🔴，变更产物落 `openspec/changes/`
4. 涉及关键权衡时，补充 `decisions/`（ADR）
5. 所有档位收尾都执行 `xijia-sync-knowledge`；稳定结论回灌活文档，过程文档归档离场
6. 若本次存在 Deferred，先写入 `requirements/backlog.md` 再收尾

## 分档路由

- 🟢 轻量：`requirements`（方案与验收写在需求文档内）
- 🟢-trivial：`requirements`（显式声明「本需求无数据流（green-trivial）」）
- 🟡 中等：`requirements`（必要时补 ADR / domain）
- 🔴 核心：`requirements` + `openspec` + `decisions` + `domain`

## Godot 项目结构

```
game/
├── project.godot          # 项目配置
├── scenes/                # 场景文件
│   ├── main/             # 主场景
│   ├── levels/           # 关卡场景
│   ├── ui/               # UI 场景
│   └── entities/         # 实体场景
├── scripts/               # GDScript 脚本
│   ├── core/             # 核心系统
│   ├── entities/         # 实体逻辑
│   ├── ui/               # UI 逻辑
│   └── systems/          # 游戏系统
└── resouces/              # 资源文件
    ├── textures/         # 纹理
    └── audio/            # 音频
```
