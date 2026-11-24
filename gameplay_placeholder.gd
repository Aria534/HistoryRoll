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
const CERTIFICATE_SCENE: String = "res://certificate.tscn"
const LevelCatalog = preload("res://level_catalog.gd")
const BoardRules = preload("res://board_rules.gd")
const DiceRoller = preload("res://dice_roller.gd")
const QuizSession = preload("res://quiz_session.gd")
const QuizQuestionBank = preload("res://quiz_question_bank.gd")
const LevelCompletionCard = preload("res://level_completion_card.gd")
const TERRACE_BACKGROUND: Texture2D = preload("res://assets/gameplay_ui/forest_parchment/background.png")

@export var shuffle_questions: bool = true
@export var dice_animation_steps: int = 8
@export var dice_animation_interval: float = 0.06
@export var movement_step_duration: float = 0.14
@export var tile_effect_duration: float = 0.55
@export var enable_test_dice_controls: bool = false

@onready var background: TextureRect = $Background
@onready var gameplay_body: VBoxContainer = $MarginContainer/Content/BodyCenter/Body
@onready var board_view: Control = %BoardView
@onready var board_panel: PanelContainer = $MarginContainer/Content/BodyCenter/Body/BoardPanel
@onready var level_label: Label = %LevelLabel
@onready var position_label: Label = %PositionLabel
@onready var score_label: Label = %ScoreLabel
@onready var power_status_label: Label = %PowerStatusLabel
@onready var state_label: Label = %StateLabel
@onready var question_popup_layer: Control = %QuestionPopupLayer
@onready var quiz_panel: PanelContainer = %QuizPanel
@onready var fixture_notice: Label = %FixtureNotice
@onready var question_label: Label = %QuestionLabel
@onready var answers_grid: GridContainer = $QuestionPopupLayer/QuizPanel/QuizMargin/QuizContent/Answers
@onready var turn_message_label: Label = %TurnMessageLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var reaction_popup: PanelContainer = %ReactionPopup
@onready var reaction_face: TextureRect = %ReactionFace
@onready var reaction_title: Label = %ReactionTitle
@onready var reaction_score: Label = %ReactionScore
@onready var dice_label: Label = %DiceLabel
@onready var roll_button: Button = %RollButton
@onready var next_turn_button: Button = %NextTurnButton
@onready var back_button: Button = %BackButton
@onready var results_panel: LevelCompletionCard = %ResultsPanel
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
var incorrect_answer_penalty: int = 2
var bonus_points: int = 0
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
var fatal_error_active: bool = false
var landing_effect_resolved: bool = false
var resolved_tiles_this_turn: Dictionary = {}
var progress_manager: Node
var scene_change_handler: Callable
var results_transition_started: bool = false
var dice_roller
var quiz_session = QuizSession.new()
var question_popup_tween: Tween
var reaction_tween: Tween


func _ready() -> void:
	_request_music("res://assets/audio/music/gameplay.ogg")
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
	resized.connect(_update_gameplay_layout)
	_initialize_gameplay()
	_update_gameplay_layout.call_deferred()


