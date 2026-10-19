extends SceneTree

const DiceRoller = preload("res://dice_roller.gd")

const SAMPLE_SIZE: int = 60000
# Chi-square critical value for 5 degrees of freedom at alpha = 0.001.
# This deliberately tests for a substantial departure instead of treating an
# ordinary amount of random sample variation as a failure.
const CHI_SQUARE_CRITICAL: float = 20.515

var _failed: bool = false


func _init() -> void:
	var dice = DiceRoller.new()
	var frequencies: Array[int] = [0, 0, 0, 0, 0, 0]
	var previous_result: int = 0
	var consecutive_identical_pairs: int = 0

	_check(not dice.controlled_results_enabled(), "normal gameplay dice has deterministic controls disabled")
	for roll_index: int in range(SAMPLE_SIZE):
		var result: int = dice.roll()
		if result < 1 or result > 6:
			_failed = true
			push_error("Dice result outside 1 through 6 at roll %d: %d" % [roll_index + 1, result])
			continue
		frequencies[result - 1] += 1
		if result == previous_result:
			consecutive_identical_pairs += 1
		previous_result = result

	var observed_total: int = 0
	for frequency: int in frequencies:
		observed_total += frequency
	var expected: float = float(SAMPLE_SIZE) / 6.0
	var chi_square: float = 0.0
	for frequency: int in frequencies:
		var difference: float = float(frequency) - expected
		chi_square += difference * difference / expected

	print("Dice sample size: %d" % SAMPLE_SIZE)
	print("Expected per face: %.2f (theoretical probability 1/6)" % expected)
	for face: int in range(1, 7):
		var frequency: int = frequencies[face - 1]
		var percentage: float = float(frequency) * 100.0 / float(SAMPLE_SIZE)
		print("Face %d: %d (%.3f%%)" % [face, frequency, percentage])
	print("Consecutive identical pairs: %d" % consecutive_identical_pairs)
	print("Chi-square: %.6f (df=5, substantial-departure threshold=%.3f, alpha=0.001)" % [chi_square, CHI_SQUARE_CRITICAL])

	_check(observed_total == SAMPLE_SIZE, "exactly one valid result was recorded per roll")
	for face: int in range(1, 7):
		_check(frequencies[face - 1] > 0, "face %d appeared in the sample" % face)
	_check(consecutive_identical_pairs > 0, "consecutive identical results occur naturally")
	_check(chi_square < CHI_SQUARE_CRITICAL, "distribution has no substantial departure from uniformity")

	var controlled_dice = DiceRoller.new(12345, true)
	if OS.is_debug_build():
		_check(controlled_dice.controlled_results_enabled(), "deterministic controls require explicit debug opt-in")
		var controlled_results: Array[int] = [6, 2]
		controlled_dice.set_controlled_results(controlled_results)
		_check(controlled_dice.roll() == 6, "debug test control returns its first configured value")
		_check(controlled_dice.roll() == 2, "debug test control returns its second configured value")
	else:
		_check(not controlled_dice.controlled_results_enabled(), "release builds reject deterministic controls")

	print("Dice fairness test: %s" % ("FAILED" if _failed else "PASSED"))
	quit(1 if _failed else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_failed = true
		push_error("FAIL: %s" % description)
