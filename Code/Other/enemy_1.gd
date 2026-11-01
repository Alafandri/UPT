extends CharacterBody2D

@onready var damage_area: Area2D = $DamageArea

func _physics_process(_delta: float) -> void:
	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hit()
			var knockback_direction = (body.global_position - global_position).normalized()
			body.apply_knockback(knockback_direction, 450.0, 0.12)
