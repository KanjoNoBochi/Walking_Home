# new_raider_movement.gd
extends CharacterBody2D

enum State { IDLE, WALK, ATTACK, HURT, DEAD }

const SPEED = 300.0
const ATTACK_DAMAGE = 1

@onready var animationPlayer = $AnimationPlayer
@onready var sprite2d = $Sprite2D
@onready var hitbox = $HitBox
@onready var hurtbox = $HurtBox

var current_state = State.IDLE
var attack_type = ""
var health = 11
var can_deal_damage = false
var can_receive_damage = true

# Offsets específicos para tu personaje
var hitbox_offset_right = Vector2(0, 0)
var hitbox_offset_left = Vector2(-63, 0)
var hurtbox_offset_right = Vector2(0, 0)
var hurtbox_offset_left = Vector2(12, 0)

func _ready():
	animationPlayer.animation_finished.connect(_on_animation_finished)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	add_to_group("player")
	
	hitbox.monitoring = false
	hitbox.monitorable = false

func _physics_process(delta):
	match current_state:
		State.IDLE:
			handle_idle()
		State.WALK:
			handle_walk()
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
	var input_direction = get_input_direction()
	
	if input_direction.length() > 0:
		change_state(State.WALK)
	elif Input.is_action_just_pressed("attack_l"):
		perform_attack("LAttack")
	elif Input.is_action_just_pressed("attack_v"):
		perform_attack("VAttack")
	else:
		animationPlayer.play("idle")

func handle_walk():
	var input_direction = get_input_direction()
	
	if input_direction.length() == 0:
		change_state(State.IDLE)
		return
	
	velocity = input_direction.normalized() * SPEED
	move_and_slide()
	
	if input_direction.x != 0:
		sprite2d.flip_h = input_direction.x < 0
	
	animationPlayer.play("walk")
	
	if Input.is_action_just_pressed("attack_l"):
		perform_attack("LAttack")
	elif Input.is_action_just_pressed("attack_v"):
		perform_attack("VAttack")

func handle_attack():
	velocity = Vector2.ZERO

func handle_hurt():
	velocity = Vector2.ZERO
	can_receive_damage = false

func handle_dead():
	velocity = Vector2.ZERO
	can_receive_damage = false

func get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

func change_state(new_state: State, attack_anim: String = ""):
	if current_state == State.DEAD:
		return
		
	can_deal_damage = false
	hitbox.monitoring = false
	hitbox.monitorable = false
	
	current_state = new_state
	attack_type = attack_anim
	
	match new_state:
		State.IDLE:
			animationPlayer.play("idle")
			can_receive_damage = true
			hurtbox.monitoring = true
		State.WALK:
			animationPlayer.play("walk")
			can_receive_damage = true
			hurtbox.monitoring = true
		State.ATTACK:
			animationPlayer.play(attack_anim)
			can_receive_damage = true
			hurtbox.monitoring = true
		State.HURT:
			animationPlayer.play("hurt")
			hurtbox.monitoring = false
		State.DEAD:
			animationPlayer.play("dead")
			hurtbox.monitoring = false
			set_physics_process(false)

func perform_attack(attack_name: String):
	if current_state != State.ATTACK and current_state != State.HURT:
		change_state(State.ATTACK, attack_name)

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
		if area.is_in_group("enemy_hurtbox"):
			print("¡Jugador golpeó al NPC!")
			area.get_parent().take_damage(ATTACK_DAMAGE)
			can_deal_damage = false
			hitbox.monitoring = false

func take_damage(amount: int):
	if not can_receive_damage or current_state == State.DEAD:
		return
	
	health -= amount
	print("Jugador recibió ", amount, " de daño. Vida: ", health)
	
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

func _on_hurtbox_area_entered(area):
	if area.is_in_group("enemy_hitbox") and can_receive_damage:
		print("¡Jugador recibió golpe del NPC!")
		take_damage(1)

func _on_animation_finished(anim_name):
	match anim_name:
		"LAttack", "VAttack":
			change_state(State.IDLE)
		"hurt":
			change_state(State.IDLE)
