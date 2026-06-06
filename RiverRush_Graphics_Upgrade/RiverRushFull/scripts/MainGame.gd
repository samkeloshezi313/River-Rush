# =============================================================
# MainGame.gd  —  Root Node2D of Main.tscn
# =============================================================
extends Node2D

@onready var spawner:         Node2D          = $Spawner
@onready var hud:             CanvasLayer     = $HUD
@onready var player:          CharacterBody2D = $Player
@onready var start_screen:    Control         = $UIScreens/StartScreen
@onready var gameover_screen: Control         = $UIScreens/GameOverScreen
@onready var levelup_screen:  Control         = $UIScreens/LevelUpScreen
@onready var go_score:  Label = $UIScreens/GameOverScreen/Center/VBox/FinalScore
@onready var go_best:   Label = $UIScreens/GameOverScreen/Center/VBox/BestScore
@onready var go_level:  Label = $UIScreens/GameOverScreen/Center/VBox/FinalLevel
@onready var lu_num:    Label = $UIScreens/LevelUpScreen/Center/VBox/LevelNum
@onready var lu_name:   Label = $UIScreens/LevelUpScreen/Center/VBox/LevelName
@onready var lu_desc:   Label = $UIScreens/LevelUpScreen/Center/VBox/LevelDesc

const LEVELUP_DESCS: Array = [
	"The water moves faster.\nCrocs grow bolder. Stay sharp!",
	"Night crossing. Reduced visibility.\nMaximum danger. Almost there!",
	"Kofi reached Sanctuary Island!\nYou escaped the river!"
]

func _ready() -> void:
	GameManager.game_over_signal.connect(_on_game_over)
	GameManager.level_complete_signal.connect(_on_level_complete)
	_show_only(start_screen)

func start_game() -> void:
	GameManager.reset_game()
	player.position = Vector2(110, 230)
	spawner.clear_obstacles()
	spawner.start_spawning()
	hud.set_level_banner(GameManager.get_config().name)
	_show_only(null)

func continue_game() -> void:
	GameManager.next_level()
	spawner.clear_obstacles()
	spawner.start_spawning()
	hud.set_level_banner(GameManager.get_config().name)
	_show_only(null)

func restart_game() -> void:
	start_game()

func _on_game_over() -> void:
	spawner.stop_spawning()
	await get_tree().create_timer(0.6).timeout
	go_score.text = "Score:  " + str(GameManager.score)
	go_best.text  = "Best:   " + str(GameManager.best_score)
	go_level.text = "Level:  " + str(GameManager.level + 1)
	_show_only(gameover_screen)

func _on_level_complete() -> void:
	spawner.stop_spawning()
	spawner.clear_obstacles()
	var next := GameManager.level + 1
	lu_num.text  = str(next + 1) if next <= GameManager.MAX_LEVEL else "🏝️"
	lu_name.text = GameManager.LEVELS[next].name if next <= GameManager.MAX_LEVEL else "SANCTUARY ISLAND"
	lu_desc.text = LEVELUP_DESCS[GameManager.level]
	_show_only(levelup_screen)

func _show_only(screen) -> void:
	start_screen.visible    = screen == start_screen
	gameover_screen.visible = screen == gameover_screen
	levelup_screen.visible  = screen == levelup_screen
