extends CanvasLayer

@onready var boton_iniciar = $BotonIniciar
@onready var boton_salir = $BotonSalir

func _ready():
	# Conectar señales de los botones
	boton_iniciar.pressed.connect(_on_boton_iniciar_pressed)
	boton_salir.pressed.connect(_on_boton_salir_pressed)
	
	# Asegurar que el menú se vea bien
	boton_iniciar.grab_focus()

func _on_boton_iniciar_pressed():
	print("Mostrando pantalla de lore...")
	
	# Cambiar a la pantalla de lore
	get_tree().change_scene_to_file("res://lore_screen.tscn")

func _on_boton_salir_pressed():
	print("Saliendo del juego...")
	get_tree().quit()
