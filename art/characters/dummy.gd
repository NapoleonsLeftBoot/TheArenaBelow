extends CharacterBody2D

var health: int = 100

func take_hit(move: MoveData, facing: int) -> void:
	if health <= 0:
		print("dummy KO, resetting")
		health = 100
	health -= move.damage
	velocity = Vector2(move.knockback.x * facing, move.knockback.y)
	print("hit! health = ", health)

func _physics_process(delta: float) -> void:
	velocity.y += 980.0 * delta
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	move_and_slide()