func _request_music(track_path: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music"):
		audio_manager.call("play_music", track_path, 0.6)


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
	_apply_level_background()
	board_config = level_data.get("board", {})
	var config_errors: PackedStringArray = board_view.configure(board_config)
	if not config_errors.is_empty():
		_show_fatal_error("Invalid board configuration:\n%s" % "\n".join(config_errors))
		return
	tile_count = BoardRules.get_tile_count(board_config)
	correct_answer_points = maxi(0, int(level_data.get("correct_answer_points", 10)))
	incorrect_answer_penalty = maxi(0, int(level_data.get("incorrect_answer_penalty", 2)))
	bonus_points = maxi(0, int(level_data.get("bonus_points", 0)))
	snake_score_penalty = maxi(0, int(level_data.get("snake_score_penalty", 0)))
	allow_negative_score = bool(level_data.get("allow_negative_score", false))
	maximum_shield_charges = maxi(0, int(level_data.get("maximum_shield_charges", 0)))
	maximum_effect_depth = maxi(1, int(level_data.get("maximum_effect_depth", 12)))
	resolve_destination_effects = bool(level_data.get("resolve_destination_effects", true))
	if not quiz_session.configure(QuizQuestionBank.get_questions_for_level(level_id, "regular"), shuffle_questions):
		_show_fatal_error("No valid regular questions are configured for this level.")
		return

	level_label.text = str(level_data.get("title", "LEVEL %d" % level_id)).to_upper()
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
	fatal_error_active = false
	results_transition_started = false
	landing_effect_resolved = false
	resolved_tiles_this_turn.clear()
	results_panel.hide()
	board_view.set_player_position_immediate(player_position)
	board_view.set_hero_tokens(
		str(level_data.get("hero_name", "Hero")),
		str(level_data.get("portrait_path", "")),
		str(level_data.get("waiting_hero_name", "FINAL TROPHY")),
		str(level_data.get("waiting_hero_portrait_path", "")),
		level_id == LevelCatalog.get_highest_level_id()
	)
	board_view.reset_dice_display()
	_update_status_labels()
	dice_label.text = "—"
	turn_message_label.text = "Answer the question to begin."
	_begin_question("regular")


func _apply_level_background() -> void:
	# The shared gameplay skin changes scenery only, never level rules/content.
	background.texture = TERRACE_BACKGROUND


func _begin_question(question_type: String) -> void:
	current_question_type = question_type
	current_question = quiz_session.next_question()
	if current_question.is_empty():
		_show_fatal_error("The quiz could not provide a %s question." % question_type)
		return
	question_label.text = str(current_question.get("question_text", ""))
	fixture_notice.visible = question_label.text.begins_with("DEVELOPMENT PLACEHOLDER")
	fixture_notice.text = "DEVELOPMENT QUESTION FIXTURE — NOT FINAL CONTENT"
	reaction_popup.hide()
	turn_message_label.hide()
	feedback_label.hide()
	question_label.show()
	answer_buttons[0].get_parent().show()
	var choices: Array = current_question.get("choices", [])
	if choices.size() < 2 or choices.size() > answer_buttons.size():
		_show_fatal_error("The current question has an invalid number of answer choices.")
		return
	_apply_question_typography(choices)
	# Typography chooses a balanced row or full-width answers for longer text.
	for index: int in range(answer_buttons.size()):
		var answer_button := answer_buttons[index]
		answer_button.visible = index < choices.size()
		answer_button.text = str(choices[index]) if answer_button.visible else ""
		answer_button.modulate = Color.WHITE
	feedback_label.text = ""
	next_turn_button.hide()
	next_turn_button.text = "Continue"
	_set_quiz_panel_height(true)
	_set_state(GameplayState.QUESTION)
	_show_question_popup()


func _apply_question_typography(choices: Array) -> void:
	var question_text := question_label.text.strip_edges()
	var question_length := question_text.length()
	var question_font_size := 34
	if question_length > 55:
		question_font_size = 28
	if question_length > 95:
		question_font_size = 23
	question_label.text = question_text
	question_label.add_theme_font_size_override("font_size", question_font_size)
	var panel_width := get_viewport_rect().size.x * (quiz_panel.anchor_right - quiz_panel.anchor_left)
	var panel_style := quiz_panel.get_theme_stylebox("panel")
	var content_width := panel_width - panel_style.get_content_margin(SIDE_LEFT) - panel_style.get_content_margin(SIDE_RIGHT)
	var inset := question_label.get_theme_stylebox("normal")
	var question_width := maxf(32.0, content_width - inset.get_content_margin(SIDE_LEFT) - inset.get_content_margin(SIDE_RIGHT))
	var question_font := question_label.get_theme_font("font")
	var question_text_height := question_font.get_multiline_string_size(question_text, HORIZONTAL_ALIGNMENT_CENTER, question_width, question_font_size).y
	question_label.custom_minimum_size.y = maxf(74.0, ceilf(question_text_height) + 12.0)

	var longest_choice := 0
	for choice: Variant in choices:
		longest_choice = maxi(longest_choice, str(choice).length())
	var answer_font_size := 25
	if longest_choice > 24:
		answer_font_size = 23
	if longest_choice > 36:
		answer_font_size = 21
	var answer_columns := choices.size() if choices.size() <= 3 else 2
	var column_width := (content_width - answers_grid.get_theme_constant("h_separation") * (answer_columns - 1)) / maxi(1, answer_columns)
	# Keep short choices together, but give long answers the full parchment width
	# instead of squeezing three or more lines into a narrow button.
	if choices.size() > 2:
		for index: int in range(choices.size()):
			var sample_button := answer_buttons[index]
			var sample_style := sample_button.get_theme_stylebox("normal")
			var sample_width := maxf(32.0, column_width - sample_style.get_content_margin(SIDE_LEFT) - sample_style.get_content_margin(SIDE_RIGHT))
			var sample_font := sample_button.get_theme_font("font")
			var sample_height := sample_font.get_multiline_string_size(str(choices[index]), HORIZONTAL_ALIGNMENT_CENTER, sample_width, answer_font_size).y
			if sample_height > sample_font.get_height(answer_font_size) * 2.0 + 1.0:
				answer_columns = 1
				column_width = content_width
				break
	answers_grid.columns = answer_columns
	for index: int in range(answer_buttons.size()):
		var answer_button := answer_buttons[index]
		answer_button.add_theme_font_size_override("font_size", answer_font_size)
		var answer_style := answer_button.get_theme_stylebox("normal")
		var answer_width := maxf(32.0, column_width - answer_style.get_content_margin(SIDE_LEFT) - answer_style.get_content_margin(SIDE_RIGHT))
		var answer_text := str(choices[index]) if index < choices.size() else ""
		var answer_font := answer_button.get_theme_font("font")
		var answer_text_height := answer_font.get_multiline_string_size(answer_text, HORIZONTAL_ALIGNMENT_CENTER, answer_width, answer_font_size).y
		# Keep wrapped lettering inside the illustrated green inset, including
		# its transparent top/bottom padding and thick golden rim.
		answer_button.custom_minimum_size.y = maxf(84.0, ceilf(answer_text_height / 0.58) + 12.0)


func _on_answer_pressed(choice_index: int) -> void:
	if state != GameplayState.QUESTION:
		return
	var result: Dictionary = quiz_session.submit_answer(choice_index)
	if not bool(result.get("accepted", false)):
		return
	_set_state(GameplayState.ANSWER_FEEDBACK)
	var is_correct := bool(result.get("correct", false))
	_play_answer_sound(is_correct)
	var correct_index := int(result.get("correct_index", -1))
	if correct_index >= 0 and correct_index < answer_buttons.size():
		answer_buttons[correct_index].modulate = Color("#a8df9f")
	if not is_correct:
		answer_buttons[choice_index].modulate = Color("#e7a1a1")

	if is_correct:
		correct_answers += 1
		score += correct_answer_points
		feedback_label.text = "Correct! +%d points." % correct_answer_points
		_show_chibi_reaction(true, correct_answer_points)
	else:
		incorrect_answers += 1
		score -= incorrect_answer_penalty
		if not allow_negative_score:
			score = maxi(0, score)
		feedback_label.text = "Incorrect. -%d points." % incorrect_answer_penalty
		_show_chibi_reaction(false, incorrect_answer_penalty)
	feedback_label.show()
	_set_popup_height(520.0)
	_update_status_labels()
	_set_state(GameplayState.READY_TO_ROLL)
	await get_tree().create_timer(0.95).timeout
	if state == GameplayState.READY_TO_ROLL:
		reaction_popup.hide()
		await _hide_question_popup()


func _play_answer_sound(is_correct: bool) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	var method := "play_correct_answer" if is_correct else "play_incorrect_answer"
	if audio_manager.has_method(method):
		audio_manager.call(method)


func _on_roll_pressed() -> void:
	if state != GameplayState.READY_TO_ROLL:
		return
	_set_state(GameplayState.DICE_ROLLING)
	await _hide_question_popup()
	landing_effect_resolved = false
	resolved_tiles_this_turn.clear()
	var dice_result: int = dice_roller.roll()
	dice_label.text = "..."
	await board_view.animate_dice_result(dice_result, dice_animation_steps, dice_animation_interval)
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
		_begin_next_turn("You rolled %d. An exact roll is needed to reach tile %d." % [dice_result, tile_count])
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
		_begin_next_turn("Tile-effect safety limit reached.")
		return
	if resolved_tiles_this_turn.has(player_position):
		_begin_next_turn("Tile %d was already resolved this turn." % player_position)
		return
	resolved_tiles_this_turn[player_position] = true
	var effect := BoardRules.get_primary_tile_effect(board_config, player_position)
	match str(effect.get("type", "normal")):
		"bonus":
			_collect_bonus()
		"shield":
			_collect_shield()
		"ladder", "snake":
			await _apply_snake_or_ladder(effect, depth)
		_:
			_begin_next_turn(landing_feedback)


func _collect_bonus() -> void:
	score += bonus_points
	bonus_score_increase += bonus_points
	_update_status_labels()
	_begin_next_turn("Bonus Tile! +%d points. (Amount is configurable.)" % bonus_points)


func _collect_shield() -> void:
	var previous_charges := shield_charges
	shield_charges += 1
	if maximum_shield_charges > 0:
		shield_charges = mini(shield_charges, maximum_shield_charges)
	if shield_charges > previous_charges:
		shields_collected += 1
	_update_status_labels()
	_begin_next_turn("Shield acquired! Shield count: %d." % shield_charges)


func _apply_snake_or_ladder(effect: Dictionary, depth: int) -> void:
	_set_state(GameplayState.RESOLVING_TILE)
	var effect_type := str(effect.get("type", ""))
	var effect_destination := int(effect.get("to", player_position))
	if effect_type == "snake" and shield_charges > 0:
		shield_charges -= 1
		shields_consumed += 1
		_update_status_labels()
		_begin_next_turn("Shield protected you from the snake on tile %d." % player_position)
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
		_begin_next_turn(effect_feedback)


func _begin_next_turn(message: String) -> void:
	fixture_notice.hide()
	next_turn_button.hide()
	turn_message_label.text = message
	_begin_question("regular")


func _complete_level() -> void:
	if completion_recorded or results_transition_started:
		return
	_set_state(GameplayState.LEVEL_COMPLETE)
	question_popup_layer.hide()
	_request_music("res://assets/audio/music/victory.ogg")
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
	return_button.text = "Continue"
	return_button.disabled = false
	results_panel.present_completion(level_id, score, bonus_score_increase)


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
	return


func _on_back_pressed() -> void:
	if state != GameplayState.READY_TO_ROLL and state != GameplayState.QUESTION:
		return
	get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE)


