# Deferred Backlog

> 统一收敛 `partial/reject` 需求中的 Deferred 项，避免遗漏。兼作轻量路线图（版本线 + 优先级）。

## 当前版本线（活文档，Gate-3 维护）

| 版本 | 目标日期 | 范围摘要 | 状态 |
| --- | --- | --- | --- |
| v0.1.0 | <yyyy-MM-dd> | <MVP / 首批能力> | planning |

## Deferred 项

| ID | 版本线 | 来源需求 | Deferred 项 | 原因 | 优先级 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BL-20260820-01 | backlog | 20260818214301-AB-P1 | 多球/特殊砖块 | 超出 P1 MVP 范围 | P1 | open | → P2/P3 |
| BL-20260820-02 | backlog | 20260818214301-AB-P1 | 关卡程序生成 | 超出 P1 MVP 范围 | P1 | open | → P7 |
| BL-20260820-03 | backlog | 20260818214301-AB-P1 | 本地存档与进度 | 超出 P1 MVP 范围 | P2 | open | → P11 |
| BL-20260820-04 | backlog | 20260818214301-AB-P1 | 正式包名 Gradle 构建 | 预构建模板默认包名 | P2 | open | → P12 |

## 维护规则

- 仅收录来自 Gate-0 `partial/reject` 或收尾阶段显式 Deferred 的事项。
- 每次需求收尾前必须确认本次 Deferred 是否已写入此表。
- **版本线**：未排期填 `backlog`；已承诺填 `vX.Y.Z`。
- **优先级**：P0（阻塞）/ P1（本版本）/ P2（后续）。
- 状态建议：`open` / `planned` / `in-progress` / `done` / `cancelled`。
