extends CharacterBody2D

enum State { IDLE, WALK, ATTACK, HURT, DEAD }

const SPEED = 300.0
const SPECIAL_RECHARGE_RATE = 0.5
const SPECIAL_DAMAGE = 5  # ¡5 puntos de daño!
const SPECIAL_RADIUS = 400.0  # Radio del tornado

@onready var animationPlayer = $AnimationPlayer
@onready var sprite2d = $Sprite2D
@onready var hitbox = $HitBox
@onready var hurtbox = $HurtBox
@onready var effect_sprite = $SpecialEffectSprite  # ¡ASEGÚRATE que existe!

var current_state = State.IDLE
var attack_type = ""
var health = 11
var max_health = 11
var special_charge = 7
var max_special = 7
var can_deal_damage = false
var can_receive_damage = true
var current_attack_damage = 1

# NUEVO: Variable para saber si es nivel 2
var is_level_2: bool = false

# Offsets específicos para tu personaje
var hitbox_offset_right = Vector2(0, 0)
var hitbox_offset_left = Vector2(-63, 0)
var hurtbox_offset_right = Vector2(0, 0)
var hurtbox_offset_left = Vector2(12, 0)

func _ready():
	# Conectar señales
	if not animationPlayer.animation_finished.is_connected(_on_animation_finished):
		animationPlayer.animation_finished.connect(_on_animation_finished)
	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	add_to_group("player")
	
	hitbox.monitoring = false
	hitbox.monitorable = false
	
	# Verificar control conectado
	check_controller()
	
	# NUEVO: Verificar si estamos en nivel 2
	check_current_level()
	
	# Asegurar que el efecto empiece invisible
	if effect_sprite:
		effect_sprite.visible = false
		effect_sprite.z_index = 1
		print("✅ SpecialEffectSprite configurado")
	else:
		print("⚠️ ADVERTENCIA: No se encontró SpecialEffectSprite")
	
	# Inicializar HUD
	update_hud_health()
	update_hud_special()

func check_current_level():
	# Verificar el nombre de la escena actual
	var current_scene_name = get_tree().current_scene.name
	var scene_filename = get_tree().current_scene.scene_file_path
	
	if "level2" in current_scene_name or "boss" in current_scene_name or "level2" in scene_filename:
		is_level_2 = true
		print("=== NIVEL 2 DETECTADO ===")
		print("Restaurando jugador para nivel 2...")
		
		# Restaurar vida y special completos
		health = max_health
		special_charge = max_special
		current_state = State.IDLE
		can_receive_damage = true
		
		print("✓ Vida restaurada: ", health, "/", max_health)
		print("✓ Special restaurado: ", special_charge, "/", max_special)
	else:
		print("=== NIVEL 1 DETECTADO ===")

func _physics_process(delta):
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
		return
	
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
	
	# Recargar special
	if special_charge < max_special and current_state != State.DEAD:
		special_charge += delta * SPECIAL_RECHARGE_RATE
		if special_charge >= max_special:
			special_charge = max_special
			update_hud_special()
		elif int(special_charge) != int(special_charge - delta * SPECIAL_RECHARGE_RATE):
			update_hud_special()

func _input(event):
	# ESC o BOTÓN B en CUALQUIER momento vuelve al menú
	if event.is_action_pressed("ui_cancel"):
		print("Volviendo al menú principal...")
		get_tree().change_scene_to_file("res://menu_inicio.tscn")
		return
	
	# ENTER o BOTÓN A si está muerto
	if current_state == State.DEAD and event.is_action_pressed("ui_accept"):
		handle_death_respawn()

func check_controller():
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		print("Control detectado: ", Input.get_joy_name(0))
	else:
		print("Usando teclado")

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
	elif Input.is_action_just_pressed("attack_l"):  # Botón X (Cuadrado)
		perform_attack("LAttack")
	elif Input.is_action_just_pressed("attack_v"):  # Botón Y (Triángulo)
		perform_attack("VAttack")
	elif Input.is_action_just_pressed("special_attack") and special_charge >= max_special:  # Botón B (Círculo)
		use_special_attack()
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
	
	if Input.is_action_just_pressed("attack_l"):  # Botón X (Cuadrado)
		perform_attack("LAttack")
	elif Input.is_action_just_pressed("attack_v"):  # Botón Y (Triángulo)
		perform_attack("VAttack")
	elif Input.is_action_just_pressed("special_attack") and special_charge >= max_special:  # Botón B (Círculo)
		use_special_attack()

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
			# Solo notificamos al HUD y a los enemigos
			get_tree().call_group("hud", "player_died")
			get_tree().call_group("enemy", "on_player_died")

func perform_attack(attack_name: String):
	if current_state != State.ATTACK and current_state != State.HURT:
		# Configurar daño según el tipo de ataque
		match attack_name:
			"LAttack":
				current_attack_damage = 1
			"VAttack":
				current_attack_damage = 2  # ¡Ataque vertical hace más daño!
		
		change_state(State.ATTACK, attack_name)

