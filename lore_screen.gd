extends Node2D  # ← CAMBIAR si tu nodo raíz es diferente

@onready var canvas = $CanvasLayer
var next_scene: String = "res://main.tscn"
var can_continue: bool = false

func _ready():
	print("=== LORE SCREEN INICIADA ===")
	
	# Asegurar posición
	canvas.layer = 100
	
	# Tomar focus
	set_process_input(true)
	
	# Delay inicial
	await get_tree().create_timer(0.5).timeout
	can_continue = true
	
	print("✓ Lista para continuar")

func _input(event):
	if can_continue and event.is_action_pressed("ui_accept"):
		print("Cambiando a: ", next_scene)
		get_tree().change_scene_to_file(next_scene)

func _exit_tree():
	print("Lore screen destruida")
