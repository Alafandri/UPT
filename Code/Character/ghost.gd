extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const GRAVITY := 1100
const FALL_GRAVITY := 1700

#Coyote time
@onready var CoyoteTimer: Timer = $CoyoteTimer
var CoyoteTimeActivated: bool = false
var was_on_floor := false

func get_current_gravity():
	if velocity.y < 0:
		return GRAVITY
	return FALL_GRAVITY

#func jump():
	#$JumpSplash.visible = true
	#$JumpWoosh.visible = true
	#$JumpSplash.global_position = $GhostSprite2D.global_position + Vector2(0, 16)
	#$JumpWoosh.global_position = $GhostSprite2D.global_position + Vector2(0, -5)
	#$JumpSplash.play("default")
	#$JumpWoosh.play("default")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += get_current_gravity() * delta

	# Sprite direction
	if Input.is_action_pressed("Right"):
		$GhostSprite2D.flip_h = false
	elif Input.is_action_pressed("Left"):
		$GhostSprite2D.flip_h = true

	# jump
	if Input.is_action_just_pressed("Jump"):
		$JumpBufferTime.start()
		
	if (was_on_floor or not CoyoteTimer.is_stopped()) and not $JumpBufferTime.is_stopped():
		velocity.y = JUMP_VELOCITY
		$JumpBufferTime.stop()
		CoyoteTimer.stop()
		
		$GhostSprite2D.play("Jump")
		$JumpTrailParticles.restart()
		$JumpPoofParticles.restart()
	
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y = JUMP_VELOCITY / 4

	# Move
	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	
	if not was_on_floor and is_on_floor():
		$ImpactParticles.restart()

	# Animations
	if not is_on_floor():
		$MoveParticles.emitting = false
		
		if velocity.y < 0:
			if $GhostSprite2D.animation != "Jump":
				$GhostSprite2D.play("Jump")
				$JumpTrailParticles.restart()
				$JumpPoofParticles.restart()
				
			if Input.is_action_pressed("Jump") and $GhostSprite2D.frame >= 1:
				$GhostSprite2D.frame = 1
				$GhostSprite2D.pause()
				$JumpTrailParticles.emitting = false
				$JumpPoofParticles.emitting = false
				
			if Input.is_action_just_released("Jump"):
				$GhostSprite2D.frame = 1
				$GhostSprite2D.play("Jump")
		else:
			if $GhostSprite2D.animation != "Jump":
				$GhostSprite2D.play("Jump")
			$GhostSprite2D.frame = 2
			$GhostSprite2D.pause()
			$JumpTrailParticles.emitting = false
			$JumpPoofParticles.emitting = false
	elif direction:
		$GhostSprite2D.play("Move")
		if is_on_floor():
			$MoveParticles.emitting = true
			$JumpTrailParticles.emitting = false
			$JumpPoofParticles.emitting = false
	else:
		$GhostSprite2D.play("Idle")
		$MoveParticles.emitting = false
		$JumpTrailParticles.emitting = false
		$JumpPoofParticles.emitting = false

	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		CoyoteTimer.start()
	
	was_on_floor = is_on_floor()
