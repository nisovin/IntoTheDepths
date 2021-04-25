extends Node

const SCREEN_WIDTH = 576
const CHUNK_WIDTH = 600
const CHUNK_HEIGHT = 250
const CHUNK_MARGINS = 50
const CHUNK_X_OFFSET = -(CHUNK_WIDTH - SCREEN_WIDTH) / 2
const CHANGE_INTERVAL = 50
const TRANSITION_CHUNKS = 10
const TRANSITION_TIME = 10
const CENTER_CHANGE_VARIANCE = 25
const WIDTH_NOISE_VARIANCE = 25
const WIDTH_MIN = 100
const WIDTH_MAX = 300
const WIDTH_START = 450

const FALL_SPEED_START = 300
const FALL_SPEED_MAX = 1000
const PIXELS_PER_DEPTH_UNIT = 50

const SAVE_FILE = "user://save.dat"
const SAVE_FIELDS = ["first_run", "gold", "max_depth", "slow_time", "missiles", "missile_bounces", "shields", "gold_multiplier"]

enum PowerUpType { SLOW_TIME, MISSILE, SHIELD, GOLD_MULT }

const Missile = preload("res://player/Missile.tscn")
const Explosion = preload("res://player/Explosion.tscn")
const PowerUp = preload("res://level/PowerUp.tscn")

const Sounds = {
	"rollover": preload("res://audio/rollover.wav"),
	"click": preload("res://audio/click.wav"),
	"boop1": preload("res://audio/boop1.wav"),
	"boop2": preload("res://audio/boop2.wav"),
	"explode": preload("res://audio/explode.wav"),
	"fire": preload("res://audio/fire.wav"),
	"powerup_gold": preload("res://audio/powerup_gold.wav"),
	"powerup_missile": preload("res://audio/powerup_missile.wav"),
	"powerup_shield": preload("res://audio/powerup_shield.wav"),
	"powerup_slow": preload("res://audio/powerup_slow.wav")
}

var noise := OpenSimplexNoise.new()
var rng := RandomNumberGenerator.new()

var first_run = true
var collected_slow = false
var collected_missile = false
var using_controller = false
var device = 0
var gold = 0
var last_depth = 0
var max_depth = 0
var last_texture = null

var slow_time = 0
var missiles = 0
var missile_bounces = 0
var shields = 0
var gold_multiplier = 0

var upgrades = {
	"slow_time": "100 + level * level * 100",
	"missiles": "200 + level * level * 150",
	"missile_bounces": "500 + level * level * 300",
	"shields": "500 + level * level * 500",
	"gold_multiplier": "pow(5, level) * 1000"
}

var powerups = {
	PowerUpType.SLOW_TIME: 10,
	PowerUpType.MISSILE: 10,
	PowerUpType.SHIELD: 3,
	PowerUpType.GOLD_MULT: 2
}

var music_player
var audio_players = []

func _init():
	load_game()

func _ready():
	rng.randomize()
	
	for up in upgrades:
		var e = Expression.new()
		e.parse(upgrades[up], ["level"])
		upgrades[up] = e

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.stream = preload("res://audio/music.ogg")
	add_child(music_player)
	for i in 10:
		var audio = AudioStreamPlayer.new()
		audio.bus = "SFX"
		add_child(audio)
		audio_players.append(audio)

func noise_1d(v):
	#return 0
	return noise.get_noise_1d(v)

func save_game():
	var data = {}
	for field in SAVE_FIELDS:
		data[field] = get(field)
	var file = File.new()
	file.open(SAVE_FILE, File.WRITE)
	file.store_var(data)
	file.close()
	
func load_game():
	var file = File.new()
	if file.file_exists(SAVE_FILE):
		file.open(SAVE_FILE, File.READ)
		var data = file.get_var()
		print(data)
		if data:
			for field in SAVE_FIELDS:
				if field in data:
					set(field, data[field])
		file.close()
	
func rand_weighted(options):
	var total_weight = 0
	for option in options:
		total_weight += options[option]
	var rand = rng.randf_range(0, total_weight)
	for option in options:
		rand -= options[option]
		if rand < 0:
			return option
	return options.keys()[0]
	
func play_music():
	if not music_player.playing:
		music_player.play()
	
func play_audio(sound):
	for a in audio_players:
		if not a.playing:
			a.stream = Sounds[sound]
			a.play()
			return

func _unhandled_key_input(event):
	if event.pressed and event.scancode == KEY_F11:
		OS.window_fullscreen = not OS.window_fullscreen
