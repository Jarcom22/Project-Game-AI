extends Node2D
## Main.gd
##
## Ngerakit semuanya jadi satu:
## 1. Generate labirin baru pakai MazeGenerator.
## 2. Gambar labirinnya (kotak hitam = jalan, sisanya tetap hijau = tembok)
##    plus collider tembok, semuanya dibikin lewat kode, bukan digambar manual.
## 3. Naruh Player, Key, Goal, dan Enemy di sel-sel yang masuk akal
##    (goal = sel paling jauh dari start, key = kira-kira di tengah jalan
##    menuju goal, enemy = patroli di dekat situ).
## 4. Nangani menang/kalah, lalu generate labirin baru lagi (reload scene).

@export var cols: int = 6
@export var rows: int = 6
@export var cell_size: float = 56.0
@export var margin: float = 40.0

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var key_scene: PackedScene
@export var goal_scene: PackedScene

var generator := MazeGenerator.new()

@onready var maze_layer: Node2D = $MazeLayer
@onready var status_label: Label = $UI/StatusLabel
@onready var key_label: Label = $UI/KeyLabel


func _ready() -> void:
	randomize()
	generator.generate(cols, rows)
	_build_visuals()
	_spawn_entities()
	status_label.text = "Cari kuncinya, lalu kabur ke kotak merah!"
	key_label.text = "Kunci: belum ada"


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x, cell.y) * cell_size + Vector2(cell_size, cell_size) * 0.5 + Vector2(margin, margin)


func _build_visuals() -> void:
	var w: float = generator.width * cell_size + margin * 2.0
	var h: float = generator.height * cell_size + margin * 2.0

	var bg := Polygon2D.new()
	bg.color = Color(0.28, 0.85, 0.45)
	bg.polygon = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
	maze_layer.add_child(bg)

	_add_border_ticks(w, h)

	var half: float = cell_size / 2.0
	for y in range(generator.height):
		for x in range(generator.width):
			var world_pos: Vector2 = cell_to_world(Vector2i(x, y))
			if generator.is_open(x, y):
				var tile := Polygon2D.new()
				tile.color = Color(0, 0, 0)
				tile.polygon = PackedVector2Array([
					Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
				])
				tile.position = world_pos
				maze_layer.add_child(tile)
			else:
				var body := StaticBody2D.new()
				body.position = world_pos
				body.collision_layer = 1
				body.collision_mask = 0
				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(cell_size, cell_size)
				shape.shape = rect
				body.add_child(shape)
				maze_layer.add_child(body)


func _add_border_ticks(w: float, h: float) -> void:
	# Hiasan segitiga kecil di sepanjang tepi, cuma kosmetik biar mirip
	# gaya gambar acuan, tidak mempengaruhi gameplay sama sekali.
	var spacing := 28.0
	var size := 8.0
	var x := spacing / 2.0
	while x < w:
		_add_tick(Vector2(x, size * 0.5), true)
		_add_tick(Vector2(x, h - size * 0.5), false)
		x += spacing
	var y := spacing / 2.0
	while y < h:
		_add_tick(Vector2(size * 0.5, y), true, true)
		_add_tick(Vector2(w - size * 0.5, y), false, true)
		y += spacing


func _add_tick(pos: Vector2, pointing_positive: bool, vertical_edge: bool = false) -> void:
	var tri := Polygon2D.new()
	tri.color = Color(0, 0, 0)
	var s := 6.0
	if not vertical_edge:
		if pointing_positive:
			tri.polygon = PackedVector2Array([Vector2(-s, s), Vector2(s, s), Vector2(0, -s)])
		else:
			tri.polygon = PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(0, s)])
	else:
		if pointing_positive:
			tri.polygon = PackedVector2Array([Vector2(s, -s), Vector2(s, s), Vector2(-s, 0)])
		else:
			tri.polygon = PackedVector2Array([Vector2(-s, -s), Vector2(-s, s), Vector2(s, 0)])
	tri.position = pos
	maze_layer.add_child(tri)


func _spawn_entities() -> void:
	var start_cell := Vector2i(1, 1)
	var goal_cell: Vector2i = generator.farthest_cell(start_cell)
	var key_cell: Vector2i = generator.cell_at_ratio(start_cell, 0.5)
	if key_cell == goal_cell:
		key_cell = generator.cell_at_ratio(start_cell, 0.35)

	var enemy_start_cell: Vector2i = generator.cell_at_ratio(start_cell, 0.6)
	var patrol_cells: Array = generator.random_walk(enemy_start_cell, 5)

	var player := player_scene.instantiate()
	add_child(player)
	player.global_position = cell_to_world(start_cell)
	player.key_collected.connect(_on_key_collected)
	player.reached_goal.connect(_on_reached_goal)
	player.caught.connect(_on_caught)

	var key_node := key_scene.instantiate()
	add_child(key_node)
	key_node.global_position = cell_to_world(key_cell)

	var goal_node := goal_scene.instantiate()
	add_child(goal_node)
	goal_node.global_position = cell_to_world(goal_cell)

	var enemy := enemy_scene.instantiate()
	var patrol_world: Array = []
	for c in patrol_cells:
		patrol_world.append(cell_to_world(c))
	enemy.patrol_points = patrol_world
	add_child(enemy)
	enemy.global_position = cell_to_world(enemy_start_cell)


func _on_key_collected() -> void:
	key_label.text = "Kunci: sudah dapat!"
	status_label.text = "Bagus, sekarang kabur ke kotak merah!"


func _on_reached_goal() -> void:
	status_label.text = "Kamu menang! Labirin baru sedang disiapkan..."
	_schedule_restart()


func _on_caught() -> void:
	status_label.text = "Ketangkap musuh! Labirin baru sedang disiapkan..."
	_schedule_restart()


func _schedule_restart() -> void:
	await get_tree().create_timer(1.6).timeout
	get_tree().reload_current_scene()
