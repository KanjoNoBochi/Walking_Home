extends CanvasLayer

var life_bar: AnimatedSprite2D
var special_bar: AnimatedSprite2D
var is_in_transition: bool = false

func _ready():
	# Configurar capa del HUD
	layer = 10
	
	# Buscar los nodos del HUD
	find_hud_nodes()
	
	# Conectar con el jugador
	connect_to_player()
	
	print("=== HUD INICIALIZADO ===")

func find_hud_nodes():
	# Buscar los nodos del HUD
	var hud = $HUD
	
	if not hud:
		print("ERROR: No se encontró el nodo HUD principal")
		return
	
	# Buscar LifeBar
	life_bar = find_animated_sprite(hud, "LifeBar")
	
	# Buscar Special
	special_bar = find_animated_sprite(hud, "Special")
	
	# Debug
	print("HUD encontrado:")
	print("- LifeBar: ", life_bar != null)
	print("- Special: ", special_bar != null)

func find_animated_sprite(parent, node_name: String) -> AnimatedSprite2D:
	var target_node = parent.find_child(node_name, true, false)
	if target_node:
		var sprite = target_node.find_child("AnimatedSprite2D", true, false)
		if sprite:
			return sprite
		elif target_node is AnimatedSprite2D:
			return target_node
	return null

func connect_to_player():
	# Esperar a que el jugador esté disponible
	await get_tree().create_timer(0.2).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("HUD: Conectado al jugador - ", player.name)
		
		# Obtener valores del jugador
		var player_health = 11
		var player_special = 7
		
		if player.has_method("get_health"):
			player_health = player.get_health()
		
		if player.has_method("get_special_charge"):
			player_special = player.get_special_charge()
		
		print("Valores del jugador:")
		print("- Salud: ", player_health)
		print("- Special: ", player_special)
		
		# Actualizar HUD con los valores del jugador
		update_health(player_health)
		update_special(player_special)
	else:
		print("HUD: Jugador no encontrado, usando valores por defecto")
		update_health(11)
		update_special(7)

func update_health(value):
	if life_bar == null:
		print("ERROR HUD: life_bar es null - no se puede actualizar vida")
		# Intentar encontrar de nuevo
		find_hud_nodes()
		if life_bar == null:
			return
	
	value = clamp(value, 0, 11)
	
	print("HUD actualizando vida: ", value)
	
	match value:
		11: 
			life_bar.play("full")
			print("  -> Animación: full")
		10: 
			life_bar.play("4.5")
			print("  -> Animación: 4.5")
		9: 
			life_bar.play("4")
			print("  -> Animación: 4")
		8: 
			life_bar.play("3.5")
			print("  -> Animación: 3.5")
		7: 
			life_bar.play("3")
			print("  -> Animación: 3")
		6: 
			life_bar.play("2.5")
			print("  -> Animación: 2.5")
		5: 
			life_bar.play("2")
			print("  -> Animación: 2")
		4: 
			life_bar.play("1.5")
			print("  -> Animación: 1.5")
		3: 
			life_bar.play("1")
			print("  -> Animación: 1")
		2: 
			life_bar.play("0.5")
			print("  -> Animación: 0.5")
		1: 
			life_bar.play("0")
			print("  -> Animación: 0")
		0: 
			life_bar.play("dead")
			print("  -> Animación: dead")

func update_special(value):
	if special_bar == null:
		print("ERROR HUD: special_bar es null - no se puede actualizar special")
		# Intentar encontrar de nuevo
		find_hud_nodes()
		if special_bar == null:
			return
	
	value = clamp(value, 0, 7)
	
	print("HUD actualizando special: ", value)
	
	match value:
		7: 
			special_bar.play("full")
			print("  -> Animación: full")
		6: 
			special_bar.play("5")
			print("  -> Animación: 5")
		5: 
			special_bar.play("4")
			print("  -> Animación: 4")
		4: 
			special_bar.play("3")
			print("  -> Animación: 3")
		3: 
			special_bar.play("2")
			print("  -> Animación: 2")
		2: 
			special_bar.play("1")
			print("  -> Animación: 1")
		1: 
			special_bar.play("empty")
			print("  -> Animación: empty")
		0: 
			special_bar.play("dead")
			print("  -> Animación: dead")

func player_died():
	print("HUD: Jugador murió")
	if life_bar:
		life_bar.modulate = Color(1, 1, 1, 0.5)
	if special_bar:
		special_bar.modulate = Color(1, 1, 1, 0.5)

func on_scene_transition_start():
	is_in_transition = true
	print("HUD: Transición de escena iniciada")
	set_hud_alpha(0.3)

func on_scene_transition_end():
	is_in_transition = false
	print("HUD: Transición de escena finalizada")
	set_hud_alpha(1.0)
	
	# Reconectar con jugador en nueva escena
	await get_tree().create_timer(0.3).timeout
	connect_to_player()

func set_hud_alpha(alpha: float):
	if life_bar:
		life_bar.modulate.a = alpha
	if special_bar:
		special_bar.modulate.a = alpha

func force_update_from_player():
	print("HUD: Forzando actualización desde jugador...")
	connect_to_player()
