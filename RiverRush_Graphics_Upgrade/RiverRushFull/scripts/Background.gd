# Background.gd — Enhanced realistic water graphics
extends Node2D

const W: float = 720.0
const H: float = 460.0

var water_offset: float = 0.0
var tick:         float = 0.0
var lightning_timer: float = 0.0
var lightning_flash: float = 0.0

func _get_colors() -> Array:
	match clamp(GameManager.level, 0, 2):
		0: return [Color(0.025, 0.155, 0.265), Color(0.055, 0.305, 0.490), Color(0.04, 0.22, 0.38)]
		1: return [Color(0.015, 0.095, 0.175), Color(0.035, 0.200, 0.360), Color(0.025, 0.14, 0.26)]
		2: return [Color(0.006, 0.030, 0.065), Color(0.015, 0.075, 0.145), Color(0.01, 0.05, 0.10)]
	return [Color(0.025, 0.155, 0.265), Color(0.055, 0.305, 0.490), Color(0.04, 0.22, 0.38)]

func _process(delta: float) -> void:
	if GameManager.is_playing():
		var spd: float = GameManager.get_config().scroll_speed
		water_offset = fmod(water_offset + spd * delta * 0.38, 200.0)
	tick += delta
	# Storm lightning flicker
	if GameManager.level == 2:
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			lightning_flash = randf_range(0.05, 0.18)
			lightning_timer = randf_range(2.5, 7.0)
		lightning_flash = max(0.0, lightning_flash - delta * 3.0)
	queue_redraw()

func _draw() -> void:
	var lvl:  int   = GameManager.level
	var cols: Array = _get_colors()
	var top:  Color = cols[0]
	var bot:  Color = cols[1]
	var mid:  Color = cols[2]

	# ── Base gradient (16 bands for smooth look) ─────────────
	for row in 16:
		var t:   float = float(row) / 15.0
		var col: Color = top.lerp(bot, ease(t, 0.7))
		draw_rect(Rect2(0.0, row * H / 16.0, W, H / 16.0 + 1.0), col)

	# ── Subtle depth ripple patches ───────────────────────────
	for i in 8:
		var px: float = fmod(float(i) * 137.0 + water_offset * 0.2, W + 80.0) - 40.0
		var py: float = 40.0 + fmod(float(i) * 89.3 + tick * 12.0, H - 80.0)
		var pr: float = 55.0 + float(i) * 9.0
		_ellipse(Vector2(px, py), Vector2(pr, pr * 0.38),
				 Color(bot.r, bot.g, bot.b + 0.04, 0.08 + sin(tick * 0.4 + float(i)) * 0.03))

	# ── WAVE LAYER 1: Large background swells ─────────────────
	var off1: float = fmod(water_offset * 0.30, 180.0)
	for row_i in range(0, int(H), 50):
		var y:   float = float(row_i)
		var rstg: float = float(row_i) * 31.7
		for xi in range(-80, int(W) + 80, 75):
			var cx: float = float(xi) - fmod(off1 + rstg * 0.28, 75.0)
			var cy: float = y + sin(tick * 0.35 + float(row_i) * 0.55) * 5.0
			var sz: float = 28.0 + sin(float(row_i)*1.3 + float(xi)*0.05) * 7.0
			var al: float = 0.08 + abs(sin(float(row_i)*0.7 + float(xi)*0.03)) * 0.04
			var wc: Color = mid.lerp(Color(0.75, 0.88, 1.0), 0.3)
			_draw_crescent(Vector2(cx, cy), sz, Color(wc.r, wc.g, wc.b, al), 2.2)

	# ── WAVE LAYER 2: Mid surface waves ───────────────────────
	var off2: float = fmod(water_offset * 0.62, 130.0)
	for row_i in range(16, int(H) - 16, 36):
		var y:    float = float(row_i)
		var rstg: float = float(row_i) * 43.9
		for xi in range(-60, int(W) + 60, 58):
			var cx: float = float(xi) - fmod(off2 + rstg * 0.35, 58.0)
			var cy: float = y + sin(tick * 0.72 + float(row_i)*0.42 + float(xi)*0.018) * 3.5
			var sz: float = 17.0 + sin(float(row_i)*2.1 + float(xi)*0.07) * 4.5
			var al: float = 0.17 + abs(sin(float(row_i)*1.4 + float(xi)*0.05)) * 0.07
			_draw_crescent(Vector2(cx, cy), sz, Color(1.0, 1.0, 1.0, al), 1.8)
			# Foam inner highlight
			_draw_crescent(Vector2(cx, cy - 1.8), sz * 0.62, Color(0.92, 0.97, 1.0, al * 0.38), 1.0)

	# ── WAVE LAYER 3: Bright foam crests (fastest) ────────────
	var off3: float = fmod(water_offset * 1.05, 95.0)
	for row_i in range(24, int(H) - 24, 26):
		var y:    float = float(row_i)
		var rstg: float = float(row_i) * 57.3
		for xi in range(-40, int(W) + 40, 44):
			var cx: float = float(xi) - fmod(off3 + rstg * 0.42, 44.0)
			var cy: float = y + sin(tick * 1.2 + float(row_i)*0.33) * 2.0
			var sz: float = 10.0 + sin(float(row_i)*3.3 + float(xi)*0.12) * 3.0
			var al: float = 0.24 + abs(sin(float(row_i)*2.2 + float(xi)*0.09)) * 0.09
			_draw_crescent(Vector2(cx, cy), sz, Color(1.0, 1.0, 1.0, al), 1.6)

	# ── SPECULAR HIGHLIGHTS ───────────────────────────────────
	_draw_specular()

	# ── Level-specific effects ────────────────────────────────
	if lvl == 1: _draw_rapids()
	if lvl == 2:
		draw_rect(Rect2(0,0,W,H), Color(0.004,0.012,0.035, 0.48))
		_draw_rain()
		if lightning_flash > 0.0:
			draw_rect(Rect2(0,0,W,H), Color(0.8, 0.85, 1.0, lightning_flash))

	_draw_banks()

