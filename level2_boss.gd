extends Node

func _ready():
	print("=== NIVEL 2 - JEFE FINAL ===")
	print("¡Prepárate para enfrentar al Gangster!")
	
	# Pequeño delay para asegurar que todo esté cargado
	await get_tree().create_timer(0.5).timeout
	
	# Configurar jugador para nivel 2
	setup_player_for_level_2()
	
	# Actualizar HUD
	update_hud_for_level_2()
	
	print("✓ Nivel 2 completamente inicializado")

func setup_player_for_level_2():
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("Configurando jugador para nivel 2...")
		
		# Intentar restaurar usando el nuevo método
		if player.has_method("restore_for_level_2"):
			player.restore_for_level_2()
			print("✓ Jugador restaurado con restore_for_level_2()")
		# Si no existe, usar el método viejo
		elif player.has_method("check_current_level"):
			player.check_current_level()
			print("✓ Jugador configurado con check_current_level()")
		# Si no hay métodos, establecer valores manualmente
		else:
			print("ADVERTENCIA: Jugador no tiene métodos de restauración")
			print("Estableciendo valores manualmente...")
			
			# Intentar establecer salud directamente
			if "health" in player:
				player.health = 11
			
			if "special_charge" in player:
				player.special_charge = 7
			
			print("✓ Valores establecidos manualmente")
	else:
		print("ERROR: No se encontró jugador en nivel 2")

func update_hud_for_level_2():
	# Esperar un poco más para que el HUD esté listo
	await get_tree().create_timer(0.8).timeout
	
	print("Actualizando HUD para nivel 2...")
	
	# Buscar todos los nodos HUD en la escena
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	
	if hud_nodes.size() > 0:
		print("Encontrados ", hud_nodes.size(), " nodos HUD")
		
		for hud in hud_nodes:
			print("Procesando HUD: ", hud.name)
			
			# Intentar conectar primero
			if hud.has_method("connect_to_player"):
				hud.connect_to_player()
				print("✓ HUD conectado al jugador")
			
			# Luego forzar actualización
			if hud.has_method("force_update_from_player"):
				hud.force_update_from_player()
				print("✓ HUD forzado a actualizar")
			
			# Si no funciona, establecer valores directamente
			elif hud.has_method("update_health"):
				hud.update_health(11)
				hud.update_special(7)
				print("✓ HUD actualizado directamente")
	else:
		print("ADVERTENCIA: No se encontraron nodos HUD en grupos")
		
		# Buscar por nombre como fallback
		var hud = get_node_or_null("CanvasLayer/HUD")
		if hud:
			print("Encontrado HUD por ruta: CanvasLayer/HUD")
			if hud.has_method("update_health"):
				hud.update_health(11)
				hud.update_special(7)
				print("✓ HUD actualizado por ruta")

func _on_gangster_defeated():
	print("¡VICTORIA! Gangster derrotado")
	
	# Mostrar mensaje de victoria
	print("🎉 ¡FELICIDADES! Has completado el juego")
	print("Derrotaste al Gangster y limpiaste las calles")
	
	# Esperar y volver al menú
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://menu_inicio.tscn")