func _on_return_pressed() -> void:
	if state != GameplayState.LEVEL_COMPLETE or results_transition_started:
		return
	results_transition_started = true
	return_button.disabled = true
	if fatal_error_active:
		_change_scene(LEVEL_SELECTION_SCENE)
		return
	progress_manager.finish_level_results(level_id)
	if level_id == 6 and progress_manager.has_method("is_certificate_unlocked") and progress_manager.is_certificate_unlocked():
		_change_scene(CERTIFICATE_SCENE)
	else:
		_change_scene(LEVEL_SELECTION_SCENE)


func _change_scene(path: String) -> void:
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		get_tree().change_scene_to_file(path)


func _set_state(new_state: GameplayState) -> void:
	state = new_state
	state_label.text = "?  %s" % GameplayState.keys()[state].capitalize()
	for button: Button in answer_buttons:
		button.disabled = state != GameplayState.QUESTION or not button.visible
	var roll_is_ready := state == GameplayState.READY_TO_ROLL
	roll_button.disabled = not roll_is_ready
	roll_button.visible = true
	if state == GameplayState.QUESTION:
		roll_button.text = "Roll Dice"
		roll_button.tooltip_text = "Choose an answer before rolling the die."
	elif state == GameplayState.READY_TO_ROLL:
		roll_button.text = "Roll Dice"
		roll_button.tooltip_text = "Roll the die and move your hero."
		roll_button.grab_focus()
	else:
		roll_button.text = "Rolling..." if state == GameplayState.DICE_ROLLING else "Roll Dice"
		roll_button.tooltip_text = "Please wait for the current turn to finish."
	back_button.disabled = state in [
		GameplayState.DICE_ROLLING,
		GameplayState.PLAYER_MOVING,
		GameplayState.RESOLVING_TILE,
		GameplayState.LEVEL_COMPLETE,
	]
	if state != GameplayState.ANSWER_FEEDBACK:
		next_turn_button.hide()
	var roll_title: Label = $BottomRollArea/RollButton/RollVisual/RollContents/RollTitle
	roll_title.text = roll_button.text
	roll_title.modulate = Color("#C9DDE5") if roll_button.disabled else Color.WHITE


