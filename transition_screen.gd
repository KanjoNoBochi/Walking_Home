extends CanvasLayer

# Variable para la escena siguiente
@export var next_scene: String = "res://level2_boss.tscn"

# Variable para controlar si ya se está procesando el input
var is_changing_scene: bool = false

func _ready():
	# Poner esta capa sobre todo (incluyendo HUD)
	layer = 100
	
	# Tomar control del input
	set_process_input(true)
	
	# Mostrar mensaje de debug
	print("=== PANTALLA DE TRANSICIÓN ===")
	print("Has completado el nivel 1")
	print("Escena destino: ", next_scene)
	print("INSTRUCCIÓN: Presiona ENTER para ir al nivel del Gangster")

func _input(event):
	# Solo procesar si no estamos ya cambiando de escena
	if is_changing_scene:
		return
	
	# Detectar tecla ENTER o botón A del control
	if event.is_action_pressed("ui_accept"):
		print("Jugador presionó ENTER, cambiando al nivel 2...")
		change_to_next_scene()

func change_to_next_scene():
	# Prevenir múltiples llamadas
	if is_changing_scene:
		return
	
	is_changing_scene = true
	
	# Notificar al HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("on_scene_transition_start"):
		hud.on_scene_transition_start()
	
	# Cambiar de escena
	print("Iniciando cambio a: ", next_scene)
	
	if ResourceLoader.exists(next_scene):
		get_tree().change_scene_to_file(next_scene)
	else:
		print("ERROR: La escena no existe: ", next_scene)
		print("Volviendo al menú principal...")
		get_tree().change_scene_to_file("res://menu_inicio.tscn")
	
	# Eliminar esta pantalla de transición
	queue_free()

func _exit_tree():
	is_changing_scene = false
	set_process_input(false)
