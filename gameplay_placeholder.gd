extends Control

enum GameplayState {
	LOADING,
	READY_TO_ROLL,
	DICE_ROLLING,
	PLAYER_MOVING,
	RESOLVING_TILE,
	QUESTION,
	ANSWER_FEEDBACK,
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
@export var enable_test_dice_controls: bool = false

@onready var board_view: Control = %BoardView
@onready var level_label: Label = %LevelLabel
@onready var position_label: Label = %PositionLabel
@onready var score_label: Label = %ScoreLabel
@onready var power_status_label: Label = %PowerStatusLabel
@onready var state_label: Label = %StateLabel
@onready var quiz_panel: PanelContainer = $MarginContainer/Content/QuizPanel
@onready var fixture_notice: Label = %FixtureNotice
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
var player_position: int = 1
var score: int = 0
var correct_answer_points: int = 100
var incorrect_answer_points: int = 0
var snake_score_penalty: int = 50
var allow_negative_score: bool = false
var maximum_shield_charges: int = 0
var maximum_effect_depth: int = 12
var resolve_destination_effects: bool = true
var shield_charges: int = 0
var correct_answers: int = 0
var incorrect_answers: int = 0
var bonus_correct_answers: int = 0
var bonus_incorrect_answers: int = 0
var bonus_score_increase: int = 0
var snake_penalties: int = 0
var snake_penalty_events: int = 0
var shields_collected: int = 0
var shields_consumed: int = 0
var current_question: Dictionary = {}
var current_question_type: String = "regular"
var completion_recorded: bool = false
var landing_effect_resolved: bool = false
var resolved_tiles_this_turn: Dictionary = {}
var progress_manager: Node
var dice_roller
var quiz_session = QuizSession.new()
var bonus_quiz_session = QuizSession.new()


func _ready() -> void:
	dice_roller = DiceRoller.new(0, enable_test_dice_controls and OS.is_debug_build())
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
	if not enable_test_dice_controls or not OS.is_debug_build():
		push_warning("Controlled dice results are available only in debug test configurations.")
		return
	dice_roller.set_controlled_results(results)


func _initialize_gameplay() -> void:
	_set_state(GameplayState.LOADING)
	level_id = int(progress_manager.selected_level)
	level_data = LevelCatalog.get_level(level_id)
	if level_data.is_empty() or not LevelCatalog.is_level_playable(level_id):
		_show_fatal_error("The selected level is not configured for gameplay.")
		return
	board_config = level_data.get("board", {})
	var config_errors: PackedStringArray = board_view.configure(board_config)
	if not config_errors.is_empty():
		_show_fatal_error("Invalid board configuration:\n%s" % "\n".join(config_errors))
		return
	tile_count = BoardRules.get_tile_count(board_config)
	correct_answer_points = maxi(0, int(level_data.get("correct_answer_points", 100)))
	incorrect_answer_points = maxi(0, int(level_data.get("incorrect_answer_points", 0)))
	snake_score_penalty = maxi(0, int(level_data.get("snake_score_penalty", 50)))
	allow_negative_score = bool(level_data.get("allow_negative_score", false))
	maximum_shield_charges = maxi(0, int(level_data.get("maximum_shield_charges", 0)))
	maximum_effect_depth = maxi(1, int(level_data.get("maximum_effect_depth", 12)))
	resolve_destination_effects = bool(level_data.get("resolve_destination_effects", true))
	if not quiz_session.configure(QuizFixtures.get_questions_for_level(level_id, "regular"), shuffle_questions):
		_show_fatal_error("No valid regular quiz fixtures are configured for this level.")
		return
	if not bonus_quiz_session.configure(QuizFixtures.get_questions_for_level(level_id, "bonus"), shuffle_questions):
		_show_fatal_error("No valid bonus quiz fixtures are configured for this level.")
		return