func _show_chibi_reaction(correct: bool, points: int) -> void:
	if reaction_tween != null and reaction_tween.is_valid():
		reaction_tween.kill()
	reaction_face.texture = _get_reaction_face_texture(correct)
	reaction_face.modulate = Color.WHITE
	reaction_title.text = "HOORAY!" if correct else "OH NO!"
	reaction_score.text = "%s%d POINTS" % ["+" if correct else "-", points]
	reaction_popup.add_theme_stylebox_override("panel", _make_reaction_style(correct))
	reaction_popup.show()
	reaction_popup.pivot_offset = reaction_popup.size * 0.5
	reaction_popup.scale = Vector2(0.62, 0.62)
	reaction_popup.modulate.a = 0.0
	reaction_face.rotation = -0.08 if correct else 0.06
	reaction_face.position.y = 0.0
	reaction_tween = create_tween().set_parallel(true)
	reaction_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reaction_tween.tween_property(reaction_popup, "scale", Vector2.ONE, 0.28)
	reaction_tween.tween_property(reaction_popup, "modulate:a", 1.0, 0.18)
	reaction_tween.tween_property(reaction_face, "rotation", 0.08 if correct else -0.035, 0.32)
	if correct:
		reaction_tween.tween_property(reaction_face, "position:y", -7.0, 0.25)
	else:
		reaction_tween.tween_property(reaction_face, "position:y", 7.0, 0.32)


