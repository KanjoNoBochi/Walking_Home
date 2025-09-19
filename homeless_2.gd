extends CharacterBody2D

# Configuración del enemigo
@export var speed = 150
@export var health = 3
@export var is_boss = false
@export var attack_cooldown = 1.0

# Estados del enemigo
enum State {IDLE, CHASE, ATTACK, HURT, DEAD}
var current_state = State.IDLE

# Referencias
var player = null
var can_attack = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_box = $AttackBox
@onready var hurt_box = $HurtBox
@onready var hurt_timer = $HurtTimer
@onready var attack_timer = $AttackTimer
@onready var attack_cooldown_timer = $AttackCooldownTimer
@onready var death_timer = $DeathTimer

func _ready():
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	
	if is_boss:
		add_to_group("boss")
	else:
		add_to_group("enemies")

func _physics_process(delta):
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			velocity = Vector2.ZERO
		State.HURT:
			velocity = Vector2.ZERO
		State.DEAD:
			velocity = Vector2.ZERO
	
	move_and_slide()
	update_animation()

func chase_player(delta):
	if player and current_state != State.HURT and current_state != State.DEAD and can_attack:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		if direction.x != 0:
			animated_sprite.flip_h = direction.x < 0
		
		if global_position.distance_to(player.global_position) < 50 and can_attack:
			start_attack()

func start_attack():
	current_state = State.ATTACK
	can_attack = false
	attack_box.monitoring = true
	attack_timer.start(0.4)
	attack_cooldown_timer.start(attack_cooldown)

func update_animation():
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.CHASE:
			animated_sprite.play("walk")
		State.ATTACK:
			animated_sprite.play("attack")
		State.HURT:
			animated_sprite.play("hurt")
		State.DEAD:
			animated_sprite.play("dead")

func take_damage(amount):
	if current_state == State.DEAD:
		return
	
	health -= amount
	
	if health <= 0:
		health = 0
		current_state = State.DEAD
		$CollisionShape2D.disabled = true
		detection_area.monitoring = false
		attack_box.monitoring = false
		hurt_box.monitoring = false
		death_timer.start(2.0)
	else:
		current_state = State.HURT
		hurt_timer.start(0.5)

func _on_detection_area_body_entered(body):
	if body.name == "Raider":
		player = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body.name == "Raider":
		player = null
		current_state = State.IDLE

func _on_hurt_box_area_entered(area):
	if area.is_in_group("player_attack") and current_state != State.HURT and current_state != State.DEAD:
		take_damage(1)

func _on_attack_timer_timeout():
	attack_box.monitoring = false
	if current_state == State.ATTACK:
		current_state = State.CHASE

func _on_attack_cooldown_timer_timeout():
	can_attack = true

func _on_hurt_timer_timeout():
	if current_state == State.HURT:
		current_state = State.CHASE

func _on_death_timer_timeout():
	queue_free()
