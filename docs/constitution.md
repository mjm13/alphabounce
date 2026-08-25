# Project Constitution

## Purpose

本文档定义 **Alphabounce_M** 项目的不可协商工程约束。用于 Haxe/Pixi.js → Godot/GDScript 的重构迁移。

## Core Principles

1. **Spec and plan first**: 非平凡变更必须先有规格和计划
2. **TDD 优先**: 测试是可执行的真相；当 spec 与测试冲突时，先解决工件再编码
3. **最小闭环**: 保持变更范围封闭在最小闭环内
4. **知识同步**: 仅在收尾时同步持久化知识

## Engineering Constraints

- **主要技术栈**: Godot 4.x + GDScript
- **目标平台**: Android
- **源项目**: Haxe/Pixi.js (EternalTwin-Alphabounce)
- **项目目标**: 完整迁移游戏功能到 Godot

## Verification Baseline

1. 每个行为变更必须包含可执行的验证证据
2. 报告未执行的检查及原因和备用检查
3. 在 closeout 工件同步前不得声称完成

## Safety Gates

以下操作需要明确的**人工确认**：

- 破坏性 schema/数据变更
- 安全/权限/秘密策略更新
- 退役已交付能力
- 引入关键外部依赖

## Godot 迁移约束

- 保持原有游戏逻辑不变
- 物理引擎从 Pixi.js 自定义实现迁移到 Godot Physics
- 渲染从 Canvas 2D 迁移到 Godot 2D
- 触摸控制替代鼠标控制
- 音频从 Web Audio API 迁移到 Godot Audio

## Change Log

- 2025-01-01 - initialized by Agnes for Alphabounce_M migration