func _get_reaction_face_texture(correct: bool) -> Texture2D:
	var portrait_path := str(level_data.get("portrait_path", ""))
	var hero_asset_id := portrait_path.get_file().trim_suffix("_chibi.png").to_lower()
	if hero_asset_id.is_empty():
		hero_asset_id = str(level_data.get("hero_id", "")).strip_edges().to_lower()
	var expression := "happy" if correct else "sad"
	var expression_path := "res://assets/gameplay_chibis/reactions/%s_%s.png" % [hero_asset_id, expression]
	if not hero_asset_id.is_empty() and ResourceLoader.exists(expression_path, "Texture2D"):
		return load(expression_path) as Texture2D
	# Keep gameplay functional if a future level has no expression art yet.
	return board_view.player_sprite.texture


func _make_reaction_style(correct: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#176B38") if correct else Color("#743242")
	style.border_color = Color("#FFD45A") if correct else Color("#E6A56C")
	style.set_border_width_all(6)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.05, 0.02, 0.01, 0.62)
	style.shadow_size = 12
	style.content_margin_left = 28.0
	style.content_margin_top = 22.0
	style.content_margin_right = 28.0
	style.content_margin_bottom = 22.0
	return style


func _update_status_labels() -> void:
	position_label.text = "Position: %d/%d" % [player_position, tile_count]
	score_label.text = "Score: %d" % score
	power_status_label.text = "Shield: %d" % shield_charges


