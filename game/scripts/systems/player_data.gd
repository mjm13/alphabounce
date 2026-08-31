extends Node

## 玩家存档管理器（Autoload 单例）。
## 持久化：当前关卡 / 最高解锁 / 星星货币 / 物品库存 / 任务状态 → user://player_save.json。
## 首启无存档则创建默认空存档（level=1, stars=0, inventory={}, missions={}）。
## 注：方法命名为 load_data 以避免与 GDScript 全局 load() 冲突。

const SAVE_PATH := "user://player_save.json"
const SAVE_FILE := "player_save.json"

var current_level: int = 1
var max_level_unlocked: int = 1
var stars: int = 0
var inventory: Dictionary = {}
var missions: Dictionary = {}
var lives: int = 3

signal saved
signal loaded


func _ready() -> void:
	load_data()


func save() -> bool:
	var data := {
		"current_level": current_level,
		"max_level_unlocked": max_level_unlocked,
		"stars": stars,
		"inventory": inventory,
		"missions": missions,
	}
	var txt := JSON.stringify(data)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		printerr("R07_SAVE_FAIL: ", SAVE_PATH)
		return false
	f.store_string(txt)
	f.close()
	saved.emit()
	return true


func load_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_reset_default()
		return save()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		_reset_default()
		return false
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY:
		_reset_default()
		return false
	current_level = int(d.get("current_level", 1))
	max_level_unlocked = int(d.get("max_level_unlocked", 1))
	stars = int(d.get("stars", 0))
	inventory = d.get("inventory", {})
	missions = d.get("missions", {})
	loaded.emit()
	return true


## 关卡完成时的存档触发点：由 game.gd / R10 游戏循环调用，debug 场景亦直接调用验证。
func on_level_complete() -> void:
	max_level_unlocked = maxi(max_level_unlocked, current_level + 1)
	save()


## 玩家损失一条生命（敌/闪电/Molecule 碰玩家）。生命归零由 game.gd 触发 GameOver。
func lose_life() -> void:
	lives -= 1
	if lives < 0:
		lives = 0


## 删除现有存档（用于首启/重置测试）。Godot 4 DirAccess 实例方法为 remove(path)。
func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove(SAVE_FILE)


func _reset_default() -> void:
	current_level = 1
	max_level_unlocked = 1
	stars = 0
	inventory = {}
	missions = {}
