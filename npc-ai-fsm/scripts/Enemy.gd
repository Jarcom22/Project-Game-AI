extends CharacterBody2D
## Enemy.gd
##
## AI musuh di labirin, pakai Finite State Machine dengan 3 state:
##   PATROL -> mondar-mandir di rute koridor yang sudah ditentukan.
##   CHASE  -> ngejar pemain, dipicu kalau pemain masuk detection_radius
##             DAN benar-benar "kelihatan" (dicek pakai raycast ke tembok,
##             bukan cuma jarak lurus, soalnya ini labirin banyak tembok).
##   RETURN -> balik ke titik patroli terakhir kalau pemain kabur/ilang
##             dari pandangan, baru lanjut PATROL lagi.

enum State { PATROL, CHASE, RETURN }

@export var speed: float = 95.0
@export var chase_speed: float = 135.0
@export var detection_radius: float = 260.0
@export var give_up_radius: float = 340.0
@export var patrol_points: Array = []

var current_state: State = State.PATROL
var patrol_index: int = 0
var patrol_dir: int = 1
var player: Node2D = null

@onready var touch_zone: Area2D = $TouchZone
@onready var state_label: Label = $StateLabel


func _ready() -> void:
	add_to_group("enemy")
	touch_zone.add_to_group("enemy_touch")
	player = get_tree().get_first_node_in_group("player")
	_update_label()


func _physics_process(_delta: float) -> void:
	match current_state:
		State.PATROL:
			_do_patrol()
		State.CHASE:
			_do_chase()
		State.RETURN:
			_do_return()

	move_and_slide()
	_evaluate_transitions()
	_update_label()


func _do_patrol() -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return
	var target: Vector2 = patrol_points[patrol_index]
	var to_target: Vector2 = target - global_position
	if to_target.length() < 6.0:
		_advance_patrol_index()
	else:
		velocity = to_target.normalized() * speed


func _do_chase() -> void:
	if player == null:
		velocity = Vector2.ZERO
		return
	velocity = (player.global_position - global_position).normalized() * chase_speed


func _do_return() -> void:
	if patrol_points.is_empty():
		current_state = State.PATROL
		return
	var target: Vector2 = patrol_points[patrol_index]
	var to_target: Vector2 = target - global_position
	if to_target.length() < 6.0:
		current_state = State.PATROL
	else:
		velocity = to_target.normalized() * speed


func _advance_patrol_index() -> void:
	if patrol_points.size() <= 1:
		return
	patrol_index += patrol_dir
	if patrol_index >= patrol_points.size():
		patrol_index = patrol_points.size() - 2
		patrol_dir = -1
	elif patrol_index < 0:
		patrol_index = 1
		patrol_dir = 1


func _evaluate_transitions() -> void:
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)

	match current_state:
		State.PATROL:
			if dist <= detection_radius and _has_line_of_sight(player.global_position):
				current_state = State.CHASE
		State.CHASE:
			if dist > give_up_radius or not _has_line_of_sight(player.global_position):
				current_state = State.RETURN
		State.RETURN:
			pass # transisi balik ke PATROL sudah ditangani di _do_return()


func _has_line_of_sight(target_pos: Vector2) -> bool:
	# Tembak garis lurus ke posisi pemain, kalau kena tembok duluan
	# (layer 1) berarti belum "kelihatan" beneran meski jaraknya dekat.
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, target_pos, 1, [get_rid()])
	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _update_label() -> void:
	if state_label == null:
		return
	var names := {State.PATROL: "PATROL", State.CHASE: "CHASE", State.RETURN: "RETURN"}
	var colors := {
		State.PATROL: Color(0.3, 0.85, 0.3),
		State.CHASE: Color(0.95, 0.2, 0.2),
		State.RETURN: Color(0.4, 0.65, 1.0),
	}
	state_label.text = names[current_state]
	state_label.modulate = colors[current_state]
