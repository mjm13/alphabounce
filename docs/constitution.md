# Project Constitution

## Purpose

This document defines non-negotiable engineering constraints for `Alphabounce 安卓复刻`.
It is created during init and should be reviewed whenever workflow rules are adjusted.

## Core Principles

1. Spec and plan first for non-trivial changes.
2. Use tests as executable truth; when spec and tests conflict, resolve artifacts before coding ahead.
3. Keep changes scoped to the minimum closed loop.
4. Synchronize durable knowledge only at closeout.

## Engineering Constraints

- Primary language/stack summary: `Godot 4（GDScript/C#）+ 安卓导出；纯单机，无后端/数据库`
- Project goal: `将 Motion Twin 的 2D 物理打砖块游戏 Alphabounce 复刻到安卓平台；首里程碑交付可玩 MVP demo（单机、无后端）。`
- Initial modules: `游戏核心玩法（球/挡板/砖块物理与碰撞）、关卡数据加载`

## Verification Baseline

1. Every behavior change must include executable validation evidence.
2. Report unexecuted checks with reason and fallback inspection.
3. Do not claim completion before closeout artifacts are synchronized.

## Safety Gates

Require explicit human confirmation before:

- destructive schema/data changes
- security/permission/secret policy updates
- decommissioning shipped capabilities
- introducing critical external dependencies

## Change Log

- 2026-08-18 - initialized by meijianming
