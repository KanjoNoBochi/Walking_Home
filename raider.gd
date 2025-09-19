extends CharacterBody2D

# Configuración de movimiento
const SPEED = 300
const HORIZONTAL_SPEED = SPEED
const VERTICAL_SPEED = SPEED * 0.8
const JUMP_VELOCITY = -400

# Estados del jugador
enum State {IDLE, WALK, ATTACK_LIGHT, ATTACK_HEAVY, JUMP, HURT, DEAD}
var current_state = State.IDLE

# Vida y atributos
var health = 11
var max_health = 11
var special_cooldown = 0
var special_ready = true
var is_dead = false
var can_attack = true
var attack_cooldown = 0.5

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var hurt_box = $HurtBox
@onready var attack_box = $AttackBox
@onready var attack_timer = $AttackTimer
@onready var attack_cooldown_timer = $AttackCooldownTimer
@onready var hurt_timer = $HurtTimer
@onready var special_cooldown_timer = $SpecialCooldownTimer

func _ready():
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	if not special_ready:
		special_cooldown_timer.start(60)

func _physics_process(delta):
	if is_dead:
		return
	
	match current_state:
		State.IDLE, State.WALK:
			handle_movement()
			handle_attacks()
		State.ATTACK_LIGHT, State.ATTACK_HEAVY:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta * 2)
			velocity.y = move_toward(velocity.y, 0, SPEED * delta * 2)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta * 3)
			velocity.y = move_toward(velocity.y, 0, SPEED * delta * 3)
	
	move_and_slide()
	update_animation()

func handle_movement():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		current_state = State.WALK
	else:
		current_state = State.IDLE
	
	velocity.x = input_vector.x * HORIZONTAL_SPEED
	velocity.y = input_vector.y * VERTICAL_SPEED
	
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP

func handle_attacks():
	if not can_attack:
		return
	
	if Input.is_action_just_pressed("attack_light") and can_attack:
		start_attack(State.ATTACK_LIGHT, 0.3)
		
	elif Input.is_action_just_pressed("attack_heavy") and can_attack:
		start_attack(State.ATTACK_HEAVY, 0.5)
		
	elif Input.is_action_just_pressed("special_attack") and special_ready and can_attack:
		use_special_attack()

func start_attack(attack_type, duration):
	current_state = attack_type
	can_attack = false
	attack_box.monitoring = true
	attack_timer.start(duration)
	attack_cooldown_timer.start(attack_cooldown)

func use_special_attack():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(3)
	
	special_ready = false
	special_cooldown = 60
	special_cooldown_timer.start(special_cooldown)
	get_tree().call_group("hud", "update_special", 0)

func update_animation():
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.WALK:
			animated_sprite.play("walk")
			if velocity.x != 0:
				animated_sprite.flip_h = velocity.x < 0
		State.ATTACK_LIGHT:
			animated_sprite.play("lateral_attack")
		State.ATTACK_HEAVY:
			animated_sprite.play("vertical_attack")
		State.JUMP:
			animated_sprite.play("jump")
		State.HURT:
			animated_sprite.play("hurt")
		State.DEAD:
			animated_sprite.play("dead")

func take_damage(amount, attacker=null):
	if current_state == State.HURT or current_state == State.DEAD:
		return
	
	health -= amount
	get_tree().call_group("hud", "update_health", health)
	
	if health <= 0:
		health = 0
		current_state = State.DEAD
		is_dead = true
		$CollisionShape2D.disabled = true
		get_tree().call_group("hud", "player_died")
	else:
		current_state = State.HURT
		hurt_timer.start(0.5)
	
	if attacker:
		var knockback_direction = (global_position - attacker.global_position).normalized()
		velocity = knockback_direction * 200

func _on_hurt_box_area_entered(area):
	if area.is_in_group("enemy_attack") and current_state != State.HURT and current_state != State.DEAD:
		var damage = 1
		if area.get_parent().is_in_group("boss"):
			damage = 2
		take_damage(damage, area.get_parent())

func _on_attack_timer_timeout():
	attack_box.monitoring = false
	if current_state == State.ATTACK_LIGHT or current_state == State.ATTACK_HEAVY:
		current_state = State.IDLE

func _on_attack_cooldown_timer_timeout():
	can_attack = true

func _on_hurt_timer_timeout():
	if current_state == State.HURT:
		current_state = State.IDLE

func _on_special_cooldown_timer_timeout():
	special_ready = true
	get_tree().call_group("hud", "update_special", 7)
