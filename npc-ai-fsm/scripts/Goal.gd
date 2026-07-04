extends Area2D
## Goal.gd - kotak tujuan akhir, cuma bisa "dibuka" kalau pemain sudah pegang kunci.

func _ready() -> void:
	add_to_group("goal")
