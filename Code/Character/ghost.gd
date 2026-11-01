extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const GRAVITY := 1100
const FALL_GRAVITY := 1700

var is_live = true

var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

#Coyote time
@onready var CoyoteTimer: Timer = $CoyoteTimer
var CoyoteTimeActivated: bool = false
var was_on_floor := false

var is_dead: bool = false

func _ready() -> void:
	Engine.set_time_scale(1)
	$FadeCanvasLayer/Black.visible = true
	await get_tree().create_timer(.3).timeout
	$ScreenFade.active = true
	$ScreenFade.play("FadeOut")

func get_current_gravity():
	if velocity.y < 0:
		return GRAVITY
	return FALL_GRAVITY

# extra effects. might use in the future
#func jump():
	#$JumpSplash.visible = true
	#$JumpWoosh.visible = true
	#$JumpSplash.global_position = $GhostSprite2D.global_position + Vector2(0, 16)
	#$JumpWoosh.global_position = $GhostSprite2D.global_position + Vector2(0, -5)
	#$JumpSplash.play("default")
	#$JumpWoosh.play("default")

func hit() -> void:
	if $Invincible.is_stopped():
		$HpBar.hit(1)
		$Invincible.start()
		Engine.set_time_scale(0.1)
		await get_tree().create_timer(0.02).timeout
		Engine.set_time_scale(1)
		if is_dead:
			return
		else:
			$TakeDamageParticles.emitting = true
			$ScreenFade.play("flicker")

# heals player
func food_pickup():
	$HpBar.heal(2)

# plays death anim
func die() -> void:
	if is_dead:
		return
	$ScreenFade.stop()
	is_dead = true
	is_live = false

	$GhostSprite2D.stop()
	$GhostSprite2D.play("Death")

	await get_tree().create_timer(0.4).timeout
	$ScreenFade.active = true
	$ScreenFade.play("Fade")
	Engine.set_time_scale(1)
	await get_tree().create_timer(.9).timeout
	get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	#gravity
	if not is_on_floor():
		velocity.y += get_current_gravity() * delta

	# sprite direction
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
	
	#knockback
	if knockback_timer > 0.0:
		velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
	
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

# knockback on hit
func apply_knockback(direction: Vector2, force: float, knockback_duration: float) -> void:
	knockback = direction * force
	knockback_timer = knockback_duration
