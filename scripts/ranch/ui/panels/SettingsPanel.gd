extends PanelContainer

@onready var master_volume_slider = $VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider = $VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider = $VBoxContainer/SfxVolumeSlider
@onready var test_button = $VBoxContainer/TestButton

func _ready():
	master_volume_slider.value_changed.connect(AudioManager.set_master_volume)
	music_volume_slider.value_changed.connect(AudioManager.set_music_volume)
	sfx_volume_slider.value_changed.connect(AudioManager.set_sfx_volume)
	test_button.pressed.connect(_on_test_button_pressed)

	# Initialize slider values from AudioManager
	master_volume_slider.value = linear_to_db(AudioManager.master_volume)
	music_volume_slider.value = linear_to_db(AudioManager.music_volume)
	sfx_volume_slider.value = linear_to_db(AudioManager.sfx_volume)
	
	hide()

func _on_test_button_pressed():
	AudioManager.play_sfx("ui_click.ogg")

func open_panel():
	show()
	AudioManager.play_sfx("ui_confirm.ogg")

func close_panel():
	hide()
	AudioManager.play_sfx("ui_click.ogg")


func _on_close_button_pressed() -> void:
	close_panel()