func _set_quiz_panel_height(_quiz_active: bool) -> void:
	_update_gameplay_layout()


func _update_question_popup_layout() -> void:
	if current_question.is_empty() or fatal_error_active:
		return
	var choices: Array = current_question.get("choices", [])
	if choices.size() < 2:
		return
	# Widen the existing popup while retaining enough room for its entrance
	# overshoot; controls and artwork share the same responsive bounds.
	quiz_panel.anchor_left = 0.01
	quiz_panel.anchor_right = 0.99
	_apply_question_typography(choices)
	var answer_columns := answers_grid.columns
	var answer_rows := ceili(float(choices.size()) / answer_columns)
	var answer_height := 0.0
	for index: int in range(choices.size()):
		answer_height = maxf(answer_height, answer_buttons[index].custom_minimum_size.y)
	var content_height := question_label.custom_minimum_size.y + answer_height * answer_rows
	content_height += answers_grid.get_theme_constant("v_separation") * (answer_rows - 1)
	content_height += $QuestionPopupLayer/QuizPanel/QuizMargin/QuizContent.get_theme_constant("separation")
	if fixture_notice.visible:
		content_height += fixture_notice.get_minimum_size().y + 12.0
	# The crest occupies the top 24%; the footer/curls occupy the bottom 30%.
	# Reserve those proportions even when a four-choice or long-text popup grows.
	var popup_height := maxf(520.0 if choices.size() >= 4 else 450.0, ceilf((content_height + 8.0) / 0.46))
	popup_height = minf(popup_height, get_viewport_rect().size.y - 100.0)
	var style := quiz_panel.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	style.content_margin_top = popup_height * 0.24 + 4.0
	style.content_margin_bottom = popup_height * 0.30 + 4.0
	quiz_panel.add_theme_stylebox_override("panel", style)
	_set_popup_height(popup_height)


func _update_gameplay_layout() -> void:
	if not is_node_ready() or board_view.columns <= 0 or board_view.rows <= 0:
		return
	var screen_size := get_viewport_rect().size
	var margin := clampf(screen_size.x * 0.045, 18.0, 52.0)
	var content_margin: MarginContainer = $MarginContainer
	content_margin.offset_left = margin
	content_margin.offset_right = -margin
	content_margin.offset_top = screen_size.y * 0.175
	content_margin.offset_bottom = -screen_size.y * 0.245
	var width := screen_size.x - margin * 2.0
	var logo: TextureRect = $MarginContainer/Content/HistoryRollBrand
	# The reference leaves the sky open and uses only the Back icon above play.
	logo.hide()
	$MarginContainer/Content.add_theme_constant_override("separation", 0)
	$MarginContainer/Content/BodyCenter.size_flags_vertical = Control.SIZE_FILL
	var gap := clampi(int(screen_size.y * 0.012), 12, 24)
	gameplay_body.add_theme_constant_override("separation", gap)
	gameplay_body.custom_minimum_size.x = width
	var status_height := clampf(width * 0.11, 68.0, 112.0)
	$MarginContainer/Content/BodyCenter/Body/StatusRow.custom_minimum_size.y = status_height
	# Match the reference's taller board. Grid visuals and token destinations
	# share its fitted cell rectangles; catalog counts and rules stay intact.
	board_panel.custom_minimum_size.y = screen_size.y * 0.49
	var back_side := clampf(width * 0.105, 76.0, 104.0)
	back_button.custom_minimum_size = Vector2.ONE * back_side
	back_button.size = Vector2.ONE * back_side
	back_button.position = Vector2(0, screen_size.y * 0.038 - content_margin.offset_top)
	back_button.add_theme_constant_override("icon_max_width", int(back_side * 0.76))
	var label_size := clampi(int(width * 0.035), 19, 34)
	for label: Label in [position_label, score_label, power_status_label]:
		label.size_flags_vertical = Control.SIZE_FILL
		label.add_theme_font_size_override("font_size", label_size)
		label.add_theme_color_override("font_color", Color("#FFF1C4"))
		var icon := label.get_child(0) as TextureRect
		icon.offset_left = 6.0
		icon.offset_right = status_height * 0.60
		var status_style := label.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		status_style.content_margin_left = icon.offset_right + 6.0
		status_style.content_margin_right = 12.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var lettering_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
		label.custom_minimum_size.x = lettering_width + icon.offset_right + 24.0
		status_style.border_color = Color("#EFC574")
		label.add_theme_stylebox_override("normal", status_style)
	var roll_height := screen_size.y * 0.11
	var roll_title: Label = $BottomRollArea/RollButton/RollVisual/RollContents/RollTitle
	roll_title.add_theme_font_size_override("font_size", clampi(int(width * 0.082), 40, 88))
	$BottomRollArea/RollButton/RollVisual/RollContents/DieIcon.custom_minimum_size = Vector2.ONE * roll_height * 0.58
	_align_status_icons.call_deferred()
	_update_question_popup_layout()


