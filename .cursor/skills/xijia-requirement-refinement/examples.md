# 案例：外部任务同步管理（Gate-0 细化）

本案例展示 `xijia-requirement-refinement` + `brainstorming` 的 **Gate-0 回补**形态。  
Gate-1 验收标准/实现方案应在 `/xijia:prd` 落盘时已按分档写满；本技能不重写 Gate-1。

## 触发

```
参考 document/外部任务服务契约.md，细化 docs/requirements/inbox/<时间戳>-外部任务同步管理.md 的 Gate-0
```

## Phase 0 发现

- 初稿：列表数据来源、外部服务契约、冗余字段未闭合
- `--check-intake`：数据流表多行 `[待确认]`
- codegraph：任务管理入口、数据源配置、外部服务配置可复用（留给 A.0.5 若 plan 仍缺）

## 关键问答（节选）

| 轮次 | 问题 | 结论 |
| --- | --- | --- |
| Q1 | 列表主数据从哪来？ | 本地 `task_sync` + 外部 SQL 补齐运行态 |
| Q2 | 哪些字段可 CRUD？ | `name`、`category`、`external_id`、`external_name` |
| Q3 | 执行频率可编辑吗？ | 否，只读外部计划描述 |
| Q4 | SQL 与 HTTP 凭证？ | SQL→数据源配置；HTTP→外部服务配置 |
| Q5 | 改绑外部任务后？ | 不触发执行；立即同步状态写冗余字段 |

## 回写章节（仅 Gate-0）

- Gate-0 `## 数据流闭环表`：verdict → 已通过
- `OQ-*`：闭合记录
- Gate-0 `## 范围与切片` In Scope：同步/执行/改绑/统计（能力边界）
- **不写** Gate-1 `## 验收标准` / `## 实现方案`

## Gate 结果

- `--check-intake`：通过
- 下一步：`/xijia:start`（若 `--check-plan` fail → A.0.5 增量；若已满 → 直接 Gate-1 提请）
