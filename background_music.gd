extends AudioStreamPlayer

@export var music_type: String = "normal"  # "normal" o "boss"
@export var audio_stream_normal: AudioStream
@export var audio_stream_boss: AudioStream

func _ready():
	# Cargar música según tipo
	var target_stream = audio_stream_normal
	var target_volume = -10
	
	if music_type == "boss":
		target_stream = audio_stream_boss
		target_volume = -5
	
	# Si no hay stream asignado, buscar por ruta
	if target_stream == null:
		target_stream = load_default_stream()
	
	if target_stream:
		stream = target_stream
		
		# Configurar propiedades
		if stream:
			stream.loop = true
			volume_db = target_volume
			
			# Reproducir
			if not playing:
				play()
				print("Música ", music_type, " iniciada - Volumen: ", volume_db, "dB")
			else:
				print("Música ", music_type, " ya estaba reproduciéndose")
		else:
			print("ERROR: Stream de música es null para tipo: ", music_type)
	else:
		print("ADVERTENCIA: No se pudo cargar música para tipo: ", music_type)

func load_default_stream() -> AudioStream:
	# Intentar cargar archivos por defecto
	var stream_path = ""
	
	if music_type == "normal":
		stream_path = "res://Walking_Home/assets/audio/normal_music.ogg"
	elif music_type == "boss":
		stream_path = "res://Walking_Home/assets/audio/boss_music.ogg"
	
	if ResourceLoader.exists(stream_path):
		print("Cargando música desde: ", stream_path)
		return load(stream_path)
	
	print("ERROR: No se encontró archivo en: ", stream_path)
	return null

func change_music(new_type: String):
	if new_type != music_type:
		music_type = new_type
		
		# Recargar con nuevo tipo
		stop()
		_ready()

func _exit_tree():
	# Detener música al salir
	stop()
