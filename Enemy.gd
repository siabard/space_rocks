extends Area2D

signal shoot

export (PackedScene) var Bullet
export (PackedScene) var speed = 150
export (PackedScene) var health = 3

var follow
var target = null

func _ready():
	$Sprite.frame = randi() % 3
	var path = $EnemyPath.get_children()[randi() % $EnemyPath.get_child_count()]
	follow = PathFollow2D.new()
	path.add_child(follow)
	follow.loop = false

func _process(delta):
	follow.offset += speed * delta
	position = follow.global_position
	if follow.unit_offset > 1:
		queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func shoot():
	var dir = target.global_position - global_position
	dir = dir.rotated(rand_range(-0.1, 0.1)).angle()
	emit_signal("shoot", Bullet, global_position, dir)
	$ShootSound.play()

func shoot_pulse(n, delay):
	for i in range(n):
		shoot()
		yield(get_tree().create_timer(delay), 'timeout')
		
func _on_GunTimer_timeout():
	shoot_pulse(3, 0.15)

func take_damage(amount):
	health -= amount
	$AnimationPlayer.play('flash')
	if health <= 0:
		explode()
	yield($AnimationPlayer, 'animation_finished')
	$AnimationPlayer.play('rotate')

func explode():
	speed = 0
	$GunTimer.stop()
	$CollisionShape2D.disabled = true
	$Sprite.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explotion")
	$ExplodeSound.play()

func _on_Enemy_body_entered(body):
	if body.name == 'Player':
		body.shield -= 50
