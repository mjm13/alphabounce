# Context Map（Established）

> 本文件除关系图外，同时作为 Bounded Context 增量注册表：每次迭代只登记本次涉及 BC，无需回填历史全量。

## Bounded Contexts

- Gameplay（挡板/球/砖块/HUD/胜负 — P1 MVP 已交付，见 `android/levels/LevelBase.gd`）
- MetaProgress（经济/存档 — 待 P8/P11 细化）

## Relationship Matrix

| Upstream | Downstream | Pattern | Contract |
| --- | --- | --- | --- |
| Gameplay | MetaProgress | Partnership | 关卡结果 → 进度/货币（待定义） |

## Notes

- 纯单机 Godot 项目，无跨服务 ACL；BC 边界随玩法需求 Gate-3 增量登记。

## 修订记录（动态更新）

| 日期 | change-id | 操作 | BC/关系 | 说明 |
| --- | --- | --- | --- | --- |
| 2026-08-20 | 20260818214301-AB-P1核心玩法MVP | UPDATE | Gameplay | P1 MVP 挡板/球/砖块/HUD 闭环 |
