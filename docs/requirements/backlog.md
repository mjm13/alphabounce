# Deferred Backlog

> 统一收敛 `partial/reject` 需求中的 Deferred 项，避免遗漏。兼作轻量路线图（版本线 + 优先级）。

## 当前版本线（活文档，Gate-3 维护）

| 版本 | 目标日期 | 范围摘要 | 状态 |
| --- | --- | --- | --- |
| v1.0 全量复刻 | 2026-Q4 | P0–P16 全部 Gate-2 | active |

## Deferred 项

| ID | 版本线 | 来源需求 | Deferred 项 | 原因 | 优先级 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BL-20260820-01 | backlog | 20260818214301-AB-P1 | 多球/特殊砖块 | 超出 P1 MVP 范围 | P1 | open | → P2/P3 |
| BL-20260820-02 | backlog | 20260818214301-AB-P1 | 关卡程序生成 | 超出 P1 MVP 范围 | P1 | open | → P7 |
| BL-20260820-03 | backlog | 20260818214301-AB-P1 | 本地存档与进度 | 超出 P1 MVP 范围 | P2 | open | → P11 |
| BL-20260820-05 | v1.0 | 20260820131200-P8b | 装备 loadout / Defense / 全局唯一分配 | 原 P0–P12 规划缺口 | P1 | in-progress | inbox 全量需求已建 |
| BL-20260820-06 | v1.0 | 20260818214303-P3 | 球体飞行粒子（partSpark/mcBolt 等） | P3 仅行为；表现归 P10 | P1 | open | → `20260818214310-AB-P10音频与表现力.md` AC-4 |
| BL-20260820-07 | v1.0 | 20260818214303-P3 | SAUVETAGE 首球保护（flSafe/levelTimer） | P3 未含关卡保护 | P1 | open | → `20260820150300-AB-P3c关卡SAUVETAGE首球保护.md` |

## 维护规则

- 仅收录来自 Gate-0 `partial/reject` 或收尾阶段显式 Deferred 的事项。
- 每次需求收尾前必须确认本次 Deferred 是否已写入此表。
- **版本线**：未排期填 `backlog`；已承诺填 `vX.Y.Z`。
- **优先级**：P0（阻塞）/ P1（本版本）/ P2（后续）。
- 状态建议：`open` / `planned` / `in-progress` / `done` / `cancelled`。
