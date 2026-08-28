---
name: godot-mission-system
description: "Use when implementing mission/task systems in Godot - condition checking, reward distribution, and mission state management"
version: "1.0.0"
---

# Godot Mission System Skill

## When to Use

- Implementing mission logic
- Creating condition checkers
- Managing mission rewards
- Handling mission progression

## Mission Data Structure

```gdscript
# scripts/systems/mission.gd
class Mission:
    var id: int
    var name: String
    var description: String
    var conditions: Array[Array]  # [[condition_type, param1, param2...]]
    var start_items: Array[Array]  # [[item_id, item_status]]
    var end_items: Array[Array]
    var status: int = -1  # -1: not started, 0: active, 1: completed
    
    enum ConditionType {
        GOT_ITEM = 0,
        GOT_SHOPITEM = 1,
        GOT_PLANET = 2,
        ENTER_ZONE = 3,
        LEAVE_ZONE = 4,
        GOT_MISSION = 5,
        GOT_MISSILE = 6,
        GOT_MINERAI = 7,
        NOT_ITEM = 8,
        IS_LEVEL = 9
    }
```

## Mission Manager

```gdscript
# scripts/systems/mission_manager.gd
extends Node

var missions: Dictionary = {}
var player: PlayerInfo

func init_missions():
    for mission_data in MissionInfo.LIST:
        var mission = Mission.new()
        mission.id = mission_data.id
        mission.name = mission_data.name
        mission.conditions = mission_data.conditions
        mission.start_items = mission_data.startItem
        mission.end_items = mission_data.endItem
        mission.status = -1
        missions[mission.id] = mission

func check_missions():
    for id in missions.keys():
        var mission = missions[id]
        if mission.status == -1:
            if check_start_conditions(mission):
                mission.status = 0
                give_start_items(mission)
        elif mission.status == 0:
            if check_end_conditions(mission):
                mission.status = 1
                give_end_items(mission)
```

## Condition Checking

```gdscript
func check_condition(condition: Array) -> bool:
    match condition[0]:
        Mission.ConditionType.GOT_ITEM:
            for i in range(1, condition.size()):
                if not player.got_item(condition[i]):
                    return false
            return true
            
        Mission.ConditionType.GOT_PLANET:
            return player.comp[condition[1]] >= ZoneInfo.get_squares_length(condition[1])
            
        Mission.ConditionType.ENTER_ZONE:
            var dx = condition[1] - player.x
            var dy = condition[2] - player.y
            return sqrt(dx*dx + dy*dy) <= condition[3]
            
        Mission.ConditionType.LEAVE_ZONE:
            var dx = condition[1] - player.x
            var dy = condition[2] - player.y
            return sqrt(dx*dx + dy*dy) > condition[3]
            
        _:
            return true
```

## Migration from Haxe

| Haxe | Godot GDScript |
|------|---------------|
| `MissionInfo.LIST` | `MissionInfo.MISSIONS` |
| `GOT_ITEM` constant | `Mission.ConditionType.GOT_ITEM` |
| `player.gotItem(n)` | `player.got_item(n)` |
| `isAllConditionsOk(list)` | `check_all_conditions(list)` |

## Test Cases

```gdscript
# tests/test_mission.gd
extends Test

func test_mission_start_condition():
    var mission = create_mission()
    mission.status = -1
    mission.start_conditions = [[Mission.ConditionType.GOT_MISSION, 0]]
    
    player.missions[0] = 1  # Complete mission 0
    assert_true(mission.check_start_conditions(), "Should start when prerequisite completed")

func test_mission_complete():
    var mission = create_mission()
    mission.status = 0
    mission.conditions = [[Mission.ConditionType.GOT_ITEM, MissionInfo.FIRST_LEVEL]]
    
    player.items[MissionInfo.FIRST_LEVEL] = MissionInfo.COLLECTED
    assert_true(mission.check_end_conditions(), "Should complete when item collected")
```
