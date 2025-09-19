extends CanvasLayer

# Referencias a nodos
@onready var life_bar = $HUD/LifeBar/AnimatedSprite2D
@onready var special_bar = $HUD/Special/AnimatedSprite2D

func _ready():
	# Inicializar con valores por defecto
	update_health(11)
	update_special(7)

func update_health(value):
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
	# Mostrar game over
	$GameOver.visible = true
	# Pausar el juego
	get_tree().paused = true
