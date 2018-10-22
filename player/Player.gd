extends RigidBody2D

signal shield_changed
signal shoot
signal live_changed
signal dead

export (int) var max_shield
export (float) var shield_regen
export (PackedScene) var Bullet
export (float) var fire_rate
export (int) var engine_power
export (int) var spin_power

var shield = 0 setget set_shield
var can_shoot = true
enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = null
var thrust = Vector2()
var rotation_dir = 0
var screensize = Vector2()
var lives = 0 setget set_lives

func set_lives(value):
	lives = value
	self.shield = max_shield
	emit_signal("live_changed", value)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)

func start():
	$Sprite.show()
	self.lives = 3
	change_state(ALIVE)
	self.shield = max_shield

func _ready():
	change_state(INIT)
	screensize = get_viewport().get_visible_rect().size
	$GunTimer.wait_time = fire_rate
	
func change_state(new_state):
	state = new_state
	match new_state:
		INIT:
			$CollisionShape2D.disabled = true
			$Sprite.modulate.a = 0.5
		ALIVE:
			$CollisionShape2D.disabled = false
			$Sprite.modulate.a = 1.0
		INVULNERABLE:
			$CollisionShape2D.disabled = true
			$Sprite.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		DEAD:
			$EngineSound.stop()
			$CollisionShape2D.disabled = true
			$Sprite.hide()
			linear_velocity = Vector2()
			emit_signal("dead")
	
	
func _process(delta):
	get_input()
	self.shield += shield_regen * delta

func get_input():
	$Exhaust.emitting = false
	thrust = Vector2()
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thrust"):
		$Exhaust.emitting = true
		thrust = Vector2(engine_power, 0)
		if not $EngineSound.playing:
			$EngineSound.play()
	rotation_dir = 0
	if Input.is_action_pressed("rotate_right"):
		rotation_dir += 1
	if Input.is_action_pressed("rotate_left"):
		rotation_dir -= 1
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	if state == INVULNERABLE:
		return
	emit_signal("shoot", Bullet, $Muzzle.global_position, rotation)
	can_shoot = false
	$GunTimer.start()
	$LaserSound.play()

func _integrate_forces(physics_state):
	set_applied_force(thrust.rotated(rotation))
	set_applied_torque(spin_power * rotation_dir)
	var xform = physics_state.get_transform()
	if xform.origin.x > screensize.x:
		xform.origin.x = 0
	if xform.origin.x < 0:
		xform.origin.x = screensize.x
	if xform.origin.y > screensize.y:
		xform.origin.y = 0
	if xform.origin.y < 0:
		xform.origin.y = screensize.y
	physics_state.set_transform(xform)

func _on_GunTimer_timeout():
	can_shoot = true


func _on_InvulnerabilityTimer_timeout():
	change_state(ALIVE)


func _on_AnimationPlayer_animation_finished(anim_name):
	$Explosion.hide()


func _on_Player_body_entered(body):
	if body.is_in_group('rocks'):
		body.explode()
		$Explosion.show()
		$Explosion/AnimationPlayer.play("explotion")
		self.shield -= body.size * 25

func set_shield(value):
	if value > max_shield:
		value = max_shield
	shield = value
	emit_signal("shield_changed", shield/max_shield)
	if shield <= 0:
		self.lives -= 1