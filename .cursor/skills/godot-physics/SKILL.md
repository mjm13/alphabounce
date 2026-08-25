---
name: godot-physics
description: "Use when implementing physics systems in Godot - ball physics, collision detection, and rigid body dynamics"
version: "1.0.0"
---

# Godot Physics System Skill

## When to Use

- Implementing ball physics
- Setting up collision detection
- Creating rigid body interactions
- Optimizing physics performance

## Ball Physics Implementation

### 基础球体物理

```gdscript
extends CharacterBody2D

const SPEED = 300.0
const BOUNCE_DAMPING = 0.9

var velocity = Vector2.ZERO
var ball_type: int = 0  # 0: normal, 1: fire, 2: ice, etc.

func _physics_process(delta):
    velocity *= BOUNCE_DAMPING
    position += velocity * delta
    check_boundaries()
```

### 碰撞响应

```gdscript
func _on_body_entered(body):
    if body.is_in_group("blocks"):
        handle_block_collision(body)
    elif body.is_in_group("enemies"):
        handle_enemy_collision(body)
    elif body.is_in_group("items"):
        collect_item(body)
```

### 网格坐标系统

```gdscript
# 从像素坐标到网格坐标
func world_to_grid(pos: Vector2) -> Vector2:
    return Vector2(
        int(pos.x / GRID_SIZE),
        int(pos.y / GRID_SIZE)
    )

# 从网格坐标到像素坐标
func grid_to_world(grid_pos: Vector2) -> Vector2:
    return Vector2(
        grid_pos.x * GRID_SIZE + GRID_SIZE / 2,
        grid_pos.y * GRID_SIZE + GRID_SIZE / 2
    )
```

## Collision Layers

```gdscript
# 定义碰撞层
const LAYER_BALL = 1
const LAYER_BLOCK = 2
const LAYER_ENEMY = 4
const LAYER_ITEM = 8
const LAYER_PAD = 16

# 设置碰撞形状
func setup_collision():
    $CollisionShape2D.shape = CircleShape2D.new()
    $CollisionShape2D.shape.radius = 10
```

## Physics Optimization

1. **使用 SpatialPartition** 进行高效查询
2. **限制物理更新频率** 使用 `set_fixed_logic_fps()`
3. **批量处理碰撞** 使用 `move_and_collide()` 而非信号
4. **对象池** 复用频繁创建销毁的对象

## Migration from Haxe

| Haxe/Pixi.js | Godot GDScript |
|-------------|----------------|
| `Element.update()` | `_physics_process()` |
| `onBounce()` | `_on_body_entered()` |
| `isFree(x, y)` | `is_free_cell(x, y)` |
| `Grid<StringMap<Block>>` | `Dictionary<Vector2i, Block>` |

## Test Cases

```gdscript
# tests/test_ball_physics.gd
extends Test

func test_ball_bounce():
    var ball = create_ball()
    ball.velocity = Vector2(100, 0)
    ball.position = Vector2(50, 50)
    
    # 模拟碰撞
    ball.position = Vector2(100, 50)
    assert_true(ball.velocity.x < 0, "Ball should bounce")

func test_ball_gravity():
    var ball = create_ball()
    ball.apply_gravity()
    assert_true(ball.velocity.y > 0, "Ball should fall")
```