	level_label.text = "%s — TEST CONTENT" % str(level_data.get("title", "LEVEL %d" % level_id)).to_upper()
	player_position = 1
	score = 0
	shield_charges = 0
	correct_answers = 0
	incorrect_answers = 0
	bonus_correct_answers = 0
	bonus_incorrect_answers = 0
	bonus_score_increase = 0
	snake_penalties = 0
	snake_penalty_events = 0
	shields_collected = 0
	shields_consumed = 0
	completion_recorded = false
	landing_effect_resolved = false
	resolved_tiles_this_turn.clear()
	results_panel.hide()
	board_view.set_player_position_immediate(player_position)
	_update_status_labels()
	dice_label.text = "—"
	_prepare_for_roll("Roll the die to begin. Questions appear only after landing on ? or Bonus tiles.")


func _begin_question(question_type: String) -> void:
	current_question_type = question_type
	current_question = (
		bonus_quiz_session.next_question()
		if question_type == "bonus"
		else quiz_session.next_question()
	)
	if current_question.is_empty():
		_show_fatal_error("The quiz could not provide a %s question." % question_type)
		return
	question_label.text = str(current_question.get("question_text", ""))
	fixture_notice.show()
	question_label.show()
	answer_buttons[0].get_parent().show()
	var choices: Array = current_question.get("choices", [])
	for index: int in range(answer_buttons.size()):
		answer_buttons[index].text = str(choices[index])
		answer_buttons[index].modulate = Color.WHITE
	feedback_label.text = (
		"Bonus question: a correct answer doubles your current score."
		if question_type == "bonus"
		else "Choose one answer. Correct answers earn %d points." % correct_answer_points
	)
	next_turn_button.hide()
	next_turn_button.text = "Continue"
	_set_quiz_panel_height(true)
	_set_state(GameplayState.QUESTION)


func _on_answer_pressed(choice_index: int) -> void:
	if state != GameplayState.QUESTION:
		return
	var active_session = bonus_quiz_session if current_question_type == "bonus" else quiz_session
	var result: Dictionary = active_session.submit_answer(choice_index)
	if not bool(result.get("accepted", false)):
		return
	_set_state(GameplayState.ANSWER_FEEDBACK)
	var is_correct := bool(result.get("correct", false))
	var explanation := str(result.get("explanation", ""))
	var correct_index := int(result.get("correct_index", -1))
	if correct_index >= 0 and correct_index < answer_buttons.size():
		answer_buttons[correct_index].modulate = Color("#a8df9f")
	if not is_correct:
		answer_buttons[choice_index].modulate = Color("#e7a1a1")

	if is_correct:
		correct_answers += 1
		if current_question_type == "bonus":
			bonus_correct_answers += 1
			var previous_score := score
			score *= 2
			var increase := score - previous_score
			bonus_score_increase += increase
			feedback_label.text = "Correct bonus answer! Score %d × 2 = %d. %s" % [previous_score, score, explanation]
		else:
			score += correct_answer_points
			feedback_label.text = "Correct! +%d points. %s" % [correct_answer_points, explanation]
	else:
		incorrect_answers += 1
		if current_question_type == "bonus":
			bonus_incorrect_answers += 1
			feedback_label.text = "Not quite. Your score remains %d. %s" % [score, explanation]
		else:
			score += incorrect_answer_points
			feedback_label.text = "Not quite. +%d points. %s" % [incorrect_answer_points, explanation]
	_update_status_labels()
	next_turn_button.show()


func _on_roll_pressed() -> void:
	if state != GameplayState.READY_TO_ROLL:
		return
	_set_state(GameplayState.DICE_ROLLING)
	landing_effect_resolved = false
	resolved_tiles_this_turn.clear()
	var dice_result: int = dice_roller.roll()
	for step: int in range(maxi(1, dice_animation_steps)):
		dice_label.text = str((dice_result + step) % 6 + 1)
		await get_tree().create_timer(maxf(0.0, dice_animation_interval)).timeout
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
		_prepare_for_roll("You rolled %d. An exact roll is needed to reach tile %d." % [dice_result, tile_count])
		return
	_set_state(GameplayState.PLAYER_MOVING)
	for tile: int in range(player_position + 1, destination + 1):
		await board_view.animate_player_to(tile, movement_step_duration)
		player_position = tile
		_update_status_labels()
	await _resolve_landing_tile("You moved to tile %d." % player_position)


func _resolve_landing_tile(landing_feedback: String) -> void:
	if landing_effect_resolved:
		return
	landing_effect_resolved = true
	await _resolve_current_tile(landing_feedback, 0)


func _resolve_current_tile(landing_feedback: String, depth: int) -> void:
	_set_state(GameplayState.RESOLVING_TILE)
	if player_position == tile_count:
		_complete_level()
		return
	if depth >= maximum_effect_depth:
		_prepare_for_roll("Tile-effect safety limit reached. Roll again.")
		return
	if resolved_tiles_this_turn.has(player_position):
		_prepare_for_roll("Tile %d was already resolved this turn. Roll again." % player_position)
		return
	resolved_tiles_this_turn[player_position] = true
	var effect := BoardRules.get_primary_tile_effect(board_config, player_position)
	match str(effect.get("type", "normal")):
		"question":
			_begin_question("regular")
		"bonus":
			_begin_question("bonus")
		"shield":
			_collect_shield()
		"ladder", "snake":
			await _apply_snake_or_ladder(effect, depth)
		_:
			_prepare_for_roll("%s Roll again." % landing_feedback)


func _collect_shield() -> void:
	var previous_charges := shield_charges
	shield_charges += 1
	if maximum_shield_charges > 0:
		shield_charges = mini(shield_charges, maximum_shield_charges)
	if shield_charges > previous_charges:
		shields_collected += 1
	_update_status_labels()
	_prepare_for_roll("Shield acquired! Shield count: %d. Roll again." % shield_charges)


func _apply_snake_or_ladder(effect: Dictionary, depth: int) -> void:
	_set_state(GameplayState.RESOLVING_TILE)
	var effect_type := str(effect.get("type", ""))
	var effect_destination := int(effect.get("to", player_position))
	if effect_type == "snake" and shield_charges > 0:
		shield_charges -= 1
		shields_consumed += 1
		_update_status_labels()
		_prepare_for_roll("Shield protected you from the snake on tile %d. No score penalty was applied." % player_position)
		return

