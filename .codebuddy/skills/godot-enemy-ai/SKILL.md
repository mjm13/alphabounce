---
name: godot-enemy-ai
description: "Use when implementing enemy AI behaviors in Godot - movement patterns, attack logic, and state machines"
version: "1.0.0"
---

# Godot Enemy AI Skill

## When to Use

- Creating enemy behaviors
- Implementing AI state machines
- Designing enemy patterns
- Balancing enemy difficulty

## Enemy Base Class

```gdscript
# scripts/entities/enemy/base_enemy.gd
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, DIE }

var state: State = State.IDLE
var target: Node2D
var health: int = 100
var speed: float = 100.0

func _physics_process(delta):
    match state:
        State.IDLE:
            idle_behavior(delta)
        State.CHASE:
            chase_behavior(delta)
        State.ATTACK:
            attack_behavior(delta)
        State.DIE:
            die_behavior(delta)

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        die()
```

## Enemy Types

### Dragon (ev/Dragon.hx)

```gdscript
# scripts/entities/enemy/dragon.gd
extends BaseEnemy

var flame_timer: float = 0.0
const FLAME_COOLDOWN = 2.0

func _physics_process(delta):
    super(delta)
    if state == State.ATTACK:
        flame_timer += delta
        if flame_timer >= FLAME_COOLDOWN:
            spawn_flame()
            flame_timer = 0.0

func spawn_flame():
    var flame = preload("res://scenes/entities/Flame.tscn").instantiate()
    add_child(flame)
    flame.direction = get_direction_to_player()
```

### Drone (ev/Drone.hx)

```gdscript
# scripts/entities/enemy/drone.gd
extends BaseEnemy

var patrol_points: Array[Vector2]
var current_point: int = 0

func idle_behavior(delta):
    var target_pos = patrol_points[current_point]
    var direction = (target_pos - position).normalized()
    velocity = direction * speed * 0.5
    move_and_slide()
    
    if position.distance_to(target_pos) < 10:
        current_point = (current_point + 1) % patrol_points.size()
```

### Generator (ev/Generator.hx)

```gdscript
# scripts/entities/enemy/generator.gd
extends BaseEnemy

var spawn_timer: float = 0.0
const SPAWN_INTERVAL = 5.0

func _physics_process(delta):
    super(delta)
    spawn_timer += delta
    if spawn_timer >= SPAWN_INTERVAL:
        spawn_minion()
        spawn_timer = 0.0
```

## AI Patterns

### Chase Pattern

```gdscript
func chase_behavior(delta):
    if target:
        var direction = (target.position - position).normalized()
        velocity = direction * speed
        move_and_slide()
        
        # Attack when close
        if position.distance_to(target.position) < ATTACK_RANGE:
            state = State.ATTACK
```

### Flee Pattern

```gdscript
func flee_behavior(delta):
    if target:
        var direction = (position - target.position).normalized()
        velocity = direction * speed * 1.5
        move_and_slide()
```

### Patrol Pattern

```gdscript
func patrol_behavior(delta):
    var target_pos = patrol_waypoints[current_index]
    var direction = (target_pos - position).normalized()
    
    if position.distance_to(target_pos) < 5:
        current_index = (current_index + 1) % patrol_waypoints.size()
    else:
        velocity = direction * patrol_speed
        move_and_slide()
```

## State Machine

```gdscript
# scripts/systems/state_machine.gd
class StateMachine:
    var states: Dictionary = {}
    var current_state: String = ""
    
    func add_state(name: String, state: Node):
        states[name] = state
        
    func change_state(new_state: String):
        if current_state in states:
            states[current_state].exit()
        
        current_state = new_state
        if current_state in states:
            states[current_state].enter()
    
    func process(delta):
        if current_state in states:
            states[current_state].process(delta)
```

## Migration from Haxe

| Haxe | Godot GDScript |
|------|---------------|
| `Dragon.hx` | `scripts/entities/enemy/dragon.gd` |
| `Drone.hx` | `scripts/entities/enemy/drone.gd` |
| `Generator.hx` | `scripts/entities/enemy/generator.gd` |
| `update()` | `_physics_process()` |
| `Collision` | `body_entered` signal |

## Test Cases

```gdscript
# tests/test_enemy_ai.gd
extends Test

func test_dragon_spawns_flame():
    var dragon = preload("res://scenes/entities/enemy/Dragon.tscn").instantiate()
    add_child(dragon)
    
    # Fast forward time
    dragon.flame_timer = 2.0
    dragon._physics_process(1.0)
    
    assert_true(dragon.has_flame_spawning, "Dragon should spawn flame after cooldown")

func test_drone_patrols():
    var drone = preload("res://scenes/entities/enemy/Drone.tscn").instantiate()
    add_child(drone)
    
    var start_pos = drone.position
    drone._physics_process(10.0)
    
    assert_true(drone.position != start_pos, "Drone should move during patrol")
```
