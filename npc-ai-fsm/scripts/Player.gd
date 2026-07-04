extends CharacterBody2D
## Player.gd
## Gerak bebas 4 arah di dalam labirin (panah kanan/kiri/atas/bawah).
## Tabrakan sama tembok ditangani otomatis lewat move_and_slide().
## Deteksi kunci, goal, dan sentuhan musuh ditangani lewat area
## PickupDetector di bawah.

@export var speed: float = 210.0

var has_key: bool = false
var alive: bool = true

signal key_collected
signal reached_goal
signal caught

@onready var detector: Area2D = $PickupDetector


func _ready() -> void:
	add_to_group("player")
	detector.area_entered.connect(_on_area_entered)


func _physics_process(_delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		return

	var dir := Vector2.ZERO
	dir.x = Input.get_axis("ui_left", "ui_right")
	dir.y = Input.get_axis("ui_up", "ui_down")
	velocity = dir.normalized() * speed
	move_and_slide()


func _on_area_entered(area: Area2D) -> void:
	if not alive:
		return

	if area.is_in_group("key"):
		has_key = true
		key_collected.emit()
		area.queue_free()
	elif area.is_in_group("goal"):
		if has_key:
			alive = false
			reached_goal.emit()
	elif area.is_in_group("enemy_touch"):
		alive = false
		caught.emit()
