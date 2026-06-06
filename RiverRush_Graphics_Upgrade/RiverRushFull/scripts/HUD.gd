# =============================================================
# HUD.gd  —  Attach to CanvasLayer named "HUD"
# Expected child node paths (build these in the editor):
#   HUD/TopBar/ScoreBox/ScoreValue   (Label)
#   HUD/TopBar/HealthBar             (HBoxContainer)
#   HUD/TopBar/LevelBox/LevelValue   (Label)
#   HUD/LevelBanner                  (Label)
#   HUD/ProgressRow/ProgressBar      (ProgressBar)
#   HUD/StaminaRow/StaminaBar        (ProgressBar)
# =============================================================
extends CanvasLayer

@onready var score_val:    Label         = $TopBar/ScoreBox/ScoreValue
@onready var level_val:    Label         = $TopBar/LevelBox/LevelValue
@onready var health_bar:   HBoxContainer = $TopBar/HealthBar
@onready var level_banner: Label         = $LevelBanner
@onready var progress_bar: ProgressBar   = $ProgressRow/ProgressBar
@onready var stamina_bar:  ProgressBar   = $StaminaRow/StaminaBar

var player_ref: Node = null

func _ready() -> void:
	GameManager.score_changed.connect(_on_score)
	GameManager.health_changed.connect(_on_health)
	_refresh_health(GameManager.health)

	await get_tree().process_frame
	var found := get_tree().get_nodes_in_group("player")
	if found.size() > 0:
		player_ref = found[0]

func _process(_delta: float) -> void:
	if not GameManager.is_playing():
		return
	# Progress bar
	var cfg := GameManager.get_config()
	progress_bar.value = clamp(GameManager.distance / cfg.max_distance * 100.0, 0, 100)
	# Stamina bar
	if player_ref and is_instance_valid(player_ref):
		stamina_bar.value = player_ref.get_stamina()

func _on_score(val: int) -> void:
	score_val.text = str(val)

func _on_health(val: int) -> void:
	_refresh_health(val)

func _refresh_health(hp: int) -> void:
	for child in health_bar.get_children():
		child.queue_free()
	for i in GameManager.MAX_HEALTH:
		var lbl := Label.new()
		lbl.text = "❤️" if i < hp else "🖤"
		lbl.add_theme_font_size_override("font_size", 20)
		health_bar.add_child(lbl)

func set_level_banner(text: String) -> void:
	level_banner.text   = text
	level_val.text      = str(GameManager.level + 1)