# ── CRESCENT WAVE SHAPE ───────────────────────────────────────
# Flattened arc open on the right side (downstream face of wave)
func _draw_crescent(center: Vector2, radius: float, color: Color, width: float = 2.0) -> void:
	var pts := PackedVector2Array()
	var segs: int  = 14
	var span: float = PI * 1.28   # ~230 degree arc (leaves gap on right)
	var start: float = -span * 0.5
	for i in segs + 1:
		var t: float = float(i) / float(segs)
		var a: float = start + span * t
		# x uses full radius; y is flattened to 0.34 — creates wave crest shape
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius * 0.34))
	draw_polyline(pts, color, width, true)

func _draw_specular() -> void:
	# Tiny bright dashes representing light glinting off water
	for i in 24:
		var sx: float = fmod(float(i)*97.3 + water_offset*0.9, W)
		var sy: float = fmod(float(i)*61.7 + tick*22.0, H - 30.0) + 15.0
		var sl: float = 5.0 + sin(float(i)*2.7)*3.0
		var sa: float = 0.25 + abs(sin(tick*1.8 + float(i)*0.9)) * 0.2
		draw_line(Vector2(sx, sy), Vector2(sx+sl, sy+1.0),
				  Color(1.0, 1.0, 1.0, sa), 1.2, true)

