# =============================================================
# Powerup.gd  —  Attach to Area2D named "Powerup"
# =============================================================
extends Area2D

enum Type { HEALTH, STAMINA }
var type:     Type  = Type.HEALTH
var bob_time: float = 0.0
var base_y:   float = 0.0
const SPEED:  float = 2.2

func _ready() -> void:
	base_y   = position.y
	bob_time = randf() * TAU
	# 30% chance of stamina paddle powerup
	type = Type.STAMINA if randf() < 0.30 else Type.HEALTH
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	bob_time   += delta * 2.2
	position.x -= SPEED
	position.y  = base_y + sin(bob_time) * 6.0
	queue_redraw()
	if position.x < -80:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match type:
		Type.HEALTH:
			if GameManager.health < GameManager.MAX_HEALTH:
				GameManager.health = min(GameManager.MAX_HEALTH, GameManager.health + 1)
				GameManager.health_changed.emit(GameManager.health)
		Type.STAMINA:
			body.restore_stamina(65.0)
	queue_free()

func _draw() -> void:
	var col := Color("#EF5350") if type == Type.HEALTH else Color("#FFC107")

	# Glowing outline
	draw_rect(Rect2(-16, -16, 32, 32), col.darkened(0.3))
	draw_rect(Rect2(-13, -13, 26, 26), col)

	# Icon
	if type == Type.HEALTH:
		# Red cross
		draw_rect(Rect2(-2, -9, 4, 18), Color(1, 1, 1, 0.92))
		draw_rect(Rect2(-9, -2, 18,  4), Color(1, 1, 1, 0.92))
	else:
		# Paddle icon
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color(1, 1, 1, 0.9), 3)
		draw_circle(Vector2(9, 0), 5, Color(1, 1, 1, 0.7))
