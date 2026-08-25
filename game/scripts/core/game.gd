extends Node2D

const BALL_SCENE = preload("res://scenes/entities/Ball.tscn")
const PAD_SCENE = preload("res://scenes/entities/Pad.tscn")

var score: int = 0
var lives: int = 3
var missiles: int = 0

@onready var camera = $Camera2D
@onready var world = $World
@onready var hud_score = $HUD/Score
@onready var hud_lives = $HUD/Lives
@onready var hud_missile = $HUD/Missile

func _ready():
	_init_game()

func _init_game():
	score = 0
	lives = 3
	missiles = 0
	_update_hud()

func _input(event):
	if event.is_action_pressed("tap_pause"):
		get_tree().paused = not get_tree().paused
	
	if event.is_action_pressed("tap_shoot") and missiles > 0:
		_fire_missile()

func _fire_missile():
	missiles -= 1
	_update_hud()
	# TODO: Implement missile logic

func _add_score(points: int):
	score += points
	_update_hud()

func _lose_life():
	lives -= 1
	_update_hud()
	if lives <= 0:
		_game_over()

func _game_over():
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _update_hud():
	hud_score.text = "分数: %d" % score
	hud_lives.text = "生命: %d" % lives
	hud_missile.text = "导弹: %d" % missiles