func _align_status_icons() -> void:
	for label: Label in [position_label, score_label, power_status_label]:
		var icon := label.get_child(0) as TextureRect
		var icon_width := icon.size.x
		var font_size := label.get_theme_font_size("font_size")
		var lettering_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var right_padding := label.get_theme_stylebox("normal").content_margin_right
		# Keep the icon beside its caption after the HBox has allocated widths.
		icon.offset_right = label.size.x - right_padding - lettering_width - 10.0
		icon.offset_left = icon.offset_right - icon_width


func _set_popup_height(popup_height: float) -> void:
	quiz_panel.custom_minimum_size.y = popup_height
	quiz_panel.offset_top = -popup_height * 0.5
	quiz_panel.offset_bottom = popup_height * 0.5


func _show_question_popup() -> void:
	if question_popup_tween != null and question_popup_tween.is_valid():
		question_popup_tween.kill()
	question_popup_layer.show()
	question_popup_layer.modulate.a = 0.0
	quiz_panel.pivot_offset = quiz_panel.size * 0.5
	quiz_panel.scale = Vector2(0.88, 0.88)
	question_popup_tween = create_tween().set_parallel(true)
	question_popup_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	question_popup_tween.tween_property(question_popup_layer, "modulate:a", 1.0, 0.22)
	question_popup_tween.tween_property(quiz_panel, "scale", Vector2.ONE, 0.26)


func _hide_question_popup() -> void:
	if not question_popup_layer.visible:
		return
	if question_popup_tween != null and question_popup_tween.is_valid():
		question_popup_tween.kill()
	question_popup_tween = create_tween().set_parallel(true)
	question_popup_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	question_popup_tween.tween_property(question_popup_layer, "modulate:a", 0.0, 0.16)
	question_popup_tween.tween_property(quiz_panel, "scale", Vector2(0.94, 0.94), 0.16)
	await question_popup_tween.finished
	question_popup_layer.hide()
	reaction_popup.hide()
	question_popup_layer.modulate.a = 1.0
	quiz_panel.scale = Vector2.ONE


func _show_fatal_error(message: String) -> void:
	fatal_error_active = true
	question_popup_layer.hide()
	feedback_label.text = message
	question_label.text = "Gameplay cannot start."
	_set_state(GameplayState.LEVEL_COMPLETE)
	return_button.text = "BACK TO LEVEL SELECTION"
	results_label.text = message
	results_panel.present_error(message)
