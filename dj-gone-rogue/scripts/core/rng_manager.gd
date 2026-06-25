extends Node
class_name GameplayRngManager

var _rng := RandomNumberGenerator.new()
var seed_string := ""
var numeric_seed := 1


func _ready() -> void:
	if seed_string.is_empty():
		set_seed_from_string(Config.DEFAULT_SEED)


func set_seed_from_string(value: String) -> void:
	seed_string = value.strip_edges()
	if seed_string.is_empty():
		seed_string = Config.DEFAULT_SEED
	numeric_seed = _stable_seed_hash(seed_string)
	_rng.seed = numeric_seed


func rand_int_range(a: int, b: int) -> int:
	var low := mini(a, b)
	var high := maxi(a, b)
	return _rng.randi_range(low, high)


func rand_float() -> float:
	return _rng.randf()


func choice(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[rand_int_range(0, values.size() - 1)]


func shuffle_array(values: Array) -> Array:
	var result := values.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rand_int_range(0, i)
		var swap_value: Variant = result[i]
		result[i] = result[j]
		result[j] = swap_value
	return result


func shuffle_array_in_place(values: Array) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rand_int_range(0, i)
		var swap_value: Variant = values[i]
		values[i] = values[j]
		values[j] = swap_value


func get_state_snapshot() -> Dictionary:
	return {
		"seed_string": seed_string,
		"numeric_seed": numeric_seed,
		"rng_state": _rng.state,
	}


func restore_state_snapshot(snapshot: Dictionary) -> void:
	seed_string = str(snapshot.get("seed_string", Config.DEFAULT_SEED))
	numeric_seed = int(snapshot.get("numeric_seed", _stable_seed_hash(seed_string)))
	_rng.seed = numeric_seed
	_rng.state = int(snapshot.get("rng_state", _rng.state))


func _stable_seed_hash(value: String) -> int:
	var hash_value := 5381
	for i in range(value.length()):
		hash_value = ((hash_value * 33) + value.unicode_at(i)) % 2147483647
	if hash_value <= 0:
		hash_value = 1
	return hash_value
