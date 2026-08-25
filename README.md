# Alphabounce_M

## 项目简介

- **目标**: 将 Haxe/Pixi.js 版 AlphaBounce 游戏使用 Godot 4.x + GDScript 完整重构，迁移到 Android 平台
- **源项目**: `D:\Project\Self\EternalTwin-Alphabounce` (Haxe/Pixi.js)
- **首批模块**: 游戏核心、物理引擎、敌人系统、任务系统、商店系统、UI系统
- **技术栈（已确认）**: Godot 4.x + GDScript + Android Export（Gate-3：栈变化时须与 `docs/architecture.md` 同步）

## 仓库导航

- `AGENTS.md`：Agent 操作面板（栈、目录、可执行命令、安全）
- `docs/README.md`：文档目录与读写边界
- `docs/process/project-lifecycle.md`：全生命周期与 xijia 命令对照
- `.cursor/rules/00-workflow.mdc`：研发流程门禁与收尾规范
- `game/`：Godot 游戏项目根目录

## 快速开始

1. 阅读 `AGENTS.md` 与 `docs/README.md` 了解运行时命令与文档结构
2. 运行 `/xijia:start docs/requirements/inbox/` 查看种子需求
3. 游戏开发遵循 TDD：先写测试，再实现

> **活文档**：本文件为 Gate-3 维护对象；技术栈摘要须与 `docs/architecture.md` 保持一致。

## 游戏概述

AlphaBounce 是一款太空主题的动作消除游戏，核心玩法包括：

1. **球体物理**: 弹射球体消除方块
2. **导弹系统**: 多种导弹类型打击敌人
3. **24个星球区域**: 不同颜色和难度
4. **47个任务**: 丰富的任务链系统
5. **11种敌人**: Dragon, Drone, Generator 等
6. **商店系统**: 升级飞船、购买道具
