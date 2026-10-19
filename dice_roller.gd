extends RefCounted

var _random := RandomNumberGenerator.new()
var _controlled_results: Array[int] = []
var _allow_controlled_results: bool = false


func _init(seed_value: int = 0, allow_controlled_results: bool = false) -> void:
	_allow_controlled_results = allow_controlled_results and OS.is_debug_build()
	if seed_value == 0:
		_random.randomize()
	else:
		_random.seed = seed_value


func roll() -> int:
	if _allow_controlled_results and not _controlled_results.is_empty():
		return _controlled_results.pop_front()
	return _random.randi_range(1, 6)


func set_controlled_results(results: Array[int]) -> void:
	if not _allow_controlled_results:
		push_warning("Controlled dice results are disabled outside the test configuration.")
		return
	_controlled_results.clear()
	for result: int in results:
		if result >= 1 and result <= 6:
			_controlled_results.append(result)


func controlled_results_enabled() -> bool:
	return _allow_controlled_results
