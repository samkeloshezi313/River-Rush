# Crocodile.gd — Menacing redesign
extends CharacterBody2D

var move_speed:  float = 200.0
var aggression:  float = 0.003
var phase:       float = 0.0
var anim_time:   float = 0.0
var lunge:       float = 0.0
var player_ref:  Node2D = null

const SCREEN_TOP: float = 44.0
const SCREEN_BOT: float = 416.0
const CW: float = 96.0   # wider
const CH: float = 38.0   # taller

func _ready() -> void:
	phase = randf() * TAU
	add_to_group("obstacles")
	await get_tree().process_frame
	var found := get_tree().get_nodes_in_group("player")
	if found.size() > 0:
		player_ref = found[0]

func setup(spd: float, agg: float) -> void:
	move_speed = spd * randf_range(0.70, 1.10)
	aggression = agg

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	anim_time += delta
	lunge = sin(anim_time * 2.4 + phase) * 6.0
	velocity.x = -move_speed
	if player_ref and is_instance_valid(player_ref):
		var dy: float = player_ref.position.y - position.y
		velocity.y += dy * aggression * move_speed * delta * 60.0
	velocity.y = clamp(velocity.y, -170.0, 170.0)
	if position.y <= SCREEN_TOP or position.y >= SCREEN_BOT:
		velocity.y *= -0.8
	position.y = clamp(position.y, SCREEN_TOP, SCREEN_BOT)
	move_and_slide()
	for i in get_slide_collision_count():
		var col  := get_slide_collision(i)
		var body := col.get_collider()
		if body != null and body.is_in_group("player"):
			body.take_hit()
	queue_redraw()
	if position.x < -140.0:
		position.x = get_viewport_rect().size.x + 60.0 + randf_range(0, 240)
		position.y = randf_range(60, 400)

