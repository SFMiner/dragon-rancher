extends Node

var sfx_player_pool: Array[AudioStreamPlayer]
var music_player: AudioStreamPlayer
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var previous_money: int = 0

const SFX_PLAYER_COUNT = 4
const SFX_PATH = "res://assets/audio/sfx/"
const MUSIC_PATH = "res://assets/audio/music/"

func _ready():
	for i in range(SFX_PLAYER_COUNT):
		var player = AudioStreamPlayer.new()
		add_child(player)
		sfx_player_pool.append(player)
	
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	RanchState.egg_created.connect(_on_egg_created)
	RanchState.egg_hatched.connect(_on_egg_hatched)
	RanchState.order_completed.connect(_on_order_completed)
	RanchState.money_changed.connect(_on_money_changed)
	RanchState.reputation_increased.connect(_on_reputation_increased)
	RanchState.facility_built.connect(_on_facility_built)

func _on_egg_created(_egg):
	play_sfx("egg_created.ogg")

func _on_egg_hatched(_egg_id: String, _dragon_id: String):
	play_sfx("egg_hatched.ogg")

func _on_order_completed(_order_id: String, _payment: int):
	play_sfx("order_completed.ogg")

func _on_money_changed(new_total: int):
	if new_total > previous_money:
		play_sfx("money_gain.ogg")
	previous_money = new_total

func _on_reputation_increased(_amount):
	play_sfx("unlock.ogg")

func _on_facility_built(_facility):
	play_sfx("build.ogg")

func play_sfx(sfx_name: String):
	var sfx_path = SFX_PATH + sfx_name
	if not FileAccess.file_exists(sfx_path):
		printerr("SFX file not found: " + sfx_path)
		return

	for player in sfx_player_pool:
		if not player.playing:
			player.stream = load(sfx_path)
			player.volume_db = linear_to_db(sfx_volume * master_volume)
			player.play()
			return
	
	# All players are busy, maybe add a warning here if needed
	# print("All SFX players are busy.")

func play_music(track_name: String, loop: bool = true):
	var music_path = MUSIC_PATH + track_name
	if not ResourceLoader.exists(music_path):
		printerr("Music file not found: " + music_path)
		return

	if music_player.playing:
		music_player.stop()

	var stream = load(music_path)
	if stream == null:
		printerr("Failed to load music: " + music_path)
		return

	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	if music_player.stream:
		music_player.stream.loop = loop
	music_player.play()

func set_master_volume(db: float):
	master_volume = db_to_linear(db)
	update_volumes()
	SaveSystem.trigger_autosave_if_enabled()

func set_music_volume(db: float):
	music_volume = db_to_linear(db)
	update_volumes()
	SaveSystem.trigger_autosave_if_enabled()

func set_sfx_volume(db: float):
	sfx_volume = db_to_linear(db)
	update_volumes()
	SaveSystem.trigger_autosave_if_enabled()

func update_volumes():
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	for player in sfx_player_pool:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

# TODO: Connect to SaveSystem to load/save volume settings