func _draw_rapids() -> void:
	# Churning white foam streaks
	for i in 22:
		var rx: float = fmod(tick*280.0 + float(i)*97.0, W+80.0) - 40.0
		var ry: float = 38.0 + fmod(float(i)*73.0, H-76.0)
		var ln: float = 22.0 + fmod(float(i)*37.0, 38.0)
		draw_line(Vector2(rx,ry), Vector2(rx+ln,ry+5.0), Color(1,1,1,0.32), 2.2)
	# Foam blobs
	for i in 16:
		var rx: float = fmod(tick*190.0+float(i)*113.0, W+60.0)-30.0
		var ry: float = 35.0+fmod(float(i)*61.0, H-70.0)
		_ellipse(Vector2(rx,ry), Vector2(14.0+fmod(float(i)*7.0,11.0), 5.0+fmod(float(i)*3.0,5.0)),
				 Color(1,1,1,0.22))
	# Submerged rocks
	for i in 6:
		var rx: float = fmod(tick*85.0+float(i)*183.0, W+110.0)-55.0
		var ry: float = 48.0+fmod(float(i)*93.0, H-96.0)
		var rw: float = 20.0+fmod(float(i)*11.0,16.0)
		var rh: float = 12.0+fmod(float(i)*7.0,9.0)
		_ellipse(Vector2(rx,ry), Vector2(rw,rh), Color(0.13,0.10,0.07,0.65))
		# Foam arc wrapping rock
		var arc_pts := PackedVector2Array()
		for s in 22:
			var a: float = PI*0.82 + float(s)/21.0 * PI*1.36
			arc_pts.append(Vector2(rx+cos(a)*(rw+9.0), ry+sin(a)*(rh+5.0)))
		for s in arc_pts.size()-1:
			draw_line(arc_pts[s], arc_pts[s+1], Color(1,1,1,0.34), 2.0)
	# Turbulent chop (extra dense wave layer)
	var off_r: float = fmod(water_offset*1.4, 80.0)
	for row_i in range(12, int(H)-12, 22):
		var y: float = float(row_i)
		for xi in range(-40, int(W)+40, 38):
			var cx: float = float(xi) - fmod(off_r+float(row_i)*19.0, 38.0)
			var cy: float = y + sin(tick*1.8+float(row_i)*0.6)*2.0
			var sz: float = 8.0 + sin(float(row_i)*4.1+float(xi)*0.15)*2.5
			_draw_crescent(Vector2(cx,cy), sz, Color(1,1,1,0.18), 1.4)

func _draw_rain() -> void:
	for i in 45:
		var rx: float = fmod(tick*110.0+float(i)*53.0, W)
		var ry: float = fmod(tick*220.0+float(i)*97.0, H)
		var ra: float = 0.20 + abs(sin(tick*3.0+float(i)))*0.12
		draw_line(Vector2(rx,ry), Vector2(rx-5.0,ry+16.0), Color(0.6,0.75,1.0,ra), 1.0)

func _draw_banks() -> void:
	# Top bank — gradient from grass into water
	for i in 7:
		var t: float = float(i)/6.0
		draw_rect(Rect2(0, float(i)*5.5, W, 6.0), Color(0.12,0.26,0.10, 1.0-t))
	# Top grass blades
	for i in 7:
		var t: float = float(i)/6.0
		draw_rect(Rect2(0, H-32.0+float(i)*5.5, W, 6.0), Color(0.12,0.26,0.10, t))
	var gx_off: float = fmod(water_offset*0.28, 62.0)
	for xi in range(-1, int(W/62.0)+2):
		var gx: float = float(xi)*62.0 + gx_off
		# Grass tufts top
		draw_rect(Rect2(gx,    0, 7, 10), Color(0.14,0.32,0.12))
		draw_rect(Rect2(gx+9,  0, 5,  7), Color(0.18,0.38,0.14))
		draw_rect(Rect2(gx+16, 0, 4,  9), Color(0.12,0.28,0.10))
		# Bottom
		draw_rect(Rect2(gx,    H-10, 7, 10), Color(0.14,0.32,0.12))
		draw_rect(Rect2(gx+9,  H- 7, 5,  7), Color(0.18,0.38,0.14))
		draw_rect(Rect2(gx+16, H- 9, 4,  9), Color(0.12,0.28,0.10))

func _ellipse(center: Vector2, radii: Vector2, color: Color, segs: int = 20) -> void:
	var pts := PackedVector2Array()
	for i in segs:
		var a: float = float(i)/float(segs)*TAU
		pts.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(pts, color)
