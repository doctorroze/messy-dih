extends Node
class_name PrototypeDebugTools


func add_money(amount: int = 25) -> void:
	RunState.add_money(amount)
	RunState.last_result_message = "Debug added $%d." % amount


func heal_resources() -> void:
	RunState.hands_remaining = Config.HANDS_PER_STOP
	RunState.discards_remaining = Config.DISCARDS_PER_STOP
	RunState.last_result_message = "Debug restored hands and discards."
	RunState.notify_piles_changed()


func add_random_gear() -> void:
	var gear := GameData.get_random_gear()
	if RunState.add_gear(gear):
		RunState.last_result_message = "Debug added Gear: %s." % gear.display_name


func jump_to_next_stop() -> void:
	if not TourManager.run_active:
		return
	if not RunState.advance_stop_pointer():
		TourManager.win_run()
		return
	RunState.run_flags["phase"] = "map"
	RunState.last_result_message = "Debug jumped to next stop."


func force_boss(boss_id: String) -> void:
	var boss := GameData.get_boss_by_id(boss_id)
	if boss != null:
		RunState.current_boss = boss
		RunState.last_result_message = "Debug forced boss: %s." % boss.display_name


func print_deck() -> void:
	DeckManager.print_pile_snapshot()


func run_tests() -> void:
	print("Running prototype debug tests")
	HandEvaluator.run_debug_tests()
	var rng_snapshot := RngManager.get_state_snapshot()
	RngManager.set_seed_from_string("debug-seed")
	var snapshot_a := RngManager.shuffle_array([1, 2, 3, 4, 5, 6, 7, 8])
	RngManager.set_seed_from_string("debug-seed")
	var snapshot_b := RngManager.shuffle_array([1, 2, 3, 4, 5, 6, 7, 8])
	RngManager.restore_state_snapshot(rng_snapshot)
	print("Deterministic seed reproduction: %s" % str(snapshot_a == snapshot_b))
