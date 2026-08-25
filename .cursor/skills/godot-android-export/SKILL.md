---
name: godot-android-export
description: "Use when configuring Godot project for Android export - build settings, touch controls, and performance optimization"
version: "1.0.0"
---

# Godot Android Export Skill

## When to Use

- Configuring Android export presets
- Setting up touch controls
- Optimizing for mobile performance
- Building APK/AAB files

## Export Configuration

### 基本设置

```ini
# project.godot
config/name="AlphaBounce"
config/version="0.1.0"
application/config/icon="res://resouces/icons/icon.svg"
application/run/main_scene="res://scenes/main/Main.tscn"
```

### Android 导出设置

```gdscript
# .export_presets.cfg
[preset.0]
name="Android"
platform="Android"
runnable=true
dedicated_server=false

[preset.0.options]
package/unique_name="com.eternaltwin.alphabounce"
package/name="AlphaBounce"
custom_package/debug=""
custom_package/release=""
```

## Touch Controls

### 触摸输入处理

```gdscript
extends Node

var touch_start_pos = Vector2.ZERO
var touch_end_pos = Vector2.ZERO
var is_touching = false

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_start_pos = event.position
            is_touching = true
        else:
            touch_end_pos = event.position
            is_touching = false
            handle_touch_release()
    elif event is InputEventScreenDrag and is_touching:
        touch_end_pos = event.position
        handle_touch_drag(touch_end_pos - touch_start_pos)
```

### 虚拟按钮

```gdscript
extends Control

@export var button_pressed: Signal
@export var button_released: Signal

func _input(event):
    if event is InputEventScreenTouch:
        if get_rect().has_point(event.position):
            if event.pressed:
                button_pressed.emit()
            else:
                button_released.emit()
```

## Performance Optimization

### 纹理优化

```gdscript
# 启用纹理压缩
texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# 使用 Atlas
var atlas = AtlasTexture.new()
atlas.atlas = preload("res://resouces/textures/atlas.png")
atlas.region = Rect2(0, 0, 32, 32)
```

### 对象池

```gdscript
class_name ObjectPool
extends Node

var pool: Array = []
var scene: PackedScene

func prepare(prepare_count: int):
    for i in prepare_count:
        var obj = scene.instantiate()
        obj.queue_free()
        pool.append(obj)

func get() -> Node:
    if pool.size() > 0:
        return pool.pop_back()
    return scene.instantiate()

func release(obj: Node):
    obj.queue_free()
    pool.append(obj)
```

## Build Commands

### 导出 APK (Debug)

```bash
godot --export-debug "Android"
```

### 导出 AAB (Release)

```bash
godot --export-release "Android"
```

### 安装到设备

```bash
adb install -r app-debug.apk
```

## Common Issues

| 问题 | 解决方案 |
|------|----------|
| 触摸无响应 | 检查 `InputMap` 配置 |
| 屏幕比例失真 | 设置 `display/stretch mode = viewport` |
| 性能卡顿 | 检查 Draw Call，使用纹理图集 |
| 内存不足 | 及时 `free()` 大纹理 |
