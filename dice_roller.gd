extends RefCounted

var _random := RandomNumberGenerator.new()
var _controlled_results: Array[int] = []


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_random.randomize()
	else:
		_random.seed = seed_value


func roll() -> int:
	if not _controlled_results.is_empty():
		return _controlled_results.pop_front()
	return _random.randi_range(1, 6)


func set_controlled_results(results: Array[int]) -> void:
	_controlled_results.clear()
	for result: int in results:
		if result >= 1 and result <= 6:
			_controlled_results.append(result)
