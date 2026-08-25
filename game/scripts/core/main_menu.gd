extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("tap_pause"):
		get_tree().paused = not get_tree().paused