# ========== ATAQUE ESPECIAL - TORNADO ==========
func use_special_attack():
	if special_charge < max_special or current_state == State.DEAD:
		return
	
	print("🌀 ¡ATAQUE ESPECIAL ACTIVADO!")
	print("🌪️ TORNADO - Daño: ", SPECIAL_DAMAGE, " | Radio: ", SPECIAL_RADIUS)
	
	# Consumir toda la carga
	special_charge = 0
	update_hud_special()
	
	# Cambiar a estado de ataque especial
	change_state(State.ATTACK, "special_tornado")
	
	# Feedback visual y de audio
	start_vibration(0.9, 1.0, 1.5)  # Vibración fuerte
	screen_shake()
	
	# Aplicar daño del tornado (con delay para sincronizar con animación)
	apply_tornado_damage()

func apply_tornado_damage():
	# Pequeño delay para que coincida con la animación
	await get_tree().create_timer(0.3).timeout
	
	print("🌪️ APLICANDO DAÑO MASIVO DEL TORNADO...")
	
	# Obtener TODOS los enemigos en la escena
	var enemies = get_tree().get_nodes_in_group("enemy")
	var enemies_hit = 0
	
	for enemy in enemies:
		# Verificar distancia al jugador
		var distance = global_position.distance_to(enemy.global_position)
		
		if distance <= SPECIAL_RADIUS:
			print("  ✅ Golpeando: ", enemy.name, " (Distancia: ", int(distance), ")")
			
			# Aplicar daño (5 puntos)
			if enemy.has_method("take_damage"):
				enemy.take_damage(SPECIAL_DAMAGE)
				enemies_hit += 1
			else:
				# Fallback si no tiene take_damage
				if "health" in enemy:
					enemy.health -= SPECIAL_DAMAGE
					enemies_hit += 1
	
	print("🌪️ TORNADO completado. Enemigos golpeados: ", enemies_hit, "/", enemies.size())

func screen_shake():
	# Agitar la cámara para más épica
	var camera = $Camera2D
	if camera:
		var original_offset = camera.offset
		
		var tween = create_tween()
		for i in range(8):  # 8 sacudidas
			var shake_offset = Vector2(
				randf_range(-15, 15),
				randf_range(-15, 15)
			)
			tween.tween_property(camera, "offset", original_offset + shake_offset, 0.05)
		
		tween.tween_property(camera, "offset", original_offset, 0.2)
# ========== FIN ATAQUE ESPECIAL ==========

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
			area.get_parent().take_damage(current_attack_damage)
			can_deal_damage = false
			hitbox.monitoring = false

func take_damage(amount: int):
	if not can_receive_damage or current_state == State.DEAD:
		return
	
	health -= amount
	print("Jugador recibió ", amount, " de daño. Vida: ", health)
	
	# SOLO VIBRA AL RECIBIR DAÑO - NADA MÁS
	start_vibration(1, 1, 0.4)
	
	update_hud_health()
	
	if health <= 0:
		health = 0
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

# FUNCIÓN DE VIBRACIÓN - SOLO PARA DAÑO
func start_vibration(weak_strength: float, strong_strength: float, duration: float):
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		Input.start_joy_vibration(0, weak_strength, strong_strength, duration)

# COMUNICACIÓN CON HUD
func update_hud_health():
	get_tree().call_group("hud", "update_health", health)

func update_hud_special():
	get_tree().call_group("hud", "update_special", int(special_charge))

func get_health() -> int:
	return health

func get_special_charge() -> int:
	return int(special_charge)

# FUNCIÓN PARA VICTORIA - CUANDO EL GANGSTER MUERE
func on_boss_defeated():
	print("¡VICTORIA! Gangster derrotado")
	
	# Mostrar mensaje de victoria
	show_victory_message()
	
	# Esperar y volver al menú
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://menu_inicio.tscn")

func show_victory_message():
	print("🎉 ¡FELICIDADES! Has derrotado al Gangster")
	print("Juego completado - Volviendo al menú...")

func _on_hurtbox_area_entered(area):
	if area.is_in_group("enemy_hitbox") and can_receive_damage:
		print("¡Jugador recibió golpe del NPC!")
		take_damage(1)

func _on_animation_finished(anim_name):
	match anim_name:
		"LAttack", "VAttack":
			change_state(State.IDLE)
		"special_tornado":
			print("🌀 Animación de tornado finalizada")
			change_state(State.IDLE)
		"hurt":
			change_state(State.IDLE)

func handle_death_respawn():
	var current_scene = get_tree().current_scene.name
	var scene_filename = get_tree().current_scene.scene_file_path
	
	if "level2" in current_scene or "boss" in current_scene or "level2" in scene_filename:
		# Reiniciar solo el nivel 2
		print("Reiniciando nivel 2...")
		get_tree().reload_current_scene()
	else:
		# Volver al menú para nivel 1
		print("Volviendo al menú desde nivel 1...")
		get_tree().change_scene_to_file("res://menu_inicio.tscn")

# NUEVA FUNCIÓN: Para restaurar explícitamente desde level2_boss.gd
func restore_for_level_2():
	print("=== RESTAURACIÓN MANUAL PARA NIVEL 2 ===")
	
	# Restaurar valores
	health = max_health
	special_charge = max_special
	current_state = State.IDLE
	can_receive_damage = true
	
	# Actualizar HUD
	update_hud_health()
	update_hud_special()
	
	print("✓ Vida: ", health, "/", max_health)
	print("✓ Special: ", special_charge, "/", max_special)
	print("✓ Estado: IDLE")
	
	return true
