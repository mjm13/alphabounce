# 研发约定（Conventions）

## 需求分级

- 🟢 轻量：配置/样式/简单 CRUD
- 🟡 中等：单上下文常规功能
- 🔴 核心：复杂规则、跨上下文、多聚合

## 基本流程

`explore -> propose -> apply -> verify -> sync -> archive -> xijia-sync-knowledge -> commit`

## 核心原则

- 先分级，再决定流程深度
- 小步切片：一个 change = 一条端到端链路
- 测试优先于文字 Spec
- 每个需求收尾必须包含人工验收说明
- 以 `git commit` 作为需求完成的最终动作

## Godot 开发约定

### 命名规范

- **脚本文件**: `snake_case.gd` (如 `ball.gd`, `mission_system.gd`)
- **场景文件**: `snake_case.tscn` (如 `main_menu.tscn`)
- **类名**: PascalCase (如 `Ball`, `MissionSystem`)
- **节点名**: snake_case (如 `player_sprite`, `score_label`)

### 目录结构

```
scripts/
├── core/        # 核心系统
├── entities/    # 游戏实体
├── ui/          # UI 组件
└── systems/     # 游戏系统

scenes/
├── main/        # 主菜单
├── levels/      # 关卡
├── ui/          # UI 场景
└── entities/    # 实体
```

### 代码风格

- 使用 4 空格缩进
- 函数之间空一行
- 常量使用 UPPER_SNAKE_CASE
- 私有变量使用 `_` 前缀
- 使用 `@export` 暴露变量到编辑器

### Git 约定

- 分支命名: `feature/xxx`, `fix/xxx`, `chore/xxx`
- 提交信息: `type(scope): description`
  - `feat: add ball physics system`
  - `fix: resolve collision detection bug`
  - `chore: update project settings`

## 测试约定

- 每个核心系统必须有单元测试
- 使用 Godot 的 `ClassDB` 和 `assert` 进行验证
- 测试文件放在 `tests/` 目录

## Android 构建约定

- 目标 SDK: 33+
- 最小 SDK: 21
- 支持屏幕密度: mdpi 到 xxxhdpi
- 触摸控制优先于虚拟按钮
