# Player.gd — Enhanced raft graphics
extends CharacterBody2D

const ACCEL:         float = 950.0
const FRICTION:      float = 6.5
const MAX_Y_SPD:     float = 290.0
const STAMINA_DRAIN: float = 34.0
const STAMINA_REGEN: float = 18.0
const INV_DURATION:  float = 1.8
const SCREEN_TOP:    float = 44.0
const SCREEN_BOT:    float = 416.0

var stamina:    float = 100.0
var invincible: bool  = false
var inv_timer:  float = 0.0
var anim_time:  float = 0.0
var score_tick: float = 0.0
var hit_flash:  float = 0.0

func _ready() -> void:
	position = Vector2(110, 230)
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	anim_time  += delta
	score_tick += delta
	hit_flash   = max(0.0, hit_flash - delta * 4.0)
	_handle_movement(delta)
	_handle_invincibility(delta)
	position.y = clamp(position.y, SCREEN_TOP, SCREEN_BOT)
	move_and_slide()
	GameManager.advance_distance(delta)
	if score_tick >= 0.4:
		score_tick = 0.0
		GameManager.add_score(1)
	queue_redraw()

func _handle_movement(delta: float) -> void:
	var dir: float = 0.0
	if Input.is_action_pressed("move_up"):   dir = -1.0
	elif Input.is_action_pressed("move_down"): dir =  1.0
	if dir != 0.0 and stamina > 2.0:
		velocity.y += dir * ACCEL * delta
		stamina = max(0.0, stamina - STAMINA_DRAIN * delta)
	else:
		stamina = min(100.0, stamina + STAMINA_REGEN * delta)
	velocity.y = lerp(velocity.y, 0.0, FRICTION * delta)
	velocity.y = clamp(velocity.y, -MAX_Y_SPD, MAX_Y_SPD)
	velocity.x = 0.0

func _handle_invincibility(delta: float) -> void:
	if not invincible: return
	inv_timer -= delta
	modulate.a = 0.25 if (int(inv_timer * 8) % 2 == 0) else 1.0
	if inv_timer <= 0.0:
		invincible = false
		modulate.a = 1.0

func take_hit() -> void:
	if invincible: return
	invincible = true
	inv_timer  = INV_DURATION
	hit_flash  = 1.0
	GameManager.take_damage()

func restore_stamina(amount: float) -> void:
	stamina = min(100.0, stamina + amount)

func get_stamina() -> float:
	return stamina

