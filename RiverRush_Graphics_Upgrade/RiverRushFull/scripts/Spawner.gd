# =============================================================
# Spawner.gd  —  Attach to Node2D named "Spawner"
# Children: SpawnTimer (Timer), PowerupTimer (Timer)
# =============================================================
extends Node2D

# Scene references — Godot will load these from res://scenes/
@onready var spawn_timer:   Timer = $SpawnTimer
@onready var powerup_timer: Timer = $PowerupTimer

var croc_scene:   PackedScene
var log_scene:    PackedScene
var powerup_scene: PackedScene

var viewport_w: float = 720.0

func _ready() -> void:
	viewport_w = get_viewport_rect().size.x
	# Load obstacle scenes
	croc_scene    = load("res://scenes/Crocodile.tscn")
	log_scene     = load("res://scenes/Log.tscn")
	powerup_scene = load("res://scenes/Powerup.tscn")

	spawn_timer.timeout.connect(_on_spawn_tick)
	powerup_timer.timeout.connect(_on_powerup_tick)

# ── Public API called by MainGame ─────────────────────────────
func start_spawning() -> void:
	var cfg := GameManager.get_config()
	spawn_timer.wait_time   = cfg.spawn_interval
	powerup_timer.wait_time = 8.5
	spawn_timer.start()
	powerup_timer.start()
	_spawn_initial()

func stop_spawning() -> void:
	spawn_timer.stop()
	powerup_timer.stop()

func clear_obstacles() -> void:
	for child in get_children():
		if child is CharacterBody2D or child is Area2D:
			child.queue_free()

# ── Spawn initial wave ────────────────────────────────────────
func _spawn_initial() -> void:
	var cfg := GameManager.get_config()
	for i in cfg.croc_count:
		_spawn_croc(viewport_w + 80 + randf_range(0, 600))
	for i in cfg.log_count:
		_spawn_log(viewport_w + 80 + randf_range(0, 800))

# ── Timer callbacks ───────────────────────────────────────────
func _on_spawn_tick() -> void:
	if not GameManager.is_playing():
		return
	if randf() < 0.55:
		_spawn_croc(viewport_w + 60)
	else:
		_spawn_log(viewport_w + 60)
	# Update interval for current level
	spawn_timer.wait_time = GameManager.get_config().spawn_interval

func _on_powerup_tick() -> void:
	if not GameManager.is_playing():
		return
	# Only spawn if player needs health or stamina
	_spawn_powerup(viewport_w + 60)

# ── Factory functions ─────────────────────────────────────────
func _spawn_croc(x: float) -> void:
	if not croc_scene:
		return
	var croc: CharacterBody2D = croc_scene.instantiate()
	croc.position = Vector2(x, randf_range(60, 400))
	var cfg := GameManager.get_config()
	croc.setup(cfg.obstacle_spd, cfg.croc_aggression)
	add_child(croc)

func _spawn_log(x: float) -> void:
	if not log_scene:
		return
	var log: CharacterBody2D = log_scene.instantiate()
	log.position = Vector2(x, randf_range(60, 400))
	log.setup(GameManager.get_config().obstacle_spd)
	add_child(log)

func _spawn_powerup(x: float) -> void:
	if not powerup_scene:
		return
	var pu: Area2D = powerup_scene.instantiate()
	pu.position = Vector2(x, randf_range(80, 380))
	add_child(pu)
