# =============================================================
# GameManager.gd  —  AutoLoad Singleton
# Add via: Project > Project Settings > AutoLoad
# Name it exactly: GameManager
# =============================================================
extends Node

# ── Signals ──────────────────────────────────────────────────
signal score_changed(new_score: int)
signal health_changed(new_health: int)
signal game_over_signal
signal level_complete_signal

# ── Constants ────────────────────────────────────────────────
const MAX_HEALTH: int = 3
const MAX_LEVEL:  int = 2   # levels 0, 1, 2

# ── Level Configuration ───────────────────────────────────────
const LEVELS: Array = [
	{
		"name":          "CALM WATERS",
		"scroll_speed":  200.0,
		"obstacle_spd":  190.0,
		"croc_count":    2,
		"log_count":     3,
		"max_distance":  900.0,
		"spawn_interval":2.2,
		"croc_aggression":0.003,
		"water_top":     Color(0.043, 0.239, 0.376),
		"water_bot":     Color(0.082, 0.431, 0.627),
	},
	{
		"name":          "THE RAPIDS",
		"scroll_speed":  310.0,
		"obstacle_spd":  280.0,
		"croc_count":    4,
		"log_count":     5,
		"max_distance":  1400.0,
		"spawn_interval":1.6,
		"croc_aggression":0.005,
		"water_top":     Color(0.027, 0.165, 0.267),
		"water_bot":     Color(0.051, 0.290, 0.502),
	},
	{
		"name":          "STORM'S END",
		"scroll_speed":  420.0,
		"obstacle_spd":  380.0,
		"croc_count":    6,
		"log_count":     7,
		"max_distance":  1900.0,
		"spawn_interval":1.0,
		"croc_aggression":0.008,
		"water_top":     Color(0.016, 0.051, 0.094),
		"water_bot":     Color(0.027, 0.102, 0.196),
	}
]

# ── State ─────────────────────────────────────────────────────
enum State { START, PLAYING, LEVEL_UP, GAME_OVER }
var current_state: State = State.START

var score:      int   = 0
var health:     int   = MAX_HEALTH
var level:      int   = 0
var distance:   float = 0.0
var best_score: int   = 0

# ── Helpers ───────────────────────────────────────────────────
func get_config() -> Dictionary:
	return LEVELS[clamp(level, 0, MAX_LEVEL)]

func is_playing() -> bool:
	return current_state == State.PLAYING

# ── Actions ───────────────────────────────────────────────────
func add_score(pts: int) -> void:
	score += pts
	score_changed.emit(score)

func take_damage() -> void:
	if not is_playing():
		return
	health = max(0, health - 1)
	health_changed.emit(health)
	if health == 0:
		current_state = State.GAME_OVER
		if score > best_score:
			best_score = score
		game_over_signal.emit()

func advance_distance(delta: float) -> void:
	if not is_playing():
		return
	distance += get_config().scroll_speed * delta * 0.3
	if distance >= get_config().max_distance:
		if level < MAX_LEVEL:
			current_state = State.LEVEL_UP
			level_complete_signal.emit()
		else:
			# Player won!
			score += 1000
			add_score(0)
			if score > best_score:
				best_score = score
			current_state = State.GAME_OVER
			game_over_signal.emit()

func reset_game() -> void:
	score    = 0
	health   = MAX_HEALTH
	level    = 0
	distance = 0.0
	current_state = State.PLAYING
	score_changed.emit(score)
	health_changed.emit(health)

func next_level() -> void:
	level    = min(level + 1, MAX_LEVEL)
	distance = 0.0
	current_state = State.PLAYING