func _draw() -> void:
	var w:  float = 68.0
	var h:  float = 42.0
	var ox: float = -w * 0.5
	var oy: float = -h * 0.5
	var t:  float = anim_time

	# ── Water wake / splash ───────────────────────────────────
	for i in 3:
		var wa: float = 0.12 - float(i)*0.035
		var wr: float = float(i+1)*7.0
		_ellipse(Vector2(ox - float(i)*4.0, 0.0), Vector2(wr*0.5, wr*0.22), Color(1,1,1,wa), 10)
		_ellipse(Vector2(w*0.5 + float(i)*3.0, 0.0), Vector2(wr*0.4, wr*0.18), Color(1,1,1,wa*0.7), 10)

	# ── Shadow on water ───────────────────────────────────────
	_ellipse(Vector2(2.0, h*0.5+5.0), Vector2(w*0.5, 7.0), Color(0,0,0,0.28))

	# ── RAFT — 3 individual log planks ───────────────────────
	var plank_h: float = h / 3.0
	var plank_cols := [
		[Color(0.38,0.23,0.11), Color(0.50,0.32,0.15), Color(0.28,0.17,0.08)],
		[Color(0.42,0.26,0.12), Color(0.54,0.34,0.16), Color(0.32,0.20,0.09)],
		[Color(0.34,0.21,0.10), Color(0.46,0.29,0.14), Color(0.26,0.15,0.07)],
	]
	for pi in 3:
		var py: float = oy + float(pi) * plank_h
		# Base colour
		draw_rect(Rect2(ox, py, w, plank_h - 1.0), plank_cols[pi][0])
		# Top highlight strip
		draw_rect(Rect2(ox, py, w, plank_h * 0.32), plank_cols[pi][1])
		# Bottom shadow strip
		draw_rect(Rect2(ox, py + plank_h*0.72, w, plank_h * 0.28), plank_cols[pi][2])
		# Grain lines
		for gi in 3:
			var gx1: float = ox + float(gi+1) * w*0.22
			var gy1: float = py + plank_h*0.3 + sin(float(gi)*2.1)*1.5
			draw_line(Vector2(gx1, gy1), Vector2(gx1 + w*0.18, gy1+1.0),
					  Color(0.22,0.13,0.06,0.40), 1.0)
		# End grain rings (right side)
		_draw_plank_end(Vector2(ox+w, py+plank_h*0.5), plank_h*0.48)

	# ── ROPE BINDINGS — twisted look ─────────────────────────
	_draw_rope(Vector2(ox+10.0, oy-2.0), Vector2(ox+10.0, oy+h+2.0))
	_draw_rope(Vector2(ox+w-16.0, oy-2.0), Vector2(ox+w-16.0, oy+h+2.0))

	# ── MAST ──────────────────────────────────────────────────
	var mx: float = ox + w * 0.54
	# Mast shadow
	draw_rect(Rect2(mx+2.0, oy-26.0, 4.0, h*0.5+26.0), Color(0,0,0,0.22))
	# Mast pole
	var mast_col: Color = Color(0.30, 0.18, 0.08)
	draw_rect(Rect2(mx-2.0, oy-26.0, 4.0, h*0.5+26.0), mast_col)
	# Mast highlight
	draw_rect(Rect2(mx-2.0, oy-26.0, 1.5, h*0.5+26.0), Color(0.5,0.32,0.16,0.5))

	# ── SAIL — billowing with light/shadow ────────────────────
	var bil: float = sin(t * 2.8) * 7.0 + 4.0  # always billowing outward
	var sail_pts := PackedVector2Array([
		Vector2(mx,          oy - 22.0),
		Vector2(mx + 32.0 + bil, oy),
		Vector2(mx + 28.0 + bil, oy + h*0.28),
		Vector2(mx,          oy + h*0.52),
		Vector2(mx - 8.0,    oy + h*0.42),
	])
	# Sail shadow side
	draw_colored_polygon(sail_pts, Color(0.88, 0.84, 0.74, 0.92))
	# Sail light side (top triangle)
	var sail_light := PackedVector2Array([
		sail_pts[0], sail_pts[1], sail_pts[4]
	])
	draw_colored_polygon(sail_light, Color(1.0, 0.97, 0.88, 0.7))
	# Sail seam line
	draw_line(sail_pts[0], Vector2(mx + 16.0+bil*0.5, oy+h*0.25),
			  Color(0.70, 0.66, 0.58, 0.5), 1.0)
	# Sail outline
	draw_polyline(PackedVector2Array([sail_pts[0],sail_pts[1],sail_pts[2],sail_pts[3],sail_pts[4],sail_pts[0]]),
				  Color(0.60,0.56,0.48,0.6), 1.0, true)

	# ── KOFI CHARACTER ────────────────────────────────────────
	var kx: float = ox + 15.0
	var ky: float = oy + h*0.5 - 8.0
	var bob: float = sin(t * 2.0) * 1.2
	# Body shadow
	draw_circle(Vector2(kx+1.0, ky+1.0+bob), 7.0, Color(0,0,0,0.2))
	# Torso
	draw_rect(Rect2(kx-5.5, ky+bob, 11.0, 12.0), Color(0.08,0.38,0.70))  # blue shirt
	draw_rect(Rect2(kx-5.5, ky+bob, 11.0,  4.0), Color(0.10,0.48,0.85))  # shirt highlight
	# Legs
	draw_rect(Rect2(kx-4.0, ky+12.0+bob, 4.5, 7.0), Color(0.22,0.14,0.06))
	draw_rect(Rect2(kx+0.5, ky+12.0+bob, 4.0, 7.0), Color(0.18,0.11,0.05))
	# Head
	draw_circle(Vector2(kx, ky-7.0+bob), 7.5, Color(0.48,0.31,0.18))
	# Face highlight
	draw_circle(Vector2(kx-1.0, ky-8.5+bob), 2.5, Color(0.55,0.37,0.22,0.5))
	# Hat brim
	draw_rect(Rect2(kx-10.0, ky-15.5+bob, 20.0, 5.0), Color(0.72,0.44,0.05))
	# Hat crown
	draw_rect(Rect2(kx-6.0, ky-22.0+bob, 12.0, 8.0), Color(0.82,0.52,0.06))
	draw_rect(Rect2(kx-6.0, ky-22.0+bob, 12.0, 2.5), Color(0.92,0.64,0.10))  # highlight

	# ── PADDLE — animated ─────────────────────────────────────
	var paddle_angle: float = sin(t * 4.5) * 0.50 - 0.25
	var p_origin := Vector2(kx - 4.0, ky + 7.0 + bob)
	var p_tip    := p_origin + Vector2(cos(paddle_angle)*32.0, sin(paddle_angle)*32.0)
	# Handle
	draw_line(p_origin, p_tip, Color(0.34,0.20,0.09), 3.0)
	draw_line(p_origin, p_tip, Color(0.48,0.30,0.14), 1.5)
	# Blade
	_ellipse(p_tip, Vector2(7.0, 5.0), Color(0.28, 0.17, 0.08))
	_ellipse(p_tip, Vector2(5.5, 3.5), Color(0.40, 0.25, 0.12))

func _draw_plank_end(center: Vector2, hh: float) -> void:
	_ellipse(center, Vector2(4.5, hh), Color(0.18,0.10,0.05), 12)
	for r in 3:
		var rr: float = hh * 0.78 - float(r) * hh * 0.22
		_ellipse(center, Vector2(3.5, rr), Color(0.44,0.28,0.13).lerp(Color(0.26,0.16,0.08),float(r)/2.0), 10)
	_ellipse(center, Vector2(2.0, hh*0.22), Color(0.20,0.12,0.06), 8)

func _draw_rope(from: Vector2, to: Vector2) -> void:
	var segs: int = 8
	for i in segs:
		var t1: float = float(i) / float(segs)
		var t2: float = float(i+1) / float(segs)
		var p1 := from.lerp(to, t1)
		var p2 := from.lerp(to, t2)
		# Alternate twist colour
		var rc: Color = Color(0.55,0.44,0.28) if i % 2 == 0 else Color(0.40,0.30,0.18)
		draw_line(p1, p2, rc, 3.5)
	# Rope highlight
	for i in segs:
		var t1: float = float(i) / float(segs)
		var t2: float = float(i+1) / float(segs)
		if i % 2 == 0:
			draw_line(from.lerp(to,t1), from.lerp(to,t2), Color(0.70,0.58,0.38,0.45), 1.5)

func _ellipse(center: Vector2, radii: Vector2, color: Color, segs: int = 24) -> void:
	var pts := PackedVector2Array()
	for i in segs:
		var a: float = float(i)/float(segs)*TAU
		pts.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(pts, color)
