extends Node

const SCREEN_WIDTH = 576
const CHUNK_WIDTH = 600
const CHUNK_HEIGHT = 250
const CHUNK_MARGINS = 50
const CHUNK_X_OFFSET = -(CHUNK_WIDTH - SCREEN_WIDTH) / 2
const CHANGE_INTERVAL = 50
const CENTER_CHANGE_VARIANCE = 25
const WIDTH_NOISE_VARIANCE = 25
const WIDTH_MIN = 90
const WIDTH_MAX = 300
const WIDTH_START = 450

const FALL_SPEED_START = 300
const FALL_SPEED_MAX = 800
const PIXELS_PER_DEPTH_UNIT = 50

const SAVE_FILE = "user://save.dat"
const SAVE_FIELDS = ["first_run", "gold", "max_depth", "slow_time", "missiles", "missile_bounces", "shields", "gold_multiplier"]

enum PowerUpType { SLOW_TIME, MISSILE, SHIELD, GOLD_MULT }

const Missile = preload("res://player/Missile.tscn")
const Explosion = preload("res://player/Explosion.tscn")
const PowerUp = preload("res://level/PowerUp.tscn")

var noise := OpenSimplexNoise.new()
var rng := RandomNumberGenerator.new()

var first_run = true
var gold = 0
var last_depth = 0
var max_depth = 0

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

func _init():
	load_game()

func _ready():
	rng.randomize()
	
	for up in upgrades:
		var e = Expression.new()
		e.parse(upgrades[up], ["level"])
		upgrades[up] = e

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
	
