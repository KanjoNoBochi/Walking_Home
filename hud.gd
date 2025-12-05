# hud.gd - PARA NODE2D
extends Node2D

# Referencias a nodos - RUTAS CORRECTAS para tu estructura
@onready var life_bar = $LifeBar/AnimatedSprite2D
@onready var special_bar = $Special/AnimatedSprite2D

func _ready():
	# Esperar un frame para que el jugador esté cargado
	await get_tree().process_frame
	
	# Buscar al jugador en la escena
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("HUD: Jugador encontrado, conectando...")
		# Actualizar con los valores actuales del jugador
		if player.has_method("get_health"):
			update_health(player.get_health())
		else:
			update_health(player.health)
		
		update_special(7)
	else:
		print("HUD: No se encontró jugador, usando valores por defecto")
		update_health(11)
		update_special(7)

func update_health(value):
	print("HUD actualizando vida: ", value)
	value = clamp(value, 0, 11)
	
	match value:
		11: life_bar.play("full")
		10: life_bar.play("4.5")
		9: life_bar.play("4")
		8: life_bar.play("3.5")
		7: life_bar.play("3")
		6: life_bar.play("2.5")
		5: life_bar.play("2")
		4: life_bar.play("1.5")
		3: life_bar.play("1")
		2: life_bar.play("0.5")
		1: life_bar.play("0")
		0: life_bar.play("dead")

func update_special(value):
	print("HUD actualizando special: ", value)
	value = clamp(value, 0, 7)
	
	match value:
		7: special_bar.play("full")
		6: special_bar.play("5")
		5: special_bar.play("4")
		4: special_bar.play("3")
		3: special_bar.play("2")
		2: special_bar.play("1")
		1: special_bar.play("empty")
		0: special_bar.play("dead")

func player_died():
	print("HUD: Mostrando Game Over")
	# Pausar el juego
	get_tree().paused = true