	var effect_feedback := "Ladder! Climb to tile %d." % effect_destination
	if effect_type == "snake":
		var applied_penalty := snake_score_penalty
		if not allow_negative_score:
			applied_penalty = mini(score, snake_score_penalty)
		score -= applied_penalty
		snake_penalties += applied_penalty
		snake_penalty_events += 1
		effect_feedback = "Snake! Slide to tile %d and lose %d points." % [effect_destination, applied_penalty]
	feedback_label.text = effect_feedback
	_update_status_labels()
	await board_view.animate_player_to(effect_destination, tile_effect_duration)
	player_position = effect_destination
	_update_status_labels()
	if player_position == tile_count:
		_complete_level()
	elif resolve_destination_effects:
		await _resolve_current_tile(effect_feedback, depth + 1)
	else:
		_prepare_for_roll("%s Roll again." % effect_feedback)


func _prepare_for_roll(message: String) -> void:
	fixture_notice.hide()
	question_label.hide()
	if not answer_buttons.is_empty():
		answer_buttons[0].get_parent().hide()
	next_turn_button.hide()
	feedback_label.text = message
	_set_quiz_panel_height(false)
	_set_state(GameplayState.READY_TO_ROLL)


func _complete_level() -> void:
	_set_state(GameplayState.LEVEL_COMPLETE)
	var requires_progression: bool = not bool(progress_manager.is_level_completed(level_id))
	if not completion_recorded:
		completion_recorded = true
		progress_manager.record_board_completion(level_id, score, get_gameplay_statistics())
	results_label.text = (
		"LEVEL %d COMPLETE!\n\nFinal score: %d\nCorrect answers: %d\nIncorrect answers: %d\n"
		+ "Bonus score gained: %d\nSnake penalties: %d\nShields: %d collected / %d used"
	) % [
		level_id, score, correct_answers, incorrect_answers, bonus_score_increase,
		snake_penalties, shields_collected, shields_consumed,
	]
	return_button.text = "Continue to Story" if requires_progression else "Return to Level Selection"
	results_panel.show()


func get_gameplay_statistics() -> Dictionary:
	return {
		"correct_answers": correct_answers,
		"incorrect_answers": incorrect_answers,
		"bonus_correct_answers": bonus_correct_answers,
		"bonus_incorrect_answers": bonus_incorrect_answers,
		"bonus_score_increase": bonus_score_increase,
		"snake_penalties": snake_penalties,
		"snake_penalty_events": snake_penalty_events,
		"shields_collected": shields_collected,
		"shields_consumed": shields_consumed,
		"position": player_position,
	}


func _on_next_turn_pressed() -> void:
	if state != GameplayState.ANSWER_FEEDBACK:
		return
	_prepare_for_roll("Question complete. Roll the die for your next turn.")


func _on_back_pressed() -> void:
	if state != GameplayState.READY_TO_ROLL:
		return
	get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE)


func _on_return_pressed() -> void:
	if state != GameplayState.LEVEL_COMPLETE:
		return
	if progress_manager.is_level_completed(level_id):
		get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE)
	elif progress_manager.begin_post_level_story(level_id):
		get_tree().change_scene_to_file(STORY_MODE_SCENE)


func _set_state(new_state: GameplayState) -> void:
	state = new_state
	state_label.text = GameplayState.keys()[state].capitalize()
	for button: Button in answer_buttons:
		button.disabled = state != GameplayState.QUESTION
	roll_button.disabled = state != GameplayState.READY_TO_ROLL
	back_button.disabled = state != GameplayState.READY_TO_ROLL
	if state != GameplayState.ANSWER_FEEDBACK:
		next_turn_button.hide()


func _update_status_labels() -> void:
	position_label.text = "Position: %d / %d" % [player_position, tile_count]
	score_label.text = "Score: %d" % score
	power_status_label.text = "Shield: %d" % shield_charges


func _set_quiz_panel_height(quiz_active: bool) -> void:
	quiz_panel.custom_minimum_size.y = 430.0 if quiz_active else 230.0


func _show_fatal_error(message: String) -> void:
	feedback_label.text = message
	question_label.text = "Gameplay cannot start."
	_set_state(GameplayState.LEVEL_COMPLETE)
	return_button.text = "Return to Level Selection"
	results_label.text = message
	results_panel.show()
