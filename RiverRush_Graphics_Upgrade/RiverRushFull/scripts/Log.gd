# Log.gd — Realistic wood texture
extends CharacterBody2D

var move_speed:  float = 150.0
var drift_speed: float = 30.0
var rot_speed:   float = 0.5
var phase:       float = 0.0
var anim_time:   float = 0.0

const SCREEN_TOP: float = 44.0
const SCREEN_BOT: float = 416.0

func _ready() -> void:
	phase     = randf() * TAU
	rot_speed = randf_range(-0.55, 0.55)
	add_to_group("obstacles")

func setup(base_speed: float) -> void:
	move_speed  = base_speed * randf_range(0.55, 0.85)
	drift_speed = randf_range(-55.0, 55.0)

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	anim_time += delta
	rotation  += rot_speed * delta
	velocity.x = -move_speed
	velocity.y  = drift_speed + sin(anim_time * 0.9 + phase) * 22.0
	position.y = clamp(position.y, SCREEN_TOP, SCREEN_BOT)
	move_and_slide()
	for i in get_slide_collision_count():
		var col  := get_slide_collision(i)
		var body := col.get_collider()
		if body != null and body.is_in_group("player"):
			body.take_hit()
	queue_redraw()
	if position.x < -150.0:
		position.x = get_viewport_rect().size.x + 60.0 + randf_range(0, 200)
		position.y = randf_range(60, 400)
		rotation   = randf() * TAU

func _draw() -> void:
	var w:  float = 92.0
	var h:  float = 24.0
	var hw: float = w * 0.5
	var hh: float = h * 0.5

	# ── Drop shadow ───────────────────────────────────────────
	draw_rect(Rect2(-hw + 5.0, -hh + 9.0, w, h), Color(0, 0, 0, 0.38))

	# ── Bark outer layer ──────────────────────────────────────
	draw_rect(Rect2(-hw, -hh, w, h), Color(0.22, 0.13, 0.07))

	# ── Wood body — base colour gradient (3 strips) ───────────
	var strips := [
		[Color(0.36, 0.21, 0.10), 0.0,       h * 0.33],
		[Color(0.44, 0.27, 0.13), h * 0.33,  h * 0.34],
		[Color(0.30, 0.18, 0.09), h * 0.67,  h * 0.33],
	]
	for s in strips:
		draw_rect(Rect2(-hw, -hh + s[1], w, s[2]), s[0])

	# ── Wood grain lines ──────────────────────────────────────
	var grain_cols := [
		Color(0.26, 0.15, 0.07, 0.55),
		Color(0.50, 0.32, 0.15, 0.40),
		Color(0.20, 0.11, 0.05, 0.50),
		Color(0.48, 0.30, 0.14, 0.35),
		Color(0.24, 0.14, 0.06, 0.45),
	]
	for g in 5:
		var gy: float = -hh + float(g + 1) * (h / 6.0)
		# Slightly wavy grain
		var grain_pts := PackedVector2Array()
		for xi in 12:
			var gx: float = -hw + float(xi) * (w / 11.0)
			var gy2: float = gy + sin(float(xi) * 0.8 + float(g) * 1.3) * 1.5
			grain_pts.append(Vector2(gx, gy2))
		draw_polyline(grain_pts, grain_cols[g], 1.0, true)

	# ── Knot — circular grain disruption ─────────────────────
	var kx: float = hw * 0.18   # slight offset from centre
	var ky: float = hh * 0.15
	for ring in 4:
		var kr: float = float(ring + 1) * 2.8
		var ka: float = 0.45 - float(ring) * 0.08
		_ellipse(Vector2(kx, ky), Vector2(kr, kr*0.65), Color(0.18, 0.10, 0.05, ka), 10)

	# ── Bark texture — irregular dark patches ─────────────────
	for i in 6:
		var bx: float = -hw * 0.75 + float(i) * hw * 0.28
		draw_rect(Rect2(bx, -hh,      randf_range(3,6), randf_range(2,4)), Color(0.14,0.08,0.04,0.5))
		draw_rect(Rect2(bx+2, hh-3.0, randf_range(3,5), randf_range(2,3)), Color(0.14,0.08,0.04,0.45))

	# ── Water-darkened wet patch on one side ──────────────────
	draw_rect(Rect2(-hw, -hh, w * 0.22, h), Color(0.14, 0.08, 0.04, 0.40))

	# ── Moss patch ────────────────────────────────────────────
	_ellipse(Vector2(-hw*0.28, -hh*0.45), Vector2(12.0, 5.5), Color(0.18, 0.34, 0.10, 0.58))
	_ellipse(Vector2(-hw*0.15, -hh*0.35), Vector2(7.0,  3.5), Color(0.22, 0.40, 0.12, 0.45))

	# ── Cut end grain — LEFT (growth rings) ───────────────────
	_draw_end_grain(Vector2(-hw, 0.0), hh)

	# ── Cut end grain — RIGHT ─────────────────────────────────
	_draw_end_grain(Vector2(hw, 0.0), hh)

func _draw_end_grain(center: Vector2, hh: float) -> void:
	# Outermost ring (bark)
	_ellipse(center, Vector2(5.5, hh - 0.5), Color(0.18, 0.10, 0.05), 14)
	# Sapwood rings (light)
	for ring in 4:
		var r: float = hh - 2.0 - float(ring) * ((hh - 3.5) / 4.5)
		var col: Color = Color(0.52, 0.34, 0.18).lerp(Color(0.35, 0.22, 0.11), float(ring)/3.0)
		_ellipse(center, Vector2(4.5, r), col, 12)
	# Heartwood (dark centre)
	_ellipse(center, Vector2(3.5, hh * 0.28), Color(0.22, 0.13, 0.07), 10)
	_ellipse(center, Vector2(2.0, hh * 0.16), Color(0.16, 0.09, 0.05), 8)

func _ellipse(center: Vector2, radii: Vector2, color: Color, segs: int = 20) -> void:
	var pts := PackedVector2Array()
	for i in segs:
		var a: float = float(i) / float(segs) * TAU
		pts.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(pts, color)