func _draw() -> void:
	var w:  float = CW
	var h:  float = CH
	var hw: float = w * 0.5
	var hh: float = h * 0.5

	# Flip: snout faces LEFT (toward player)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))

	# ── Drop shadow ───────────────────────────────────────────
	_ellipse(Vector2(3.0, hh + 10.0), Vector2(hw * 0.92, hh * 0.38), Color(0,0,0,0.30))

	# ── TAIL — tapered, segmented, slightly curved ─────────────
	var sw: float = sin(anim_time * 2.8 + phase) * 12.0
	var tail_pts := PackedVector2Array([
		Vector2(-hw + 18.0,  hh * 0.2),
		Vector2(-hw - 8.0,   sw * 0.5),
		Vector2(-hw - 28.0,  sw),
		Vector2(-hw - 42.0,  sw * 0.7),
		Vector2(-hw - 52.0,  sw * 0.3),
		Vector2(-hw - 48.0, -sw * 0.1),
		Vector2(-hw + 18.0,  hh * 0.8),
	])
	draw_colored_polygon(tail_pts, Color(0.075, 0.20, 0.07))
	# Tail ridge
	draw_polyline(PackedVector2Array([
		Vector2(-hw+14.0, hh*0.48),
		Vector2(-hw-10.0, sw*0.3),
		Vector2(-hw-32.0, sw*0.55),
		Vector2(-hw-44.0, sw*0.35),
	]), Color(0.04, 0.12, 0.04, 0.7), 1.5, true)

	# ── MAIN BODY — dark armored oval ─────────────────────────
	var body_col: Color = Color(0.09, 0.22, 0.08)
	_ellipse(Vector2(-hw*0.06, 0.0), Vector2(hw*0.72, hh*0.92), body_col)

	# ── BELLY — lighter center strip ──────────────────────────
	_ellipse(Vector2(-hw*0.10, 0.0), Vector2(hw*0.38, hh*0.58), Color(0.28, 0.42, 0.18, 0.55))

	# ── SCALE TEXTURE — rows of raised plates ─────────────────
	var scale_col: Color = Color(0.06, 0.17, 0.06, 0.80)
	var highlight_col: Color = Color(0.16, 0.34, 0.12, 0.50)
	for row in 5:
		var ry: float = -hh * 0.75 + float(row) * (h * 0.32)
		var row_w: float = hw * 0.60 - abs(ry) * 0.45
		var scale_size: float = 5.5 + float(row) * 0.4
		var col_count: int = int(row_w * 2.0 / (scale_size * 2.2))
		for sc in col_count:
			var sx: float = -row_w + float(sc) * scale_size * 2.2 + (scale_size if row % 2 == 1 else 0.0)
			# Scale plate (hexagonal-ish)
			_ellipse(Vector2(sx, ry), Vector2(scale_size, scale_size * 0.65), scale_col, 6)
			# Highlight top edge
			_ellipse(Vector2(sx - 0.5, ry - 0.5), Vector2(scale_size * 0.55, scale_size * 0.28), highlight_col, 6)

	# ── SPINE RIDGE — plates along centre back ────────────────
	for i in 8:
		var rx: float = -hw * 0.55 + float(i) * hw * 0.14
		var ridge := PackedVector2Array([
			Vector2(rx - 3.0, -1.0),
			Vector2(rx,       -hh * 0.88),
			Vector2(rx + 3.0, -1.0),
		])
		draw_colored_polygon(ridge, Color(0.05, 0.15, 0.04))
		draw_colored_polygon(PackedVector2Array([
			Vector2(rx - 1.0, -1.0), Vector2(rx, -hh*0.6), Vector2(rx+1.0, -1.0)
		]), Color(0.18, 0.38, 0.12, 0.4))

	# ── HEAD — wide flat triangular ───────────────────────────
	var hd_x: float = hw * 0.34 + lunge  # head starts here
	var head_pts := PackedVector2Array([
		Vector2(hd_x,           -hh * 0.82),
		Vector2(hw * 0.94 + lunge, -hh * 0.28),
		Vector2(hw * 1.02 + lunge, hh * 0.12),  # snout tip
		Vector2(hw * 0.94 + lunge,  hh * 0.38),
		Vector2(hd_x,            hh * 0.82),
	])
	draw_colored_polygon(head_pts, Color(0.10, 0.24, 0.09))
	# Head scales
	_ellipse(Vector2(hw*0.62+lunge*0.7, -hh*0.25), Vector2(8.0,5.5), Color(0.07,0.18,0.06,0.8), 6)
	_ellipse(Vector2(hw*0.62+lunge*0.7,  hh*0.25), Vector2(8.0,5.5), Color(0.07,0.18,0.06,0.8), 6)
	_ellipse(Vector2(hw*0.78+lunge*0.9,  0.0),     Vector2(6.0,4.5), Color(0.07,0.18,0.06,0.8), 6)

	# ── UPPER JAW TEETH — visible from above ──────────────────
	# Upper row (top of snout)
	for t in 5:
		var tx: float = hd_x + 8.0 + float(t) * (hw*0.52 + lunge*0.8) / 4.5
		var tooth_h: float = 4.5 if t % 2 == 0 else 3.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - 1.8, -hh*0.72),
			Vector2(tx,       -hh*0.72 - tooth_h),
			Vector2(tx + 1.8, -hh*0.72)
		]), Color(0.92, 0.90, 0.84))
	# Lower row (bottom of snout)
	for t in 4:
		var tx: float = hd_x + 12.0 + float(t) * (hw*0.46 + lunge*0.7) / 3.5
		var tooth_h: float = 4.0 if t % 2 == 0 else 2.8
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - 1.8,  hh*0.72),
			Vector2(tx,        hh*0.72 + tooth_h),
			Vector2(tx + 1.8,  hh*0.72)
		]), Color(0.88, 0.86, 0.80))

	# ── JAW SEAM LINE ─────────────────────────────────────────
	draw_line(Vector2(hd_x + 4.0,  0.0), Vector2(hw*0.96 + lunge, 0.0),
			  Color(0.04, 0.11, 0.04, 0.9), 1.2)

	# ── NOSTRILS ──────────────────────────────────────────────
	draw_circle(Vector2(hw*0.88 + lunge, -hh*0.22), 2.2, Color(0.03, 0.08, 0.03))
	draw_circle(Vector2(hw*0.88 + lunge,  hh*0.22), 2.2, Color(0.03, 0.08, 0.03))
	draw_circle(Vector2(hw*0.88 + lunge, -hh*0.22), 1.0, Color(0.01, 0.04, 0.01))
	draw_circle(Vector2(hw*0.88 + lunge,  hh*0.22), 1.0, Color(0.01, 0.04, 0.01))

	# ── EYES — menacing raised bumps with slit pupils ─────────
	var ex: float = hw * 0.56 + lunge * 0.6
	var ey_top: float = -hh * 0.72
	var ey_bot: float =  hh * 0.72
	for ey in [ey_top, ey_bot]:
		# Eye socket (dark)
		draw_circle(Vector2(ex, ey), 6.5, Color(0.04, 0.12, 0.04))
		# Iris (yellow-orange glow)
		draw_circle(Vector2(ex, ey), 5.2, Color(0.85, 0.62, 0.0))
		# Slit pupil (vertical)
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - 1.2, ey - 4.5),
			Vector2(ex + 1.2, ey - 4.5),
			Vector2(ex + 2.0, ey),
			Vector2(ex + 1.2, ey + 4.5),
			Vector2(ex - 1.2, ey + 4.5),
			Vector2(ex - 2.0, ey),
		]), Color(0.02, 0.02, 0.02))
		# Eye highlight
		draw_circle(Vector2(ex + 1.5, ey - 2.0), 1.2, Color(1.0, 0.95, 0.5, 0.7))
		# Eye rim (raised bump effect)
		_ellipse(Vector2(ex, ey), Vector2(6.5, 4.5), Color(0.12, 0.30, 0.10, 0.6), 12)

	# Reset mirror transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0))

func _ellipse(center: Vector2, radii: Vector2, color: Color, segs: int = 24) -> void:
	var pts := PackedVector2Array()
	for i in segs:
		var a: float = float(i) / float(segs) * TAU
		pts.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(pts, color)
