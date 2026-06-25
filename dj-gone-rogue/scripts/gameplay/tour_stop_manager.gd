extends Node
class_name GameplayTourStopManager

signal tour_state_changed()
signal stop_completed()
signal shop_opened()

var boss_order: Array[BossData] = []
var run_active := false
var run_finished := false
var won_run := false


func start_run(seed_string: String, album_deck_id: String) -> void:
	DeckManager.start_new_run(seed_string, album_deck_id)
	boss_order = GameData.get_boss_order_for_run()
	run_active = true
	run_finished = false
	won_run = false
	RunState.run_flags["phase"] = "map"
	RunState.last_result_message = "Run started."
	emit_signal("tour_state_changed")


func begin_current_stop() -> void:
	var stop_type := RunState.get_next_stop_type()
	var boss := get_current_boss() if stop_type == Config.STOP_EUROPE else null
	RunState.begin_stop(stop_type, boss)
	RunState.run_flags["phase"] = "play"
	RunState.run_flags["encore_pending"] = false
	RunState.run_flags["encore_met"] = false
	if boss != null and boss.effect_type == GameData.BOSS_ZERO_DISCARDS:
		RunState.discards_remaining = 0
	DeckManager.reset_draw_pile_from_deck(true)
	DeckManager.draw_to_hand_size()
	RunState.last_result_message = "Started %s." % Config.get_stop_display_name(stop_type)
	emit_signal("tour_state_changed")


func play_selected_hand() -> Dictionary:
	if RunState.selected_cards.is_empty():
		return _result(false, "Select 1-5 Tracks first.", "play")
	if RunState.selected_cards.size() > 5:
		return _result(false, "Play at most 5 Tracks.", "play")
	if RunState.hands_remaining <= 0:
		return _result(false, "No hands remaining.", "play")

	var selected := RunState.selected_cards.duplicate()
	var breakdown := ScoringEngine.score_cards(selected)
	var hype := int(breakdown["final_hype"])
	RunState.current_hype += hype
	RunState.hands_remaining -= 1
	RunState.previous_hand_types_this_stop.append(str(breakdown["hand_type"]))
	ScoringEngine.after_hand_scored(str(breakdown["hand_type"]))
	DeckManager.discard_cards(selected)
	DeckManager.draw_to_hand_size()

	var message := "%s scored %d Crowd Hype." % [breakdown["hand_display_name"], hype]
	RunState.last_result_message = message

	var completion := _check_stop_completion(hype)
	if completion["complete"]:
		return _complete_stop(completion["message"])

	if RunState.hands_remaining <= 0:
		return lose_run("Tour stop failed. Crowd Hype target missed.")

	emit_signal("tour_state_changed")
	return _result(true, message, "play")


func discard_selected_cards() -> Dictionary:
	if RunState.selected_cards.is_empty():
		return _result(false, "Select Tracks to discard.", "play")
	if RunState.discards_remaining <= 0:
		return _result(false, "No discards remaining.", "play")
	DeckManager.discard_selected_cards()
	RunState.discards_remaining -= 1
	RunState.discards_used_this_stop += 1
	_apply_discard_gear()
	DeckManager.draw_to_hand_size()
	RunState.last_result_message = "Discarded selected Tracks."
	emit_signal("tour_state_changed")
	return _result(true, RunState.last_result_message, "play")


func leave_shop_to_map() -> void:
	if not run_active:
		return
	var still_running := RunState.advance_stop_pointer()
	if not still_running:
		win_run()
		return
	RunState.run_flags["phase"] = "map"
	RunState.last_result_message = "Next stop ready."
	emit_signal("tour_state_changed")


func get_current_boss() -> BossData:
	if boss_order.is_empty():
		return null
	var index := clampi(RunState.current_leg - 1, 0, boss_order.size() - 1)
	return boss_order[index]


func get_current_map_summary() -> Dictionary:
	var boss := get_current_boss()
	return {
		"leg": RunState.current_leg,
		"stop_type": RunState.get_next_stop_type(),
		"stop_display_name": Config.get_stop_display_name(RunState.get_next_stop_type()),
		"target_hype": Config.get_target_hype(RunState.current_leg, RunState.get_next_stop_type()),
		"boss": boss,
	}


func lose_run(reason: String) -> Dictionary:
	run_finished = true
	won_run = false
	RunState.run_flags["phase"] = "end"
	RunState.last_result_message = reason
	RunState.mark_run_lost(reason)
	tour_state_changed.emit()
	return _result(false, reason, "end")


func win_run() -> void:
	run_finished = true
	won_run = true
	RunState.run_flags["phase"] = "end"
	RunState.last_result_message = "World tour complete."
	RunState.mark_run_won()
	tour_state_changed.emit()


func _check_stop_completion(last_hype: int) -> Dictionary:
	if RunState.current_boss != null and RunState.current_boss.effect_type == GameData.BOSS_ENCORE:
		var required := int(ceil(RunState.target_hype * float(RunState.current_boss.parameters.get("required_ratio", 0.1))))
		if bool(RunState.run_flags.get("encore_pending", false)):
			if last_hype >= required:
				RunState.run_flags["encore_met"] = true
				return {"complete": true, "message": "Encore cleared."}
			return {"complete": false, "message": "Encore needs at least %d Crowd Hype." % required}
		if RunState.current_hype >= RunState.target_hype:
			RunState.run_flags["encore_pending"] = true
			RunState.last_result_message = "Target reached. Encore needs %d Crowd Hype." % required
			return {"complete": false, "message": RunState.last_result_message}

	if RunState.current_hype >= RunState.target_hype:
		return {"complete": true, "message": "Target reached."}
	return {"complete": false, "message": ""}


func _complete_stop(message: String) -> Dictionary:
	var reward := RunState.earn_stop_reward()
	var gold := _pay_gold_plating()
	var final_message := "%s Reward: $%d" % [message, reward]
	if gold > 0:
		final_message += " Gold Plating: $%d" % gold
	RunState.last_result_message = final_message

	if RunState.current_leg == Config.TOUR_LEGS and RunState.current_stop_type == Config.STOP_EUROPE:
		win_run()
		return _result(true, final_message, "end")

	ShopGenerator.generate_shop()
	RunState.run_flags["phase"] = "shop"
	emit_signal("stop_completed")
	emit_signal("shop_opened")
	emit_signal("tour_state_changed")
	return _result(true, final_message, "shop")


func _pay_gold_plating() -> int:
	var gold_cards := 0
	for card in RunState.hand:
		if card.has_enhancement("gold_plating"):
			gold_cards += 1
	var payout := gold_cards * 3
	if payout > 0:
		RunState.add_money(payout)
	return payout


func _apply_discard_gear() -> void:
	for gear in RunState.gear_inventory:
		if gear.effect_type == GameData.EFFECT_MONEY_ON_DISCARD:
			RunState.add_money(int(gear.parameters.get("money", 0)))


func _result(success: bool, message: String, phase: String) -> Dictionary:
	return {"success": success, "message": message, "phase": phase}
