extends Control

enum GameplayState {
	LOADING,
	QUESTION,
	ANSWER_FEEDBACK,
	READY_TO_ROLL,
	DICE_ROLLING,
	PLAYER_MOVING,
	TILE_EFFECT,
	LEVEL_COMPLETE,
}

const LEVEL_SELECTION_SCENE: String = "res://level_selection.tscn"
const STORY_MODE_SCENE: String = "res://story_mode.tscn"
const LevelCatalog = preload("res://level_catalog.gd")
const BoardRules = preload("res://board_rules.gd")
const DiceRoller = preload("res://dice_roller.gd")
const QuizSession = preload("res://quiz_session.gd")
const QuizFixtures = preload("res://quiz_test_fixtures.gd")

@export var shuffle_questions: bool = true
@export var dice_animation_steps: int = 8
@export var dice_animation_interval: float = 0.06
@export var movement_step_duration: float = 0.14
@export var tile_effect_duration: float = 0.55

@onready var board_view: Control = %BoardView
@onready var level_label: Label = %LevelLabel
@onready var position_label: Label = %PositionLabel
@onready var state_label: Label = %StateLabel
@onready var question_label: Label = %QuestionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var dice_label: Label = %DiceLabel
@onready var roll_button: Button = %RollButton
@onready var next_turn_button: Button = %NextTurnButton
@onready var back_button: Button = %BackButton
@onready var results_panel: PanelContainer = %ResultsPanel
@onready var results_label: Label = %ResultsLabel
@onready var return_button: Button = %ReturnButton

var answer_buttons: Array[Button] = []
var state: GameplayState = GameplayState.LOADING
var level_id: int = 1
var level_data: Dictionary = {}
var board_config: Dictionary = {}
var tile_count: int = 0
var player_position: int = 0
var current_question: Dictionary = {}
var completion_recorded: bool = false
var progress_manager: Node
var dice_roller = DiceRoller.new()
var quiz_session = QuizSession.new()


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	answer_buttons = [%AnswerButton0, %AnswerButton1, %AnswerButton2, %AnswerButton3]
	for index: int in range(answer_buttons.size()):
		answer_buttons[index].pressed.connect(_on_answer_pressed.bind(index))
	roll_button.pressed.connect(_on_roll_pressed)
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	back_button.pressed.connect(_on_back_pressed)
	return_button.pressed.connect(_on_return_pressed)
	_initialize_gameplay()


func set_controlled_dice_results(results: Array[int]) -> void:
	dice_roller.set_controlled_results(results)


func _initialize_gameplay() -> void:
	_set_state(GameplayState.LOADING)
	level_id = int(progress_manager.selected_level)
	level_data = LevelCatalog.get_level(level_id)
	if level_data.is_empty():
		_show_fatal_error("The selected level is not configured.")
		return

	board_config = level_data.get("board", {})
	var config_errors: PackedStringArray = board_view.configure(board_config)
	if not config_errors.is_empty():
		_show_fatal_error("Invalid board configuration:\n%s" % "\n".join(config_errors))
		return
	tile_count = BoardRules.get_tile_count(board_config)

	var questions := QuizFixtures.get_questions_for_level(level_id)
	if not quiz_session.configure(questions, shuffle_questions):
		_show_fatal_error("No valid quiz fixtures are configured for this level.")
		return

	level_label.text = "LEVEL %d — TEST CONTENT" % level_id
	player_position = 0
	completion_recorded = false
	results_panel.hide()
	board_view.set_player_position_immediate(player_position)
	_update_position_label()
	_begin_question()


func _begin_question() -> void:
	current_question = quiz_session.next_question()
	if current_question.is_empty():
		_show_fatal_error("The quiz could not provide a question.")
		return

	question_label.text = str(current_question.get("question_text", ""))
	var choices: Array = current_question.get("choices", [])
	for index: int in range(answer_buttons.size()):
		answer_buttons[index].text = str(choices[index])
		answer_buttons[index].modulate = Color.WHITE
	feedback_label.text = "Choose one answer. A correct answer unlocks the die."
	dice_label.text = "—"
	next_turn_button.hide()
	_set_state(GameplayState.QUESTION)


