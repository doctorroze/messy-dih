extends Control

enum Screen {
	MENU,
	ALBUM,
	MAP,
	PLAY,
	SHOP,
	END,
}

var current_screen := Screen.MENU
var selected_album_id := "basic_mixtape"
var pending_seed := "opening-night"
var seed_input: LineEdit
var status_label: Label
var screen_container: VBoxContainer
var render_locked := false


func _ready() -> void:
	_build_root()
	RunState.piles_changed.connect(_refresh_current_screen)
	RunState.inventories_changed.connect(_refresh_current_screen)
	RunState.money_changed.connect(_on_money_changed)
	RunState.scoring_breakdown_changed.connect(_on_breakdown_changed)
	TourManager.tour_state_changed.connect(_refresh_current_screen)
	ShopGenerator.shop_changed.connect(_refresh_current_screen)
	_show_menu()


func _build_root() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	screen_container = VBoxContainer.new()
	screen_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_container.add_theme_constant_override("separation", 14)
	scroll.add_child(screen_container)


func _show_menu() -> void:
	current_screen = Screen.MENU
	_begin_render()
	_add_title("DJ Gone Rogue")
	_add_text("Crowd Hype: Groove x Heat")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	screen_container.add_child(row)

	seed_input = LineEdit.new()
	seed_input.text = Config.DEFAULT_SEED
	seed_input.placeholder_text = "Seed"
	seed_input.custom_minimum_size = Vector2(260, 40)
	row.add_child(seed_input)

	var start_button := _make_button("Start Run", Vector2(160, 40))
	start_button.pressed.connect(_on_menu_start_pressed)
	row.add_child(start_button)

	_add_text("Prototype build: placeholder visuals only.")
	_end_render()


func _show_album_select() -> void:
	current_screen = Screen.ALBUM
	_begin_render()
	_add_title("Album Select")
	_add_text("Basic Mixtape")
	_add_text("Standard 52-track starting deck. No gameplay modifier.")

	var continue_button := _make_button("Continue", Vector2(180, 44))
	continue_button.pressed.connect(_on_album_continue)
	screen_container.add_child(continue_button)
	_end_render()


func _show_map() -> void:
	current_screen = Screen.MAP
	_begin_render()
	var summary := TourManager.get_current_map_summary()
	var boss: BossData = summary["boss"]
	_add_title("Tour Map")
	_add_text("Tour Leg %d / %d" % [summary["leg"], Config.TOUR_LEGS])
	_add_text("Route: Asia Set -> North America Set -> Europe Headliner")
	_add_text("Next Stop: %s | Target Crowd Hype: %d" % [summary["stop_display_name"], summary["target_hype"]])
	if boss != null:
		_add_text("Europe Boss: %s / %s" % [boss.country, boss.venue_name])
		_add_text(boss.rule_text)

	var continue_button := _make_button("Start Stop", Vector2(180, 44))
	continue_button.pressed.connect(_on_start_stop_pressed)
	screen_container.add_child(continue_button)
	_end_render()


func _show_play() -> void:
	current_screen = Screen.PLAY
	_begin_render()
	_add_title("%s - Leg %d" % [Config.get_stop_display_name(RunState.current_stop_type), RunState.current_leg])
	_add_text("Crowd Hype: %d / %d | Hands: %d | Discards: %d | Money: $%d" % [
		RunState.current_hype,
		RunState.target_hype,
		RunState.hands_remaining,
		RunState.discards_remaining,
		RunState.money,
	])
	if RunState.current_boss != null:
		_add_text("Boss: %s / %s - %s" % [RunState.current_boss.country, RunState.current_boss.venue_name, RunState.current_boss.rule_text])
	if RunState.last_result_message != "":
		_add_text(RunState.last_result_message)

	_add_section_label("Hand")
	var hand_grid := GridContainer.new()
	hand_grid.columns = 4
	hand_grid.add_theme_constant_override("h_separation", 8)
	hand_grid.add_theme_constant_override("v_separation", 8)
	screen_container.add_child(hand_grid)
	for card in RunState.hand:
		hand_grid.add_child(_make_card_button(card))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	screen_container.add_child(actions)
	var play_button := _make_button("Play Hand", Vector2(160, 44))
	play_button.pressed.connect(_on_play_hand_pressed)
	actions.add_child(play_button)
	var discard_button := _make_button("Discard", Vector2(140, 44))
	discard_button.pressed.connect(_on_discard_pressed)
	actions.add_child(discard_button)
	var clear_button := _make_button("Clear Selection", Vector2(170, 44))
	clear_button.pressed.connect(_on_clear_selection_pressed)
	actions.add_child(clear_button)

	_add_consumables()
	_add_gear()
	_add_breakdown()
	_add_debug_panel()
	_end_render()


