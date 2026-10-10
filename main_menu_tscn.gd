extends Control

# =========================================================
# HISTORYROLL - MAIN MENU
# =========================================================

@export var start_game_scene: String = "res://level_selection.tscn"
@export var hero_cards_scene: String = "res://HeroCards.tscn"
@export var achievement_scene: String = "res://Achievements.tscn"


func _ready():
	# Connect buttons
	$StartButton.pressed.connect(_on_start_pressed)
	$HeroCardsButton.pressed.connect(_on_hero_cards_pressed)
	$AchievementButton.pressed.connect(_on_achievement_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)


# =========================================================
# START GAME
# =========================================================

func _on_start_pressed():
	print("Start Game pressed!")

	if ResourceLoader.exists(start_game_scene):
		get_tree().change_scene_to_file(start_game_scene)
	else:
		print("START GAME SCENE NOT FOUND: ", start_game_scene)


# =========================================================
# HERO CARDS
# =========================================================

func _on_hero_cards_pressed():
	print("Hero Cards pressed!")

	if ResourceLoader.exists(hero_cards_scene):
		get_tree().change_scene_to_file(hero_cards_scene)
	else:
		print("HERO CARDS SCENE NOT FOUND: ", hero_cards_scene)


# =========================================================
# ACHIEVEMENTS
# =========================================================

func _on_achievement_pressed():
	print("Achievements pressed!")

	if ResourceLoader.exists(achievement_scene):
		get_tree().change_scene_to_file(achievement_scene)
	else:
		print("ACHIEVEMENTS SCENE NOT FOUND: ", achievement_scene)


# =========================================================
# QUIT GAME
# =========================================================

func _on_quit_pressed():
	print("Quit Game pressed!")
	get_tree().quit()