func _on_answer_pressed(choice_index: int) -> void:
	if state != GameplayState.QUESTION:
		return
	var result: Dictionary = quiz_session.submit_answer(choice_index)
	if not bool(result.get("accepted", false)):
		return

	_set_state(GameplayState.ANSWER_FEEDBACK)
	var explanation := str(result.get("explanation", ""))
	var correct_index := int(result.get("correct_index", -1))
	if bool(result.get("correct", false)):
		answer_buttons[choice_index].modulate = Color("#a8df9f")
		feedback_label.text = "Correct! %s You may roll the die." % explanation
		_set_state(GameplayState.READY_TO_ROLL)
	else:
		answer_buttons[choice_index].modulate = Color("#e7a1a1")
		if correct_index >= 0 and correct_index < answer_buttons.size():
			answer_buttons[correct_index].modulate = Color("#a8df9f")
		feedback_label.text = "Not quite. %s No roll this turn." % explanation
		next_turn_button.text = "Next Question"
		next_turn_button.show()


func _on_roll_pressed() -> void:
	if state != GameplayState.READY_TO_ROLL:
		return
	_set_state(GameplayState.DICE_ROLLING)
	for step: int in range(max(1, dice_animation_steps)):
		dice_label.text = str(step % 6 + 1)
		await get_tree().create_timer(max(0.0, dice_animation_interval)).timeout

	var dice_result: int = dice_roller.roll()
	dice_label.text = str(dice_result)
	await _resolve_roll(dice_result)


func _resolve_roll(dice_result: int) -> void:
	var destination := BoardRules.calculate_normal_destination(
		player_position,
		dice_result,
		tile_count,
		bool(board_config.get("exact_finish", true))
	)
	if destination == player_position:
		feedback_label.text = "You rolled %d. An exact roll is needed to reach tile %d." % [dice_result, tile_count]
		_finish_turn()
		return

	_set_state(GameplayState.PLAYER_MOVING)
	for tile: int in range(player_position + 1, destination + 1):
		await board_view.animate_player_to(tile, movement_step_duration)
		player_position = tile
		_update_position_label()

	var effect := BoardRules.get_tile_effect(board_config, player_position)
	if not effect.is_empty():
		_set_state(GameplayState.TILE_EFFECT)
		var effect_type := str(effect.get("type", ""))
		var effect_destination := int(effect.get("to", player_position))
		feedback_label.text = (
			"Ladder! Climb to tile %d." if effect_type == "ladder"
			else "Snake! Slide to tile %d."
		) % effect_destination
		await board_view.animate_player_to(effect_destination, tile_effect_duration)
		player_position = effect_destination
		_update_position_label()

	if player_position == tile_count:
		_complete_level()
	else:
		if effect.is_empty():
			feedback_label.text = "You moved to tile %d." % player_position
		_finish_turn()


func _finish_turn() -> void:
	_set_state(GameplayState.ANSWER_FEEDBACK)
	next_turn_button.text = "Next Question"
	next_turn_button.show()


func _complete_level() -> void:
	_set_state(GameplayState.LEVEL_COMPLETE)
	if not completion_recorded:
		completion_recorded = true
		progress_manager.mark_level_completed(level_id)

	var next_level_id: int = LevelCatalog.get_next_level_id(level_id)
	results_label.text = "LEVEL %d COMPLETE!\n\n" % level_id
	if next_level_id > 0:
		results_label.text += "Level %d is now unlocked." % next_level_id
	else:
		results_label.text += "No additional level is configured yet."
	results_panel.show()


func _on_next_turn_pressed() -> void:
	if state != GameplayState.ANSWER_FEEDBACK:
		return
	_begin_question()


func _on_back_pressed() -> void:
	if state in [GameplayState.DICE_ROLLING, GameplayState.PLAYER_MOVING, GameplayState.TILE_EFFECT]:
		return
	get_tree().change_scene_to_file(STORY_MODE_SCENE)


func _on_return_pressed() -> void:
	if state == GameplayState.LEVEL_COMPLETE:
		get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE)


func _set_state(new_state: GameplayState) -> void:
	state = new_state
	state_label.text = GameplayState.keys()[state].capitalize()
	for button: Button in answer_buttons:
		button.disabled = state != GameplayState.QUESTION
	roll_button.disabled = state != GameplayState.READY_TO_ROLL
	back_button.disabled = state in [
		GameplayState.DICE_ROLLING,
		GameplayState.PLAYER_MOVING,
		GameplayState.TILE_EFFECT,
	]
	if state != GameplayState.ANSWER_FEEDBACK:
		next_turn_button.hide()


func _update_position_label() -> void:
	position_label.text = "Position: %s / %d" % ["Start" if player_position == 0 else str(player_position), tile_count]


func _show_fatal_error(message: String) -> void:
	feedback_label.text = message
	question_label.text = "Gameplay cannot start."
	_set_state(GameplayState.LEVEL_COMPLETE)
	return_button.text = "Return to Level Selection"
	results_label.text = message
	results_panel.show()