func _show_shop() -> void:
	current_screen = Screen.SHOP
	_begin_render()
	_add_title("Backstage")
	_add_text("Money: $%d | Gear: %d/%d | Studio/Chart: %d/%d" % [
		RunState.money,
		RunState.gear_inventory.size(),
		Config.MAX_GEAR_SLOTS,
		RunState.consumables.size(),
		Config.MAX_CONSUMABLE_SLOTS,
	])
	if RunState.last_result_message != "":
		_add_text(RunState.last_result_message)

	_add_section_label("Offers")
	var offers_grid := GridContainer.new()
	offers_grid.columns = 2
	offers_grid.add_theme_constant_override("h_separation", 8)
	offers_grid.add_theme_constant_override("v_separation", 8)
	screen_container.add_child(offers_grid)
	for i in range(ShopGenerator.offers.size()):
		offers_grid.add_child(_make_offer_button(i))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	screen_container.add_child(actions)
	var reroll_button := _make_button("Reroll $%d" % ShopGenerator.get_reroll_cost(), Vector2(140, 44))
	reroll_button.pressed.connect(_on_reroll_pressed)
	actions.add_child(reroll_button)
	var leave_button := _make_button("Leave", Vector2(140, 44))
	leave_button.pressed.connect(_on_leave_shop_pressed)
	actions.add_child(leave_button)

	_add_section_label("Current Gear")
	for i in range(RunState.gear_inventory.size()):
		var gear := RunState.gear_inventory[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		screen_container.add_child(row)
		var label := Label.new()
		label.text = "%s ($%d sell) - %s" % [gear.display_name, gear.get_sell_value(), gear.description]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var sell := _make_button("Sell", Vector2(90, 36))
		sell.pressed.connect(_on_sell_gear_pressed.bind(i))
		row.add_child(sell)

	_add_consumable_inventory_text()
	_end_render()


func _show_end() -> void:
	current_screen = Screen.END
	_begin_render()
	if TourManager.won_run:
		_add_title("World Tour Complete")
	else:
		_add_title("Run Over")
	_add_text(RunState.last_result_message)
	_add_text("Seed: %s" % RunState.rng_seed_string)
	var restart := _make_button("New Run", Vector2(160, 44))
	restart.pressed.connect(_show_menu)
	screen_container.add_child(restart)
	_end_render()


func _add_consumables() -> void:
	_add_section_label("Studio / Chart Cards")
	if RunState.consumables.is_empty():
		_add_text("Empty")
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	screen_container.add_child(row)
	for consumable in RunState.consumables:
		var button := _make_button("%s\n$%d\n%s" % [consumable.display_name, consumable.price, consumable.description], Vector2(180, 86))
		button.tooltip_text = consumable.description
		button.pressed.connect(_on_consumable_pressed.bind(consumable))
		row.add_child(button)


func _add_gear() -> void:
	_add_section_label("Gear")
	if RunState.gear_inventory.is_empty():
		_add_text("Empty")
		return
	for gear in RunState.gear_inventory:
		_add_text("%s [%s] - %s" % [gear.display_name, gear.rarity, gear.description])


func _add_breakdown() -> void:
	_add_section_label("Scoring Breakdown")
	if RunState.last_scoring_breakdown.is_empty():
		_add_text("No hand scored yet.")
		return
	var breakdown := RunState.last_scoring_breakdown
	_add_text("%s | Groove %.1f x Heat %.1f x Final %.2f = %d Crowd Hype" % [
		breakdown["hand_display_name"],
		breakdown["groove"],
		breakdown["heat"],
		breakdown["final_multiplier"],
		breakdown["final_hype"],
	])
	_add_lines("Cards", breakdown.get("card_lines", []))
	_add_lines("Gear", breakdown.get("gear_lines", []))
	_add_lines("Boss", breakdown.get("boss_lines", []))


func _add_debug_panel() -> void:
	_add_section_label("Debug")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	screen_container.add_child(row)

	var money := _make_button("+$25", Vector2(90, 36))
	money.pressed.connect(_on_debug_money)
	row.add_child(money)

	var gear := _make_button("Add Gear", Vector2(110, 36))
	gear.pressed.connect(_on_debug_gear)
	row.add_child(gear)

	var heal := _make_button("Restore", Vector2(100, 36))
	heal.pressed.connect(_on_debug_heal)
	row.add_child(heal)

	var print_deck := _make_button("Print Deck", Vector2(120, 36))
	print_deck.pressed.connect(DebugTools.print_deck)
	row.add_child(print_deck)

	var tests := _make_button("Run Tests", Vector2(120, 36))
	tests.pressed.connect(DebugTools.run_tests)
	row.add_child(tests)

	var row_two := HBoxContainer.new()
	row_two.add_theme_constant_override("separation", 8)
	screen_container.add_child(row_two)

	var next_stop := _make_button("Next Stop", Vector2(120, 36))
	next_stop.pressed.connect(_on_debug_next_stop)
	row_two.add_child(next_stop)

	var force_boss := _make_button("Force Boss", Vector2(120, 36))
	force_boss.pressed.connect(_on_debug_force_boss)
	row_two.add_child(force_boss)


func _add_consumable_inventory_text() -> void:
	_add_section_label("Current Studio / Chart Cards")
	if RunState.consumables.is_empty():
		_add_text("Empty")
		return
	for consumable in RunState.consumables:
		_add_text("%s [%s] - %s" % [consumable.display_name, consumable.category, consumable.description])


func _make_card_button(card: TrackCard) -> Button:
	var selected := RunState.selected_cards.has(card)
	var button := Button.new()
	button.custom_minimum_size = Vector2(138, 138)
	button.text = "%s\n%s %d\n%s%s" % [
		card.display_track_name,
		card.suit.capitalize(),
		card.rank,
		card.display_suit_subtitle,
		_enhancement_suffix(card),
	]
	button.tooltip_text = card.get_display_label()
	button.add_theme_stylebox_override("normal", _white_box(Color.BLACK, 2))
	button.add_theme_stylebox_override("hover", _white_box(Color(0.2, 0.2, 0.2), 3))
	button.add_theme_stylebox_override("pressed", _white_box(Color(0.0, 0.45, 0.9), 4))
	if selected:
		button.add_theme_stylebox_override("normal", _white_box(Color(0.0, 0.45, 0.9), 4))
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.pressed.connect(_on_card_pressed.bind(card))
	return button


func _make_offer_button(index: int) -> Button:
	var offer: Dictionary = ShopGenerator.offers[index]
	var item = offer["item"]
	var sold := bool(offer.get("sold", false))
	var label := "Sold" if sold else "%s\n%s\n$%d\n%s" % [item.display_name, offer["type"].capitalize(), offer["price"], item.description]
	var button := _make_button(label, Vector2(240, 118))
	button.disabled = sold
	button.tooltip_text = item.description
	button.pressed.connect(_on_buy_offer_pressed.bind(index))
	return button


func _make_button(text: String, minimum_size: Vector2 = Vector2.ZERO) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.add_theme_stylebox_override("normal", _white_box(Color.BLACK, 2))
	button.add_theme_stylebox_override("hover", _white_box(Color(0.25, 0.25, 0.25), 2))
	button.add_theme_stylebox_override("pressed", _white_box(Color(0.0, 0.45, 0.9), 3))
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	return button


func _white_box(border_color: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(4)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


func _enhancement_suffix(card: TrackCard) -> String:
	if card.enhancements.is_empty():
		return ""
	return "\n[%s]" % ", ".join(card.enhancements)


func _add_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_container.add_child(label)


func _add_section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	screen_container.add_child(label)


func _add_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_container.add_child(label)


func _add_lines(title: String, lines: Array) -> void:
	if lines.is_empty():
		return
	_add_text("%s: %s" % [title, " | ".join(lines)])


func _begin_render() -> void:
	render_locked = true
	for child in screen_container.get_children():
		screen_container.remove_child(child)
		child.queue_free()
	_update_status()


func _end_render() -> void:
	render_locked = false


func _refresh_current_screen() -> void:
	if render_locked:
		return
	match current_screen:
		Screen.MENU:
			_show_menu()
		Screen.ALBUM:
			_show_album_select()
		Screen.MAP:
			_show_map()
		Screen.PLAY:
			if str(RunState.run_flags.get("phase", "")) == "shop":
				_show_shop()
			elif str(RunState.run_flags.get("phase", "")) == "end":
				_show_end()
			else:
				_show_play()
		Screen.SHOP:
			if str(RunState.run_flags.get("phase", "")) == "end":
				_show_end()
			else:
				_show_shop()
		Screen.END:
			_show_end()


func _update_status() -> void:
	if RunState.rng_seed_string == "":
		status_label.text = "No active run."
		return
	status_label.text = "Seed: %s | Leg %d/%d | Money: $%d | Deck: %d" % [
		RunState.rng_seed_string,
		RunState.current_leg,
		Config.TOUR_LEGS,
		RunState.money,
		RunState.deck.size(),
	]


func _on_album_continue() -> void:
	TourManager.start_run(pending_seed, selected_album_id)
	_show_map()


func _on_menu_start_pressed() -> void:
	if seed_input != null:
		pending_seed = seed_input.text
	if pending_seed.strip_edges().is_empty():
		pending_seed = Config.DEFAULT_SEED
	_show_album_select()


func _on_start_stop_pressed() -> void:
	TourManager.begin_current_stop()
	_show_play()


func _on_card_pressed(card: TrackCard) -> void:
	if not DeckManager.toggle_card_selection(card, 5):
		RunState.last_result_message = "Select at most 5 Tracks."
	_show_play()


func _on_play_hand_pressed() -> void:
	var result := TourManager.play_selected_hand()
	RunState.last_result_message = result["message"]
	if result["phase"] == "shop":
		_show_shop()
	elif result["phase"] == "end":
		_show_end()
	else:
		_show_play()


func _on_discard_pressed() -> void:
	var result := TourManager.discard_selected_cards()
	RunState.last_result_message = result["message"]
	_show_play()


func _on_clear_selection_pressed() -> void:
	RunState.clear_selected_cards()
	_show_play()


func _on_consumable_pressed(consumable: ConsumableData) -> void:
	var result := ConsumableProcessor.use_consumable(consumable, RunState.selected_cards)
	RunState.last_result_message = result["message"]
	_show_play()


func _on_buy_offer_pressed(index: int) -> void:
	var result := ShopGenerator.buy_offer(index)
	RunState.last_result_message = result["message"]
	_show_shop()


func _on_reroll_pressed() -> void:
	var result := ShopGenerator.reroll_shop()
	RunState.last_result_message = result["message"]
	_show_shop()


func _on_sell_gear_pressed(index: int) -> void:
	var result := ShopGenerator.sell_gear(index)
	RunState.last_result_message = result["message"]
	_show_shop()


func _on_leave_shop_pressed() -> void:
	TourManager.leave_shop_to_map()
	if str(RunState.run_flags.get("phase", "")) == "end":
		_show_end()
	else:
		_show_map()


func _on_debug_money() -> void:
	DebugTools.add_money()
	_show_play()


func _on_debug_gear() -> void:
	DebugTools.add_random_gear()
	_show_play()


func _on_debug_heal() -> void:
	DebugTools.heal_resources()
	_show_play()


func _on_debug_next_stop() -> void:
	DebugTools.jump_to_next_stop()
	_show_map()


func _on_debug_force_boss() -> void:
	DebugTools.force_boss("germany_industrial_warehouse")
	_show_play()


func _on_money_changed(_money: int) -> void:
	_update_status()


func _on_breakdown_changed(_breakdown: Dictionary) -> void:
	if current_screen == Screen.PLAY:
		_refresh_current_screen()
