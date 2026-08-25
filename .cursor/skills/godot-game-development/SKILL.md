---
name: godot-game-development
description: "Use when developing Godot games - covers project structure, GDScript patterns, scene management, and Android export"
version: "1.0.0"
---

# Godot Game Development Skill

## When to Use

- Creating new Godot projects
- Writing GDScript code
- Managing scenes and nodes
- Exporting for Android

## Core Rules

### Project Structure

```
game/
├── project.godot          # 项目配置（只读）
├── scenes/                # 场景文件
│   ├── main/             # 主菜单、加载画面
│   ├── levels/           # 关卡场景
│   ├── ui/               # UI 界面
│   └── entities/         # 游戏实体
├── scripts/               # GDScript 脚本
│   ├── core/             # 核心系统
│   ├── entities/         # 实体逻辑
│   ├── ui/               # UI 逻辑
│   └── systems/          # 游戏系统
└── resouces/              # 资源文件
    ├── textures/         # 图片
    ├── audio/            # 音频
    └── fonts/            # 字体
```

### GDScript 命名规范

- **脚本文件**: `snake_case.gd`
- **类名**: PascalCase
- **节点名**: snake_case
- **常量**: UPPER_SNAKE_CASE
- **私有变量**: `_` 前缀

### Scene Management

```gdscript
# 加载场景
var scene = load("res://scenes/main/Menu.tscn")
var instance = scene.instantiate()
get_tree().root.add_child(instance)

# 切换场景
get_tree().change_scene_to_file("res://scenes/main/Game.tscn")
```

### Android Export

```gdscript
# 触摸输入
func _input(event):
    if event is InputEventScreenTouch:
        handle_touch(event.position)
    elif event is InputEventScreenDrag:
        handle_drag(event.position)
```

## Godot 4.x 迁移要点

| 旧版 (3.x) | 新版 (4.x) |
|-----------|-----------|
| `Signal.connect()` | `connect()` 方法 |
| `get_node()` | `get_node()` 保持不变 |
| `PhysicsServer` | `PhysicsServer2D`/`3D` |
| `CanvasItem.draw_*` | 保持不变 |
| `ResourceLoader` | `load()` 函数 |

## 常见模式

### Singleton (Autoload)

```gdscript
# scripts/core/GameData.gd
extends Node

var player_score: int = 0
var current_level: int = 0

func save_game():
    var save_data = {
        "score": player_score,
        "level": current_level
    }
    var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
```

### Signal 通信

```gdscript
# 发出信号
signal level_completed(score)
signal enemy_defeated(enemy_type)

# 连接信号
node.signal_name.connect(on_signal_name)
```

## Android 特定注意事项

1. **触摸控制**: 优先使用 `InputEventScreenTouch` 而非虚拟按钮
2. **屏幕适配**: 使用 `display/stretch` 模式
3. **性能优化**: 限制 Draw Call，使用纹理图集
4. **内存管理**: 及时释放不再使用的资源
