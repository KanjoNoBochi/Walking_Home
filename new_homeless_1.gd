# homeless_npc_complete.gd
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

const SPEED = 150.0
const ATTACK_DAMAGE = 1
const ATTACK_RADIUS = 25.0  # Radio para detectar cuando atacar

@onready var animationPlayer = $AnimationPlayer
@onready var sprite2d = $Sprite2D
@onready var hitbox = $HitBox
@onready var hurtbox = $HurtBox
@onready var detection_area = $DetectionArea

var current_state = State.IDLE
var health = 5
var player_ref = null
var can_deal_damage = false
var can_receive_damage = true

# Offsets específicos para Homeless
var hitbox_offset_right = Vector2(0, 0)
var hitbox_offset_left = Vector2(-35, 0)
var hurtbox_offset_right = Vector2(0, 0)
var hurtbox_offset_left = Vector2(12, 0)

func _ready():
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	animationPlayer.animation_finished.connect(_on_animation_finished)
	add_to_group("enemy")
	
	hitbox.monitoring = false
	hitbox.monitorable = false

func _physics_process(delta):
	match current_state:
		State.IDLE:
			handle_idle()
		State.CHASE:
			handle_chase()
		State.ATTACK:
			handle_attack()
		State.HURT:
			handle_hurt()
		State.DEAD:
			handle_dead()
	
	update_collision_positions()

func update_collision_positions():
	if sprite2d.flip_h:
		hitbox.position = hitbox_offset_left
		hurtbox.position = hurtbox_offset_left
	else:
		hitbox.position = hitbox_offset_right
		hurtbox.position = hurtbox_offset_right

func handle_idle():
	animationPlayer.play("idle")
	can_receive_damage = true
	hurtbox.monitoring = true
	
	# Si hay jugador detectado, perseguirlo
	if player_ref:
		change_state(State.CHASE)

func handle_chase():
	# Verificar si jugador está muerto o no existe
	if not player_ref or (player_ref.has_method("current_state") and player_ref.current_state == player_ref.State.DEAD):
		change_state(State.IDLE)
		return
	
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()
	
	sprite2d.flip_h = direction.x < 0
	animationPlayer.play("walk")
	
	# Verificar distancia para atacar (usando un radio en lugar de la hitbox)
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	if distance_to_player < ATTACK_RADIUS:
		change_state(State.ATTACK)

func handle_attack():
	# Verificar si jugador está muerto
	if player_ref and player_ref.has_method("current_state") and player_ref.current_state == player_ref.State.DEAD:
		change_state(State.IDLE)
		return
	
	velocity = Vector2.ZERO

func handle_hurt():
	velocity = Vector2.ZERO
	can_receive_damage = false
	hurtbox.monitoring = false

func handle_dead():
	velocity = Vector2.ZERO
	can_receive_damage = false
	hurtbox.monitoring = false
	hitbox.monitoring = false

func change_state(new_state: State):
	if current_state == State.DEAD:
		return
		
	can_deal_damage = false
	hitbox.monitoring = false
	hitbox.monitorable = false
	
	current_state = new_state
	
	match new_state:
		State.IDLE:
			animationPlayer.play("idle")
			can_receive_damage = true
			hurtbox.monitoring = true
		State.CHASE:
			animationPlayer.play("walk")
			can_receive_damage = true
			hurtbox.monitoring = true
		State.ATTACK:
			animationPlayer.play("attack")
			can_receive_damage = true
			hurtbox.monitoring = true
		State.HURT:
			animationPlayer.play("hurt")
		State.DEAD:
			animationPlayer.play("dead")
			# Desactivar completamente las colisiones
			hurtbox.monitoring = false
			hitbox.monitoring = false
			hitbox.monitorable = false
			# Programar desaparición
			await get_tree().create_timer(2.0).timeout
			queue_free()

func take_damage(amount: int):
	if not can_receive_damage or current_state == State.DEAD:
		return
	
	health -= amount
	print("NPC recibió ", amount, " de daño. Vida: ", health)
	
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

func enable_attack_damage():
	can_deal_damage = true
	hitbox.monitoring = true
	hitbox.monitorable = true
	check_hitbox_collisions()

func disable_attack_damage():
	can_deal_damage = false
	hitbox.monitoring = false
	hitbox.monitorable = false

func check_hitbox_collisions():
	if not can_deal_damage:
		return
		
	var overlapping_areas = hitbox.get_overlapping_areas()
	
	for area in overlapping_areas:
		if area.is_in_group("player_hurtbox"):
			print("¡NPC golpeó al jugador!")
			area.get_parent().take_damage(ATTACK_DAMAGE)
			can_deal_damage = false
			hitbox.monitoring = false

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		if current_state == State.IDLE:
			change_state(State.CHASE)

func _on_detection_area_body_exited(body):
	if body == player_ref:
		player_ref = null
		if current_state == State.CHASE or current_state == State.ATTACK:
			change_state(State.IDLE)

func _on_hurtbox_area_entered(area):
	if area.is_in_group("player_hitbox") and can_receive_damage:
		print("¡NPC recibió golpe del jugador!")
		take_damage(1)

func _on_animation_finished(anim_name):
	match anim_name:
		"attack":
			# Verificar si el jugador sigue en rango
			if player_ref:
				var distance_to_player = global_position.distance_to(player_ref.global_position)
				if distance_to_player < ATTACK_RADIUS:
					change_state(State.ATTACK)
				else:
					change_state(State.CHASE)
			else:
				change_state(State.IDLE)
		"hurt":
			# Si hay jugador detectado, perseguirlo
			if player_ref:
				change_state(State.CHASE)
			else:
				change_state(State.IDLE)
