# AlphaBounce Test Suite

This directory contains tests for the AlphaBounce Godot implementation.

## Running Tests

```bash
godot --headless --path game --build-sceens tests/test_suite.tscn
```

## Test Structure

- `test_core/` - Core system tests
- `test_physics/` - Physics engine tests
- `test_mission/` - Mission system tests
- `test_enemy/` - Enemy AI tests
- `test_ui/` - UI system tests

## Writing Tests

Use Godot's built-in testing framework:

```gdscript
extends Node

func test_example():
    assert_true(true, "Basic assertion")
    assert_eq(1 + 1, 2, "Math check")
```
