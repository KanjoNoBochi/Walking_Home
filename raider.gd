extends CharacterBody2D

# Configuración de movimiento
const SPEED = 300
const HORIZONTAL_SPEED = SPEED
const VERTICAL_SPEED = SPEED * 0.8  # 80% de la velocidad horizontal
const JUMP_VELOCITY = -400

# Estados del jugador
enum State {IDLE, WALK, ATTACK_LIGHT, ATTACK_HEAVY, JUMP, HURT, DEAD}
var current_state = State.IDLE
var previous_state = State.IDLE

# Vida y atributos
var health = 11
var max_health = 11
var special_cooldown = 0
var special_ready = true
var is_dead = false

# Referencias a nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var hurt_box = $HurtBox
@onready var attack_box = $AttackBox

func _ready():
	# Conectar señales de las áreas
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	# Iniciar temporizador para la habilidad especial
	if not special_ready:
		$SpecialCooldownTimer.start(60)

func _physics_process(delta):
	if is_dead:
		return
	
	# Manejar cambios de estado
	match current_state:
		State.IDLE, State.WALK:
			handle_movement()
			handle_attacks()
		State.ATTACK_LIGHT, State.ATTACK_HEAVY:
			# Durante el ataque, reducir velocidad
			velocity.x = move_toward(velocity.x, 0, SPEED * delta * 2)
			velocity.y = move_toward(velocity.y, 0, SPEED * delta * 2)
		State.HURT:
			# Durante el daño, reducir velocidad
			velocity.x = move_toward(velocity.x, 0, SPEED * delta * 3)
			velocity.y = move_toward(velocity.y, 0, SPEED * delta * 3)
	
	# Aplicar movimiento
	move_and_slide()
	
	# Actualizar animaciones
	update_animation()

func handle_movement():
	# Obtener input de movimiento
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# Normalizar para movimiento diagonal
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		current_state = State.WALK
	else:
		current_state = State.IDLE
	
	# Aplicar velocidades diferentes para horizontal/vertical
	velocity.x = input_vector.x * HORIZONTAL_SPEED
	velocity.y = input_vector.y * VERTICAL_SPEED
	
	# Saltar (si es necesario)
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP

func handle_attacks():
	if Input.is_action_just_pressed("attack_light"):
		current_state = State.ATTACK_LIGHT
		# Activar la caja de ataque
		attack_box.monitoring = true
		# Temporizador para desactivar la caja de ataque
		$AttackTimer.start(0.3)
		
	elif Input.is_action_just_pressed("attack_heavy"):
		current_state = State.ATTACK_HEAVY
		# Activar la caja de ataque
		attack_box.monitoring = true
		# Temporizador para desactivar la caja de ataque
		$AttackTimer.start(0.5)
		
	elif Input.is_action_just_pressed("special_attack") and special_ready:
		use_special_attack()

func use_special_attack():
	# Encontrar todos los enemigos en la escena
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		# Aplicar 3 puntos de daño a cada enemigo
		enemy.take_damage(3)
	
	# Reiniciar el cooldown de la habilidad especial
	special_ready = false
	special_cooldown = 60
	$SpecialCooldownTimer.start(special_cooldown)
	# Actualizar HUD
	get_tree().call_group("hud", "update_special", 0)

func update_animation():
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.WALK:
			animated_sprite.play("walk")
			# Girar sprite según dirección
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
	# Actualizar HUD
	get_tree().call_group("hud", "update_health", health)
	
	if health <= 0:
		health = 0
		current_state = State.DEAD
		is_dead = true
		# Desactivar colisiones
		$CollisionShape2D.disabled = true
		# Notificar al HUD
		get_tree().call_group("hud", "player_died")
	else:
		current_state = State.HURT
		# Temporizador para salir del estado de daño
		$HurtTimer.start(0.5)
	
	# Aplicar retroceso si hay un atacante
	if attacker:
		var knockback_direction = (global_position - attacker.global_position).normalized()
		velocity = knockback_direction * 200

func _on_hurt_box_area_entered(area):
	# Verificar si el área que entró es una caja de ataque enemiga
	if area.is_in_group("enemy_attack"):
		var damage = 1
		# Si es el jefe, hace más daño
		if area.get_parent().is_in_group("boss"):
			damage = 2
		take_damage(damage, area.get_parent())

func _on_attack_timer_timeout():
	attack_box.monitoring = false
	# Volver al estado anterior después de atacar
	if current_state == State.ATTACK_LIGHT or current_state == State.ATTACK_HEAVY:
		current_state = State.IDLE

func _on_hurt_timer_timeout():
	if current_state == State.HURT:
		current_state = State.IDLE

func _on_special_cooldown_timer_timeout():
	special_ready = true
	# Notificar al HUD
	get_tree().call_group("hud", "update_special", 7)
