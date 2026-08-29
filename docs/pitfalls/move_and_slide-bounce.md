# move_and_slide 反射必须基于碰撞前速度

> 来源：R03 测试阶段暴露的真实问题。

## 陷阱

`CharacterBody2D.move_and_slide()` 在撞到墙体时会把**沿法向的速度分量清零**（slide 行为）。
若直接对 `move_and_slide()` 之后的 `velocity` 做 `velocity.bounce(normal)`，此时速度已被清零，
反射结果为 `(0,0)` —— 球体「撞墙后瞬间静止、失去所有动能」。

## 正确写法

```gdscript
velocity += acceleration * delta
velocity *= friction
var pre := velocity
move_and_slide()
var col := get_last_slide_collision()
if col != null:
    velocity = pre.bounce(col.get_normal()) * RESTITUTION
```

用碰撞**前**保存的 `pre` 做反射，restitution 才能正确施加在入射速度上。

## 关联

- `Ball.tscn` 的 `physics_material_override.bounce` 须设为 0，否则 `move_and_slide` 自身也会施加
  弹性，与手动反射叠加导致反弹倍率翻倍。
