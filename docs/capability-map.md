# 能力追溯索引（Capability Map）

> 行主键：`moduleKey` + `前端入口`（normalize 后）。Gate-3 **动态合并**（ADD/UPDATE/DEPRECATE），禁止同主键重复行。
> 操作级细节真相源：各 `docs/requirements/shipped/*` 需求「数据流闭环表」。
> 维护：`xijia-sync-knowledge` Gate-3 调用 `python .cursor/hooks/extract_capability_index.py --req <shipped-req>`。

| 模块 | moduleKey | 前端入口 | 后端能力 | 相关表 | 来源摘要 | 去向摘要 | 状态 | 需求来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 安卓工程基座 | android-bootstrap | `android/scenes/Main.tscn` | 无（纯单机） | 无 | Godot 工程 + SDK/JDK | debug APK | active | 20260818205718-AB-安卓工程初始化 |
| 核心玩法 MVP | gameplay-mvp | `android/scenes/Main.tscn` + `android/levels/LevelBase.gd` | 无（纯单机） | 无 | 触控输入/物理循环 | HUD/胜负/重开 | active | 20260818214301-AB-P1核心玩法MVP |

## 修订记录

| 日期 | 操作 | 主键 | 需求来源 | 说明 |
| --- | --- | --- | --- | --- |
| 2026-08-20 | ADD | android-bootstrap\|Main.tscn | 20260818205718-AB-安卓工程初始化 | init 工程基座占位 |
| 2026-08-20 | ADD | gameplay-mvp\|LevelBase.gd | 20260818214301-AB-P1核心玩法MVP | 挡板/球/砖块/HUD/胜负闭环 |
