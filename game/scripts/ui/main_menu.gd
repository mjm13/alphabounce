extends Control

# [R14] 主菜单 UI：提供开始游戏、商店、任务、调试入口，适配触摸与 Android 屏幕缩放。

const GAME_SCENE := "res://scenes/main/Game.tscn"
const SHOP_SCENE := "res://debug/R06_shop_debug.tscn"
const MISSION_SCENE := "res://debug/R05_debug.tscn"
const DEBUG_SCENE := "res://debug/debug_launcher.tscn"

func _ready() -> void:
	_setup_menu()

func _setup_menu() -> void:
	var vbox := $VBoxContainer
	if vbox == null:
		return
	_set_button("Start", _on_start)
	_set_button("Shop", _on_shop)
	_set_button("Missions", _on_missions)
	_set_button("Debug", _on_debug)

func _set_button(name: String, handler: Callable) -> void:
	var btn := get_node_or_null("VBoxContainer/%s" % name)
	if btn != null and not btn.pressed.is_connected(handler):
		btn.pressed.connect(handler)

func _on_start() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)

func _on_missions() -> void:
	get_tree().change_scene_to_file(MISSION_SCENE)

func _on_debug() -> void:
	get_tree().change_scene_to_file(DEBUG_SCENE)
