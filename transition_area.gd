extends Area2D

# Configuración exportable desde el editor
@export var next_scene: String = "res://level2_boss.tscn"
@export var transition_scene: String = "res://transition_screen.tscn"

# Variables internas
var transition_triggered: bool = false

func _ready():
	# Conectar señales de detección
	body_entered.connect(_on_body_entered)
	
	# Mensaje de inicialización
	print("Área de transición inicializada")
	print("Escena destino: ", next_scene)
	print("Transición automática activada")

func _on_body_entered(body):
	# Solo reaccionar al jugador, una sola vez
	if body.is_in_group("player") and not transition_triggered:
		transition_triggered = true
		print("=== JUGADOR ALCANZÓ EL FINAL DEL NIVEL 1 ===")
		print("Activando transición automática...")
		
		# Pequeño delay para feedback
		await get_tree().create_timer(0.5).timeout
		
		# Mostrar pantalla de transición
		show_transition_screen()

func show_transition_screen():
	# Cargar la escena de transición
	var transition_scene_resource = load(transition_scene)
	
	if transition_scene_resource:
		var transition_instance = transition_scene_resource.instantiate()
		
		# Configurar la escena destino
		transition_instance.next_scene = next_scene
		
		# Agregar a la escena actual
		get_tree().current_scene.add_child(transition_instance)
		
		print("Pantalla de transición creada exitosamente")
		print("El jugador debe presionar ENTER para ir al nivel 2")
	else:
		print("ERROR: No se pudo cargar la escena de transición")
		# Fallback seguro
		get_tree().change_scene_to_file(next_scene)
